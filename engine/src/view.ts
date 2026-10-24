import { VETO_UNLOCK, leaderKnowsTraitors } from './rules.js';
import type {
  GameEvent,
  GameState,
  Investigation,
  Phase,
  PlayerId,
  Policy,
  Power,
  Role,
  Team,
  WinReason,
} from './types.js';

/** اللي يشوفه لاعب واحد من اللعبة: كل شي عام + أسراره هو بس. هذا اللي يوصل للجوال. */
export interface PlayerView {
  you: PlayerId;
  yourRole: Role;
  players: {
    id: PlayerId;
    name: string;
    seat: number;
    alive: boolean;
    /** الدور يظهر بس لو أنت تعرفه (أعوانك، أو انتهت اللعبة). */
    knownRole: Role | null;
    hasVoted: boolean;
  }[];
  phase: Phase;
  round: number;
  presidentId: PlayerId;
  nomineeId: PlayerId | null;
  lastElected: GameState['lastElected'];
  electionTracker: number;
  drawPileCount: number;
  loyalPolicies: number;
  traitorPolicies: number;
  pendingPower: Power | null;
  /** الكروت اللي بيدك أنت (لو أنت الرئيس أو المستشار الحين). */
  hand: Policy[];
  peeked: Policy[] | null;
  canVeto: boolean;
  /** نتائج التحقيقات اللي سويتها أنت. */
  yourInvestigations: Investigation[];
  /** تقدر تدّعي الحين؟ وكم كرت؟ */
  claimable: { office: 'president' | 'chancellor'; count: number } | null;
  winner: Team | null;
  winReason: WinReason | null;
  log: GameEvent[];
}

export function viewFor(s: GameState, playerId: PlayerId): PlayerView {
  const me = s.players.find((p) => p.id === playerId);
  if (!me) throw new Error(`unknown player ${playerId}`);
  const over = s.phase === 'gameOver';

  const knows = (role: Role): boolean => {
    if (over) return true;
    if (me.role === 'traitor') return role !== 'loyal';
    if (me.role === 'leader') return role === 'traitor' && leaderKnowsTraitors(s.players.length);
    return false;
  };

  const handVisible =
    (s.phase === 'presidentDiscard' && s.presidentId === playerId) ||
    ((s.phase === 'chancellorEnact' || s.phase === 'vetoResponse') &&
      (s.nomineeId === playerId || (s.phase === 'vetoResponse' && s.presidentId === playerId)));

  const leg = s.lastLegislature;
  let claimable: PlayerView['claimable'] = null;
  if (leg && !over && !leg.claimed.includes(playerId)) {
    if (leg.government.president === playerId) claimable = { office: 'president', count: 3 };
    else if (leg.government.chancellor === playerId) claimable = { office: 'chancellor', count: 2 };
  }

  return {
    you: playerId,
    yourRole: me.role,
    players: s.players.map((p) => ({
      id: p.id,
      name: p.name,
      seat: p.seat,
      alive: p.alive,
      knownRole: p.id === playerId || knows(p.role) ? p.role : null,
      hasVoted: p.id in s.votes,
    })),
    phase: s.phase,
    round: s.round,
    presidentId: s.presidentId,
    nomineeId: s.nomineeId,
    lastElected: s.lastElected,
    electionTracker: s.electionTracker,
    drawPileCount: s.drawPile.length,
    loyalPolicies: s.loyalPolicies,
    traitorPolicies: s.traitorPolicies,
    pendingPower: s.pendingPower,
    hand: handVisible ? [...s.hand] : [],
    peeked: s.presidentId === playerId ? s.peeked : null,
    canVeto: s.phase === 'chancellorEnact' && s.traitorPolicies >= VETO_UNLOCK && !s.vetoRejectedThisRound,
    yourInvestigations: s.investigations.filter((i) => i.by === playerId),
    claimable,
    winner: s.winner,
    winReason: s.winReason,
    log: s.log,
  };
}
