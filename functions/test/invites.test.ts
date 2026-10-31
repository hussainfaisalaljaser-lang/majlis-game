import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { INVITE_MAX, INVITE_NEW_REWARD, INVITE_REWARD } from '../src/economy.js';
import { canBeInvited, rewardInvited, rewardInviter } from '../src/invites.js';
import { newProfile, type Profile } from '../src/profile.js';

const DAY = 24 * 3600_000;
const now = Date.parse('2026-11-01T12:00:00Z');
/** حساب انسوى قبل [days] يوم (createdAt من Firestore يجي Timestamp). */
const made = (days: number, more: Partial<Profile> = {}): Profile => ({
  ...newProfile(),
  name: 'جديد',
  createdAt: { toMillis: () => now - days * DAY } as unknown as Profile['createdAt'],
  ...more,
});

describe('مين ينحسب مدعو', () => {
  it('حساب جديد ما لعب شي، أو لعب الشرح بس', () => {
    assert.equal(canBeInvited(made(1), now), true);
    assert.equal(canBeInvited(made(1, { gamesPlayed: 1, tutorialDone: true }), now), true);
  });

  it('لا: لعب لعبة حقيقية، أو حسابه أقدم من أسبوع، أو أحد دعاه قبل، أو ما ندري متى انسوى', () => {
    assert.equal(canBeInvited(made(1, { gamesPlayed: 1 }), now), false);
    assert.equal(canBeInvited(made(1, { gamesPlayed: 2, tutorialDone: true }), now), false);
    assert.equal(canBeInvited(made(8), now), false);
    assert.equal(canBeInvited(made(1, { invitedBy: { uid: 'a', name: 'أحمد' } }), now), false);
    assert.equal(canBeInvited(made(1, { inviteDone: true }), now), false);
    assert.equal(canBeInvited({ ...newProfile(), createdAt: undefined }, now), false);
  });
});

describe('الهدية', () => {
  it('الصاحب الجديد ياخذ هديته مرة وحدة، ويطلع له مين دعاه', () => {
    const p = made(1, { invitedBy: { uid: 'a', name: 'أحمد' } });
    const once = rewardInvited(p);
    assert.equal(once.coins, p.coins + INVITE_NEW_REWARD.coins);
    assert.equal(once.diamonds, p.diamonds + INVITE_NEW_REWARD.diamonds);
    assert.equal(once.inviteDone, true);
    assert.deepEqual(once.gifts?.at(-1), { kind: 'invite', n: 0, from: 'أحمد', ...INVITE_NEW_REWARD, items: [] });
    assert.equal(rewardInvited(once), once, 'ما تتكرر');
    const plain = made(1);
    assert.equal(rewardInvited(plain), plain, 'ما أحد دعاه: ولا شي');
  });

  it('اللي دعا ياخذ عن كل صاحب لين الحد، وبعده ما ياخذ شي', () => {
    const p = made(30, { name: 'أحمد' });
    const one = rewardInviter(p, 'جديد');
    assert.equal(one.coins, p.coins + INVITE_REWARD.coins);
    assert.equal(one.diamonds, p.diamonds + INVITE_REWARD.diamonds);
    assert.equal(one.invites, 1);
    assert.deepEqual(one.gifts?.at(-1), { kind: 'invite', n: 1, from: 'جديد', ...INVITE_REWARD, items: [] });
    const full = { ...p, invites: INVITE_MAX };
    assert.equal(rewardInviter(full, 'جديد'), full);
  });
});
