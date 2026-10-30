import { FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions/v2';
import { db, userRef } from './base.js';
import type { Note } from './notify.js';
import type { Profile } from './profile.js';
import { afterwards } from './ticks.js';

/**
 * يرسل إشعارات لأجهزة اللاعبين. أي خطأ هنا ما يأثر على اللي قبله (الحركة أو الطلب انحفظ).
 * [data] يوصل التطبيق (code للطاولة، وkind لطلبات الصداقة والدعوات)، و[tag] يخلي الإشعار الجديد
 * يحل محل القديم بدل ما تتكوم. الأجهزة اللي ما عادت موجودة تنشال من ملف اللاعب.
 */
export async function sendNotes(notes: Note[], data: Record<string, string>, tag?: string): Promise<void> {
  if (notes.length === 0) return;
  try {
    const uids = [...new Set(notes.map((n) => n.uid))];
    const snaps = await db.getAll(...uids.map(userRef));
    const tokens = new Map(snaps.map((s) => [s.id, ((s.data() as Profile | undefined)?.fcmTokens ?? []) as string[]]));
    const messages = notes.flatMap((n) =>
      (tokens.get(n.uid) ?? []).map((token) => ({
        token,
        notification: { title: n.title, body: n.body },
        data,
        android: { priority: 'high' as const, notification: { tag, icon: 'ic_stat_notify', color: '#F5B942' } },
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

/** إشعارات الطاولة (دورك، بدأت اللعبة…). تنرسل بعد ما تنحفظ الحركة، مع منبّه الدور بنفس الوقت (ticks.ts). */
export const sendPush = (code: string, notes: Note[]) => afterwards(() => sendNotes(notes, { code }, code));
