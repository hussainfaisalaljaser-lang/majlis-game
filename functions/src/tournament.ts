/**
 * بطولة الأسبوع: مفتوحة وقت نهاية الأسبوع (من الخميس ٦ المغرب لين نهاية السبت بتوقيت الخليج).
 * تسجّل برسوم مرة بالأسبوع، وتلعب طاولات البطولة: لو فاز فريقك تتأهل للدور اللي بعده
 * (الدور الأول ← نص النهائي ← النهائي)، ولو خسر تطلع. اللي يفوز النهائي بطل الأسبوع وياخذ الجائزة.
 * - tours/{الأسبوع}: المشاركين ووين وصل كل واحد (الكل يقرا).
 * - ملف اللاعب فيه tour (الأسبوع والدور، وطلع أو لا).
 * - طاولة البطولة روم عام فيه tour (الدور) وtourWeek، يتكمل بالبوتات مثل الطاولات العامة.
 */
import { type Transaction } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { db, requireAuth, userRef } from './base.js';
import { weekendBoost } from './economy.js';
import { gulfWeek } from './missions.js';
import { avatarOf, equippedOf, readProfile, type Profile } from './profile.js';

export const TOUR_FEE = 1000;
export const TOUR_PRIZE = { coins: 15000, diamonds: 25 };
/** كم فوز ورا بعض للبطولة: الدور الأول، نص النهائي، النهائي. */
export const TOUR_STAGES = 3;
/** عدد لاعبين طاولة البطولة. */
export const TOUR_TABLE = 7;

/** البطولة مفتوحة الحين؟ (نفس وقت نهاية الأسبوع). اختبارات السيرفر تفتحها دايم بـ MAJLIS_TOUR_OPEN=1. */
export const tourOpen = (now: number) => process.env.MAJLIS_TOUR_OPEN === '1' || weekendBoost(now) > 1;

/** وين وصل اللاعب في بطولة أسبوع. */
export interface TourState {
  week: string;
  /** كم دور فاز فيه (٠ الدور الأول … ٣ بطل). */
  stage: number;
  out: boolean;
}

export interface TourEntry {
  name: string;
  avatar: string;
  frame: string;
  stage: number;
  out: boolean;
  at: number;
}

export interface Tour {
  week: string;
  players: Record<string, TourEntry>;
  champions: string[];
}

export const tourRef = (week: string) => db.doc(`tours/${week}`);

/** يسجّل في بطولة هالأسبوع (برسوم، مرة وحدة). */
export const tourJoin = onCall(async (req) => {
  const uid = requireAuth(req);
  const now = Date.now();
  if (!tourOpen(now)) throw new HttpsError('failed-precondition', 'البطولة تفتح الخميس ٦ المغرب');
  const week = gulfWeek(now);
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const tour = (await tx.get(tourRef(week))).data() as Tour | undefined;
    if (p.tour?.week === week) throw new HttpsError('already-exists', 'سجّلت في بطولة هالأسبوع');
    const fee = p.dev ? 0 : TOUR_FEE;
    if (p.coins < fee) throw new HttpsError('failed-precondition', 'ما عندك ذهب كافي');
    const entry: TourEntry = { name: p.name, avatar: avatarOf(p), frame: equippedOf(p).frame, stage: 0, out: false, at: now };
    tx.set(userRef(uid), { ...p, coins: p.coins - fee, tour: { week, stage: 0, out: false } });
    tx.set(tourRef(week), { week, players: { ...(tour?.players ?? {}), [uid]: entry }, champions: tour?.champions ?? [] });
  });
  return {};
});

/** اللاعب يقدر يلعب جولة بطولة الحين؟ يرجّع دوره، أو يرمي سبب. */
export function tourStageOf(p: Profile, now: number): number {
  if (!tourOpen(now)) throw new HttpsError('failed-precondition', 'البطولة مقفلة الحين');
  const t = p.tour;
  if (!t || t.week !== gulfWeek(now)) throw new HttpsError('failed-precondition', 'سجّل في البطولة أول');
  if (t.out) throw new HttpsError('failed-precondition', 'طلعت من بطولة هالأسبوع');
  if (t.stage >= TOUR_STAGES) throw new HttpsError('failed-precondition', 'أنت بطل الأسبوع!');
  return t.stage;
}

/**
 * نتيجة طاولة بطولة لكل لاعب فيها (داخل finishTurn، بعد القراءات): الفايز يتأهل، والخسران يطلع،
 * واللي فاز النهائي بطل وياخذ الجائزة. يرجّع الملف الجديد ووش صار له.
 */
export function applyTour(
  p: Profile,
  stage: number,
  week: string,
  won: boolean,
): { profile: Profile; result: { stage: number; out: boolean; champion: boolean } | null } {
  const t = p.tour;
  if (!t || t.week !== week || t.out || t.stage !== stage) return { profile: p, result: null };
  const next: TourState = won ? { week, stage: stage + 1, out: false } : { week, stage, out: true };
  const champion = next.stage >= TOUR_STAGES;
  let profile: Profile = { ...p, tour: next };
  if (champion) {
    const gift = { kind: 'tour' as const, n: 1, coins: TOUR_PRIZE.coins, diamonds: TOUR_PRIZE.diamonds, items: [] };
    profile = {
      ...profile,
      coins: profile.coins + TOUR_PRIZE.coins,
      diamonds: profile.diamonds + TOUR_PRIZE.diamonds,
      gifts: [...(profile.gifts ?? []), gift].slice(-10),
    };
  }
  return { profile, result: { stage: next.stage, out: next.out, champion } };
}

/** يحدّث لوحة البطولة (tours/{week}) بعد طاولة خلصت. */
export function writeTour(
  tx: Transaction,
  week: string,
  tour: Tour | undefined,
  changes: { uid: string; p: Profile; stage: number; out: boolean; champion: boolean }[],
): void {
  if (!changes.length) return;
  const players = { ...(tour?.players ?? {}) };
  const champions = [...(tour?.champions ?? [])];
  for (const c of changes) {
    const old = players[c.uid];
    players[c.uid] = {
      name: c.p.name,
      avatar: avatarOf(c.p),
      frame: equippedOf(c.p).frame,
      at: old?.at ?? Date.now(),
      stage: c.stage,
      out: c.out,
    };
    if (c.champion && !champions.includes(c.uid)) champions.push(c.uid);
  }
  tx.set(tourRef(week), { week, players, champions });
}
