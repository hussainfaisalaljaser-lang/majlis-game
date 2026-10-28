import { logger } from 'firebase-functions/v2';
import {
  HttpsError,
  onCall as rawOnCall,
  type CallableFunction,
  type CallableOptions,
  type CallableRequest,
} from 'firebase-functions/v2/https';
import { db } from './base.js';
import { isOwner } from './dev.js';

/**
 * الحماية من الغش: كل طلب لازم يجي من تطبيقنا الأصلي (App Check: شهادة من قوقل بلاي إن التطبيق ما انعدّل
 * وإنه على جهاز حقيقي). «مراقبة» (الافتراضي): نسجّل اللي بدون شهادة بس. «مفعّلة»: نرفضه.
 * صاحب اللعبة يحوّلها من أدوات المطور (config/security)، ويفعّلها لما تنزل اللعبة على قوقل بلاي:
 * اللي ينزّل الملف من برا المتجر ما عنده الشهادة.
 */
export type AppCheckMode = 'monitor' | 'enforce';

/** كل نسخة من السيرفر تقرا الإعداد مرة كل دقيقة (في المحاكي كل طلب، عشان الاختبارات). */
const MODE_TTL_MS = process.env.FUNCTIONS_EMULATOR === 'true' ? 0 : 60_000;
let cached: { mode: AppCheckMode; at: number } | null = null;

export async function appCheckMode(): Promise<AppCheckMode> {
  if (cached && Date.now() - cached.at < MODE_TTL_MS) return cached.mode;
  const mode: AppCheckMode = (await db.doc('config/security').get()).get('appCheck') === 'enforce' ? 'enforce' : 'monitor';
  cached = { mode, at: Date.now() };
  return mode;
}

export async function setAppCheckMode(mode: AppCheckMode): Promise<void> {
  await db.doc('config/security').set({ appCheck: mode }, { merge: true });
  cached = { mode, at: Date.now() };
}

/** آخر مرة سجّلنا فيها إن هاللاعب يطلب بدون شهادة (مرة بالساعة لكل لاعب، عشان السجل ما يمتلي). */
const warned = new Map<string, number>();
const WARN_EVERY_MS = 60 * 60_000;

async function guard(req: CallableRequest): Promise<void> {
  // صاحب اللعبة دايم يدخل، عشان ما يقفل على نفسه لو فعّلها من نسخة من برا المتجر.
  if (req.app || isOwner(req)) return;
  if ((await appCheckMode()) === 'enforce') {
    throw new HttpsError('failed-precondition', 'حمّل اللعبة من قوقل بلاي عشان تكمل');
  }
  const uid = req.auth?.uid ?? '-';
  const last = warned.get(uid) ?? 0;
  if (Date.now() - last > WARN_EVERY_MS) {
    warned.set(uid, Date.now());
    logger.warn('طلب بدون شهادة التطبيق (الحماية على المراقبة)', { uid });
  }
}

type Handler<T, R> = (req: CallableRequest<T>) => R | Promise<R>;

/** مثل onCall، بس يفحص شهادة التطبيق قبل الطلب. كل طلبات اللعبة تمر من هنا. */
export function onCall<T = any, R = any>(handler: Handler<T, R>): CallableFunction<T, Promise<R>>;
export function onCall<T = any, R = any>(opts: CallableOptions, handler: Handler<T, R>): CallableFunction<T, Promise<R>>;
export function onCall<T, R>(a: CallableOptions | Handler<T, R>, b?: Handler<T, R>): CallableFunction<T, Promise<R>> {
  const opts: CallableOptions = typeof a === 'function' ? {} : a;
  const handler = (typeof a === 'function' ? a : b)!;
  return rawOnCall(opts, async (req: CallableRequest<T>) => {
    await guard(req);
    return handler(req);
  });
}

/** بدون فحص الشهادة: للي يجي من برا التطبيق (صفحة حذف الحساب في الموقع). */
export const openCall = rawOnCall;
