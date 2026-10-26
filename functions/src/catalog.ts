// مولّد من tools/catalog/catalog.py — لا تعدله باليد.

export type Slot = 'frame' | 'avatar' | 'table' | 'cards' | 'bubble' | 'reactions';
/** الأغراض اللي تنلبس (واحد بس من كل نوع). */
export type EquipSlot = 'frame' | 'cards' | 'table' | 'bubble';

export interface CatalogItem {
  id: string;
  slot: Slot;
  coins?: number;
  diamonds?: number;
  /** يجي هدية في هذا المستوى (ما ينشرى). */
  level?: number;
  /** لأبطال الأسبوع (المركز)، لمدة أسبوع. */
  champion?: number;
  /** من الباتل باس لهذا الموسم. */
  season?: string;
}

export const DEFAULT_EQUIPPED: Record<EquipSlot, string> = {"frame": "frame_none", "bubble": "bubble_classic", "table": "table_majlis", "cards": "cards_classic"};

export const CATALOG: CatalogItem[] = [
  {"id": "frame_ice", "slot": "frame", "coins": 3000},
  {"id": "frame_sand", "slot": "frame", "coins": 4000},
  {"id": "frame_oasis", "slot": "frame", "coins": 5000},
  {"id": "frame_pearl", "slot": "frame", "coins": 6000},
  {"id": "frame_night", "slot": "frame", "coins": 7000},
  {"id": "frame_fire", "slot": "frame", "coins": 8000},
  {"id": "frame_smoke", "slot": "frame", "coins": 9000},
  {"id": "frame_lightning", "slot": "frame", "coins": 10000},
  {"id": "frame_comet", "slot": "frame", "coins": 11000},
  {"id": "frame_neon", "slot": "frame", "coins": 12000},
  {"id": "frame_rainbow", "slot": "frame", "coins": 15000},
  {"id": "frame_emerald", "slot": "frame", "diamonds": 15},
  {"id": "frame_blood", "slot": "frame", "diamonds": 20},
  {"id": "frame_blackgold", "slot": "frame", "diamonds": 25},
  {"id": "frame_sun", "slot": "frame", "diamonds": 30},
  {"id": "frame_arabesque", "slot": "frame", "diamonds": 35},
  {"id": "frame_king", "slot": "frame", "diamonds": 40},
  {"id": "frame_galaxy", "slot": "frame", "diamonds": 45},
  {"id": "frame_lv10", "slot": "frame", "level": 10},
  {"id": "frame_lv20", "slot": "frame", "level": 20},
  {"id": "frame_lv30", "slot": "frame", "level": 30},
  {"id": "frame_lv40", "slot": "frame", "level": 40},
  {"id": "frame_lv50", "slot": "frame", "level": 50},
  {"id": "frame_s1f", "slot": "frame", "season": "s1"},
  {"id": "frame_s1a", "slot": "frame", "season": "s1"},
  {"id": "frame_s1b", "slot": "frame", "season": "s1"},
  {"id": "frame_s1c", "slot": "frame", "season": "s1"},
  {"id": "frame_champ1", "slot": "frame", "champion": 1},
  {"id": "frame_champ2", "slot": "frame", "champion": 2},
  {"id": "frame_champ3", "slot": "frame", "champion": 3},
  {"id": "bubble_gold", "slot": "bubble", "coins": 2500},
  {"id": "bubble_silver", "slot": "bubble", "coins": 3000},
  {"id": "bubble_desert", "slot": "bubble", "coins": 3500},
  {"id": "bubble_sea", "slot": "bubble", "coins": 4000},
  {"id": "bubble_coffee", "slot": "bubble", "coins": 4500},
  {"id": "bubble_night", "slot": "bubble", "coins": 6000},
  {"id": "bubble_emerald", "slot": "bubble", "coins": 7000},
  {"id": "bubble_fire", "slot": "bubble", "coins": 8000},
  {"id": "bubble_ice", "slot": "bubble", "coins": 8000},
  {"id": "bubble_neon", "slot": "bubble", "coins": 10000},
  {"id": "bubble_rose", "slot": "bubble", "coins": 12000},
  {"id": "bubble_lightning", "slot": "bubble", "diamonds": 12},
  {"id": "bubble_blood", "slot": "bubble", "diamonds": 15},
  {"id": "bubble_royal", "slot": "bubble", "diamonds": 25},
  {"id": "bubble_rainbow", "slot": "bubble", "diamonds": 30},
  {"id": "bubble_galaxy", "slot": "bubble", "diamonds": 40},
  {"id": "bubble_s1f", "slot": "bubble", "season": "s1"},
  {"id": "bubble_s1", "slot": "bubble", "season": "s1"},
  {"id": "bubble_s1b", "slot": "bubble", "season": "s1"},
  {"id": "bubble_lv5", "slot": "bubble", "level": 5},
  {"id": "bubble_lv25", "slot": "bubble", "level": 25},
  {"id": "bubble_lv45", "slot": "bubble", "level": 45},
  {"id": "avatar_detective", "slot": "avatar", "coins": 6000},
  {"id": "avatar_spy", "slot": "avatar", "coins": 6000},
  {"id": "avatar_doctor", "slot": "avatar", "coins": 6000},
  {"id": "avatar_diver", "slot": "avatar", "coins": 7000},
  {"id": "avatar_poet", "slot": "avatar", "coins": 7000},
  {"id": "avatar_camel", "slot": "avatar", "coins": 8000},
  {"id": "avatar_falconer", "slot": "avatar", "coins": 12000},
  {"id": "avatar_lady_gold", "slot": "avatar", "coins": 12000},
  {"id": "avatar_pilot", "slot": "avatar", "coins": 12000},
  {"id": "avatar_seer", "slot": "avatar", "coins": 14000},
  {"id": "avatar_knight", "slot": "avatar", "coins": 15000},
  {"id": "avatar_ghost", "slot": "avatar", "diamonds": 18},
  {"id": "avatar_assassin", "slot": "avatar", "diamonds": 20},
  {"id": "avatar_wolf", "slot": "avatar", "diamonds": 20},
  {"id": "avatar_falcon_bird", "slot": "avatar", "diamonds": 22},
  {"id": "avatar_tycoon", "slot": "avatar", "diamonds": 30},
  {"id": "avatar_emir", "slot": "avatar", "diamonds": 35},
  {"id": "avatar_sultana", "slot": "avatar", "diamonds": 35},
  {"id": "avatar_queen", "slot": "avatar", "diamonds": 40},
  {"id": "avatar_astronaut", "slot": "avatar", "diamonds": 45},
  {"id": "avatar_lv10", "slot": "avatar", "level": 10},
  {"id": "avatar_lv20", "slot": "avatar", "level": 20},
  {"id": "avatar_lv30", "slot": "avatar", "level": 30},
  {"id": "avatar_lv40", "slot": "avatar", "level": 40},
  {"id": "avatar_lv50", "slot": "avatar", "level": 50},
  {"id": "avatar_s1a", "slot": "avatar", "season": "s1"},
  {"id": "avatar_s1b", "slot": "avatar", "season": "s1"},
  {"id": "avatar_s1c", "slot": "avatar", "season": "s1"},
  {"id": "avatar_champ1", "slot": "avatar", "champion": 1},
  {"id": "avatar_champ2", "slot": "avatar", "champion": 2},
  {"id": "avatar_champ3", "slot": "avatar", "champion": 3},
  {"id": "table_sand", "slot": "table", "coins": 6000},
  {"id": "table_oasis", "slot": "table", "coins": 8000},
  {"id": "table_night", "slot": "table", "coins": 15000},
  {"id": "table_palace", "slot": "table", "diamonds": 25},
  {"id": "table_gold", "slot": "table", "diamonds": 50},
  {"id": "table_s1", "slot": "table", "season": "s1"},
  {"id": "cards_oasis", "slot": "cards", "coins": 5000},
  {"id": "cards_night", "slot": "cards", "coins": 12000},
  {"id": "cards_dragon", "slot": "cards", "diamonds": 20},
  {"id": "cards_s1", "slot": "cards", "season": "s1"},
  {"id": "cards_royal", "slot": "cards", "diamonds": 50},
  {"id": "stk_shock", "slot": "reactions", "coins": 3000},
  {"id": "stk_laugh", "slot": "reactions", "coins": 3000},
  {"id": "stk_coffee", "slot": "reactions", "coins": 3500},
  {"id": "stk_angry", "slot": "reactions", "coins": 3500},
  {"id": "stk_nervous", "slot": "reactions", "coins": 3500},
  {"id": "stk_detective", "slot": "reactions", "coins": 4000},
  {"id": "stk_innocent", "slot": "reactions", "coins": 4000},
  {"id": "stk_party", "slot": "reactions", "coins": 5000},
  {"id": "stk_traitor", "slot": "reactions", "coins": 6000},
  {"id": "stk_vip", "slot": "reactions", "diamonds": 15},
  {"id": "stk_hype", "slot": "reactions", "level": 15},
  {"id": "stk_s1", "slot": "reactions", "season": "s1"},
  {"id": "stk_legend", "slot": "reactions", "level": 35},
  {"id": "pack_phrases", "slot": "reactions", "coins": 4000},
];

/** الشخصيات المجانية (assets/avatars). الباقي من الكتالوج: avatar_<الاسم>. */
export const FREE_AVATARS = ["falcon", "sheikh", "cool", "scholar", "desert", "hawk", "merchant", "youth", "pearl", "rose", "night", "jasmine", "amber", "sky", "masked", "shadow"];

/** الردود المسموحة: target = لازم يختار لاعب، pack = لازم يملك الباقة. */
export const REACTIONS: Record<string, { target: boolean; pack?: string }> = {
  suspect: {"target": true},
  trust: {"target": true},
  liar: {"target": true},
  pick: {"target": true},
  innocent: {"target": false},
  sure: {"target": false, "pack": "pack_phrases"},
  khayin: {"target": true, "pack": "pack_phrases"},
  stab: {"target": true, "pack": "pack_phrases"},
  calm: {"target": false, "pack": "pack_phrases"},
  hurry: {"target": false, "pack": "pack_phrases"},
  trustme: {"target": false, "pack": "pack_phrases"},
  gg: {"target": false, "pack": "pack_phrases"},
  b_laugh: {"target": false},
  b_think: {"target": false},
  b_eyes: {"target": false},
  b_shh: {"target": false},
  b_smirk: {"target": false},
  b_angry: {"target": false},
  shock_jaw: {"target": false, "pack": "stk_shock"},
  shock_hands: {"target": false, "pack": "stk_shock"},
  shock_what: {"target": false, "pack": "stk_shock"},
  shock_no: {"target": false, "pack": "stk_shock"},
  shock_dizzy: {"target": false, "pack": "stk_shock"},
  shock_faint: {"target": false, "pack": "stk_shock"},
  laugh_tears: {"target": false, "pack": "stk_laugh"},
  laugh_roll: {"target": false, "pack": "stk_laugh"},
  laugh_clap: {"target": false, "pack": "stk_laugh"},
  laugh_point: {"target": false, "pack": "stk_laugh"},
  laugh_grin: {"target": false, "pack": "stk_laugh"},
  laugh_wink: {"target": false, "pack": "stk_laugh"},
  cof_cup: {"target": false, "pack": "stk_coffee"},
  cof_pour: {"target": false, "pack": "stk_coffee"},
  cof_welcome: {"target": false, "pack": "stk_coffee"},
  cof_cold: {"target": false, "pack": "stk_coffee"},
  cof_dates: {"target": false, "pack": "stk_coffee"},
  cof_enough: {"target": false, "pack": "stk_coffee"},
  ang_steam: {"target": false, "pack": "stk_angry"},
  ang_never: {"target": false, "pack": "stk_angry"},
  ang_upset: {"target": false, "pack": "stk_angry"},
  ang_bored: {"target": false, "pack": "stk_angry"},
  ang_ugh: {"target": false, "pack": "stk_angry"},
  ang_fist: {"target": false, "pack": "stk_angry"},
  nerv_sweat: {"target": false, "pack": "stk_nervous"},
  nerv_cover: {"target": false, "pack": "stk_nervous"},
  nerv_heart: {"target": false, "pack": "stk_nervous"},
  nerv_luck: {"target": false, "pack": "stk_nervous"},
  nerv_notme: {"target": false, "pack": "stk_nervous"},
  nerv_bite: {"target": false, "pack": "stk_nervous"},
  det_who: {"target": false, "pack": "stk_detective"},
  det_clue: {"target": false, "pack": "stk_detective"},
  det_watch: {"target": false, "pack": "stk_detective"},
  det_obvious: {"target": false, "pack": "stk_detective"},
  det_solved: {"target": false, "pack": "stk_detective"},
  det_hmm: {"target": false, "pack": "stk_detective"},
  inn_me: {"target": false, "pack": "stk_innocent"},
  inn_cry: {"target": false, "pack": "stk_innocent"},
  inn_trust: {"target": false, "pack": "stk_innocent"},
  inn_halo: {"target": false, "pack": "stk_innocent"},
  inn_hands: {"target": false, "pack": "stk_innocent"},
  inn_pls: {"target": false, "pack": "stk_innocent"},
  par_kafu: {"target": false, "pack": "stk_party"},
  par_won: {"target": false, "pack": "stk_party"},
  par_clap: {"target": false, "pack": "stk_party"},
  par_fireworks: {"target": false, "pack": "stk_party"},
  par_dance: {"target": false, "pack": "stk_party"},
  par_best: {"target": false, "pack": "stk_party"},
  tr_evil: {"target": false, "pack": "stk_traitor"},
  tr_dagger: {"target": false, "pack": "stk_traitor"},
  tr_poker: {"target": false, "pack": "stk_traitor"},
  tr_plan: {"target": false, "pack": "stk_traitor"},
  tr_mask: {"target": false, "pack": "stk_traitor"},
  tr_laugh: {"target": false, "pack": "stk_traitor"},
  vip_falcon: {"target": false, "pack": "stk_vip"},
  vip_bisht: {"target": false, "pack": "stk_vip"},
  vip_gg: {"target": false, "pack": "stk_vip"},
  vip_crown: {"target": false, "pack": "stk_vip"},
  vip_gold: {"target": false, "pack": "stk_vip"},
  vip_cool: {"target": false, "pack": "stk_vip"},
  hype_fire: {"target": false, "pack": "stk_hype"},
  hype_go: {"target": false, "pack": "stk_hype"},
  hype_strong: {"target": false, "pack": "stk_hype"},
  hype_100: {"target": false, "pack": "stk_hype"},
  hype_rocket: {"target": false, "pack": "stk_hype"},
  hype_eyes: {"target": false, "pack": "stk_hype"},
  s1_night: {"target": false, "pack": "stk_s1"},
  s1_champ: {"target": false, "pack": "stk_s1"},
  s1_tea: {"target": false, "pack": "stk_s1"},
  s1_lantern: {"target": false, "pack": "stk_s1"},
  s1_sleep: {"target": false, "pack": "stk_s1"},
  s1_star: {"target": false, "pack": "stk_s1"},
  leg_king: {"target": false, "pack": "stk_legend"},
  leg_genius: {"target": false, "pack": "stk_legend"},
  leg_ghost: {"target": false, "pack": "stk_legend"},
  leg_mind: {"target": false, "pack": "stk_legend"},
  leg_storm: {"target": false, "pack": "stk_legend"},
  leg_legend: {"target": false, "pack": "stk_legend"},
};

export interface Reward {
  coins: number;
  diamonds: number;
  items: string[];
}
export const LEVEL_REWARDS: (Reward & { level: number })[] = [
  {"level": 5, "coins": 1000, "diamonds": 5, "items": ["bubble_lv5"]},
  {"level": 10, "coins": 2000, "diamonds": 0, "items": ["frame_lv10", "avatar_lv10"]},
  {"level": 15, "coins": 3000, "diamonds": 10, "items": ["stk_hype"]},
  {"level": 20, "coins": 4000, "diamonds": 0, "items": ["frame_lv20", "avatar_lv20"]},
  {"level": 25, "coins": 5000, "diamonds": 15, "items": ["bubble_lv25"]},
  {"level": 30, "coins": 6000, "diamonds": 0, "items": ["frame_lv30", "avatar_lv30"]},
  {"level": 35, "coins": 7000, "diamonds": 20, "items": ["stk_legend"]},
  {"level": 40, "coins": 8000, "diamonds": 0, "items": ["frame_lv40", "avatar_lv40"]},
  {"level": 45, "coins": 9000, "diamonds": 25, "items": ["bubble_lv45"]},
  {"level": 50, "coins": 15000, "diamonds": 50, "items": ["frame_lv50", "avatar_lv50"]},
];
export const LATE_REWARD = {"every": 5, "coins": 10000, "diamonds": 20};
export const CHAMPION_REWARDS: Record<number, Reward> = {
  1: {"coins": 5000, "diamonds": 0, "items": ["frame_champ1", "avatar_champ1"]},
  2: {"coins": 3000, "diamonds": 0, "items": ["frame_champ2", "avatar_champ2"]},
  3: {"coins": 1500, "diamonds": 0, "items": ["frame_champ3", "avatar_champ3"]},
};

/** الإنجازات: الإحصائية اللي تنعد، والأرقام المطلوبة لكل درجة (برونزي، فضي، ذهبي). */
export const ACHIEVEMENTS: { id: string; stat: string; tiers: number[] }[] = [
  {"id": "games", "stat": "games", "tiers": [10, 50, 200]},
  {"id": "loyal", "stat": "winsLoyal", "tiers": [5, 25, 100]},
  {"id": "traitor", "stat": "winsTraitor", "tiers": [5, 25, 100]},
  {"id": "leader", "stat": "winsLeader", "tiers": [1, 10, 30]},
  {"id": "hunter", "stat": "caught", "tiers": [1, 10, 30]},
  {"id": "detective", "stat": "found", "tiers": [1, 10, 30]},
  {"id": "minister", "stat": "loyalLaws", "tiers": [5, 25, 100]},
  {"id": "streak", "stat": "bestStreak", "tiers": [3, 5, 10]},
  {"id": "seer", "stat": "seerWins", "tiers": [1, 5, 20]},
  {"id": "guardian", "stat": "saved", "tiers": [1, 5, 15]},
];
/** ذهب كل درجة. */
export const ACHIEVEMENT_REWARDS = [150, 400, 1000];

/** التصنيف: نقاط الفوز والخسارة، ورتب الموسم (أقل نقاط لكل رتبة ومكافأة أول وصول لها). */
export const RANK_WIN = 24;
export const RANK_LOSS = 16;
export const RANK_TIERS: { id: string; min: number; coins: number; diamonds: number }[] = [
  {"id": "bronze", "min": 0, "coins": 0, "diamonds": 0},
  {"id": "silver", "min": 200, "coins": 1500, "diamonds": 0},
  {"id": "gold", "min": 500, "coins": 3000, "diamonds": 10},
  {"id": "diamond", "min": 900, "coins": 5000, "diamonds": 25},
  {"id": "legend", "min": 1400, "coins": 10000, "diamonds": 60},
];

/** الموسم الحالي (الباتل باس). start/end بتوقيت الخليج، والمكافآت حسب الدرجة. */
export const SEASON = {"id": "s1", "start": "2026-10-25", "end": "2026-12-27", "price": 150, "tier_points": 150, "tiers": 30, "free": {"2": {"coins": 300, "diamonds": 0, "items": []}, "4": {"coins": 500, "diamonds": 0, "items": []}, "6": {"coins": 0, "diamonds": 5, "items": []}, "8": {"coins": 800, "diamonds": 0, "items": []}, "10": {"coins": 0, "diamonds": 0, "items": ["bubble_s1f"]}, "12": {"coins": 1000, "diamonds": 0, "items": []}, "14": {"coins": 0, "diamonds": 5, "items": []}, "16": {"coins": 1200, "diamonds": 0, "items": []}, "18": {"coins": 0, "diamonds": 0, "items": ["frame_s1f"]}, "20": {"coins": 1500, "diamonds": 0, "items": []}, "22": {"coins": 0, "diamonds": 10, "items": []}, "24": {"coins": 1800, "diamonds": 0, "items": []}, "26": {"coins": 0, "diamonds": 10, "items": []}, "28": {"coins": 2000, "diamonds": 0, "items": []}, "30": {"coins": 3000, "diamonds": 15, "items": []}}, "premium": {"1": {"coins": 0, "diamonds": 0, "items": ["avatar_s1a"]}, "2": {"coins": 500, "diamonds": 0, "items": []}, "3": {"coins": 1000, "diamonds": 0, "items": []}, "4": {"coins": 0, "diamonds": 5, "items": []}, "5": {"coins": 0, "diamonds": 0, "items": ["stk_s1"]}, "6": {"coins": 1000, "diamonds": 0, "items": []}, "7": {"coins": 0, "diamonds": 10, "items": []}, "8": {"coins": 1500, "diamonds": 0, "items": []}, "9": {"coins": 0, "diamonds": 0, "items": ["bubble_s1"]}, "10": {"coins": 0, "diamonds": 0, "items": ["frame_s1a"]}, "11": {"coins": 1500, "diamonds": 0, "items": []}, "12": {"coins": 0, "diamonds": 0, "items": ["cards_s1"]}, "13": {"coins": 0, "diamonds": 10, "items": []}, "14": {"coins": 2000, "diamonds": 0, "items": []}, "15": {"coins": 0, "diamonds": 0, "items": ["avatar_s1b"]}, "16": {"coins": 2000, "diamonds": 0, "items": []}, "17": {"coins": 0, "diamonds": 15, "items": []}, "18": {"coins": 0, "diamonds": 0, "items": ["table_s1"]}, "19": {"coins": 2500, "diamonds": 0, "items": []}, "20": {"coins": 0, "diamonds": 0, "items": ["frame_s1b"]}, "21": {"coins": 2500, "diamonds": 0, "items": []}, "22": {"coins": 0, "diamonds": 15, "items": []}, "23": {"coins": 3000, "diamonds": 0, "items": []}, "24": {"coins": 0, "diamonds": 0, "items": ["bubble_s1b"]}, "25": {"coins": 0, "diamonds": 20, "items": []}, "26": {"coins": 3500, "diamonds": 0, "items": []}, "27": {"coins": 4000, "diamonds": 0, "items": []}, "28": {"coins": 0, "diamonds": 25, "items": []}, "29": {"coins": 5000, "diamonds": 0, "items": []}, "30": {"coins": 0, "diamonds": 30, "items": ["avatar_s1c", "frame_s1c"]}}} as {
  id: string; start: string; end: string; price: number; tier_points: number; tiers: number;
  free: Record<string, Reward>; premium: Record<string, Reward>;
};
