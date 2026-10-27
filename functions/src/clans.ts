/**
 * الدواوين: ديوان مع ربعك (بالكثير ٣٠)، فيه شيخ الديوان ونوابه. كل لعبة بطاولة عامة يلعبها عضو تزيد نقاط
 * ديوانه هالأسبوع، والترتيب الأسبوعي بين الدواوين من هالنقاط. ولو وصل الديوان هدف الأسبوع، كل عضو لعب
 * معهم يستلم صندوق.
 * - clans/{id}: الديوان وأعضاؤه (الكل يقرا، والسيرفر بس يكتب).
 * - clanNames/{key}: حجز اسم الديوان (ما يتكرر).
 * - ملف اللاعب فيه clan (المعرف والاسم واللون والشعار) عشان يطلع في بطاقته.
 */
import { FieldValue, type DocumentSnapshot, type Transaction } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { boardRef, db, requireAuth, userRef } from './base.js';
import { FREE_AVATARS } from './catalog.js';
import { gulfWeek } from './missions.js';
import { avatarOf, nameKey, readProfile, toLeaderboard, type Profile } from './profile.js';

/** سعر تأسيس ديوان (عشان ما تكثر الدواوين الفاضية). */
export const CLAN_PRICE = 5000;
export const CLAN_MAX = 30;
export const CLAN_DEPUTIES = 3;
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

export interface ClanMember {
  name: string;
  avatar: string;
  role: 'owner' | 'deputy' | 'member';
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
    };
    tx.set(ref, clan);
    tx.set(nameRef(key), { id: ref.id });
    setTag(tx, uid, { ...p, coins: p.coins - price }, tagOf(clan));
    return { id: ref.id };
  });
});

/** تدخل ديوان (لو فيه مكان). */
export const joinClan = onCall(async (req) => {
  const uid = requireAuth(req);
  const id = String(req.data?.id ?? '');
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const clan = await readClan(tx, id);
    if (p.clan) throw new HttpsError('failed-precondition', 'أنت في ديوان، اطلع منه أول');
    if (clan.count >= CLAN_MAX) throw new HttpsError('failed-precondition', 'الديوان مليان');
    tx.update(clanRef(id), { [`members.${uid}`]: member(p, 'member', Date.now()), count: clan.count + 1 });
    setTag(tx, uid, p, tagOf(clan));
  });
  return {};
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
    if (snap.exists) removeMember(tx, snap.data() as Clan, uid);
    setTag(tx, uid, p, null);
  });
  return {};
});

/** الشيخ (أو نائبه) يطلّع عضو. النائب ما يطلّع نائب ولا الشيخ. */
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
    const allowed = me.role === 'owner' || (me.role === 'deputy' && other.role === 'member');
    if (!allowed) throw new HttpsError('permission-denied', 'ما تقدر تطلّعه');
    removeMember(tx, clan, target);
    if (them?.clan?.id === clan.id) setTag(tx, target, them, null);
  });
  return {};
});

/** الشيخ يخلي عضو نائب (بالكثير ٣) أو يرجّعه عضو. */
export const clanRole = onCall(async (req) => {
  const uid = requireAuth(req);
  const target = String(req.data?.uid ?? '');
  const deputy = req.data?.deputy === true;
  await db.runTransaction(async (tx) => {
    const p = await readProfile(db, tx, uid);
    const clan = await readClan(tx, p.clan?.id);
    if (clan.ownerId !== uid) throw new HttpsError('permission-denied', 'بس شيخ الديوان');
    const other = clan.members[target];
    if (!other || target === uid) throw new HttpsError('invalid-argument', 'اختار عضو من الديوان');
    const deputies = Object.values(clan.members).filter((m) => m.role === 'deputy').length;
    if (deputy && other.role !== 'deputy' && deputies >= CLAN_DEPUTIES) {
      throw new HttpsError('failed-precondition', `بالكثير ${CLAN_DEPUTIES} نواب`);
    }
    tx.update(clanRef(clan.id), { [`members.${target}.role`]: deputy ? 'deputy' : 'member' });
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
