import { randomInt } from 'node:crypto';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, Timestamp, type Transaction } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { HttpsError, type CallableFunction } from 'firebase-functions/v2/https';
import { boardRef, db, requireAuth, userRef } from './base.js';
import { sendPush } from './push.js';
import { appCheckMode, onCall, openCall, setAppCheckMode } from './security.js';
import {
  buyPid,
  findPlayer,
  forgetUser,
  friendRequest,
  friendRespond,
  inviteFriend,
  quotePid,
  removeFriend,
  reservePid,
  suggestIds,
} from './social.js';
import {
  MAX_PLAYERS,
  MIN_PLAYERS,
  PHASE_SECONDS,
  RuleError,
  applyAction,
  botAction,
  botReactions,
  botSeerReveal,
  botSpyPeek,
  botClaim,
  createGame,
  currentActors,
  teamOf,
  timeoutActions,
  turnKey,
  viewFor,
  watchView,
  WATCHER,
  type Action,
  type GameState,
} from '../../engine/src/index.js';
import {
  BOT_THINK_JITTER_MS,
  QUICK_TIME_FACTOR,
  TUTORIAL_TIME_FACTOR,
  botThink,
  quickBotThink,
  scenesDelay,
  startGrace,
  tutorialBotExtra,
} from './pacing.js';
import {
  xpForLevel,
  gulfDay,
  LINK_REWARD,
  MISSION_PASS_POINTS,
  TUTORIAL_REWARD,
  XP_PER_GAME,
  XP_PER_WIN,
  levelFor,
  tierById,
  weekendBoost,
  type TableTier,
} from './economy.js';
import {
  MISSIONS,
  SEASON_MISSIONS,
  WEEKLY_MISSIONS,
  bumpMissions,
  bumpPassMissions,
  currentPassMissions,
  gulfWeek,
  passStatsFromGame,
  todaysMissions,
  type MissionId,
} from './missions.js';
import { isDev, isOwner } from './dev.js';
import { validPid } from './ids.js';
import { applyStats, statsFromGame } from './achievements.js';
import { offensiveName } from './moderation.js';
import { applyRank, rankDelta, rankOf } from './rank.js';
import { whoToNotify, type Note } from './notify.js';
import {
  avatarOf,
  cleanAvatar,
  cleanName,
  nameKey,
  dailyClaim,
  equippedOf,
  newProfile,
  owns,
  readProfile,
  toLeaderboard,
  type LeaderboardEntry,
  type Profile,
} from './profile.js';
import { CATALOG, CHAMPION_REWARDS, REACTIONS, SEASON } from './catalog.js';
import {
  addPassPoints,
  applyLevelRewards,
  claimPass,
  grant,
  passComplete,
  hasVip,
  passOf,
  passPrice,
  seasonActive,
  upgradePass,
} from './rewards.js';
import { avatarOfItem, itemById, slotOf } from './shop.js';
import {
  addClanPoints,
  claimClanChest,
  clanInvite,
  clanInviteRespond,
  clanKick,
  clanPoints,
  clanRespond,
  clanRole,
  clanSettings,
  createClan,
  joinClan,
  leaveClan,
  readClans,
} from './clans.js';
import { dmPair, readDm, sendChat } from './chat.js';
import {
  TOUR_TABLE,
  applyTour,
  tourJoin,
  tourRef,
  tourStageOf,
  writeTour,
  type Tour,
} from './tournament.js';

export interface RoomPlayer {
  uid: string;
  name: string;
  avatar: string;
  /** إطار الصورة من المتجر، يشوفه الكل في الطاولة. */
  frame: string;
  /** شكل فقاعة الكلام من المتجر، يشوفها الكل. */
  bubble?: string;
  /** افكت موته من المتجر: يطلع عليه لما ينطرد، والكل يشوفه. */
  death?: string;
  /** لاعب آلي. يطلع للكل إنه بوت. */
  bot?: boolean;
  /** نسخة بروتوكول تطبيقه (Profile.proto). الأدوار الجديدة بس لو كل البشر عندهم ٢ أو أكثر. */
  proto?: number;
}

// البوتات لابسة أغراض من المتجر، عشان اللاعب يشوفها في اللعب.
const BOTS: Omit<RoomPlayer, 'uid'>[] = [
  { name: 'سلمان', avatar: 'sheikh', frame: 'frame_king', bubble: 'bubble_gold', death: 'death_gold' },
  { name: 'مها', avatar: 'pearl', frame: 'frame_pearl', bubble: 'bubble_rose', death: 'death_petals' },
  { name: 'بدر', avatar: 'desert', frame: 'frame_sand', bubble: 'bubble_desert', death: 'death_sand' },
  { name: 'لولوة', avatar: 'jasmine', frame: 'frame_oasis', bubble: 'bubble_emerald' },
  { name: 'تركي', avatar: 'hawk', frame: 'frame_fire', bubble: 'bubble_fire', death: 'death_fire' },
  { name: 'جود', avatar: 'rose', frame: 'frame_rainbow', bubble: 'bubble_rainbow', death: 'death_ghost' },
  { name: 'ماجد', avatar: 'merchant', frame: 'frame_ice', bubble: 'bubble_ice', death: 'death_ice' },
  { name: 'العنود', avatar: 'sky', frame: 'frame_night', bubble: 'bubble_night', death: 'death_bats' },
  { name: 'فيصل', avatar: 'youth', frame: 'frame_lightning', bubble: 'bubble_neon', death: 'death_lightning' },
];

/** الطاولة العامة تنتظر كذا قبل ما نسمح نكملها بالبوتات. */
const BOT_FILL_AFTER_MS = 20_000;

/** اللي كسبه كل لاعب في آخر اللعبة. */
export interface GameResult {
  won: boolean;
  coins: number;
  xp: number;
  /** نقاط التصنيف (الطاولات العامة بس). */
  rank?: number;
  /** الذهب انضرب في هالرقم (نهاية الأسبوع). */
  boost?: number;
  /** طاولة البطولة: وين صار (الدور بعد اللعبة)، وطلع أو لا، وصار بطل. */
  tour?: { stage: number; out: boolean; champion: boolean };
}

export interface Room {
  code: string;
  hostId: string;
  status: 'waiting' | 'playing' | 'finished';
  isPrivate: boolean;
  /** وقت إنشاء الروم بالملي ثانية (لحساب متى نسمح بالبوتات). */
  createdAtMs?: number;
  maxPlayers: number;
  tierId: string | null;
  /** رسوم الدخول بالذهب. تنخصم لما تدخل الروم وترجع لو طلعت قبل ما تبدأ. */
  entryFee: number;
  players: RoomPlayer[];
  createdAt: FieldValue;
  /** آخر الردود السريعة في الطاولة (أشك، أثق، إيموجي…). */
  reactions?: Reaction[];
  /** رأي كل لاعب في الباقين: opinions[من][في] = أشك أو أثق. منه نحسب مؤشر الشك. */
  opinions?: Record<string, Record<string, 'suspect' | 'trust'>>;
  /** لعبة الشرح. */
  tutorial?: boolean;
  /** الوضع السريع (الوقت نص). */
  quick?: boolean;
  /**
   * طور الشخصيات: فيه العرّاف والحارس (والقاضي والشيخ والجاسوس لو كل البشر عندهم نسخة ٢).
   * الطور العادي (false أو ما فيه) بدون أي دور خاص: الزعيم والخونة والأوفياء بس.
   */
  roles?: boolean;
  results?: Record<string, GameResult>;
  /** متى خلصت اللعبة. بعدها الطاولة تبقى مفتوحة للسوالف لين يطلعون. */
  finishedAtMs?: number;
  /** اللي طلعوا من الطاولة بعد ما خلصت اللعبة (يبان للباقين إنهم طلعوا). */
  gone?: string[];
  /** «العب مرة ثانية»: كود الروم الجديد بنفس الإعدادات (أول واحد ضغطها سواه، والباقين يدخلونه). */
  next?: string;
  /** أصحاب اللاعبين اللي يتفرجون على اللعبة (يقرون نسخة المتفرج). */
  watchers?: string[];
  /** طاولة بطولة الأسبوع: أي دور (٠ الأول، ١ نص النهائي، ٢ النهائي) وأي أسبوع. */
  tour?: number;
  tourWeek?: string;
}

export interface Reaction {
  from: string;
  kind: string;
  target: string | null;
  at: number;
}

// الردود المسموحة (REACTIONS) في الكتالوج: كلام وملصقات، ما فيه كتابة حرة أبداً.
const MAX_REACTIONS = 40;
/** الطاولة بعد اللعبة تبقى للسوالف، بس مو للأبد: بعد نص ساعة تقفل. */
const AFTER_GAME_CHAT_MS = 30 * 60_000;

// بدون الحروف اللي تتلخبط مثل O و 0 و I و 1.
const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function cleanMaxPlayers(n: unknown): number {
  return typeof n === 'number' && Number.isInteger(n) && n >= MIN_PLAYERS && n <= MAX_PLAYERS ? n : 7;
}

async function newRoomCode(): Promise<string> {
  for (let attempt = 0; attempt < 10; attempt++) {
    const code = Array.from({ length: 5 }, () => CODE_ALPHABET[randomInt(CODE_ALPHABET.length)]).join('');
    if (!(await db.doc(`rooms/${code}`).get()).exists) return code;
  }
  throw new HttpsError('resource-exhausted', 'ما قدرنا نسوي كود، جرّب مرة ثانية');
}

const asPlayer = (uid: string, p: Profile): RoomPlayer => {
  const eq = equippedOf(p);
  return { uid, name: p.name, avatar: avatarOf(p), frame: eq.frame, bubble: eq.bubble, death: eq.death, proto: p.proto ?? 1 };
};

/** نسخة البروتوكول اللي فيها الأدوار الجديدة وإعادة اللعب والتفرج (Profile.proto). */
const PROTO_V2 = 2;

/** كل البشر في الروم تطبيقهم يعرف الأدوار الجديدة؟ (النسخة القديمة تطيح لو شافت دور ما تعرفه.) */
const modernRoom = (room: Room) => room.players.every((p) => p.bot || (p.proto ?? 1) >= PROTO_V2);

/** يتأكد إن اللاعب يقدر يدخل الطاولة (المستوى والذهب والـ VIP). */
function checkTier(p: Profile, tier: TableTier): void {
  if (tier.vipOnly && !hasVip(p, Date.now())) {
    throw new HttpsError('permission-denied', 'هذي الطاولة لأعضاء VIP بس. اشتر باتل الموسم الحالي وتنفتح لك');
  }
  if (p.level < tier.requiredLevel) {
    throw new HttpsError('permission-denied', `هذي الطاولة تفتح في مستوى ${tier.requiredLevel}`);
  }
}

/** يخصم رسوم الدخول ويحفظ الملف (يسويه لو جديد). المطور ذهبه ما يخلص. */
function chargeEntry(tx: Transaction, uid: string, p: Profile, fee: number): void {
  if (p.dev) return void tx.set(userRef(uid), p);
  if (p.coins < fee) throw new HttpsError('failed-precondition', 'ما عندك ذهب كافي');
  tx.set(userRef(uid), { ...p, coins: p.coins - fee });
}

/** يبدأ اللعبة داخل نفس العملية: يوزع الأدوار ويكتب نسخة كل لاعب. */
function startGameTx(tx: Transaction, room: Room): GameState {
  const state: GameState = {
    ...createGame(
      room.players.map((p) => ({ id: p.uid, name: p.name })),
      randomInt(2 ** 31),
      { specials: room.roles === true, extraSpecials: modernRoom(room) },
    ),
    quick: room.quick ?? false,
  };
  tx.update(db.doc(`rooms/${room.code}`), { status: 'playing' });
  writeGame(tx, room.code, state, deadlineFor(state, Date.now(), startGrace()));
  // يلعب الحين: أصحابه يشوفونه ويقدرون يتفرجون.
  const at = Date.now();
  for (const p of room.players.filter((pl) => !isBot(pl.uid))) {
    tx.set(userRef(p.uid), { playing: { code: room.code, at } }, { merge: true });
    tx.set(boardRef(p.uid), { playingSince: at }, { merge: true });
  }
  return state;
}

const isBot = (id: string) => id.startsWith('bot_');

/** يلعب عنه البوت: بوت أصلاً، أو لاعب طلع أو انطرد من اللعبة. */
const botPlays = (s: GameState) => (id: string) => isBot(id) || (s.autopilot ?? []).includes(id);

/** كم دور يفوّته اللاعب ورا بعض قبل ما ينطرد، وكم يتعاقب (ما يدخل ألعاب). */
const MAX_MISSES = 2;
const AFK_BAN_MS = 5 * 60_000;

/**
 * آخر وقت للدور الحالي (بالملي ثانية). [waitMs] وقت ننتظره قبل ما يبدأ الدور (الترحيب، أو مشاهد
 * الأحداث اللي صارت للتو) عشان ما يركب شي على شي. لو الدور على بوت، يفكر ٣–٥ ثواني،
 * وبعدها أي جوال في الطاولة يطلب من السيرفر يلعب عنه.
 */
function deadlineFor(state: GameState, now: number, waitMs = 0): number | null {
  if (state.phase === 'gameOver') return null;
  // رقم صحيح دايم (التطبيق يقراه int).
  const start = Math.round(now + waitMs);
  const actors = currentActors(state);
  if (actors.length > 0 && actors.every(botPlays(state))) {
    const jitter = randomInt(BOT_THINK_JITTER_MS);
    if (state.quick) return start + quickBotThink(jitter);
    // لعبة الشرح: أول جولتين البوتات أبطأ عشان اللاعب يلحق يقرا النصايح.
    return start + botThink(jitter) + (state.tutorial && state.round <= 2 ? tutorialBotExtra() : 0);
  }
  const factor = state.tutorial ? TUTORIAL_TIME_FACTOR : state.quick ? QUICK_TIME_FACTOR : 1;
  return start + Math.round(PHASE_SECONDS[state.phase] * 1000 * factor);
}

/** حركات البوتات اللي ما تحتاج انتظار: التصويت (سري لين يكتمل)، والادعاء بعد الحكم، وكشف العرّاف. */
function runInstantBots(state: GameState): GameState {
  let s = state;
  for (let guard = 0; guard < 50 && s.phase !== 'gameOver'; guard++) {
    let changed = false;
    const leg = s.lastLegislature;
    if (leg) {
      for (const [office, id] of [['president', leg.government.president], ['chancellor', leg.government.chancellor]] as const) {
        if (botPlays(s)(id) && !leg.claimed.includes(id) && s.players.find((p) => p.id === id)?.alive) {
          s = applyAction(s, id, { type: 'claim', policies: botClaim(s, id, office, Math.random) });
          changed = true;
        }
      }
    }
    // العرّاف البوت يستخدم كشفه لما يجي وقته (من الجولة الثانية)، والجاسوس البوت يشوف الكومة.
    for (const p of s.players) {
      if (!botPlays(s)(p.id)) continue;
      const target = botSeerReveal(s, p.id);
      if (target) {
        s = applyAction(s, p.id, { type: 'seerReveal', target });
        changed = true;
      }
      if (botSpyPeek(s, p.id)) {
        s = applyAction(s, p.id, { type: 'spyPeek' });
        changed = true;
      }
    }
    if (s.phase === 'election') {
      for (const id of currentActors(s).filter(botPlays(s))) {
        if (s.phase !== 'election') break;
        // لعبة الشرح: البوتات يوافقون على أول حكومة عشان اللاعب الجديد يشوف كيف يمر القرار.
        s = applyAction(s, id, s.tutorial && s.round === 1 ? { type: 'vote', ja: true } : botAction(s, id)!);
        changed = true;
      }
    }
    if (!changed) break;
  }
  return s;
}

/** نحفظ الحالة الكاملة مع المؤقت، ونسخة لكل لاعب. */
function writeGame(tx: Transaction, code: string, state: GameState, deadline: number | null): void {
  const gameRef = db.doc(`games/${code}`);
  tx.set(gameRef, { ...state, deadline, turnKey: turnKey(state) });
  for (const p of state.players) {
    tx.set(gameRef.collection('views').doc(p.id), { ...viewFor(state, p.id), deadline, autopilot: state.autopilot ?? [] });
  }
  // نسخة المتفرجين (بدون أي سر).
  tx.set(gameRef.collection('views').doc(WATCHER), { ...watchView(state), deadline, autopilot: state.autopilot ?? [] });
}

interface StoredGame extends GameState {
  deadline: number | null;
  turnKey: string;
}

function splitGame(data: StoredGame): { state: GameState; deadline: number | null; key: string } {
  const { deadline, turnKey: key, ...state } = data;
  return { state, deadline, key };
}

/** يسوي ملف اللاعب لو أول مرة يدخل. التطبيق يتابع الملف مباشرة من Firestore. */
export const ensureProfile = onCall(async (req) => {
  const uid = requireAuth(req);
  const owner = isOwner(req);
  // نسخة التطبيق (النسخ القديمة ما ترسلها).
  const proto = clampInt(req.data?.proto ?? 1, 1, 100);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef(uid));
    if (!snap.exists) {
      return tx.set(userRef(uid), { ...newProfile(), dev: owner, owner, proto, pid: await reservePid(tx, uid), pidTier: 0 });
    }
    const p = snap.data() as Profile;
    const dev = isDev(req, p);
    // لاعب من قبل الرموز: ياخذ رمز عادي.
    const withPid = p.pid ? p : { ...p, pid: await reservePid(tx, uid), pidTier: 0 };
    // هدايا مستويات ما أخذها (مثلاً وصل المستوى قبل ما تنضاف الهدايا).
    const rewarded = applyLevelRewards(withPid);
    if (rewarded !== p || (p.dev ?? false) !== dev || (p.owner ?? false) !== owner || (p.proto ?? 1) !== proto) {
      tx.set(userRef(uid), { ...rewarded, dev, owner, proto });
    }
    if (withPid !== p && p.setupDone) tx.set(boardRef(uid), toLeaderboard(rewarded));
  });
  // أسبوع جديد؟ نتوّج أبطال اللي فات (مرة وحدة). أي خطأ هنا ما يمنع اللاعب يدخل.
  await maybeCrown(Date.now()).catch((e) => logger.warn('التتويج', e));
  return {};
});

/**
 * أدوات المطور للتجربة. ما تشتغل إلا لحساب مطور (isDev).
 * grant: ذهب وجواهر · level: يحط مستواك · unlockAll: كل أغراض المتجر · resetDaily · unban
 * forceRole: في لعبة شغالة، يخليك الدور والدور الخاص اللي تختاره.
 * لصاحب اللعبة بس: setDev (يخلي لاعب مطوّر برمزه أو يشيله) · devs (المطورين) · appCheck (الحماية من الغش).
 */
export const devTool = onCall(async (req) => {
  const uid = requireAuth(req);
  const owner = isOwner(req);
  if (!isDev(req, (await userRef(uid).get()).data() as Profile | undefined)) {
    throw new HttpsError('permission-denied', 'هذي للمطور بس');
  }
  const action = String(req.data?.action ?? '');
  if (action === 'setDev' || action === 'devs') {
    if (!owner) throw new HttpsError('permission-denied', 'بس صاحب اللعبة يقدر يخلي أحد مطوّر');
    return action === 'devs' ? { devs: await listDevs() } : setDev(String(req.data?.pid ?? '').trim(), req.data?.on !== false);
  }
  if (action === 'forceRole') return forceRole(uid, String(req.data?.code ?? ''), req.data?.role, req.data?.special);
  // الحماية من الغش (security.ts): كل مطوّر يشوفها، وصاحب اللعبة بس يغيّرها.
  if (action === 'appCheck') {
    const mode = req.data?.mode;
    if (mode === 'monitor' || mode === 'enforce') {
      if (!owner) throw new HttpsError('permission-denied', 'بس صاحب اللعبة يغيّر الحماية');
      await setAppCheckMode(mode);
    }
    return { mode: await appCheckMode() };
  }
  if (action === 'crown') return { champions: await crownChampions(gulfWeek(Date.now()), Date.now()) };
  if (action === 'reports') return { reports: await openReports() };
  if (action === 'feedback') return { feedback: await recentFeedback() };
  if (action === 'deletionRequests') return { requests: await openDeletionRequests() };
  if (action === 'deleteUser') return deleteFromRequest(String(req.data?.request ?? ''), req.data?.confirm === true);
  if (action === 'resolveReport') {
    return resolveReports(String(req.data?.target ?? ''), String(req.data?.decision ?? ''), clampInt(req.data?.days, 1, 365));
  }
  return db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    let next: Profile = p;
    switch (action) {
      case 'grant':
        next = { ...p, coins: p.coins + clampInt(req.data?.coins, 0, 1_000_000), diamonds: p.diamonds + clampInt(req.data?.diamonds, 0, 100_000) };
        break;
      case 'level': {
        const level = clampInt(req.data?.level, 1, 100);
        // ينزل المستوى؟ نرجّع الهدايا من جديد عشان يقدر يجربها مرة ثانية.
        const back = level < p.level ? { rewardedLevel: level } : {};
        next = applyLevelRewards({ ...p, ...back, xp: xpForLevel(level), level });
        break;
      }
      case 'unlockAll':
        next = { ...p, owned: CATALOG.map((i) => i.id) };
        break;
      case 'passPoints': {
        const s = passOf(p);
        next = { ...p, pass: { ...s, points: s.points + clampInt(req.data?.points, 0, 100_000) } };
        break;
      }

      case 'resetDaily':
        next = { ...p, lastDaily: null };
        break;
      case 'unban':
        next = { ...p, bannedUntil: 0 };
        break;
      default:
        throw new HttpsError('invalid-argument', 'أداة مو معروفة');
    }
    tx.set(userRef(uid), next);
    tx.set(boardRef(uid), toLeaderboard(next));
    return {};
  });
});

/** يخلي لاعب مطوّر برمزه (أو يشيله). صاحب اللعبة نفسه يبقى مطوّر دايماً. */
async function setDev(pid: string, on: boolean): Promise<{ name: string; pid: string }> {
  if (!validPid(pid)) throw new HttpsError('invalid-argument', 'الرمز أرقام بس، من ٣ إلى ٨');
  const target = (await db.doc(`ids/${pid}`).get()).data()?.uid as string | undefined;
  if (!target) throw new HttpsError('not-found', 'ما لقينا لاعب بهالرمز');
  return db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, target);
    tx.set(userRef(target), { ...p, devGranted: on, dev: on || (p.owner ?? false) });
    return { name: p.name, pid };
  });
}

/** اللاعبين اللي صاحب اللعبة خلاهم مطورين. */
async function listDevs(): Promise<{ uid: string; name: string; pid: string }[]> {
  const snap = await db.collection('users').where('devGranted', '==', true).limit(100).get();
  return snap.docs.map((d) => ({ uid: d.id, name: String(d.get('name') ?? ''), pid: String(d.get('pid') ?? '') }));
}

function clampInt(raw: unknown, min: number, max: number): number {
  const n = Math.round(Number(raw));
  return Number.isFinite(n) ? Math.min(max, Math.max(min, n)) : min;
}

/** المطور يختار دوره في لعبة شغالة: نبدّل دوره مع لاعب عنده الدور المطلوب، ونعطيه الدور الخاص. */
async function forceRole(uid: string, code: string, role: unknown, special: unknown): Promise<object> {
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(db.doc(`games/${code}`));
    if (!snap.exists) throw new HttpsError('not-found', 'اللعبة مو موجودة');
    const { state, deadline } = splitGame(snap.data() as StoredGame);
    const players = state.players.map((p) => ({ ...p }));
    const me = players.find((p) => p.id === uid);
    if (!me) throw new HttpsError('permission-denied', 'أنت مو في هذي اللعبة');
    const known = ['seer', 'guardian', 'judge', 'elder', 'spy'] as const;
    const wanted = known.find((k) => k === special) ?? null;
    // العرّاف والحارس للأوفياء بس، والأدوار الجديدة لأي فريق (إلا الزعيم).
    const wantRole = wanted === 'seer' || wanted === 'guardian' ? 'loyal' : wanted && role === 'leader' ? 'loyal' : role;
    if (wantRole === 'loyal' || wantRole === 'traitor' || wantRole === 'leader') {
      const other = players.find((p) => p.id !== uid && p.role === wantRole && !p.special);
      if (me.role !== wantRole && other) [me.role, other.role] = [other.role, me.role];
    }
    if (wanted) {
      const holder = players.find((p) => p.special === wanted);
      if (holder && holder !== me) holder.special = me.special;
      me.special = wanted;
    }
    writeGame(tx, code, { ...state, players, seerSees: null }, deadline);
  });
  return {};
}

export const updateProfile = onCall(async (req) => {
  const uid = requireAuth(req);
  const name = cleanName(req.data?.name);
  const key = nameKey(name);
  if (BOTS.some((b) => nameKey(b.name) === key)) throw new HttpsError('already-exists', 'هذا الاسم محجوز، اختر اسم ثاني');
  if (offensiveName(name)) throw new HttpsError('invalid-argument', 'الاسم فيه كلمة مو لائقة، اختر اسم ثاني');
  await db.runTransaction(async (tx) => {
    // كل اسم لواحد بس: نحجزه في names/ ونفك الاسم القديم.
    const nameRef = db.doc(`names/${key}`);
    const taken = await tx.get(nameRef);
    const old = await readProfile(db, tx, uid);
    const avatar = cleanAvatar(req.data?.avatar, old);
    if (taken.exists && taken.data()!.uid !== uid) throw new HttpsError('already-exists', 'هذا الاسم مأخوذ، اختر اسم ثاني');
    if (old.nameKey && old.nameKey !== key) tx.delete(db.doc(`names/${old.nameKey}`));
    tx.set(nameRef, { uid });
    // اسم جديد: البلاغات على الاسم القديم ما عاد تنحسب.
    const changed = old.nameKey !== key;
    const p: Profile = {
      ...old,
      name,
      nameKey: key,
      avatar,
      setupDone: true,
      ...(changed ? { nameReporters: [], renamed: false } : {}),
    };
    tx.set(userRef(uid), p);
    tx.set(boardRef(uid), toLeaderboard(p));
  });
  return {};
});

/** مكافأة ربط الحساب بقوقل، مرة وحدة بس. التوكن لازم يكون فيه هوية قوقل. */
export const claimLinkReward = onCall(async (req) => {
  const uid = requireAuth(req);
  const identities = (req.auth!.token.firebase?.identities ?? {}) as Record<string, unknown>;
  if (!identities['google.com']) throw new HttpsError('failed-precondition', 'اربط حسابك بقوقل أول');
  return db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    if (p.linked) return { coins: 0 };
    tx.set(userRef(uid), { ...p, linked: true, coins: p.coins + LINK_REWARD });
    return { coins: LINK_REWARD };
  });
});

export const claimDaily = onCall(async (req) => {
  const uid = requireAuth(req);
  return db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const reward = dailyClaim(p, Date.now());
    tx.set(userRef(uid), {
      ...p,
      coins: p.coins + reward.coins,
      diamonds: p.diamonds + reward.diamonds,
      lastDaily: reward.today,
      dailyStreak: reward.streak,
    });
    return { coins: reward.coins, diamonds: reward.diamonds, streak: reward.streak };
  });
});

/** روم خاص بكود، بدون رسوم دخول. */
export const createRoom = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = await newRoomCode();
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    requireNotBanned(p);
    const room: Room = {
      code,
      hostId: uid,
      status: 'waiting',
      isPrivate: true,
      maxPlayers: cleanMaxPlayers(req.data?.maxPlayers),
      tierId: null,
      entryFee: 0,
      players: [asPlayer(uid, p)],
      createdAt: FieldValue.serverTimestamp(),
      createdAtMs: Date.now(),
      quick: req.data?.quick === true,
      roles: req.data?.roles === true,
    };
    tx.set(db.doc(`rooms/${code}`), room);
  });
  return { code };
});

/** يدخّل لاعب روم ينتظر (داخل عملية): يتأكد من المكان والطاولة ويخصم الرسوم. يرجّع اللعبة لو بدأت. */
async function joinTx(tx: Transaction, code: string, uid: string): Promise<GameState | null> {
  const ref = db.doc(`rooms/${code}`);
  const snap = await tx.get(ref);
  if (!snap.exists) throw new HttpsError('not-found', 'ما فيه روم بهذا الكود');
  const room = snap.data() as Room;
  if (room.players.some((p) => p.uid === uid)) return null;
  if (room.status !== 'waiting') throw new HttpsError('failed-precondition', 'اللعبة بدأت');
  if (room.players.length >= room.maxPlayers) throw new HttpsError('failed-precondition', 'الروم مليان');
  const p = await readProfile(db, tx, uid);
  requireNotBanned(p);
  const tier = tierById(room.tierId);
  if (tier) checkTier(p, tier);
  if (room.entryFee > 0) chargeEntry(tx, uid, p, room.entryFee);
  room.players.push(asPlayer(uid, p));
  tx.update(ref, { players: room.players });
  return !room.isPrivate && room.players.length === room.maxPlayers ? startGameTx(tx, room) : null;
}

export const joinRoom = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '').trim().toUpperCase();
  if (!/^[A-Z0-9]{5}$/.test(code)) throw new HttpsError('invalid-argument', 'الكود لازم يكون ٥ حروف');
  const started = await db.runTransaction((tx) => joinTx(tx, code, uid));
  if (started) await sendPush(code, whoToNotify(null, started));
  return { code };
});

/**
 * «العب مرة ثانية» بعد ما تخلص اللعبة: أول واحد يضغطها يسوي روم جديد بنفس الإعدادات والبوتات (وهو صاحبه)،
 * والباقين يدخلونه. التدريب (أنت والبوتات بس) يبدأ على طول، والطاولة العامة تبدأ لما تكتمل.
 */
export const rematch = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  const fresh = await newRoomCode();
  const out = await db.runTransaction(async (tx): Promise<{ code: string; started: GameState | null }> => {
    const ref = db.doc(`rooms/${code}`);
    const room = (await tx.get(ref)).data() as Room | undefined;
    if (!room || room.status !== 'finished') throw new HttpsError('failed-precondition', 'اللعبة ما خلصت');
    if (!room.players.some((p) => p.uid === uid)) throw new HttpsError('permission-denied', 'أنت مو في هذي الطاولة');
    if (room.tutorial) throw new HttpsError('failed-precondition', 'لعبة الشرح ما تنعاد');
    if (room.tour != null) throw new HttpsError('failed-precondition', 'جولات البطولة ما تنعاد، العب جولتك الجاية من البطولة');
    // فيه روم جاهز من واحد ضغط قبلك: تدخله.
    if (room.next) return { code: room.next, started: await joinTx(tx, room.next, uid) };
    const p = await readProfile(db, tx, uid);
    requireNotBanned(p);
    const tier = tierById(room.tierId);
    if (tier) checkTier(p, tier);
    // البوتات ترجع لنفس الطاولة (مو اللاعبين اللي طلعوا وكمّل عنهم بوت).
    const bots = room.players.filter((pl) => isBot(pl.uid));
    const alone = room.players.every((pl) => pl.uid === uid || isBot(pl.uid));
    const next: Room = {
      code: fresh,
      hostId: uid,
      status: 'waiting',
      isPrivate: room.isPrivate,
      maxPlayers: room.maxPlayers,
      tierId: room.tierId,
      entryFee: room.entryFee,
      players: [asPlayer(uid, p), ...bots.slice(0, room.maxPlayers - 1)],
      createdAt: FieldValue.serverTimestamp(),
      createdAtMs: Date.now(),
      quick: room.quick ?? false,
      roles: room.roles ?? false,
    };
    if (room.entryFee > 0) chargeEntry(tx, uid, p, room.entryFee);
    tx.set(db.doc(`rooms/${fresh}`), next);
    tx.update(ref, { next: fresh });
    const start =
      (room.isPrivate && alone && next.players.length >= MIN_PLAYERS) ||
      (!room.isPrivate && next.players.length === next.maxPlayers);
    return { code: fresh, started: start ? startGameTx(tx, next) : null };
  });
  if (out.started) await sendPush(out.code, whoToNotify(null, out.started));
  return { code: out.code, started: out.started !== null };
});

/** "العب الحين": يدخلك أول روم عام فيه مكان بنفس الطاولة وعدد اللاعبين، أو يسوي واحد جديد. */
export const quickMatch = onCall(async (req) => {
  const uid = requireAuth(req);
  const maxPlayers = cleanMaxPlayers(req.data?.maxPlayers);
  const tier = tierById(req.data?.tierId);
  if (!tier) throw new HttpsError('invalid-argument', 'اختار طاولة');
  const quick = req.data?.quick === true;
  // الطور: عادي (بدون أدوار خاصة) أو الشخصيات. اللي يختار طور ما ينحط إلا مع نفس الطور.
  const roles = req.data?.roles === true;

  const open = await db
    .collection('rooms')
    .where('status', '==', 'waiting')
    .where('isPrivate', '==', false)
    .where('maxPlayers', '==', maxPlayers)
    .where('tierId', '==', tier.id)
    .where('quick', '==', quick)
    .where('roles', '==', roles)
    .limit(10)
    .get();

  for (const doc of open.docs) {
    const joined = await db.runTransaction(async (tx): Promise<{ started: GameState | null } | null> => {
      const room = (await tx.get(doc.ref)).data() as Room | undefined;
      const p = await readProfile(db, tx, uid);
      requireNotBanned(p);
      if (!room || room.status !== 'waiting' || room.players.length >= room.maxPlayers) return null;
      if (room.players.some((x) => x.uid === uid)) return { started: null };
      // ما نحطه مع أحد حظره.
      if (room.players.some((x) => (p.blocked ?? []).includes(x.uid))) return null;
      checkTier(p, tier);
      chargeEntry(tx, uid, p, room.entryFee);
      room.players.push(asPlayer(uid, p));
      tx.update(doc.ref, { players: room.players });
      return { started: room.players.length === room.maxPlayers ? startGameTx(tx, room) : null };
    });
    if (joined?.started) await sendPush(doc.id, whoToNotify(null, joined.started));
    if (joined) return { code: doc.id };
  }

  const code = await newRoomCode();
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    requireNotBanned(p);
    checkTier(p, tier);
    chargeEntry(tx, uid, p, tier.entryFee);
    const room: Room = {
      code,
      hostId: uid,
      status: 'waiting',
      isPrivate: false,
      maxPlayers,
      tierId: tier.id,
      entryFee: tier.entryFee,
      players: [asPlayer(uid, p)],
      createdAt: FieldValue.serverTimestamp(),
      createdAtMs: Date.now(),
      quick,
      roles,
    };
    tx.set(db.doc(`rooms/${code}`), room);
  });
  return { code };
});

/**
 * «العب جولتك» في بطولة الأسبوع: يدخلك طاولة بطولة بنفس دورك (أو يسوي وحدة)، وتتكمل بالبوتات بعد شوي.
 */
export const tourPlay = onCall(async (req) => {
  const uid = requireAuth(req);
  const now = Date.now();
  const week = gulfWeek(now);
  const stage = await db.runTransaction(async (tx) => tourStageOf(await readProfile(db, tx, uid), now));
  const open = await db
    .collection('rooms')
    .where('status', '==', 'waiting')
    .where('isPrivate', '==', false)
    .where('tour', '==', stage)
    .where('tourWeek', '==', week)
    .limit(10)
    .get();
  for (const doc of open.docs) {
    const joined = await db.runTransaction(async (tx): Promise<{ started: GameState | null } | null> => {
      const room = (await tx.get(doc.ref)).data() as Room | undefined;
      const p = await readProfile(db, tx, uid);
      requireNotBanned(p);
      if (tourStageOf(p, now) !== stage) return null;
      if (!room || room.status !== 'waiting' || room.players.length >= room.maxPlayers) return null;
      if (room.players.some((x) => x.uid === uid)) return { started: null };
      if (room.players.some((x) => (p.blocked ?? []).includes(x.uid))) return null;
      room.players.push(asPlayer(uid, p));
      tx.update(doc.ref, { players: room.players });
      return { started: room.players.length === room.maxPlayers ? startGameTx(tx, room) : null };
    });
    if (joined?.started) await sendPush(doc.id, whoToNotify(null, joined.started));
    if (joined) return { code: doc.id };
  }
  const code = await newRoomCode();
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    requireNotBanned(p);
    tourStageOf(p, now);
    const room: Room = {
      code,
      hostId: uid,
      status: 'waiting',
      isPrivate: false,
      maxPlayers: TOUR_TABLE,
      tierId: null,
      entryFee: 0,
      players: [asPlayer(uid, p)],
      createdAt: FieldValue.serverTimestamp(),
      createdAtMs: Date.now(),
      quick: false,
      // البطولة بالطور العادي.
      roles: false,
      tour: stage,
      tourWeek: week,
    };
    tx.set(db.doc(`rooms/${code}`), room);
  });
  return { code };
});

/**
 * يكمّل الروم بالبوتات.
 * - الروم الخاص: صاحبه يضيف بوت واحد كل مرة (عشان تجرب لحالك أو تكمل العدد مع أصحابك).
 * - الطاولة العامة: أي واحد فيها يقدر يكملها بالبوتات بعد ٢٠ ثانية انتظار، وتبدأ على طول.
 */
export const addBots = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  const started = await db.runTransaction(async (tx): Promise<GameState | null> => {
    const ref = db.doc(`rooms/${code}`);
    const room = (await tx.get(ref)).data() as Room | undefined;
    if (!room || room.status !== 'waiting') throw new HttpsError('failed-precondition', 'الروم مو في الانتظار');
    if (!room.players.some((p) => p.uid === uid)) throw new HttpsError('permission-denied', 'أنت مو في هذا الروم');
    const free = room.maxPlayers - room.players.length;
    if (free <= 0) throw new HttpsError('failed-precondition', 'الروم مليان');
    if (room.isPrivate && room.hostId !== uid) throw new HttpsError('permission-denied', 'بس صاحب الروم يضيف بوتات');
    if (!room.isPrivate && Date.now() - (room.createdAtMs ?? 0) < BOT_FILL_AFTER_MS) {
      throw new HttpsError('failed-precondition', 'ننتظر لاعبين شوي قبل البوتات');
    }
    const taken = new Set(room.players.map((p) => p.name));
    const available = BOTS.filter((b) => !taken.has(b.name));
    const count = room.isPrivate ? 1 : free;
    for (let i = 0; i < count; i++) {
      const b = available.splice(randomInt(available.length), 1)[0];
      room.players.push({ ...b, uid: `bot_${randomInt(1e9)}`, bot: true });
    }
    tx.update(ref, { players: room.players });
    return !room.isPrivate && room.players.length === room.maxPlayers ? startGameTx(tx, room) : null;
  });
  if (started) await sendPush(code, whoToNotify(null, started));
  return {};
});

/** صاحب الروم الخاص يشيل بوت (الطاولة ما بدأت للحين). */
export const removeBot = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  const botId = String(req.data?.botId ?? '');
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`rooms/${code}`);
    const room = (await tx.get(ref)).data() as Room | undefined;
    if (!room || room.status !== 'waiting' || room.hostId !== uid || !isBot(botId)) {
      throw new HttpsError('permission-denied', 'ما تقدر تشيله');
    }
    tx.update(ref, { players: room.players.filter((p) => p.uid !== botId) });
  });
  return {};
});

/** الطلوع من غرفة الانتظار. لو كان فيه رسوم دخول ترجع لك. */
export const leaveRoom = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`rooms/${code}`);
    const room = (await tx.get(ref)).data() as Room | undefined;
    const p = await readProfile(db, tx, uid);
    if (!room || room.status !== 'waiting' || !room.players.some((x) => x.uid === uid)) return;
    const players = room.players.filter((x) => x.uid !== uid);
    if (players.length === 0) tx.delete(ref);
    else tx.update(ref, { players, hostId: room.hostId === uid ? players[0].uid : room.hostId });
    if (room.entryFee > 0 && !p.dev) tx.set(userRef(uid), { ...p, coins: p.coins + room.entryFee });
  });
  return {};
});

/** صاحب الروم الخاص يبدأ اللعبة لما يكون فيه ٥ لاعبين على الأقل. */
export const startGame = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  const started = await db.runTransaction(async (tx) => {
    const snap = await tx.get(db.doc(`rooms/${code}`));
    const room = snap.data() as Room | undefined;
    if (!room) throw new HttpsError('not-found', 'الروم مو موجود');
    if (room.hostId !== uid) throw new HttpsError('permission-denied', 'بس صاحب الروم يقدر يبدأ');
    if (room.status !== 'waiting') throw new HttpsError('failed-precondition', 'اللعبة بدأت');
    if (room.players.length < MIN_PLAYERS) {
      throw new HttpsError('failed-precondition', `لازم ${MIN_PLAYERS} لاعبين على الأقل`);
    }
    return startGameTx(tx, room);
  });
  await sendPush(code, whoToNotify(null, started));
  return {};
});

/** التدريب بطلب واحد: روم خاص فيه أنت و٤ بوتات، ويبدأ على طول (بدال ٦ طلبات ورا بعض). */
export const startTraining = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = await newRoomCode();
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    requireNotBanned(p);
    const bots = [...BOTS];
    const room: Room = {
      code,
      hostId: uid,
      status: 'waiting',
      isPrivate: true,
      maxPlayers: 5,
      tierId: null,
      entryFee: 0,
      players: [
        asPlayer(uid, p),
        ...Array.from({ length: 4 }, () => ({ ...bots.splice(randomInt(bots.length), 1)[0], uid: `bot_${randomInt(1e9)}`, bot: true })),
      ],
      createdAt: FieldValue.serverTimestamp(),
      createdAtMs: Date.now(),
      quick: false,
      roles: req.data?.roles === true,
    };
    tx.set(db.doc(`rooms/${code}`), room);
    startGameTx(tx, room);
  });
  return { code };
});

/**
 * لعبة الشرح: أنت وفي (بدون دور خاص) وأنت أول رئيس، وأول ٣ كروت فيها أزرق وأحمر عشان يكون للاختيار معنى.
 */
function rigTutorial(state: GameState, uid: string): GameState {
  const players = state.players.map((p) => ({ ...p }));
  const me = players.find((p) => p.id === uid)!;
  if (me.role !== 'loyal') {
    // نبدّل مع وفي ما عنده دور خاص (الدور الخاص للأوفياء بس).
    const other = players.find((p) => p.id !== uid && p.role === 'loyal' && !p.special)!;
    [me.role, other.role] = [other.role, me.role];
    [me.special, other.special] = [other.special, me.special];
  }
  if (me.special) {
    const other = players.find((p) => p.id !== uid && p.role === 'loyal' && !p.special)!;
    [me.special, other.special] = [null, me.special];
  }
  const drawPile = [...state.drawPile];
  const top = drawPile.slice(0, 3);
  if (!top.includes('L') || !top.includes('T')) {
    const need = top.includes('L') ? 'T' : 'L';
    const j = drawPile.findIndex((c, i) => i >= 3 && c === need);
    if (j >= 0) [drawPile[2], drawPile[j]] = [drawPile[j], drawPile[2]];
  }
  return { ...state, players, presidentId: uid, rotationSeat: me.seat, drawPile, tutorial: true };
}

/** يبدأ لعبة الشرح على طول: أنت و٤ بوتات، والراوي يشرح لك كل خطوة. */
export const startTutorial = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = await newRoomCode();
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    requireNotBanned(p);
    const bots = [...BOTS]
      .sort(() => Math.random() - 0.5)
      .slice(0, 4)
      .map((b) => ({ ...b, uid: `bot_${randomInt(1e9)}`, bot: true }));
    const room: Room = {
      code,
      hostId: uid,
      status: 'playing',
      isPrivate: true,
      maxPlayers: 5,
      tierId: null,
      entryFee: 0,
      players: [asPlayer(uid, p), ...bots],
      createdAt: FieldValue.serverTimestamp(),
      createdAtMs: Date.now(),
      tutorial: true,
    };
    tx.set(db.doc(`rooms/${code}`), room);
    // لعبة الشرح بالطور العادي (بدون أدوار خاصة): خلّها بسيطة للاعب الجديد.
    const players = room.players.map((pl) => ({ id: pl.uid, name: pl.name }));
    const state = rigTutorial(createGame(players, randomInt(2 ** 31), { specials: false }), uid);
    writeGame(tx, code, state, deadlineFor(state, Date.now(), startGrace(true)));
  });
  return { code };
});

/** كل حركة في اللعبة تمر من هنا. السيرفر يتأكد إنها مسموحة قبل ما يطبقها. */
export const act = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  const action = req.data?.action as Action | undefined;
  if (!action || typeof action.type !== 'string') throw new HttpsError('invalid-argument', 'حركة ناقصة');

  const notes = await db.runTransaction(async (tx) => {
    const snap = await tx.get(db.doc(`games/${code}`));
    if (!snap.exists) throw new HttpsError('not-found', 'اللعبة مو موجودة');
    const prev = splitGame(snap.data() as StoredGame);
    if ((prev.state.autopilot ?? []).includes(uid)) {
      throw new HttpsError('failed-precondition', 'طلعت من هذي اللعبة، والبوت يكمل عنك');
    }
    let next: GameState;
    try {
      next = applyAction(prev.state, uid, action);
      if (next.misses?.[uid]) next = { ...next, misses: { ...next.misses, [uid]: 0 } };
    } catch (e) {
      if (e instanceof RuleError) throw new HttpsError('failed-precondition', e.message, { code: e.code });
      throw e;
    }
    const bumps = new Map<string, Partial<Record<MissionId, number>>>();
    if (action.type === 'enact') {
      if (!isBot(prev.state.presidentId)) bumps.set(prev.state.presidentId, { legislate1: 1 });
      bumps.set(uid, { legislate1: 1 });
    }
    if (action.type === 'claim') bumps.set(uid, { claim2: 1 });
    return finishTurn(tx, code, prev, next, bumps);
  });
  await sendPush(code, notes);
  return {};
});

/**
 * يكمّل أي تغيير في اللعبة: يقرا اللي يحتاجه (الروم والملفات) قبل أي كتابة (شرط Firestore)،
 * ثم يحفظ الحالة والمؤقت، ويحدّث المهام، ويوزع الجوائز لو انتهت اللعبة.
 */
async function finishTurn(
  tx: Transaction,
  code: string,
  prev: { state: GameState; deadline: number | null; key: string },
  next: GameState,
  bumps: Map<string, Partial<Record<MissionId, number>>>,
): Promise<Note[]> {
  next = runInstantBots(next);
  const now = Date.now();
  const over = next.phase === 'gameOver';
  const humans = next.players.filter((p) => !isBot(p.id));
  const uids = over ? humans.map((p) => p.id) : [...bumps.keys()];
  // البوتات يتفاعلون مع اللي صار (يدافعون، يشكّون، يقولون كذاب…).
  const chatter = botReactions(prev.state, next);
  const roomRef = db.doc(`rooms/${code}`);
  const room = over || chatter.length ? ((await tx.get(roomRef)).data() as Room) : null;
  // اللي حذف حسابه وسط اللعبة ما نرجّع له ملف.
  const profiles = (await Promise.all(uids.map((uid) => tx.get(userRef(uid))))).map((s) =>
    s.exists ? (s.data() as Profile) : null,
  );
  // الدواوين: الطاولات العامة بس تزيد نقاطها (عشان ما تنجمع من التدريب).
  const forClans = over && !!room && !room.isPrivate && !next.tutorial;
  const clans = forClans ? await readClans(tx, profiles.flatMap((p) => (p?.clan ? [p.clan.id] : []))) : new Map();
  const clanGains: Parameters<typeof addClanPoints>[2] = [];
  // طاولة البطولة: نقرا لوحة البطولة قبل الكتابة.
  const tourWeek = over && room?.tour != null ? room.tourWeek : undefined;
  const tourDoc = tourWeek ? ((await tx.get(tourRef(tourWeek))).data() as Tour | undefined) : undefined;
  const tourChanges: Parameters<typeof writeTour>[3] = [];

  const delay = scenesDelay(prev.state, next);
  const deadline = turnKey(next) === prev.key ? prev.deadline : deadlineFor(next, now, delay);
  writeGame(tx, code, next, deadline);

  // ردود البوتات تطلع بعد المشاهد (كشف التصويت والختم)، وحدة ورا الثانية.
  const roomUpdate: Record<string, unknown> = {};
  if (chatter.length && room) {
    const at = now + delay;
    const added = chatter.map((c, i) => ({ from: c.from, kind: c.kind, target: c.target, at: at + i * 1500 }));
    roomUpdate.reactions = [...(room.reactions ?? []), ...added].slice(-MAX_REACTIONS);
    for (const c of chatter) {
      if (c.target && (c.kind === 'suspect' || c.kind === 'trust')) roomUpdate[`opinions.${c.from}.${c.target}`] = c.kind;
    }
  }

  if (!over) {
    if (Object.keys(roomUpdate).length) tx.update(roomRef, roomUpdate);
    uids.forEach((uid, i) => {
      const p = profiles[i];
      if (p) tx.set(userRef(uid), { ...p, missions: bumpMissions(p.missions, now, bumps.get(uid)!) });
    });
    return whoToNotify(prev.state, next);
  }

  if (!room) throw new HttpsError('not-found', 'الروم مو موجود');
  // البوتات ما يدفعون، فالجائزة من رسوم البشر بس. ونصيب البوت الفايز ما يروح لأحد.
  const winners = next.players.filter((p) => teamOf(p.role) === next.winner);
  const pot = room.entryFee * humans.length;
  const share = winners.length ? Math.floor(pot / winners.length) : 0;
  // نهاية الأسبوع: ذهب الفوز مضاعف.
  const boost = weekendBoost(now);
  const week = gulfWeek(now);
  const results: Record<string, GameResult> = {};
  humans.forEach((player, i) => {
    // اللي طلع أو انطرد قبل النهاية ما ياخذ فوز ولا جائزة.
    const won = teamOf(player.role) === next.winner && !(next.autopilot ?? []).includes(player.id);
    const p = profiles[i];
    const xp = XP_PER_GAME + (won ? XP_PER_WIN : 0);
    const coins = won ? share * boost : 0;
    results[player.id] = { won, coins, xp, ...(coins > 0 && boost > 1 ? { boost } : {}) };
    if (!p) return;
    const base: Profile = {
      ...p,
      // خلصت اللعبة: ما عاد يلعب (إلا لو طلع منها ودخل لعبة ثانية).
      playing: p.playing?.code === code ? null : (p.playing ?? null),
      coins: p.coins + coins,
      xp: p.xp + xp,
      level: levelFor(p.xp + xp),
      gamesPlayed: p.gamesPlayed + 1,
      gamesWon: p.gamesWon + (won ? 1 : 0),
      week,
      weeklyWins: (p.week === week ? (p.weeklyWins ?? 0) : 0) + (won ? 1 : 0),
      missions: bumpMissions(p.missions, now, { ...bumps.get(player.id), play3: 1, ...(won ? { win1: 1 } : {}) }),
    };
    // نقاط الموسم نفس الخبرة، وهدايا المستويات لو طلع مستوى، ومكافأة أول لعبة شرح.
    let updated = applyLevelRewards(addPassPoints(base, xp, now));
    if (next.tutorial && !updated.tutorialDone && !(next.autopilot ?? []).includes(player.id)) {
      updated = grant({ ...updated, tutorialDone: true }, { coins: TUTORIAL_REWARD, diamonds: 0, items: [] }, { kind: 'tutorial', n: 0 });
    }
    // الإنجازات: إحصائيات هاللعبة، ودرجات جديدة لو وصلها.
    updated = applyStats(updated, statsFromGame(next, player.id, won), won);
    // مهام الباتل باس (الأسبوعية والموسم).
    if (seasonActive(now)) {
      const inc = passStatsFromGame(next, player.id, won, room.roles === true);
      if (Object.keys(inc).length) {
        updated = { ...updated, passMissions: bumpPassMissions(updated.passMissions, SEASON.id, now, inc) };
      }
    }
    // البطولة: الفايز يتأهل للدور اللي بعده، والخسران (أو اللي طلع) يطلع منها، واللي فاز النهائي بطل.
    if (tourWeek && room.tour != null) {
      const t = applyTour(updated, room.tour, tourWeek, won);
      updated = t.profile;
      if (t.result) {
        tourChanges.push({ uid: player.id, p: updated, ...t.result });
        results[player.id] = { ...results[player.id], tour: t.result };
      }
    }
    // ديوانه: نقاط اللعبة (واللي ديوانه انحذف ينشال من ملفه).
    if (forClans && updated.clan) {
      if (!clans.has(updated.clan.id)) updated = { ...updated, clan: null };
      else if (!(next.autopilot ?? []).includes(player.id)) {
        clanGains.push({ uid: player.id, clan: updated.clan.id, points: clanPoints(won), p: updated });
      }
    }
    // التصنيف: الطاولات العامة بس (اللي طلع يخسر نقاط).
    if (!room.isPrivate && !next.tutorial) {
      const before = rankOf(updated).points;
      updated = applyRank(updated, rankDelta(won, humans.length, next.players.length));
      results[player.id] = { ...results[player.id], rank: rankOf(updated).points - before };
    }
    if (!next.tutorial) {
      tx.set(userRef(player.id).collection('history').doc(`${now}-${code}`), historyEntry(next, room, player.id, results[player.id], now));
    }
    tx.set(userRef(player.id), updated);
    tx.set(boardRef(player.id), toLeaderboard(updated));
  });
  if (clanGains.length) addClanPoints(tx, clans, clanGains, now);
  if (tourWeek) writeTour(tx, tourWeek, tourDoc, tourChanges);
  tx.update(roomRef, { ...roomUpdate, status: 'finished', results, finishedAtMs: Date.now() });
  return whoToNotify(prev.state, next);
}

/** كم يوم تبقى اللعبة في سجل المباريات (Firestore يحذفها بنفسه بعدها: firestore.indexes.json → expireAt). */
const HISTORY_DAYS = 30;

/**
 * سجل المباريات: نسخة اللاعب من اللعبة بعد النهاية (كل الأدوار والادعاءات والكروت الحقيقية، عشان «مين كذب؟»)،
 * ولاعبين الروم (أسماؤهم وصورهم)، ونتيجته هو.
 */
function historyEntry(state: GameState, room: Room, uid: string, result: GameResult, now: number) {
  return {
    at: now,
    expireAt: Timestamp.fromMillis(now + HISTORY_DAYS * 24 * 3600_000),
    view: { ...viewFor(state, uid), deadline: null, autopilot: state.autopilot ?? [] },
    room: {
      code: room.code,
      hostId: room.hostId,
      status: 'finished',
      isPrivate: room.isPrivate,
      maxPlayers: room.maxPlayers,
      tierId: room.tierId,
      entryFee: room.entryFee,
      players: room.players,
      roles: room.roles === true,
      quick: room.quick === true,
      ...(room.tour != null ? { tour: room.tour } : {}),
      ...(room.createdAtMs != null ? { createdAtMs: room.createdAtMs } : {}),
      results: { [uid]: result },
    },
  };
}

/**
 * يسلّم مقاعد لاعبين للبوت: يطلع جنبهم علامة البوت للكل. [banUntil] عقاب اللي انطرد لأنه ما لعب.
 * كتابة بس (الروم مقروء من بداية العملية)، لأن Firestore يبي كل القراءات قبل الكتابات.
 */
function handOver(tx: Transaction, room: Room, uids: string[], banUntil?: number): void {
  tx.update(db.doc(`rooms/${room.code}`), {
    players: room.players.map((p) => (uids.includes(p.uid) ? { ...p, bot: true } : p)),
  });
  // طلع من اللعبة: ما عاد يلعب (والبوت يكمل عنه).
  for (const uid of uids) {
    tx.set(userRef(uid), { playing: null, ...(banUntil ? { bannedUntil: banUntil } : {}) }, { merge: true });
    tx.set(boardRef(uid), { playingSince: null }, { merge: true });
  }
}

/** اللي انطرد لأنه ما لعب، ما يدخل ألعاب لين يخلص عقابه. */
function requireNotBanned(p: Profile): void {
  const left = (p.bannedUntil ?? 0) - Date.now();
  if (left > 0) {
    const minutes = Math.ceil(left / 60_000);
    throw new HttpsError('failed-precondition', `انطردت لأنك ما لعبت دورك. تقدر ترجع تلعب بعد ${minutes} دقيقة`);
  }
}

/**
 * اللاعب يطلع من لعبة شغالة: يكمل عنه بوت لين النهاية، وما ياخذ فوز ولا جائزة.
 * وبعد ما تخلص: يطلع من الطاولة بس، ويبان للباقين إنه طلع.
 */
export const leaveGame = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  const notes = await db.runTransaction(async (tx): Promise<Note[] | null> => {
    const snap = await tx.get(db.doc(`games/${code}`));
    if (!snap.exists) throw new HttpsError('not-found', 'اللعبة مو موجودة');
    const prev = splitGame(snap.data() as StoredGame);
    if (!prev.state.players.some((p) => p.id === uid)) throw new HttpsError('permission-denied', 'أنت مو في هذي اللعبة');
    const room = (await tx.get(db.doc(`rooms/${code}`))).data() as Room;
    if (prev.state.phase === 'gameOver') {
      if (!(room.gone ?? []).includes(uid)) tx.update(db.doc(`rooms/${code}`), { gone: [...(room.gone ?? []), uid] });
      return null;
    }
    if ((prev.state.autopilot ?? []).includes(uid)) return null;
    const next = runInstantBots({ ...prev.state, autopilot: [...(prev.state.autopilot ?? []), uid] });
    const notes = await finishTurn(tx, code, { ...prev, key: '' }, next, new Map());
    handOver(tx, room, [uid]);
    return notes;
  });
  if (notes) await sendPush(code, notes);
  return {};
});

/**
 * أي لاعب في الطاولة يطلبها لما يخلص الوقت. السيرفر يتأكد إن الوقت خلص فعلاً،
 * ثم يلعب بدال اللي تأخر. لو أكثر من واحد طلبها بنفس اللحظة، وحدة بس تنفذ.
 */
export const timeout = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  const notes = await db.runTransaction(async (tx): Promise<Note[] | null> => {
    const snap = await tx.get(db.doc(`games/${code}`));
    if (!snap.exists) throw new HttpsError('not-found', 'اللعبة مو موجودة');
    const prev = splitGame(snap.data() as StoredGame);
    if (!prev.state.players.some((p) => p.id === uid)) throw new HttpsError('permission-denied', 'أنت مو في هذي اللعبة');
    if (prev.deadline === null || Date.now() < prev.deadline) return null;
    const room = (await tx.get(db.doc(`rooms/${code}`))).data() as Room;

    let next = prev.state;
    let kicked: string[] = [];
    const actors = currentActors(prev.state);
    const plays = botPlays(prev.state);
    if (actors.length > 0 && actors.every(plays)) {
      for (const id of actors) next = applyAction(next, id, botAction(next, id)!);
    } else {
      for (const [id, a] of timeoutActions(prev.state, Math.random)) next = applyAction(next, id, a);
      // اللي خلص وقته وهو ما لعب: نعدّ عليه، ولو فوّت دورين ورا بعض يلعب عنه بوت ويتعاقب.
      const missed = prev.state.tutorial ? [] : actors.filter((id) => !plays(id));
      if (missed.length) {
        const misses = { ...(next.misses ?? {}) };
        for (const id of missed) {
          misses[id] = (misses[id] ?? 0) + 1;
          if (misses[id] >= MAX_MISSES) kicked.push(id);
        }
        next = { ...next, misses, autopilot: [...(next.autopilot ?? []), ...kicked] };
      }
    }
    const notes = await finishTurn(tx, code, prev, next, new Map());
    if (kicked.length) handOver(tx, room, kicked, Date.now() + AFK_BAN_MS);
    return notes;
  });
  if (notes) await sendPush(code, notes);
  return { applied: notes !== null };
});

/** بالكثير كم واحد يتفرج على لعبة. */
const MAX_WATCHERS = 20;

/**
 * تتفرج على لعبة صاحبك وهي شغالة: لازم يكون صاحبك ويلعب الحين. ترجع كود الروم، وتقدر تقرا نسخة المتفرج
 * (كل شي عام، بدون أدوار ولا كروت).
 */
export const spectate = onCall(async (req) => {
  const uid = requireAuth(req);
  const target = String(req.data?.uid ?? '');
  return db.runTransaction(async (tx) => {
    const me = await readProfile(db, tx, uid);
    if (!target || !(me.friends ?? []).includes(target)) throw new HttpsError('permission-denied', 'تقدر تتفرج على أصحابك بس');
    const them = (await tx.get(userRef(target))).data() as Profile | undefined;
    const code = them?.playing?.code;
    if (!code) throw new HttpsError('failed-precondition', 'صاحبك ما يلعب الحين');
    const ref = db.doc(`rooms/${code}`);
    const room = (await tx.get(ref)).data() as Room | undefined;
    if (!room || room.status !== 'playing') throw new HttpsError('failed-precondition', 'لعبة صاحبك خلصت');
    if (room.players.some((p) => p.uid === uid)) throw new HttpsError('failed-precondition', 'أنت معه في نفس اللعبة!');
    const watchers = room.watchers ?? [];
    if (!watchers.includes(uid)) {
      if (watchers.length >= MAX_WATCHERS) throw new HttpsError('resource-exhausted', 'المتفرجين كثير، جرّب بعدين');
      tx.update(ref, { watchers: [...watchers, uid] });
    }
    return { code };
  });
});

/** خلّص تفرّج: يطلع من قائمة المتفرجين (عشان العدد يبقى صحيح). */
export const stopWatching = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`rooms/${code}`);
    const room = (await tx.get(ref)).data() as Room | undefined;
    if (room?.watchers?.includes(uid)) tx.update(ref, { watchers: room.watchers.filter((w) => w !== uid) });
  });
  return {};
});

/** شراء غرض من المتجر بالذهب أو الجواهر. */
export const buyItem = onCall(async (req) => {
  const uid = requireAuth(req);
  const item = itemById(req.data?.id);
  if (!item) {
    const special = CATALOG.find((i) => i.id === req.data?.id);
    if (special) throw new HttpsError('failed-precondition', 'هذا الغرض ما ينشرى، ينكسب بالمستويات أو الموسم أو البطولة');
    throw new HttpsError('invalid-argument', 'غرض مو معروف');
  }
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const owned = p.owned ?? [];
    if (owns(p, item.id)) throw new HttpsError('already-exists', 'عندك هذا الغرض');
    const balance = item.currency === 'coins' ? p.coins : p.diamonds;
    // المطور يشتري ببلاش عشان يجرب كل شي.
    const price = p.dev ? 0 : item.price;
    if (balance < price) {
      throw new HttpsError('failed-precondition', item.currency === 'coins' ? 'ما عندك ذهب كافي' : 'ما عندك جواهر كافية');
    }
    // الإطار والكروت والطاولة تنلبس على طول، والشخصية تصير صورته.
    const slot = slotOf(item.id);
    const updated: Profile = {
      ...p,
      [item.currency]: balance - price,
      owned: [...owned, item.id],
      ...(slot ? { equipped: { ...equippedOf(p), [slot]: item.id } } : {}),
      ...(item.slot === 'avatar' ? { avatar: avatarOfItem(item.id) } : {}),
    };
    tx.set(userRef(uid), updated);
    if (item.slot === 'frame' || item.slot === 'avatar') tx.set(boardRef(uid), toLeaderboard(updated));
  });
  return {};
});

/** لبس غرض تملكه (أو الرجوع للشكل الأساسي). */
export const equipItem = onCall(async (req) => {
  const uid = requireAuth(req);
  const id = String(req.data?.id ?? '');
  const slot = slotOf(id);
  if (!slot) throw new HttpsError('invalid-argument', 'غرض مو معروف');
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    if (!owns(p, id)) throw new HttpsError('permission-denied', 'ما تملك هذا الغرض');
    const updated = { ...p, equipped: { ...equippedOf(p), [slot]: id } };
    tx.set(userRef(uid), updated);
    tx.set(boardRef(uid), toLeaderboard(updated));
  });
  return {};
});

/** يحفظ جهاز اللاعب عشان نرسل له إشعار لما يجي دوره. نخلي آخر ٥ أجهزة بس. */
export const registerPushToken = onCall(async (req) => {
  const uid = requireAuth(req);
  const token = String(req.data?.token ?? '');
  if (token.length < 20 || token.length > 4096) throw new HttpsError('invalid-argument', 'رمز غلط');
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const tokens = [...(p.fcmTokens ?? []).filter((t) => t !== token), token].slice(-5);
    tx.set(userRef(uid), { ...p, fcmTokens: tokens });
  });
  return {};
});

/** يشيل الهدايا اللي شافها (التطبيق يعرضها ويناديها بعدين). */
export const ackGifts = onCall(async (req) => {
  const uid = requireAuth(req);
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    if (p.gifts?.length) tx.set(userRef(uid), { ...p, gifts: [] });
  });
  return {};
});

/**
 * يشتري الباتل باس (بالجواهر، والمطور ببلاش): العادي = المسار المدفوع ومعه درجات هدية، و[full] = كل الدرجات
 * مفتوحة على طول (لو عنده العادي يدفع الفرق بس). يرجّع السعر.
 */
export const buyPass = onCall(async (req) => {
  const uid = requireAuth(req);
  const full = req.data?.full === true;
  return db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    if (!seasonActive(Date.now())) throw new HttpsError('failed-precondition', 'الموسم مو شغال الحين');
    const s = passOf(p);
    if (full ? passComplete(s) : s.premium) {
      throw new HttpsError('already-exists', full ? 'عندك الباتل باس كامل' : 'عندك الباتل باس');
    }
    const price = p.dev ? 0 : passPrice(s, full);
    if (p.diamonds < price) throw new HttpsError('failed-precondition', 'ما عندك جواهر كافية');
    tx.set(userRef(uid), { ...p, diamonds: p.diamonds - price, pass: upgradePass(s, full) });
    return { price };
  });
});

/** يهدي صاحبه الباتل باس (العادي أو الكامل) من جواهره. صاحبه تطلع له هدية باسمه. */
export const giftPass = onCall(async (req) => {
  const uid = requireAuth(req);
  const target = String(req.data?.uid ?? '');
  const full = req.data?.full === true;
  if (!target || target === uid || target.includes('/')) throw new HttpsError('invalid-argument', 'اختار صاحب');
  return db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    if (!seasonActive(Date.now())) throw new HttpsError('failed-precondition', 'الموسم مو شغال الحين');
    if (!(p.friends ?? []).includes(target)) throw new HttpsError('permission-denied', 'تقدر تهدي أصحابك بس');
    const snap = await tx.get(userRef(target));
    if (!snap.exists) throw new HttpsError('not-found', 'صاحبك مو موجود');
    const them = snap.data() as Profile;
    const s = passOf(them);
    if (s.premium) throw new HttpsError('already-exists', 'صاحبك عنده الباتل باس');
    const price = p.dev ? 0 : passPrice(s, full);
    if (p.diamonds < price) throw new HttpsError('failed-precondition', 'ما عندك جواهر كافية');
    const gift = { kind: 'passGift' as const, n: full ? 1 : 0, coins: 0, diamonds: 0, items: [], from: p.name };
    tx.set(userRef(uid), { ...p, diamonds: p.diamonds - price });
    tx.set(userRef(target), { ...them, pass: upgradePass(s, full), gifts: [...(them.gifts ?? []), gift].slice(-10) });
    return { price };
  });
});

/** يستلم نقاط مهمة باتل باس (أسبوعية أو للموسم) خلصها. */
export const claimPassMission = onCall(async (req) => {
  const uid = requireAuth(req);
  const id = String(req.data?.id ?? '');
  const weekly = WEEKLY_MISSIONS.find((m) => m.id === id);
  const mission = weekly ?? SEASON_MISSIONS.find((m) => m.id === id);
  if (!mission) throw new HttpsError('invalid-argument', 'مهمة مو معروفة');
  return db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const now = Date.now();
    if (!seasonActive(now)) throw new HttpsError('failed-precondition', 'الموسم مو شغال الحين');
    const m = currentPassMissions(p.passMissions, SEASON.id, now);
    const claimed = weekly ? m.weeklyClaimed : m.seasonClaimed;
    if (claimed.includes(id)) throw new HttpsError('failed-precondition', 'استلمتها من قبل');
    if (((weekly ? m.weekly : m.total)[mission.stat] ?? 0) < mission.target) {
      throw new HttpsError('failed-precondition', 'ما خلصت المهمة للحين');
    }
    const next = weekly ? { ...m, weeklyClaimed: [...claimed, id] } : { ...m, seasonClaimed: [...claimed, id] };
    tx.set(userRef(uid), addPassPoints({ ...p, passMissions: next }, mission.points, now));
    return { points: mission.points };
  });
});

/** يستلم كل مكافآت الباتل باس اللي وصلها (المجانية، والمدفوعة لو شراه). يرجّع اللي أخذه. */
export const claimPassRewards = onCall(async (req) => {
  const uid = requireAuth(req);
  return db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const { profile, got } = claimPass(p);
    tx.set(userRef(uid), profile);
    if (got.items.some((id) => id.startsWith('avatar_') || id.startsWith('frame_'))) tx.set(boardRef(uid), toLeaderboard(profile));
    return got;
  });
});

const CHAMPION_IDS = new Set(Object.values(CHAMPION_REWARDS).flatMap((r) => r.items));

/**
 * أبطال الأسبوع: أول ٣ في الترتيب الأسبوعي ياخذون إطار وشخصية خاصة لين التتويج الجاي (أسبوع)، مع ذهب.
 * اللي كانوا أبطال قبل ترجع لهم أشكالهم. يرجّع معرفات الأبطال الجدد.
 */
async function crownChampions(week: string, now: number): Promise<string[]> {
  const snap = await db.collection('leaderboard').where('week', '==', week).orderBy('weeklyWins', 'desc').limit(10).get();
  const top = snap.docs
    .map((d) => ({ ...(d.data() as LeaderboardEntry), uid: d.id }))
    .filter((e) => e.weeklyWins > 0)
    .sort((a, b) => b.weeklyWins - a.weeklyWins || b.gamesWon - a.gamesWon || b.level - a.level)
    .slice(0, 3);
  const until = now + 7 * 86400_000;
  const metaRef = db.doc('meta/champions');
  const before = ((await metaRef.get()).data()?.uids ?? []) as string[];
  const dropChampionItems = (p: Profile) =>
    Object.fromEntries(Object.entries(p.temp ?? {}).filter(([id]) => !CHAMPION_IDS.has(id)));

  // الأبطال القدام: تخلص أغراضهم ويرجعون لأشكالهم.
  for (const uid of before.filter((u) => !top.some((t) => t.uid === u))) {
    await db.runTransaction(async (tx) => {
      const p = await readProfile(db, tx, uid);
      const back: Profile = { ...p, temp: dropChampionItems(p) };
      const fixed: Profile = { ...back, avatar: avatarOf(back, now), equipped: equippedOf(back, now), restore: {} };
      tx.set(userRef(uid), fixed);
      tx.set(boardRef(uid), toLeaderboard(fixed));
    });
  }

  const list: { uid: string; rank: number; name: string; avatar: string; wins: number }[] = [];
  for (const [i, e] of top.entries()) {
    const rank = i + 1;
    const reward = CHAMPION_REWARDS[rank];
    const frame = reward.items.find((id) => id.startsWith('frame_'))!;
    const avatar = avatarOfItem(reward.items.find((id) => id.startsWith('avatar_'))!);
    await db.runTransaction(async (tx) => {
      const p = await readProfile(db, tx, e.uid);
      const temp: Record<string, number> = dropChampionItems(p);
      for (const id of reward.items) temp[id] = until;
      // اللي لابسه الحين (لو مو من البطولة) يرجع له بعد الأسبوع.
      const eq = equippedOf(p, now);
      const current = avatarOf(p, now);
      const restore = {
        frame: CHAMPION_IDS.has(eq.frame) ? p.restore?.frame : eq.frame,
        avatar: CHAMPION_IDS.has(`avatar_${current}`) ? p.restore?.avatar : current,
      };
      const gift = { kind: 'champion' as const, n: rank, coins: reward.coins, diamonds: reward.diamonds, items: reward.items };
      const next: Profile = {
        ...p,
        coins: p.coins + reward.coins,
        diamonds: p.diamonds + reward.diamonds,
        temp,
        restore,
        avatar,
        equipped: { ...eq, frame },
        gifts: [...(p.gifts ?? []), gift].slice(-10),
      };
      tx.set(userRef(e.uid), next);
      tx.set(boardRef(e.uid), toLeaderboard(next));
    });
    list.push({ uid: e.uid, rank, name: e.name, avatar, wins: e.weeklyWins });
  }
  await metaRef.set({ week, uids: list.map((c) => c.uid), list, until, at: now });
  return list.map((c) => c.uid);
}

/**
 * تتويج أبطال الأسبوع اللي خلص، أول ما يفتح أي لاعب اللعبة بعد بداية أسبوع جديد (الأحد).
 * القفل في meta/crownLock يضمن إنه يصير مرة وحدة بس لكل أسبوع حتى لو فتح أكثر من لاعب بنفس اللحظة.
 */
async function maybeCrown(now: number): Promise<void> {
  const lastWeek = gulfWeek(now - 7 * 86400_000);
  const lockRef = db.doc('meta/crownLock');
  const mine = await db.runTransaction(async (tx) => {
    const lock = (await tx.get(lockRef)).data();
    if (lock?.week === lastWeek) return false;
    tx.set(lockRef, { week: lastWeek, at: now });
    return true;
  });
  if (!mine) return;
  const champions = await crownChampions(lastWeek, now);
  logger.info('أبطال الأسبوع', { week: lastWeek, champions });
}

/** يستلم مكافأة مهمة خلصها اليوم. */
export const claimMission = onCall(async (req) => {
  const uid = requireAuth(req);
  const mission = MISSIONS.find((m) => m.id === req.data?.id);
  if (!mission) throw new HttpsError('invalid-argument', 'مهمة مو معروفة');
  return db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const today = todaysMissions(p.missions, Date.now());
    if (today.claimed.includes(mission.id)) throw new HttpsError('failed-precondition', 'استلمتها من قبل');
    if ((today.progress[mission.id] ?? 0) < mission.target) {
      throw new HttpsError('failed-precondition', 'ما خلصت المهمة للحين');
    }
    const claimed = { ...p, coins: p.coins + mission.coins, missions: { ...today, claimed: [...today.claimed, mission.id] } };
    tx.set(userRef(uid), addPassPoints(claimed, MISSION_PASS_POINTS, Date.now()));
    return { coins: mission.coins };
  });
});

/** كم ملصق يقدر يحط في المفضلة. */
const MAX_FAVORITES = 5;

/** الملصقات المفضلة: بالكثير ٥، من الباقات اللي يملكها، بالترتيب اللي يبيه. */
export const setFavorites = onCall(async (req) => {
  const uid = requireAuth(req);
  const raw: unknown[] = Array.isArray(req.data?.ids) ? req.data.ids : [];
  const ids = [...new Set(raw.map(String))];
  if (ids.length > MAX_FAVORITES) throw new HttpsError('invalid-argument', `المفضلة بالكثير ${MAX_FAVORITES}`);
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    for (const id of ids) {
      const spec = Object.hasOwn(REACTIONS, id) ? REACTIONS[id] : null;
      if (!spec || spec.target) throw new HttpsError('invalid-argument', 'ملصق مو معروف');
      if (spec.pack && !owns(p, spec.pack)) throw new HttpsError('permission-denied', 'هذا الملصق من باقة ما تملكها');
    }
    tx.set(userRef(uid), { ...p, favorites: ids });
  });
  return {};
});

/** اللاعب الجديد لازم يقرا القوانين ويلعب الشرح، إلا إذا تخطّاه بنفسه (يعرف يلعب). */
export const skipTutorial = onCall(async (req) => {
  const uid = requireAuth(req);
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    if (!p.tutorialDone && !p.tutorialSkipped) tx.set(userRef(uid), { ...p, tutorialSkipped: true });
  });
  return {};
});

/** يشيل رأيك (أشك أو أثق) في لاعب، لو غيّرت رأيك. */
export const clearOpinion = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  const target = String(req.data?.target ?? '');
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`rooms/${code}`);
    const room = (await tx.get(ref)).data() as Room | undefined;
    if (!room || !room.players.some((p) => p.uid === uid)) throw new HttpsError('permission-denied', 'أنت مو في هذي الطاولة');
    tx.update(ref, { [`opinions.${uid}.${target}`]: FieldValue.delete() });
  });
  return {};
});

/** رد سريع في الطاولة (كلام أو ملصق). بعض الكلام يحتاج لاعب مستهدف (مثل أشك في فلان). */
export const react = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  const kind = String(req.data?.kind ?? '');
  const spec = Object.hasOwn(REACTIONS, kind) ? REACTIONS[kind] : null;
  if (!spec) throw new HttpsError('invalid-argument', 'رد مو معروف');
  const target = spec.target ? String(req.data?.target ?? '') : null;

  await db.runTransaction(async (tx) => {
    const ref = db.doc(`rooms/${code}`);
    const room = (await tx.get(ref)).data() as Room | undefined;
    const game = (await tx.get(db.doc(`games/${code}`))).data() as StoredGame | undefined;
    const profile = await readProfile(db, tx, uid);
    if (!room || room.status === 'waiting') throw new HttpsError('failed-precondition', 'اللعبة مو شغالة');
    if (!room.players.some((p) => p.uid === uid)) throw new HttpsError('permission-denied', 'أنت مو في هذي الطاولة');
    // بعد ما تخلص اللعبة الطاولة تبقى للسوالف (للكل، حتى المطرودين) لين يطلعون.
    const over = room.status === 'finished';
    if (over && ((room.gone ?? []).includes(uid) || Date.now() - (room.finishedAtMs ?? 0) > AFTER_GAME_CHAT_MS)) {
      throw new HttpsError('failed-precondition', 'الطاولة قفلت');
    }
    if (over && (kind === 'suspect' || kind === 'trust')) throw new HttpsError('failed-precondition', 'اللعبة خلصت');
    // المطرود ما يتكلم لين تخلص اللعبة.
    if (!over && game?.players.find((p) => p.id === uid)?.alive === false) {
      throw new HttpsError('failed-precondition', 'انطردت من المجلس، ما تقدر تتكلم');
    }
    if (spec.pack && !owns(profile, spec.pack)) {
      throw new HttpsError('permission-denied', 'هذا الرد من باقة ما تملكها للحين');
    }
    if (target !== null && (target === uid || !room.players.some((p) => p.uid === target))) {
      throw new HttpsError('invalid-argument', 'اختار لاعب ثاني');
    }
    const now = Date.now();
    const recent = (room.reactions ?? []).filter((r) => r.from === uid && now - r.at < 1500);
    if (recent.length > 0) throw new HttpsError('resource-exhausted', 'شوي شوي، انتظر ثانية');
    const reactions = [...(room.reactions ?? []), { from: uid, kind, target, at: now }].slice(-MAX_REACTIONS);
    const update: Record<string, unknown> = { reactions };
    if (kind === 'suspect' || kind === 'trust') update[`opinions.${uid}.${target}`] = kind;
    tx.update(ref, update);
    tx.set(userRef(uid), { ...profile, missions: bumpMissions(profile.missions, now, { react5: 1 }) });
  });
  return {};
});

// ───────────── البلاغ والحظر وحذف الحساب والرسائل ─────────────

const REPORT_REASONS = ['name', 'behavior', 'cheat', 'chat'] as const;
const MAX_REPORTS_PER_DAY = 10;
/** كم لاعب مختلف لازم يبلّغون عن اسم عشان ينغيّر تلقائياً. */
const NAME_REPORTS_TO_RENAME = 3;

/** اسم مؤقت محايد لما ينغيّر الاسم بسبب البلاغات (واللاعب يختار اسم جديد). */
function placeholderName(): string {
  return `لاعب${randomInt(1000, 9999)}`;
}

/** يغيّر اسم لاعب لاسم محايد (داخل عملية) ويفك حجز اسمه القديم. */
function renameTx(tx: Transaction, uid: string, p: Profile): Profile {
  const name = placeholderName();
  const key = nameKey(name);
  if (p.nameKey) tx.delete(db.doc(`names/${p.nameKey}`));
  tx.set(db.doc(`names/${key}`), { uid });
  const next: Profile = { ...p, name, nameKey: key, nameReporters: [], renamed: true };
  tx.set(userRef(uid), next);
  tx.set(boardRef(uid), toLeaderboard(next));
  return next;
}

/** بلاغ عن لاعب: اسم مسيء، أو يخرّب اللعب، أو غش. لو ٣ بلّغوا عن نفس الاسم، ينغيّر تلقائياً. */
export const reportPlayer = onCall(async (req) => {
  const uid = requireAuth(req);
  const target = String(req.data?.uid ?? '');
  const reason = String(req.data?.reason ?? '') as (typeof REPORT_REASONS)[number];
  const code = req.data?.code ? String(req.data.code).slice(0, 8) : null;
  // بلاغ عن رسالة في الدردشة: نحفظ نصها عشان المراجعة.
  const text = reason === 'chat' && typeof req.data?.text === 'string' ? req.data.text.slice(0, 200) : null;
  if (!REPORT_REASONS.includes(reason)) throw new HttpsError('invalid-argument', 'اختار سبب البلاغ');
  if (!target || target === uid || target.startsWith('bot_')) throw new HttpsError('invalid-argument', 'ما تقدر تبلّغ عن هذا اللاعب');
  const now = Date.now();
  const day = gulfDay(now);
  // بلاغ واحد في اليوم لكل لاعب وسبب (لو كرره ما ينحسب مرتين).
  const ref = db.doc(`reports/${day}_${uid}_${target}_${reason}`);
  return db.runTransaction(async (tx) => {
    const existing = await tx.get(ref);
    const targetSnap = await tx.get(userRef(target));
    const me = await readProfile(db, tx, uid);
    if (!targetSnap.exists) throw new HttpsError('not-found', 'اللاعب مو موجود');
    if (existing.exists) return { already: true };
    const count = me.reportDay === day ? (me.reportCount ?? 0) : 0;
    if (count >= MAX_REPORTS_PER_DAY) throw new HttpsError('resource-exhausted', 'وصلت حد البلاغات اليوم، شكراً لك');
    const t = targetSnap.data() as Profile;
    tx.set(ref, { reporter: uid, target, reason, code, ...(text ? { text } : {}), name: t.name, at: now, status: 'open' });
    tx.set(userRef(uid), { ...me, reportDay: day, reportCount: count + 1 });
    if (reason === 'name') {
      const reporters = [...new Set([...(t.nameReporters ?? []), uid])];
      if (reporters.length >= NAME_REPORTS_TO_RENAME) {
        renameTx(tx, target, t);
        logger.info('اسم انغيّر بسبب البلاغات', { target, name: t.name });
      } else {
        tx.set(userRef(target), { ...t, nameReporters: reporters });
      }
    }
    return { already: false };
  });
});

/** يحظر لاعب أو يفك حظره: ما يشوف ردوده ولا رأيه، وما تجمعه المطابقة معه. */
export const setBlocked = onCall(async (req) => {
  const uid = requireAuth(req);
  const target = String(req.data?.uid ?? '');
  const blocked = req.data?.blocked === true;
  if (!target || target === uid) throw new HttpsError('invalid-argument', 'اختار لاعب ثاني');
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const list = new Set(p.blocked ?? []);
    if (blocked) list.add(target);
    else list.delete(target);
    if (list.size > 300) throw new HttpsError('resource-exhausted', 'قائمة الحظر مليانة');
    tx.set(userRef(uid), { ...p, blocked: [...list] });
  });
  return {};
});

/** رسالة للمطور من داخل اللعبة (مشكلة، اقتراح، أو أي شي). */
export const sendFeedback = onCall(async (req) => {
  const uid = requireAuth(req);
  const text = String(req.data?.text ?? '').trim().slice(0, 1000);
  const kind = ['bug', 'idea', 'other'].includes(req.data?.kind) ? String(req.data.kind) : 'other';
  if (text.length < 3) throw new HttpsError('invalid-argument', 'اكتب رسالتك');
  const now = Date.now();
  const day = gulfDay(now);
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const count = p.feedbackDay === day ? (p.feedbackCount ?? 0) : 0;
    if (count >= 5) throw new HttpsError('resource-exhausted', 'وصلت حد الرسائل اليوم، نرد عليك قريب');
    tx.set(db.collection('feedback').doc(), {
      uid,
      name: p.name,
      kind,
      text,
      version: String(req.data?.version ?? '').slice(0, 20),
      at: now,
    });
    tx.set(userRef(uid), { ...p, feedbackDay: day, feedbackCount: count + 1 });
  });
  return {};
});

/**
 * حذف الحساب نهائياً: الملف، والاسم المحجوز، ومكانه في الترتيب، ورسائله، والحساب نفسه.
 * البلاغات اللي سواها تبقى بدون هويته (عشان ما ينمسح بلاغ صحيح عن لاعب ثاني).
 */
export const deleteAccount = onCall(async (req) => {
  await deleteUserData(requireAuth(req));
  return {};
});

/** يحذف كل بيانات اللاعب وحساب الدخول (من التطبيق نفسه، أو المطور لطلب حذف من الموقع). */
async function deleteUserData(uid: string): Promise<void> {
  const snap = await userRef(uid).get();
  const p = snap.data() as Profile | undefined;
  const batch = db.batch();
  batch.delete(userRef(uid));
  batch.delete(boardRef(uid));
  if (p?.nameKey) batch.delete(db.doc(`names/${p.nameKey}`));
  const [mine, feedback] = await Promise.all([
    db.collection('reports').where('reporter', '==', uid).get(),
    db.collection('feedback').where('uid', '==', uid).get(),
  ]);
  for (const d of mine.docs) batch.update(d.ref, { reporter: 'deleted' });
  for (const d of feedback.docs) batch.delete(d.ref);
  batch.delete(db.doc(`presence/${uid}`));
  await batch.commit();
  // محادثاته مع أصحابه تنحذف كلها.
  for (const friend of p?.friends ?? []) {
    const msgs = await db.collection(`dms/${dmPair(uid, friend)}/msgs`).limit(500).get();
    if (msgs.empty) continue;
    const wipe = db.batch();
    for (const d of msgs.docs) wipe.delete(d.ref);
    await wipe.commit();
  }
  // سجل مبارياته.
  for (;;) {
    const old = await userRef(uid).collection('history').limit(400).get();
    if (old.empty) break;
    const wipe = db.batch();
    for (const d of old.docs) wipe.delete(d.ref);
    await wipe.commit();
  }
  if (p) await forgetUser(uid, p);
  await getAuth()
    .deleteUser(uid)
    .catch((e) => logger.warn('حذف حساب الدخول', e));
  logger.info('حساب انحذف', { uid });
}

const MAX_DELETION_REQUESTS_PER_DAY = 200;

/**
 * طلب حذف حساب من صفحة الموقع (site/delete.html) لمن ما يقدر يدخل اللعبة. بدون تسجيل دخول،
 * فالمطور يراجعه ويحذف بنفسه (devTool → deleteUser). فيه حد يومي عشان ما ينضرب بالطلبات.
 */
export const requestDeletion = openCall(async (req) => {
  const name = String(req.data?.name ?? '').trim().slice(0, 40);
  const details = String(req.data?.details ?? '').trim().slice(0, 500);
  const contact = String(req.data?.contact ?? '').trim().slice(0, 100);
  if (name.length < 2) throw new HttpsError('invalid-argument', 'اكتب اسمك في اللعبة');
  const day = gulfDay(Date.now());
  await db.runTransaction(async (tx) => {
    // كل القراءات قبل الكتابات (شرط Firestore في العمليات).
    const counter = db.doc('meta/deletionRequests');
    const c = (await tx.get(counter)).data() as { day?: string; count?: number } | undefined;
    const owner = (await tx.get(db.doc(`names/${nameKey(name)}`))).data()?.uid ?? null;
    const count = c?.day === day ? (c.count ?? 0) : 0;
    if (count >= MAX_DELETION_REQUESTS_PER_DAY) throw new HttpsError('resource-exhausted', 'جرّب بكرة');
    tx.set(counter, { day, count: count + 1 });
    tx.set(db.collection('deletionRequests').doc(), { name, details, contact, uid: owner, at: Date.now(), status: 'open' });
  });
  return {};
});

interface ReportDoc {
  reporter: string;
  target: string;
  reason: string;
  code: string | null;
  name: string;
  at: number;
  status: string;
}

/** البلاغات المفتوحة، مجمّعة حسب اللاعب (الأكثر بلاغات أول). للمطور. */
async function openReports(): Promise<object[]> {
  const snap = await db.collection('reports').where('status', '==', 'open').limit(300).get();
  const byTarget = new Map<string, { target: string; name: string; count: number; reasons: Record<string, number>; last: number }>();
  for (const d of snap.docs) {
    const r = d.data() as ReportDoc;
    const g = byTarget.get(r.target) ?? { target: r.target, name: r.name, count: 0, reasons: {}, last: 0 };
    g.count++;
    g.reasons[r.reason] = (g.reasons[r.reason] ?? 0) + 1;
    if (r.at > g.last) {
      g.last = r.at;
      g.name = r.name;
    }
    byTarget.set(r.target, g);
  }
  return [...byTarget.values()].sort((a, b) => b.count - a.count || b.last - a.last);
}

async function recentFeedback(): Promise<object[]> {
  const snap = await db.collection('feedback').orderBy('at', 'desc').limit(50).get();
  return snap.docs.map((d) => {
    const f = d.data();
    return { name: f.name, kind: f.kind, text: f.text, at: f.at, version: f.version };
  });
}

/** المطور يقرر في بلاغات لاعب: rename (اسم محايد)، ban (منع لعدد أيام)، أو dismiss (ما فيه شي). */
async function resolveReports(target: string, decision: string, days: number): Promise<object> {
  if (!['rename', 'ban', 'dismiss'].includes(decision)) throw new HttpsError('invalid-argument', 'قرار مو معروف');
  const open = await db.collection('reports').where('target', '==', target).where('status', '==', 'open').get();
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef(target));
    if (snap.exists) {
      const p = snap.data() as Profile;
      if (decision === 'rename') renameTx(tx, target, p);
      if (decision === 'ban') tx.set(userRef(target), { ...p, bannedUntil: Date.now() + days * 86_400_000 });
    }
    for (const d of open.docs) tx.update(d.ref, { status: decision });
  });
  return { resolved: open.size };
}

async function openDeletionRequests(): Promise<object[]> {
  const snap = await db.collection('deletionRequests').where('status', '==', 'open').limit(100).get();
  return snap.docs
    .map((d) => ({ id: d.id, ...(d.data() as { name: string; details: string; contact: string; uid: string | null; at: number }) }))
    .sort((a, b) => b.at - a.at);
}

/** المطور يقرر في طلب حذف: confirm = يحذف الحساب (لو لقينا صاحب الاسم)، وإلا يقفل الطلب بدون حذف. */
async function deleteFromRequest(id: string, confirm: boolean): Promise<object> {
  const ref = db.doc(`deletionRequests/${id}`);
  const r = (await ref.get()).data() as { uid: string | null } | undefined;
  if (!r) throw new HttpsError('not-found', 'الطلب مو موجود');
  if (confirm && r.uid) await deleteUserData(r.uid);
  await ref.update({ status: confirm && r.uid ? 'deleted' : 'closed' });
  return { deleted: confirm && !!r.uid };
}

export { buyPid, findPlayer, friendRequest, friendRespond, inviteFriend, quotePid, removeFriend, suggestIds };
export {
  claimClanChest,
  clanInvite,
  clanInviteRespond,
  clanKick,
  clanRespond,
  clanRole,
  clanSettings,
  createClan,
  joinClan,
  leaveClan,
  readDm,
  sendChat,
  tourJoin,
};

/**
 * كل طلبات التطبيق من دالة وحدة: بعد أول طلب (لما تفتح اللعبة) تبقى صاحية لكل الأزرار، بدال ما كل
 * زر يصحّي دالته لحاله (أول ضغطة كانت تتأخر ثواني). ومعالج كامل يخليها تخدم طلبات كثير بنفس الوقت
 * بدال نسخة جديدة لكل طلب. الدوال لحالها باقية للنسخ القديمة من التطبيق.
 */
const ROUTES: Record<string, CallableFunction<unknown, unknown>> = {
  ensureProfile, devTool, updateProfile, claimLinkReward, claimDaily, createRoom, joinRoom, quickMatch, addBots,
  removeBot, leaveRoom, startGame, startTraining, startTutorial, act, leaveGame, timeout, buyItem, equipItem, rematch,
  registerPushToken, ackGifts, buyPass, giftPass, claimPassRewards, claimPassMission, claimMission, clearOpinion, react,
  setFavorites, reportPlayer, skipTutorial,
  spectate, stopWatching, createClan, joinClan, leaveClan, clanKick, clanRole, claimClanChest, tourJoin, tourPlay,
  clanSettings, clanRespond, clanInvite, clanInviteRespond, sendChat, readDm,
  setBlocked, sendFeedback, deleteAccount, findPlayer, friendRequest, friendRespond, removeFriend, inviteFriend,
  quotePid, suggestIds, buyPid,
};

export const api = onCall({ cpu: 1, memory: '512MiB', concurrency: 80 }, async (req) => {
  const route = ROUTES[String(req.data?.fn ?? '')];
  if (!route) throw new HttpsError('not-found', 'طلب مو معروف');
  return route.run({ ...req, data: req.data?.data ?? {} });
});
