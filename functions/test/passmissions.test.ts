import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { createGame, type GameState } from '../../engine/src/index.js';
import { bumpPassMissions, currentPassMissions, gulfWeek, passStatsFromGame } from '../src/missions.js';

const ids = (n: number) => Array.from({ length: n }, (_, i) => ({ id: `p${i}`, name: `لاعب ${i}` }));

/** لعبة خلصت بشكل معيّن (نعدّل الحالة مباشرة). */
function finished(n: number, patch: (s: GameState) => void): GameState {
  const s = createGame(ids(n), 7, { specials: false });
  s.phase = 'gameOver';
  patch(s);
  return s;
}

describe('مهام الباتل باس', () => {
  it('الفوز وأنت الزعيم بعد ما صرت وزير، والفوز في طاولة ١٠', () => {
    const s = finished(10, (g) => {
      g.winner = 'traitor';
      g.winReason = 'leaderElected';
    });
    const leader = s.players.find((p) => p.role === 'leader')!.id;
    const stats = passStatsFromGame(s, leader, true, false);
    assert.deepEqual(stats, { play: 1, win: 1, winTraitor: 1, win10: 1, leaderMinister: 1 });
    const loyal = s.players.find((p) => p.role === 'loyal')!.id;
    assert.deepEqual(passStatsFromGame(s, loyal, false, true), { play: 1, rolesGame: 1 });
  });

  it('طرد الزعيم، وقرار أزرق وأنت وزير، وكشف خاين بالتحقيق', () => {
    const s = finished(7, () => {});
    const leader = s.players.find((p) => p.role === 'leader')!.id;
    const traitor = s.players.find((p) => p.role === 'traitor')!.id;
    s.winner = 'loyal';
    s.winReason = 'leaderExecuted';
    s.log.push({ type: 'enacted', round: 1, policy: 'L', chaos: false, government: { president: 'p1', chancellor: 'p0' } });
    s.log.push({ type: 'enacted', round: 2, policy: 'L', chaos: true });
    s.log.push({ type: 'executed', round: 3, by: 'p0', target: leader });
    s.investigations = [{ by: 'p0', target: traitor, team: 'traitor' }];
    const stats = passStatsFromGame(s, 'p0', true, false);
    assert.equal(stats.killLeader, 1);
    assert.equal(stats.loyalLaw, 1, 'الفوضى ما تنحسب');
    assert.equal(stats.found, 1);
  });

  it('اللي طلع من اللعبة ولعبة الشرح ما تنحسب', () => {
    const s = finished(5, (g) => {
      g.autopilot = ['p1'];
    });
    assert.deepEqual(passStatsFromGame(s, 'p1', true, false), {});
    const tut = finished(5, (g) => {
      g.tutorial = true;
    });
    assert.deepEqual(passStatsFromGame(tut, 'p0', true, false), {});
  });

  it('الأسبوعية تتصفر كل أسبوع، والموسم كله يبقى لين يتغير الموسم', () => {
    const now = Date.parse('2026-10-27T12:00:00Z');
    let m = bumpPassMissions(undefined, 's1', now, { win: 2, play: 3 });
    m = { ...m, weeklyClaimed: ['w_win5'], seasonClaimed: ['s_play50'] };
    assert.equal(m.week, gulfWeek(now));
    const nextWeek = now + 7 * 86400_000;
    const later = currentPassMissions(m, 's1', nextWeek);
    assert.deepEqual(later.weekly, {});
    assert.deepEqual(later.weeklyClaimed, []);
    assert.deepEqual(later.total, { win: 2, play: 3 });
    assert.deepEqual(later.seasonClaimed, ['s_play50']);
    const newSeason = currentPassMissions(m, 's2', now);
    assert.deepEqual(newSeason.total, {});
  });
});
