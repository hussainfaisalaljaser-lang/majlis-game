import { FieldValue, type Firestore, type Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { DAILY_REWARDS, STARTING_COINS, gulfDay, levelFor, previousDay } from './economy.js';
import type { MissionState } from './missions.js';
import { CATALOG, FREE_AVATARS } from './catalog.js';
import type { Stats } from './achievements.js';
import type { RankState } from './rank.js';
import type { PassMissionState } from './missions.js';
import type { PassState } from './rewards.js';
import { DEFAULT_EQUIPPED, avatarOfItem, isDefault, type EquipSlot } from './shop.js';
import { rankOf } from './rank.js';
import type { ClanInvite, ClanTag } from './clans.js';
import type { TourState } from './tournament.js';

/** الشخصيات المجانية (app/assets/avatars). */
export const AVATARS = FREE_AVATARS;

/** هدية وصلت اللاعب (مستوى، بطولة الأسبوع، الشرح، إنجاز). التطبيق يعرضها ويشيلها بـ ackGifts. */
export interface Gift {
  kind: 'level' | 'champion' | 'tutorial' | 'achievement' | 'rank' | 'tour' | 'passGift';
  /** المستوى (للمستويات) أو المركز (للأبطال) أو الدرجة (للإنجازات). */
  n: number;
  /** معرف الإنجاز (للإنجازات). */
  ach?: string;
  /** اسم اللي أهداه (هدية الباتل باس من صاحب). n: ١ لو الباتل باس كامل. */
  from?: string;
  coins: number;
  diamonds: number;
  items: string[];
}

/** آخر رسالة في محادثة صاحبين (قائمة المحادثات). */
export interface ChatLast {
  text: string;
  sticker?: string;
  at: number;
  /** معرف اللي أرسلها. */
  from: string;
}

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
  equipped?: Partial<Record<EquipSlot, string>>;
  /** أغراض مؤقتة (أبطال الأسبوع): المعرف ← لين متى (ملي ثانية). */
  temp?: Record<string, number>;
  /** اللي كان لابسه قبل أغراض البطولة، يرجع له لما تخلص. */
  restore?: { frame?: string; avatar?: string };
  /** هدايا ما شافها للحين. */
  gifts?: Gift[];
  /** آخر مستوى أخذ هداياه (عشان ما تنعطى مرتين). */
  rewardedLevel?: number;
  /** الباتل باس (rewards.ts → PassState). */
  pass?: PassState;
  /** مهام الباتل باس الأسبوعية ومهام الموسم (missions.ts). */
  passMissions?: PassMissionState;
  /** خلّص لعبة الشرح وأخذ مكافأتها. */
  tutorialDone?: boolean;
  /** تخطّى الشرح (يعرف يلعب، أو حساب جديد على جوال جديد): ما نجبره عليه بعدها. */
  tutorialSkipped?: boolean;
  /** إحصائيات الإنجازات (achievements.ts)، ودرجة كل إنجاز وصلها (١ برونزي، ٢ فضي، ٣ ذهبي). */
  stats?: Stats;
  badges?: Record<string, number>;
  /** تصنيفه في الطاولات العامة (rank.ts). */
  rank?: RankState;
  /** لاعبين حظرهم: ما يشوف ردودهم ولا رأيهم، وما تجمعه المطابقة معهم. */
  blocked?: string[];
  /** حد البلاغات والرسائل في اليوم. */
  reportDay?: string;
  reportCount?: number;
  feedbackDay?: string;
  feedbackCount?: number;
  /** اللي بلّغوا عن اسمه الحالي. لو وصلوا ٣ ينغيّر اسمه تلقائياً. */
  nameReporters?: string[];
  /** اسمه انغيّر لأنه انبلغ عنه: التطبيق يطلب منه يختار اسم جديد. */
  renamed?: boolean;
  /** أجهزة اللاعب للإشعارات. */
  fcmTokens?: string[];
  /** انطرد من لعبة لأنه ما لعب: ممنوع يدخل ألعاب لين هالوقت (ملي ثانية). */
  bannedUntil?: number;
  /** حساب مطور: صاحب اللعبة أو اللي خلاه مطوّر (dev.ts). التطبيق يطلع له أدوات التجربة. */
  dev?: boolean;
  /** صاحب اللعبة (من إيميل قوقل): يقدر يخلي غيره مطوّر برمزه. */
  owner?: boolean;
  /** صاحب اللعبة خلاه مطوّر برمزه. */
  devGranted?: boolean;
  /** مفتاح اسمه المحجوز في names/ (عشان محد ياخذ نفس الاسم). */
  nameKey?: string;
  /** ربط حسابه بقوقل وأخذ المكافأة. */
  linked?: boolean;
  /** رمزه اللي يبحثون فيه عنه (محجوز في ids/)، ودرجته: ٠ عادي … ٤ أسطوري (ids.ts). */
  pid?: string;
  pidTier?: number;
  /** أصدقاؤه، وطلبات الصداقة اللي وصلته (مين ← متى)، واللي أرسلها وما انردت. */
  friends?: string[];
  friendReqs?: Record<string, number>;
  sentReqs?: string[];
  /** آخر مرة دعا كل صديق لرومه (عشان ما يزعجه). */
  invitedAt?: Record<string, number>;
  /**
   * نسخة بروتوكول التطبيق اللي فتحه آخر مرة (ensureProfile). النسخ القديمة ما ترسله (يعني ١).
   * ٢: تعرف الأدوار الجديدة (قاضي، شيخ، جاسوس) وإعادة اللعب والتفرج.
   */
  proto?: number;
  /** بطولة الأسبوع: أي أسبوع سجّل فيه، ووين وصل، وطلع أو لا. */
  tour?: TourState;
  /** ديوانه (المعرف والاسم واللون والشعار)، أو null. */
  clan?: ClanTag | null;
  /** دعوات الدواوين اللي وصلته (معرف الديوان ← الدعوة). */
  clanInvites?: Record<string, ClanInvite>;
  /** آخر رسالة أرسلها (عشان ما يكرر بسرعة)، والرسائل اللي ما قراها من كل صاحب. */
  chatAt?: number;
  dmUnread?: Record<string, number>;
  /** آخر رسالة في محادثته مع كل صاحب (قائمة المحادثات): الكلام أو الملصق، ومتى، ومن أرسلها. */
  dmLast?: Record<string, ChatLast>;
  /** يلعب الحين: في أي روم ومن متى (أصحابه يقدرون يتفرجون). يتصفر لما تخلص اللعبة أو يطلع. */
  playing?: { code: string; at: number } | null;
  /** ملصقاته المفضلة (بالكثير ٥): تطلع له جنب زر التفاعل في اللعب بضغطة وحدة. */
  favorites?: string[];
  /** آخر دعوة وصلته من صديق: التطبيق يعرضها لو كانت جديدة والروم للحين ينتظر. */
  invite?: { from: string; name: string; code: string; at: number };
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
  /** درجات الإنجازات اللي يعرضها ملفه للناس. */
  badges: Record<string, number>;
  /** نقاط التصنيف وموسمها (جدول التصنيف يقرا الموسم الحالي بس). */
  rankSeason: string;
  rankPoints: number;
  /** رمزه ودرجته (للبحث والبطاقة). */
  pid: string;
  pidTier: number;
  /** يلعب الحين من متى (بدون كود الروم، الكود بس لأصحابه من spectate). */
  playingSince: number | null;
  /** ديوانه (يطلع في بطاقته). */
  clan: ClanTag | null;
}

export function toLeaderboard(p: Profile): LeaderboardEntry {
  return {
    name: p.name,
    avatar: avatarOf(p),
    frame: equippedOf(p).frame,
    level: p.level,
    xp: p.xp,
    gamesWon: p.gamesWon,
    gamesPlayed: p.gamesPlayed,
    week: p.week ?? null,
    weeklyWins: p.weeklyWins ?? 0,
    badges: p.badges ?? {},
    rankSeason: rankOf(p).season,
    rankPoints: rankOf(p).points,
    pid: p.pid ?? '',
    pidTier: p.pidTier ?? 0,
    playingSince: p.playing?.at ?? null,
    clan: p.clan ?? null,
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

/** يملك الغرض؟ (الأساسي، أو اشتراه أو أخذه هدية، أو مؤقت وما خلص وقته). */
export function owns(p: Profile, id: string, now = Date.now()): boolean {
  return isDefault(id) || (p.owned ?? []).includes(id) || (p.temp?.[id] ?? 0) > now;
}

/** اللي لابسه الحين. لو كان لابس غرض بطولة خلص وقته، يرجع للي كان لابسه قبل. */
export function equippedOf(p: Profile, now = Date.now()): Record<EquipSlot, string> {
  const out = { ...DEFAULT_EQUIPPED, ...p.equipped };
  for (const slot of Object.keys(out) as EquipSlot[]) {
    if (owns(p, out[slot], now)) continue;
    const back = slot === 'frame' ? p.restore?.frame : undefined;
    out[slot] = back && owns(p, back, now) ? back : DEFAULT_EQUIPPED[slot];
  }
  return out;
}

/** صورته الحين، بنفس الفكرة (شخصية البطولة ترجع للي قبلها لما يخلص الأسبوع). */
export function avatarOf(p: Profile, now = Date.now()): string {
  if (AVATARS.includes(p.avatar) || owns(p, `avatar_${p.avatar}`, now)) return p.avatar;
  const back = p.restore?.avatar;
  return back && (AVATARS.includes(back) || owns(p, `avatar_${back}`, now)) ? back : AVATARS[0];
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

/** الشخصيات المميزة (من المتجر أو هدايا المستويات أو للأبطال). */
export const PREMIUM_AVATARS = CATALOG.filter((i) => i.slot === 'avatar').map((i) => avatarOfItem(i.id));

export function cleanAvatar(raw: unknown, p?: Profile): string {
  if (typeof raw !== 'string') throw new HttpsError('invalid-argument', 'صورة مو معروفة');
  if (AVATARS.includes(raw)) return raw;
  if (!PREMIUM_AVATARS.includes(raw)) throw new HttpsError('invalid-argument', 'صورة مو معروفة');
  if (!p || !owns(p, `avatar_${raw}`)) throw new HttpsError('permission-denied', 'هذي الشخصية ما تملكها للحين');
  return raw;
}

/** نتيجة الهدية اليومية: كم ذهب وجواهر، ورقم اليوم في السلسلة. */
export function dailyClaim(p: Profile, now: number): { coins: number; diamonds: number; streak: number; today: string } {
  const today = gulfDay(now);
  if (p.lastDaily === today) throw new HttpsError('failed-precondition', 'أخذت هدية اليوم، تعال بكرة');
  const continued = p.lastDaily === previousDay(today);
  const streak = continued ? (p.dailyStreak % DAILY_REWARDS.length) + 1 : 1;
  return { ...DAILY_REWARDS[streak - 1], streak, today };
}

export { levelFor };
