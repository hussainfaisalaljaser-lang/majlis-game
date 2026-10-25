/**
 * المتجر فوق الكتالوج (catalog.ts المولّد من tools/catalog/catalog.py).
 * التطبيق عنده نفس الكتالوج مع الأشكال (app/lib/models/catalog.dart).
 */
import { CATALOG, DEFAULT_EQUIPPED, type CatalogItem, type EquipSlot, type Slot } from './catalog.js';

export { DEFAULT_EQUIPPED, type EquipSlot, type Slot };
export type Currency = 'coins' | 'diamonds';

/** غرض ينشرى بالذهب أو الجواهر. */
export interface ShopItem {
  id: string;
  slot: Slot;
  currency: Currency;
  price: number;
}

export const SHOP_ITEMS: ShopItem[] = CATALOG.flatMap((i): ShopItem[] => {
  if (i.coins !== undefined) return [{ id: i.id, slot: i.slot, currency: 'coins', price: i.coins }];
  if (i.diamonds !== undefined) return [{ id: i.id, slot: i.slot, currency: 'diamonds', price: i.diamonds }];
  return [];
});

/** الشخصية اللي يعطيها غرض الكتالوج (avatar_emir ← emir). */
export const avatarOfItem = (id: string): string => id.replace(/^avatar_/, '');

/** غرض ينشرى (مو هدية مستوى ولا للأبطال). */
export function itemById(id: unknown): ShopItem | null {
  return SHOP_ITEMS.find((i) => i.id === id) ?? null;
}

export function catalogItem(id: unknown): CatalogItem | null {
  return CATALOG.find((i) => i.id === id) ?? null;
}

export function isDefault(id: string): boolean {
  return Object.values(DEFAULT_EQUIPPED).includes(id);
}

const EQUIP_SLOTS = new Set<string>(Object.keys(DEFAULT_EQUIPPED));

/** نوع الغرض لو كان ينلبس، وإلا null. */
export function slotOf(id: string): EquipSlot | null {
  for (const [slot, def] of Object.entries(DEFAULT_EQUIPPED)) if (id === def) return slot as EquipSlot;
  const slot = catalogItem(id)?.slot;
  return slot && EQUIP_SLOTS.has(slot) ? (slot as EquipSlot) : null;
}
