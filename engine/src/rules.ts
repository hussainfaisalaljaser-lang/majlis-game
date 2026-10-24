import type { Power } from './types.js';

export const MIN_PLAYERS = 5;
export const MAX_PLAYERS = 10;

export const LOYAL_TO_WIN = 5;
export const TRAITOR_TO_WIN = 6;
/** بعد هذا العدد من قرارات الخونة، انتخاب الزعيم كمستشار = فوز الخونة. */
export const LEADER_DANGER_ZONE = 3;
/** بعد هذا العدد من قرارات الخونة، يصير حق النقض (الفيتو) متاح. */
export const VETO_UNLOCK = 5;
export const MAX_FAILED_ELECTIONS = 3;

export const DECK = { L: 6, T: 11 } as const;

/** عدد الخونة (بدون الزعيم) حسب عدد اللاعبين. */
export function traitorCount(players: number): number {
  return Math.floor((players - 3) / 2);
}

/** الزعيم يعرف أعوانه فقط في الطاولات الصغيرة. */
export function leaderKnowsTraitors(players: number): boolean {
  return players <= 6;
}

/** القدرة اللي تنفتح للرئيس بعد تمرير قرار الخونة رقم n (يبدأ من ١). */
export function powerFor(players: number, traitorPolicyNumber: number): Power | null {
  const small: (Power | null)[] = [null, null, 'peek', 'execute', 'execute'];
  const medium: (Power | null)[] = [null, 'investigate', 'specialElection', 'execute', 'execute'];
  const large: (Power | null)[] = ['investigate', 'investigate', 'specialElection', 'execute', 'execute'];
  const table = players <= 6 ? small : players <= 8 ? medium : large;
  return table[traitorPolicyNumber - 1] ?? null;
}
