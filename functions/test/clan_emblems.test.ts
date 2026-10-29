import assert from 'node:assert/strict';
import { test } from 'node:test';
import { CLAN_SYMBOLS, isClanEmblem } from '../src/clan_emblems.js';

test('شعار الديوان: الشخصية المجانية أو رمز من القائمة بس', () => {
  assert.equal(isClanEmblem('falcon'), true, 'شخصية مجانية');
  assert.equal(isClanEmblem('sym:crown'), true, 'رمز مسموح');
  for (const s of CLAN_SYMBOLS) assert.equal(isClanEmblem(`sym:${s}`), true, s);
  assert.equal(isClanEmblem('crown'), false, 'الرمز لازم يبدأ بـ sym:');
  assert.equal(isClanEmblem('sym:hacker'), false, 'رمز مو في القائمة');
  assert.equal(isClanEmblem('sym:'), false);
  assert.equal(isClanEmblem(''), false);
  assert.equal(isClanEmblem('emir'), false, 'شخصية مو مجانية');
});
