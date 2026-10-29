import type { Power } from './types.js';

export const MIN_PLAYERS = 5;
export const MAX_PLAYERS = 10;

export const LOYAL_TO_WIN = 5;
export const TRAITOR_TO_WIN = 6;
/** بعد هذا العدد من قرارات الخونة، انتخاب الزعيم كوزير = فوز الخونة. */
export const LEADER_DANGER_ZONE = 3;
/** بعد هذا العدد من قرارات الخونة، يصير حق النقض متاح. */
export const VETO_UNLOCK = 5;
export const MAX_FAILED_ELECTIONS = 3;

/** البوليسات: ١٧ (١١ خونة و٦ أوفياء)، تنخلط مرة وحدة بس في بداية اللعبة. */
export const DECK = { L: 6, T: 11 } as const;

/**
 * لما تخلص خانة السحب: false = بوليسات خانة الرمي ترجع بنفس ترتيبها (أول وحدة انرمت أول وحدة تنسحب)،
 * true = تنخلط من جديد. طور تجريبي، نقرر بعدين أي واحد نعتمد.
 */
export const RESHUFFLE_DISCARDS = false;

/** عدد الخونة (بدون الزعيم) حسب عدد اللاعبين. */
export function traitorCount(players: number): number {
  return Math.floor((players - 3) / 2);
}

/** الزعيم يعرف أعوانه فقط في الطاولات الصغيرة. */
export function leaderKnowsTraitors(players: number): boolean {
  return players <= 6;
}

/** كم دور جديد (قاضي، شيخ، جاسوس) يطلع في اللعبة حسب عدد اللاعبين. */
export function extraSpecialCount(players: number): number {
  return players <= 6 ? 1 : players <= 8 ? 2 : 3;
}

/** القدرة اللي تنفتح للرئيس بعد تمرير قرار الخونة رقم n (يبدأ من ١). */
export function powerFor(players: number, traitorPolicyNumber: number): Power | null {
  const small: (Power | null)[] = [null, null, 'peek', 'execute', 'execute'];
  const medium: (Power | null)[] = [null, 'investigate', 'specialElection', 'execute', 'execute'];
  const large: (Power | null)[] = ['investigate', 'investigate', 'specialElection', 'execute', 'execute'];
  const table = players <= 6 ? small : players <= 8 ? medium : large;
  return table[traitorPolicyNumber - 1] ?? null;
}

/** كم ثانية لكل مرحلة قبل ما السيرفر يلعب بدال اللي تأخر. */
export const PHASE_SECONDS = {
  nomination: 30,
  election: 25,
  presidentDiscard: 20,
  chancellorEnact: 20,
  vetoResponse: 15,
  power: 30,
} as const;
