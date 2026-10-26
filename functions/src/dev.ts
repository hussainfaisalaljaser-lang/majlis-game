import type { CallableRequest } from 'firebase-functions/v2/https';

/**
 * صاحب اللعبة: مطوّر دايماً، وهو بس يقدر يخلي لاعبين ثانيين مطورين برموزهم (devGranted في ملفهم).
 * نتأكد من الإيميل من توكن قوقل نفسه، فلازم يكون الحساب مربوط بقوقل والإيميل متحقق منه.
 */
const OWNER_EMAILS = ['hussainfaisalaljaser@gmail.com'];

export function isOwner(req: CallableRequest): boolean {
  const token = req.auth?.token;
  return !!token?.email && token.email_verified === true && OWNER_EMAILS.includes(token.email.toLowerCase());
}

/** مطوّر (أدوات التجربة): صاحب اللعبة، أو لاعب خلاه صاحب اللعبة مطوّر برمزه. */
export function isDev(req: CallableRequest, profile: { devGranted?: boolean } | undefined): boolean {
  return isOwner(req) || profile?.devGranted === true;
}
