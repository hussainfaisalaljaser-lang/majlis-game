/**
 * التصنيف: نقاط من الطاولات العامة بس، تتصفّر كل موسم (نفس موسم الباتل باس).
 * الفوز يزيد والخسارة تنقص، مضروبة في نسبة البشر بالطاولة (اللعب مع بوتات ما يرفعك كثير)،
 * وما تنزل تحت أول نقطة في رتبتك. أول ما توصل رتبة في الموسم تاخذ مكافأتها.
 */
import { RANK_LOSS, RANK_TIERS, RANK_WIN, SEASON } from './catalog.js';
import type { Profile } from './profile.js';
import { grant } from './rewards.js';

export interface RankState {
  season: string;
  points: number;
  /** أعلى نقاط وصلها هالموسم. */
  best: number;
  /** أعلى رتبة أخذ مكافأتها هالموسم (رقمها في RANK_TIERS). */
  rewarded: number;
}

/** تصنيفه في الموسم الحالي (موسم جديد = يبدأ من الصفر). */
export function rankOf(p: Profile): RankState {
  const r = p.rank;
  return r && r.season === SEASON.id ? r : { season: SEASON.id, points: 0, best: 0, rewarded: 0 };
}

export const tierIndex = (points: number) => RANK_TIERS.filter((t) => points >= t.min).length - 1;

/** كم نقطة يكسب أو يخسر من لعبة عامة فيها [humans] بشر من [total] لاعب. */
export function rankDelta(won: boolean, humans: number, total: number): number {
  const share = total > 0 ? humans / total : 0;
  return won ? Math.max(1, Math.round(RANK_WIN * share)) : -Math.round(RANK_LOSS * share);
}

/** يطبق النقاط على ملفه، ويعطيه مكافأة كل رتبة جديدة وصلها هالموسم. */
export function applyRank(p: Profile, delta: number): Profile {
  const r = rankOf(p);
  const floor = RANK_TIERS[tierIndex(r.points)].min;
  const points = Math.max(floor, r.points + delta);
  const tier = tierIndex(points);
  let out: Profile = { ...p, rank: { ...r, points, best: Math.max(r.best, points), rewarded: Math.max(r.rewarded, tier) } };
  for (let t = r.rewarded + 1; t <= tier; t++) {
    const T = RANK_TIERS[t];
    out = grant(out, { coins: T.coins, diamonds: T.diamonds, items: [] }, { kind: 'rank', n: t });
  }
  return out;
}
