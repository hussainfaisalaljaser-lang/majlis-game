/**
 * أساسيات السيرفر اللي تحتاجها كل الملفات: تشغيل Firebase، والمنطقة، ومراجع الملفات، والتحقق من الدخول.
 * لازم ينقرا قبل أي تعريف دالة (onCall تاخذ المنطقة من setGlobalOptions وقت التعريف).
 */
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { HttpsError, type CallableRequest } from 'firebase-functions/v2/https';

initializeApp();
setGlobalOptions({ region: 'europe-west1', maxInstances: 10 });
export const db = getFirestore();

export const userRef = (uid: string) => db.doc(`users/${uid}`);
export const boardRef = (uid: string) => db.doc(`leaderboard/${uid}`);

export function requireAuth(req: CallableRequest): string {
  if (!req.auth) throw new HttpsError('unauthenticated', 'لازم تسجل دخول');
  return req.auth.uid;
}
