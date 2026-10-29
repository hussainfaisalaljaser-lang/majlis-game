/**
 * الأصدقاء ورموز اللاعبين.
 * - كل لاعب له رمز (pid) فريد محجوز في ids/{pid}، يبحثون فيه عنه ويضيفونه.
 * - طلب الصداقة ينحفظ عند الثاني (friendReqs)، ولو قبله يصيرون أصدقاء عند الاثنين.
 * - تدعو صديقك لرومك: توصله الدعوة في اللعبة وبإشعار، ولو ضغطها يدخل الروم.
 * - الرمز المميز ينشرى بالجواهر (السعر من ids.ts)، والرمز القديم ينفك لغيره.
 */
import { randomInt } from 'node:crypto';
import { FieldValue, type Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { boardRef, db, requireAuth, userRef } from './base.js';
import { pidPrice, pidTier, randomPid, suggestPids, validPid } from './ids.js';
import { toLeaderboard, type Profile } from './profile.js';
import { sendNotes } from './push.js';
import { onCall } from './security.js';

export const MAX_FRIENDS = 200;
const MAX_REQUESTS = 50;
/** بين كل دعوتين لنفس الصديق. */
const INVITE_GAP_MS = 60_000;

const idRef = (pid: string) => db.doc(`ids/${pid}`);
const rand = () => randomInt(2 ** 30) / 2 ** 30;
const without = (list: string[] | undefined, id: string) => (list ?? []).filter((x) => x !== id);

function otherUid(raw: unknown, me: string): string {
  const uid = typeof raw === 'string' ? raw : '';
  if (!uid || uid === me || uid.startsWith('bot_') || uid.includes('/')) {
    throw new HttpsError('invalid-argument', 'لا تستطيع أن تسويها مع هاللاعب');
  }
  return uid;
}

/** يحجز رمز عادي جديد داخل عملية (القراءات قبل الكتابة). */
export async function reservePid(tx: Transaction, uid: string): Promise<string> {
  const options = [randomPid(rand), randomPid(rand), randomPid(rand)];
  const snaps = await tx.getAll(...options.map(idRef));
  const pid = options.find((_, i) => !snaps[i].exists);
  if (!pid) throw new HttpsError('aborted', 'صار خطأ بسيط، جرّب مرة ثانية');
  tx.set(idRef(pid), { uid, at: Date.now() });
  return pid;
}

/** يصيرون أصدقاء: كل واحد في قائمة الثاني، والطلبات بينهم تنشال. */
function befriend(p: Profile, other: string): Partial<Profile> {
  const reqs = { ...p.friendReqs };
  delete reqs[other];
  return { friends: [...without(p.friends, other), other], friendReqs: reqs, sentReqs: without(p.sentReqs, other) };
}

/** طلبات الصداقة اللي وصلته: نخلي الأحدث بس لو كثرت. */
function trimReqs(reqs: Record<string, number>): Record<string, number> {
  return Object.fromEntries(
    Object.entries(reqs)
      .sort((a, b) => b[1] - a[1])
      .slice(0, MAX_REQUESTS),
  );
}

/** يدور لاعب برمزه. يرجع اللي يطلع للناس بس (مثل جدول الترتيب). */
export const findPlayer = onCall(async (req) => {
  requireAuth(req);
  const pid = String(req.data?.pid ?? '').trim();
  if (!validPid(pid)) throw new HttpsError('invalid-argument', 'الرمز أرقام فقط، من ٣ إلى ٨');
  const owner = (await idRef(pid).get()).data()?.uid as string | undefined;
  const p = owner ? ((await userRef(owner).get()).data() as Profile | undefined) : undefined;
  if (!owner || !p?.setupDone) throw new HttpsError('not-found', 'ما لقينا لاعب بهالرمز');
  return { uid: owner, ...toLeaderboard(p) };
});

/** طلب صداقة. لو هو أرسل لك قبل، تصيرون أصدقاء على طول. */
export const friendRequest = onCall(async (req) => {
  const uid = requireAuth(req);
  const to = otherUid(req.data?.uid, uid);
  const { status, name } = await db.runTransaction(async (tx) => {
    const [meSnap, themSnap] = await tx.getAll(userRef(uid), userRef(to));
    if (!themSnap.exists || !meSnap.exists) throw new HttpsError('not-found', 'اللاعب مو موجود');
    const me = meSnap.data() as Profile;
    const them = themSnap.data() as Profile;
    if ((me.friends ?? []).includes(to)) return { status: 'friends', name: me.name };
    if ((me.blocked ?? []).includes(to)) throw new HttpsError('failed-precondition', 'فك الحظر عنه أول');
    if ((me.friends ?? []).length >= MAX_FRIENDS) throw new HttpsError('resource-exhausted', 'وصلت حد الأصدقاء');
    if (me.friendReqs?.[to]) {
      if ((them.friends ?? []).length >= MAX_FRIENDS) throw new HttpsError('resource-exhausted', 'قائمة أصدقائه مليانة');
      tx.update(userRef(uid), befriend(me, to));
      tx.update(userRef(to), befriend(them, uid));
      return { status: 'accepted', name: me.name };
    }
    const sent = me.sentReqs ?? [];
    if (sent.includes(to)) return { status: 'sent', name: me.name };
    if (sent.length >= MAX_REQUESTS) throw new HttpsError('resource-exhausted', 'عندك طلبات كثير ما انردت، انتظر قليلاً');
    tx.update(userRef(uid), { sentReqs: [...sent, to] });
    // اللي حاظرك ما يوصله طلبك (وما نقول لك إنه حاظرك).
    if ((them.blocked ?? []).includes(uid)) return { status: 'sent', name: me.name };
    tx.update(userRef(to), { friendReqs: trimReqs({ ...them.friendReqs, [uid]: Date.now() }) });
    return { status: 'new', name: me.name };
  });
  if (status === 'new') await sendNotes([{ uid: to, title: 'طلب صداقة', body: `${name} يبي يضيفك صديق` }], { kind: 'friend' }, 'friend');
  if (status === 'accepted') await sendNotes([{ uid: to, title: 'صرتوا أصدقاء', body: `${name} قبل طلب صداقتك` }], { kind: 'friend' }, 'friend');
  return { status: status === 'new' ? 'sent' : status };
});

/** يقبل طلب صداقة أو يرفضه. */
export const friendRespond = onCall(async (req) => {
  const uid = requireAuth(req);
  const from = otherUid(req.data?.uid, uid);
  const accept = req.data?.accept === true;
  const name = await db.runTransaction(async (tx) => {
    const [meSnap, themSnap] = await tx.getAll(userRef(uid), userRef(from));
    const me = meSnap.data() as Profile;
    const them = themSnap.data() as Profile | undefined;
    if (!me?.friendReqs?.[from]) throw new HttpsError('not-found', 'الطلب انتهى');
    if (accept && them) {
      if ((me.friends ?? []).length >= MAX_FRIENDS) throw new HttpsError('resource-exhausted', 'وصلت حد الأصدقاء');
      if ((them.friends ?? []).length >= MAX_FRIENDS) throw new HttpsError('resource-exhausted', 'قائمة أصدقائه مليانة');
      tx.update(userRef(uid), befriend(me, from));
      tx.update(userRef(from), befriend(them, uid));
      return me.name;
    }
    tx.update(userRef(uid), { [`friendReqs.${from}`]: FieldValue.delete() });
    if (them) tx.update(userRef(from), { sentReqs: without(them.sentReqs, uid) });
    return null;
  });
  if (name) await sendNotes([{ uid: from, title: 'صرتوا أصدقاء', body: `${name} قبل طلب صداقتك` }], { kind: 'friend' }, 'friend');
  return {};
});

/** يشيل صديق (من القائمتين). */
export const removeFriend = onCall(async (req) => {
  const uid = requireAuth(req);
  const other = otherUid(req.data?.uid, uid);
  await db.runTransaction(async (tx) => {
    const [meSnap, themSnap] = await tx.getAll(userRef(uid), userRef(other));
    if (meSnap.exists) tx.update(userRef(uid), { friends: without((meSnap.data() as Profile).friends, other) });
    if (themSnap.exists) tx.update(userRef(other), { friends: without((themSnap.data() as Profile).friends, uid) });
  });
  return {};
});

/** يدعو صديق لرومه: الدعوة تطلع له في اللعبة، ويوصله إشعار. */
export const inviteFriend = onCall(async (req) => {
  const uid = requireAuth(req);
  const to = otherUid(req.data?.uid, uid);
  const code = String(req.data?.code ?? '').toUpperCase();
  if (!/^[A-Z0-9]{5}$/.test(code)) throw new HttpsError('invalid-argument', 'الطاولة مو موجودة');
  const now = Date.now();
  const name = await db.runTransaction(async (tx) => {
    const [meSnap, themSnap, roomSnap] = await tx.getAll(userRef(uid), userRef(to), db.doc(`rooms/${code}`));
    const me = meSnap.data() as Profile;
    const them = themSnap.data() as Profile | undefined;
    const room = roomSnap.data() as { status: string; players: { uid: string }[]; maxPlayers: number } | undefined;
    if (!me || !them || !(me.friends ?? []).includes(to)) throw new HttpsError('failed-precondition', 'تستطيع أن تدعو أصدقاءك فقط');
    if (!room || room.status !== 'waiting' || !room.players.some((p) => p.uid === uid)) {
      throw new HttpsError('failed-precondition', 'يجب أن تكون في طاولة تنتظر لاعبين');
    }
    if (room.players.some((p) => p.uid === to)) throw new HttpsError('already-exists', 'صديقك موجود في الطاولة');
    if (room.players.length >= room.maxPlayers) throw new HttpsError('failed-precondition', 'الطاولة مليانة');
    if (now - (me.invitedAt?.[to] ?? 0) < INVITE_GAP_MS) throw new HttpsError('resource-exhausted', 'دعيته قبل قليلاً، انتظر دقيقة');
    // نخلي آخر دعوة لكل صديق بس (اللي ما عادوا أصدقاء ينشالون).
    const invitedAt = Object.fromEntries(Object.entries({ ...me.invitedAt, [to]: now }).filter(([id]) => (me.friends ?? []).includes(id)));
    tx.update(userRef(uid), { invitedAt });
    if (!(them.blocked ?? []).includes(uid)) tx.update(userRef(to), { invite: { from: uid, name: me.name, code, at: now } });
    return me.name;
  });
  await sendNotes([{ uid: to, title: 'دعوة للعب', body: `${name} يدعوك تلعب معه في المجلس` }], { kind: 'invite', code }, 'invite');
  return {};
});

/** سعر رمز مميز، وهل هو متاح. */
export const quotePid = onCall(async (req) => {
  const uid = requireAuth(req);
  const pid = String(req.data?.pid ?? '').trim();
  if (!validPid(pid)) throw new HttpsError('invalid-argument', 'الرمز أرقام فقط، من ٣ إلى ٨، وما يبدأ بصفر');
  const owner = (await idRef(pid).get()).data()?.uid as string | undefined;
  return { pid, price: pidPrice(pid), tier: pidTier(pid), available: !owner, mine: owner === uid };
});

/** اقتراحات رموز مميزة متاحة، من كل الدرجات. */
export const suggestIds = onCall(async (req) => {
  requireAuth(req);
  const options = [...new Set([...suggestPids(rand), ...suggestPids(rand)])];
  const snaps = await db.getAll(...options.map(idRef));
  const free = options.filter((_, i) => !snaps[i].exists);
  const byTier = new Map<number, string[]>();
  for (const pid of free) byTier.set(pidTier(pid), [...(byTier.get(pidTier(pid)) ?? []), pid]);
  // من كل درجة شوي، الأغلى أول.
  const list = [...byTier.entries()].sort((a, b) => b[0] - a[0]).flatMap(([, pids]) => pids.slice(0, 3));
  return { list: list.slice(0, 12).map((pid) => ({ pid, price: pidPrice(pid), tier: pidTier(pid) })) };
});

/** يشتري رمز مميز بالجواهر. رمزه القديم ينفك وممكن ياخذه غيره. */
export const buyPid = onCall(async (req) => {
  const uid = requireAuth(req);
  const pid = String(req.data?.pid ?? '').trim();
  if (!validPid(pid)) throw new HttpsError('invalid-argument', 'الرمز أرقام فقط، من ٣ إلى ٨، وما يبدأ بصفر');
  const price = pidPrice(pid);
  await db.runTransaction(async (tx) => {
    const [meSnap, idSnap] = await tx.getAll(userRef(uid), idRef(pid));
    const me = meSnap.data() as Profile | undefined;
    if (!me) throw new HttpsError('not-found', 'سجّل دخول أول');
    if (idSnap.exists) {
      throw new HttpsError('already-exists', idSnap.data()?.uid === uid ? 'هذا رمزك الآن' : 'هالرمز مأخوذ، اختر غيره');
    }
    if (me.diamonds < price) throw new HttpsError('failed-precondition', 'جواهرك ما تكفي');
    tx.set(idRef(pid), { uid, at: Date.now(), price });
    if (me.pid) tx.delete(idRef(me.pid));
    const next: Profile = { ...me, pid, pidTier: pidTier(pid), diamonds: me.diamonds - price };
    tx.set(userRef(uid), next);
    if (me.setupDone) tx.set(boardRef(uid), toLeaderboard(next));
  });
  return { pid, price };
});

/** لما ينحذف حساب: نشيله من أصدقائه وطلباتهم (ومعها آخر رسالة منه في قائمة محادثاتهم)، ونفك رمزه. */
export async function forgetUser(uid: string, p: Profile): Promise<void> {
  const others = [...new Set([...(p.friends ?? []), ...(p.sentReqs ?? []), ...Object.keys(p.friendReqs ?? {})])];
  const batch = db.batch();
  if (p.pid) batch.delete(idRef(p.pid));
  if (others.length) {
    const snaps = await db.getAll(...others.map(userRef));
    for (const s of snaps) {
      if (!s.exists) continue;
      batch.update(s.ref, {
        friends: FieldValue.arrayRemove(uid),
        sentReqs: FieldValue.arrayRemove(uid),
        [`friendReqs.${uid}`]: FieldValue.delete(),
        [`invitedAt.${uid}`]: FieldValue.delete(),
        [`dmUnread.${uid}`]: FieldValue.delete(),
        [`dmLast.${uid}`]: FieldValue.delete(),
      });
    }
  }
  await batch.commit();
}
