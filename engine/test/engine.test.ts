import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  RuleError,
  applyAction,
  botSeerReveal,
  createGame,
  eligibleChancellors,
  viewFor,
  type Action,
  type GameState,
  type Policy,
  type Role,
} from '../src/index.js';
import { nextRandom } from '../src/rng.js';

const ids = (n: number) => Array.from({ length: n }, (_, i) => ({ id: `p${i}`, name: `لاعب ${i}` }));

/** لعبة بأدوار وكروت محددة، عشان نختبر حالات معينة. */
function rigged(n: number, roles: Role[], deck: Policy[], president = 'p0'): GameState {
  const s = createGame(ids(n), 1);
  s.players.forEach((p, i) => {
    p.role = roles[i];
    p.special = null;
  });
  s.seerSees = null;
  s.drawPile = [...deck];
  s.presidentId = president;
  s.rotationSeat = s.players.find((p) => p.id === president)!.seat;
  return s;
}

const act = (s: GameState, id: string, a: Action) => applyAction(s, id, a);

function voteAll(s: GameState, ja: boolean): GameState {
  for (const p of s.players.filter((p) => p.alive)) s = act(s, p.id, { type: 'vote', ja });
  return s;
}

/** حكومة كاملة: ترشيح، تصويت بالموافقة، الرئيس يرمي أول كرت، الوزير يمرر أول كرت. */
function govern(s: GameState, chancellor: string): GameState {
  const president = s.presidentId;
  s = act(s, president, { type: 'nominate', chancellor });
  s = voteAll(s, true);
  if (s.phase !== 'presidentDiscard') return s;
  s = act(s, president, { type: 'discard', index: 0 });
  return act(s, chancellor, { type: 'enact', index: 0 });
}

const FIVE: Role[] = ['loyal', 'loyal', 'loyal', 'traitor', 'leader'];

describe('إنشاء اللعبة', () => {
  it('يوزع الأدوار الصحيحة لكل عدد لاعبين', () => {
    const expected: Record<number, [number, number]> = { 5: [3, 1], 6: [4, 1], 7: [4, 2], 8: [5, 2], 9: [5, 3], 10: [6, 3] };
    for (const [n, [loyal, traitor]] of Object.entries(expected)) {
      const s = createGame(ids(Number(n)), 42);
      const count = (r: Role) => s.players.filter((p) => p.role === r).length;
      assert.equal(count('loyal'), loyal, `loyal for ${n}`);
      assert.equal(count('traitor'), traitor, `traitor for ${n}`);
      assert.equal(count('leader'), 1);
      assert.equal(s.drawPile.length, 17);
      assert.equal(s.drawPile.filter((c) => c === 'T').length, 11);
    }
  });

  it('يرفض عدد لاعبين غلط', () => {
    assert.throws(() => createGame(ids(4), 1), RuleError);
    assert.throws(() => createGame(ids(11), 1), RuleError);
  });

  it('نفس البذرة تعطي نفس اللعبة', () => {
    assert.deepEqual(createGame(ids(7), 99), createGame(ids(7), 99));
  });
});

describe('الأسرار', () => {
  it('الخائن يعرف أعوانه والزعيم، والوفي ما يعرف أحد', () => {
    const s = rigged(7, ['loyal', 'loyal', 'loyal', 'loyal', 'traitor', 'traitor', 'leader'], []);
    const traitorView = viewFor(s, 'p4');
    assert.deepEqual(traitorView.players.map((p) => p.knownRole), [null, null, null, null, 'traitor', 'traitor', 'leader']);
    const loyalView = viewFor(s, 'p0');
    assert.deepEqual(loyalView.players.map((p) => p.knownRole), ['loyal', null, null, null, null, null, null]);
  });

  it('الزعيم يعرف أعوانه بس في طاولة ٥ أو ٦', () => {
    const small = rigged(5, FIVE, []);
    assert.equal(viewFor(small, 'p4').players[3].knownRole, 'traitor');
    const big = rigged(7, ['loyal', 'loyal', 'loyal', 'loyal', 'traitor', 'traitor', 'leader'], []);
    assert.equal(viewFor(big, 'p6').players[4].knownRole, null);
  });

  it('الكروت تظهر بس للرئيس وقت الاختيار', () => {
    let s = rigged(5, FIVE, ['L', 'T', 'T', 'L', 'L', 'T']);
    s = act(s, 'p0', { type: 'nominate', chancellor: 'p1' });
    s = voteAll(s, true);
    assert.deepEqual(viewFor(s, 'p0').hand, ['L', 'T', 'T']);
    assert.deepEqual(viewFor(s, 'p1').hand, []);
    assert.deepEqual(viewFor(s, 'p2').hand, []);
  });
});

describe('الترشيح والتصويت', () => {
  it('ما ينفع ترشح نفسك أو الوزير السابق', () => {
    let s = rigged(5, FIVE, Array(17).fill('L'));
    assert.throws(() => act(s, 'p0', { type: 'nominate', chancellor: 'p0' }), RuleError);
    s = govern(s, 'p1');
    assert.equal(s.presidentId, 'p1');
    assert.ok(!eligibleChancellors(s).includes('p1'));
    // في طاولة ٥ لاعبين، الرئيس السابق مسموح.
    assert.ok(eligibleChancellors(s).includes('p0'));
  });

  it('مع أكثر من ٥ أحياء، الرئيس السابق ممنوع بعد', () => {
    let s = rigged(6, ['loyal', 'loyal', 'loyal', 'loyal', 'traitor', 'leader'], Array(17).fill('L'));
    s = govern(s, 'p2');
    assert.ok(!eligibleChancellors(s).includes('p0'));
    assert.ok(!eligibleChancellors(s).includes('p2'));
  });

  it('ما ينفع غير الرئيس يرشح، ولا تصوّت مرتين', () => {
    let s = rigged(5, FIVE, Array(17).fill('L'));
    assert.throws(() => act(s, 'p1', { type: 'nominate', chancellor: 'p2' }), RuleError);
    s = act(s, 'p0', { type: 'nominate', chancellor: 'p2' });
    s = act(s, 'p3', { type: 'vote', ja: true });
    assert.throws(() => act(s, 'p3', { type: 'vote', ja: false }), RuleError);
  });

  it('التعادل يعني رفض', () => {
    let s = rigged(6, ['loyal', 'loyal', 'loyal', 'loyal', 'traitor', 'leader'], Array(17).fill('L'));
    s = act(s, 'p0', { type: 'nominate', chancellor: 'p1' });
    s.players.forEach((p, i) => (s = act(s, p.id, { type: 'vote', ja: i < 3 })));
    assert.equal(s.phase, 'nomination');
    assert.equal(s.electionTracker, 1);
    assert.equal(s.presidentId, 'p1');
  });

  it('٣ رفضات متتالية تمرر أول قرار تلقائياً وتمسح حدود الترشيح', () => {
    let s = rigged(5, FIVE, ['T', 'L', 'L', 'L', 'L', 'L']);
    s.lastElected = { president: 'p3', chancellor: 'p4' };
    for (let i = 0; i < 3; i++) {
      s = act(s, s.presidentId, { type: 'nominate', chancellor: eligibleChancellors(s)[0] });
      s = voteAll(s, false);
    }
    assert.equal(s.traitorPolicies, 1);
    assert.equal(s.electionTracker, 0);
    assert.equal(s.lastElected, null);
    assert.equal(s.phase, 'nomination');
    assert.ok(s.log.some((e) => e.type === 'enacted' && e.chaos));
  });
});

describe('تمرير القرارات والفوز', () => {
  it('الأوفياء يفوزون بـ ٥ قرارات زرقاء', () => {
    let s = rigged(5, FIVE, Array(17).fill('L'));
    for (let i = 0; i < 5; i++) s = govern(s, eligibleChancellors(s)[0]);
    assert.equal(s.phase, 'gameOver');
    assert.equal(s.winner, 'loyal');
    assert.equal(s.winReason, 'loyalPolicies');
  });

  it('الخونة يفوزون لو انتخب الزعيم وزير بعد ٣ قرارات حمراء', () => {
    let s = rigged(7, ['loyal', 'loyal', 'loyal', 'loyal', 'traitor', 'traitor', 'leader'], Array(17).fill('L'));
    s.traitorPolicies = 3;
    s = act(s, 'p0', { type: 'nominate', chancellor: 'p6' });
    s = voteAll(s, true);
    assert.equal(s.winner, 'traitor');
    assert.equal(s.winReason, 'leaderElected');
  });

  it('طرد الزعيم يعطي الفوز للأوفياء', () => {
    let s = rigged(5, FIVE, Array(17).fill('T'));
    s.traitorPolicies = 3;
    s = govern(s, 'p1');
    assert.equal(s.phase, 'power');
    assert.equal(s.pendingPower, 'execute');
    s = act(s, 'p0', { type: 'execute', target: 'p4' });
    assert.equal(s.winner, 'loyal');
    assert.equal(s.winReason, 'leaderExecuted');
  });

  it('المطرود ما يقدر يلعب ويتخطاه الدور', () => {
    let s = rigged(5, FIVE, Array(17).fill('T'));
    s.traitorPolicies = 3;
    s = govern(s, 'p2');
    s = act(s, 'p0', { type: 'execute', target: 'p1' });
    assert.equal(s.presidentId, 'p2');
    assert.throws(() => act(s, 'p1', { type: 'vote', ja: true }), RuleError);
  });
});

describe('القدرات', () => {
  it('التلصص يكشف أول ٣ كروت للرئيس بس', () => {
    let s = rigged(5, FIVE, ['T', 'T', 'T', 'L', 'T', 'L', 'L', 'L']);
    s.traitorPolicies = 2;
    s = govern(s, 'p1');
    assert.equal(s.pendingPower, 'peek');
    assert.deepEqual(viewFor(s, 'p0').peeked, ['L', 'T', 'L']);
    assert.equal(viewFor(s, 'p1').peeked, null);
    s = act(s, 'p0', { type: 'acknowledgePeek' });
    assert.equal(s.presidentId, 'p1');
  });

  it('التحقيق يكشف الفريق للرئيس بس، وما ينعاد على نفس اللاعب', () => {
    let s = rigged(7, ['loyal', 'loyal', 'loyal', 'loyal', 'traitor', 'traitor', 'leader'], Array(17).fill('T'));
    s.traitorPolicies = 1;
    s = govern(s, 'p1');
    assert.equal(s.pendingPower, 'investigate');
    s = act(s, 'p0', { type: 'investigate', target: 'p6' });
    assert.deepEqual(viewFor(s, 'p0').yourInvestigations, [{ by: 'p0', target: 'p6', team: 'traitor' }]);
    assert.deepEqual(viewFor(s, 'p1').yourInvestigations, []);
  });

  it('الانتخاب الخاص ثم يرجع الدور لمكانه', () => {
    let s = rigged(7, ['loyal', 'loyal', 'loyal', 'loyal', 'traitor', 'traitor', 'leader'], Array(17).fill('T'));
    s.traitorPolicies = 2;
    s = govern(s, 'p1');
    assert.equal(s.pendingPower, 'specialElection');
    s = act(s, 'p0', { type: 'specialElection', target: 'p4' });
    assert.equal(s.presidentId, 'p4');
    s.traitorPolicies = 0; // نتفادى قدرة ثانية عشان نشيّك الدور بس
    s.drawPile = Array(17).fill('L');
    s = govern(s, 'p2');
    assert.equal(s.presidentId, 'p1');
  });
});

describe('البوليسات', () => {
  it('خانة الرمي ترجع لخانة السحب بنفس ترتيب الرمي (أول مرمية أول مسحوبة)', () => {
    let s = rigged(5, FIVE, ['T', 'L', 'T']);
    s.discardPile = ['L', 'T', 'L', 'T'];
    s = act(s, 'p0', { type: 'nominate', chancellor: 'p1' });
    s = voteAll(s, true);
    s = act(s, 'p0', { type: 'discard', index: 0 }); // يرمي T
    s = act(s, 'p1', { type: 'enact', index: 0 }); // يمرر L ويرمي T
    assert.equal(s.loyalPolicies, 1);
    assert.deepEqual(s.drawPile, ['L', 'T', 'L', 'T', 'T', 'T']);
    assert.deepEqual(s.discardPile, []);
  });

  it('لو باقي بوليسة أو ثنتين، المرمية تنحط تحتها', () => {
    let s = rigged(5, FIVE, ['L', 'L', 'L', 'T']);
    s.discardPile = ['T', 'T'];
    s = govern(s, 'p1');
    // سحب ٣ وبقى T وحدة، فالمرمية (القديمة ثم الجديدة) تنحط تحتها
    assert.deepEqual(s.drawPile, ['T', 'T', 'T', 'L', 'L']);
    assert.equal(viewFor(s, 'p2').discardPileCount, 0);
  });
});

describe('الفيتو', () => {
  function vetoReady(): GameState {
    let s = rigged(5, FIVE, ['T', 'T', 'T', 'L', 'L', 'L']);
    s.traitorPolicies = 5;
    s = act(s, 'p0', { type: 'nominate', chancellor: 'p1' });
    s = voteAll(s, true);
    return act(s, 'p0', { type: 'discard', index: 0 });
  }

  it('يتطلب ٥ قرارات حمراء', () => {
    let s = rigged(5, FIVE, Array(17).fill('L'));
    s = act(s, 'p0', { type: 'nominate', chancellor: 'p1' });
    s = voteAll(s, true);
    s = act(s, 'p0', { type: 'discard', index: 0 });
    assert.throws(() => act(s, 'p1', { type: 'proposeVeto' }), RuleError);
  });

  it('قبول الفيتو يرمي الكروت ويزيد العداد', () => {
    let s = vetoReady();
    s = act(s, 'p1', { type: 'proposeVeto' });
    s = act(s, 'p0', { type: 'respondVeto', accept: true });
    assert.equal(s.traitorPolicies, 5);
    assert.equal(s.electionTracker, 1);
    assert.equal(s.presidentId, 'p1');
  });

  it('رفض الفيتو يجبر الوزير يمرر', () => {
    let s = vetoReady();
    s = act(s, 'p1', { type: 'proposeVeto' });
    s = act(s, 'p0', { type: 'respondVeto', accept: false });
    assert.equal(s.phase, 'chancellorEnact');
    assert.throws(() => act(s, 'p1', { type: 'proposeVeto' }), RuleError);
    s = act(s, 'p1', { type: 'enact', index: 0 });
    assert.equal(s.winner, 'traitor');
  });
});

describe('الادعاءات', () => {
  it('الرئيس يدّعي ٣ والوزير ٢، مرة وحدة بس، ومسموح الكذب', () => {
    let s = rigged(5, FIVE, ['L', 'L', 'T', 'L', 'L', 'L']);
    s = govern(s, 'p1');
    assert.deepEqual(viewFor(s, 'p0').claimable, { office: 'president', count: 3 });
    s = act(s, 'p0', { type: 'claim', policies: ['T', 'T', 'T'] });
    assert.throws(() => act(s, 'p0', { type: 'claim', policies: ['L', 'L', 'L'] }), RuleError);
    assert.throws(() => act(s, 'p1', { type: 'claim', policies: ['L', 'L', 'L'] }), RuleError);
    s = act(s, 'p1', { type: 'claim', policies: ['L', 'T'] });
    assert.throws(() => act(s, 'p2', { type: 'claim', policies: ['L', 'T'] }), RuleError);
    const claims = s.log.filter((e) => e.type === 'claim');
    assert.equal(claims.length, 2);
  });
});

describe('لعب عشوائي', () => {
  it('ألف لعبة عشوائية تنتهي بدون أخطاء والكروت ما تضيع', () => {
    for (let g = 0; g < 1000; g++) {
      let rng = g * 7919 + 1;
      const rand = () => {
        const [v, n] = nextRandom(rng);
        rng = n;
        return v;
      };
      const pick = <T>(xs: T[]): T => xs[Math.floor(rand() * xs.length)];
      let s = createGame(ids(5 + (g % 6)), g);
      let steps = 0;
      while (s.phase !== 'gameOver') {
        assert.ok(steps++ < 2000, 'اللعبة ما انتهت');
        const cards = s.drawPile.length + s.discardPile.length + s.hand.length + s.loyalPolicies + s.traitorPolicies;
        assert.equal(cards, 17, 'عدد الكروت تغير');
        const alive = s.players.filter((p) => p.alive);
        const others = alive.filter((p) => p.id !== s.presidentId);
        switch (s.phase) {
          case 'nomination':
            s = act(s, s.presidentId, { type: 'nominate', chancellor: pick(eligibleChancellors(s)) });
            break;
          case 'election': {
            const voter = alive.find((p) => !(p.id in s.votes))!;
            s = act(s, voter.id, { type: 'vote', ja: rand() < 0.65 });
            break;
          }
          case 'presidentDiscard':
            s = act(s, s.presidentId, { type: 'discard', index: Math.floor(rand() * 3) });
            break;
          case 'chancellorEnact':
            s = !s.vetoRejectedThisRound && s.traitorPolicies >= 5 && rand() < 0.3
              ? act(s, s.nomineeId!, { type: 'proposeVeto' })
              : act(s, s.nomineeId!, { type: 'enact', index: Math.floor(rand() * 2) });
            break;
          case 'vetoResponse':
            s = act(s, s.presidentId, { type: 'respondVeto', accept: rand() < 0.5 });
            break;
          case 'power':
            if (s.pendingPower === 'peek') s = act(s, s.presidentId, { type: 'acknowledgePeek' });
            else if (s.pendingPower === 'investigate') {
              const fresh = others.filter((p) => !s.investigations.some((i) => i.target === p.id));
              s = act(s, s.presidentId, { type: 'investigate', target: pick(fresh).id });
            } else s = act(s, s.presidentId, { type: s.pendingPower!, target: pick(others).id });
            break;
        }
      }
      assert.ok(s.winner);
    }
  });
});

describe('المؤقت', () => {
  it('لو خلص الوقت في كل مرحلة، حركات السيرفر دايماً مسموحة واللعبة تنتهي', async () => {
    const { timeoutActions } = await import('../src/index.js');
    for (let g = 0; g < 300; g++) {
      let rng = g + 11;
      const rand = () => {
        const [v, n] = nextRandom(rng);
        rng = n;
        return v;
      };
      let s = createGame(ids(5 + (g % 6)), g);
      let steps = 0;
      while (s.phase !== 'gameOver') {
        assert.ok(steps++ < 3000);
        const actions = timeoutActions(s, rand);
        assert.ok(actions.length > 0, `ما فيه حركة للمرحلة ${s.phase}`);
        for (const [id, a] of actions) s = act(s, id, a);
      }
    }
  });

  it('التصويت الافتراضي رفض، وبس للي ما صوّتوا', async () => {
    const { timeoutActions } = await import('../src/index.js');
    let s = rigged(5, FIVE, Array(17).fill('L'));
    s = act(s, 'p0', { type: 'nominate', chancellor: 'p1' });
    s = act(s, 'p2', { type: 'vote', ja: true });
    const actions = timeoutActions(s, Math.random);
    assert.deepEqual(actions.map(([id]) => id), ['p0', 'p1', 'p3', 'p4']);
    assert.ok(actions.every(([, a]) => a.type === 'vote' && a.ja === false));
  });
});

describe('البوتات', () => {
  it('ألف لعبة كلها بوتات: كل حركاتهم مسموحة وكل لعبة تنتهي', async () => {
    const { botAction, botClaim, currentActors } = await import('../src/index.js');
    const wins = { loyal: 0, traitor: 0 };
    for (let g = 0; g < 1000; g++) {
      let rng = g * 31 + 7;
      const rand = () => {
        const [v, n] = nextRandom(rng);
        rng = n;
        return v;
      };
      let s = createGame(ids(5 + (g % 6)), g + 1000);
      let steps = 0;
      while (s.phase !== 'gameOver') {
        assert.ok(steps++ < 3000, 'اللعبة ما انتهت');
        const leg = s.lastLegislature;
        if (leg) {
          for (const [office, id] of [['president', leg.government.president], ['chancellor', leg.government.chancellor]] as const) {
            if (!leg.claimed.includes(id) && s.players.find((p) => p.id === id)!.alive) {
              s = act(s, id, { type: 'claim', policies: botClaim(s, id, office, rand) });
            }
          }
        }
        const [actor] = currentActors(s);
        const a = botAction(s, actor, rand);
        assert.ok(a, `البوت ما عنده حركة في ${s.phase}`);
        s = act(s, actor, a);
      }
      wins[s.winner!]++;
    }
    // بوتات متوازنة: ما فيه فريق يفوز دايماً.
    assert.ok(wins.loyal > 150 && wins.traitor > 150, `الفوز: ${JSON.stringify(wins)}`);
  });

  it('الخائن يرشح الزعيم لما يقدر يفوز فيه', async () => {
    const { botAction } = await import('../src/index.js');
    const s = rigged(7, ['traitor', 'loyal', 'loyal', 'loyal', 'loyal', 'traitor', 'leader'], Array(17).fill('L'));
    s.traitorPolicies = 3;
    assert.deepEqual(botAction(s, 'p0', Math.random), { type: 'nominate', chancellor: 'p6' });
  });

  it('الوفي يرمي الأحمر ويمرر الأزرق', async () => {
    const { botAction } = await import('../src/index.js');
    let s = rigged(5, FIVE, ['T', 'L', 'T', 'L', 'L', 'L']);
    s = act(s, 'p0', { type: 'nominate', chancellor: 'p1' });
    for (const p of s.players) s = act(s, p.id, { type: 'vote', ja: true });
    const discard = botAction(s, 'p0', () => 0.5)!;
    assert.equal(discard.type, 'discard');
    s = act(s, 'p0', discard);
    assert.ok(!s.hand.every((c) => c === 'T'), 'رمى أحمر');
    const enact = botAction(s, 'p1', () => 0.5)!;
    s = act(s, 'p1', enact);
    assert.equal(s.loyalPolicies, 1);
  });
});

describe('الأدوار الخاصة', () => {
  it('كل لعبة فيها عرّاف وحارس من الأوفياء، والعرّاف ما يعرف أحد في البداية', () => {
    for (let n = 5; n <= 10; n++) {
      const s = createGame(ids(n), n * 13);
      const seer = s.players.filter((p) => p.special === 'seer');
      const guardian = s.players.filter((p) => p.special === 'guardian');
      assert.equal(seer.length, 1);
      assert.equal(guardian.length, 1);
      assert.equal(seer[0].role, 'loyal');
      assert.equal(guardian[0].role, 'loyal');
      assert.equal(s.seerSees, null);
      assert.equal(viewFor(s, seer[0].id).seerReady, true);
    }
  });

  it('العرّاف يكشف فريق لاعب واحد بس، في أي وقت، وسراً', () => {
    let s = rigged(5, FIVE, Array(17).fill('L'));
    s.players[1].special = 'seer';
    // الزعيم يطلع له خائن (يعرف الفريق بس، مو الدور).
    const leader = s.players.find((p) => p.role === 'leader')!;
    const logBefore = s.log.length;
    s = act(s, 'p1', { type: 'seerReveal', target: leader.id });
    assert.equal(s.log.length, logBefore, 'ما ينكتب في السجل');
    const v = viewFor(s, 'p1');
    assert.equal(v.seerSees, leader.id);
    assert.equal(v.seerReady, false);
    assert.equal(v.players.find((p) => p.id === leader.id)!.knownRole, 'traitor');
    assert.equal(viewFor(s, 'p2').players.find((p) => p.id === leader.id)!.knownRole, null, 'الباقين ما يشوفون');
    assert.throws(() => act(s, 'p1', { type: 'seerReveal', target: 'p3' }), /seerUsed|استخدمت/);
    assert.throws(() => act(s, 'p2', { type: 'seerReveal', target: 'p3' }), /notSeer|العرّاف/);
  });

  it('العرّاف البوت يكشف من الجولة الثانية', () => {
    const s = rigged(5, FIVE, Array(17).fill('L'));
    s.players[1].special = 'seer';
    assert.equal(botSeerReveal(s, 'p1'), null, 'الجولة الأولى لا');
    s.round = 2;
    const t = botSeerReveal(s, 'p1');
    assert.ok(t && t !== 'p1');
    assert.equal(botSeerReveal(s, 'p2'), null, 'مو عرّاف');
  });

  it('الحارس ينجو من أول طرد وينكشف للكل، والثاني يطرده', () => {
    let s = rigged(5, FIVE, Array(17).fill('T'));
    s.players[2].special = 'guardian';
    s.traitorPolicies = 3;
    s = govern(s, 'p1');
    assert.equal(s.pendingPower, 'execute');
    s = act(s, 'p0', { type: 'execute', target: 'p2' });
    assert.ok(s.players[2].alive, 'الحارس نجا');
    assert.ok(s.log.some((e) => e.type === 'guarded'));
    assert.equal(viewFor(s, 'p3').players[2].knownSpecial, 'guardian');
    assert.equal(s.phase, 'nomination');
    // الطرد الثاني
    s.presidentId = 'p0';
    s.rotationSeat = 0;
    s.lastElected = null;
    s = govern(s, 'p1');
    s = act(s, 'p0', { type: 'execute', target: 'p2' });
    assert.ok(!s.players[2].alive);
  });
});
