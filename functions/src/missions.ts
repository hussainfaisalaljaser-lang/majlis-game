import { gulfDay } from './economy.js';

/** المهام اليومية. التطبيق عنده نسخة من النصوص (app/lib/models/missions.dart). */
export const MISSIONS = [
  { id: 'play3', target: 3, coins: 300 }, // العب ٣ ألعاب
  { id: 'win1', target: 1, coins: 400 }, // فز بلعبة
  { id: 'legislate1', target: 1, coins: 250 }, // مرّر قرار وأنت رئيس أو مستشار
  { id: 'claim2', target: 2, coins: 200 }, // ادّعِ مرتين
  { id: 'react5', target: 5, coins: 100 }, // أرسل ٥ ردود سريعة
] as const;

export type MissionId = (typeof MISSIONS)[number]['id'];

export interface MissionState {
  day: string;
  progress: Partial<Record<MissionId, number>>;
  claimed: MissionId[];
}

/** مهام اليوم. لو تغير اليوم ترجع من الصفر. */
export function todaysMissions(m: MissionState | undefined, now: number): MissionState {
  const day = gulfDay(now);
  return m?.day === day ? m : { day, progress: {}, claimed: [] };
}

export function bumpMissions(
  m: MissionState | undefined,
  now: number,
  inc: Partial<Record<MissionId, number>>,
): MissionState {
  const today = todaysMissions(m, now);
  const progress = { ...today.progress };
  for (const [id, n] of Object.entries(inc) as [MissionId, number][]) {
    const target = MISSIONS.find((x) => x.id === id)!.target;
    progress[id] = Math.min(target, (progress[id] ?? 0) + n);
  }
  return { ...today, progress };
}

/** رقم الأسبوع بتوقيت الخليج. الأسبوع يبدأ يوم الأحد. */
export function gulfWeek(now: number): string {
  const days = Math.floor(Date.parse(`${gulfDay(now)}T00:00:00Z`) / 86400_000);
  // ١٩٧٠/١/٤ كان يوم أحد.
  return `W${Math.floor((days - 3) / 7)}`;
}
