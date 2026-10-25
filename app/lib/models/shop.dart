import 'package:flutter/material.dart';

/// شكل إطار الصورة: ألوان الحلقة والتوهج.
class FrameStyle {
  const FrameStyle(this.colors, {this.glow});

  final List<Color> colors;
  final Color? glow;
}

/// شكل الكروت: ألوان كل وجه، وإطار الكرت، والرمز.
class CardSkin {
  const CardSkin({
    required this.loyal,
    required this.traitor,
    required this.loyalIcon,
    required this.traitorIcon,
    this.border,
  });

  final List<Color> loyal;
  final List<Color> traitor;
  final String loyalIcon;
  final String traitorIcon;
  final Color? border;
}

enum ShopSlot { frame, cards }

enum Rarity {
  common('عادي', Color(0xFF9097B3)),
  rare('نادر', Color(0xFF9CC4FF)),
  epic('ملحمي', Color(0xFFD4BBFF)),
  legendary('أسطوري', Color(0xFFFFD27A));

  const Rarity(this.label, this.color);
  final String label;
  final Color color;
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.slot,
    required this.name,
    required this.rarity,
    this.coins,
    this.diamonds,
    this.frame,
    this.cards,
  });

  final String id;
  final ShopSlot slot;
  final String name;
  final Rarity rarity;
  final int? coins;
  final int? diamonds;
  final FrameStyle? frame;
  final CardSkin? cards;

  bool get isDefault => coins == null && diamonds == null;
}

const _classicCards = CardSkin(
  loyal: [Color(0xFF5B9BFF), Color(0xFF1F4FB3)],
  traitor: [Color(0xFFF05252), Color(0xFFA32020)],
  loyalIcon: '🛡️',
  traitorIcon: '⚔️',
);

/// نفس functions/src/shop.ts (الأسعار والمعرفات).
const shopItems = [
  ShopItem(id: 'frame_none', slot: ShopSlot.frame, name: 'بدون إطار', rarity: Rarity.common),
  ShopItem(
    id: 'frame_ice',
    slot: ShopSlot.frame,
    name: 'جليد',
    rarity: Rarity.rare,
    coins: 3000,
    frame: FrameStyle([Color(0xFF5EE0FF), Color(0xFFB8F4FF)], glow: Color(0xFF5EE0FF)),
  ),
  ShopItem(
    id: 'frame_fire',
    slot: ShopSlot.frame,
    name: 'نار',
    rarity: Rarity.epic,
    coins: 8000,
    frame: FrameStyle([Color(0xFFFF3D00), Color(0xFFFFB300)], glow: Color(0xFFFF6D00)),
  ),
  ShopItem(
    id: 'frame_emerald',
    slot: ShopSlot.frame,
    name: 'زمرد',
    rarity: Rarity.epic,
    diamonds: 15,
    frame: FrameStyle([Color(0xFF00C853), Color(0xFF69F0AE), Color(0xFF00897B)], glow: Color(0xFF00E676)),
  ),
  ShopItem(
    id: 'frame_king',
    slot: ShopSlot.frame,
    name: 'الملك',
    rarity: Rarity.legendary,
    diamonds: 40,
    frame: FrameStyle([Color(0xFFFFD54F), Color(0xFFFF8F00), Color(0xFFFFF8E1), Color(0xFFFFB300)],
        glow: Color(0xFFFFC107)),
  ),
  ShopItem(id: 'cards_classic', slot: ShopSlot.cards, name: 'كلاسيك', rarity: Rarity.common, cards: _classicCards),
  ShopItem(
    id: 'cards_oasis',
    slot: ShopSlot.cards,
    name: 'واحة',
    rarity: Rarity.rare,
    coins: 5000,
    cards: CardSkin(
      loyal: [Color(0xFF26C6DA), Color(0xFF00695C)],
      traitor: [Color(0xFFFF8A65), Color(0xFFBF360C)],
      loyalIcon: '🌴',
      traitorIcon: '🦂',
      border: Color(0xFFFFE0B2),
    ),
  ),
  ShopItem(
    id: 'cards_night',
    slot: ShopSlot.cards,
    name: 'ليل الصحراء',
    rarity: Rarity.epic,
    coins: 12000,
    cards: CardSkin(
      loyal: [Color(0xFF3949AB), Color(0xFF0D1440)],
      traitor: [Color(0xFF8E24AA), Color(0xFF2A0636)],
      loyalIcon: '🌙',
      traitorIcon: '🐺',
      border: Color(0xFFB0BEC5),
    ),
  ),
  ShopItem(
    id: 'cards_dragon',
    slot: ShopSlot.cards,
    name: 'التنين',
    rarity: Rarity.epic,
    diamonds: 20,
    cards: CardSkin(
      loyal: [Color(0xFF00B0FF), Color(0xFF01579B)],
      traitor: [Color(0xFFD50000), Color(0xFF3E0000)],
      loyalIcon: '🐉',
      traitorIcon: '🔥',
      border: Color(0xFFFF5252),
    ),
  ),
  ShopItem(
    id: 'cards_royal',
    slot: ShopSlot.cards,
    name: 'الذهب الملكي',
    rarity: Rarity.legendary,
    diamonds: 50,
    cards: CardSkin(
      loyal: [Color(0xFF1E88E5), Color(0xFF0B2F6B)],
      traitor: [Color(0xFFE53935), Color(0xFF5B0E0E)],
      loyalIcon: '👑',
      traitorIcon: '🗡️',
      border: Color(0xFFFFD54F),
    ),
  ),
];

ShopItem? shopItem(String? id) => shopItems.where((i) => i.id == id).firstOrNull;

FrameStyle? frameStyle(String? id) => shopItem(id)?.frame;

CardSkin cardSkin(String? id) => shopItem(id)?.cards ?? _classicCards;

/// باقات الجواهر (تحتاج ربط Google Play Billing قبل ما تشتغل).
const diamondPacks = [
  (diamonds: 100, price: '٤٫٩٩ ريال', bonus: ''),
  (diamonds: 550, price: '١٩٫٩٩ ريال', bonus: '+١٠٪'),
  (diamonds: 1200, price: '٣٩٫٩٩ ريال', bonus: '+٢٠٪'),
];
