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
import { SEASON } from '../src/catalog.js';
import { seasonActive } from '../src/rewards.js';

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
  // طور الشخصيات (فيه العرّاف والحارس) عشان نجرب العرّاف تحت.
  const { code } = await host.call<{ code: string }>('createRoom', { maxPlayers: 5, roles: true });
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
  await rest[1].call('react', { code, kind: 'b_laugh' });
  await expectError(rest[1].call('react', { code, kind: 'shock_jaw' }), 'permission-denied');
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
    assert.equal(r.rank, undefined, 'الروم الخاص ما يحسب في التصنيف');
    assert.equal(after.xp - (before[i].xp ?? 0), r.won ? 50 : 20);
    assert.equal(after.gamesPlayed, 1);
    assert.equal(after.gamesWon, r.won ? 1 : 0);
  }
  console.log('✓ نهاية الروم الخاص: خبرة للكل، والفايزين انحسب لهم فوز');

  // ٥أ. بعد اللعبة: الطاولة تبقى للسوالف (حتى المطرودين) لين يطلعون، واللي يطلع يبان للباقين
  const roomRef = doc(getFirestore(host.app), `rooms/${code}`);
  await rest[2].call('react', { code, kind: 'b_laugh' });
  await expectError(rest[3].call('react', { code, kind: 'suspect', target: host.uid }), 'failed-precondition');
  const deadOne = players.find((p) => end.players.some((x) => x.id === p.uid && !x.alive) && p !== rest[0]);
  if (deadOne) await deadOne.call('react', { code, kind: 'innocent' });
  await rest[2].call('leaveGame', { code });
  await rest[2].call('leaveGame', { code });
  assert.deepEqual((await getDoc(roomRef)).data()!.gone, [rest[2].uid], 'اللي طلع ينحفظ مرة وحدة');
  await new Promise((r) => setTimeout(r, 1600));
  await expectError(rest[2].call('react', { code, kind: 'b_laugh' }), 'failed-precondition');
  console.log(`✓ بعد اللعبة: الطاولة تبقى للسوالف${deadOne ? ' (حتى المطرود)' : ''}، واللي يطلع يبان إنه طلع`);

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
  // ذهب الإنجازات (لو أحد وصل درجة جديدة في هاللعبة) ينحسب لحاله.
  const achCoins = (prof: Record<string, any>) =>
    ((prof.gifts ?? []) as { kind: string; coins: number }[]).filter((g) => g.kind === 'achievement').reduce((a, g) => a + g.coins, 0);
  const startProfiles = await Promise.all(players.map((p) => p.profile()));
  const startCoins = startProfiles.map((p) => p.coins - achCoins(p));
  const codes = new Set<string>();
  for (const p of players) codes.add((await p.call<{ code: string }>('quickMatch', { maxPlayers: 5, tierId: 'city' })).code);
  assert.equal(codes.size, 1, 'كلهم لازم يدخلون نفس الروم');
  const [qm] = codes;
  assert.equal((await players[2].view(qm)).phase, 'nomination');
  for (const [i, p] of players.entries()) {
    const prof = await p.profile();
    assert.equal(prof.coins - achCoins(prof), startCoins[i] - 1000);
  }
  console.log(`✓ المطابقة: ٥ لاعبين دخلوا روم ${qm} ودفعوا الرسوم وبدأت تلقائياً`);
  await playToEnd(players, qm);
  const qmResults = (await getDoc(doc(getFirestore(host.app), `rooms/${qm}`))).data()!.results;
  const winnerCount = Object.values(qmResults).filter((r: any) => r.won).length;
  for (const [i, p] of players.entries()) {
    const expected = qmResults[p.uid].won ? Math.floor(5000 / winnerCount) : 0;
    assert.equal(qmResults[p.uid].coins, expected);
    const prof = await p.profile();
    assert.equal(prof.coins - achCoins(prof), startCoins[i] - 1000 + expected);
  }
  console.log(`✓ الجائزة: ${winnerCount} فايزين، كل واحد أخذ ${Math.floor(5000 / winnerCount)} ذهب`);
  // التصنيف: الطاولة العامة تحسب، والفايز يطلع، والخسران ما ينزل تحت الصفر
  for (const p of players) {
    const r = qmResults[p.uid];
    assert.equal(typeof r.rank, 'number');
    if (r.won) assert.ok(r.rank > 0, 'الفايز ياخذ نقاط تصنيف');
    else assert.ok(r.rank <= 0);
  }
  const rankWinner = players.find((p) => qmResults[p.uid].won)!;
  const rankBoard = (await getDoc(doc(getFirestore(host.app), `leaderboard/${rankWinner.uid}`))).data()!;
  assert.equal(rankBoard.rankPoints, qmResults[rankWinner.uid].rank);
  assert.equal((await rankWinner.profile()).rank.points, qmResults[rankWinner.uid].rank);
  console.log(`✓ التصنيف: الفايز +${qmResults[rankWinner.uid].rank} في الموسم ${rankBoard.rankSeason}`);

  // ٨. المتجر: الشراء واللبس، والإطار يطلع في الطاولة
  const rich = (await Promise.all(players.map(async (p) => ({ p, prof: await p.profile() })))).sort(
    (a, b) => b.prof.coins - a.prof.coins,
  )[0];
  // الفايز معه ٢٦٦٦ ذهب على الأقل (لو فازوا ٣)، والفقاعة الذهبية بـ ٢٥٠٠.
  assert.ok(rich.prof.coins >= 2500, 'الفايز عنده ذهب يكفي');
  await expectError(rich.p.call('buyItem', { id: 'frame_king' }), 'failed-precondition');
  await expectError(rich.p.call('buyItem', { id: 'nope' }), 'invalid-argument');
  await expectError(rich.p.call('buyItem', { id: 'frame_rainbow' }), 'failed-precondition');
  await expectError(rich.p.call('equipItem', { id: 'bubble_gold' }), 'permission-denied');
  await rich.p.call('buyItem', { id: 'bubble_gold' });
  const bought = await rich.p.profile();
  assert.equal(bought.coins, rich.prof.coins - 2500);
  assert.deepEqual(bought.owned, ['bubble_gold']);
  assert.equal(bought.equipped.bubble, 'bubble_gold', 'يلبسه على طول');
  await expectError(rich.p.call('buyItem', { id: 'bubble_gold' }), 'already-exists');
  await rich.p.call('equipItem', { id: 'bubble_classic' });
  assert.equal((await rich.p.profile()).equipped.bubble, 'bubble_classic');
  await rich.p.call('equipItem', { id: 'bubble_gold' });
  const { code: shopRoom } = await rich.p.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  const shopRoomData = (await getDoc(doc(getFirestore(host.app), `rooms/${shopRoom}`))).data()!;
  assert.equal(shopRoomData.players[0].bubble, 'bubble_gold');
  console.log('✓ المتجر: الشراء ينخصم ويلبس، وما ينشرى مرتين، وما يكفي الذهب يرفض، والفقاعة تطلع في الطاولة');

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
  const botTalk = ((await getDoc(doc(getFirestore(host.app), `rooms/${botRoom}`))).data()!.reactions ?? []).filter(
    (r: { from: string }) => r.from.startsWith('bot_'),
  );
  assert.ok(botTalk.length > 0, 'البوتات يتفاعلون في الطاولة');
  console.log(`  البوتات ردّوا ${botTalk.length} مرة: ${botTalk.map((r: { kind: string }) => r.kind).join('، ')}`);
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
  assert.equal(devAfter.coins, devCoins + 10000 + 1000, 'ومعها هدية مستوى ٥');
  assert.equal(devAfter.level, 5);
  console.log('✓ وضع المطور: لإيميل المطور بس');

  // صاحب اللعبة يخلي أي لاعب مطوّر برمزه ويشيله، والمطوّر ما يقدر يخلي غيره
  const helperPid = (await linker.profile()).pid as string;
  await expectError(dev.call('devTool', { action: 'setDev', pid: '12' }), 'invalid-argument');
  const made = await dev.call<{ name: string; pid: string }>('devTool', { action: 'setDev', pid: helperPid, on: true });
  assert.equal(made.pid, helperPid);
  assert.equal((await linker.profile()).dev, true, 'صار مطوّر');
  await linker.call('devTool', { action: 'grant', coins: 100 });
  await expectError(linker.call('devTool', { action: 'setDev', pid: helperPid, on: false }), 'permission-denied');
  const devList = await dev.call<{ devs: { pid: string }[] }>('devTool', { action: 'devs' });
  assert.ok(devList.devs.some((d) => d.pid === helperPid), 'يطلع في قائمة المطورين');
  await linker.call('ensureProfile');
  assert.equal((await linker.profile()).dev, true, 'يبقى مطوّر لما يفتح اللعبة من جديد');
  await dev.call('devTool', { action: 'setDev', pid: helperPid, on: false });
  assert.equal((await linker.profile()).dev, false);
  await expectError(linker.call('devTool', { action: 'grant', coins: 100 }), 'permission-denied');
  await dev.call('ensureProfile');
  assert.equal((await dev.profile()).owner, true, 'صاحب اللعبة');
  console.log('✓ المطورين: صاحب اللعبة يخلي أي لاعب مطوّر برمزه ويشيله');

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
  await expectError(dev.call('equipItem', { id: 'stk_shock' }), 'invalid-argument');
  const { code: packRoom } = await dev.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  for (let i = 0; i < 4; i++) await dev.call('addBots', { code: packRoom });
  await dev.call('startGame', { code: packRoom });
  await expectError(dev.call('react', { code: packRoom, kind: 'shock_jaw' }), 'permission-denied');
  await dev.call('buyItem', { id: 'stk_shock' });
  await dev.call('react', { code: packRoom, kind: 'shock_jaw' });
  await dev.call('buyItem', { id: 'bubble_neon' });
  await dev.call('equipItem', { id: 'bubble_neon' });
  const { code: bubbleRoom } = await dev.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  const bubbleRoomData = (await getDoc(doc(getFirestore(dev.app), `rooms/${bubbleRoom}`))).data()!;
  assert.equal(bubbleRoomData.players[0].bubble, 'bubble_neon', 'الفقاعة تطلع للكل في الطاولة');
  await dev.call('leaveRoom', { code: bubbleRoom });
  console.log('✓ المتجر الجديد: طاولة، شخصية مميزة، باقة ملصقات، وفقاعة');

  // هدايا المستويات: كل ٥ مستويات شي، وكل ١٠ إطار وشخصية. ما تنعطى مرتين.
  await expectError(dev.call('buyItem', { id: 'frame_lv10' }), 'failed-precondition');
  await dev.call('devTool', { action: 'level', level: 1 });
  await dev.call('ackGifts');
  const beforeLevels = await dev.profile();
  await dev.call('devTool', { action: 'level', level: 10 });
  const leveled = await dev.profile();
  for (const id of ['bubble_lv5', 'frame_lv10', 'avatar_lv10']) assert.ok(leveled.owned.includes(id), id);
  assert.equal(leveled.coins, beforeLevels.coins + 3000);
  assert.equal(leveled.diamonds, beforeLevels.diamonds + 5);
  assert.deepEqual(leveled.gifts.map((g: { n: number }) => g.n), [5, 10]);
  await dev.call('ackGifts');
  assert.deepEqual((await dev.profile()).gifts, []);
  await dev.call('equipItem', { id: 'frame_lv10' });
  await dev.call('updateProfile', { name: 'المطور', avatar: 'lv10' });
  await dev.call('devTool', { action: 'level', level: 10 });
  assert.equal((await dev.profile()).coins, leveled.coins, 'نفس المستوى ما يعطي مرة ثانية');
  console.log('✓ هدايا المستويات: مستوى ٥ و١٠، مرة وحدة بس');

  // الباتل باس: المجاني للكل، والمدفوع يفتح مكافآته (حتى اللي فاتت)
  if (seasonActive(Date.now())) {
    await dev.call('devTool', { action: 'passPoints', points: 450 });
    const free = await dev.call<{ coins: number; items: string[] }>('claimPassRewards');
    assert.equal(free.coins, 300, 'المجاني: درجة ٢');
    assert.deepEqual(free.items, []);
    await dev.call('buyPass');
    await expectError(dev.call('buyPass'), 'already-exists');
    // الباتل باس العادي معه ١٠ درجات هدية: من الدرجة ٣ لين ١٣، ويستلم المجاني ٤–١٣ والمدفوع ١–١٣.
    assert.equal((await dev.profile()).pass.points, 450 + SEASON.bonus_tiers * SEASON.tier_points);
    const track = (t: Record<string, { coins: number; items: string[] }>, from: number, to: number) =>
      Object.entries(t).filter(([k]) => +k >= from && +k <= to).map(([, r]) => r);
    const expected = [...track(SEASON.free, 4, 13), ...track(SEASON.premium, 1, 13)];
    const prem = await dev.call<{ coins: number; items: string[] }>('claimPassRewards');
    assert.equal(prem.coins, expected.reduce((n, r) => n + r.coins, 0), 'المجاني والمدفوع لين درجة ١٣');
    assert.deepEqual([...prem.items].sort(), expected.flatMap((r) => r.items).sort());
    assert.ok(prem.items.includes('avatar_s1a'));
    const again = await dev.call<{ coins: number; items: string[] }>('claimPassRewards');
    assert.equal(again.coins, 0);
    assert.ok((await dev.profile()).owned.includes('avatar_s1a'));
    console.log('✓ الباتل باس: المجاني والمدفوع، والاستلام مرة وحدة');
  }

  // لعبة الشرح: أنت وفي وأول رئيس، والبوتات يوافقون على أول حكومة، والمكافأة لمن يكملها بس
  const newbie = await client(77);
  await newbie.call('ensureProfile');
  const newbieCoins = (await newbie.profile()).coins;
  const botTurns = async (code: string, mine: (v: PlayerView) => Record<string, unknown> | null) => {
    let steps = 0;
    for (;;) {
      const v = (await newbie.view(code)) as PlayerView & { deadline: number | null };
      if (v.phase === 'gameOver') return steps;
      assert.ok(steps++ < 400, 'لعبة الشرح طولت');
      const move = mine(v);
      if (move) {
        await newbie.call('act', { code, action: move });
        continue;
      }
      if (v.deadline) await new Promise((r) => setTimeout(r, Math.max(0, v.deadline! - Date.now()) + 50));
      await newbie.call('timeout', { code });
    }
  };
  // اللي يطلع من الشرح قبل لا يخلص ما ياخذ المكافأة
  const { code: quit } = await newbie.call<{ code: string }>('startTutorial');
  await newbie.call('leaveGame', { code: quit });
  await botTurns(quit, () => null);
  const quitter = await newbie.profile();
  assert.ok(!quitter.tutorialDone, 'طلع قبل لا يخلص');
  assert.ok(!(quitter.gifts ?? []).some((g: { kind: string }) => g.kind === 'tutorial'));

  const { code: tut } = await newbie.call<{ code: string }>('startTutorial');
  const first = await newbie.view(tut);
  assert.equal(first.tutorial, true);
  assert.equal(first.yourRole, 'loyal');
  assert.equal(first.yourSpecial, null);
  assert.equal(first.presidentId, newbie.uid);
  assert.equal(first.players.length, 5);
  let firstGov: boolean | null = null;
  const tutSteps = await botTurns(tut, (v) => {
    // أول حكومة: الكل وافق، فتوصل للرئيس الكروت
    if (firstGov === null && v.phase === 'presidentDiscard') firstGov = v.round === 1;
    if (firstGov === null && v.round > 1) firstGov = false;
    return nextMove(v);
  });
  assert.equal(firstGov, true, 'أول حكومة تنتخب في الشرح');
  const tutProfile = await newbie.profile();
  assert.equal(tutProfile.tutorialDone, true);
  assert.ok(tutProfile.coins >= newbieCoins + 500, 'مكافأة الشرح وصلت');
  assert.equal(tutProfile.gifts.filter((g: { kind: string }) => g.kind === 'tutorial').length, 1);
  console.log(`✓ لعبة الشرح: وفي وأول رئيس، الحكومة الأولى تمر، و+٥٠٠ لمن يكملها (${tutSteps} خطوة)`);
  await deleteApp(newbie.app);

  // الوضع السريع: الروم يوصل للعبة، ووقت دور اللاعب نص الوقت، والطاولات السريعة ما تختلط بالعادية
  const { code: quickRoom } = await players[3].call<{ code: string }>('createRoom', { maxPlayers: 5, quick: true });
  for (let i = 0; i < 4; i++) await players[3].call('addBots', { code: quickRoom });
  await players[3].call('startGame', { code: quickRoom });
  const qv = (await players[3].view(quickRoom)) as PlayerView & { deadline: number | null };
  assert.equal(qv.quick, true);
  await players[3].call('leaveGame', { code: quickRoom });
  const { code: normalTable } = await players[1].call<{ code: string }>('quickMatch', { maxPlayers: 6, tierId: 'starter' });
  const { code: quickTable } = await players[2].call<{ code: string }>('quickMatch', { maxPlayers: 6, tierId: 'starter', quick: true });
  assert.notEqual(normalTable, quickTable, 'السريع ما يدخل طاولة عادية');
  const { code: quickTable2 } = await players[4].call<{ code: string }>('quickMatch', { maxPlayers: 6, tierId: 'starter', quick: true });
  assert.equal(quickTable2, quickTable, 'السريع يدخل طاولة سريعة');
  // طور الشخصيات ما يختلط بالطور العادي.
  const { code: rolesTable } = await players[0].call<{ code: string }>('quickMatch', { maxPlayers: 6, tierId: 'starter', roles: true });
  assert.notEqual(rolesTable, normalTable, 'طور الشخصيات ما يدخل طاولة عادية');
  for (const [p, c] of [[players[1], normalTable], [players[2], quickTable], [players[4], quickTable], [players[0], rolesTable]] as const) await p.call('leaveRoom', { code: c });
  console.log('✓ الوضع السريع والطور: الطاولات العامة ما تختلط');

  // الأسماء المسيئة تنرفض
  await expectError(players[0].call('updateProfile', { name: 'شرموط', avatar: 'falcon' }), 'invalid-argument');
  // البلاغ: ٣ بلّغوا عن نفس الاسم = ينغيّر تلقائياً، والبلاغ المكرر ما ينحسب
  const reported = players[4];
  const reportArgs = { uid: reported.uid, reason: 'name' };
  await expectError(reported.call('reportPlayer', { ...reportArgs }), 'invalid-argument');
  await expectError(players[0].call('reportPlayer', { uid: 'bot_1', reason: 'name' }), 'invalid-argument');
  await expectError(players[0].call('reportPlayer', { uid: reported.uid, reason: 'rude' }), 'invalid-argument');
  const oldName = (await reported.profile()).name;
  await players[0].call('reportPlayer', reportArgs);
  const again = await players[0].call<{ already: boolean }>('reportPlayer', reportArgs);
  assert.equal(again.already, true);
  await players[1].call('reportPlayer', reportArgs);
  assert.equal((await reported.profile()).name, oldName, 'بلاغين ما يكفون');
  await players[2].call('reportPlayer', { ...reportArgs, code: 'ABCDE' });
  const renamedP = await reported.profile();
  assert.notEqual(renamedP.name, oldName);
  assert.ok(renamedP.name.startsWith('لاعب'));
  assert.equal(renamedP.renamed, true);
  assert.equal((await getDoc(doc(getFirestore(reported.app), `leaderboard/${reported.uid}`))).data()!.name, renamedP.name);
  // يختار اسم جديد: تنشال علامة التغيير
  await reported.call('updateProfile', { name: 'اسم نظيف', avatar: 'falcon' });
  assert.equal((await reported.profile()).renamed, false);
  // المطور يشوف البلاغات ويقفلها
  const { reports } = await dev.call<{ reports: { target: string; count: number }[] }>('devTool', { action: 'reports' });
  assert.ok(reports.find((r) => r.target === reported.uid)!.count >= 3);
  await expectError(players[0].call('devTool', { action: 'reports' }), 'permission-denied');
  const { resolved } = await dev.call<{ resolved: number }>('devTool', { action: 'resolveReport', target: reported.uid, decision: 'dismiss' });
  assert.ok(resolved >= 3);
  const after = await dev.call<{ reports: { target: string }[] }>('devTool', { action: 'reports' });
  assert.ok(!after.reports.some((r) => r.target === reported.uid));
  console.log('✓ البلاغ: الأسماء المسيئة تنرفض، و٣ بلاغات تغيّر الاسم، والمطور يقفلها');

  // الحظر
  await players[0].call('setBlocked', { uid: players[1].uid, blocked: true });
  assert.deepEqual((await players[0].profile()).blocked, [players[1].uid]);
  await players[0].call('setBlocked', { uid: players[1].uid, blocked: false });
  assert.deepEqual((await players[0].profile()).blocked, []);
  await expectError(players[0].call('setBlocked', { uid: players[0].uid, blocked: true }), 'invalid-argument');
  // رسالة للمطور
  await players[0].call('sendFeedback', { kind: 'idea', text: 'ابي وضع سريع', version: '92' });
  const { feedback } = await dev.call<{ feedback: { text: string }[] }>('devTool', { action: 'feedback' });
  assert.equal(feedback[0].text, 'ابي وضع سريع');
  console.log('✓ الحظر ورسائل التواصل');

  // الإنجازات: بعد الألعاب اللي فاتت، الإحصائيات تنحسب وتطلع في الترتيب
  const hostStats = await host.profile();
  assert.ok((hostStats.stats?.games ?? 0) >= 2, 'الألعاب تنعد');
  const board = (await getDoc(doc(getFirestore(host.app), `leaderboard/${host.uid}`))).data()!;
  assert.equal(typeof board.badges, 'object');
  console.log(`✓ الإنجازات: ${hostStats.stats.games} ألعاب انعدت، والدرجات: ${JSON.stringify(hostStats.badges ?? {})}`);

  // الرموز والأصدقاء: كل لاعب له رمز يبحثون فيه، وطلبات صداقة، ودعوة للروم
  const pals = await Promise.all([60, 61, 62, 63, 64].map(client));
  const palNames = ['رفيق', 'نديم', 'سمير', 'جليس', 'ونيس'];
  for (const [i, pal] of pals.entries()) {
    await pal.call('ensureProfile');
    await pal.call('updateProfile', { name: palNames[i], avatar: 'falcon' });
  }
  const [pa, pb, pc, pd, pe] = pals;
  const aProfile = await pa.profile();
  assert.match(aProfile.pid, /^[1-9]\d{7}$/, 'كل لاعب له رمز ٨ أرقام');
  assert.equal(aProfile.pidTier, 0);
  assert.notEqual(aProfile.pid, (await pb.profile()).pid);
  const aBoard = (await getDoc(doc(getFirestore(pb.app), `leaderboard/${pa.uid}`))).data()!;
  assert.equal(aBoard.pid, aProfile.pid, 'الرمز يطلع في بطاقته');
  const found = await pb.call<{ uid: string; name: string; pid: string }>('findPlayer', { pid: aProfile.pid });
  assert.equal(found.uid, pa.uid);
  assert.equal(found.name, 'رفيق');
  await expectError(pb.call('findPlayer', { pid: '12' }), 'invalid-argument');
  await expectError(pb.call('findPlayer', { pid: '99999998' }), 'not-found');
  // طلب وقبول
  assert.equal((await pb.call<{ status: string }>('friendRequest', { uid: pa.uid })).status, 'sent');
  assert.equal((await pb.call<{ status: string }>('friendRequest', { uid: pa.uid })).status, 'sent', 'الطلب ما يتكرر');
  assert.ok((await pa.profile()).friendReqs[pb.uid] > 0);
  assert.deepEqual((await pb.profile()).sentReqs, [pa.uid]);
  await pa.call('friendRespond', { uid: pb.uid, accept: true });
  assert.deepEqual((await pa.profile()).friends, [pb.uid]);
  assert.deepEqual((await pb.profile()).friends, [pa.uid]);
  assert.deepEqual((await pb.profile()).sentReqs, []);
  assert.deepEqual((await pa.profile()).friendReqs, {});
  // طلب من الطرفين: أصدقاء على طول
  await pc.call('friendRequest', { uid: pa.uid });
  assert.equal((await pa.call<{ status: string }>('friendRequest', { uid: pc.uid })).status, 'accepted');
  assert.ok((await pc.profile()).friends.includes(pa.uid));
  // رفض
  await pd.call('friendRequest', { uid: pa.uid });
  await pa.call('friendRespond', { uid: pd.uid, accept: false });
  assert.equal((await pa.profile()).friendReqs[pd.uid], undefined);
  assert.deepEqual((await pd.profile()).sentReqs, []);
  await expectError(pa.call('friendRespond', { uid: pd.uid, accept: true }), 'not-found');
  await expectError(pa.call('friendRequest', { uid: pa.uid }), 'invalid-argument');
  await expectError(pa.call('friendRequest', { uid: 'bot_1' }), 'invalid-argument');
  // اللي حاظرك ما يوصله طلبك
  await pd.call('setBlocked', { uid: pe.uid, blocked: true });
  assert.equal((await pe.call<{ status: string }>('friendRequest', { uid: pd.uid })).status, 'sent');
  assert.equal((await pd.profile()).friendReqs?.[pe.uid], undefined, 'طلب المحظور ما يوصل');
  await pd.call('setBlocked', { uid: pe.uid, blocked: false });
  // دعوة صديق للروم
  const { code: palRoom } = await pa.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  await expectError(pa.call('inviteFriend', { uid: pd.uid, code: palRoom }), 'failed-precondition');
  await pa.call('inviteFriend', { uid: pb.uid, code: palRoom });
  const invite = (await pb.profile()).invite;
  assert.equal(invite.code, palRoom);
  assert.equal(invite.from, pa.uid);
  assert.equal(invite.name, 'رفيق');
  await expectError(pa.call('inviteFriend', { uid: pb.uid, code: palRoom }), 'resource-exhausted');
  await pb.call('joinRoom', { code: palRoom });
  await expectError(pa.call('inviteFriend', { uid: pc.uid, code: 'ZZZZZ' }), 'failed-precondition');
  await pb.call('leaveRoom', { code: palRoom });
  await pa.call('leaveRoom', { code: palRoom });
  // شيل صديق
  await pa.call('removeFriend', { uid: pc.uid });
  assert.ok(!(await pa.profile()).friends.includes(pc.uid));
  assert.ok(!(await pc.profile()).friends.includes(pa.uid));
  console.log('✓ الأصدقاء: الرمز والبحث، والطلب والقبول والرفض، والحظر، ودعوة الروم، والإزالة');

  // الرمز المميز: السعر من الطول والنمط، وينشرى بالجواهر، والقديم ينفك
  const quote = await pa.call<{ price: number; available: boolean; tier: number }>('quotePid', { pid: '7777' });
  assert.deepEqual([quote.price, quote.available, quote.tier], [1500, true, 4]);
  await expectError(pa.call('quotePid', { pid: '0777' }), 'invalid-argument');
  await expectError(pa.call('buyPid', { pid: '7777' }), 'failed-precondition');
  const { list: ideas } = await pa.call<{ list: { pid: string; price: number; tier: number }[] }>('suggestIds');
  assert.ok(ideas.length >= 6 && ideas.every((x) => x.price > 30 && x.tier >= 1), 'اقتراحات مميزة');
  await dev.call('devTool', { action: 'grant', diamonds: 2000 });
  const devBefore = await dev.profile();
  await dev.call('buyPid', { pid: '7777' });
  const devPid = await dev.profile();
  assert.equal(devPid.pid, '7777');
  assert.equal(devPid.pidTier, 4);
  assert.equal(devPid.diamonds, devBefore.diamonds - 1500);
  assert.equal((await pa.call<{ uid: string }>('findPlayer', { pid: '7777' })).uid, dev.uid);
  await expectError(pa.call('findPlayer', { pid: devBefore.pid }), 'not-found');
  assert.equal((await getDoc(doc(getFirestore(pa.app), `leaderboard/${dev.uid}`))).data()!.pid, '7777');
  await expectError(pb.call('buyPid', { pid: '7777' }), 'already-exists');
  assert.equal((await pb.call<{ available: boolean }>('quotePid', { pid: '7777' })).available, false);
  console.log('✓ الرمز المميز: ٧٧٧٧ بـ ١٥٠٠ جوهرة، والقديم انفك، وما ينشرى مرتين');

  // حذف حساب صديق: ينشال من الأصدقاء ورمزه ينفك
  const fbPid = (await pb.profile()).pid;
  await pb.call('deleteAccount');
  assert.ok(!((await pa.profile()).friends ?? []).includes(pb.uid), 'انشال من أصدقائه');
  await expectError(pa.call('findPlayer', { pid: fbPid }), 'not-found');
  await Promise.all(pals.filter((x) => x !== pb).map((x) => deleteApp(x.app)));
  await deleteApp(pb.app);
  console.log('✓ حذف الحساب: ينشال من الأصدقاء ورمزه ينفك');

  // حذف الحساب: الملف والترتيب والاسم ينحذفون
  const leaver = await client(55);
  await leaver.call('ensureProfile');
  await leaver.call('updateProfile', { name: 'حذفني', avatar: 'falcon' });
  await leaver.call('sendFeedback', { kind: 'bug', text: 'رسالة قبل الحذف' });
  await leaver.call('deleteAccount');
  assert.equal((await getDoc(doc(getFirestore(players[0].app), `leaderboard/${leaver.uid}`))).exists(), false);
  await players[0].call('updateProfile', { name: 'حذفني', avatar: 'falcon' });
  assert.equal((await players[0].profile()).name, 'حذفني', 'الاسم انفك بعد الحذف');
  const fb = await dev.call<{ feedback: { text: string }[] }>('devTool', { action: 'feedback' });
  assert.ok(!fb.feedback.some((f) => f.text === 'رسالة قبل الحذف'), 'رسائله انحذفت');
  await deleteApp(leaver.app);
  console.log('✓ حذف الحساب: الملف والترتيب والاسم والرسائل');

  // طلب حذف من الموقع (بدون دخول): المطور يشوفه ويحذف الحساب
  const asker = await client(56);
  await asker.call('ensureProfile');
  await asker.call('updateProfile', { name: 'نسيت جوالي', avatar: 'falcon' });
  await expectError(asker.call('requestDeletion', { name: 'x' }), 'invalid-argument');
  await asker.call('requestDeletion', { name: 'نسيت جوالي', details: 'احذفوا حسابي', contact: '' });
  const { requests } = await dev.call<{ requests: { id: string; uid: string | null; name: string }[] }>('devTool', { action: 'deletionRequests' });
  const reqDoc = requests.find((r) => r.name === 'نسيت جوالي')!;
  assert.equal(reqDoc.uid, asker.uid, 'لقينا صاحب الاسم');
  const del = await dev.call<{ deleted: boolean }>('devTool', { action: 'deleteUser', request: reqDoc.id, confirm: true });
  assert.equal(del.deleted, true);
  assert.equal((await getDoc(doc(getFirestore(players[1].app), `leaderboard/${asker.uid}`))).exists(), false);
  await deleteApp(asker.app);
  console.log('✓ طلب الحذف من الموقع: المطور يراجعه ويحذف');

  // كل الطلبات من دالة وحدة (api) بهوية اللاعب، والتدريب يبدأ بطلب واحد
  const trainee = await client(57);
  const viaApi = <T = unknown>(fn: string, data: unknown = {}) => trainee.call<T>('api', { fn, data });
  await viaApi('ensureProfile');
  await viaApi('updateProfile', { name: 'متدرب', avatar: 'falcon' });
  assert.equal((await trainee.profile()).name, 'متدرب', 'الطلب وصل بهوية اللاعب');
  await expectError(viaApi('nothing'), 'not-found');
  await expectError(viaApi('updateProfile', { name: 'x', avatar: 'falcon' }), 'invalid-argument');
  const training = await viaApi<{ code: string }>('startTraining');
  const tv = await trainee.view(training.code);
  assert.equal(tv.players.length, 5);
  assert.equal(tv.players.filter((p) => p.id.startsWith('bot_')).length, 4, 'أنت و٤ بوتات');
  assert.equal(tv.phase, 'nomination');
  const troom = (await getDoc(doc(getFirestore(trainee.app), `rooms/${training.code}`))).data()!;
  assert.deepEqual([troom.isPrivate, troom.status, troom.hostId], [true, 'playing', trainee.uid]);
  // الحركات والمؤقت كذلك من api: ترشّح لو أنت الرئيس، وإلا البوت يرشّح لما يخلص وقته.
  if (tv.presidentId === trainee.uid) {
    const pick = tv.players.find((p) => p.id !== trainee.uid)!.id;
    await viaApi('act', { code: training.code, action: { type: 'nominate', chancellor: pick } });
  } else {
    for (let i = 0; i < 20 && (await trainee.view(training.code)).phase === 'nomination'; i++) {
      await new Promise((r) => setTimeout(r, 500));
      await viaApi('timeout', { code: training.code });
    }
  }
  assert.notEqual((await trainee.view(training.code)).phase, 'nomination', 'اللعبة مشت');
  await deleteApp(trainee.app);
  console.log('✓ دالة وحدة لكل الطلبات (api)، والتدريب يبدأ بطلب واحد');

  // أبطال الأسبوع: أول ٣ ياخذون إطار وشخصية مؤقتة
  const { champions } = await dev.call<{ champions: string[] }>('devTool', { action: 'crown' });
  assert.ok(champions.length >= 1, 'فيه فايزين هالأسبوع');
  const champ = players.find((p) => p.uid === champions[0])!;
  const champProfile = await champ.profile();
  assert.equal(champProfile.equipped.frame, 'frame_champ1');
  assert.equal(champProfile.avatar, 'champ1');
  assert.ok(champProfile.temp.frame_champ1 > Date.now());
  assert.ok(!champProfile.owned?.includes('frame_champ1'), 'مؤقت، مو ملك دائم');
  assert.equal(champProfile.gifts.at(-1).kind, 'champion');
  const meta = (await getDoc(doc(getFirestore(dev.app), 'meta/champions'))).data()!;
  assert.equal(meta.uids[0], champ.uid);
  console.log(`✓ أبطال الأسبوع: ${champions.length} تتوّجوا بإطار وشخصية لأسبوع`);
  await deleteApp(dev.app);

  await Promise.all(players.map((p) => deleteApp(p.app)));
  console.log('\nكل الاختبارات نجحت ✅');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
