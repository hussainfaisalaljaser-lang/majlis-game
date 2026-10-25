/** الطاولات والذهب والمستويات. التطبيق عنده نسخة من هذي الأرقام (app/lib/models/table_tier.dart). */

export interface TableTier {
  id: string;
  entryFee: number;
  requiredLevel: number;
  vipOnly: boolean;
}

export const TIERS: TableTier[] = [
  { id: 'starter', entryFee: 100, requiredLevel: 1, vipOnly: false },
  { id: 'city', entryFee: 1000, requiredLevel: 1, vipOnly: false },
  { id: 'palace', entryFee: 5000, requiredLevel: 10, vipOnly: false },
  { id: 'kings', entryFee: 25000, requiredLevel: 30, vipOnly: false },
  { id: 'vip', entryFee: 100000, requiredLevel: 1, vipOnly: true },
];

export function tierById(id: unknown): TableTier | null {
  return TIERS.find((t) => t.id === id) ?? null;
}

/** ذهب البداية لكل لاعب جديد. يكفي يجرب طاولة المدينة مرتين. */
export const STARTING_COINS = 2000;

/** مكافأة أول مرة يربط حسابه بقوقل. */
export const LINK_REWARD = 500;

/** مكافأة الدخول اليومي حسب اليوم في السلسلة (١ إلى ٧). اليوم السابع فيه جواهر. */
export const DAILY_REWARDS: { coins: number; diamonds: number }[] = [
  { coins: 200, diamonds: 0 },
  { coins: 300, diamonds: 0 },
  { coins: 400, diamonds: 0 },
  { coins: 500, diamonds: 0 },
  { coins: 700, diamonds: 0 },
  { coins: 900, diamonds: 0 },
  { coins: 1500, diamonds: 10 },
];

/** نقاط الموسم (الباتل باس) لكل مهمة يومية يستلمها. نقاط اللعب نفس الخبرة. */
export const MISSION_PASS_POINTS = 25;

export const XP_PER_GAME = 20;
export const XP_PER_WIN = 30;
/**
 * كل مستوى أصعب من اللي قبله: من مستوى ١ لـ ٢ تحتاج ١٠٠ خبرة، وكل مستوى بعده يزيد ٥٠
 * (١٠٠، ١٥٠، ٢٠٠…). نفس الحسبة في التطبيق (app/lib/models/profile.dart).
 */
export const XP_FIRST_LEVEL = 100;
export const XP_LEVEL_STEP = 50;

/** الخبرة اللي تحتاجها من مستوى [level] للي بعده. */
export function xpToNext(level: number): number {
  return XP_FIRST_LEVEL + XP_LEVEL_STEP * (level - 1);
}

/** مجموع الخبرة اللي توصلك لبداية مستوى [level]. */
export function xpForLevel(level: number): number {
  const n = level - 1;
  return XP_FIRST_LEVEL * n + (XP_LEVEL_STEP * n * (n - 1)) / 2;
}

export function levelFor(xp: number): number {
  let level = 1;
  while (xpForLevel(level + 1) <= xp) level++;
  return level;
}

/** تاريخ اليوم بتوقيت الخليج (UTC+3)، عشان الهدية اليومية تتجدد الساعة ١٢ بالليل عندنا. */
export function gulfDay(ms: number): string {
  return new Date(ms + 3 * 3600_000).toISOString().slice(0, 10);
}

export function previousDay(day: string): string {
  return new Date(Date.parse(`${day}T00:00:00Z`) - 86400_000).toISOString().slice(0, 10);
}
