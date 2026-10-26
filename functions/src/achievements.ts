import type { GameState } from '../../engine/src/index.js';
import { ACHIEVEMENTS, ACHIEVEMENT_REWARDS } from './catalog.js';
import type { Profile } from './profile.js';
import { grant } from './rewards.js';

/** إحصائيات اللاعب اللي تتقدم فيها الإنجازات (games، winsLoyal، caught…). */
export type Stats = Record<string, number>;

/**
 * وش كسب اللاعب من هاللعبة. اللي طلع قبل النهاية (أو انطرد) تنحسب له اللعبة بس،
 * عشان محد يكسب إنجازات وهو تارك اللعب للبوت.
 */
export function statsFromGame(state: GameState, uid: string, won: boolean): Stats {
  const me = state.players.find((p) => p.id === uid);
  const out: Stats = { games: 1 };
  if (!me || (state.autopilot ?? []).includes(uid)) return out;
  const roleOf = (id: string) => state.players.find((p) => p.id === id)?.role;
  const add = (k: string, n = 1) => {
    if (n > 0) out[k] = (out[k] ?? 0) + n;
  };
  if (won) {
    add(me.role === 'loyal' ? 'winsLoyal' : me.role === 'traitor' ? 'winsTraitor' : 'winsLeader');
    if (me.special === 'seer') add('seerWins');
  }
  for (const e of state.log) {
    if (e.type === 'executed' && e.by === uid && roleOf(e.target) !== 'loyal') add('caught');
    if (e.type === 'guarded' && e.target === uid) add('saved');
    if (e.type === 'enacted' && !e.chaos && e.policy === 'L' && e.government?.chancellor === uid) add('loyalLaws');
  }
  add('found', state.investigations.filter((i) => i.by === uid && i.team === 'traitor').length);
  return out;
}

/** يضيف إحصائيات اللعبة للملف، ويعطي هدية لكل درجة إنجاز جديدة (ذهب ونافذة احتفال). */
export function applyStats(p: Profile, delta: Stats, won: boolean): Profile {
  const stats: Stats = { ...p.stats };
  for (const [k, n] of Object.entries(delta)) stats[k] = (stats[k] ?? 0) + n;
  // سلسلة الفوز: تنقطع بأي خسارة (أو لو طلع من اللعبة).
  stats.streak = won ? (stats.streak ?? 0) + 1 : 0;
  stats.bestStreak = Math.max(stats.bestStreak ?? 0, stats.streak);
  let out: Profile = { ...p, stats };
  const badges = { ...p.badges };
  for (const a of ACHIEVEMENTS) {
    const value = stats[a.stat] ?? 0;
    const tier = a.tiers.filter((t) => value >= t).length;
    for (let t = (badges[a.id] ?? 0) + 1; t <= tier; t++) {
      out = grant(out, { coins: ACHIEVEMENT_REWARDS[t - 1], diamonds: 0, items: [] }, { kind: 'achievement', n: t, ach: a.id });
    }
    if (tier > (badges[a.id] ?? 0)) badges[a.id] = tier;
  }
  return { ...out, badges };
}
