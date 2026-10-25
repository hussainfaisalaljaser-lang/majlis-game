import assert from 'node:assert/strict';
import { test } from 'node:test';
import { avatarOf, equippedOf, owns, type Profile } from '../src/profile.js';
import { applyLevelRewards, claimPass, levelRewardsBetween, passTier } from '../src/rewards.js';

const base = (extra: Partial<Profile> = {}): Profile =>
  ({ name: 'x', avatar: 'falcon', setupDone: true, coins: 0, diamonds: 0, xp: 0, level: 1, vip: false,
     gamesPlayed: 0, gamesWon: 0, lastDaily: null, dailyStreak: 0, ...extra }) as Profile;

test('أغراض البطولة تخلص وترجع الأشكال القديمة', () => {
  const now = 1_000_000;
  const p = base({
    owned: ['frame_ice'],
    temp: { frame_champ1: now + 10, avatar_champ1: now + 10 },
    equipped: { frame: 'frame_champ1' },
    avatar: 'champ1',
    restore: { frame: 'frame_ice', avatar: 'sheikh' },
  });
  assert.equal(equippedOf(p, now).frame, 'frame_champ1');
  assert.equal(avatarOf(p, now), 'champ1');
  assert.ok(owns(p, 'frame_champ1', now));
  const later = now + 11;
  assert.equal(equippedOf(p, later).frame, 'frame_ice');
  assert.equal(avatarOf(p, later), 'sheikh');
  assert.ok(!owns(p, 'frame_champ1', later));
});

test('هدايا المستويات: كل ٥، وبعد ٥٠ ذهب وجواهر', () => {
  assert.deepEqual(levelRewardsBetween(1, 10).map((r) => r.level), [5, 10]);
  assert.deepEqual(levelRewardsBetween(50, 61).map((r) => r.level), [55, 60]);
  const p = applyLevelRewards(base({ level: 12 }));
  assert.equal(p.rewardedLevel, 12);
  assert.equal(p.coins, 3000);
  assert.equal(applyLevelRewards(p), p, 'ما تنعطى مرتين');
});

test('الباتل باس: الدرجات والاستلام', () => {
  assert.equal(passTier(149), 0);
  assert.equal(passTier(150 * 40), 30, 'ما يتعدى آخر درجة');
  const p = base({ pass: { season: 's1', points: 150 * 30, premium: true, free: 0, prem: 0 } });
  const { profile, got } = claimPass(p);
  assert.ok(got.items.includes('avatar_s1c') && got.items.includes('frame_s1c'));
  assert.ok(profile.owned!.includes('table_s1'));
  assert.equal(claimPass(profile).got.coins, 0);
});
