import type { CallableRequest } from 'firebase-functions/v2/https';

/**
 * حسابات المطور: لها أدوات تجربة (ذهب، مستوى، أدوار…). نتأكد من الإيميل من توكن قوقل نفسه،
 * فلازم يكون الحساب مربوط بقوقل والإيميل متحقق منه.
 */
const DEV_EMAILS = ['hussainfaisalaljaser@gmail.com'];

export function isDev(req: CallableRequest): boolean {
  const token = req.auth?.token;
  return !!token?.email && token.email_verified === true && DEV_EMAILS.includes(token.email.toLowerCase());
}
