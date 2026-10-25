import {
  DECK,
  LEADER_DANGER_ZONE,
  LOYAL_TO_WIN,
  MAX_FAILED_ELECTIONS,
  MAX_PLAYERS,
  MIN_PLAYERS,
  TRAITOR_TO_WIN,
  VETO_UNLOCK,
  powerFor,
  traitorCount,
} from './rules.js';
import { shuffle } from './rng.js';
import {
  RuleError,
  type Action,
  type GameState,
  type Player,
  type PlayerId,
  type Policy,
  type Role,
  type Team,
  type WinReason,
} from './types.js';

export function teamOf(role: Role): Team {
  return role === 'loyal' ? 'loyal' : 'traitor';
}

/** ينشئ لعبة جديدة: يوزع الأدوار ويخلط الكروت ويختار أول رئيس عشوائياً. */
export function createGame(
  players: { id: PlayerId; name: string }[],
  seed: number,
): GameState {
  if (players.length < MIN_PLAYERS || players.length > MAX_PLAYERS) {
    throw new RuleError('playerCount', `عدد اللاعبين لازم يكون بين ${MIN_PLAYERS} و ${MAX_PLAYERS}`);
  }
  if (new Set(players.map((p) => p.id)).size !== players.length) {
    throw new RuleError('duplicatePlayer', 'فيه لاعب مكرر');
  }

  const roles: Role[] = ['leader'];
  for (let i = 0; i < traitorCount(players.length); i++) roles.push('traitor');
  while (roles.length < players.length) roles.push('loyal');

  let rng = seed | 0;
  let shuffledRoles: Role[];
  [shuffledRoles, rng] = shuffle(roles, rng);

  const deck: Policy[] = [
    ...Array<Policy>(DECK.L).fill('L'),
    ...Array<Policy>(DECK.T).fill('T'),
  ];
  let drawPile: Policy[];
  [drawPile, rng] = shuffle(deck, rng);

  let order: number[];
  [order, rng] = shuffle(players.map((_, i) => i), rng);
  const firstSeat = order[0];

  const seated: Player[] = players.map((p, seat) => ({
    id: p.id,
    name: p.name,
    seat,
    role: shuffledRoles[seat],
    special: null,
    alive: true,
  }));

  // الأدوار الخاصة: عرّاف وحارس من الأوفياء. العرّاف ما يعرف أحد في البداية، ويختار متى يكشف.
  let loyalSeats: number[];
  [loyalSeats, rng] = shuffle(seated.filter((p) => p.role === 'loyal').map((p) => p.seat), rng);
  const seer = seated[loyalSeats[0]];
  const guardian = seated[loyalSeats[1]];
  seer.special = 'seer';
  guardian.special = 'guardian';

  return {
    players: seated,
    phase: 'nomination',
    round: 1,
    presidentId: seated[firstSeat].id,
    rotationSeat: firstSeat,
    nomineeId: null,
    votes: {},
    lastElected: null,
    electionTracker: 0,
    drawPile,
    discardPile: [],
    hand: [],
    peeked: null,
    loyalPolicies: 0,
    traitorPolicies: 0,
    vetoRejectedThisRound: false,
    pendingPower: null,
    lastLegislature: null,
    investigations: [],
    seerSees: null,
    guardianUsed: false,
    winner: null,
    winReason: null,
    log: [],
    rngState: rng,
  };
}

/** يطبق حركة لاعب ويرجع حالة جديدة. يرمي RuleError لو الحركة مو مسموحة. */
export function applyAction(state: GameState, playerId: PlayerId, action: Action): GameState {
  const s: GameState = structuredClone(state);
  const actor = s.players.find((p) => p.id === playerId);
  if (!actor) throw new RuleError('unknownPlayer', 'اللاعب مو موجود في هذي اللعبة');
  if (s.phase === 'gameOver') throw new RuleError('gameOver', 'اللعبة انتهت');
  if (!actor.alive) throw new RuleError('dead', 'اللاعب المطرود ما يقدر يلعب');

  switch (action.type) {
    case 'seerReveal': {
      if (actor.special !== 'seer') throw new RuleError('notSeer', 'بس العرّاف يقدر يكشف');
      if (s.seerSees !== null) throw new RuleError('seerUsed', 'استخدمت كشفك من قبل');
      const target = requireTarget(s, playerId, action.target);
      // سري: ما ينكتب في السجل العام عشان العرّاف ما ينكشف.
      s.seerSees = target.id;
      return s;
    }

    case 'nominate': {
      requirePhase(s, 'nomination');
      requirePresident(s, playerId);
      if (!eligibleChancellors(s).includes(action.chancellor)) {
        throw new RuleError('ineligible', 'هذا اللاعب ما يقدر يكون وزير هالجولة');
      }
      s.nomineeId = action.chancellor;
      s.votes = {};
      s.phase = 'election';
      s.log.push({ type: 'nominated', round: s.round, president: s.presidentId, chancellor: action.chancellor });
      return s;
    }

    case 'vote': {
      requirePhase(s, 'election');
      if (playerId in s.votes) throw new RuleError('alreadyVoted', 'صوّتت من قبل');
      s.votes[playerId] = action.ja;
      if (Object.keys(s.votes).length === alivePlayers(s).length) resolveElection(s);
      return s;
    }

    case 'discard': {
      requirePhase(s, 'presidentDiscard');
      requirePresident(s, playerId);
      requireIndex(s.hand, action.index);
      s.discardPile.push(...s.hand.splice(action.index, 1));
      s.phase = 'chancellorEnact';
      return s;
    }

    case 'enact': {
      requirePhase(s, 'chancellorEnact');
      requireChancellor(s, playerId);
      requireIndex(s.hand, action.index);
      const [policy] = s.hand.splice(action.index, 1);
      s.discardPile.push(...s.hand);
      s.hand = [];
      const government = { president: s.presidentId, chancellor: s.nomineeId! };
      s.lastLegislature = { round: s.round, government, claimed: [] };
      enactPolicy(s, policy, false, government);
      return s;
    }

    case 'proposeVeto': {
      requirePhase(s, 'chancellorEnact');
      requireChancellor(s, playerId);
      if (s.traitorPolicies < VETO_UNLOCK) throw new RuleError('vetoLocked', 'الفيتو ما انفتح للحين');
      if (s.vetoRejectedThisRound) throw new RuleError('vetoRejected', 'الرئيس رفض الفيتو، لازم تمرر قرار');
      s.phase = 'vetoResponse';
      return s;
    }

    case 'respondVeto': {
      requirePhase(s, 'vetoResponse');
      requirePresident(s, playerId);
      if (!action.accept) {
        s.vetoRejectedThisRound = true;
        s.phase = 'chancellorEnact';
        s.log.push({ type: 'vetoRejected', round: s.round });
        return s;
      }
      s.discardPile.push(...s.hand);
      s.hand = [];
      s.log.push({ type: 'vetoed', round: s.round, government: { president: s.presidentId, chancellor: s.nomineeId! } });
      failGovernment(s);
      return s;
    }

    case 'claim': {
      const leg = s.lastLegislature;
      if (!leg) throw new RuleError('noLegislature', 'ما فيه حكومة تقدر تدّعي');
      const office =
        leg.government.president === playerId ? 'president'
        : leg.government.chancellor === playerId ? 'chancellor'
        : null;
      if (!office) throw new RuleError('notInGovernment', 'بس الرئيس والوزير يقدرون يدّعون');
      if (leg.claimed.includes(playerId)) throw new RuleError('alreadyClaimed', 'ادّعيت من قبل');
      const expected = office === 'president' ? 3 : 2;
      if (action.policies.length !== expected || action.policies.some((p) => p !== 'L' && p !== 'T')) {
        throw new RuleError('badClaim', `الادعاء لازم يكون ${expected} كروت`);
      }
      leg.claimed.push(playerId);
      s.log.push({ type: 'claim', round: leg.round, claim: { by: playerId, office, policies: [...action.policies] } });
      return s;
    }

    case 'investigate': {
      requirePower(s, playerId, 'investigate');
      const target = requireTarget(s, playerId, action.target);
      if (s.investigations.some((i) => i.target === target.id)) {
        throw new RuleError('alreadyInvestigated', 'هذا اللاعب انكشف من قبل');
      }
      s.investigations.push({ by: playerId, target: target.id, team: teamOf(target.role) });
      s.log.push({ type: 'investigated', round: s.round, by: playerId, target: target.id });
      finishPower(s);
      return s;
    }

    case 'acknowledgePeek': {
      requirePower(s, playerId, 'peek');
      s.peeked = null;
      s.log.push({ type: 'peeked', round: s.round, by: playerId });
      finishPower(s);
      return s;
    }

    case 'specialElection': {
      requirePower(s, playerId, 'specialElection');
      const target = requireTarget(s, playerId, action.target);
      s.log.push({ type: 'specialElection', round: s.round, by: playerId, target: target.id });
      s.pendingPower = null;
      // الدور يرجع بعدين للي بعد الرئيس الحالي، مو للي بعد المنتخب.
      s.rotationSeat = actorSeat(s, playerId);
      startRound(s, target.id);
      return s;
    }

    case 'execute': {
      requirePower(s, playerId, 'execute');
      const target = requireTarget(s, playerId, action.target);
      if (target.special === 'guardian' && !s.guardianUsed) {
        // الحارس ينجو مرة وحدة وينكشف للكل.
        s.guardianUsed = true;
        s.log.push({ type: 'guarded', round: s.round, by: playerId, target: target.id });
        finishPower(s);
        return s;
      }
      target.alive = false;
      s.log.push({ type: 'executed', round: s.round, by: playerId, target: target.id });
      if (target.role === 'leader') return endGame(s, 'loyal', 'leaderExecuted');
      finishPower(s);
      return s;
    }
  }
}

/** اللاعبين اللي يقدر الرئيس يرشحهم كوزير. */
export function eligibleChancellors(s: GameState): PlayerId[] {
  const alive = alivePlayers(s);
  return alive
    .filter((p) => p.id !== s.presidentId)
    .filter((p) => p.id !== s.lastElected?.chancellor)
    .filter((p) => alive.length <= 5 || p.id !== s.lastElected?.president)
    .map((p) => p.id);
}

export function alivePlayers(s: GameState): Player[] {
  return s.players.filter((p) => p.alive);
}

function resolveElection(s: GameState): void {
  const ja = Object.values(s.votes).filter(Boolean).length;
  const passed = ja > alivePlayers(s).length / 2;
  s.log.push({ type: 'voteResult', round: s.round, votes: { ...s.votes }, passed });
  if (!passed) {
    failGovernment(s);
    return;
  }

  s.electionTracker = 0;
  s.lastElected = { president: s.presidentId, chancellor: s.nomineeId! };
  const chancellor = s.players.find((p) => p.id === s.nomineeId)!;
  if (s.traitorPolicies >= LEADER_DANGER_ZONE && chancellor.role === 'leader') {
    endGame(s, 'traitor', 'leaderElected');
    return;
  }
  ensureDeck(s, 3);
  s.hand = s.drawPile.splice(0, 3);
  s.phase = 'presidentDiscard';
}

/** حكومة فشلت (تصويت أو فيتو): يزيد العداد، ولو وصل ٣ يتمرر أول قرار تلقائياً. */
function failGovernment(s: GameState): void {
  s.electionTracker++;
  if (s.electionTracker >= MAX_FAILED_ELECTIONS) {
    ensureDeck(s, 1);
    const policy = s.drawPile.shift()!;
    s.electionTracker = 0;
    s.lastElected = null;
    enactPolicy(s, policy, true);
    return;
  }
  advancePresident(s);
}

function enactPolicy(s: GameState, policy: Policy, chaos: boolean, government?: { president: PlayerId; chancellor: PlayerId }): void {
  if (policy === 'L') s.loyalPolicies++;
  else s.traitorPolicies++;
  s.log.push({ type: 'enacted', round: s.round, policy, chaos, ...(government ? { government } : {}) });
  if (!chaos) s.electionTracker = 0;

  if (s.loyalPolicies >= LOYAL_TO_WIN) return void endGame(s, 'loyal', 'loyalPolicies');
  if (s.traitorPolicies >= TRAITOR_TO_WIN) return void endGame(s, 'traitor', 'traitorPolicies');

  ensureDeck(s, 3);
  const power = !chaos && policy === 'T' ? powerFor(s.players.length, s.traitorPolicies) : null;
  if (power) {
    s.pendingPower = power;
    s.phase = 'power';
    if (power === 'peek') s.peeked = s.drawPile.slice(0, 3);
    return;
  }
  advancePresident(s);
}

function finishPower(s: GameState): void {
  s.pendingPower = null;
  advancePresident(s);
}

function advancePresident(s: GameState): void {
  const n = s.players.length;
  let seat = s.rotationSeat;
  do seat = (seat + 1) % n;
  while (!s.players[seat].alive);
  s.rotationSeat = seat;
  startRound(s, s.players[seat].id);
}

function startRound(s: GameState, presidentId: PlayerId): void {
  s.round++;
  s.presidentId = presidentId;
  s.nomineeId = null;
  s.votes = {};
  s.hand = [];
  s.vetoRejectedThisRound = false;
  s.phase = 'nomination';
}

/** لو الكروت المتبقية أقل من المطلوب، نخلط المرمية معها. */
function ensureDeck(s: GameState, needed: number): void {
  if (s.drawPile.length >= needed) return;
  const [shuffled, rng] = shuffle([...s.drawPile, ...s.discardPile], s.rngState);
  s.drawPile = shuffled;
  s.discardPile = [];
  s.rngState = rng;
}

function endGame(s: GameState, winner: Team, reason: WinReason): GameState {
  s.phase = 'gameOver';
  s.winner = winner;
  s.winReason = reason;
  s.pendingPower = null;
  s.hand = [];
  s.log.push({ type: 'gameOver', round: s.round, winner, reason });
  return s;
}

function actorSeat(s: GameState, id: PlayerId): number {
  return s.players.find((p) => p.id === id)!.seat;
}

function requirePhase(s: GameState, phase: GameState['phase']): void {
  if (s.phase !== phase) throw new RuleError('wrongPhase', 'هذي الحركة مو وقتها');
}

function requirePresident(s: GameState, id: PlayerId): void {
  if (s.presidentId !== id) throw new RuleError('notPresident', 'بس الرئيس يقدر يسوي هذا');
}

function requireChancellor(s: GameState, id: PlayerId): void {
  if (s.nomineeId !== id) throw new RuleError('notChancellor', 'بس الوزير يقدر يسوي هذا');
}

function requirePower(s: GameState, id: PlayerId, power: GameState['pendingPower']): void {
  requirePhase(s, 'power');
  requirePresident(s, id);
  if (s.pendingPower !== power) throw new RuleError('wrongPower', 'هذي القدرة مو متاحة الحين');
}

function requireIndex(hand: Policy[], index: number): void {
  if (!Number.isInteger(index) || index < 0 || index >= hand.length) {
    throw new RuleError('badIndex', 'اختيار كرت غلط');
  }
}

function requireTarget(s: GameState, actorId: PlayerId, targetId: PlayerId): Player {
  const target = s.players.find((p) => p.id === targetId);
  if (!target || !target.alive || target.id === actorId) {
    throw new RuleError('badTarget', 'ما تقدر تختار هذا اللاعب');
  }
  return target;
}
