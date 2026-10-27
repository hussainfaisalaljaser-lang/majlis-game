import { alivePlayers, eligibleChancellors, teamOf } from './engine.js';
import { LEADER_DANGER_ZONE, leaderKnowsTraitors } from './rules.js';
import type { Action, Claim, GameState, Government, Player, PlayerId, Policy } from './types.js';

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
  if (bot.special === 'seer' && s.seerSees === target) return teamOf(t.role) === 'traitor';
  if (bot.role === 'traitor') return t.role !== 'loyal';
  if (bot.role === 'leader' && leaderKnowsTraitors(s.players.length)) return t.role === 'traitor';
  return s.investigations.some((i) => i.by === botId && i.target === target && i.team === 'traitor');
}

function knownLoyal(s: GameState, botId: PlayerId, target: PlayerId): boolean {
  if (target === botId) return me(s, botId).role === 'loyal';
  // الحارس اللي انكشف وفي أكيد.
  if (s.guardianUsed && me(s, target).special === 'guardian') return true;
  const bot = me(s, botId);
  if (bot.special === 'seer' && s.seerSees === target) return teamOf(me(s, target).role) === 'loyal';
  if (bot.role === 'traitor' || (bot.role === 'leader' && leaderKnowsTraitors(s.players.length))) {
    return me(s, target).role === 'loyal';
  }
  return s.investigations.some((i) => i.by === botId && i.target === target && i.team === 'loyal');
}

/**
 * العرّاف البوت: من الجولة الثانية يكشف أكثر واحد يشك فيه (ولو تعادلوا، عشوائي).
 * يرجع null لو ما هو عرّاف أو استخدم كشفه.
 */
export function botSeerReveal(s: GameState, botId: PlayerId, rand: Rand = Math.random): PlayerId | null {
  const bot = me(s, botId);
  if (bot.special !== 'seer' || !bot.alive || s.seerSees !== null || s.phase === 'gameOver' || s.round < 2) return null;
  const others = alivePlayers(s).filter((p) => p.id !== botId);
  if (others.length === 0) return null;
  const top = Math.max(...others.map((p) => suspicion(s, botId, p.id)));
  return pick(others.filter((p) => suspicion(s, botId, p.id) === top), rand).id;
}

/**
 * القاضي البوت: يلغي التصويت بدال ما يصوّت؟ الوفي يلغي حكومة فيها أحد مشكوك فيه كثير (أو الزعيم ممكن يفوز فيها)،
 * والخاين يلغي حكومة وفية لما الأوفياء قربوا يفوزون.
 */
function wantsJudgeCancel(s: GameState, botId: PlayerId, rand: Rand): boolean {
  const bot = me(s, botId);
  if (bot.special !== 'judge' || s.judgeUsed || s.judgeCancel || s.tutorial) return false;
  const gov = [s.presidentId, s.nomineeId!];
  if (gov.includes(botId)) return false;
  if (isTraitorTeam(bot)) {
    if (gov.some((id) => knownTraitor(s, botId, id))) return false;
    return s.loyalPolicies >= 3 && rand() < 0.7;
  }
  if (s.traitorPolicies >= LEADER_DANGER_ZONE && suspicion(s, botId, s.nomineeId!) > 1) return true;
  const worst = Math.max(...gov.map((id) => suspicion(s, botId, id)));
  return worst >= 6 || (worst >= 3 && s.traitorPolicies >= 3 && rand() < 0.6);
}

/** الجاسوس البوت: يشوف الكومة مرة من الجولة الثالثة. */
export function botSpyPeek(s: GameState, botId: PlayerId, rand: Rand = Math.random): boolean {
  const bot = me(s, botId);
  return bot.special === 'spy' && bot.alive && !s.spySaw && s.phase !== 'gameOver' && s.round >= 3 && rand() < 0.5;
}

/**
 * درجة الشك من السجل العام: كل حكومة مررت أحمر تزيد الشك، والأزرق ينقصه،
 * والادعاءات اللي ما تركب مع بعض (أو مع اللي يعرفه البوت لو كان في الحكومة) تزيده.
 */
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
  return score + claimSuspicion(s, botId, target);
}

const blues = (ps: Policy[]) => ps.filter((p) => p === 'L').length;
const sameCards = (a: Policy[], b: Policy[]) => a.length === b.length && blues(a) === blues(b);

/** ادعاء الرئيس (٣) يركب مع ادعاء الوزير (٢)؟ يعني الوزير وصله نفس الثلاث ناقص كرت. */
function fits(president: Policy[], chancellor: Policy[]): boolean {
  const b = blues(president);
  const c = blues(chancellor);
  return (c === b && b <= 2) || (c === b - 1 && b >= 1);
}

/** كل حكومة مررت قرار: مين فيها، وش تمرر، ووش ادعى كل واحد. */
function legislatures(s: GameState): Map<number, { gov: Government; enacted: Policy; pres?: Claim; chan?: Claim }> {
  const out = new Map<number, { gov: Government; enacted: Policy; pres?: Claim; chan?: Claim }>();
  for (const e of s.log) {
    if (e.type === 'enacted' && e.government && !e.chaos) out.set(e.round, { gov: e.government, enacted: e.policy });
    if (e.type === 'claim') {
      const leg = out.get(e.round);
      if (leg) leg[e.claim.office === 'president' ? 'pres' : 'chan'] = e.claim;
    }
  }
  return out;
}

/**
 * الشك من الادعاءات. البوت اللي كان في الحكومة يعرف وش وصله بالضبط (s.hands)، فيكشف كذب شريكه:
 * عطيته أزرق ومرّر أحمر، أو رمى أزرق وعطاني أحمرين. وغيره يشوف بس إذا الادعاءين يتناقضون.
 */
function claimSuspicion(s: GameState, botId: PlayerId, target: PlayerId): number {
  let score = 0;
  for (const [round, leg] of legislatures(s)) {
    const { gov, enacted, pres, chan } = leg;
    if (gov.president !== target && gov.chancellor !== target) continue;
    const passed = s.hands?.[round]?.chancellor;
    if (passed?.length === 2 && gov.president === botId && target === gov.chancellor) {
      // أنا الرئيس: عطيته أزرق ومرّر أحمر، أو ادعى غير اللي عطيته.
      if (enacted === 'T' && blues(passed) > 0) score += 8;
      else if (chan && !sameCards(chan.policies, passed)) score += 6;
      else score -= 1;
      continue;
    }
    if (passed?.length === 2 && gov.chancellor === botId && target === gov.president) {
      // أنا الوزير: ادعاؤه ما يركب مع اللي وصلني، أو كان معه أزرق وعطاني أحمرين.
      if (pres && !fits(pres.policies, passed)) score += 8;
      else if (pres && blues(pres.policies) > 0 && blues(passed) === 0) score += 6;
      else score -= blues(passed) > 0 ? 1 : 0;
      continue;
    }
    if (pres && chan) {
      // من برا: الادعاءين يتناقضون؟ واحد منهم يكذب.
      if (!fits(pres.policies, chan.policies) || (enacted === 'T' ? blues(chan.policies) === 2 : blues(chan.policies) === 0)) {
        score += 2;
      } else if (target === gov.chancellor && enacted === 'T' && blues(chan.policies) > 0) {
        score += 3; // يقول وصله أزرق ومرّر أحمر
      } else if (target === gov.president && blues(pres.policies) > 0 && blues(chan.policies) === 0) {
        score += 3; // يقول كان معه أزرق ورماه
      }
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
  // الزعيم كوزير بعد ٣ حمر = خسارة، فالوفي يرفض أي أحد مشكوك فيه.
  const worst = Math.max(...gov.map((id) => suspicion(s, botId, id)));
  if (s.electionTracker === 2 && worst < 2) return true;
  if (s.traitorPolicies >= LEADER_DANGER_ZONE && suspicion(s, botId, nominee.id) > 0) return false;
  return worst < 1 ? rand() < 0.85 : rand() < 0.2;
}

/** يختار كرت يرميه (الرئيس) أو يمرره (الوزير). */
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

/**
 * الادعاء بعد الحكم: البوت يتذكر وش وصله فعلاً. الوفي يقول الصدق، والخائن يقول الصدق
 * إلا لو يفضحه: رمى أزرق (يقول كلها حمر)، أو كان معه أزرق ومرّر أحمر (يلوم الرئيس).
 */
export function botClaim(s: GameState, botId: PlayerId, office: 'president' | 'chancellor', rand: Rand): Policy[] {
  const n = office === 'president' ? 3 : 2;
  const enacted = [...s.log].reverse().find((e) => e.type === 'enacted' && !e.chaos);
  const policy = enacted?.type === 'enacted' ? enacted.policy : 'T';
  const leg = s.lastLegislature;
  const drawn = leg ? s.hands?.[leg.round] : undefined;
  const mine = drawn ? (office === 'president' ? drawn.president : drawn.chancellor) : undefined;
  if (drawn && mine?.length === n) {
    const sorted = [...mine].sort();
    if (!isTraitorTeam(me(s, botId)) || policy !== 'T') return sorted;
    const partner = office === 'president' ? leg!.government.chancellor : leg!.government.president;
    if (office === 'president' && (blues(drawn.chancellor) < blues(mine) || knownTraitor(s, botId, partner))) {
      return ['T', 'T', 'T'];
    }
    if (office === 'chancellor' && blues(mine) > 0) return ['T', 'T'];
    return sorted;
  }
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
      if (botId in s.votes) return null;
      return wantsJudgeCancel(s, botId, rand) ? { type: 'judgeCancel' } : { type: 'vote', ja: vote(s, botId, rand) };
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

// ───────────── ردود البوتات في الطاولة ─────────────

export interface BotReaction {
  from: PlayerId;
  /** رد من الكتالوج: كلام (suspect، liar، innocent…) أو ملصق. */
  kind: string;
  target: PlayerId | null;
}

const isBot = (id: PlayerId) => id.startsWith('bot_');

// ملصقات البوتات (منها من باقات المتجر، عشان اللاعب يشوفها ويعرف إنها موجودة).
const STICKERS = {
  laugh: ['b_laugh', 'laugh_tears', 'laugh_clap', 'laugh_point'],
  think: ['b_think', 'b_eyes'],
  shock: ['shock_jaw', 'shock_hands', 'shock_what'],
  upset: ['b_angry', 'ang_upset', 'ang_steam'],
  smug: ['b_smirk', 'b_shh', 'cof_cup'],
};

/**
 * البوتات يتفاعلون مع اللي صار (الأحداث الجديدة بين [prev] و[next]): يدافعون عن أنفسهم، ويشكّون،
 * ويكشفون اللي كذب عليهم، ويضحكون أو يزعلون آخر اللعبة. كل بوت مرة وحدة، وبالكثير ٣ ردود.
 */
export function botReactions(prev: GameState, next: GameState, rand: Rand = Math.random): BotReaction[] {
  const bots = next.players.filter((p) => isBot(p.id) && (p.alive || next.phase === 'gameOver'));
  if (bots.length === 0) return [];
  const out: BotReaction[] = [];
  const said = new Set<PlayerId>();
  const add = (from: PlayerId, kind: string, target: PlayerId | null = null) => {
    if (said.has(from) || out.length >= 3 || from === target) return;
    said.add(from);
    out.push({ from, kind, target });
  };
  const shuffled = [...bots].sort(() => rand() - 0.5);
  for (const e of next.log.slice(prev.log.length)) {
    if (e.type === 'enacted' && e.government && !e.chaos) {
      const gov = [e.government.president, e.government.chancellor];
      if (e.policy === 'T') {
        for (const id of gov) if (isBot(id) && rand() < 0.45) add(id, 'innocent');
        for (const b of shuffled) {
          if (gov.includes(b.id) || rand() > 0.35) continue;
          // الوفي يشك في الأكثر شبهة، والخاين يرمي التهمة على الوفي اللي في الحكومة.
          const target = isTraitorTeam(b)
            ? (gov.find((id) => !knownTraitor(next, b.id, id) && id !== b.id) ?? null)
            : [...gov].sort((x, y) => suspicion(next, b.id, y) - suspicion(next, b.id, x))[0];
          if (target) add(b.id, 'suspect', target);
        }
      } else {
        for (const id of gov) if (isBot(id) && rand() < 0.25) add(id, pick(STICKERS.smug, rand));
      }
    }
    if (e.type === 'claim') {
      // ادعاء يناقض اللي وصل البوت فعلاً (كان شريكه في الحكومة): كذاب!
      const leg = legislatures(next).get(e.round);
      const passed = next.hands?.[e.round]?.chancellor;
      if (leg && passed?.length === 2) {
        const partner = e.claim.office === 'president' ? leg.gov.chancellor : leg.gov.president;
        const bot = next.players.find((p) => p.id === partner);
        const lie =
          e.claim.office === 'president' ? !fits(e.claim.policies, passed) : !sameCards(e.claim.policies, passed);
        if (bot && isBot(bot.id) && bot.alive && !isTraitorTeam(bot) && lie) add(bot.id, 'liar', e.claim.by);
        else if (lie && rand() < 0.3) {
          const watcher = shuffled.find((b) => b.alive && b.id !== e.claim.by && b.id !== partner);
          if (watcher) add(watcher.id, pick(STICKERS.think, rand));
        }
      }
    }
    if (e.type === 'voteResult' && e.cancelledBy) {
      // القاضي ألغى التصويت: ينصدمون.
      const watcher = shuffled.find((b) => b.alive && b.id !== e.cancelledBy);
      if (watcher && rand() < 0.6) add(watcher.id, pick(STICKERS.shock, rand));
    }
    if (e.type === 'executed' || e.type === 'guarded') {
      const watcher = shuffled.find((b) => b.alive && b.id !== e.by);
      if (watcher && rand() < 0.5) add(watcher.id, pick(STICKERS.shock, rand));
    }
    if (e.type === 'gameOver') {
      for (const b of shuffled) {
        if (rand() > 0.5) continue;
        add(b.id, teamOf(b.role) === e.winner ? pick(STICKERS.laugh, rand) : pick(STICKERS.upset, rand));
      }
    }
  }
  return out;
}
