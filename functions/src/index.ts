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
  viewFor,
  type Action,
  type GameState,
} from '../../engine/src/index.js';

initializeApp();
setGlobalOptions({ region: 'europe-west1', maxInstances: 10 });
const db = getFirestore();

export interface RoomPlayer {
  uid: string;
  name: string;
  avatar: string;
}

export interface Room {
  code: string;
  hostId: string;
  status: 'waiting' | 'playing' | 'finished';
  isPrivate: boolean;
  maxPlayers: number;
  tierId: string | null;
  players: RoomPlayer[];
  createdAt: FieldValue;
  /** آخر الردود السريعة في الطاولة (أشك، أثق، إيموجي…). */
  reactions?: Reaction[];
  /** رأي كل لاعب في الباقين: opinions[من][في] = أشك أو أثق. منه نحسب مؤشر الشك. */
  opinions?: Record<string, Record<string, 'suspect' | 'trust'>>;
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
const AVATARS = ['😎', '👩', '🧔', '👨‍🦱', '👴', '👱‍♀️', '🧑', '👩‍🦰', '👨', '🧕'];

function requireAuth(req: CallableRequest): string {
  if (!req.auth) throw new HttpsError('unauthenticated', 'لازم تسجل دخول');
  return req.auth.uid;
}

function cleanPlayer(uid: string, data: { name?: unknown; avatar?: unknown }): RoomPlayer {
  const name = typeof data.name === 'string' ? data.name.trim().slice(0, 20) : '';
  const avatar = typeof data.avatar === 'string' && AVATARS.includes(data.avatar) ? data.avatar : AVATARS[0];
  return { uid, name: name || 'ضيف', avatar };
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

export const createRoom = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = await newRoomCode();
  const room: Room = {
    code,
    hostId: uid,
    status: 'waiting',
    isPrivate: req.data?.isPrivate !== false,
    maxPlayers: cleanMaxPlayers(req.data?.maxPlayers),
    tierId: typeof req.data?.tierId === 'string' ? req.data.tierId : null,
    players: [cleanPlayer(uid, req.data ?? {})],
    createdAt: FieldValue.serverTimestamp(),
  };
  await db.doc(`rooms/${code}`).set(room);
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
    room.players.push(cleanPlayer(uid, req.data ?? {}));
    tx.update(ref, { players: room.players });
    if (!room.isPrivate && room.players.length === room.maxPlayers) startGameTx(tx, room);
  });
  return { code };
});

/** "العب الحين": يدخلك أول روم عام فاضي بنفس الإعدادات، أو يسوي واحد جديد. */
export const quickMatch = onCall(async (req) => {
  const uid = requireAuth(req);
  const maxPlayers = cleanMaxPlayers(req.data?.maxPlayers);
  const tierId = typeof req.data?.tierId === 'string' ? req.data.tierId : null;
  const player = cleanPlayer(uid, req.data ?? {});

  const open = await db
    .collection('rooms')
    .where('status', '==', 'waiting')
    .where('isPrivate', '==', false)
    .where('maxPlayers', '==', maxPlayers)
    .where('tierId', '==', tierId)
    .limit(10)
    .get();

  for (const doc of open.docs) {
    const joined = await db.runTransaction(async (tx) => {
      const snap = await tx.get(doc.ref);
      const room = snap.data() as Room | undefined;
      if (!room || room.status !== 'waiting' || room.players.length >= room.maxPlayers) return false;
      if (!room.players.some((p) => p.uid === uid)) room.players.push(player);
      tx.update(doc.ref, { players: room.players });
      if (room.players.length === room.maxPlayers) startGameTx(tx, room);
      return true;
    });
    if (joined) return { code: doc.id };
  }

  const code = await newRoomCode();
  const room: Room = {
    code,
    hostId: uid,
    status: 'waiting',
    isPrivate: false,
    maxPlayers,
    tierId,
    players: [player],
    createdAt: FieldValue.serverTimestamp(),
  };
  await db.doc(`rooms/${code}`).set(room);
  return { code };
});

export const leaveRoom = onCall(async (req) => {
  const uid = requireAuth(req);
  const code = String(req.data?.code ?? '');
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`rooms/${code}`);
    const snap = await tx.get(ref);
    const room = snap.data() as Room | undefined;
    if (!room || room.status !== 'waiting') return;
    const players = room.players.filter((p) => p.uid !== uid);
    if (players.length === 0) tx.delete(ref);
    else tx.update(ref, { players, hostId: room.hostId === uid ? players[0].uid : room.hostId });
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
    writeGame(tx, code, next);
    if (next.phase === 'gameOver') tx.update(db.doc(`rooms/${code}`), { status: 'finished' });
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
