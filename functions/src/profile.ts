import { FieldValue, type Firestore, type Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { DAILY_REWARDS, STARTING_COINS, gulfDay, levelFor, previousDay } from './economy.js';
import type { MissionState } from './missions.js';
import { DEFAULT_EQUIPPED, type Slot } from './shop.js';

/** الشخصيات المرسومة (app/assets/avatars). */
export const AVATARS = [
  'falcon', 'sheikh', 'cool', 'scholar', 'desert', 'hawk', 'merchant', 'youth',
  'pearl', 'rose', 'night', 'jasmine', 'amber', 'sky', 'masked', 'shadow',
];

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
  missions?: MissionState;
  /** الفوز في هذا الأسبوع، لجدول الترتيب الأسبوعي. */
  week?: string | null;
  weeklyWins?: number;
  /** أغراض المتجر اللي اشتراها، واللي لابسها الحين. */
  owned?: string[];
  equipped?: Record<Slot, string>;
  /** أجهزة اللاعب للإشعارات. */
  fcmTokens?: string[];
  /** انطرد من لعبة لأنه ما لعب: ممنوع يدخل ألعاب لين هالوقت (ملي ثانية). */
  bannedUntil?: number;
  /** مفتاح اسمه المحجوز في names/ (عشان محد ياخذ نفس الاسم). */
  nameKey?: string;
  /** ربط حسابه بقوقل وأخذ المكافأة. */
  linked?: boolean;
  createdAt?: FieldValue;
}

/** اللي يطلع للكل في جدول الترتيب (بدون الذهب وباقي الخصوصيات). */
export interface LeaderboardEntry {
  name: string;
  avatar: string;
  frame: string;
  level: number;
  /** للترتيب بين اللي بنفس المستوى. */
  xp: number;
  gamesWon: number;
  gamesPlayed: number;
  week: string | null;
  weeklyWins: number;
}

export function toLeaderboard(p: Profile): LeaderboardEntry {
  return {
    name: p.name,
    avatar: p.avatar,
    frame: equippedOf(p).frame,
    level: p.level,
    xp: p.xp,
    gamesWon: p.gamesWon,
    gamesPlayed: p.gamesPlayed,
    week: p.week ?? null,
    weeklyWins: p.weeklyWins ?? 0,
  };
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

export function equippedOf(p: Profile): Record<Slot, string> {
  return { ...DEFAULT_EQUIPPED, ...p.equipped };
}

/** يقرا ملف اللاعب داخل عملية، ويسويه لو ما كان موجود. */
export async function readProfile(db: Firestore, tx: Transaction, uid: string): Promise<Profile> {
  const snap = await tx.get(db.doc(`users/${uid}`));
  return snap.exists ? (snap.data() as Profile) : newProfile();
}

/**
 * مفتاح الاسم للمقارنة: نفس الاسم بأشكال مختلفة يعتبر واحد
 * (الهمزات، التاء المربوطة، الألف المقصورة، التشكيل، المسافات، الحروف الكبيرة).
 */
export function nameKey(name: string): string {
  return name
    .toLowerCase()
    .replace(/[\u064B-\u0652\u0640]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/\s+/g, '');
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
