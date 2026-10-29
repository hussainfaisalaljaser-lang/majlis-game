/**
 * شعار الديوان: شخصية مجانية (مثل «falcon»)، أو رمز من اللعبة بصيغة «sym:اسم» (تاج، درع، خنجر…).
 * الرموز نفس قائمة app/lib/models/clan.dart → clanSymbols (واختبار التطبيق يتأكد إنهم نفس بعض).
 */
import { FREE_AVATARS } from './catalog.js';

export const CLAN_SYMBOL_PREFIX = 'sym:';

export const CLAN_SYMBOLS = [
  'crown',
  'shield',
  'dagger',
  'fire',
  'eye',
  'skull',
  'scales',
  'trophy',
  'bolt',
  'card_moon',
  'card_wolf',
  'card_dragon',
];

/** شعار مسموح لديوان؟ */
export function isClanEmblem(emblem: string): boolean {
  if (FREE_AVATARS.includes(emblem)) return true;
  return emblem.startsWith(CLAN_SYMBOL_PREFIX) && CLAN_SYMBOLS.includes(emblem.slice(CLAN_SYMBOL_PREFIX.length));
}
