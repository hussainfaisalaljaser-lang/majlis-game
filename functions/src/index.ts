import { randomInt } from 'node:crypto';
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore, type Transaction } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger, setGlobalOptions } from 'firebase-functions/v2';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';
import {
  MAX_PLAYERS,
  MIN_PLAYERS,
  PHASE_SECONDS,
  RuleError,
  applyAction,
  botAction,
  botSeerReveal,
  botClaim,
  createGame,
  currentActors,
  teamOf,
  timeoutActions,
  turnKey,
  viewFor,
  type Action,
  type GameState,
} from '../../engine/src/index.js';
import { LINK_REWARD, XP_PER_GAME, XP_PER_WIN, levelFor, tierById, type TableTier } from './economy.js';
import { MISSIONS, bumpMissions, gulfWeek, todaysMissions, type MissionId } from './missions.js';
import { whoToNotify, type Note } from './notify.js';
import {
  cleanAvatar,
  cleanName,
  dailyClaim,
  equippedOf,
  newProfile,
  readProfile,
  toLeaderboard,
  type Profile,
} from './profile.js';
import { isDefault, itemById, slotOf } from './shop.js';

initializeApp();
setGlobalOptions({ region: 'europe-west1', maxInstances: 10 });
const db = getFirestore();

export interface RoomPlayer {
  uid: string;
  name: string;
  avatar: string;
  /** إطار الصورة من المتجر، يشوفه الكل في الطاولة. */
  frame: string;
  /** لاعب آلي. يطلع للكل إنه بوت. */
  bot?: boolean;
}

const BOTS: Omit<RoomPlayer, 'uid'>[] = [
  { name: 'سلمان', avatar: 'sheikh', frame: 'frame_none' },
  { name: 'مها', avatar: 'pearl', frame: 'frame_none' },
  { name: 'بدر', avatar: 'desert', frame: 'frame_none' },
  { name: 'لولوة', avatar: 'jasmine', frame: 'frame_none' },
  { name: 'تركي', avatar: 'hawk', frame: 'frame_none' },
  { name: 'جود', avatar: 'rose', frame: 'frame_none' },
  { name: 'ماجد', avatar: 'merchant', frame: 'frame_none' },
  { name: 'العنود', avatar: 'sky', frame: 'frame_none' },
  { name: 'فيصل', avatar: 'youth', frame: 'frame_none' },
];

/** الطاولة العامة تنتظر كذا قبل ما نسمح نكملها بالبوتات. */
const BOT_FILL_AFTER_MS = 20_000;

/** اللي كسبه كل لاعب في آخر اللعبة. */
export interface GameResult {
  won: boolean;
  coins: number;
  xp: number;
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
  results?: Record<string, GameResult>;
}

export interface Reaction {
  from: string;
  kind: ReactionKind;
  target: string | null;
  at: number;
}

/** الردود المسموحة. ما فيه كتابة حرة أبداً. */
const REACTIONS = {
  suspect: true, // 🤨 أشك في…
  trust: true, // 🤝 أثق في…
  liar: true, // ❌ كذاب
  pick: true, // 👉 جربوا فلان
  innocent: false, // 🙏 أنا بريء
  laugh: false, // 😂
  think: false, // 🤔
  angry: false, // 😡
  eyes: false, // 👀
  zip: false, // 🤐
  smirk: false, // 😏
} as const;
type ReactionKind = keyof typeof REACTIONS;
const MAX_REACTIONS = 40;

// بدون الحروف اللي تتلخبط مثل O و 0 و I و 1.
const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function requireAuth(req: CallableRequest): string {
  if (!req.auth) throw new HttpsError('unauthenticated', 'لازم تسجل دخول');
  return req.auth.uid;
}

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

const userRef = (uid: string) => db.doc(`users/${uid}`);
const boardRef = (uid: string) => db.doc(`leaderboard/${uid}`);
const asPlayer = (uid: string, p: Profile): RoomPlayer => ({
  uid,
  name: p.name,
  avatar: p.avatar,
  frame: equippedOf(p).frame,
});

/**
 * يرسل الإشعارات بعد ما تنحفظ الحركة. أي خطأ هنا ما يأثر على اللعبة.
 * الأجهزة اللي ما عادت موجودة تنشال من ملف اللاعب.
 */
async function sendPush(code: string, notes: Note[]): Promise<void> {
  if (notes.length === 0) return;
  try {
    const uids = [...new Set(notes.map((n) => n.uid))];
    const snaps = await db.getAll(...uids.map(userRef));
    const tokens = new Map(snaps.map((s) => [s.id, ((s.data() as Profile | undefined)?.fcmTokens ?? []) as string[]]));
    const messages = notes.flatMap((n) =>
      (tokens.get(n.uid) ?? []).map((token) => ({
        token,
        notification: { title: n.title, body: n.body },
        data: { code },
        // الـ tag يخلي إشعار الطاولة الجديد يحل محل القديم بدل ما تتكوم.
        android: { priority: 'high' as const, notification: { tag: code, icon: 'ic_stat_notify', color: '#F5B942' } },
      })),
    );
    if (messages.length === 0) return;
    const res = await getMessaging().sendEach(messages);
    const dead = res.responses
      .map((r, i) => (r.error?.code === 'messaging/registration-token-not-registered' ? messages[i].token : null))
      .filter((t): t is string => t !== null);
    await Promise.all(
      [...tokens.entries()].map(([uid, list]) => {
        const gone = list.filter((t) => dead.includes(t));
        return gone.length ? userRef(uid).update({ fcmTokens: FieldValue.arrayRemove(...gone) }) : null;
      }),
    );
  } catch (e) {
    logger.warn('push failed', e);
  }
}

/** يتأكد إن اللاعب يقدر يدخل الطاولة (المستوى والذهب والـ VIP). */
function checkTier(p: Profile, tier: TableTier): void {
  if (tier.vipOnly && !p.vip) throw new HttpsError('permission-denied', 'هذي الطاولة لأعضاء VIP بس');
  if (p.level < tier.requiredLevel) {
    throw new HttpsError('permission-denied', `هذي الطاولة تفتح في مستوى ${tier.requiredLevel}`);
  }
}

/** يخصم رسوم الدخول ويحفظ الملف (يسويه لو جديد). */
function chargeEntry(tx: Transaction, uid: string, p: Profile, fee: number): void {
  if (p.coins < fee) throw new HttpsError('failed-precondition', 'ما عندك ذهب كافي 🪙');
  tx.set(userRef(uid), { ...p, coins: p.coins - fee });
}

/** يبدأ اللعبة داخل نفس العملية: يوزع الأدوار ويكتب نسخة كل لاعب. */
function startGameTx(tx: Transaction, room: Room): GameState {
  const state = createGame(
    room.players.map((p) => ({ id: p.uid, name: p.name })),
    randomInt(2 ** 31),
  );
  tx.update(db.doc(`rooms/${room.code}`), { status: 'playing' });
  writeGame(tx, room.code, state, deadlineFor(state, Date.now()));
  return state;
}

const isBot = (id: string) => id.startsWith('bot_');

/**
 * آخر وقت للدور الحالي (بالملي ثانية). لو الدور على بوت، نعطيه ٢–٤ ثواني بس
 * عشان يبان إنه يفكر، وبعدها أي جوال في الطاولة يطلب من السيرفر يلعب عنه.
 */
function deadlineFor(state: GameState, now: number): number | null {
  if (state.phase === 'gameOver') return null;
  const actors = currentActors(state);
  if (actors.length > 0 && actors.every(isBot)) return now + 2000 + randomInt(2000);
  return now + PHASE_SECONDS[state.phase] * 1000;
}

/** حركات البوتات اللي ما تحتاج انتظار: التصويت (سري لين يكتمل)، والادعاء بعد الحكم، وكشف العرّاف. */
function runInstantBots(state: GameState): GameState {
  let s = state;
  for (let guard = 0; guard < 50 && s.phase !== 'gameOver'; guard++) {
    let changed = false;
    const leg = s.lastLegislature;
    if (leg) {
      for (const [office, id] of [['president', leg.government.president], ['chancellor', leg.government.chancellor]] as const) {
        if (isBot(id) && !leg.claimed.includes(id) && s.players.find((p) => p.id === id)?.alive) {
          s = applyAction(s, id, { type: 'claim', policies: botClaim(s, id, office, Math.random) });
          changed = true;
        }
      }
    }
    // العرّاف البوت يستخدم كشفه لما يجي وقته (من الجولة الثانية).
    for (const p of s.players) {
      if (!isBot(p.id)) continue;
      const target = botSeerReveal(s, p.id);
      if (target) {
        s = applyAction(s, p.id, { type: 'seerReveal', target });
        changed = true;
      }
    }
    if (s.phase === 'election') {
      for (const id of currentActors(s).filter(isBot)) {
        if (s.phase !== 'election') break;
        s = applyAction(s, id, botAction(s, id)!);
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
    tx.set(gameRef.collection('views').doc(p.id), { ...viewFor(state, p.id), deadline });
  }
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
  await db.runTransaction(async (tx) => {
    if (!(await tx.get(userRef(uid))).exists) tx.set(userRef(uid), newProfile());
  });
  return {};
});

export const updateProfile = onCall(async (req) => {
  const uid = requireAuth(req);
  const name = cleanName(req.data?.name);
  const avatar = cleanAvatar(req.data?.avatar);
  await db.runTransaction(async (tx) => {
    const p = { ...(await readProfile(db, tx, uid)), name, avatar, setupDone: true };
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
    };
    tx.set(db.doc(`rooms/${code}`), room);
  });
  return { code };
});

export const joinRoom = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '').trim().toUpperCase();
  if (!/^[A-Z0-9]{5}$/.test(code)) throw new HttpsError('invalid-argument', 'الكود لازم يكون ٥ حروف');
  const started = await db.runTransaction(async (tx): Promise<GameState | null> => {
    const ref = db.doc(`rooms/${code}`);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'ما فيه روم بهذا الكود');
    const room = snap.data() as Room;
    if (room.players.some((p) => p.uid === uid)) return null;
    if (room.status !== 'waiting') throw new HttpsError('failed-precondition', 'اللعبة بدأت');
    if (room.players.length >= room.maxPlayers) throw new HttpsError('failed-precondition', 'الروم مليان');
    const p = await readProfile(db, tx, uid);
    const tier = tierById(room.tierId);
    if (tier) checkTier(p, tier);
    if (room.entryFee > 0) chargeEntry(tx, uid, p, room.entryFee);
    room.players.push(asPlayer(uid, p));
    tx.update(ref, { players: room.players });
    return !room.isPrivate && room.players.length === room.maxPlayers ? startGameTx(tx, room) : null;
  });
  if (started) await sendPush(code, whoToNotify(null, started));
  return { code };
});

/** "العب الحين": يدخلك أول روم عام فيه مكان بنفس الطاولة وعدد اللاعبين، أو يسوي واحد جديد. */
export const quickMatch = onCall(async (req) => {
  const uid = requireAuth(req);
  const maxPlayers = cleanMaxPlayers(req.data?.maxPlayers);
  const tier = tierById(req.data?.tierId);
  if (!tier) throw new HttpsError('invalid-argument', 'اختار طاولة');

  const open = await db
    .collection('rooms')
    .where('status', '==', 'waiting')
    .where('isPrivate', '==', false)
    .where('maxPlayers', '==', maxPlayers)
    .where('tierId', '==', tier.id)
    .limit(10)
    .get();

  for (const doc of open.docs) {
    const joined = await db.runTransaction(async (tx): Promise<{ started: GameState | null } | null> => {
      const room = (await tx.get(doc.ref)).data() as Room | undefined;
      const p = await readProfile(db, tx, uid);
      if (!room || room.status !== 'waiting' || room.players.length >= room.maxPlayers) return null;
      if (room.players.some((x) => x.uid === uid)) return { started: null };
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
    if (room.entryFee > 0) tx.set(userRef(uid), { ...p, coins: p.coins + room.entryFee });
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
    let next: GameState;
    try {
      next = applyAction(prev.state, uid, action);
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
  const roomRef = db.doc(`rooms/${code}`);
  const room = over ? ((await tx.get(roomRef)).data() as Room) : null;
  const profiles = await Promise.all(uids.map((uid) => readProfile(db, tx, uid)));

  const deadline = turnKey(next) === prev.key ? prev.deadline : deadlineFor(next, now);
  writeGame(tx, code, next, deadline);

  if (!room) {
    uids.forEach((uid, i) => {
      const p = profiles[i];
      tx.set(userRef(uid), { ...p, missions: bumpMissions(p.missions, now, bumps.get(uid)!) });
    });
    return whoToNotify(prev.state, next);
  }

  // البوتات ما يدفعون، فالجائزة من رسوم البشر بس. ونصيب البوت الفايز ما يروح لأحد.
  const winners = next.players.filter((p) => teamOf(p.role) === next.winner);
  const pot = room.entryFee * humans.length;
  const share = winners.length ? Math.floor(pot / winners.length) : 0;
  const week = gulfWeek(now);
  const results: Record<string, GameResult> = {};
  humans.forEach((player, i) => {
    const won = teamOf(player.role) === next.winner;
    const p = profiles[i];
    const xp = XP_PER_GAME + (won ? XP_PER_WIN : 0);
    const coins = won ? share : 0;
    results[player.id] = { won, coins, xp };
    const updated: Profile = {
      ...p,
      coins: p.coins + coins,
      xp: p.xp + xp,
      level: levelFor(p.xp + xp),
      gamesPlayed: p.gamesPlayed + 1,
      gamesWon: p.gamesWon + (won ? 1 : 0),
      week,
      weeklyWins: (p.week === week ? (p.weeklyWins ?? 0) : 0) + (won ? 1 : 0),
      missions: bumpMissions(p.missions, now, { ...bumps.get(player.id), play3: 1, ...(won ? { win1: 1 } : {}) }),
    };
    tx.set(userRef(player.id), updated);
    tx.set(boardRef(player.id), toLeaderboard(updated));
  });
  tx.update(roomRef, { status: 'finished', results });
  return whoToNotify(prev.state, next);
}

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

    let next = prev.state;
    const actors = currentActors(prev.state);
    if (actors.length === 1 && isBot(actors[0])) {
      next = applyAction(next, actors[0], botAction(next, actors[0])!);
    } else {
      for (const [id, a] of timeoutActions(prev.state, Math.random)) next = applyAction(next, id, a);
    }
    return finishTurn(tx, code, prev, next, new Map());
  });
  if (notes) await sendPush(code, notes);
  return { applied: notes !== null };
});

/** شراء غرض من المتجر بالذهب أو الجواهر. */
export const buyItem = onCall(async (req) => {
  const uid = requireAuth(req);
  const item = itemById(req.data?.id);
  if (!item) throw new HttpsError('invalid-argument', 'غرض مو معروف');
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const owned = p.owned ?? [];
    if (owned.includes(item.id)) throw new HttpsError('already-exists', 'عندك هذا الغرض');
    const balance = item.currency === 'coins' ? p.coins : p.diamonds;
    if (balance < item.price) {
      throw new HttpsError('failed-precondition', item.currency === 'coins' ? 'ما عندك ذهب كافي 🪙' : 'ما عندك جواهر كافية 💎');
    }
    tx.set(userRef(uid), {
      ...p,
      [item.currency]: balance - item.price,
      owned: [...owned, item.id],
      equipped: { ...equippedOf(p), [item.slot]: item.id },
    });
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
    if (!isDefault(id) && !(p.owned ?? []).includes(id)) throw new HttpsError('permission-denied', 'ما تملك هذا الغرض');
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
    tx.set(userRef(uid), {
      ...p,
      coins: p.coins + mission.coins,
      missions: { ...today, claimed: [...today.claimed, mission.id] },
    });
    return { coins: mission.coins };
  });
});

/** رد سريع في الطاولة. بعض الردود تحتاج لاعب مستهدف (مثل أشك في فلان). */
export const react = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  const kind = req.data?.kind as ReactionKind;
  if (!(kind in REACTIONS)) throw new HttpsError('invalid-argument', 'رد مو معروف');
  const target = REACTIONS[kind] ? String(req.data?.target ?? '') : null;

  await db.runTransaction(async (tx) => {
    const ref = db.doc(`rooms/${code}`);
    const room = (await tx.get(ref)).data() as Room | undefined;
    const profile = await readProfile(db, tx, uid);
    if (!room || room.status !== 'playing') throw new HttpsError('failed-precondition', 'اللعبة مو شغالة');
    if (!room.players.some((p) => p.uid === uid)) throw new HttpsError('permission-denied', 'أنت مو في هذي الطاولة');
    if (target !== null && (target === uid || !room.players.some((p) => p.uid === target))) {
      throw new HttpsError('invalid-argument', 'اختار لاعب ثاني');
    }
    const now = Date.now();
    const recent = (room.reactions ?? []).filter((r) => r.from === uid && now - r.at < 1500);
    if (recent.length > 0) throw new HttpsError('resource-exhausted', 'شوي شوي 😅');
    const reactions = [...(room.reactions ?? []), { from: uid, kind, target, at: now }].slice(-MAX_REACTIONS);
    const update: Record<string, unknown> = { reactions };
    if (kind === 'suspect' || kind === 'trust') update[`opinions.${uid}.${target}`] = kind;
    tx.update(ref, update);
    tx.set(userRef(uid), { ...profile, missions: bumpMissions(profile.missions, now, { react5: 1 }) });
  });
  return {};
});
