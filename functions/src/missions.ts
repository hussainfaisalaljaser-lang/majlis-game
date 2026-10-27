import type { GameState } from '../../engine/src/index.js';
import { gulfDay } from './economy.js';

/** المهام اليومية. التطبيق عنده نسخة من النصوص (app/lib/models/missions.dart). */
export const MISSIONS = [
  { id: 'play3', target: 3, coins: 300 }, // العب ٣ ألعاب
  { id: 'win1', target: 1, coins: 400 }, // فز بلعبة
  { id: 'legislate1', target: 1, coins: 250 }, // مرّر قرار وأنت رئيس أو وزير
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

// ───────────── مهام الباتل باس ─────────────

/** إحصائيات لعبة وحدة تتقدم فيها مهام الباتل باس. */
export type PassStat =
  | 'play' // لعب لعبة
  | 'win' // فاز
  | 'winTraitor' // فاز وهو من فريق الخونة (خاين أو الزعيم)
  | 'win10' // فاز في طاولة ١٠ لاعبين
  | 'killLeader' // طرد زعيم الخونة وهو رئيس
  | 'leaderMinister' // فاز وهو الزعيم بعد ما انتخبوه وزير
  | 'loyalLaw' // مرّر قرار أزرق وهو وزير
  | 'found' // كشف خاين بالتحقيق
  | 'rolesGame'; // لعب لعبة في طور الشخصيات

export interface PassMission {
  id: string;
  stat: PassStat;
  target: number;
  /** نقاط الباتل باس لما يستلمها. */
  points: number;
}

/** مهام الأسبوع (تتجدد كل أحد بتوقيت الخليج). التطبيق عنده النصوص (app/lib/models/missions.dart). */
export const WEEKLY_MISSIONS: PassMission[] = [
  { id: 'w_play10', stat: 'play', target: 10, points: 120 },
  { id: 'w_win5', stat: 'win', target: 5, points: 150 },
  { id: 'w_traitor', stat: 'winTraitor', target: 1, points: 150 },
  { id: 'w_ten', stat: 'win10', target: 1, points: 150 },
  { id: 'w_laws', stat: 'loyalLaw', target: 3, points: 120 },
];

/** مهام الموسم كله (لين نهاية الباتل باس). */
export const SEASON_MISSIONS: PassMission[] = [
  { id: 's_leader3', stat: 'killLeader', target: 3, points: 400 },
  { id: 's_minister', stat: 'leaderMinister', target: 1, points: 500 },
  { id: 's_traitor10', stat: 'winTraitor', target: 10, points: 400 },
  { id: 's_ten5', stat: 'win10', target: 5, points: 400 },
  { id: 's_win30', stat: 'win', target: 30, points: 500 },
  { id: 's_found5', stat: 'found', target: 5, points: 300 },
  { id: 's_roles10', stat: 'rolesGame', target: 10, points: 300 },
  { id: 's_play50', stat: 'play', target: 50, points: 300 },
];

export interface PassMissionState {
  season: string;
  week: string;
  /** تقدم هالأسبوع وكل الموسم لكل إحصائية. */
  weekly: Partial<Record<PassStat, number>>;
  total: Partial<Record<PassStat, number>>;
  weeklyClaimed: string[];
  seasonClaimed: string[];
}

/** مهام الباتل باس الحين: موسم جديد يبدأ من الصفر، وأسبوع جديد يصفّر الأسبوعية بس. */
export function currentPassMissions(m: PassMissionState | undefined, season: string, now: number): PassMissionState {
  const week = gulfWeek(now);
  const s: PassMissionState =
    m?.season === season ? m : { season, week, weekly: {}, total: {}, weeklyClaimed: [], seasonClaimed: [] };
  return s.week === week ? s : { ...s, week, weekly: {}, weeklyClaimed: [] };
}

export function bumpPassMissions(
  m: PassMissionState | undefined,
  season: string,
  now: number,
  inc: Partial<Record<PassStat, number>>,
): PassMissionState {
  const cur = currentPassMissions(m, season, now);
  const weekly = { ...cur.weekly };
  const total = { ...cur.total };
  for (const [k, n] of Object.entries(inc) as [PassStat, number][]) {
    if (!n) continue;
    weekly[k] = (weekly[k] ?? 0) + n;
    total[k] = (total[k] ?? 0) + n;
  }
  return { ...cur, weekly, total };
}

/**
 * وش سوى اللاعب في هاللعبة لمهام الباتل باس. اللي طلع قبل النهاية (أو انطرد لأنه ما لعب) ولعبة الشرح ما تنحسب.
 * [roles]: اللعبة في طور الشخصيات.
 */
export function passStatsFromGame(
  state: GameState,
  uid: string,
  won: boolean,
  roles: boolean,
): Partial<Record<PassStat, number>> {
  const me = state.players.find((p) => p.id === uid);
  if (!me || state.tutorial || (state.autopilot ?? []).includes(uid)) return {};
  const out: Partial<Record<PassStat, number>> = { play: 1 };
  const add = (k: PassStat, n = 1) => {
    if (n > 0) out[k] = (out[k] ?? 0) + n;
  };
  const roleOf = (id: string) => state.players.find((p) => p.id === id)?.role;
  if (won) {
    add('win');
    if (me.role !== 'loyal') add('winTraitor');
    if (state.players.length === 10) add('win10');
    if (me.role === 'leader' && state.winReason === 'leaderElected') add('leaderMinister');
  }
  for (const e of state.log) {
    if (e.type === 'executed' && e.by === uid && roleOf(e.target) === 'leader') add('killLeader');
    if (e.type === 'enacted' && !e.chaos && e.policy === 'L' && e.government?.chancellor === uid) add('loyalLaw');
  }
  add('found', state.investigations.filter((i) => i.by === uid && i.team === 'traitor').length);
  if (roles) add('rolesGame');
  return out;
}
