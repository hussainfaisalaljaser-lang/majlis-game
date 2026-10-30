import { AsyncLocalStorage } from 'node:async_hooks';
import { Agent, request as httpsRequest } from 'node:https';
import { getFunctions, type TaskQueue } from 'firebase-admin/functions';
import { logger } from 'firebase-functions/v2';
import { db, REGION } from './base.js';

/**
 * منبّه الدور: كل ما يبدأ دور جديد، نحط مهمة (Cloud Tasks) تصحى عند آخر وقت الدور وتكمّل اللعبة
 * (البوتات تلعب، واللي خلص وقته يلعب عنه). كذا البوتات ما تنتظر جوال لاعب يطلب من السيرفر.
 * الجوال يطلب بعدها بشوي كاحتياط (game_screen.dart)، والسيرفر ينفذ مرة وحدة بس.
 */
export const TICK_FN = 'gameTick';

/**
 * المنبّه شغال (يحتاج خدمة Cloud Tasks مفعّلة في المشروع، وصلاحية «Cloud Tasks Admin» لحساب الرفع).
 * لو طفيناه (false) اللعبة تكمل من الجوالات مثل قبل.
 */
export const TICKS_ON = true;

/** شغل الطلب اللي بعد ما تنحفظ العملية: منبّه لكل لعبة انكتبت، والإشعارات. يمشون كلهم بنفس الوقت. */
interface After {
  games: Map<string, { key: string; deadline: number | null }>;
  jobs: Array<() => Promise<unknown>>;
}
const store = new AsyncLocalStorage<After>();

/**
 * writeGame يسجل آخر حالة انكتبت لكل لعبة في هالطلب (آخر محاولة للعملية هي اللي انحفظت).
 * [deadline] null: ما نحتاج منبّه (اللعبة خلصت، أو نفس الدور وله منبّه من قبل).
 */
export function noteGameWrite(code: string, key: string, deadline: number | null): void {
  store.getStore()?.games.set(code, { key, deadline });
}

/** شغل بعد الطلب (مثل الإشعارات): داخل [withTicks] يتأجل لآخره ويمشي مع المنبّهات بنفس الوقت، وبرا يمشي على طول. */
export async function afterwards(job: () => Promise<unknown>): Promise<void> {
  const after = store.getStore();
  if (after) after.jobs.push(job);
  else await job();
}

/** كم أخذ كل جزء من الطلب بالملي ثانية (قياس السرعة في التطبيق): العملية، والمنبّه، والإشعارات. */
export type Timings = Partial<Record<'work' | 'tick' | 'push' | 'tickFallback', number>>;

/** كم ننتظر حط المنبّه قبل ما نرد على اللاعب (بس لين يطلع الطلب لقوقل). */
const TICK_WAIT_MS = 200;
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/** يشغّل الطلب، وبعده يحط منبّه لكل لعبة انكتبت فيه ويرسل الإشعارات (مع بعض). */
export async function withTicks<T>(run: () => Promise<T>, timings?: Timings): Promise<T> {
  const after: After = { games: new Map(), jobs: [] };
  const started = Date.now();
  try {
    return await store.run(after, run);
  } finally {
    const done = Date.now();
    // نعرف متى طلعت طلبات المنبّه كلها (عشان نرد على اللاعب بعدها على طول).
    const alarms = [...after.games].filter(([, g]) => g.deadline !== null && TICKS_ON);
    let sentCount = 0;
    let allSent = () => {};
    const sent = new Promise<void>((resolve) => (allSent = resolve));
    const onSent = () => {
      if (++sentCount === alarms.length) allSent();
    };
    const ticks = Promise.all(
      alarms.map(([code, g]) =>
        scheduleTick(code, g.key, g.deadline, 0, onSent).then((fallback) => {
          if (fallback && timings) timings.tickFallback = 1;
        }),
      ),
    );
    const jobs = Promise.all(
      after.jobs.map((job) =>
        Promise.resolve()
          .then(job)
          .catch((e) => logger.warn('after-request job failed', e))
          .finally(() => {
            if (timings) timings.push = Math.max(timings.push ?? 0, Date.now() - done);
          }),
      ),
    );
    // خدمة المهام عند قوقل ترد بعد حوالي ثانية. ننتظر بس لين يطلع طلب المنبّه (وبالكثير [TICK_WAIT_MS])، ونرد
    // على اللاعب، والحجز يكمل بالخلفية. لو تأخر، الجوال يكمّل الدور بنفسه مثل قبل.
    await Promise.all([jobs, alarms.length ? Promise.race([sent, ticks, sleep(TICK_WAIT_MS)]) : null]);
    if (timings) {
      timings.work = done - started;
      if (alarms.length) timings.tick = Date.now() - done;
    }
  }
}

let warned = false;
let restWarned = false;
let queue: TaskQueue | undefined;

/**
 * يحط منبّه عند [deadline] للعبة [code] على الدور [key]. أي خطأ (مثل صلاحية ناقصة) ما يوقف اللعبة.
 * يرجع true لو الطريقة المباشرة فشلت وانحط بالمكتبة (للقياس).
 */
export async function scheduleTick(
  code: string,
  key: string,
  deadline: number | null,
  attempt = 0,
  onSent: () => void = () => {},
): Promise<boolean> {
  if (deadline === null || !TICKS_ON) return false;
  const payload = { code, key, attempt };
  const at = new Date(Math.max(Date.now(), deadline) + 60);
  const viaSdk = async () => {
    queue ??= getFunctions().taskQueue(`locations/${REGION}/functions/${TICK_FN}`);
    await queue.enqueue(payload, { scheduleTime: at });
    onSent();
  };
  try {
    // بدون اسم للمهمة: مع الاسم قوقل تدور أول على مهمة بنفس الاسم، وهذا يبطّئ حطها كثير.
    // نفس الدور ما ينحط له منبّه مرتين (finishTurn)، ولو تكرر ما يضر: اللي يصحى بعد الأول ما يلقى شي يسويه.
    if (process.env.FUNCTIONS_EMULATOR === 'true') {
      await viaSdk();
      return false;
    }
    try {
      await createTask(payload, at, onSent);
      return false;
    } catch (e) {
      // الطريقة المباشرة ما مشت: نحطه بالمكتبة (أبطأ بس أكيد)، ونسجل السبب مرة (وفي config/diag لفحص السرعة).
      if (!restWarned) {
        restWarned = true;
        const err = String((e as Error)?.message ?? e).slice(0, 500);
        logger.warn('حط المنبّه المباشر ما مشى، رجعنا للمكتبة', { err });
        await db.doc('config/diag').set({ tickRest: { err, at: Date.now() } }, { merge: true }).catch(() => undefined);
      }
      await viaSdk();
      return true;
    }
  } catch (e) {
    if (!warned) {
      warned = true;
      logger.warn('ما قدرنا نحط منبّه الدور (اللعبة تكمل من الجوالات)', { code, err: String((e as Error)?.message ?? e) });
    }
    return false;
  }
}

// ── حط المهمة مباشرة (بدال مكتبة firebase-admin): التوكن واسم الحساب من خادم البيانات الداخلي ونحفظهم،
// والاتصال بخدمة المهام يبقى مفتوح بين الطلبات. نفس المهمة اللي تحطها المكتبة بالضبط.
const PROJECT = process.env.GCLOUD_PROJECT ?? 'majlis-game-1d739';
const META = 'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default';
let token: { value: string; until: number } | undefined;
let account: string | undefined;

async function meta(path: string): Promise<string> {
  const res = await fetch(`${META}/${path}`, { headers: { 'Metadata-Flavor': 'Google' } });
  if (!res.ok) throw new Error(`metadata ${path}: ${res.status}`);
  return res.text();
}

async function accessToken(): Promise<string> {
  if (token && Date.now() < token.until) return token.value;
  const json = JSON.parse(await meta('token')) as { access_token: string; expires_in: number };
  token = { value: json.access_token, until: Date.now() + (json.expires_in - 120) * 1000 };
  return token.value;
}

/** اتصال واحد مفتوح لخدمة المهام يتعاد استخدامه بين الطلبات. */
const agent = new Agent({ keepAlive: true, keepAliveMsecs: 30_000 });

/** يحط المهمة. [onSent]: الطلب طلع كامل من السيرفر (قوقل بتحطها حتى لو ما قرينا ردها). */
async function createTask(payload: unknown, at: Date, onSent: () => void): Promise<void> {
  account ??= (await meta('email')).trim();
  const body = JSON.stringify({
    task: {
      scheduleTime: at.toISOString(),
      httpRequest: {
        httpMethod: 'POST',
        url: `https://${REGION}-${PROJECT}.cloudfunctions.net/${TICK_FN}`,
        headers: { 'content-type': 'application/json' },
        body: Buffer.from(JSON.stringify({ data: payload })).toString('base64'),
        oidcToken: { serviceAccountEmail: account },
      },
    },
  });
  const auth = await accessToken();
  await new Promise<void>((resolve, reject) => {
    const req = httpsRequest(
      {
        host: 'cloudtasks.googleapis.com',
        path: `/v2/projects/${PROJECT}/locations/${REGION}/queues/${TICK_FN}/tasks`,
        method: 'POST',
        agent,
        headers: {
          authorization: `Bearer ${auth}`,
          'content-type': 'application/json',
          'content-length': Buffer.byteLength(body),
        },
      },
      (res) => {
        let text = '';
        res.setEncoding('utf8');
        res.on('data', (chunk: string) => (text += chunk));
        res.on('end', () => {
          const ok = (res.statusCode ?? 500) < 300;
          if (ok) resolve();
          else reject(new Error(`createTask ${res.statusCode}: ${text.slice(0, 300)}`));
        });
      },
    );
    req.on('error', reject);
    req.on('finish', onSent);
    req.end(body);
  });
}
