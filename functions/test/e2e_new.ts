/**
 * اختبار المزايا الجديدة على محاكي Firebase: المفضلة، والأدوار الجديدة (قاضي، شيخ، جاسوس) ونسخة التطبيق،
 * والكروت الحقيقية بعد اللعبة («مين كذب؟»)، و«العب مرة ثانية».
 * التشغيل: MAJLIS_FAST_PACING=1 npx firebase emulators:exec --only auth,firestore,functions "npx tsx test/e2e_new.ts"
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
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  type Firestore,
} from 'firebase/firestore';
import { connectFunctionsEmulator, getFunctions, httpsCallable } from 'firebase/functions';
import { initializeApp as adminApp } from 'firebase-admin/app';
import { getFirestore as adminFirestore } from 'firebase-admin/firestore';
import type { GameState, PlayerView } from '../../engine/src/index.js';

const PROJECT = 'majlis-game-1d739';
const admin = adminFirestore(adminApp({ projectId: PROJECT }, 'admin'));
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

interface Client {
  app: FirebaseApp;
  uid: string;
  fs: Firestore;
  call: <T = unknown>(name: string, data?: unknown) => Promise<T>;
  view: (code: string) => Promise<PlayerView>;
  profile: () => Promise<Record<string, any>>;
  room: (code: string) => Promise<Record<string, any>>;
}

async function client(i: number, owner = false): Promise<Client> {
  const app = initializeApp({ projectId: PROJECT, apiKey: 'fake' }, `n${i}`);
  const auth = getAuth(app);
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  const fs = getFirestore(app);
  connectFirestoreEmulator(fs, '127.0.0.1', 8080);
  const fns = getFunctions(app, 'europe-west1');
  connectFunctionsEmulator(fns, '127.0.0.1', 5001);
  const { user } = await signInAnonymously(auth);
  if (owner) {
    await linkWithCredential(
      user,
      GoogleAuthProvider.credential(`{"sub":"g-owner-${i}","email":"hussainfaisalaljaser@gmail.com","email_verified":true}`),
    );
    await user.getIdToken(true);
  }
  return {
    app,
    uid: user.uid,
    fs,
    call: async (name, data) => (await httpsCallable(fns, name)(data)).data as never,
    view: async (code) => (await getDoc(doc(fs, `games/${code}/views/${user.uid}`))).data() as PlayerView,
    profile: async () => (await getDoc(doc(fs, `users/${user.uid}`))).data()!,
    room: async (code) => (await getDoc(doc(fs, `rooms/${code}`))).data()!,
  };
}

async function expectError(p: Promise<unknown>, code: string): Promise<void> {
  await assert.rejects(p, (e: { code?: string }) => {
    assert.equal(e.code, `functions/${code}`);
    return true;
  });
}

const fullGame = async (code: string) => (await admin.doc(`games/${code}`).get()).data() as GameState;

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

/** يلعب مع البوتات لين [stop]: حركته هو (أو [extra] لو رجّعت حركة)، والبوتات بطلب timeout. */
async function drive(
  c: Client,
  code: string,
  stop: (v: PlayerView) => boolean,
  extra?: (v: PlayerView) => Record<string, unknown> | null,
): Promise<PlayerView> {
  for (let i = 0; i < 800; i++) {
    const v = await c.view(code);
    if (stop(v)) return v;
    const move = extra?.(v) ?? nextMove(v);
    if (move) {
      try {
        await c.call('act', { code, action: move });
        continue;
      } catch {
        // الحالة تغيّرت قبل حركتنا: نكمل.
      }
    }
    await sleep(250);
    await c.call('timeout', { code });
  }
  throw new Error('اللعبة ما وصلت للي ننتظره');
}

async function training(dev: Client, special?: string, roles = true): Promise<string> {
  const { code } = await dev.call<{ code: string }>('startTraining', { roles });
  if (special) await dev.call('devTool', { action: 'forceRole', code, special });
  return code;
}

async function main(): Promise<void> {
  const dev = await client(1, true);
  await dev.call('ensureProfile', { proto: 2 });
  await dev.call('updateProfile', { name: 'المطور', avatar: 'cool' });
  assert.equal((await dev.profile()).proto, 2);
  assert.equal((await dev.profile()).dev, true);

  // ١. المفضلة: بالكثير ٥، ومن الباقات اللي تملكها، وملصقات بس
  await expectError(
    dev.call('setFavorites', { ids: ['b_laugh', 'b_think', 'b_eyes', 'b_smirk', 'b_shh', 'b_angry'] }),
    'invalid-argument',
  );
  await expectError(dev.call('setFavorites', { ids: ['suspect'] }), 'invalid-argument');
  await expectError(dev.call('setFavorites', { ids: ['nothing'] }), 'invalid-argument');
  const plain = await client(2);
  await plain.call('ensureProfile', { proto: 2 });
  await expectError(plain.call('setFavorites', { ids: ['laugh_tears'] }), 'permission-denied');
  await dev.call('setFavorites', { ids: ['b_laugh', 'b_think', 'b_laugh'] });
  assert.deepEqual((await dev.profile()).favorites, ['b_laugh', 'b_think'], 'بدون تكرار وبالترتيب');
  console.log('✓ المفضلة: بالكثير ٥، من الباقات اللي تملكها');

  // ٢أ. الطور العادي (الافتراضي): الزعيم والخونة والأوفياء بس، بدون أي دور خاص
  const classic = await training(dev, undefined, false);
  assert.ok((await fullGame(classic)).players.every((p) => !p.special), 'العادي بدون أدوار خاصة');
  const { code: classicRoom } = await dev.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  for (let i = 0; i < 4; i++) await dev.call('addBots', { code: classicRoom });
  await dev.call('startGame', { code: classicRoom });
  assert.ok((await fullGame(classicRoom)).players.every((p) => !p.special), 'الروم الخاص العادي بدون أدوار خاصة');
  console.log('✓ الطور العادي: بدون عرّاف ولا حارس ولا أي دور خاص');

  // ٢. نسخة التطبيق: لو فيه أحد بنسخة قديمة، ما تطلع الأدوار الجديدة (في طور الشخصيات)
  const old = await client(3);
  await old.call('ensureProfile');
  await old.call('updateProfile', { name: 'نسخة قديمة', avatar: 'falcon' });
  const { code: mixed } = await dev.call<{ code: string }>('createRoom', { maxPlayers: 5, roles: true });
  await old.call('joinRoom', { code: mixed });
  for (let i = 0; i < 3; i++) await dev.call('addBots', { code: mixed });
  await dev.call('startGame', { code: mixed });
  const mixedSpecials = (await fullGame(mixed)).players.map((p) => p.special).filter(Boolean);
  assert.deepEqual(mixedSpecials.sort(), ['guardian', 'seer'], 'بس العرّاف والحارس');
  const modern = await training(dev);
  const extra = (await fullGame(modern)).players.filter((p) => ['judge', 'elder', 'spy'].includes(p.special ?? ''));
  assert.equal(extra.length, 1, 'طاولة ٥: دور جديد واحد');
  console.log(`✓ نسخة التطبيق: القديمة بدون أدوار جديدة، والجديدة فيها ${extra[0].special}`);

  // ٣. القاضي يلغي التصويت
  const jcode = await training(dev, 'judge');
  assert.equal((await fullGame(jcode)).players.find((p) => p.id === dev.uid)!.special, 'judge');
  const judged = await drive(
    dev,
    jcode,
    (v) => v.log.some((e) => e.type === 'voteResult' && e.cancelledBy === dev.uid),
    (v) => ((v as PlayerView & { judgeReady: boolean }).judgeReady ? { type: 'judgeCancel' } : null),
  );
  const cancelled = judged.log.find((e) => e.type === 'voteResult' && e.cancelledBy)!;
  assert.ok(cancelled.type === 'voteResult' && !cancelled.passed);
  const g = await fullGame(jcode);
  assert.equal(g.judgeUsed, true);
  const botId = g.players.find((p) => p.id.startsWith('bot_'))!.id;
  const { viewFor } = await import('../../engine/src/index.js');
  assert.equal(viewFor(g, botId).players.find((p) => p.id === dev.uid)!.knownSpecial, 'judge', 'انكشف للكل');
  console.log('✓ القاضي: ألغى التصويت والحكومة سقطت وانكشف');

  // ٤. الجاسوس يشوف أول كرت مرة وحدة
  const scode = await training(dev, 'spy');
  const before = await dev.view(scode);
  assert.equal((before as PlayerView & { spyReady: boolean }).spyReady, true);
  const top = (await fullGame(scode)).drawPile[0];
  await dev.call('act', { code: scode, action: { type: 'spyPeek' } });
  const saw = (await dev.view(scode)) as PlayerView & { spySaw: { card: string; round: number } | null };
  assert.equal(saw.spySaw?.card, top);
  await expectError(dev.call('act', { code: scode, action: { type: 'spyPeek' } }), 'failed-precondition');
  console.log('✓ الجاسوس: شاف أول كرت مرة وحدة');

  // ٥. الشيخ صوته بصوتين
  const ecode = await training(dev, 'elder');
  const voted = await drive(dev, ecode, (v) => v.log.some((e) => e.type === 'voteResult'));
  const firstVote = voted.log.find((e) => e.type === 'voteResult')!;
  assert.ok(firstVote.type === 'voteResult' && firstVote.weights?.[dev.uid] === 2);
  console.log('✓ الشيخ: صوته بصوتين');

  // ٦. «مين كذب؟»: الكروت الحقيقية تطلع بس بعد نهاية اللعبة
  assert.equal(voted.truths, null, 'سر وقت اللعب');
  const over = await drive(dev, ecode, (v) => v.phase === 'gameOver');
  const enacted = over.log.filter((e) => e.type === 'enacted' && !e.chaos);
  assert.ok(over.truths, 'بعد اللعبة تطلع');
  for (const e of enacted) {
    const t = over.truths![e.round];
    assert.equal(t?.president.length, 3, `الجولة ${e.round}: كروت الرئيس`);
    assert.equal(t?.chancellor.length, 2, `الجولة ${e.round}: كروت الوزير`);
  }
  console.log(`✓ مين كذب: ${enacted.length} حكومة بكروتها الحقيقية بعد النهاية`);

  // ٦ب. سجل المباريات: اللعبة اللي خلصت تنحفظ لصاحبها (له بس) بأدوارها وكروتها الحقيقية ونتيجته.
  const hist = await getDocs(query(collection(dev.fs, `users/${dev.uid}/history`), orderBy('at', 'desc')));
  const entry = hist.docs.map((d) => d.data()).find((h) => h.room.code === ecode);
  assert.ok(entry, 'اللعبة في السجل');
  assert.equal(entry.view.phase, 'gameOver');
  assert.ok(entry.view.truths, 'فيها الكروت الحقيقية');
  assert.ok(entry.view.players.every((p: { knownRole: string | null }) => p.knownRole), 'كل الأدوار مكشوفة');
  const myTeam = entry.view.yourRole === 'loyal' ? 'loyal' : 'traitor';
  assert.equal(entry.room.results[dev.uid].won, myTeam === entry.view.winner, 'نتيجته');
  assert.ok(entry.expireAt, 'تنحذف بعد ٣٠ يوم');
  await assert.rejects(getDocs(collection(plain.fs, `users/${dev.uid}/history`)), 'غيره ما يشوفه');
  console.log('✓ سجل المباريات: اللعبة انحفظت لصاحبها بأدوارها وكروتها ونتيجته، وغيره ما يشوفها');

  // ٧. «العب مرة ثانية» في التدريب: نفس البوتات، وتبدأ على طول
  const oldBots = (await dev.room(ecode)).players.filter((p: { bot?: boolean }) => p.bot).map((p: { name: string }) => p.name);
  const again = await dev.call<{ code: string; started: boolean }>('rematch', { code: ecode });
  assert.equal(again.started, true);
  const fresh = await dev.room(again.code);
  assert.equal(fresh.status, 'playing');
  assert.deepEqual(
    fresh.players.filter((p: { bot?: boolean }) => p.bot).map((p: { name: string }) => p.name).sort(),
    [...oldBots].sort(),
    'نفس البوتات',
  );
  assert.equal((await dev.room(ecode)).next, again.code);
  await expectError(dev.call('rematch', { code: mixed }), 'failed-precondition');
  console.log('✓ العب مرة ثانية (تدريب): نفس البوتات وبدأت على طول');

  // ٨. «العب مرة ثانية» مع صاحب: أول واحد يسوي الروم، والثاني يدخله
  const friend = await client(4);
  await friend.call('ensureProfile', { proto: 2 });
  await friend.call('updateProfile', { name: 'الصاحب', avatar: 'falcon' });
  const { code: pr } = await dev.call<{ code: string }>('createRoom', { maxPlayers: 5 });
  await friend.call('joinRoom', { code: pr });
  for (let i = 0; i < 3; i++) await dev.call('addBots', { code: pr });
  await dev.call('startGame', { code: pr });
  // نخلّص اللعبة بسرعة (المهم هنا الإعادة).
  await admin.doc(`rooms/${pr}`).update({ status: 'finished' });
  const r1 = await friend.call<{ code: string; started: boolean }>('rematch', { code: pr });
  assert.equal(r1.started, false, 'فيه بشر ثانيين: تنتظر');
  const waiting = await dev.room(r1.code);
  assert.deepEqual([waiting.status, waiting.hostId, waiting.isPrivate, waiting.players.length], ['waiting', friend.uid, true, 4]);
  const r2 = await dev.call<{ code: string; started: boolean }>('rematch', { code: pr });
  assert.equal(r2.code, r1.code, 'دخل نفس الروم');
  assert.equal((await dev.room(r1.code)).players.length, 5);
  await friend.call('startGame', { code: r1.code });
  assert.equal((await dev.room(r1.code)).status, 'playing');
  console.log('✓ العب مرة ثانية مع صاحب: روم واحد للكل، وصاحبه يبدأ');

  // ٩. التفرج: صاحبك يلعب الحين؟ تتفرج على نسخة ما فيها ولا سر
  const watcher = await client(5);
  await watcher.call('ensureProfile', { proto: 2 });
  await watcher.call('updateProfile', { name: 'المتفرج', avatar: 'falcon' });
  const devPid = (await dev.profile()).pid as string;
  const found = await watcher.call<{ uid: string }>('findPlayer', { pid: devPid });
  assert.equal(found.uid, dev.uid);
  await expectError(watcher.call('spectate', { uid: dev.uid }), 'permission-denied');
  await watcher.call('friendRequest', { uid: dev.uid });
  await dev.call('friendRespond', { uid: watcher.uid, accept: true });
  const live = await training(dev);
  const board = (await admin.doc(`leaderboard/${dev.uid}`).get()).data()!;
  assert.ok(board.playingSince > 0, 'يبان لأصحابه إنه يلعب');
  assert.equal(board.code, undefined, 'كود الروم ما يطلع للناس');
  const { code: watched } = await watcher.call<{ code: string }>('spectate', { uid: dev.uid });
  assert.equal(watched, live);
  const wfs = getFirestore(watcher.app);
  const wv = (await getDoc(doc(wfs, `games/${live}/views/_watch`))).data() as PlayerView;
  assert.equal(wv.spectator, true);
  assert.ok(wv.players.every((p) => p.knownRole === null), 'ما يشوف الأدوار');
  assert.deepEqual(wv.hand, []);
  await assert.rejects(getDoc(doc(wfs, `games/${live}/views/${dev.uid}`)), 'نسخة اللاعب نفسه ممنوعة');
  await assert.rejects(getDoc(doc(getFirestore(plain.app), `games/${live}/views/_watch`)), 'اللي مو متفرج ممنوع');
  assert.deepEqual((await dev.room(live)).watchers, [watcher.uid]);
  await watcher.call('stopWatching', { code: live });
  assert.deepEqual((await dev.room(live)).watchers, []);
  await drive(dev, live, (v) => v.phase === 'gameOver');
  assert.equal((await admin.doc(`leaderboard/${dev.uid}`).get()).data()!.playingSince, null, 'خلصت: ما عاد يلعب');
  console.log('✓ التفرج: لأصحابه بس، نسخة بدون أسرار، والعدد يتحدث');

  // ١٠. الدواوين: تأسيس وانضمام ونواب وطرد، ونقاط من الطاولات العامة، وصندوق الهدف
  await expectError(plain.call('createClan', { name: 'ديوان فقير', color: 0, emblem: 'falcon' }), 'failed-precondition');
  await expectError(dev.call('createClan', { name: 'x', color: 0, emblem: 'falcon' }), 'invalid-argument');
  const { id: clanId } = await dev.call<{ id: string }>('createClan', { name: 'ديوان الصقور', color: 2, emblem: 'hawk' });
  await expectError(dev.call('createClan', { name: 'ديوان ثاني', color: 0, emblem: 'falcon' }), 'failed-precondition');
  await admin.doc(`users/${friend.uid}`).update({ coins: 9000 });
  await expectError(friend.call('createClan', { name: 'ديوان  الصقور', color: 1, emblem: 'falcon' }), 'already-exists');
  await plain.call('updateProfile', { name: 'العضو', avatar: 'falcon' });
  await plain.call('joinClan', { id: clanId });
  assert.equal((await plain.profile()).clan.id, clanId);
  assert.equal((await admin.doc(`leaderboard/${plain.uid}`).get()).data()!.clan.name, 'ديوان الصقور', 'يطلع في بطاقته');
  await dev.call('clanRole', { uid: plain.uid, deputy: true });
  await expectError(plain.call('clanKick', { uid: dev.uid }), 'permission-denied');
  await dev.call('clanKick', { uid: plain.uid });
  assert.equal((await plain.profile()).clan, null);
  const { code: pub } = await dev.call<{ code: string }>('quickMatch', { maxPlayers: 5, tierId: 'starter' });
  await sleep(21_000);
  await dev.call('addBots', { code: pub });
  const pubEnd = await drive(dev, pub, (v) => v.phase === 'gameOver');
  const won = (await dev.room(pub)).results[dev.uid].won as boolean;
  const clanDoc = (await admin.doc(`clans/${clanId}`).get()).data()!;
  const week = Object.keys(clanDoc.weekly).sort().at(-1)!;
  assert.equal(clanDoc.weekly[week], won ? 30 : 10, 'نقاط اللعبة للديوان');
  assert.equal(clanDoc.members[dev.uid].points, won ? 30 : 10);
  assert.ok(pubEnd.phase === 'gameOver');
  await expectError(dev.call('claimClanChest'), 'failed-precondition');
  await admin.doc(`clans/${clanId}`).update({ [`weekly.${week}`]: 3000 });
  const coinsBefore = (await dev.profile()).coins;
  await dev.call('claimClanChest');
  assert.equal((await dev.profile()).coins, coinsBefore + 1000);
  await expectError(dev.call('claimClanChest'), 'already-exists');
  await dev.call('leaveClan');
  assert.equal((await admin.doc(`clans/${clanId}`).get()).exists, false, 'آخر واحد طلع: انحذف');
  console.log('✓ الدواوين: تأسيس وانضمام ونواب وطرد ونقاط وصندوق وحذف');

  // ١١. بطولة الأسبوع: تسجيل برسوم، وجولة بطولة تتكمل بالبوتات، والنتيجة تتأهل أو تطلع
  const coins0 = (await plain.profile()).coins;
  await plain.call('tourJoin');
  assert.equal((await plain.profile()).coins, coins0 - 1000);
  await expectError(plain.call('tourJoin'), 'already-exists');
  const { code: tcode } = await plain.call<{ code: string }>('tourPlay');
  const troom = await plain.room(tcode);
  assert.deepEqual([troom.tour, troom.maxPlayers, troom.isPrivate], [0, 7, false]);
  await sleep(21_000);
  await plain.call('addBots', { code: tcode });
  await drive(plain, tcode, (v) => v.phase === 'gameOver');
  const tres = (await plain.room(tcode)).results[plain.uid];
  const tp = (await plain.profile()).tour;
  if (tres.won) assert.deepEqual([tp.stage, tp.out, tres.tour.stage], [1, false, 1], 'فاز: نص النهائي');
  else assert.deepEqual([tp.stage, tp.out, tres.tour.out], [0, true, true], 'خسر: طلع');
  const board2 = (await admin.doc(`tours/${tp.week}`).get()).data()!;
  assert.equal(board2.players[plain.uid].stage, tp.stage);
  await expectError(plain.call('rematch', { code: tcode }), 'failed-precondition');
  console.log(`✓ البطولة: ${tres.won ? 'فاز وتأهل لنص النهائي' : 'خسر وطلع'}، ولوحة البطولة تحدّثت`);

  // ١٢. الباتل باس: مهام الأسبوع والموسم، وخياري الشراء، والإهداء لصاحب
  const pm = (await plain.profile()).passMissions;
  assert.ok((pm?.weekly?.play ?? 0) >= 1 && (pm?.total?.play ?? 0) >= 1, 'اللعبة انحسبت في مهام الباتل باس');
  await expectError(plain.call('claimPassMission', { id: 'w_play10' }), 'failed-precondition');
  await expectError(plain.call('claimPassMission', { id: 'nope' }), 'invalid-argument');
  await admin.doc(`users/${plain.uid}`).update({ 'passMissions.weekly.play': 10 });
  const passBefore = (await plain.profile()).pass?.points ?? 0;
  assert.equal((await plain.call<{ points: number }>('claimPassMission', { id: 'w_play10' })).points, 120);
  assert.equal((await plain.profile()).pass.points, passBefore + 120);
  await expectError(plain.call('claimPassMission', { id: 'w_play10' }), 'failed-precondition');
  console.log('✓ مهام الباتل باس: اللعب ينحسب، والاستلام مرة وحدة ويعطي نقاط');

  await admin.doc(`users/${plain.uid}`).update({ diamonds: 2000 });
  await plain.call('buyPass');
  let pp = await plain.profile();
  assert.equal(pp.pass.premium, true);
  assert.equal(pp.pass.points, passBefore + 120 + 10 * 150, 'العادي معه ١٠ درجات هدية');
  assert.equal(pp.diamonds, 2000 - 150);
  await expectError(plain.call('buyPass'), 'already-exists');
  await plain.call('buyPass', { full: true });
  pp = await plain.profile();
  assert.equal(pp.pass.points, 30 * 150, 'الكامل يفتح كل الدرجات');
  assert.equal(pp.diamonds, 2000 - 750, 'الكامل بعد العادي بالفرق بس');
  await expectError(plain.call('buyPass', { full: true }), 'already-exists');
  console.log('✓ الباتل باس: العادي بـ١٥٠ ومعه ١٠ درجات، والكامل بالفرق يفتح كل الدرجات');

  await expectError(dev.call('giftPass', { uid: plain.uid }), 'permission-denied');
  await dev.call('giftPass', { uid: watcher.uid, full: true });
  const wp = await watcher.profile();
  assert.equal(wp.pass.premium, true);
  assert.equal(wp.pass.points, 30 * 150);
  const pg = wp.gifts.find((g: { kind: string }) => g.kind === 'passGift');
  assert.deepEqual([pg.from, pg.n], ['المطور', 1]);
  await expectError(dev.call('giftPass', { uid: watcher.uid }), 'already-exists');
  console.log('✓ الإهداء: لأصحابك بس، ويوصل صاحبك الباتل باس وهدية باسمك');

  // ١٣. الشرح الإجباري: اللاعب الجديد يقدر يتخطاه بنفسه، ومرة وحدة تكفي.
  const newbie = await client(9);
  await newbie.call('ensureProfile', { proto: 2 });
  assert.equal((await newbie.profile()).tutorialSkipped, undefined);
  await newbie.call('skipTutorial');
  assert.equal((await newbie.profile()).tutorialSkipped, true);
  await newbie.call('skipTutorial');
  assert.equal((await newbie.profile()).tutorialDone, undefined, 'التخطي ما يعطي مكافأة الشرح');
  console.log('✓ الشرح الإجباري: يتخطاه بنفسه، وبدون مكافأة');

  // ١٤. الدواوين: الوصف والشروط (المستوى، بطلب، بالدعوة) والرتب وتسليم المشيخة.
  const [sheikh, joiner, outsider, stranger] = [await client(10), await client(11), await client(12), await client(13)];
  for (const [c, name] of [
    [sheikh, 'شيخ تجربة'],
    [joiner, 'طالب تجربة'],
    [outsider, 'ضيف تجربة'],
    [stranger, 'غريب تجربة'],
  ] as const) {
    await c.call('ensureProfile', { proto: 2 });
    await c.call('updateProfile', { name, avatar: 'falcon' });
  }
  await admin.doc(`users/${sheikh.uid}`).update({ coins: 9000 });
  const { id: cid } = await sheikh.call<{ id: string }>('createClan', {
    name: 'ديوان النخبة',
    color: 1,
    emblem: 'falcon',
    desc: 'هلا يا كلب',
    minLevel: 50,
    join: 'request',
  });
  let cd = (await admin.doc(`clans/${cid}`).get()).data()!;
  assert.equal(cd.desc, 'هلا يا ***', 'الكلام السيء ينخفى في الوصف');
  assert.deepEqual([cd.minLevel, cd.join], [50, 'request']);
  await expectError(joiner.call('joinClan', { id: cid }), 'failed-precondition');
  await admin.doc(`users/${joiner.uid}`).update({ xp: 50_000_000 });
  assert.equal((await joiner.call<{ requested?: boolean }>('joinClan', { id: cid })).requested, true);
  assert.ok((await admin.doc(`clans/${cid}`).get()).data()!.requests[joiner.uid], 'الطلب وصل الديوان');
  await sheikh.call('clanRespond', { uid: joiner.uid, accept: true });
  assert.equal((await joiner.profile()).clan.id, cid);
  await sheikh.call('clanRole', { uid: joiner.uid, role: 'elder' });
  assert.equal((await admin.doc(`clans/${cid}`).get()).data()!.members[joiner.uid].role, 'elder');
  await expectError(joiner.call('clanSettings', { desc: '', minLevel: 0, join: 'open' }), 'permission-denied');
  await sheikh.call('clanSettings', { desc: 'ديوان للمحترفين', minLevel: 0, join: 'invite' });
  await expectError(outsider.call('joinClan', { id: cid }), 'permission-denied');
  await joiner.call('clanInvite', { uid: outsider.uid });
  assert.equal((await outsider.profile()).clanInvites[cid].fromName, 'طالب تجربة');
  await outsider.call('clanInviteRespond', { id: cid, accept: true });
  assert.equal((await outsider.profile()).clan.id, cid, 'الدعوة تدخّله');
  await sheikh.call('clanRole', { uid: joiner.uid, role: 'owner' });
  cd = (await admin.doc(`clans/${cid}`).get()).data()!;
  assert.deepEqual([cd.ownerId, cd.members[sheikh.uid].role], [joiner.uid, 'deputy']);
  console.log('✓ الدواوين: وصف وشروط (مستوى وطلب ودعوة)، ورتب (وجيه ونائب)، وتسليم المشيخة');

  // ١٥. الدردشة: الديوان لأعضائه بس، وبين الأصحاب بس، والكلام السيء ينخفى، ورسالة كل ثانية.
  await outsider.call('sendChat', { to: 'clan', text: 'هلا يا حمار' });
  await expectError(outsider.call('sendChat', { to: 'clan', text: 'ثانية' }), 'resource-exhausted');
  const last = await admin.collection(`clans/${cid}/chat`).orderBy('at', 'desc').limit(1).get();
  assert.deepEqual([last.docs[0].data().text, last.docs[0].data().role], ['هلا يا ****', 'member']);
  assert.ok((await getDocs(collection(outsider.fs, `clans/${cid}/chat`))).size >= 3, 'العضو يقرا (ومعها أسطر الدخول)');
  await assert.rejects(getDocs(collection(stranger.fs, `clans/${cid}/chat`)), 'الغريب ما يقرا دردشة الديوان');
  await expectError(stranger.call('sendChat', { to: outsider.uid, text: 'هلا' }), 'permission-denied');
  await stranger.call('friendRequest', { uid: outsider.uid });
  await outsider.call('friendRespond', { uid: stranger.uid, accept: true });
  await stranger.call('sendChat', { to: outsider.uid, text: 'شوف www.spam.com' });
  assert.equal((await outsider.profile()).dmUnread[stranger.uid], 1);
  const pair = [stranger.uid, outsider.uid].sort().join('_');
  const dms = await getDocs(collection(outsider.fs, `dms/${pair}/msgs`));
  assert.equal(dms.docs[0].data().text, 'شوف •••', 'الروابط تنخفى');
  await assert.rejects(getDocs(collection(sheikh.fs, `dms/${pair}/msgs`)), 'الثالث ما يقرا');
  await outsider.call('readDm', { uid: stranger.uid });
  assert.equal((await outsider.profile()).dmUnread[stranger.uid], undefined);
  console.log('✓ الدردشة: الديوان لأعضائه، والأصحاب بس، والكلام السيء والروابط تنخفى');

  // ١٦. حالة الاتصال: كل واحد يكتب نبضته، وأصحابه وربعه في الديوان يشوفونها، والغريب لا.
  await setDoc(doc(stranger.fs, `presence/${stranger.uid}`), { t: serverTimestamp(), on: true });
  await assert.rejects(setDoc(doc(stranger.fs, `presence/${outsider.uid}`), { t: serverTimestamp(), on: true }));
  await assert.rejects(setDoc(doc(stranger.fs, `presence/${stranger.uid}`), { t: 5, on: true }), 'الوقت لازم من السيرفر');
  assert.equal((await getDoc(doc(outsider.fs, `presence/${stranger.uid}`))).data()!.on, true, 'صاحبه يشوفه');
  await setDoc(doc(outsider.fs, `presence/${outsider.uid}`), { t: serverTimestamp(), on: true });
  assert.equal((await getDoc(doc(joiner.fs, `presence/${outsider.uid}`))).exists(), true, 'ربعه في الديوان يشوفونه');
  await assert.rejects(getDoc(doc(sheikh.fs, `presence/${stranger.uid}`)), 'الغريب ما يشوف');
  console.log('✓ حالة الاتصال: لأصحابك وربعك في الديوان بس');

  // ١٧. افكت الموت: الافتراضي الغطا، وينشرى ويتلبس، وينحفظ في الروم عشان الكل يشوفه (والبوتات لها افكتاتها).
  const fx = await client(17);
  await fx.call('ensureProfile', { proto: 2 });
  await fx.call('updateProfile', { name: 'صاحب الافكت', avatar: 'falcon' });
  type Seat = { uid: string; bot?: boolean; death?: string };
  const deathIn = async (code: string) => ((await fx.room(code)).players as Seat[]).find((p) => p.uid === fx.uid)!.death;
  assert.equal(await deathIn(await training(fx, undefined, false)), 'death_cloth', 'الافتراضي الغطا');
  await expectError(fx.call('equipItem', { id: 'death_fire' }), 'permission-denied');
  await admin.doc(`users/${fx.uid}`).update({ coins: 9000 });
  await fx.call('buyItem', { id: 'death_sand' });
  assert.equal((await fx.profile()).equipped.death, 'death_sand', 'ينلبس أول ما ينشرى');
  await fx.call('equipItem', { id: 'death_cloth' });
  await fx.call('equipItem', { id: 'death_sand' });
  const fxRoom = await training(fx, undefined, false);
  const seats = (await fx.room(fxRoom)).players as Seat[];
  assert.equal(await deathIn(fxRoom), 'death_sand', 'افكته في الروم');
  assert.ok(seats.filter((p) => p.bot).some((p) => p.death), 'البوتات لها افكتات');
  console.log('✓ افكت الموت: ينشرى وينلبس، ويوصل للروم عشان الكل يشوفه');

  // ١٨. الحماية من الغش: على المراقبة الكل يدخل، ولما تتفعّل اللي بدون شهادة التطبيق ينرفض (إلا صاحب اللعبة).
  type Mode = { mode: string };
  assert.equal((await dev.call<Mode>('devTool', { action: 'appCheck' })).mode, 'monitor', 'الافتراضي مراقبة');
  await expectError(plain.call('devTool', { action: 'appCheck', mode: 'enforce' }), 'permission-denied');
  await dev.call('devTool', { action: 'appCheck', mode: 'enforce' });
  await expectError(fx.call('claimDaily'), 'failed-precondition');
  await expectError(fx.call('ensureProfile', { proto: 2 }), 'failed-precondition');
  assert.equal((await dev.call<Mode>('devTool', { action: 'appCheck' })).mode, 'enforce', 'صاحب اللعبة يدخل دايم');
  await dev.call('devTool', { action: 'appCheck', mode: 'monitor' });
  await fx.call('ensureProfile', { proto: 2 });
  console.log('✓ الحماية من الغش: مراقبة بالبداية، ولما تتفعّل اللي بدون شهادة ينرفض وصاحب اللعبة يدخل');

  await Promise.all(
    [dev, plain, old, friend, watcher, newbie, sheikh, joiner, outsider, stranger, fx].map((c) => deleteApp(c.app)),
  );
  console.log('\nكل اختبارات المزايا الجديدة نجحت ✅');
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
