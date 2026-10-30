/**
 * فحص السرعة على السيرفر الحقيقي (بعد كل رفع، من .github/workflows/speedcheck.yml): لاعب تجربة يبدأ تدريب
 * مع البوتات ويلعب كم حركة، ونقيس كل طلب: الوقت كامل، وشغل السيرفر (_ms)، وأجزاؤه (_t: العملية والمنبّه
 * والإشعارات). بعدها نمسح اللعبة. الوقت كامل يشمل الطريق من GitHub (أمريكا) للدوحة، فالمهم شغل السيرفر.
 */
import { readFileSync } from 'node:fs';
import { cert, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const PROJECT = 'majlis-game-1d739';
const REGION = 'me-central1';
/** مفتاح التطبيق العام (app/lib/firebase_options.dart)، نفس اللي في كل نسخة من اللعبة. */
const API_KEY = 'AIzaSyBvUqssl1P_-P6Zd7CaJmzLKYlZeYYVmwQ';
const UID = 'speedcheck-ci';
const PROTOCOL = 2;

// مفتاح حساب الرفع (من السر في GitHub): يوقّع توكن لاعب التجربة بنفسه بدون صلاحيات زيادة.
const keyFile = process.env.GOOGLE_APPLICATION_CREDENTIALS;
initializeApp({ projectId: PROJECT, ...(keyFile ? { credential: cert(JSON.parse(readFileSync(keyFile, 'utf8'))) } : {}) });
const db = getFirestore('gulf');
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

interface Row {
  fn: string;
  total: number;
  server?: number;
  t?: Record<string, number>;
}
const rows: Row[] = [];

async function idToken(): Promise<string> {
  const token = await getAuth().createCustomToken(UID);
  const res = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${API_KEY}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ token, returnSecureToken: true }),
  });
  const json = (await res.json()) as { idToken?: string };
  if (!json.idToken) throw new Error(`sign-in failed: ${JSON.stringify(json).slice(0, 300)}`);
  return json.idToken;
}

async function call<T = Record<string, unknown>>(token: string, fn: string, data: unknown = {}): Promise<T> {
  const started = performance.now();
  const res = await fetch(`https://${REGION}-${PROJECT}.cloudfunctions.net/api`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify({ data: { fn, data } }),
  });
  const total = Math.round(performance.now() - started);
  const json = (await res.json()) as { result?: Record<string, unknown>; error?: { message: string } };
  if (json.error) throw new Error(`${fn}: ${json.error.message}`);
  const out = json.result ?? {};
  rows.push({ fn, total, server: out._ms as number | undefined, t: out._t as Record<string, number> | undefined });
  return out as T;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function nextMove(v: any): Record<string, unknown> | null {
  const me = v.you;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const alive = v.players.filter((p: any) => p.alive);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const others = alive.filter((p: any) => p.id !== me);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const self = v.players.find((p: any) => p.id === me);
  if (!self?.alive) return null;
  if (v.claimable) return { type: 'claim', policies: v.claimable.truth ?? Array(v.claimable.count).fill('T') };
  const isPres = v.presidentId === me;
  switch (v.phase) {
    case 'nomination': {
      if (!isPres) return null;
      const blocked = new Set([me, v.lastElected?.chancellor, alive.length > 5 ? v.lastElected?.president : undefined]);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      return { type: 'nominate', chancellor: alive.find((p: any) => !blocked.has(p.id))?.id };
    }
    case 'election':
      return self.hasVoted ? null : { type: 'vote', ja: true };
    case 'presidentDiscard':
      return isPres ? { type: 'discard', index: 0 } : null;
    case 'chancellorEnact':
      return v.nomineeId === me ? { type: 'enact', index: 0 } : null;
    case 'vetoResponse':
      return isPres ? { type: 'respondVeto', accept: false } : null;
    case 'power': {
      if (!isPres) return null;
      if (v.pendingPower === 'peek') return { type: 'acknowledgePeek' };
      if (v.pendingPower === 'investigate') {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const done = new Set((v.yourInvestigations ?? []).map((i: any) => i.target));
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return { type: 'investigate', target: others.find((p: any) => !done.has(p.id))?.id };
      }
      return { type: v.pendingPower, target: others[0]?.id };
    }
    default:
      return null;
  }
}

/** دور في لعبة الفحص: [seen] متى شفناه (نقرا كل ٠٫٢ ث)، و[ended] متى شفنا اللي بعده. */
interface Turn {
  phase: string;
  round: number;
  seen: number;
  deadline: number | null;
  mine: boolean;
  ended?: number;
}
const turns: Turn[] = [];

/** توقيت اللعب: كم ياخذ كل نوع دور، وكم يتأخر منبّه السيرفر بعد آخر وقت أدوار البوتات. */
function timeline(): void {
  const done = turns.filter((t) => t.ended !== undefined);
  const late = done.filter((t) => !t.mine && t.deadline !== null).map((t) => t.ended! - t.deadline!);
  if (late.length) {
    const s = [...late].sort((a, b) => a - b);
    console.log(
      `::notice title=توقيت اللعب::منبّه السيرفر بعد آخر وقت دور البوت: الوسط ${median(late)}ms، ` +
        `٩٠٪ أقل من ${s[Math.floor(s.length * 0.9)] ?? s[s.length - 1]}ms، الأبطأ ${s[s.length - 1]}ms (${late.length} دور، والقراءة كل ٠٫٢ ث)`,
    );
  }
  const groups = new Map<string, Turn[]>();
  for (const t of done) {
    const k = `${t.phase}${t.mine ? ' (علي)' : ' (بوت)'}`;
    groups.set(k, [...(groups.get(k) ?? []), t]);
  }
  const lines = [...groups].map(([k, list]) => {
    const total = median(list.map((t) => t.ended! - t.seen));
    const wait = median(list.filter((t) => t.deadline !== null).map((t) => t.deadline! - t.seen));
    return `${k} ×${list.length}: يطول ${total}ms (وقته المكتوب ${wait}ms)`;
  });
  console.log(`::notice title=توقيت اللعب::${lines.join(' | ')}`);
}

const median = (xs: number[]) => {
  const s = [...xs].sort((a, b) => a - b);
  return s.length ? s[Math.floor(s.length / 2)] : 0;
};

function report(): void {
  const byFn = new Map<string, Row[]>();
  for (const r of rows) byFn.set(r.fn, [...(byFn.get(r.fn) ?? []), r]);
  for (const [fn, list] of byFn) {
    const part = (k: string) => median(list.map((r) => r.t?.[k] ?? 0));
    const line =
      `${fn} ×${list.length}: كامل ${median(list.map((r) => r.total))}ms، السيرفر ${median(list.map((r) => r.server ?? 0))}ms ` +
      `(العملية ${part('work')} · المنبّه ${part('tick')} · الإشعارات ${part('push')})، الأبطأ ${Math.max(...list.map((r) => r.server ?? 0))}ms` +
      `، المنبّه بالمكتبة ${list.filter((r) => r.t?.tickFallback).length} مرة`;
    console.log(`::notice title=فحص السرعة::${line}`);
  }
}

async function main(): Promise<void> {
  const token = await idToken();
  let code: string | undefined;
  try {
    for (let i = 0; i < 3; i++) await call(token, 'ensureProfile', { proto: PROTOCOL });
    code = (await call<{ code: string }>(token, 'startTraining', {})).code;
    const stop = Date.now() + 120_000;
    let moves = 0;
    let round = 0;
    let lastKey = '';
    let cur: Turn | undefined;
    while (Date.now() < stop && moves < 16) {
      const v = (await db.doc(`games/${code}/views/${UID}`).get()).data();
      round = Math.max(round, v?.round ?? 0);
      // كل دور جديد (المرحلة أو آخر وقتها تغيّر): متى شفناه، وآخر وقته، وهل الحركة علينا.
      const key = v ? `${v.round}|${v.phase}|${v.deadline}` : '';
      if (v && key !== lastKey) {
        const now = Date.now();
        if (cur) cur.ended = now;
        cur = { phase: v.phase, round: v.round, seen: now, deadline: v.deadline ?? null, mine: nextMove(v) !== null };
        turns.push(cur);
        lastKey = key;
      }
      if (!v || v.phase === 'gameOver') {
        if (v) break;
        await sleep(200);
        continue;
      }
      const move = nextMove(v);
      if (!move) {
        await sleep(200);
        continue;
      }
      try {
        await call(token, 'act', { code, action: move });
        moves++;
      } catch {
        // الحالة تغيّرت قبل ما توصل الحركة (البوتات أسرع): نقرا من جديد.
        await sleep(200);
      }
    }
    // أدوار البوتات يكملها منبّه السيرفر بس (الفحص ما يطلب timeout)، فلو الجولات تمشي المنبّه شغال.
    console.log(`::notice title=فحص السرعة::منبّه السيرفر: اللعبة وصلت الجولة ${round} بـ ${moves} حركة`);
    timeline();
    await call(token, 'leaveGame', { code }).catch(() => undefined);
  } finally {
    // نمسح لعبة الفحص قبل ما تخلص (ما تنحسب ولا تطلع في الترتيب).
    if (code) {
      await db.recursiveDelete(db.doc(`games/${code}`)).catch(() => undefined);
      await db.doc(`rooms/${code}`).delete().catch(() => undefined);
    }
    await db.doc(`users/${UID}`).update({ playing: null }).catch(() => undefined);
    report();
    // لو حط المنبّه المباشر فشل في السيرفر، السبب هنا (ticks.ts).
    const diag = (await db.doc('config/diag').get().catch(() => null))?.data();
    if (diag?.tickRest) {
      const ago = Math.round((Date.now() - diag.tickRest.at) / 60000);
      console.log(`::notice title=فحص السرعة::المنبّه المباشر فشل قبل ${ago} دقيقة: ${String(diag.tickRest.err).slice(0, 400)}`);
    }
  }
}

main().then(
  () => process.exit(0),
  (e) => {
    console.log(`::warning title=فحص السرعة::${String((e as Error)?.message ?? e).slice(0, 500)}`);
    report();
    process.exit(0);
  },
);
