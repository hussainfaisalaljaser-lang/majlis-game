/**
 * الدردشة: دردشة الديوان (لأعضائه) ودردشة بين صاحبين. الرسائل تنكتب من السيرفر بس، بعد ما نخفي الكلام
 * السيء والروابط (moderation.ts)، وبحد: رسالة كل ثانية، و٢٠٠ حرف بالكثير.
 * - clans/{id}/chat/{msg}: دردشة الديوان (الأعضاء يقرون).
 * - dms/{a_b}/msgs/{msg}: بين صاحبين (a وb مرتبين)، والاثنين بس يقرون.
 * - ملف اللاعب: dmUnread (كم رسالة ما قراها من كل صاحب)، وchatAt (آخر رسالة أرسلها).
 * الرسائل تنحذف بعد أسبوعين.
 */
import { FieldValue, type DocumentReference } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { db, requireAuth, userRef } from './base.js';
import type { Clan } from './clans.js';
import { maskBadWords } from './moderation.js';
import { avatarOf, readProfile, type Profile } from './profile.js';
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
  at: number;
  /** رتبته في الديوان (يطلع جنب اسمه). */
  role?: string;
  /** سطر من النظام (دخل، طلع…). */
  system?: boolean;
}

/** يرسل رسالة: to = 'clan' لديوانك، أو معرف صاحبك. */
export const sendChat = onCall(async (req) => {
  const uid = requireAuth(req);
  const to = String(req.data?.to ?? '');
  const raw = typeof req.data?.text === 'string' ? req.data.text : '';
  const clean = raw.replace(/\s+/g, ' ').trim();
  if (!clean) throw new HttpsError('invalid-argument', 'اكتب شي');
  if (clean.length > CHAT_MAX) throw new HttpsError('invalid-argument', `الرسالة بالكثير ${CHAT_MAX} حرف`);
  if (to !== 'clan' && (!to || to === uid || to.includes('/'))) throw new HttpsError('invalid-argument', 'لمين الرسالة؟');
  const text = maskBadWords(clean);
  const now = Date.now();
  const sent = await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    if (p.chatAt && now - p.chatAt < CHAT_GAP_MS) throw new HttpsError('resource-exhausted', 'شوي شوي على الرسائل');
    let ref: DocumentReference;
    let friend: Profile | null = null;
    if (to === 'clan') {
      if (!p.clan) throw new HttpsError('failed-precondition', 'أنت مو في ديوان');
      const snap = await tx.get(db.doc(`clans/${p.clan.id}`));
      const clan = snap.data() as Clan | undefined;
      const me = clan?.members[uid];
      if (!clan || !me) throw new HttpsError('failed-precondition', 'أنت مو في هالديوان');
      ref = db.collection(`clans/${clan.id}/chat`).doc();
      const msg: ChatMessage = { uid, name: p.name, avatar: avatarOf(p), role: me.role, text, at: now };
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
      const msg: ChatMessage = { uid, name: p.name, avatar: avatarOf(p), text, at: now };
      tx.set(ref, msg);
      tx.update(userRef(to), { [`dmUnread.${uid}`]: FieldValue.increment(1) });
    }
    tx.update(userRef(uid), { chatAt: now });
    return { path: ref.parent.path, name: p.name, dm: friend != null };
  });
  // تنظيف خفيف: أحياناً نحذف الرسائل اللي عدّى عليها أسبوعين.
  if (Math.random() < 0.05) await trimChat(sent.path, now).catch(() => {});
  if (sent.dm) {
    await sendNotes([{ uid: to, title: sent.name, body: text }], { kind: 'dm', from: uid }, `dm_${uid}`);
  }
  return { text };
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
