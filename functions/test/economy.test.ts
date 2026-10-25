import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { gulfDay, levelFor } from '../src/economy.js';
import { dailyClaim, newProfile } from '../src/profile.js';

const day = (iso: string) => Date.parse(iso);

describe('الهدية اليومية', () => {
  it('تتجدد الساعة ١٢ بالليل بتوقيت الخليج', () => {
    assert.equal(gulfDay(day('2026-10-24T20:59:00Z')), '2026-10-24');
    assert.equal(gulfDay(day('2026-10-24T21:00:00Z')), '2026-10-25');
  });

  it('السلسلة تزيد يوم ورا يوم، وترجع لليوم الأول بعد السابع', () => {
    const p = newProfile();
    const streaks: number[] = [];
    for (let d = 1; d <= 9; d++) {
      const r = dailyClaim(p, day(`2026-11-${String(d).padStart(2, '0')}T09:00:00Z`));
      streaks.push(r.streak);
      p.lastDaily = r.today;
      p.dailyStreak = r.streak;
    }
    assert.deepEqual(streaks, [1, 2, 3, 4, 5, 6, 7, 1, 2]);
  });

  it('اليوم السابع فيه جواهر', () => {
    const p = { ...newProfile(), lastDaily: '2026-11-06', dailyStreak: 6 };
    assert.deepEqual(dailyClaim(p, day('2026-11-07T09:00:00Z')), { coins: 1500, diamonds: 10, streak: 7, today: '2026-11-07' });
  });

  it('لو فوّت يوم ترجع السلسلة من البداية', () => {
    const p = { ...newProfile(), lastDaily: '2026-11-03', dailyStreak: 3 };
    assert.equal(dailyClaim(p, day('2026-11-05T09:00:00Z')).streak, 1);
  });

  it('ما تنفع مرتين في نفس اليوم', () => {
    const p = { ...newProfile(), lastDaily: '2026-11-05', dailyStreak: 1 };
    assert.throws(() => dailyClaim(p, day('2026-11-05T20:00:00Z')));
  });
});

describe('المستويات', () => {
  it('كل ١٠٠ خبرة مستوى', () => {
    assert.deepEqual([0, 99, 100, 950].map(levelFor), [1, 1, 2, 10]);
  });
});
