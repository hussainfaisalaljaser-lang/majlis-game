import { VETO_UNLOCK, leaderKnowsTraitors } from './rules.js';
import { teamOf } from './engine.js';
import type {
  GameEvent,
  GameState,
  Investigation,
  Phase,
  PlayerId,
  Policy,
  Power,
  Role,
  Special,
  Team,
  WinReason,
} from './types.js';

/** اللي يشوفه لاعب واحد من اللعبة: كل شي عام + أسراره هو بس. هذا اللي يوصل للجوال. */
export interface PlayerView {
  you: PlayerId;
  /** نسخة المتفرج (ما فيها ولا سر). */
  spectator?: boolean;
  /** لعبة الشرح (التطبيق يطلع فيها نصايح الراوي). */
  tutorial: boolean;
  /** الوضع السريع (الوقت نص). */
  quick: boolean;
  yourRole: Role;
  /** دورك الخاص لو عندك (عرّاف أو حارس). */
  yourSpecial: Special | null;
  /** لو أنت العرّاف: الخائن اللي تعرفه. */
  seerSees: PlayerId | null;
  /** أنت العرّاف وكشفك لسا ما استخدمته. */
  seerReady: boolean;
  /** أنت القاضي، والتصويت شغال وما صوّتت، وإلغاؤك ما استخدمته. */
  judgeReady: boolean;
  /** أنت الجاسوس وما شفت الكومة للحين. */
  spyReady: boolean;
  /** لو أنت الجاسوس وشفت: أول كرت كان بالكومة، وأي جولة. */
  spySaw: { card: Policy; round: number } | null;
  players: {
    id: PlayerId;
    name: string;
    seat: number;
    alive: boolean;
    /** الدور يظهر بس لو أنت تعرفه (أعوانك، أو انتهت اللعبة). */
    knownRole: Role | null;
    /** الدور الخاص يظهر لصاحبه، وللكل لما ينكشف (الحارس نجا، القاضي ألغى، الشيخ صوّت) أو تنتهي اللعبة. */
    knownSpecial: Special | null;
    hasVoted: boolean;
  }[];
  phase: Phase;
  round: number;
  presidentId: PlayerId;
  nomineeId: PlayerId | null;
  lastElected: GameState['lastElected'];
  electionTracker: number;
  drawPileCount: number;
  /** كم بوليسة في خانة الرمي. */
  discardPileCount: number;
  loyalPolicies: number;
  traitorPolicies: number;
  pendingPower: Power | null;
  /** الكروت اللي بيدك أنت (لو أنت الرئيس أو الوزير الحين). */
  hand: Policy[];
  peeked: Policy[] | null;
  canVeto: boolean;
  /** نتائج التحقيقات اللي سويتها أنت. */
  yourInvestigations: Investigation[];
  /** تقدر تدّعي الحين؟ وكم كرت؟ ومعه الكروت اللي وصلتك فعلاً (من السيرفر، عشان تعرف وش الصدق). */
  claimable: { office: 'president' | 'chancellor'; count: number; truth: Policy[] | null } | null;
  winner: Team | null;
  winReason: WinReason | null;
  log: GameEvent[];
  /**
   * بعد نهاية اللعبة بس: الكروت الحقيقية اللي وصلت كل حكومة (الجولة ← كروت الرئيس الثلاث واللي عطاها الوزير)،
   * عشان «مين كذب؟» يقارنها بادعاءاتهم. قبل النهاية null (سر).
   */
  truths: Record<number, { president: Policy[]; chancellor: Policy[] }> | null;
}

/** الدور الخاص اللي انكشف للكل (الحارس نجا، القاضي ألغى، الشيخ صوّت)، أو كله بعد نهاية اللعبة. */
function publicSpecial(s: GameState, p: GameState['players'][number]): Special | null {
  const shown =
    s.phase === 'gameOver' ||
    (p.special === 'guardian' && s.guardianUsed) ||
    (p.special === 'judge' && s.judgeUsed) ||
    (p.special === 'elder' && s.elderShown);
  return shown ? p.special : null;
}

/** معرف المتفرج في نسخة المتفرجين. */
export const WATCHER = '_watch';

/** نسخة المتفرج (أصحاب اللاعبين): كل شي عام بس، بدون أدوار ولا كروت إلا بعد نهاية اللعبة. */
export function watchView(s: GameState): PlayerView {
  const over = s.phase === 'gameOver';
  return {
    you: WATCHER,
    spectator: true,
    tutorial: s.tutorial ?? false,
    quick: s.quick ?? false,
    yourRole: 'loyal',
    yourSpecial: null,
    seerSees: null,
    seerReady: false,
    judgeReady: false,
    spyReady: false,
    spySaw: null,
    players: s.players.map((p) => ({
      id: p.id,
      name: p.name,
      seat: p.seat,
      alive: p.alive,
      knownRole: over ? p.role : null,
      knownSpecial: publicSpecial(s, p),
      hasVoted: p.id in s.votes,
    })),
    phase: s.phase,
    round: s.round,
    presidentId: s.presidentId,
    nomineeId: s.nomineeId,
    lastElected: s.lastElected,
    electionTracker: s.electionTracker,
    drawPileCount: s.drawPile.length,
    discardPileCount: s.discardPile.length,
    loyalPolicies: s.loyalPolicies,
    traitorPolicies: s.traitorPolicies,
    pendingPower: s.pendingPower,
    hand: [],
    peeked: null,
    canVeto: s.phase === 'chancellorEnact' && s.traitorPolicies >= VETO_UNLOCK && !s.vetoRejectedThisRound,
    yourInvestigations: [],
    claimable: null,
    winner: s.winner,
    winReason: s.winReason,
    log: s.log,
    truths: over ? structuredClone(s.hands ?? {}) : null,
  };
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
  // المطرود ما يتكلم، فما يدّعي.
  if (leg && !over && me.alive && !leg.claimed.includes(playerId)) {
    const drawn = s.hands?.[leg.round];
    const truth = (cards: Policy[] | undefined, count: number) => (cards?.length === count ? [...cards] : null);
    if (leg.government.president === playerId) {
      claimable = { office: 'president', count: 3, truth: truth(drawn?.president, 3) };
    } else if (leg.government.chancellor === playerId) {
      claimable = { office: 'chancellor', count: 2, truth: truth(drawn?.chancellor, 2) };
    }
  }

  return {
    you: playerId,
    tutorial: s.tutorial ?? false,
    quick: s.quick ?? false,
    yourRole: me.role,
    yourSpecial: me.special,
    seerSees: me.special === 'seer' ? s.seerSees : null,
    seerReady: me.special === 'seer' && me.alive && !over && s.seerSees === null,
    judgeReady:
      me.special === 'judge' &&
      me.alive &&
      s.phase === 'election' &&
      !s.judgeUsed &&
      !s.judgeCancel &&
      !(playerId in s.votes),
    spyReady: me.special === 'spy' && me.alive && !over && !s.spySaw,
    spySaw: me.special === 'spy' ? (s.spySaw ?? null) : null,
    players: s.players.map((p) => ({
      id: p.id,
      name: p.name,
      seat: p.seat,
      alive: p.alive,
      knownRole:
        p.id === playerId || knows(p.role)
          ? p.role
          : me.special === 'seer' && s.seerSees === p.id
            ? // العرّاف يعرف الفريق بس: الزعيم يطلع له خائن.
              teamOf(p.role) === 'loyal' ? 'loyal' : 'traitor'
            : null,
      knownSpecial: p.id === playerId ? p.special : publicSpecial(s, p),
      hasVoted: p.id in s.votes,
    })),
    phase: s.phase,
    round: s.round,
    presidentId: s.presidentId,
    nomineeId: s.nomineeId,
    lastElected: s.lastElected,
    electionTracker: s.electionTracker,
    drawPileCount: s.drawPile.length,
    discardPileCount: s.discardPile.length,
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
    truths: over ? structuredClone(s.hands ?? {}) : null,
  };
}
