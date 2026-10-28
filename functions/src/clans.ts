/**
 * الدواوين: ديوان مع ربعك (بالكثير ٣٠)، فيه رتب: شيخ الديوان، ونوابه (٣)، والوجهاء (٨)، والأعضاء. كل لعبة
 * بطاولة عامة يلعبها عضو تزيد نقاط ديوانه هالأسبوع، والترتيب الأسبوعي بين الدواوين من هالنقاط. ولو وصل الديوان
 * هدف الأسبوع، كل عضو لعب معهم يستلم صندوق.
 * الشيخ ونوابه يكتبون وصف الديوان وشروطه: أقل مستوى، والدخول (مفتوح، بطلب، بالدعوة بس). الوجهاء وفوق يدعون
 * لاعبين ويقبلون الطلبات. والدعوة تدخّل صاحبها حتى لو ما تنطبق عليه الشروط.
 * - clans/{id}: الديوان وأعضاؤه وطلبات الدخول (الكل يقرا، والسيرفر بس يكتب).
 * - clans/{id}/chat: دردشة الديوان (chat.ts)، للأعضاء بس.
 * - clanNames/{key}: حجز اسم الديوان (ما يتكرر).
 * - ملف اللاعب فيه clan (المعرف والاسم واللون والشعار) عشان يطلع في بطاقته، وclanInvites (الدعوات اللي وصلته).
 */
import { FieldValue, type DocumentSnapshot, type Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { boardRef, db, requireAuth, userRef } from './base.js';
import { FREE_AVATARS } from './catalog.js';
import { levelFor } from './economy.js';
import { gulfWeek } from './missions.js';
import { maskBadWords } from './moderation.js';
import { avatarOf, nameKey, readProfile, toLeaderboard, type Profile } from './profile.js';
import { sendNotes } from './push.js';
import { onCall } from './security.js';

/** سعر تأسيس ديوان (عشان ما تكثر الدواوين الفاضية). */
export const CLAN_PRICE = 5000;
export const CLAN_MAX = 30;
export const CLAN_DEPUTIES = 3;
export const CLAN_ELDERS = 8;
/** أطول وصف، وأعلى شرط مستوى، وكم طلب وكم دعوة نخلي. */
export const CLAN_DESC_MAX = 120;
export const CLAN_LEVEL_MAX = 100;
export const CLAN_REQUESTS_MAX = 30;
export const CLAN_INVITES_MAX = 10;
/** الطلبات والدعوات تنتهي بعد أسبوع. */
export const CLAN_INVITE_TTL = 7 * 86400_000;
/** الدخول: أي أحد تنطبق عليه الشروط، أو بطلب يقبله الوجهاء وفوق، أو بالدعوة بس. */
export const CLAN_JOIN = ['open', 'request', 'invite'] as const;
export type ClanJoin = (typeof CLAN_JOIN)[number];
/** هدف الأسبوع، وصندوقه لكل عضو لعب معهم. */
export const CLAN_GOAL = 3000;
export const CLAN_CHEST = { coins: 1000, diamonds: 5 };
/** عدد ألوان الشعار (التطبيق عنده الألوان نفسها بالترتيب). */
export const CLAN_COLORS = 8;

/** نقاط الديوان من لعبة عضو (طاولة عامة): ١٠ للعب، و٢٠ زيادة للفوز. */
export const clanPoints = (won: boolean) => (won ? 30 : 10);

/** اللي يطلع في ملف اللاعب عن ديوانه. */
export interface ClanTag {
  id: string;
  name: string;
  color: number;
  emblem: string;
}

export type ClanRole = 'owner' | 'deputy' | 'elder' | 'member';

/** قوة كل رتبة: الأعلى يقدر على اللي تحته. */
export const RANK: Record<ClanRole, number> = { owner: 3, deputy: 2, elder: 1, member: 0 };

export interface ClanMember {
  name: string;
  avatar: string;
  role: ClanRole;
  joined: number;
  /** نقاطه هالأسبوع (week) للديوان. */
  week: string;
  points: number;
}

export interface Clan {
  id: string;
  name: string;
  nameKey: string;
  color: number;
  emblem: string;
  ownerId: string;
  members: Record<string, ClanMember>;
  count: number;
  /** كل النقاط من البداية (المستوى منها). */
  total: number;
  /** نقاط كل أسبوع (نخلي هالأسبوع واللي قبله بس). الترتيب الأسبوعي يرتّب على weekly.<الأسبوع>. */
  weekly: Record<string, number>;
  /** اللي استلموا صندوق كل أسبوع. */
  chest: Record<string, string[]>;
  createdAt: number;
  /** وصف الديوان (الكلام السيء ينخفى). */
  desc?: string;
  /** شروط الدخول: أقل مستوى (٠ أي أحد)، وطريقة الدخول. */
  minLevel?: number;
  join?: ClanJoin;
  /** طلبات الدخول (لو الدخول بطلب). */
  requests?: Record<string, ClanRequest>;
  /** وقت آخر رسالة في الدردشة (ملف الديوان عام، فالرسالة نفسها ما تنحفظ هنا). */
  chatAt?: number;
}

export interface ClanRequest {
  name: string;
  avatar: string;
  level: number;
  at: number;
}

/** دعوة وصلت لاعب (في ملفه clanInvites، المفتاح معرف الديوان). */
export interface ClanInvite {
  name: string;
  color: number;
  emblem: string;
  from: string;
  fromName: string;
  at: number;
}

const clanRef = (id: string) => db.doc(`clans/${id}`);
const nameRef = (key: string) => db.doc(`clanNames/${key}`);
const tagOf = (c: Clan): ClanTag => ({ id: c.id, name: c.name, color: c.color, emblem: c.emblem });

function cleanClanName(raw: unknown): string {
  const name = typeof raw === 'string' ? raw.trim().replace(/\s+/g, ' ') : '';
  if (!/^[\p{L}\p{N} ]{3,20}$/u.test(name)) {
    throw new HttpsError('invalid-argument', 'اسم الديوان من ٣ إلى ٢٠ حرف، بدون رموز');
  }
  return name;
}

function member(p: Profile, role: ClanMember['role'], now: number): ClanMember {
  return { name: p.name, avatar: avatarOf(p), role, joined: now, week: gulfWeek(now), points: 0 };
}

function cleanDesc(raw: unknown): string {
  const text = typeof raw === 'string' ? raw.replace(/\s+/g, ' ').trim() : '';
  if (text.length > CLAN_DESC_MAX) throw new HttpsError('invalid-argument', `الوصف بالكثير ${CLAN_DESC_MAX} حرف`);
  return maskBadWords(text);
}

function cleanJoin(raw: unknown): ClanJoin {
  const join = String(raw ?? 'open') as ClanJoin;
  if (!CLAN_JOIN.includes(join)) throw new HttpsError('invalid-argument', 'اختار طريقة الدخول');
  return join;
}

function cleanLevel(raw: unknown): number {
  const n = Math.round(Number(raw ?? 0));
  if (!(n >= 0 && n <= CLAN_LEVEL_MAX)) throw new HttpsError('invalid-argument', 'شرط المستوى من ٠ إلى ١٠٠');
  return n;
}

/** سطر من النظام في دردشة الديوان (دخل، طلع، صار نائب…). */
export function clanNotice(tx: Transaction, clanId: string, text: string, now: number): void {
  tx.set(db.collection(`clans/${clanId}/chat`).doc(), { uid: '', name: '', avatar: '', text, at: now, system: true });
  tx.update(clanRef(clanId), { chatAt: now });
}

/** يدخّل لاعب الديوان (بعد ما تأكدنا إنه يقدر): عضو جديد، ودعواته تنمسح، وطلبه ينشال. */
function addMember(tx: Transaction, clan: Clan, uid: string, p: Profile, now: number): void {
  tx.update(clanRef(clan.id), {
    [`members.${uid}`]: member(p, 'member', now),
    count: clan.count + 1,
    ...(clan.requests?.[uid] ? { [`requests.${uid}`]: FieldValue.delete() } : {}),
  });
  setTag(tx, uid, { ...p, clanInvites: {} }, tagOf(clan));
  clanNotice(tx, clan.id, `${p.name} دخل الديوان`, now);
}

const levelOf = (p: Profile) => levelFor(p.xp ?? 0);

async function readClan(tx: Transaction, id: string | undefined): Promise<Clan> {
  const snap = id ? await tx.get(clanRef(id)) : null;
  if (!snap?.exists) throw new HttpsError('not-found', 'الديوان مو موجود');
  return snap.data() as Clan;
}

/** يحفظ ديوان اللاعب في ملفه وسطره بالترتيب (عشان يطلع في بطاقته). */
function setTag(tx: Transaction, uid: string, p: Profile, tag: ClanTag | null): void {
  const next: Profile = { ...p, clan: tag };
  tx.set(userRef(uid), next);
  tx.set(boardRef(uid), toLeaderboard(next));
}

/** يسوي ديوان جديد (بسعر)، وأنت شيخه. */
export const createClan = onCall(async (req) => {
  const uid = requireAuth(req);
  const name = cleanClanName(req.data?.name);
  const color = Math.round(Number(req.data?.color));
  const emblem = String(req.data?.emblem ?? '');
  if (!(color >= 0 && color < CLAN_COLORS)) throw new HttpsError('invalid-argument', 'اختار لون');
  if (!FREE_AVATARS.includes(emblem)) throw new HttpsError('invalid-argument', 'اختار شعار');
  const desc = cleanDesc(req.data?.desc);
  const minLevel = cleanLevel(req.data?.minLevel);
  const join = cleanJoin(req.data?.join);
  const key = nameKey(name);
  const ref = db.collection('clans').doc();
  return db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const taken = await tx.get(nameRef(key));
    if (p.clan) throw new HttpsError('failed-precondition', 'أنت في ديوان، اطلع منه أول');
    if (taken.exists) throw new HttpsError('already-exists', 'فيه ديوان بهالاسم، اختر اسم ثاني');
    const price = p.dev ? 0 : CLAN_PRICE;
    if (p.coins < price) throw new HttpsError('failed-precondition', 'ما عندك ذهب كافي');
    const now = Date.now();
    const clan: Clan = {
      id: ref.id,
      name,
      nameKey: key,
      color,
      emblem,
      ownerId: uid,
      members: { [uid]: member(p, 'owner', now) },
      count: 1,
      total: 0,
      weekly: { [gulfWeek(now)]: 0 },
      chest: {},
      createdAt: now,
      desc,
      minLevel,
      join,
      requests: {},
    };
    tx.set(ref, clan);
    tx.set(nameRef(key), { id: ref.id });
    setTag(tx, uid, { ...p, coins: p.coins - price, clanInvites: {} }, tagOf(clan));
    return { id: ref.id };
  });
});

/**
 * تدخل ديوان: لو عندك دعوة منه تدخل على طول. وإلا لازم تنطبق عليك الشروط (المستوى)، ولو الدخول بطلب
 * ينرسل طلبك للوجهاء ({requested: true})، ولو بالدعوة بس ما تقدر.
 */
export const joinClan = onCall(async (req) => {
  const uid = requireAuth(req);
  const id = String(req.data?.id ?? '');
  return db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const clan = await readClan(tx, id);
    const now = Date.now();
    if (p.clan) throw new HttpsError('failed-precondition', 'أنت في ديوان، اطلع منه أول');
    if (clan.count >= CLAN_MAX) throw new HttpsError('failed-precondition', 'الديوان مليان');
    const invited = (p.clanInvites?.[id]?.at ?? 0) > now - CLAN_INVITE_TTL;
    if (!invited) {
      const level = levelOf(p);
      if (level < (clan.minLevel ?? 0)) {
        throw new HttpsError('failed-precondition', `هالديوان للي مستواهم ${clan.minLevel} وفوق`);
      }
      if (clan.join === 'invite') throw new HttpsError('permission-denied', 'هالديوان بالدعوة بس');
      if (clan.join === 'request') {
        const pending = Object.entries(clan.requests ?? {}).filter(([, r]) => r.at > now - CLAN_INVITE_TTL);
        if (!clan.requests?.[uid] && pending.length >= CLAN_REQUESTS_MAX) {
          throw new HttpsError('resource-exhausted', 'طلبات الديوان كثيرة، جرب بعدين');
        }
        tx.update(clanRef(id), { [`requests.${uid}`]: { name: p.name, avatar: avatarOf(p), level, at: now } });
        return { requested: true };
      }
    }
    addMember(tx, clan, uid, p, now);
    return { joined: true };
  });
});

/** الوجهاء وفوق: يقبلون أو يرفضون طلب دخول. */
export const clanRespond = onCall(async (req) => {
  const uid = requireAuth(req);
  const target = String(req.data?.uid ?? '');
  const accept = req.data?.accept === true;
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const clan = await readClan(tx, p.clan?.id);
    const them = (await tx.get(userRef(target))).data() as Profile | undefined;
    const me = clan.members[uid];
    if (!me || RANK[me.role] < RANK.elder) throw new HttpsError('permission-denied', 'بس الوجهاء وفوق');
    if (!clan.requests?.[target]) throw new HttpsError('not-found', 'الطلب مو موجود');
    if (!accept || !them || them.clan) {
      tx.update(clanRef(clan.id), { [`requests.${target}`]: FieldValue.delete() });
      if (accept) throw new HttpsError('failed-precondition', 'دخل ديوان ثاني');
      return;
    }
    if (clan.count >= CLAN_MAX) throw new HttpsError('failed-precondition', 'الديوان مليان');
    addMember(tx, clan, target, them, Date.now());
  });
  return {};
});

/** الوجهاء وفوق: يدعون لاعب للديوان (الدعوة توصله في ملفه وبإشعار). */
export const clanInvite = onCall(async (req) => {
  const uid = requireAuth(req);
  const target = String(req.data?.uid ?? '');
  if (!target || target === uid || target.includes('/')) throw new HttpsError('invalid-argument', 'اختار لاعب');
  const res = await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const clan = await readClan(tx, p.clan?.id);
    const snap = await tx.get(userRef(target));
    const me = clan.members[uid];
    if (!me || RANK[me.role] < RANK.elder) throw new HttpsError('permission-denied', 'بس الوجهاء وفوق يدعون');
    if (!snap.exists) throw new HttpsError('not-found', 'اللاعب مو موجود');
    const them = snap.data() as Profile;
    if (them.clan) throw new HttpsError('failed-precondition', 'هو في ديوان');
    if ((them.blocked ?? []).includes(uid)) throw new HttpsError('permission-denied', 'ما تقدر تدعيه');
    if (clan.count >= CLAN_MAX) throw new HttpsError('failed-precondition', 'الديوان مليان');
    const now = Date.now();
    const kept = Object.entries(them.clanInvites ?? {})
      .filter(([cid, inv]) => cid !== clan.id && inv.at > now - CLAN_INVITE_TTL)
      .sort((a, b) => b[1].at - a[1].at)
      .slice(0, CLAN_INVITES_MAX - 1);
    const invite: ClanInvite = { name: clan.name, color: clan.color, emblem: clan.emblem, from: uid, fromName: p.name, at: now };
    tx.update(userRef(target), { clanInvites: { ...Object.fromEntries(kept), [clan.id]: invite } });
    return { clan: clan.name, from: p.name };
  });
  await sendNotes(
    [{ uid: target, title: 'دعوة للديوان', body: `${res.from} يدعوك لديوان ${res.clan}` }],
    { kind: 'clanInvite' },
    'clanInvite',
  );
  return {};
});

/** اللي وصلته دعوة: يقبلها (يدخل حتى لو ما تنطبق عليه الشروط) أو يرفضها. */
export const clanInviteRespond = onCall(async (req) => {
  const uid = requireAuth(req);
  const id = String(req.data?.id ?? '');
  const accept = req.data?.accept === true;
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const invite = p.clanInvites?.[id];
    if (!invite) throw new HttpsError('not-found', 'الدعوة مو موجودة');
    const snap = accept ? await tx.get(clanRef(id)) : null;
    const now = Date.now();
    if (!accept) {
      tx.update(userRef(uid), { [`clanInvites.${id}`]: FieldValue.delete() });
      return;
    }
    if (!snap?.exists || invite.at <= now - CLAN_INVITE_TTL) {
      tx.update(userRef(uid), { [`clanInvites.${id}`]: FieldValue.delete() });
      throw new HttpsError('not-found', 'الدعوة انتهت');
    }
    const clan = snap.data() as Clan;
    if (p.clan) throw new HttpsError('failed-precondition', 'أنت في ديوان، اطلع منه أول');
    if (clan.count >= CLAN_MAX) throw new HttpsError('failed-precondition', 'الديوان مليان');
    addMember(tx, clan, uid, p, now);
  });
  return {};
});

/** الشيخ ونوابه: وصف الديوان وشروط الدخول. */
export const clanSettings = onCall(async (req) => {
  const uid = requireAuth(req);
  const desc = cleanDesc(req.data?.desc);
  const minLevel = cleanLevel(req.data?.minLevel);
  const join = cleanJoin(req.data?.join);
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const clan = await readClan(tx, p.clan?.id);
    const me = clan.members[uid];
    if (!me || RANK[me.role] < RANK.deputy) throw new HttpsError('permission-denied', 'بس الشيخ ونوابه');
    tx.update(clanRef(clan.id), { desc, minLevel, join });
  });
  return { desc };
});

/** يطلع عضو من الديوان. لو كان الشيخ، تنتقل المشيخة لنائب (أو أقدم عضو)، ولو ما بقى أحد ينحذف الديوان. */
function removeMember(tx: Transaction, clan: Clan, uid: string): void {
  const rest = Object.entries(clan.members).filter(([id]) => id !== uid);
  if (rest.length === 0) {
    tx.delete(clanRef(clan.id));
    tx.delete(nameRef(clan.nameKey));
    return;
  }
  const update: Record<string, unknown> = { [`members.${uid}`]: FieldValue.delete(), count: rest.length };
  if (clan.ownerId === uid) {
    const [heir] = [...rest].sort(
      (a, b) => Number(b[1].role === 'deputy') - Number(a[1].role === 'deputy') || a[1].joined - b[1].joined,
    );
    update.ownerId = heir[0];
    update[`members.${heir[0]}.role`] = 'owner';
  }
  tx.update(clanRef(clan.id), update);
}

export const leaveClan = onCall(async (req) => {
  const uid = requireAuth(req);
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    if (!p.clan) throw new HttpsError('failed-precondition', 'أنت مو في ديوان');
    const snap = await tx.get(clanRef(p.clan.id));
    if (snap.exists) {
      const clan = snap.data() as Clan;
      removeMember(tx, clan, uid);
      if (clan.count > 1) clanNotice(tx, clan.id, `${p.name} طلع من الديوان`, Date.now());
    }
    setTag(tx, uid, p, null);
  });
  return {};
});

/** الشيخ ونوابه يطلّعون اللي تحتهم بالرتبة (النائب ما يطلّع نائب ولا الشيخ). */
export const clanKick = onCall(async (req) => {
  const uid = requireAuth(req);
  const target = String(req.data?.uid ?? '');
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const clan = await readClan(tx, p.clan?.id);
    const them = (await tx.get(userRef(target))).data() as Profile | undefined;
    const me = clan.members[uid];
    const other = clan.members[target];
    if (!me || !other || target === uid) throw new HttpsError('invalid-argument', 'اختار عضو من الديوان');
    const allowed = RANK[me.role] >= RANK.deputy && RANK[me.role] > RANK[other.role];
    if (!allowed) throw new HttpsError('permission-denied', 'ما تقدر تطلّعه');
    removeMember(tx, clan, target);
    if (them?.clan?.id === clan.id) setTag(tx, target, them, null);
    clanNotice(tx, clan.id, `${other.name} انطلع من الديوان`, Date.now());
  });
  return {};
});

const ROLE_NAMES: Record<ClanRole, string> = { owner: 'شيخ الديوان', deputy: 'نائب', elder: 'وجيه', member: 'عضو' };

/**
 * يغيّر رتبة عضو: الشيخ يخليه نائب (بالكثير ٣) أو وجيه (بالكثير ٨) أو عضو، أو يسلّمه المشيخة (ويصير هو نائب).
 * النائب يخلي العضو وجيه أو يرجّع الوجيه عضو. النسخ القديمة ترسل deputy بس.
 */
export const clanRole = onCall(async (req) => {
  const uid = requireAuth(req);
  const target = String(req.data?.uid ?? '');
  const role: ClanRole =
    typeof req.data?.role === 'string' ? (req.data.role as ClanRole) : req.data?.deputy === true ? 'deputy' : 'member';
  if (!Object.hasOwn(RANK, role)) throw new HttpsError('invalid-argument', 'اختار رتبة');
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const clan = await readClan(tx, p.clan?.id);
    const me = clan.members[uid];
    const other = clan.members[target];
    if (!me || !other || target === uid) throw new HttpsError('invalid-argument', 'اختار عضو من الديوان');
    // النائب: بس بين العضو والوجيه، وعلى اللي تحته.
    const allowed =
      me.role === 'owner' || (me.role === 'deputy' && RANK[other.role] < RANK.deputy && RANK[role] < RANK.deputy);
    if (!allowed) throw new HttpsError('permission-denied', 'ما تقدر تغيّر رتبته');
    const count = (r: ClanRole) => Object.entries(clan.members).filter(([id, m]) => m.role === r && id !== target).length;
    if (role === 'deputy' && count('deputy') >= CLAN_DEPUTIES) {
      throw new HttpsError('failed-precondition', `بالكثير ${CLAN_DEPUTIES} نواب`);
    }
    if (role === 'elder' && count('elder') >= CLAN_ELDERS) {
      throw new HttpsError('failed-precondition', `بالكثير ${CLAN_ELDERS} وجهاء`);
    }
    const now = Date.now();
    if (role === 'owner') {
      tx.update(clanRef(clan.id), { ownerId: target, [`members.${target}.role`]: 'owner', [`members.${uid}.role`]: 'deputy' });
      clanNotice(tx, clan.id, `${other.name} صار شيخ الديوان`, now);
      return;
    }
    tx.update(clanRef(clan.id), { [`members.${target}.role`]: role });
    clanNotice(tx, clan.id, `${other.name} صار ${ROLE_NAMES[role]}`, now);
  });
  return {};
});

/** صندوق هدف الأسبوع: لكل عضو لعب مع ديوانه هالأسبوع، مرة وحدة. */
export const claimClanChest = onCall(async (req) => {
  const uid = requireAuth(req);
  return db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const clan = await readClan(tx, p.clan?.id);
    const week = gulfWeek(Date.now());
    const m = clan.members[uid];
    if ((clan.weekly[week] ?? 0) < CLAN_GOAL) throw new HttpsError('failed-precondition', 'الديوان ما وصل هدف الأسبوع للحين');
    if (!m || m.week !== week || m.points <= 0) throw new HttpsError('failed-precondition', 'العب مع ديوانك هالأسبوع أول');
    const claimed = clan.chest[week] ?? [];
    if (claimed.includes(uid)) throw new HttpsError('already-exists', 'استلمت صندوق هالأسبوع');
    tx.update(clanRef(clan.id), { [`chest.${week}`]: [...claimed, uid] });
    tx.set(userRef(uid), { ...p, coins: p.coins + CLAN_CHEST.coins, diamonds: p.diamonds + CLAN_CHEST.diamonds });
    return CLAN_CHEST;
  });
});

/** يقرا دواوين لاعبين اللعبة (قبل أي كتابة في العملية). */
export async function readClans(tx: Transaction, ids: string[]): Promise<Map<string, Clan>> {
  const unique = [...new Set(ids)];
  const snaps: DocumentSnapshot[] = unique.length ? await tx.getAll(...unique.map(clanRef)) : [];
  return new Map(snaps.filter((s) => s.exists).map((s) => [s.id, s.data() as Clan]));
}

/**
 * نقاط لعبة خلصت لدواوين اللاعبين: [gains] لكل لاعب ديوانه ونقاطه. يحدّث نقاط الأسبوع والكل ونقاط كل عضو
 * (واسمه وصورته)، ويشيل أسابيع قديمة.
 */
export function addClanPoints(
  tx: Transaction,
  clans: Map<string, Clan>,
  gains: { uid: string; clan: string; points: number; p: Profile }[],
  now: number,
): void {
  const week = gulfWeek(now);
  const byClan = new Map<string, typeof gains>();
  for (const g of gains) byClan.set(g.clan, [...(byClan.get(g.clan) ?? []), g]);
  for (const [id, list] of byClan) {
    const clan = clans.get(id);
    if (!clan) continue;
    const sum = list.reduce((n, g) => n + g.points, 0);
    const update: Record<string, unknown> = {
      [`weekly.${week}`]: (clan.weekly[week] ?? 0) + sum,
      total: clan.total + sum,
    };
    for (const old of Object.keys(clan.weekly)) {
      if (old !== week && old !== gulfWeek(now - 7 * 86400_000)) update[`weekly.${old}`] = FieldValue.delete();
    }
    for (const old of Object.keys(clan.chest ?? {})) if (old !== week) update[`chest.${old}`] = FieldValue.delete();
    for (const g of list) {
      const m = clan.members[g.uid];
      if (!m) continue;
      update[`members.${g.uid}`] = {
        ...m,
        name: g.p.name,
        avatar: avatarOf(g.p),
        week,
        points: (m.week === week ? m.points : 0) + g.points,
      };
    }
    tx.update(clanRef(id), update);
  }
}
