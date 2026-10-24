import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  RuleError,
  applyAction,
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
  s.players.forEach((p, i) => (p.role = roles[i]));
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

/** حكومة كاملة: ترشيح، تصويت بالموافقة، الرئيس يرمي أول كرت، المستشار يمرر أول كرت. */
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
  it('ما ينفع ترشح نفسك أو المستشار السابق', () => {
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

  it('الخونة يفوزون لو انتخب الزعيم مستشار بعد ٣ قرارات حمراء', () => {
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

  it('رفض الفيتو يجبر المستشار يمرر', () => {
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
  it('الرئيس يدّعي ٣ والمستشار ٢، مرة وحدة بس، ومسموح الكذب', () => {
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
