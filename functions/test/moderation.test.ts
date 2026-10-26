import assert from 'node:assert/strict';
import { test } from 'node:test';
import { offensiveName } from '../src/moderation.js';

test('الأسماء المسيئة تنرفض', () => {
  for (const n of ['شرموط', 'يا شرموطة', 'كلب', 'أبو كلب', 'FUCK', 'fuuuck you', 'sh1t', 'B1tch', 'admin', 'ادمن اللعبة', 'ابن الكلب']) {
    assert.equal(offensiveName(n), true, n);
  }
});

test('الأسماء العادية تمشي', () => {
  for (const n of ['زبيدة', 'الشاذلي', 'كلباني', 'عبدالله', 'فهد', 'Assim', 'Classic', 'أبو راكان', 'Mohammed_99', 'حمارنة', 'كسرى']) {
    assert.equal(offensiveName(n), false, n);
  }
});
