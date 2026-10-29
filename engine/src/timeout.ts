import { alivePlayers, eligibleChancellors } from './engine.js';
import type { Action, GameState, PlayerId } from './types.js';

/**
 * الحركات اللي يسويها السيرفر بدال اللاعب اللي خلص وقته.
 * التصويت الافتراضي رفض، والنقض يترفض، وباقي الاختيارات عشوائية.
 */
export function timeoutActions(s: GameState, random: () => number): [PlayerId, Action][] {
  const pick = <T>(xs: T[]): T => xs[Math.floor(random() * xs.length)];
  const others = alivePlayers(s).filter((p) => p.id !== s.presidentId).map((p) => p.id);
  switch (s.phase) {
    case 'nomination':
      return [[s.presidentId, { type: 'nominate', chancellor: pick(eligibleChancellors(s)) }]];
    case 'election':
      return alivePlayers(s)
        .filter((p) => !(p.id in s.votes))
        .map((p) => [p.id, { type: 'vote', ja: false }]);
    case 'presidentDiscard':
      return [[s.presidentId, { type: 'discard', index: Math.floor(random() * s.hand.length) }]];
    case 'chancellorEnact':
      return [[s.nomineeId!, { type: 'enact', index: Math.floor(random() * s.hand.length) }]];
    case 'vetoResponse':
      return [[s.presidentId, { type: 'respondVeto', accept: false }]];
    case 'power':
      switch (s.pendingPower) {
        case 'peek':
          return [[s.presidentId, { type: 'acknowledgePeek' }]];
        case 'investigate': {
          const fresh = others.filter((id) => !s.investigations.some((i) => i.target === id));
          return [[s.presidentId, { type: 'investigate', target: pick(fresh.length ? fresh : others) }]];
        }
        case 'specialElection':
          return [[s.presidentId, { type: 'specialElection', target: pick(others) }]];
        case 'execute':
          return [[s.presidentId, { type: 'execute', target: pick(others) }]];
        default:
          return [];
      }
    default:
      return [];
  }
}

/** مفتاح الدور الحالي. لما يتغير، المؤقت يبدأ من جديد (التصويت الواحد ما يغيره). */
export function turnKey(s: GameState): string {
  return `${s.round}:${s.phase}:${s.pendingPower ?? ''}:${s.vetoRejectedThisRound}`;
}
