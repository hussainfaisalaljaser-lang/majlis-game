/**
 * المتجر: إطارات للصورة، أشكال للكروت والطاولة، شخصيات مميزة، وباقات ردود.
 * التطبيق عنده نسخة بالشكل والأسماء (app/lib/models/shop.dart).
 */

export type Slot = 'frame' | 'cards' | 'table' | 'avatar' | 'reactions';
/** الأغراض اللي "تنلبس" (واحد بس في كل نوع). */
export type EquipSlot = 'frame' | 'cards' | 'table';
export type Currency = 'coins' | 'diamonds';

export interface ShopItem {
  id: string;
  slot: Slot;
  currency: Currency;
  price: number;
}

/** اللي يملكه كل لاعب من البداية. */
export const DEFAULT_EQUIPPED: Record<EquipSlot, string> = {
  frame: 'frame_none',
  cards: 'cards_classic',
  table: 'table_majlis',
};

export const SHOP_ITEMS: ShopItem[] = [
  { id: 'frame_ice', slot: 'frame', currency: 'coins', price: 3000 },
  { id: 'frame_fire', slot: 'frame', currency: 'coins', price: 8000 },
  { id: 'frame_lightning', slot: 'frame', currency: 'coins', price: 10000 },
  { id: 'frame_rainbow', slot: 'frame', currency: 'coins', price: 15000 },
  { id: 'frame_emerald', slot: 'frame', currency: 'diamonds', price: 15 },
  { id: 'frame_blood', slot: 'frame', currency: 'diamonds', price: 20 },
  { id: 'frame_king', slot: 'frame', currency: 'diamonds', price: 40 },
  { id: 'frame_galaxy', slot: 'frame', currency: 'diamonds', price: 45 },
  { id: 'cards_oasis', slot: 'cards', currency: 'coins', price: 5000 },
  { id: 'cards_night', slot: 'cards', currency: 'coins', price: 12000 },
  { id: 'cards_dragon', slot: 'cards', currency: 'diamonds', price: 20 },
  { id: 'cards_royal', slot: 'cards', currency: 'diamonds', price: 50 },
  { id: 'table_sand', slot: 'table', currency: 'coins', price: 6000 },
  { id: 'table_oasis', slot: 'table', currency: 'coins', price: 8000 },
  { id: 'table_night', slot: 'table', currency: 'coins', price: 15000 },
  { id: 'table_palace', slot: 'table', currency: 'diamonds', price: 25 },
  { id: 'table_gold', slot: 'table', currency: 'diamonds', price: 50 },
  { id: 'avatar_detective', slot: 'avatar', currency: 'coins', price: 6000 },
  { id: 'avatar_falconer', slot: 'avatar', currency: 'coins', price: 12000 },
  { id: 'avatar_lady_gold', slot: 'avatar', currency: 'coins', price: 12000 },
  { id: 'avatar_assassin', slot: 'avatar', currency: 'diamonds', price: 20 },
  { id: 'avatar_emir', slot: 'avatar', currency: 'diamonds', price: 35 },
  { id: 'avatar_sultana', slot: 'avatar', currency: 'diamonds', price: 35 },
  { id: 'pack_emoji', slot: 'reactions', currency: 'coins', price: 2500 },
  { id: 'pack_phrases', slot: 'reactions', currency: 'coins', price: 4000 },
  { id: 'pack_vip', slot: 'reactions', currency: 'diamonds', price: 12 },
];

/** الشخصية اللي يعطيها غرض المتجر (avatar_emir ← emir). */
export const avatarOfItem = (id: string): string => id.replace(/^avatar_/, '');

export function itemById(id: unknown): ShopItem | null {
  return SHOP_ITEMS.find((i) => i.id === id) ?? null;
}

export function isDefault(id: string): boolean {
  return Object.values(DEFAULT_EQUIPPED).includes(id);
}

/** نوع الغرض لو كان ينلبس، وإلا null. */
export function slotOf(id: string): EquipSlot | null {
  for (const [slot, def] of Object.entries(DEFAULT_EQUIPPED)) if (id === def) return slot as EquipSlot;
  const slot = itemById(id)?.slot;
  return slot === 'frame' || slot === 'cards' || slot === 'table' ? slot : null;
}
