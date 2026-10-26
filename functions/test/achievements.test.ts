import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createGame, type GameState } from '../../engine/src/index.js';
import { applyStats, statsFromGame } from '../src/achievements.js';
import { newProfile, type Profile } from '../src/profile.js';

function game(): GameState {
  const s = createGame(['a', 'b', 'c', 'd', 'e'].map((id) => ({ id, name: id })), 7);
  const players = s.players.map((p, i) => ({
    ...p,
    role: (['loyal', 'loyal', 'loyal', 'traitor', 'leader'] as const)[i],
    special: i === 0 ? ('seer' as const) : null,
  }));
  return {
    ...s,
    players,
    investigations: [{ by: 'a', target: 'd', team: 'traitor' }, { by: 'a', target: 'b', team: 'loyal' }],
    log: [
      { type: 'enacted', round: 1, policy: 'L', chaos: false, government: { president: 'b', chancellor: 'a' } },
      { type: 'enacted', round: 2, policy: 'L', chaos: true },
      { type: 'executed', round: 3, by: 'a', target: 'd' },
      { type: 'executed', round: 4, by: 'a', target: 'c' },
      { type: 'guarded', round: 5, by: 'd', target: 'b' },
    ],
  };
}

test('إحصائيات اللعبة لكل لاعب', () => {
  const s = game();
  assert.deepEqual(statsFromGame(s, 'a', true), { games: 1, winsLoyal: 1, seerWins: 1, caught: 1, loyalLaws: 1, found: 1 });
  assert.deepEqual(statsFromGame(s, 'b', true), { games: 1, winsLoyal: 1, saved: 1 });
  assert.deepEqual(statsFromGame(s, 'e', false), { games: 1 });
  // اللي طلع وخلّى البوت يلعب: اللعبة بس
  assert.deepEqual(statsFromGame({ ...s, autopilot: ['a'] }, 'a', false), { games: 1 });
});

test('درجات الإنجازات والهدايا مرة وحدة، وسلسلة الفوز', () => {
  let p: Profile = { ...newProfile(), stats: { caught: 0, games: 9 } };
  p = applyStats(p, { games: 1, caught: 1 }, true);
  assert.equal(p.badges?.games, 1);
  assert.equal(p.badges?.hunter, 1);
  assert.equal(p.gifts?.length, 2);
  assert.ok(p.gifts?.every((g) => g.kind === 'achievement' && g.n === 1));
  const coins = p.coins;
  p = applyStats(p, { games: 1 }, true);
  assert.equal(p.coins, coins, 'ما تنعطى الدرجة مرتين');
  assert.equal(p.stats?.streak, 2);
  p = applyStats(p, { games: 1 }, true);
  assert.equal(p.badges?.streak, 1, '٣ فوز ورا بعض');
  p = applyStats(p, { games: 1 }, false);
  assert.equal(p.stats?.streak, 0);
  assert.equal(p.stats?.bestStreak, 3);
});
