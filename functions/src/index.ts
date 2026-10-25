import { randomInt } from 'node:crypto';
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore, type Transaction } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';
import {
  MAX_PLAYERS,
  MIN_PLAYERS,
  RuleError,
  applyAction,
  createGame,
  teamOf,
  viewFor,
  type Action,
  type GameState,
} from '../../engine/src/index.js';
import { XP_PER_GAME, XP_PER_WIN, levelFor, tierById, type TableTier } from './economy.js';
import { cleanAvatar, cleanName, dailyClaim, newProfile, readProfile, type Profile } from './profile.js';

initializeApp();
setGlobalOptions({ region: 'europe-west1', maxInstances: 10 });
const db = getFirestore();

export interface RoomPlayer {
  uid: string;
  name: string;
  avatar: string;
}

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
const asPlayer = (uid: string, p: Profile): RoomPlayer => ({ uid, name: p.name, avatar: p.avatar });

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
function startGameTx(tx: Transaction, room: Room): void {
  const state = createGame(
    room.players.map((p) => ({ id: p.uid, name: p.name })),
    randomInt(2 ** 31),
  );
  tx.update(db.doc(`rooms/${room.code}`), { status: 'playing' });
  writeGame(tx, room.code, state);
}

function writeGame(tx: Transaction, code: string, state: GameState): void {
  const gameRef = db.doc(`games/${code}`);
  tx.set(gameRef, state);
  for (const p of state.players) tx.set(gameRef.collection('views').doc(p.id), viewFor(state, p.id));
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
    const p = await readProfile(db, tx, uid);
    tx.set(userRef(uid), { ...p, name, avatar, setupDone: true });
  });
  return {};
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
    };
    tx.set(db.doc(`rooms/${code}`), room);
  });
  return { code };
});

export const joinRoom = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '').trim().toUpperCase();
  if (!/^[A-Z0-9]{5}$/.test(code)) throw new HttpsError('invalid-argument', 'الكود لازم يكون ٥ حروف');
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`rooms/${code}`);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'ما فيه روم بهذا الكود');
    const room = snap.data() as Room;
    if (room.players.some((p) => p.uid === uid)) return;
    if (room.status !== 'waiting') throw new HttpsError('failed-precondition', 'اللعبة بدأت');
    if (room.players.length >= room.maxPlayers) throw new HttpsError('failed-precondition', 'الروم مليان');
    const p = await readProfile(db, tx, uid);
    const tier = tierById(room.tierId);
    if (tier) checkTier(p, tier);
    if (room.entryFee > 0) chargeEntry(tx, uid, p, room.entryFee);
    room.players.push(asPlayer(uid, p));
    tx.update(ref, { players: room.players });
    if (!room.isPrivate && room.players.length === room.maxPlayers) startGameTx(tx, room);
  });
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
    const joined = await db.runTransaction(async (tx) => {
      const room = (await tx.get(doc.ref)).data() as Room | undefined;
      const p = await readProfile(db, tx, uid);
      if (!room || room.status !== 'waiting' || room.players.length >= room.maxPlayers) return false;
      if (room.players.some((x) => x.uid === uid)) return true;
      checkTier(p, tier);
      chargeEntry(tx, uid, p, room.entryFee);
      room.players.push(asPlayer(uid, p));
      tx.update(doc.ref, { players: room.players });
      if (room.players.length === room.maxPlayers) startGameTx(tx, room);
      return true;
    });
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
    };
    tx.set(db.doc(`rooms/${code}`), room);
  });
  return { code };
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
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(db.doc(`rooms/${code}`));
    const room = snap.data() as Room | undefined;
    if (!room) throw new HttpsError('not-found', 'الروم مو موجود');
    if (room.hostId !== uid) throw new HttpsError('permission-denied', 'بس صاحب الروم يقدر يبدأ');
    if (room.status !== 'waiting') throw new HttpsError('failed-precondition', 'اللعبة بدأت');
    if (room.players.length < MIN_PLAYERS) {
      throw new HttpsError('failed-precondition', `لازم ${MIN_PLAYERS} لاعبين على الأقل`);
    }
    startGameTx(tx, room);
  });
  return {};
});

/** كل حركة في اللعبة تمر من هنا. السيرفر يتأكد إنها مسموحة قبل ما يطبقها. */
export const act = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  const action = req.data?.action as Action | undefined;
  if (!action || typeof action.type !== 'string') throw new HttpsError('invalid-argument', 'حركة ناقصة');

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(db.doc(`games/${code}`));
    if (!snap.exists) throw new HttpsError('not-found', 'اللعبة مو موجودة');
    let next: GameState;
    try {
      next = applyAction(snap.data() as GameState, uid, action);
    } catch (e) {
      if (e instanceof RuleError) throw new HttpsError('failed-precondition', e.message, { code: e.code });
      throw e;
    }

    if (next.phase !== 'gameOver') {
      writeGame(tx, code, next);
      return;
    }
    // انتهت اللعبة: نقرا الروم وملفات اللاعبين قبل أي كتابة (شرط Firestore)، ثم نوزع الجائزة.
    const roomRef = db.doc(`rooms/${code}`);
    const room = (await tx.get(roomRef)).data() as Room;
    const profiles = await Promise.all(next.players.map((p) => readProfile(db, tx, p.id)));
    const winners = next.players.filter((p) => teamOf(p.role) === next.winner);
    const pot = room.entryFee * next.players.length;
    const share = winners.length ? Math.floor(pot / winners.length) : 0;

    const results: Record<string, GameResult> = {};
    next.players.forEach((player, i) => {
      const won = teamOf(player.role) === next.winner;
      const p = profiles[i];
      const xp = XP_PER_GAME + (won ? XP_PER_WIN : 0);
      const coins = won ? share : 0;
      results[player.id] = { won, coins, xp };
      tx.set(userRef(player.id), {
        ...p,
        coins: p.coins + coins,
        xp: p.xp + xp,
        level: levelFor(p.xp + xp),
        gamesPlayed: p.gamesPlayed + 1,
        gamesWon: p.gamesWon + (won ? 1 : 0),
      });
    });
    writeGame(tx, code, next);
    tx.update(roomRef, { status: 'finished', results });
  });
  return {};
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
  });
  return {};
});
