import { createHash } from 'node:crypto';
import { AsyncLocalStorage } from 'node:async_hooks';
import { getFunctions } from 'firebase-admin/functions';
import { logger } from 'firebase-functions/v2';
import { REGION } from './base.js';

/**
 * منبّه الدور: كل ما تنكتب حالة جديدة للعبة، نحط مهمة (Cloud Tasks) تصحى عند آخر وقت الدور وتكمّل اللعبة
 * (البوتات تلعب، واللي خلص وقته يلعب عنه). كذا البوتات ما تنتظر جوال لاعب يطلب من السيرفر.
 * الجوال يطلب بعدها بشوي كاحتياط (game_screen.dart)، والسيرفر ينفذ مرة وحدة بس.
 */
export const TICK_FN = 'gameTick';

type Pending = Map<string, { key: string; deadline: number | null }>;
const store = new AsyncLocalStorage<Pending>();

/** writeGame يسجل آخر حالة انكتبت لكل لعبة في هالطلب (آخر محاولة للعملية هي اللي انحفظت). */
export function noteGameWrite(code: string, key: string, deadline: number | null): void {
  store.getStore()?.set(code, { key, deadline });
}

/** يشغّل الطلب، وبعده يحط منبّه لكل لعبة انكتبت فيه. */
export async function withTicks<T>(run: () => Promise<T>): Promise<T> {
  const pending: Pending = new Map();
  try {
    return await store.run(pending, run);
  } finally {
    await Promise.all([...pending].map(([code, p]) => scheduleTick(code, p.key, p.deadline)));
  }
}

let warned = false;

/** يحط منبّه عند [deadline] للعبة [code] على الدور [key]. أي خطأ (مثل صلاحية ناقصة) ما يوقف اللعبة. */
export async function scheduleTick(code: string, key: string, deadline: number | null, attempt = 0): Promise<void> {
  if (deadline === null) return;
  // اسم المهمة ثابت لكل دور، فلو انطلبت مرتين ما تنحط مرتين. [attempt] لو صحى بدري وانحط من جديد.
  const id = `${code}-${createHash('sha1').update(`${key}|${deadline}|${attempt}`).digest('hex').slice(0, 20)}`;
  try {
    await getFunctions()
      .taskQueue(`locations/${REGION}/functions/${TICK_FN}`)
      .enqueue({ code, key, attempt }, { scheduleTime: new Date(Math.max(Date.now(), deadline) + 60), id });
  } catch (e) {
    const msg = String((e as { message?: string })?.message ?? e);
    if (/already exists|ALREADY_EXISTS|task-already-exists/i.test(msg)) return;
    if (!warned) {
      warned = true;
      logger.warn('ما قدرنا نحط منبّه الدور (اللعبة تكمل من الجوالات)', { code, err: msg });
    }
  }
}
