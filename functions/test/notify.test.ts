import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { applyAction, createGame } from '../../engine/src/index.js';
import { whoToNotify } from '../src/notify.js';

const players = Array.from({ length: 5 }, (_, i) => ({ id: `p${i}`, name: `لاعب ${i}` }));

describe('الإشعارات', () => {
  it('بداية اللعبة: الكل، وبدون كشف الدور', () => {
    const s = createGame(players, 1);
    const notes = whoToNotify(null, s);
    assert.equal(notes.length, 5);
    assert.ok(notes.every((n) => !/خائن|زعيم|وفي/.test(n.title + n.body)));
  });

  it('الترشيح ثم التصويت ثم الكروت: بس اللي عليه الدور', () => {
    let s = createGame(players, 1);
    const pres = s.presidentId;
    const chancellor = players.find((p) => p.id !== pres)!.id;
    let next = applyAction(s, pres, { type: 'nominate', chancellor });
    assert.equal(whoToNotify(s, next).length, 5, 'التصويت للكل');
    s = next;
    // صوت واحد ما يرسل شي
    next = applyAction(s, pres, { type: 'vote', ja: true });
    assert.deepEqual(whoToNotify(s, next), []);
    s = next;
    for (const p of players.filter((p) => p.id !== pres)) {
      const before = s;
      s = applyAction(s, p.id, { type: 'vote', ja: true });
      if (s.phase === 'presidentDiscard') {
        assert.deepEqual(whoToNotify(before, s).map((n) => n.uid), [pres]);
      }
    }
    const before = s;
    s = applyAction(s, pres, { type: 'discard', index: 0 });
    assert.deepEqual(whoToNotify(before, s).map((n) => n.uid), [chancellor]);
  });
});
