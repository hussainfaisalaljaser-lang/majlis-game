import assert from 'node:assert/strict';
import { test } from 'node:test';
import { avatarOf, equippedOf, owns, type Profile } from '../src/profile.js';
import { applyLevelRewards, claimPass, hasVip, levelRewardsBetween, passTier, seasonWindow, upgradePass, passOf } from '../src/rewards.js';

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

test('الباتل باس العادي معه ١٠ درجات هدية، والكامل يفتح كل الدرجات (ولو عنده العادي يدفع الفرق)', async () => {
  const { upgradePass, passPrice, passComplete } = await import('../src/rewards.js');
  const { SEASON } = await import('../src/catalog.js');
  const fresh = { season: SEASON.id, points: 300, premium: false, free: 0, prem: 0 };
  const normal = upgradePass(fresh, false);
  assert.equal(normal.premium, true);
  assert.equal(passTier(normal.points), passTier(300) + SEASON.bonus_tiers);
  assert.equal(passPrice(fresh, false), SEASON.price);
  assert.equal(passPrice(fresh, true), SEASON.full_price);
  assert.equal(passPrice(normal, true), SEASON.full_price - SEASON.price, 'الفرق بس');
  assert.equal(passComplete(normal), false);
  const full = upgradePass(normal, true);
  assert.equal(passTier(full.points), SEASON.tiers);
  assert.equal(passComplete(full), true);
  // الهدية ما تعدّي آخر درجة.
  const near = upgradePass({ ...fresh, points: SEASON.tiers * SEASON.tier_points - 10 }, false);
  assert.equal(near.points, SEASON.tiers * SEASON.tier_points);
});

test('VIP: باتل الموسم الشغال المدفوع يفتحه، وبعد الموسم أو بدون شراء ينقفل', () => {
  const { start, end } = seasonWindow();
  const inSeason = start + 1000;
  const free = base();
  assert.equal(hasVip(free, inSeason), false, 'بدون باتل باس');
  const bought = base({ pass: upgradePass(passOf(free), false) });
  assert.equal(hasVip(bought, inSeason), true, 'اشترى باتل الموسم');
  assert.equal(hasVip(bought, end + 1000), false, 'الموسم خلص');
  const oldSeason = base({ pass: { ...upgradePass(passOf(free), false), season: 'old' } });
  assert.equal(hasVip(oldSeason, inSeason), false, 'اشتراه في موسم قديم وما جدد');
  assert.equal(hasVip(base({ vip: true }), end + 1000), true, 'العلامة اليدوية من المطور تبقى');
});
