import { alivePlayers, eligibleChancellors, teamOf } from './engine.js';
import { LEADER_DANGER_ZONE, leaderKnowsTraitors } from './rules.js';
import type { Action, GameState, Player, PlayerId, Policy } from './types.js';

/**
 * عقل البوت: يلعب بس من اللي يعرفه (دوره، وأعوانه لو خائن، والسجل العام، وتحقيقاته).
 * الوفي يحاول يتجنب اللي مرّروا قرارات حمرا، والخائن يساعد فريقه ويكذب في الادعاءات.
 */

type Rand = () => number;

const pick = <T>(xs: T[], rand: Rand): T => xs[Math.floor(rand() * xs.length)];

function me(s: GameState, id: PlayerId): Player {
  return s.players.find((p) => p.id === id)!;
}

/** هل البوت يعرف إن هذا اللاعب من فريق الخونة؟ */
function knownTraitor(s: GameState, botId: PlayerId, target: PlayerId): boolean {
  const bot = me(s, botId);
  const t = me(s, target);
  if (bot.special === 'seer' && s.seerSees === target) return true;
  if (bot.role === 'traitor') return t.role !== 'loyal';
  if (bot.role === 'leader' && leaderKnowsTraitors(s.players.length)) return t.role === 'traitor';
  return s.investigations.some((i) => i.by === botId && i.target === target && i.team === 'traitor');
}

function knownLoyal(s: GameState, botId: PlayerId, target: PlayerId): boolean {
  if (target === botId) return me(s, botId).role === 'loyal';
  // الحارس اللي انكشف وفي أكيد.
  if (s.guardianUsed && me(s, target).special === 'guardian') return true;
  const bot = me(s, botId);
  if (bot.role === 'traitor' || (bot.role === 'leader' && leaderKnowsTraitors(s.players.length))) {
    return me(s, target).role === 'loyal';
  }
  return s.investigations.some((i) => i.by === botId && i.target === target && i.team === 'loyal');
}

/** درجة الشك من السجل العام: كل حكومة مررت أحمر تزيد الشك، والأزرق ينقصه. */
export function suspicion(s: GameState, botId: PlayerId, target: PlayerId): number {
  if (knownTraitor(s, botId, target)) return 100;
  if (knownLoyal(s, botId, target)) return -100;
  let score = 0;
  for (const e of s.log) {
    if (e.type === 'enacted' && e.government) {
      const inGov = e.government.president === target || e.government.chancellor === target;
      if (inGov) score += e.policy === 'T' ? 1 : -0.6;
    }
  }
  return score;
}

const isTraitorTeam = (p: Player) => teamOf(p.role) === 'traitor';

function nominate(s: GameState, botId: PlayerId, rand: Rand): PlayerId {
  const bot = me(s, botId);
  const options = eligibleChancellors(s);
  if (isTraitorTeam(bot)) {
    const leader = options.find((id) => me(s, id).role === 'leader');
    if (leader && s.traitorPolicies >= LEADER_DANGER_ZONE) return leader;
    const mates = options.filter((id) => knownTraitor(s, botId, id));
    if (mates.length && rand() < 0.6) return pick(mates, rand);
    return pick(options, rand);
  }
  const ranked = [...options].sort((a, b) => suspicion(s, botId, a) - suspicion(s, botId, b));
  const best = suspicion(s, botId, ranked[0]);
  return pick(ranked.filter((id) => suspicion(s, botId, id) <= best + 0.5), rand);
}

function vote(s: GameState, botId: PlayerId, rand: Rand): boolean {
  const bot = me(s, botId);
  const gov = [s.presidentId, s.nomineeId!];
  const nominee = me(s, s.nomineeId!);
  if (isTraitorTeam(bot)) {
    if (nominee.role === 'leader' && s.traitorPolicies >= LEADER_DANGER_ZONE) return true;
    if (gov.some((id) => knownTraitor(s, botId, id) || id === botId)) return true;
    return rand() < 0.45;
  }
  if (gov.includes(botId)) return true;
  // الزعيم كمستشار بعد ٣ حمر = خسارة، فالوفي يرفض أي أحد مشكوك فيه.
  const worst = Math.max(...gov.map((id) => suspicion(s, botId, id)));
  if (s.electionTracker === 2 && worst < 2) return true;
  if (s.traitorPolicies >= LEADER_DANGER_ZONE && suspicion(s, botId, nominee.id) > 0) return false;
  return worst < 1 ? rand() < 0.85 : rand() < 0.2;
}

/** يختار كرت يرميه (الرئيس) أو يمرره (المستشار). */
function chooseCard(s: GameState, botId: PlayerId, hand: Policy[], keepWanted: boolean, rand: Rand): number {
  const wants: Policy = isTraitorTeam(me(s, botId)) ? 'T' : 'L';
  // الخائن أحياناً يمرر أزرق عشان ما ينكشف.
  const honest = wants === 'L' || rand() < 0.8;
  const target = honest ? wants : wants === 'T' ? 'L' : 'T';
  const want = keepWanted ? target : target === 'T' ? 'L' : 'T';
  const idx = hand.indexOf(want);
  return idx >= 0 ? idx : Math.floor(rand() * hand.length);
}

function choosePowerTarget(s: GameState, botId: PlayerId, rand: Rand, mode: 'investigate' | 'elect' | 'execute'): PlayerId {
  const bot = me(s, botId);
  let others = alivePlayers(s).filter((p) => p.id !== botId).map((p) => p.id);
  if (mode === 'investigate') {
    const fresh = others.filter((id) => !s.investigations.some((i) => i.target === id));
    if (fresh.length) others = fresh;
  }
  if (isTraitorTeam(bot)) {
    const mates = others.filter((id) => knownTraitor(s, botId, id));
    const enemies = others.filter((id) => !knownTraitor(s, botId, id));
    if (mode === 'elect' && mates.length) return pick(mates, rand);
    if (mode === 'execute') return pick(enemies.length ? enemies : others, rand);
    return pick(enemies.length ? enemies : others, rand);
  }
  const ranked = [...others].sort((a, b) => suspicion(s, botId, b) - suspicion(s, botId, a));
  return mode === 'elect' ? ranked[ranked.length - 1] : ranked[0];
}

/** الادعاء بعد الحكم: الوفي يقول الصدق، والخائن يغطي على نفسه بإنه "ما جاه إلا أحمر". */
export function botClaim(s: GameState, botId: PlayerId, office: 'president' | 'chancellor', rand: Rand): Policy[] {
  const n = office === 'president' ? 3 : 2;
  const enacted = [...s.log].reverse().find((e) => e.type === 'enacted' && !e.chaos);
  const policy = enacted?.type === 'enacted' ? enacted.policy : 'T';
  if (!isTraitorTeam(me(s, botId))) {
    // الوفي ما يتذكر الكروت بالضبط هنا، فيدّعي شي منطقي مع اللي تمرر.
    if (policy === 'T') return Array<Policy>(n).fill('T');
    return n === 3 ? (rand() < 0.5 ? ['L', 'T', 'T'] : ['L', 'L', 'T']) : rand() < 0.5 ? ['L', 'T'] : ['L', 'L'];
  }
  if (policy === 'T') return Array<Policy>(n).fill('T');
  return n === 3 ? ['L', 'T', 'T'] : ['L', 'T'];
}

/** الحركة اللي يسويها البوت لو عليه الدور، أو null. */
export function botAction(s: GameState, botId: PlayerId, rand: Rand = Math.random): Action | null {
  const bot = me(s, botId);
  if (!bot.alive || s.phase === 'gameOver') return null;
  const isPres = s.presidentId === botId;
  switch (s.phase) {
    case 'nomination':
      return isPres ? { type: 'nominate', chancellor: nominate(s, botId, rand) } : null;
    case 'election':
      return botId in s.votes ? null : { type: 'vote', ja: vote(s, botId, rand) };
    case 'presidentDiscard':
      return isPres ? { type: 'discard', index: chooseCard(s, botId, s.hand, false, rand) } : null;
    case 'chancellorEnact': {
      if (s.nomineeId !== botId) return null;
      const loyal = !isTraitorTeam(bot);
      if (s.traitorPolicies >= 5 && !s.vetoRejectedThisRound && loyal && s.hand.every((c) => c === 'T')) {
        return { type: 'proposeVeto' };
      }
      return { type: 'enact', index: chooseCard(s, botId, s.hand, true, rand) };
    }
    case 'vetoResponse':
      return isPres ? { type: 'respondVeto', accept: !isTraitorTeam(bot) } : null;
    case 'power':
      if (!isPres) return null;
      switch (s.pendingPower) {
        case 'peek':
          return { type: 'acknowledgePeek' };
        case 'investigate':
          return { type: 'investigate', target: choosePowerTarget(s, botId, rand, 'investigate') };
        case 'specialElection':
          return { type: 'specialElection', target: choosePowerTarget(s, botId, rand, 'elect') };
        case 'execute':
          return { type: 'execute', target: choosePowerTarget(s, botId, rand, 'execute') };
        default:
          return null;
      }
    default:
      return null;
  }
}

/** اللاعبين اللي عليهم الدور الحين. */
export function currentActors(s: GameState): PlayerId[] {
  switch (s.phase) {
    case 'nomination':
    case 'presidentDiscard':
    case 'vetoResponse':
    case 'power':
      return [s.presidentId];
    case 'chancellorEnact':
      return [s.nomineeId!];
    case 'election':
      return alivePlayers(s).filter((p) => !(p.id in s.votes)).map((p) => p.id);
    default:
      return [];
  }
}
