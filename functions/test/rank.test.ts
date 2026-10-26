import assert from 'node:assert/strict';
import { test } from 'node:test';
import { RANK_LOSS, RANK_TIERS, RANK_WIN, SEASON } from '../src/catalog.js';
import { newProfile, toLeaderboard, type Profile } from '../src/profile.js';
import { applyRank, rankDelta, rankOf } from '../src/rank.js';

test('النقاط حسب نسبة البشر في الطاولة', () => {
  assert.equal(rankDelta(true, 5, 5), RANK_WIN);
  assert.equal(rankDelta(false, 5, 5), -RANK_LOSS);
  assert.equal(rankDelta(true, 1, 5), Math.round(RANK_WIN / 5));
  assert.equal(rankDelta(true, 0, 5), 1, 'الفوز يعطي نقطة على الأقل');
});

test('الرتب: مكافأة أول وصول مرة وحدة، وما تنزل تحت رتبتك', () => {
  let p: Profile = newProfile();
  const silver = RANK_TIERS[1];
  p = applyRank(p, silver.min + 10);
  assert.equal(rankOf(p).points, silver.min + 10);
  assert.equal(p.gifts?.at(-1)?.kind, 'rank');
  assert.equal(p.coins, newProfile().coins + silver.coins);
  // خسارة كبيرة: يوقف عند أول نقطة في الفضي
  p = applyRank(p, -500);
  assert.equal(rankOf(p).points, silver.min);
  // يرجع يطلع: ما يعطيه مكافأة الفضي مرة ثانية
  const coins = p.coins;
  p = applyRank(p, 5);
  assert.equal(p.coins, coins);
  assert.equal(rankOf(p).best, silver.min + 10);
  assert.equal(toLeaderboard(p).rankPoints, silver.min + 5);
  assert.equal(toLeaderboard(p).rankSeason, SEASON.id);
});

test('موسم جديد يبدأ من الصفر', () => {
  const old: Profile = { ...newProfile(), rank: { season: 'old', points: 900, best: 900, rewarded: 3 } };
  assert.deepEqual(rankOf(old), { season: SEASON.id, points: 0, best: 0, rewarded: 0 });
  assert.equal(toLeaderboard(old).rankPoints, 0);
});
