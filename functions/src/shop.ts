/** المتجر: إطارات للصورة وأشكال للكروت. التطبيق عنده نسخة بالشكل والأسماء (app/lib/models/shop.dart). */

export type Slot = 'frame' | 'cards';
export type Currency = 'coins' | 'diamonds';

export interface ShopItem {
  id: string;
  slot: Slot;
  currency: Currency;
  price: number;
}

/** اللي يملكه كل لاعب من البداية. */
export const DEFAULT_EQUIPPED: Record<Slot, string> = { frame: 'frame_none', cards: 'cards_classic' };

export const SHOP_ITEMS: ShopItem[] = [
  { id: 'frame_ice', slot: 'frame', currency: 'coins', price: 3000 },
  { id: 'frame_fire', slot: 'frame', currency: 'coins', price: 8000 },
  { id: 'frame_emerald', slot: 'frame', currency: 'diamonds', price: 15 },
  { id: 'frame_king', slot: 'frame', currency: 'diamonds', price: 40 },
  { id: 'cards_oasis', slot: 'cards', currency: 'coins', price: 5000 },
  { id: 'cards_night', slot: 'cards', currency: 'coins', price: 12000 },
  { id: 'cards_dragon', slot: 'cards', currency: 'diamonds', price: 20 },
  { id: 'cards_royal', slot: 'cards', currency: 'diamonds', price: 50 },
];

export function itemById(id: unknown): ShopItem | null {
  return SHOP_ITEMS.find((i) => i.id === id) ?? null;
}

export function isDefault(id: string): boolean {
  return Object.values(DEFAULT_EQUIPPED).includes(id);
}

export function slotOf(id: string): Slot | null {
  if (id === DEFAULT_EQUIPPED.frame) return 'frame';
  if (id === DEFAULT_EQUIPPED.cards) return 'cards';
  return itemById(id)?.slot ?? null;
}
