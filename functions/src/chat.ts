/**
 * الدردشة: دردشة الديوان (لأعضائه) ودردشة بين صاحبين. الرسائل تنكتب من السيرفر بس، بعد ما نخفي الكلام
 * السيء والروابط (moderation.ts)، وبحد: رسالة كل ثانية، و٢٠٠ حرف بالكثير.
 * - clans/{id}/chat/{msg}: دردشة الديوان (الأعضاء يقرون).
 * - dms/{a_b}/msgs/{msg}: بين صاحبين (a وb مرتبين)، والاثنين بس يقرون.
 * - ملف اللاعب: dmUnread (كم رسالة ما قراها من كل صاحب)، وdmLast (آخر رسالة مع كل صاحب، لقائمة المحادثات)،
 *   وchatAt (آخر رسالة أرسلها).
 * - الرسالة ممكن تكون ملصق من باقة يملكها (sticker)، بدال الكلام.
 * الرسائل تنحذف بعد أسبوعين.
 */
import { FieldValue, type DocumentReference } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { db, requireAuth, userRef } from './base.js';
import { REACTIONS } from './catalog.js';
import type { Clan } from './clans.js';
import { maskBadWords } from './moderation.js';
import { avatarOf, owns, readProfile, type ChatLast, type Profile } from './profile.js';
import { sendNotes } from './push.js';
import { onCall } from './security.js';

export const CHAT_MAX = 200;
export const CHAT_GAP_MS = 1000;
export const CHAT_KEEP_MS = 14 * 86400_000;

/** محادثة صاحبين: المعرفين مرتبين، عشان الاثنين يوصلون نفس المكان. */
export const dmPair = (a: string, b: string) => [a, b].sort().join('_');

export interface ChatMessage {
  uid: string;
  name: string;
  avatar: string;
  text: string;
  /** ملصق بدال الكلام. */
  sticker?: string;
  at: number;
  /** رتبته في الديوان (يطلع جنب اسمه). */
  role?: string;
  /** سطر من النظام (دخل، طلع…). */
  system?: boolean;
}

/** يرسل رسالة: to = 'clan' لديوانك، أو معرف صاحبك. الكلام (text) أو ملصق (sticker). */
export const sendChat = onCall(async (req) => {
  const uid = requireAuth(req);
  const to = String(req.data?.to ?? '');
  const sticker = typeof req.data?.sticker === 'string' ? req.data.sticker : null;
  const spec = sticker && Object.hasOwn(REACTIONS, sticker) ? REACTIONS[sticker] : null;
  if (sticker && !spec?.sticker) throw new HttpsError('invalid-argument', 'ملصق مو معروف');
  const raw = typeof req.data?.text === 'string' ? req.data.text : '';
  const clean = sticker ? '' : raw.replace(/\s+/g, ' ').trim();
  if (!sticker && !clean) throw new HttpsError('invalid-argument', 'اكتب شي');
  if (clean.length > CHAT_MAX) throw new HttpsError('invalid-argument', `الرسالة بالكثير ${CHAT_MAX} حرف`);
  if (to !== 'clan' && (!to || to === uid || to.includes('/') || to.includes('.'))) {
    throw new HttpsError('invalid-argument', 'لمين الرسالة؟');
  }
  const text = maskBadWords(clean);
  const now = Date.now();
  const extra = sticker ? { sticker } : {};
  const sent = await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    if (p.chatAt && now - p.chatAt < CHAT_GAP_MS) throw new HttpsError('resource-exhausted', 'شوي شوي على الرسائل');
    if (spec?.pack && !owns(p, spec.pack)) throw new HttpsError('permission-denied', 'هذا الملصق من باقة ما تملكها');
    let ref: DocumentReference;
    let friend: Profile | null = null;
    if (to === 'clan') {
      if (!p.clan) throw new HttpsError('failed-precondition', 'أنت مو في ديوان');
      const snap = await tx.get(db.doc(`clans/${p.clan.id}`));
      const clan = snap.data() as Clan | undefined;
      const me = clan?.members[uid];
      if (!clan || !me) throw new HttpsError('failed-precondition', 'أنت مو في هالديوان');
      ref = db.collection(`clans/${clan.id}/chat`).doc();
      const msg: ChatMessage = { uid, name: p.name, avatar: avatarOf(p), role: me.role, text, ...extra, at: now };
      tx.set(ref, msg);
      tx.update(snap.ref, { chatAt: now });
    } else {
      if (!(p.friends ?? []).includes(to)) throw new HttpsError('permission-denied', 'الدردشة مع أصحابك بس');
      const snap = await tx.get(userRef(to));
      if (!snap.exists) throw new HttpsError('not-found', 'اللاعب مو موجود');
      friend = snap.data() as Profile;
      if ((friend.blocked ?? []).includes(uid) || (p.blocked ?? []).includes(to)) {
        throw new HttpsError('permission-denied', 'ما تقدر تراسله');
      }
      ref = db.collection(`dms/${dmPair(uid, to)}/msgs`).doc();
      const msg: ChatMessage = { uid, name: p.name, avatar: avatarOf(p), text, ...extra, at: now };
      tx.set(ref, msg);
      const last: ChatLast = { text, ...extra, at: now, from: uid };
      tx.update(userRef(to), { [`dmUnread.${uid}`]: FieldValue.increment(1), [`dmLast.${uid}`]: last });
      tx.update(userRef(uid), { chatAt: now, [`dmLast.${to}`]: last });
    }
    if (to === 'clan') tx.update(userRef(uid), { chatAt: now });
    return { path: ref.parent.path, name: p.name, dm: friend != null };
  });
  // تنظيف خفيف: أحياناً نحذف الرسائل اللي عدّى عليها أسبوعين.
  if (Math.random() < 0.05) await trimChat(sent.path, now).catch(() => {});
  if (sent.dm) {
    await sendNotes([{ uid: to, title: sent.name, body: sticker ? 'أرسل لك ملصق' : text }], { kind: 'dm', from: uid }, `dm_${uid}`);
  }
  return { text, ...extra };
});

/** فتح محادثة صاحبه: الرسائل اللي ما قراها تنصفر. */
export const readDm = onCall(async (req) => {
  const uid = requireAuth(req);
  const friend = String(req.data?.uid ?? '');
  if (!friend || friend.includes('/') || friend.includes('.')) throw new HttpsError('invalid-argument', 'اختار صاحب');
  await userRef(uid).update({ [`dmUnread.${friend}`]: FieldValue.delete() });
  return {};
});

async function trimChat(path: string, now: number): Promise<void> {
  const old = await db.collection(path).where('at', '<', now - CHAT_KEEP_MS).limit(100).get();
  if (old.empty) return;
  const batch = db.batch();
  for (const d of old.docs) batch.delete(d.ref);
  await batch.commit();
}
