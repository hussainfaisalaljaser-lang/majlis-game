/**
 * هدية الدعوة: لاعب جديد دعاه صاحب (رابط الدعوة فيه رمز اللي أرسله، أو دخل روم صاحبه الخاص). لما يخلّص
 * أول لعبة حقيقية (مو لعبة الشرح، وما طلع منها) ياخذ هدية، واللي دعاه ياخذ هدية عن كل صاحب لين INVITE_MAX.
 */
import { INVITE_MAX, INVITE_NEW_REWARD, INVITE_REWARD, INVITE_WINDOW_MS } from './economy.js';
import type { Profile } from './profile.js';
import { grant } from './rewards.js';

/** متى انسوى الحساب (ملي ثانية)، و٠ لو ما ندري (الحسابات القديمة جداً). */
function createdMs(p: Profile): number {
  const at = p.createdAt as unknown as { toMillis?: () => number } | undefined;
  return typeof at?.toMillis === 'function' ? at.toMillis() : 0;
}

/** يقدر ينحسب مدعو: حسابه جديد، وما لعب ولا لعبة حقيقية (لعبة الشرح ما تنحسب)، وما أحد دعاه قبل. */
export function canBeInvited(p: Profile, now: number): boolean {
  if (p.invitedBy || p.inviteDone) return false;
  const created = createdMs(p);
  const realGames = p.gamesPlayed - (p.tutorialDone ? 1 : 0);
  return created > 0 && now - created < INVITE_WINDOW_MS && realGames <= 0;
}

/** خلّص أول لعبة حقيقية وفيه أحد دعاه، وما أخذ هديته. */
export function invitePending(p: Profile | null): p is Profile & { invitedBy: { uid: string; name: string } } {
  return !!p?.invitedBy && !p.inviteDone;
}

/** هدية الصاحب الجديد (مرة وحدة). */
export function rewardInvited(p: Profile): Profile {
  if (!invitePending(p)) return p;
  return grant(
    { ...p, inviteDone: true },
    { ...INVITE_NEW_REWARD, items: [] },
    { kind: 'invite', n: 0, from: p.invitedBy.name },
  );
}

/** هدية اللي دعا صاحبه [friend] (لين INVITE_MAX صاحب). */
export function rewardInviter(p: Profile, friend: string): Profile {
  const count = p.invites ?? 0;
  if (count >= INVITE_MAX) return p;
  return grant(
    { ...p, invites: count + 1 },
    { ...INVITE_REWARD, items: [] },
    { kind: 'invite', n: 1, from: friend },
  );
}
