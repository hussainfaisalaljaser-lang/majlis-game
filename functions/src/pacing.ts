import type { GameEvent, GameState } from '../../engine/src/index.js';

/**
 * إيقاع اللعبة: السيرفر يعطي وقت للمشاهد وصوت الراوي قبل ما يبدأ الدور اللي بعده،
 * عشان ما تركب الأشياء على بعض. الأرقام تطابق مدد المشاهد في التطبيق (game_screen.dart).
 * اختبارات السيرفر تشغّله سريع بـ MAJLIS_FAST_PACING=1.
 */
const fast = () => process.env.MAJLIS_FAST_PACING === '1';

/** بداية اللعبة: الترحيب (~٥ ث) + قلب بطاقة الدور وجملتها (~٦ ث). */
export const START_GRACE_MS = 13_000;

/** وقت كل مشهد في التطبيق مع جملة الراوي اللي معه. */
const SCENE_MS: Partial<Record<GameEvent['type'], number>> = {
  voteResult: 4_000,
  enacted: 3_500,
  executed: 4_000,
  guarded: 4_000,
};

/** البوت "يفكر" شوي قبل حركته. */
export const BOT_THINK_MS = 3_000;
export const BOT_THINK_JITTER_MS = 2_000;

/** وقت المشاهد اللي طلعت من الأحداث الجديدة (من بعد آخر حالة). */
export function scenesDelay(prev: GameState, next: GameState): number {
  if (fast()) return 0;
  return next.log.slice(prev.log.length).reduce((sum, e) => sum + (SCENE_MS[e.type] ?? 0), 0);
}

export function startGrace(): number {
  return fast() ? 0 : START_GRACE_MS;
}

export function botThink(jitter: number): number {
  return fast() ? 2_000 + jitter : BOT_THINK_MS + jitter;
}
