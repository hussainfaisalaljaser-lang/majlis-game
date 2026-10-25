/**
 * اختبار كامل على محاكي Firebase: لاعبين وهميين يسوون روم ويلعبون لين النهاية.
 * التشغيل: MAJLIS_FAST_PACING=1 npx firebase emulators:exec --only auth,firestore,functions "npm run e2e"
 * (الإيقاع السريع يشيل انتظار المشاهد والترحيب، عشان ما يطول الاختبار)
 */
import assert from 'node:assert/strict';
import { deleteApp, initializeApp, type FirebaseApp } from 'firebase/app';
import { GoogleAuthProvider, connectAuthEmulator, getAuth, linkWithCredential, signInAnonymously } from 'firebase/auth';
import {
  collection,
  connectFirestoreEmulator,
  doc,
  getDoc,
  getDocs,
  getFirestore,
  limit,
  orderBy,
  query,
  where,
} from 'firebase/firestore';
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
  await expectError(host.call('updateProfile', { name: 'x', avatar: 'falcon' }), 'invalid-argument');
  await expectError(host.call('updateProfile', { name: 'https://spam', avatar: 'falcon' }), 'invalid-argument');
  await expectError(host.call('updateProfile', { name: 'أبو فيصل', avatar: '💩' }), 'invalid-argument');
  await host.call('updateProfile', { name: 'أبو فيصل', avatar: 'cool' });
  const daily = await host.call<{ coins: number; streak: number }>('claimDaily');
  assert.deepEqual([daily.coins, daily.streak], [200, 1]);
  await expectError(host.call('claimDaily'), 'failed-precondition');
  const afterSetup = await host.profile();
  assert.deepEqual([afterSetup.name, afterSetup.avatar, afterSetup.setupDone, afterSetup.coins], ['أبو فيصل', 'cool', true, 2200]);
  for (const [i, p] of rest.entries()) await p.call('updateProfile', { name: `لاعب ${i + 1}`, avatar: 'falcon' });
  // الاسم لواحد بس، حتى لو اختلفت الهمزة أو المسافات، وأسماء البوتات محجوزة
  await expectError(rest[0].call('updateProfile', { name: 'ابو  فيصل', avatar: 'falcon' }), 'already-exists');
  await expectError(rest[0].call('updateProfile', { name: 'سلمان', avatar: 'falcon' }), 'already-exists');
  await host.call('updateProfile', { name: 'أبو فيصل', avatar: 'cool' });
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
    if (v.yourRole === 'loyal') assert.equal(known, 1, 'الوفي يعرف دوره بس (حتى العرّاف قبل ما يكشف)');
  }
  console.log('✓ الحالة الكاملة مقفلة، وكل لاعب يشوف أسراره هو بس');

  // العرّاف: يكشف لاعب واحد متى ما بغى، والباقين ما يدرون
  const seerIdx = views.findIndex((v) => (v as PlayerView & { yourSpecial: string | null }).yourSpecial === 'seer');
  const seer = players[seerIdx];
  const peekTarget = players[(seerIdx + 1) % players.length];
  const notSeer = players[(seerIdx + 2) % players.length];
  await expectError(notSeer.call('act', { code, action: { type: 'seerReveal', target: peekTarget.uid } }), 'failed-precondition');
  await seer.call('act', { code, action: { type: 'seerReveal', target: peekTarget.uid } });
  const seerView = await seer.view(code);
  assert.equal(seerView.players.filter((p) => p.knownRole !== null).length, 2);
  assert.equal((seerView as PlayerView & { seerReady: boolean }).seerReady, false);
  await expectError(seer.call('act', { code, action: { type: 'seerReveal', target: notSeer.uid } }), 'failed-precondition');
  const otherView = await notSeer.view(code);
  assert.equal((otherView as PlayerView & { seerSees: string | null }).seerSees, null);
  console.log('✓ العرّاف: يكشف مرة وحدة بس، والباقين ما يدرون');

  // ٣. الردود السريعة
  await rest[0].call('react', { code, kind: 'suspect', target: rest[1].uid });
  await rest[1].call('react', { code, kind: 'laugh' });
  await expectError(rest[0].call('react', { code, kind: 'trust', target: rest[0].uid }), 'invalid-argument');
  await expectError(rest[2].call('react', { code, kind: 'hello' }), 'invalid-argument');
  const roomDoc = (await getDoc(doc(getFirestore(host.app), `rooms/${code}`))).data()!;
  assert.equal(roomDoc.reactions.length, 2);
  assert.equal(roomDoc.opinions[rest[0].uid][rest[1].uid], 'suspect');
  await rest[0].call('clearOpinion', { code, target: rest[1].uid });
  const cleared = (await getDoc(doc(getFirestore(host.app), `rooms/${code}`))).data()!;
  assert.equal(cleared.opinions[rest[0].uid]?.[rest[1].uid], undefined, 'الرأي ينشال لو غيّر رأيه');
  console.log('✓ الردود السريعة تنحفظ، ومؤشر الشك يتحدث وينشال، والردود الغلط ترفض');

  // ٤. حركة غلط ترفض
  const notPresident = players.find((p) => p.uid !== views[0].presidentId)!;
  await expectError(notPresident.call('act', { code, action: { type: 'nominate', chancellor: host.uid } }), 'failed-precondition');
  console.log('✓ السيرفر يرفض الحركات الغلط');

  // ٤ب. المؤقت: قبل الوقت ما يصير شي، وبعده السيرفر يلعب بدال الرئيس
  const v1 = (await host.view(code)) as PlayerView & { deadline: number };
  assert.equal(v1.phase, 'nomination');
  assert.ok(v1.deadline > Date.now(), 'فيه وقت للدور');
  assert.equal((await host.call<{ applied: boolean }>('timeout', { code })).applied, false);
  await new Promise((r) => setTimeout(r, v1.deadline - Date.now() + 300));
  assert.equal((await rest[0].call<{ applied: boolean }>('timeout', { code })).applied, true);
  assert.equal((await rest[1].call<{ applied: boolean }>('timeout', { code })).applied, false, 'مرة وحدة بس');
  const v2 = (await host.view(code)) as PlayerView & { deadline: number };
  assert.equal(v2.phase, 'election');
  assert.ok(v2.deadline > v1.deadline, 'مؤقت جديد للتصويت');
  await host.call('act', { code, action: { type: 'vote', ja: true } });
  const v3 = (await host.view(code)) as PlayerView & { deadline: number };
  assert.equal(v3.deadline, v2.deadline, 'الصوت الواحد ما يغير المؤقت');
  console.log('✓ المؤقت: ينتظر لين يخلص الوقت، ويرشح بدال الرئيس مرة وحدة، والتصويت له وقته');

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

  // ٥ب. المهام اليومية
  const m0 = (await rest[0].profile()).missions;
  assert.equal(m0.progress.play3, 1);
  assert.equal(m0.progress.react5, 1);
  await expectError(rest[0].call('claimMission', { id: 'play3' }), 'failed-precondition');
  await expectError(rest[0].call('claimMission', { id: 'nope' }), 'invalid-argument');
  const withMissions = await Promise.all(players.map(async (p) => ({ p, m: (await p.profile()).missions })));
  const legislator = withMissions.find(({ m }) => m.progress.legislate1 === 1);
  assert.ok(legislator, 'واحد على الأقل مرّر قرار');
  const coins0 = (await legislator.p.profile()).coins;
  assert.equal((await legislator.p.call<{ coins: number }>('claimMission', { id: 'legislate1' })).coins, 250);
  assert.equal((await legislator.p.profile()).coins, coins0 + 250);
  await expectError(legislator.p.call('claimMission', { id: 'legislate1' }), 'failed-precondition');
  console.log('✓ المهام: التقدم ينحسب، وما تنستلم قبل ما تخلص، وتنستلم مرة وحدة');

  // ٥ج. جدول الترتيب
  const boardDb = getFirestore(host.app);
  const all = await getDocs(query(collection(boardDb, 'leaderboard'), orderBy('gamesWon', 'desc'), limit(50)));
  assert.equal(all.size, 5);
  const top = all.docs[0].data();
  assert.ok(top.gamesWon >= 1 && top.name && top.avatar && top.coins === undefined, 'بدون الذهب');
  const weekly = await getDocs(
    query(collection(boardDb, 'leaderboard'), where('week', '==', top.week), orderBy('weeklyWins', 'desc')),
  );
  assert.equal(weekly.docs[0].data().weeklyWins, 1);
  console.log('✓ جدول الترتيب: الكل والأسبوعي، والذهب ما يطلع للناس');

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

  // ٨. المتجر: الشراء واللبس، والإطار يطلع في الطاولة
  const rich = (await Promise.all(players.map(async (p) => ({ p, prof: await p.profile() })))).sort(
    (a, b) => b.prof.coins - a.prof.coins,
  )[0];
  assert.ok(rich.prof.coins >= 3000, 'الفايز عنده ذهب يكفي');
  await expectError(rich.p.call('buyItem', { id: 'frame_king' }), 'failed-precondition');
  await expectError(rich.p.call('buyItem', { id: 'nope' }), 'invalid-argument');
  await expectError(rich.p.call('equipItem', { id: 'frame_ice' }), 'permission-denied');
  await rich.p.call('buyItem', { id: 'frame_ice' });
  const bought = await rich.p.profile();
  assert.equal(bought.coins, rich.prof.coins - 3000);
  assert.deepEqual(bought.owned, ['frame_ice']);
  assert.equal(bought.equipped.frame, 'frame_ice', 'يلبسه على طول');
  await expectError(rich.p.call('buyItem', { id: 'frame_ice' }), 'already-exists');
  await rich.p.call('equipItem', { id: 'frame_none' });
  assert.equal((await rich.p.profile()).equipped.frame, 'frame_none');
  await rich.p.call('equipItem', { id: 'frame_ice' });
  const { code: shopRoom } = await rich.p.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  const shopRoomData = (await getDoc(doc(getFirestore(host.app), `rooms/${shopRoom}`))).data()!;
  assert.equal(shopRoomData.players[0].frame, 'frame_ice');
  console.log('✓ المتجر: الشراء ينخصم ويلبس، وما ينشرى مرتين، والإطار يطلع في الطاولة');

  // ٩. الإشعارات: الجهاز ينحفظ، والإرسال الفاشل (المحاكي ما يرسل فعلياً) ما يخرب اللعبة
  await expectError(host.call('registerPushToken', { token: 'short' }), 'invalid-argument');
  for (const p of players) await p.call('registerPushToken', { token: `fake-token-${p.uid}-xxxxxxxxxxxxxxxx` });
  assert.equal((await host.profile()).fcmTokens.length, 1);
  const { code: pushRoom } = await host.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  for (const p of rest) await p.call('joinRoom', { code: pushRoom });
  await host.call('startGame', { code: pushRoom });
  const pv = await host.view(pushRoom);
  const pres = players.find((p) => p.uid === pv.presidentId)!;
  const target = pv.players.find((x) => x.id !== pres.uid)!.id;
  await pres.call('act', { code: pushRoom, action: { type: 'nominate', chancellor: target } });
  assert.equal((await host.view(pushRoom)).phase, 'election');
  console.log('✓ الإشعارات: الأجهزة تنحفظ، واللعبة تكمل حتى لو الإرسال فشل');

  // ١٠. البوتات: لاعب واحد يسوي روم خاص ويكمله بالبوتات ويلعب لين النهاية
  const { code: botRoom } = await host.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  await expectError(rest[0].call('addBots', { code: botRoom }), 'permission-denied');
  for (let i = 0; i < 4; i++) await host.call('addBots', { code: botRoom });
  await expectError(host.call('addBots', { code: botRoom }), 'failed-precondition');
  const botRoomData = (await getDoc(doc(getFirestore(host.app), `rooms/${botRoom}`))).data()!;
  assert.equal(botRoomData.players.filter((p: { bot?: boolean }) => p.bot).length, 4);
  const removed = botRoomData.players.find((p: { bot?: boolean }) => p.bot).uid;
  await host.call('removeBot', { code: botRoom, botId: removed });
  await host.call('addBots', { code: botRoom });
  await host.call('startGame', { code: botRoom });
  const hostBefore = await host.profile();
  let steps = 0;
  for (;;) {
    const v = (await host.view(botRoom)) as PlayerView & { deadline: number | null };
    if (v.phase === 'gameOver') {
      console.log(`  انتهت لعبة البوتات بعد ${steps} خطوة: ${v.winner} (${v.winReason})`);
      break;
    }
    assert.ok(steps++ < 400, 'لعبة البوتات طولت');
    const mine = nextMove(v);
    if (mine) {
      await host.call('act', { code: botRoom, action: mine });
      continue;
    }
    // الدور على بوت: ننتظر مهلته القصيرة ونطلب من السيرفر يلعب عنه.
    if (v.deadline) await new Promise((r) => setTimeout(r, Math.max(0, v.deadline! - Date.now()) + 50));
    await host.call('timeout', { code: botRoom });
  }
  const hostAfter = await host.profile();
  assert.equal(hostAfter.gamesPlayed, hostBefore.gamesPlayed + 1, 'اللعبة انحسبت للاعب');
  const botBoard = await getDoc(doc(getFirestore(host.app), `leaderboard/${removed}`));
  assert.equal(botBoard.exists(), false, 'البوت ما يدخل الترتيب');
  console.log('✓ البوتات: تنضاف وتنشال، وتلعب بنفسها لين النهاية، وما تدخل الترتيب');

  // الخروج من لعبة شغالة: يكمل عنه بوت، وما يقدر يلعب بعدها
  const { code: leaveRoom } = await host.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  for (let i = 0; i < 4; i++) await host.call('addBots', { code: leaveRoom });
  await host.call('startGame', { code: leaveRoom });
  await host.call('leaveGame', { code: leaveRoom });
  const leftView = (await host.view(leaveRoom)) as PlayerView & { autopilot: string[] };
  assert.ok(leftView.autopilot.includes(host.uid), 'البوت يلعب عنه');
  const leftRoom = (await getDoc(doc(getFirestore(host.app), `rooms/${leaveRoom}`))).data()!;
  assert.equal(leftRoom.players.find((p: { uid: string }) => p.uid === host.uid).bot, true, 'يطلع جنبه 🤖 للكل');
  await expectError(host.call('act', { code: leaveRoom, action: { type: 'vote', ja: true } }), 'failed-precondition');
  console.log('✓ الخروج: البوت يكمل عنه، وما يقدر يلعب بعدها');

  // ١١. الطاولة العامة: ما تتكمل بالبوتات قبل ٢٠ ثانية
  const { code: lonelyQm } = await host.call<{ code: string }>('quickMatch', { maxPlayers: 5, tierId: 'starter' });
  await expectError(host.call('addBots', { code: lonelyQm }), 'failed-precondition');
  await new Promise((r) => setTimeout(r, 20_500));
  await host.call('addBots', { code: lonelyQm });
  assert.equal((await host.view(lonelyQm)).phase, 'nomination');
  console.log('✓ الطاولة العامة: بعد ٢٠ ثانية تتكمل بالبوتات وتبدأ');

  // ١٢. ربط الحساب بقوقل: المكافأة بس للي ربط، ومرة وحدة
  const linker = players[1];
  await expectError(linker.call('claimLinkReward'), 'failed-precondition');
  const linkerCoins = (await linker.profile()).coins;
  const auth = getAuth(linker.app);
  // المحاكي يقبل توكن قوقل وهمي بصيغة JSON.
  await linkWithCredential(auth.currentUser!, GoogleAuthProvider.credential('{"sub":"g-123","email":"tester@example.com"}'));
  await auth.currentUser!.getIdToken(true);
  assert.equal(auth.currentUser!.uid, linker.uid, 'نفس الحساب بعد الربط، والتقدم ما يضيع');
  assert.deepEqual(await linker.call('claimLinkReward'), { coins: 500 });
  assert.deepEqual(await linker.call('claimLinkReward'), { coins: 0 });
  assert.equal((await linker.profile()).coins, linkerCoins + 500);
  console.log('✓ ربط قوقل: نفس الحساب، و٥٠٠ ذهب مرة وحدة');

  // أدوات المطور: ترفض أي أحد، وتشتغل بس لإيميل المطور المتحقق منه
  await expectError(linker.call('devTool', { action: 'grant', coins: 100 }), 'permission-denied');
  const dev = await client(99);
  const devAuth = getAuth(dev.app);
  await linkWithCredential(
    devAuth.currentUser!,
    GoogleAuthProvider.credential('{"sub":"g-dev","email":"hussainfaisalaljaser@gmail.com","email_verified":true}'),
  );
  await devAuth.currentUser!.getIdToken(true);
  await dev.call('ensureProfile');
  assert.equal((await dev.profile()).dev, true, 'حساب المطور ينعرف');
  const devCoins = (await dev.profile()).coins;
  await dev.call('devTool', { action: 'grant', coins: 10000 });
  await dev.call('devTool', { action: 'level', level: 5 });
  const devAfter = await dev.profile();
  assert.equal(devAfter.coins, devCoins + 10000);
  assert.equal(devAfter.level, 5);
  console.log('✓ وضع المطور: لإيميل المطور بس');

  // المتجر الجديد: الطاولة تنلبس، والشخصية المميزة تصير صورته، والباقة تفتح ردودها
  await dev.call('devTool', { action: 'grant', coins: 30000, diamonds: 100 });
  await expectError(dev.call('updateProfile', { name: 'المطور', avatar: 'emir' }), 'permission-denied');
  const beforeShop = await dev.profile();
  await dev.call('buyItem', { id: 'table_night' });
  await dev.call('buyItem', { id: 'avatar_emir' });
  const shopper = await dev.profile();
  assert.equal(shopper.coins, beforeShop.coins, 'المطور يشتري ببلاش');
  assert.equal(shopper.diamonds, beforeShop.diamonds);
  assert.equal(shopper.equipped.table, 'table_night');
  assert.equal(shopper.avatar, 'emir');
  await dev.call('updateProfile', { name: 'المطور', avatar: 'falcon' });
  await dev.call('updateProfile', { name: 'المطور', avatar: 'emir' });
  await dev.call('equipItem', { id: 'table_majlis' });
  assert.equal((await dev.profile()).equipped.table, 'table_majlis');
  await expectError(dev.call('equipItem', { id: 'pack_emoji' }), 'invalid-argument');
  const { code: packRoom } = await dev.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  for (let i = 0; i < 4; i++) await dev.call('addBots', { code: packRoom });
  await dev.call('startGame', { code: packRoom });
  await expectError(dev.call('react', { code: packRoom, kind: 'fire' }), 'permission-denied');
  await dev.call('buyItem', { id: 'pack_emoji' });
  await dev.call('react', { code: packRoom, kind: 'fire' });
  console.log('✓ المتجر الجديد: طاولة، شخصية مميزة، وباقة ردود');
  await deleteApp(dev.app);

  await Promise.all(players.map((p) => deleteApp(p.app)));
  console.log('\nكل الاختبارات نجحت ✅');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
