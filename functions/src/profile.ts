import { FieldValue, type Firestore, type Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { DAILY_REWARDS, STARTING_COINS, gulfDay, levelFor, previousDay } from './economy.js';

export const AVATARS = ['😎', '👩', '🧔', '👨‍🦱', '👴', '👱‍♀️', '🧑', '👩‍🦰', '👨', '🧕', '🥷', '🤠', '👳‍♂️', '🧙', '🕵️', '🦸'];

export interface Profile {
  name: string;
  avatar: string;
  /** صار عنده اسم وصورة من اختياره؟ لو لا، التطبيق يطلب منه يختار. */
  setupDone: boolean;
  coins: number;
  diamonds: number;
  xp: number;
  level: number;
  vip: boolean;
  gamesPlayed: number;
  gamesWon: number;
  lastDaily: string | null;
  dailyStreak: number;
  createdAt?: FieldValue;
}

export function newProfile(): Profile {
  return {
    name: 'ضيف',
    avatar: AVATARS[0],
    setupDone: false,
    coins: STARTING_COINS,
    diamonds: 0,
    xp: 0,
    level: 1,
    vip: false,
    gamesPlayed: 0,
    gamesWon: 0,
    lastDaily: null,
    dailyStreak: 0,
    createdAt: FieldValue.serverTimestamp(),
  };
}

/** يقرا ملف اللاعب داخل عملية، ويسويه لو ما كان موجود. */
export async function readProfile(db: Firestore, tx: Transaction, uid: string): Promise<Profile> {
  const snap = await tx.get(db.doc(`users/${uid}`));
  return snap.exists ? (snap.data() as Profile) : newProfile();
}

export function cleanName(raw: unknown): string {
  const name = typeof raw === 'string' ? raw.trim().replace(/\s+/g, ' ') : '';
  if (!/^[\p{L}\p{N}_ ]{2,16}$/u.test(name)) {
    throw new HttpsError('invalid-argument', 'الاسم لازم يكون من ٢ إلى ١٦ حرف، بدون رموز');
  }
  return name;
}

export function cleanAvatar(raw: unknown): string {
  if (typeof raw !== 'string' || !AVATARS.includes(raw)) throw new HttpsError('invalid-argument', 'صورة مو معروفة');
  return raw;
}

/** نتيجة الهدية اليومية: كم ذهب وجواهر، ورقم اليوم في السلسلة. */
export function dailyClaim(p: Profile, now: number): { coins: number; diamonds: number; streak: number; today: string } {
  const today = gulfDay(now);
  if (p.lastDaily === today) throw new HttpsError('failed-precondition', 'أخذت هدية اليوم، تعال بكرة 😉');
  const continued = p.lastDaily === previousDay(today);
  const streak = continued ? (p.dailyStreak % DAILY_REWARDS.length) + 1 : 1;
  return { ...DAILY_REWARDS[streak - 1], streak, today };
}

export { levelFor };
