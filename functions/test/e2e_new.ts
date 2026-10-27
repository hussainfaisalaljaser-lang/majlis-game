/**
 * اختبار المزايا الجديدة على محاكي Firebase: المفضلة، والأدوار الجديدة (قاضي، شيخ، جاسوس) ونسخة التطبيق،
 * والكروت الحقيقية بعد اللعبة («مين كذب؟»)، و«العب مرة ثانية».
 * التشغيل: MAJLIS_FAST_PACING=1 npx firebase emulators:exec --only auth,firestore,functions "npx tsx test/e2e_new.ts"
 */
import assert from 'node:assert/strict';
import { deleteApp, initializeApp, type FirebaseApp } from 'firebase/app';
import { GoogleAuthProvider, connectAuthEmulator, getAuth, linkWithCredential, signInAnonymously } from 'firebase/auth';
import { connectFirestoreEmulator, doc, getDoc, getFirestore } from 'firebase/firestore';
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

async function training(dev: Client, special?: string): Promise<string> {
  const { code } = await dev.call<{ code: string }>('startTraining');
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

  // ٢. نسخة التطبيق: لو فيه أحد بنسخة قديمة، ما تطلع الأدوار الجديدة
  const old = await client(3);
  await old.call('ensureProfile');
  await old.call('updateProfile', { name: 'نسخة قديمة', avatar: 'falcon' });
  const { code: mixed } = await dev.call<{ code: string }>('createRoom', { maxPlayers: 5 });
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

  await Promise.all([dev, plain, old, friend, watcher].map((c) => deleteApp(c.app)));
  console.log('\nكل اختبارات المزايا الجديدة نجحت ✅');
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
