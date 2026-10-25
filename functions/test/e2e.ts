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
  profile: () => Promise<Record<string, any>>;
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
    profile: async () => (await getDoc(doc(fs, `users/${user.uid}`))).data()!,
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
  if (!v.players.find((p) => p.id === me)!.alive) return null;
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

async function playToEnd(players: Client[], code: string): Promise<PlayerView> {
  let moves = 0;
  for (;;) {
    const current = await Promise.all(players.map((p) => p.view(code)));
    if (current[0].phase === 'gameOver') return current[0];
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
}

async function main(): Promise<void> {
  const players = await Promise.all([0, 1, 2, 3, 4].map(client));
  const [host, ...rest] = players;

  // ٠. الملف الشخصي والهدية اليومية
  for (const p of players) await p.call('ensureProfile');
  const fresh = await host.profile();
  assert.equal(fresh.coins, 2000);
  assert.equal(fresh.setupDone, false);
  await expectError(host.call('updateProfile', { name: 'x', avatar: '😎' }), 'invalid-argument');
  await expectError(host.call('updateProfile', { name: 'https://spam', avatar: '😎' }), 'invalid-argument');
  await expectError(host.call('updateProfile', { name: 'أبو فيصل', avatar: '💩' }), 'invalid-argument');
  await host.call('updateProfile', { name: 'أبو فيصل', avatar: '🥷' });
  const daily = await host.call<{ coins: number; streak: number }>('claimDaily');
  assert.deepEqual([daily.coins, daily.streak], [200, 1]);
  await expectError(host.call('claimDaily'), 'failed-precondition');
  const afterSetup = await host.profile();
  assert.deepEqual([afterSetup.name, afterSetup.avatar, afterSetup.setupDone, afterSetup.coins], ['أبو فيصل', '🥷', true, 2200]);
  for (const [i, p] of rest.entries()) await p.call('updateProfile', { name: `لاعب ${i + 1}`, avatar: '😎' });
  console.log('✓ الملف الشخصي: ٢٠٠٠ ذهب للبداية، والاسم يتحقق منه، والهدية اليومية مرة وحدة');

  // ١. روم خاص بكود
  const { code } = await host.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  assert.match(code, /^[A-Z0-9]{5}$/);
  await expectError(host.call('startGame', { code }), 'failed-precondition');
  await expectError(rest[0].call('joinRoom', { code: 'ZZZZZ' }), 'not-found');
  for (const p of rest) await p.call('joinRoom', { code });
  const roomPlayers = (await getDoc(doc(getFirestore(host.app), `rooms/${code}`))).data()!.players;
  assert.equal(roomPlayers[0].name, 'أبو فيصل', 'الاسم يجي من الملف الشخصي');
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
  const before = await Promise.all(players.map((p) => p.profile()));
  const end = await playToEnd(players, code);
  console.log(`✓ انتهت اللعبة. الفايز: ${end.winner} (${end.winReason})`);
  const results = (await getDoc(doc(getFirestore(host.app), `rooms/${code}`))).data()!.results;
  for (const [i, p] of players.entries()) {
    const after = await p.profile();
    const r = results[p.uid];
    assert.equal(r.coins, 0, 'الروم الخاص بدون جائزة ذهب');
    assert.equal(after.xp - (before[i].xp ?? 0), r.won ? 50 : 20);
    assert.equal(after.gamesPlayed, 1);
    assert.equal(after.gamesWon, r.won ? 1 : 0);
  }
  console.log('✓ نهاية الروم الخاص: خبرة للكل، والفايزين انحسب لهم فوز');

  // ٦. الطاولات: مقفلة بالمستوى، والرسوم تنخصم وترجع لو طلعت
  await expectError(host.call('quickMatch', { maxPlayers: 5, tierId: 'palace' }), 'permission-denied');
  await expectError(host.call('quickMatch', { maxPlayers: 5, tierId: 'vip' }), 'permission-denied');
  await expectError(host.call('quickMatch', { maxPlayers: 5, tierId: 'nope' }), 'invalid-argument');
  const coinsBefore = (await host.profile()).coins;
  const { code: lonely } = await host.call<{ code: string }>('quickMatch', { maxPlayers: 7, tierId: 'city' });
  assert.equal((await host.profile()).coins, coinsBefore - 1000);
  await host.call('leaveRoom', { code: lonely });
  assert.equal((await host.profile()).coins, coinsBefore);
  console.log('✓ الطاولات: المقفلة ترفض، والرسوم تنخصم وترجع لما تطلع');

  // ٧. المطابقة على طاولة المدينة: ٥ لاعبين يدفعون ١٠٠٠، والفريق الفايز يتقاسم ٥٠٠٠
  const startCoins = await Promise.all(players.map(async (p) => (await p.profile()).coins));
  const codes = new Set<string>();
  for (const p of players) codes.add((await p.call<{ code: string }>('quickMatch', { maxPlayers: 5, tierId: 'city' })).code);
  assert.equal(codes.size, 1, 'كلهم لازم يدخلون نفس الروم');
  const [qm] = codes;
  assert.equal((await players[2].view(qm)).phase, 'nomination');
  for (const [i, p] of players.entries()) assert.equal((await p.profile()).coins, startCoins[i] - 1000);
  console.log(`✓ المطابقة: ٥ لاعبين دخلوا روم ${qm} ودفعوا الرسوم وبدأت تلقائياً`);
  await playToEnd(players, qm);
  const qmResults = (await getDoc(doc(getFirestore(host.app), `rooms/${qm}`))).data()!.results;
  const winnerCount = Object.values(qmResults).filter((r: any) => r.won).length;
  for (const [i, p] of players.entries()) {
    const expected = qmResults[p.uid].won ? Math.floor(5000 / winnerCount) : 0;
    assert.equal(qmResults[p.uid].coins, expected);
    assert.equal((await p.profile()).coins, startCoins[i] - 1000 + expected);
  }
  console.log(`✓ الجائزة: ${winnerCount} فايزين، كل واحد أخذ ${Math.floor(5000 / winnerCount)} ذهب`);

  await Promise.all(players.map((p) => deleteApp(p.app)));
  console.log('\nكل الاختبارات نجحت ✅');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
