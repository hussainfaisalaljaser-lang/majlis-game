import { AsyncLocalStorage } from 'node:async_hooks';
import { getFunctions, type TaskQueue } from 'firebase-admin/functions';
import { logger } from 'firebase-functions/v2';
import { REGION } from './base.js';

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
export type Timings = Partial<Record<'work' | 'tick' | 'push', number>>;

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
      ...[...after.games].map(([code, g]) => scheduleTick(code, g.key, g.deadline).finally(clock('tick'))),
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
let queue: TaskQueue | undefined;

/** يحط منبّه عند [deadline] للعبة [code] على الدور [key]. أي خطأ (مثل صلاحية ناقصة) ما يوقف اللعبة. */
export async function scheduleTick(code: string, key: string, deadline: number | null, attempt = 0): Promise<void> {
  if (deadline === null || !TICKS_ON) return;
  try {
    queue ??= getFunctions().taskQueue(`locations/${REGION}/functions/${TICK_FN}`);
    // بدون اسم للمهمة: مع الاسم قوقل تدور أول على مهمة بنفس الاسم، وهذا يبطّئ حطها كثير.
    // نفس الدور ما ينحط له منبّه مرتين (finishTurn)، ولو تكرر ما يضر: اللي يصحى بعد الأول ما يلقى شي يسويه.
    await queue.enqueue({ code, key, attempt }, { scheduleTime: new Date(Math.max(Date.now(), deadline) + 60) });
  } catch (e) {
    if (!warned) {
      warned = true;
      logger.warn('ما قدرنا نحط منبّه الدور (اللعبة تكمل من الجوالات)', { code, err: String((e as Error)?.message ?? e) });
    }
  }
}
