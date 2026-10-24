export type PlayerId = string;

/** الفريق: الأوفياء أو الخونة. زعيم الخونة ينتمي لفريق الخونة. */
export type Team = 'loyal' | 'traitor';
export type Role = 'loyal' | 'traitor' | 'leader';

/** القرار: L = قرار الأوفياء (أزرق)، T = قرار الخونة (أحمر). */
export type Policy = 'L' | 'T';

export type Power = 'investigate' | 'peek' | 'specialElection' | 'execute';

export type Phase =
  | 'nomination'
  | 'election'
  | 'presidentDiscard'
  | 'chancellorEnact'
  | 'vetoResponse'
  | 'power'
  | 'gameOver';

export type WinReason =
  | 'loyalPolicies'
  | 'traitorPolicies'
  | 'leaderElected'
  | 'leaderExecuted';

export interface Player {
  id: PlayerId;
  name: string;
  seat: number;
  role: Role;
  alive: boolean;
}

export interface Government {
  president: PlayerId;
  chancellor: PlayerId;
}

/** ادعاء الرئيس (٣ كروت) أو المستشار (٢ كرت) عن اللي وصله. ممكن يكون كذب. */
export interface Claim {
  by: PlayerId;
  office: 'president' | 'chancellor';
  policies: Policy[];
}

export type GameEvent =
  | { type: 'nominated'; round: number; president: PlayerId; chancellor: PlayerId }
  | { type: 'voteResult'; round: number; votes: Record<PlayerId, boolean>; passed: boolean }
  | { type: 'enacted'; round: number; policy: Policy; chaos: boolean; government?: Government }
  | { type: 'vetoed'; round: number; government: Government }
  | { type: 'vetoRejected'; round: number }
  | { type: 'claim'; round: number; claim: Claim }
  | { type: 'investigated'; round: number; by: PlayerId; target: PlayerId }
  | { type: 'peeked'; round: number; by: PlayerId }
  | { type: 'specialElection'; round: number; by: PlayerId; target: PlayerId }
  | { type: 'executed'; round: number; by: PlayerId; target: PlayerId }
  | { type: 'gameOver'; round: number; winner: Team; reason: WinReason };

export interface Investigation {
  by: PlayerId;
  target: PlayerId;
  team: Team;
}

export interface GameState {
  players: Player[];
  phase: Phase;
  /** رقم الجولة، يزيد مع كل ترشيح جديد. */
  round: number;
  presidentId: PlayerId;
  /** المقعد اللي يرجع له الدور بعد الانتخاب الخاص. */
  rotationSeat: number;
  nomineeId: PlayerId | null;
  votes: Record<PlayerId, boolean>;
  lastElected: Government | null;
  electionTracker: number;
  drawPile: Policy[];
  discardPile: Policy[];
  /** الكروت اللي بيد الرئيس أو المستشار حالياً (سرية). */
  hand: Policy[];
  /** الكرت المكشوف للرئيس في قدرة التلصص (سري). */
  peeked: Policy[] | null;
  loyalPolicies: number;
  traitorPolicies: number;
  vetoRejectedThisRound: boolean;
  pendingPower: Power | null;
  /** آخر حكومة مررت قرار، ولها حق الادعاء. */
  lastLegislature: { round: number; government: Government; claimed: PlayerId[] } | null;
  investigations: Investigation[];
  winner: Team | null;
  winReason: WinReason | null;
  log: GameEvent[];
  rngState: number;
}

export type Action =
  | { type: 'nominate'; chancellor: PlayerId }
  | { type: 'vote'; ja: boolean }
  | { type: 'discard'; index: number }
  | { type: 'enact'; index: number }
  | { type: 'proposeVeto' }
  | { type: 'respondVeto'; accept: boolean }
  | { type: 'claim'; policies: Policy[] }
  | { type: 'investigate'; target: PlayerId }
  | { type: 'acknowledgePeek' }
  | { type: 'specialElection'; target: PlayerId }
  | { type: 'execute'; target: PlayerId };

export class RuleError extends Error {
  constructor(public code: string, message: string) {
    super(message);
    this.name = 'RuleError';
  }
}
