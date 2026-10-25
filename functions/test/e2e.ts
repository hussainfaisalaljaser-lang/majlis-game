/**
 * اختبار كامل على محاكي Firebase: لاعبين وهميين يسوون روم ويلعبون لين النهاية.
 * التشغيل: npx firebase emulators:exec --only auth,firestore,functions "npm run e2e"
 */
import assert from 'node:assert/strict';
import { deleteApp, initializeApp, type FirebaseApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signInAnonymously } from 'firebase/auth';
import { connectFirestoreEmulator, doc, getDoc, getFirestore } from 'firebase/firestore';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';
import type { PlayerView } from '../../engine/src/index.js';

const PROJECT = 'majlis-game-1d739';

interface Client {
  app: FirebaseApp;
  uid: string;
  call: <T = unknown>(name: string, data?: unknown) => Promise<T>;
  view: (code: string) => Promise<PlayerView>;
  readGame: (code: string) => Promise<unknown>;
}

async function client(i: number): Promise<Client> {
  const app = initializeApp({ projectId: PROJECT, apiKey: 'fake' }, `p${i}`);
  const auth = getAuth(app);
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  const fs = getFirestore(app);
  connectFirestoreEmulator(fs, '127.0.0.1', 8080);
  const fns = getFunctions(app, 'europe-west1');
  connectFunctionsEmulator(fns, '127.0.0.1', 5001);
  const { user } = await signInAnonymously(auth);
  return {
    app,
    uid: user.uid,
    call: async (name, data) => (await httpsCallable(fns, name)(data)).data as never,
    view: async (code) => (await getDoc(doc(fs, `games/${code}/views/${user.uid}`))).data() as PlayerView,
    readGame: async (code) => (await getDoc(doc(fs, `games/${code}`))).data(),
  };
}

async function expectError(p: Promise<unknown>, code: string): Promise<void> {
  await assert.rejects(p, (e: { code?: string }) => {
    assert.equal(e.code, `functions/${code}`);
    return true;
  });
}

/** يختار حركة مسموحة لهذا اللاعب من نسخته هو بس، مثل ما بيسوي التطبيق. */
function nextMove(v: PlayerView): Record<string, unknown> | null {
  const me = v.you;
  const alive = v.players.filter((p) => p.alive);
  const others = alive.filter((p) => p.id !== me);
  const isPres = v.presidentId === me;
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

async function main(): Promise<void> {
  const players = await Promise.all([0, 1, 2, 3, 4].map(client));
  const [host, ...rest] = players;

  // ١. روم خاص بكود
  const { code } = await host.call<{ code: string }>('createRoom', { name: 'المضيف', avatar: '😎', maxPlayers: 5 });
  assert.match(code, /^[A-Z0-9]{5}$/);
  await expectError(host.call('startGame', { code }), 'failed-precondition');
  await expectError(rest[0].call('joinRoom', { code: 'ZZZZZ' }), 'not-found');
  for (const [i, p] of rest.entries()) await p.call('joinRoom', { code, name: `لاعب ${i + 1}` });
  await expectError(rest[0].call('startGame', { code }), 'permission-denied');
  await host.call('startGame', { code });
  console.log(`✓ روم ${code}: ٥ لاعبين دخلوا وبدأت اللعبة`);

  // ٢. الأسرار محمية
  await assert.rejects(host.readGame(code), (e: { code?: string }) => e.code === 'permission-denied');
  const views = await Promise.all(players.map((p) => p.view(code)));
  for (const v of views) {
    const known = v.players.filter((p) => p.knownRole !== null).length;
    if (v.yourRole === 'loyal') assert.equal(known, 1, 'الوفي يعرف دوره بس');
  }
  console.log('✓ الحالة الكاملة مقفلة، وكل لاعب يشوف أسراره هو بس');

  // ٣. الردود السريعة
  await rest[0].call('react', { code, kind: 'suspect', target: rest[1].uid });
  await rest[1].call('react', { code, kind: 'laugh' });
  await expectError(rest[0].call('react', { code, kind: 'trust', target: rest[0].uid }), 'invalid-argument');
  await expectError(rest[2].call('react', { code, kind: 'hello' }), 'invalid-argument');
  const roomDoc = (await getDoc(doc(getFirestore(host.app), `rooms/${code}`))).data()!;
  assert.equal(roomDoc.reactions.length, 2);
  assert.equal(roomDoc.opinions[rest[0].uid][rest[1].uid], 'suspect');
  console.log('✓ الردود السريعة تنحفظ، ومؤشر الشك يتحدث، والردود الغلط ترفض');

  // ٤. حركة غلط ترفض
  const notPresident = players.find((p) => p.uid !== views[0].presidentId)!;
  await expectError(notPresident.call('act', { code, action: { type: 'nominate', chancellor: host.uid } }), 'failed-precondition');
  console.log('✓ السيرفر يرفض الحركات الغلط');

  // ٥. نكمل اللعب لين النهاية
  let moves = 0;
  for (;;) {
    const current = await Promise.all(players.map((p) => p.view(code)));
    if (current[0].phase === 'gameOver') {
      console.log(`✓ انتهت اللعبة بعد ${moves} حركة. الفايز: ${current[0].winner} (${current[0].winReason})`);
      break;
    }
    let moved = false;
    for (const [i, v] of current.entries()) {
      const move = nextMove(v);
      if (!move) continue;
      await players[i].call('act', { code, action: move });
      moves++;
      moved = true;
      if (v.phase !== 'election') break;
    }
    assert.ok(moved, `ما فيه أحد يقدر يتحرك في مرحلة ${current[0].phase}`);
    assert.ok(moves < 500, 'اللعبة طولت');
  }

  // ٦. المطابقة العشوائية: ٥ لاعبين يضغطون "العب الحين" وتبدأ تلقائياً
  const codes = new Set<string>();
  for (const p of players) codes.add((await p.call<{ code: string }>('quickMatch', { maxPlayers: 5, tierId: 'starter' })).code);
  assert.equal(codes.size, 1, 'كلهم لازم يدخلون نفس الروم');
  const [qm] = codes;
  const qv = await players[2].view(qm);
  assert.equal(qv.phase, 'nomination');
  console.log(`✓ المطابقة: ٥ لاعبين دخلوا روم ${qm} وبدأت تلقائياً`);

  await Promise.all(players.map((p) => deleteApp(p.app)));
  console.log('\nكل الاختبارات نجحت ✅');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
