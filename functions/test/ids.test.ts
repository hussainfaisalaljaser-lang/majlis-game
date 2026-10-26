import assert from 'node:assert/strict';
import { test } from 'node:test';
import { pidBonus, pidPrice, pidTier, randomPid, suggestPids, validPid } from '../src/ids.js';

test('الرمز: أرقام من ٣ إلى ٨ وما يبدأ بصفر', () => {
  for (const ok of ['100', '1234', '12345678']) assert.ok(validPid(ok), ok);
  for (const bad of ['12', '012345', '123456789', '12a4', '', 1234, null]) assert.ok(!validPid(bad), String(bad));
});

test('الرمز العادي: ٨ أرقام بدون نمط', () => {
  let seed = 7;
  const rand = () => ((seed = (seed * 16807) % 2147483647) - 1) / 2147483646;
  for (let i = 0; i < 2000; i++) {
    const pid = randomPid(rand);
    assert.equal(pid.length, 8);
    assert.equal(pidBonus(pid), 1, pid);
    assert.equal(pidPrice(pid), 30);
    assert.equal(pidTier(pid), 0);
  }
});

test('السعر: الأقصر والأنماط أغلى', () => {
  assert.equal(pidPrice('777'), 3000);
  assert.equal(pidPrice('100'), 2500);
  assert.equal(pidPrice('123'), 2000);
  assert.equal(pidPrice('7777'), 1500);
  assert.equal(pidPrice('4321'), 1000);
  assert.equal(pidPrice('1212'), 750);
  assert.equal(pidPrice('4829'), 500);
  assert.equal(pidPrice('55555'), 750);
  assert.equal(pidPrice('112233'), 180);
  assert.equal(pidPrice('777777'), 360);
  assert.equal(pidPrice('123321'), 160);
  assert.equal(pidPrice('12345678'), 60);
  assert.equal(pidPrice('88888888'), 90);
  assert.equal(pidPrice('25000000'), 50);
  assert.equal(pidPrice('19951212'), 30);
  assert.equal(pidTier('777'), 4);
  assert.equal(pidTier('4829'), 3);
  assert.equal(pidTier('48291'), 2);
  assert.equal(pidTier('4829173'), 1);
});

test('الاقتراحات: رموز صحيحة ومميزة', () => {
  for (let i = 0; i < 200; i++) {
    const list = suggestPids();
    assert.ok(list.length >= 8);
    for (const pid of list) {
      assert.ok(validPid(pid), pid);
      assert.ok(pidPrice(pid) > 30, pid);
    }
  }
});
