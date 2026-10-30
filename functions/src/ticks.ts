import { AsyncLocalStorage } from 'node:async_hooks';
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

/** يشغّل الطلب، وبعده يحط منبّه لكل لعبة انكتبت فيه ويرسل الإشعارات (مع بعض). */
export async function withTicks<T>(run: () => Promise<T>, timings?: Timings): Promise<T> {
  const after: After = { games: new Map(), jobs: [] };
  const started = Date.now();
  try {
    return await store.run(after, run);
  } finally {
    const done = Date.now();
    const clock = (name: 'tick' | 'push') => () => {
      if (timings) timings[name] = Math.max(timings[name] ?? 0, Date.now() - done);
    };
    await Promise.all([
      ...[...after.games].map(([code, g]) =>
        scheduleTick(code, g.key, g.deadline)
          .then((fallback) => {
            if (fallback && timings) timings.tickFallback = 1;
          })
          .finally(clock('tick')),
      ),
      ...after.jobs.map((job) =>
        Promise.resolve()
          .then(job)
          .catch((e) => logger.warn('after-request job failed', e))
          .finally(clock('push')),
      ),
    ]);
    if (timings) timings.work = done - started;
  }
}

let warned = false;
let restWarned = false;
let queue: TaskQueue | undefined;

/**
 * يحط منبّه عند [deadline] للعبة [code] على الدور [key]. أي خطأ (مثل صلاحية ناقصة) ما يوقف اللعبة.
 * يرجع true لو الطريقة المباشرة فشلت وانحط بالمكتبة (للقياس).
 */
export async function scheduleTick(code: string, key: string, deadline: number | null, attempt = 0): Promise<boolean> {
  if (deadline === null || !TICKS_ON) return false;
  const payload = { code, key, attempt };
  const at = new Date(Math.max(Date.now(), deadline) + 60);
  const viaSdk = async () => {
    queue ??= getFunctions().taskQueue(`locations/${REGION}/functions/${TICK_FN}`);
    await queue.enqueue(payload, { scheduleTime: at });
  };
  try {
    // بدون اسم للمهمة: مع الاسم قوقل تدور أول على مهمة بنفس الاسم، وهذا يبطّئ حطها كثير.
    // نفس الدور ما ينحط له منبّه مرتين (finishTurn)، ولو تكرر ما يضر: اللي يصحى بعد الأول ما يلقى شي يسويه.
    if (process.env.FUNCTIONS_EMULATOR === 'true') {
      await viaSdk();
      return false;
    }
    try {
      await createTask(payload, at);
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

async function createTask(payload: unknown, at: Date): Promise<void> {
  account ??= (await meta('email')).trim();
  const res = await fetch(
    `https://cloudtasks.googleapis.com/v2/projects/${PROJECT}/locations/${REGION}/queues/${TICK_FN}/tasks`,
    {
      method: 'POST',
      headers: { authorization: `Bearer ${await accessToken()}`, 'content-type': 'application/json' },
      body: JSON.stringify({
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
      }),
    },
  );
  if (!res.ok) throw new Error(`createTask ${res.status}: ${(await res.text()).slice(0, 300)}`);
}
