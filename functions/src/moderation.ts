/**
 * فلتر الأسماء: نرفض الأسماء المسيئة أو اللي تنتحل صفة إدارة اللعبة.
 * الكلمات القصيرة لازم تكون كلمة كاملة (عشان "زبيدة" مثلاً ما ينرفض)، والطويلة تنرفض لو جت داخل الاسم.
 * المقارنة بعد التوحيد (nameKey): الهمزات والتاء المربوطة والتكرار وأرقام مكان الحروف.
 */
import { nameKey } from './profile.js';

const WHOLE = [
  // عربي
  'زب', 'كس', 'طيز', 'نيك', 'نيج', 'خول', 'عرص', 'زق', 'كلب', 'تفو', 'سكس', 'لوطي', 'ديوث', 'قحبه', 'حمار', 'منيك',
  'زاني', 'زانيه', 'شاذ',
  // English
  'sex', 'cum', 'fag', 'dick', 'cock', 'tits', 'porn', 'rape', 'nazi',
  // انتحال صفة الإدارة
  'admin', 'ادمن', 'مشرف', 'moderator', 'mod',
];

const INSIDE = [
  // عربي
  'منيوك', 'منيوج', 'متناك', 'شرموط', 'قحبه', 'عاهره', 'كسمك', 'كسختك', 'كساختك', 'يلعن',
  'ابنالكلب', 'خنزير', 'عرصه', 'ديوث', 'سكسي', 'نياك', 'مخنث',
  // English
  'fuck', 'shit', 'bitch', 'cunt', 'pussy', 'nigger', 'nigga', 'whore', 'slut', 'asshole', 'bastard', 'motherf',
  'porn', 'hitler', 'penis', 'vagina', 'dildo',
];

const LEET: Record<string, string> = { '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't', '@': 'a', '$': 's' };

function normalize(s: string): string {
  return nameKey(s)
    .replace(/[0134578@$]/g, (c) => (/[a-z]/i.test(s) ? (LEET[c] ?? c) : c))
    .replace(/(.)\1+/g, '$1');
}

const wholeKeys = new Set(WHOLE.map(normalize));
const insideKeys = INSIDE.map(normalize);

/** الاسم فيه كلمة مسيئة؟ */
export function offensiveName(name: string): boolean {
  const tokens = name.split(/[\s_]+/).filter(Boolean).map(normalize);
  if (tokens.some((t) => wholeKeys.has(t))) return true;
  const key = normalize(name);
  return insideKeys.some((w) => key.includes(w));
}
