/**
 * فلتر الأسماء: نرفض الأسماء المسيئة أو اللي تنتحل صفة إدارة اللعبة.
 * الكلمات القصيرة لازم تكون كلمة كاملة (عشان "زبيدة" مثلاً ما ينرفض)، والطويلة تنرفض لو جت داخل الاسم.
 * المقارنة بعد التوحيد (nameKey): الهمزات والتاء المربوطة والتكرار وأرقام مكان الحروف.
 */
import { nameKey } from './profile.js';

const RUDE = [
  // عربي
  'زب', 'كس', 'طيز', 'نيك', 'نيج', 'خول', 'عرص', 'زق', 'كلب', 'تفو', 'سكس', 'لوطي', 'ديوث', 'قحبه', 'حمار', 'منيك',
  'زاني', 'زانيه', 'شاذ',
  // English
  'sex', 'cum', 'fag', 'dick', 'cock', 'tits', 'porn', 'rape', 'nazi',
];
/** انتحال صفة الإدارة (ممنوع في الأسماء بس، مو في الدردشة). */
const STAFF = ['admin', 'ادمن', 'مشرف', 'moderator', 'mod'];
const WHOLE = [...RUDE, ...STAFF];

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

const rudeKeys = new Set(RUDE.map(normalize));

/** بادئات ولواحق عربية شايعة: «والكلب»، «يا حمار»، «كلبك» نفس الكلمة. */
const PREFIX = /^(?:و|ف)?(?:يا|بال|لل|ال|ب|ل|ك)?/;
const SUFFIX = /(?:هم|كم|ها|ين|ات|ه|ك|ي)$/;

function rudeWord(word: string): boolean {
  const k = normalize(word);
  if (!k) return false;
  const bare = k.replace(PREFIX, '');
  const forms = [k, bare, k.replace(SUFFIX, ''), bare.replace(SUFFIX, '')];
  return forms.some((f) => f.length > 1 && rudeKeys.has(f)) || insideKeys.some((w) => k.includes(w));
}

const LINK = /(?:https?:\/\/|www\.)\S+|\b[\w-]+\.(?:com|net|org|io|me|ly|gg|xyz|link|app|sa|ae)\b\S*/giu;

/**
 * الدردشة: يخفي الكلام السيء بنجوم (الكلمة كلها)، والروابط بنقاط. الأرقام تبقى (عشان رموز اللاعبين).
 */
export function maskBadWords(text: string): string {
  return text
    .replace(LINK, '•••')
    .replace(/[\p{L}\p{N}_@$]+/gu, (w) => (rudeWord(w) ? '*'.repeat(Math.min(Math.max(w.length, 3), 8)) : w));
}
