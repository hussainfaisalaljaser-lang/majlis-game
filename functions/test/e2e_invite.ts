/**
 * هدية الدعوة والرجوع للعبة على محاكي Firebase: مين ينحسب مدعو (رابط الدعوة، أو الروم الخاص)، والهدية بعد أول
 * لعبة حقيقية للثنين، والحد الأعلى، و«يلعب الحين» اللي يرجّع اللاعب لطاولته لو انقفل التطبيق.
 * التشغيل: MAJLIS_FAST_PACING=1 npx firebase emulators:exec --only auth,firestore,functions "npx tsx test/e2e_invite.ts"
 */
import assert from 'node:assert/strict';
import { initializeApp, type FirebaseApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signInAnonymously } from 'firebase/auth';
import { connectFirestoreEmulator, doc, getDoc, getFirestore } from 'firebase/firestore';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';
import { initializeApp as adminApp } from 'firebase-admin/app';
import { getFirestore as adminFirestore } from 'firebase-admin/firestore';
import type { PlayerView } from '../../engine/src/index.js';
import { INVITE_MAX, INVITE_NEW_REWARD, INVITE_REWARD } from '../src/economy.js';

const PROJECT = 'majlis-game-1d739';
const DB = 'gulf';
const admin = adminFirestore(adminApp({ projectId: PROJECT }, 'admin'), DB);
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

interface Client {
  app: FirebaseApp;
  uid: string;
  name: string;
  call: <T = unknown>(name: string, data?: unknown) => Promise<T>;
  view: (code: string) => Promise<PlayerView>;
  profile: () => Promise<Record<string, any>>;
}

async function client(i: number, name: string): Promise<Client> {
  const app = initializeApp({ projectId: PROJECT, apiKey: 'fake' }, `i${i}`);
  const auth = getAuth(app);
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  const fs = getFirestore(app, DB);
  connectFirestoreEmulator(fs, '127.0.0.1', 8080);
  const fns = getFunctions(app, 'me-central1');
  connectFunctionsEmulator(fns, '127.0.0.1', 5001);
  const { user } = await signInAnonymously(auth);
  const c: Client = {
    app,
    uid: user.uid,
    name,
    call: async (fn, data) => (await httpsCallable(fns, fn)(data)).data as never,
    view: async (code) => (await getDoc(doc(fs, `games/${code}/views/${user.uid}`))).data() as PlayerView,
    profile: async () => (await getDoc(doc(fs, `users/${user.uid}`))).data()!,
  };
  await c.call('ensureProfile', { proto: 2 });
  await c.call('updateProfile', { name, avatar: 'falcon' });
  return c;
}

/** حركة اللاعب من نسخته (مثل التطبيق). */
function nextMove(v: PlayerView): Record<string, unknown> | null {
  const me = v.you;
  const alive = v.players.filter((p) => p.alive);
  const others = alive.filter((p) => p.id !== me);
  const isPres = v.presidentId === me;
  if (!v.players.find((p) => p.id === me)!.alive) return null;
  if (v.claimable) return { type: 'claim', policies: v.claimable.truth ?? Array(v.claimable.count).fill('T') };
  switch (v.phase) {
    case 'nomination': {
      if (!isPres) return null;
      const blocked = new Set([me, v.lastElected?.chancellor, alive.length > 5 ? v.lastElected?.president : undefined]);
      return { type: 'nominate', chancellor: alive.find((p) => !blocked.has(p.id))!.id };
    }
    case 'election':
      return v.players.find((p) => p.id === me)!.hasVoted ? null : { type: 'vote', ja: true };
    case 'presidentDiscard':
      return isPres ? { type: 'discard', index: 0 } : null;
    case 'chancellorEnact':
      return v.nomineeId === me ? { type: 'enact', index: 0 } : null;
    case 'vetoResponse':
      return isPres ? { type: 'respondVeto', accept: false } : null;
    case 'power':
      if (!isPres) return null;
      if (v.pendingPower === 'peek') return { type: 'acknowledgePeek' };
      if (v.pendingPower === 'investigate') {
        const done = new Set(v.yourInvestigations.map((i) => i.target));
        return { type: 'investigate', target: others.find((p) => !done.has(p.id))!.id };
      }
      return { type: v.pendingPower, target: others[0].id };
    default:
      return null;
  }
}

/** كل البشر يلعبون أدوارهم (ما أحد ينطرد لأنه ما لعب)، والبوتات بطلب timeout، لين تخلص اللعبة. */
async function playOut(cs: Client[], code: string): Promise<void> {
  for (let i = 0; i < 1200; i++) {
    let moved = false;
    for (const c of cs) {
      const v = await c.view(code);
      if (v.phase === 'gameOver') return;
      const move = nextMove(v);
      if (!move) continue;
      try {
        await c.call('act', { code, action: move });
        moved = true;
      } catch {
        // الحالة تغيّرت قبل حركته: نكمل.
      }
    }
    if (!moved) {
      await sleep(200);
      await cs[0].call('timeout', { code });
    }
  }
  throw new Error('اللعبة ما خلصت');
}

/** روم خاص لصاحبه [host] فيه [guests] (بالرابط لو [by])، يكمّل بالبوتات ويبدأ. */
async function privateGame(host: Client, guests: Client[], by?: string): Promise<string> {
  const { code } = await host.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  for (const g of guests) await g.call('joinRoom', { code, ...(by ? { by } : {}) });
  for (let i = 1 + guests.length; i < 5; i++) await host.call('addBots', { code });
  await host.call('startGame', { code });
  return code;
}

const invites = (p: Record<string, any>) => (p.gifts ?? []).filter((g: { kind: string }) => g.kind === 'invite');

async function main(): Promise<void> {
  const ahmad = await client(1, 'أحمد');
  const ahmadPid = (await ahmad.profile()).pid as string;
  assert.ok(ahmadPid, 'له رمز لاعب');

  // ١. صاحب جديد دخل من رابط دعوة أحمد: ينحفظ إن أحمد دعاه
  const salem = await client(2, 'سالم');
  const { code: r1 } = await ahmad.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  await salem.call('joinRoom', { code: r1, by: ahmadPid });
  assert.deepEqual((await salem.profile()).invitedBy, { uid: ahmad.uid, name: 'أحمد' });
  console.log('✓ دخل من رابط الدعوة: انحفظ مين دعاه');

  // ٢. يلعبون: «يلعب الحين» ينحفظ (منه يرجع لطاولته لو انقفل التطبيق)، وينمسح لما تخلص
  for (let i = 0; i < 3; i++) await ahmad.call('addBots', { code: r1 });
  await ahmad.call('startGame', { code: r1 });
  assert.equal((await salem.profile()).playing?.code, r1);
  assert.equal((await ahmad.profile()).playing?.code, r1);
  const before = { salem: await salem.profile(), ahmad: await ahmad.profile() };
  await playOut([ahmad, salem], r1);
  const after = { salem: await salem.profile(), ahmad: await ahmad.profile() };
  assert.equal(after.salem.playing, null, 'خلصت: ما عاد يلعب');
  assert.equal(after.ahmad.playing, null);
  console.log('✓ «يلعب الحين» ينحفظ وقت اللعب وينمسح لما تخلص');

  // ٣. بعد أول لعبة: الثنين أخذوا هدية الدعوة، وكل واحد يشوف اسم الثاني
  assert.equal(after.salem.inviteDone, true);
  assert.deepEqual(invites(after.salem), [{ kind: 'invite', n: 0, from: 'أحمد', ...INVITE_NEW_REWARD, items: [] }]);
  assert.deepEqual(invites(after.ahmad), [{ kind: 'invite', n: 1, from: 'سالم', ...INVITE_REWARD, items: [] }]);
  assert.equal(after.ahmad.invites, 1);
  // الجواهر من الدعوة بس (الطاولة الخاصة ما فيها جوائز، وهدايا المستوى ذهب بأول المستويات).
  assert.equal(after.ahmad.diamonds - before.ahmad.diamonds, INVITE_REWARD.diamonds);
  console.log('✓ بعد أول لعبة: الصاحب الجديد واللي دعاه أخذوا الهدية');

  // ٤. ما تتكرر: لعبة ثانية لسالم ما فيها هدية
  await privateGame(ahmad, [salem]).then((code) => playOut([ahmad, salem], code));
  assert.equal(invites(await salem.profile()).length, 1);
  assert.equal((await ahmad.profile()).invites, 1);
  console.log('✓ الهدية مرة وحدة بس');

  // ٥. بدون رابط: الجديد اللي دخل روم صاحبه الخاص بالرمز، صاحب الروم هو اللي دعاه
  const khalid = await client(3, 'خالد');
  const { code: r2 } = await ahmad.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  await khalid.call('joinRoom', { code: r2 });
  assert.deepEqual((await khalid.profile()).invitedBy, { uid: ahmad.uid, name: 'أحمد' });
  console.log('✓ دخل الروم الخاص بالرمز: صاحب الروم دعاه');

  // ٦. اللي لعب لعبة حقيقية قبل ما ينحسب مدعو، والرابط بدون رمز صحيح ما يكسر الدخول
  const fahad = await client(4, 'فهد');
  await privateGame(fahad, []).then((code) => playOut([fahad], code));
  const { code: r3 } = await ahmad.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  await fahad.call('joinRoom', { code: r3, by: ahmadPid });
  assert.equal((await fahad.profile()).invitedBy ?? null, null);
  const nasser = await client(5, 'ناصر');
  await nasser.call('joinRoom', { code: r3, by: 'abc' });
  assert.deepEqual((await nasser.profile()).invitedBy, { uid: ahmad.uid, name: 'أحمد' }, 'رمز غلط: صاحب الروم');
  console.log('✓ اللي لعب قبل ما ينحسب، والرمز الغلط ما يكسر شي');

  // ٧. اللي دعا مو في الطاولة: تجيه هديته برضه (رابط أحمد، والروم لغيره)
  const majed = await client(6, 'منصور');
  const badr = await client(7, 'راشد');
  const r4 = await privateGame(badr, [majed], ahmadPid);
  assert.deepEqual((await majed.profile()).invitedBy, { uid: ahmad.uid, name: 'أحمد' }, 'الرابط يغلب صاحب الروم');
  await playOut([badr, majed], r4);
  assert.equal((await ahmad.profile()).invites, 2);
  assert.deepEqual(invites(await ahmad.profile()).at(-1), { kind: 'invite', n: 1, from: 'منصور', ...INVITE_REWARD, items: [] });
  assert.equal(invites(await badr.profile()).length, 0, 'صاحب الروم ما ياخذ شي (مو هو اللي دعا)');
  console.log('✓ اللي دعا ياخذ هديته حتى لو مو في الطاولة');

  // ٨. الحد الأعلى: بعده الصاحب الجديد ياخذ هديته، واللي دعا ما ياخذ شي
  await admin.doc(`users/${ahmad.uid}`).update({ invites: INVITE_MAX });
  const giftsBefore = invites(await ahmad.profile()).length;
  for (let i = 0; i < 3; i++) await ahmad.call('addBots', { code: r2 });
  await ahmad.call('startGame', { code: r2 });
  await playOut([ahmad, khalid], r2);
  assert.equal(invites(await khalid.profile()).length, 1, 'خالد أخذ هديته');
  assert.equal((await ahmad.profile()).invites, INVITE_MAX);
  assert.equal(invites(await ahmad.profile()).length, giftsBefore, 'أحمد وصل الحد');
  console.log('✓ الحد الأعلى للي يدعو');

  // ٩. لعبة الشرح ما تنحسب أول لعبة
  const tutor = await client(8, 'مشعل');
  const { code: r5 } = await ahmad.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  await tutor.call('joinRoom', { code: r5 });
  await tutor.call('leaveRoom', { code: r5 }).catch(() => undefined);
  const { code: tut } = await tutor.call<{ code: string }>('startTutorial');
  await playOut([tutor], tut);
  const t = await tutor.profile();
  assert.equal(t.inviteDone ?? false, false, 'الشرح ما يعطي هدية الدعوة');
  assert.deepEqual(t.invitedBy, { uid: ahmad.uid, name: 'أحمد' }, 'وتظل تنتظر أول لعبة حقيقية');
  console.log('✓ لعبة الشرح ما تنحسب');

  console.log('كل اختبارات هدية الدعوة نجحت');
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
