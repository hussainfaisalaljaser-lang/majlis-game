/**
 * الهدايا: هدايا المستويات، والباتل باس (الموسم)، وأبطال الأسبوع.
 * كلها تمر على grant(): تضيف الذهب والجواهر والأغراض، وتحط هدية في gifts عشان التطبيق يعرضها.
 */
import { LATE_REWARD, LEVEL_REWARDS, SEASON, type Reward } from './catalog.js';
import type { Gift, Profile } from './profile.js';

const MAX_GIFTS = 10;

/** يعطي اللاعب [r]. [gift] لو انعطت يطلع له تنبيه. */
export function grant(p: Profile, r: Reward, gift?: Pick<Gift, 'kind' | 'n' | 'ach'>): Profile {
  const owned = [...(p.owned ?? [])];
  for (const id of r.items) if (!owned.includes(id)) owned.push(id);
  const next: Profile = { ...p, coins: p.coins + r.coins, diamonds: p.diamonds + r.diamonds, owned };
  if (gift) next.gifts = [...(p.gifts ?? []), { ...gift, ...r }].slice(-MAX_GIFTS);
  return next;
}

/** مجموع عدة مكافآت في وحدة. */
export function sumRewards(rs: Reward[]): Reward {
  return {
    coins: rs.reduce((a, r) => a + r.coins, 0),
    diamonds: rs.reduce((a, r) => a + r.diamonds, 0),
    items: rs.flatMap((r) => r.items),
  };
}

/** هدايا المستويات اللي بعد [from] لين [to] (يشمل [to]). بعد آخر مستوى في القائمة: كل ٥ مستويات ذهب وجواهر. */
export function levelRewardsBetween(from: number, to: number): (Reward & { level: number })[] {
  const out = LEVEL_REWARDS.filter((r) => r.level > from && r.level <= to);
  const last = LEVEL_REWARDS[LEVEL_REWARDS.length - 1].level;
  for (let l = last + LATE_REWARD.every; l <= to; l += LATE_REWARD.every) {
    if (l > from) out.push({ level: l, coins: LATE_REWARD.coins, diamonds: LATE_REWARD.diamonds, items: [] });
  }
  return out;
}

/** يعطي هدايا المستويات اللي وصلها وما أخذها (مرة وحدة بس لكل مستوى). */
export function applyLevelRewards(p: Profile): Profile {
  const from = p.rewardedLevel ?? 1;
  if (p.level <= from) return p;
  let next: Profile = { ...p, rewardedLevel: p.level };
  for (const r of levelRewardsBetween(from, p.level)) next = grant(next, r, { kind: 'level', n: r.level });
  return next;
}

// ───────────── الباتل باس ─────────────

/** بداية ونهاية الموسم (ملي ثانية) بتوقيت الخليج. */
export function seasonWindow(): { start: number; end: number } {
  const gulf = (d: string) => Date.parse(`${d}T00:00:00Z`) - 3 * 3600_000;
  return { start: gulf(SEASON.start), end: gulf(SEASON.end) };
}

export function seasonActive(now: number): boolean {
  const { start, end } = seasonWindow();
  return now >= start && now < end;
}

export interface PassState {
  season: string;
  points: number;
  premium: boolean;
  /** آخر درجة استلمها في المسار المجاني والمدفوع. */
  free: number;
  prem: number;
}

/** حالة الباتل باس للموسم الحالي (يبدأ من الصفر لو موسم جديد). */
export function passOf(p: Profile): PassState {
  const s = p.pass;
  return s?.season === SEASON.id ? s : { season: SEASON.id, points: 0, premium: false, free: 0, prem: 0 };
}

/** الدرجة اللي وصلها بالنقاط. */
export function passTier(points: number): number {
  return Math.min(SEASON.tiers, Math.floor(points / SEASON.tier_points));
}

/** نقاط الموسم من اللعب (لو الموسم شغال). */
export function addPassPoints(p: Profile, points: number, now: number): Profile {
  if (points <= 0 || !seasonActive(now)) return p;
  const s = passOf(p);
  return { ...p, pass: { ...s, points: s.points + points } };
}

/**
 * يفتح المسار المدفوع. الباتل باس العادي معه درجات هدية (SEASON.bonus_tiers)، والكامل يفتح كل الدرجات على طول.
 */
export function upgradePass(s: PassState, full: boolean): PassState {
  const max = SEASON.tiers * SEASON.tier_points;
  const points = full ? Math.max(s.points, max) : Math.min(max, s.points + SEASON.bonus_tiers * SEASON.tier_points);
  return { ...s, premium: true, points };
}

/** سعر الباتل باس بالجواهر: العادي، أو الكامل (لو عنده العادي يدفع الفرق بس). */
export function passPrice(s: PassState, full: boolean): number {
  if (!full) return SEASON.price;
  return s.premium ? SEASON.full_price - SEASON.price : SEASON.full_price;
}

/**
 * عنده VIP (طاولة النخبة)؟ لو اشترى الباتل باس المدفوع للموسم الشغال. لما يخلص الموسم أو يجي موسم جديد
 * ما اشتراه، ينقفل عليه من جديد لين يشتري. العلامة اليدوية `vip` يعطيها المطوّر لنفسه أو لأحد (للتجربة والدعم).
 */
export function hasVip(p: Profile, now: number): boolean {
  return p.vip === true || (seasonActive(now) && passOf(p).premium);
}

/** عنده الباتل باس كامل (كل الدرجات مفتوحة)؟ */
export const passComplete = (s: PassState) => s.premium && s.points >= SEASON.tiers * SEASON.tier_points;

/** كل مكافآت الباتل باس اللي وصلها وما استلمها (المجاني، والمدفوع لو شراه). */
export function claimPass(p: Profile): { profile: Profile; got: Reward } {
  const s = passOf(p);
  const tier = passTier(s.points);
  const rs: Reward[] = [];
  for (let t = s.free + 1; t <= tier; t++) if (SEASON.free[t]) rs.push(SEASON.free[t]);
  if (s.premium) for (let t = s.prem + 1; t <= tier; t++) if (SEASON.premium[t]) rs.push(SEASON.premium[t]);
  const got = sumRewards(rs);
  const profile = grant({ ...p, pass: { ...s, free: tier, prem: s.premium ? tier : s.prem } }, got);
  return { profile, got };
}
