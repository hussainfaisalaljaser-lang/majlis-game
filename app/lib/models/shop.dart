import 'package:flutter/material.dart';

/// حركة الإطار: ثابت، يدور، ينبض، أو يدور وحوله لمعات.
enum FrameFx { none, spin, pulse, sparkle }

/// شكل إطار الصورة: ألوان الحلقة والتوهج والحركة.
class FrameStyle {
  const FrameStyle(this.colors, {this.glow, this.fx = FrameFx.none});

  final List<Color> colors;
  final Color? glow;
  final FrameFx fx;
}

/// شكل الطاولة: السجادة والصينية اللي بالنص.
class TableSkin {
  const TableSkin(this.carpet, this.tray);

  final String carpet;
  final String tray;

  static const majlis = TableSkin('assets/images/carpet_wide.png', 'assets/images/tray_wide.png');

  const TableSkin.of(String id) : carpet = 'assets/tables/carpet_$id.webp', tray = 'assets/tables/tray_$id.webp';
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

enum ShopSlot { frame, cards, table, avatar, reactions }

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
    this.table,
    this.avatar,
    this.preview,
  });

  final String id;
  final ShopSlot slot;
  final String name;
  final Rarity rarity;
  final int? coins;
  final int? diamonds;
  final FrameStyle? frame;
  final CardSkin? cards;
  final TableSkin? table;

  /// الشخصية اللي يعطيها (للشخصيات المميزة).
  final String? avatar;

  /// عينة من ردود الباقة.
  final String? preview;

  /// ينلبس (إطار، كروت، طاولة)، مو شي تملكه وبس.
  bool get equippable => slot == ShopSlot.frame || slot == ShopSlot.cards || slot == ShopSlot.table;

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
    frame: FrameStyle([Color(0xFFFF3D00), Color(0xFFFFB300)], glow: Color(0xFFFF6D00), fx: FrameFx.pulse),
  ),
  ShopItem(
    id: 'frame_lightning',
    slot: ShopSlot.frame,
    name: 'برق',
    rarity: Rarity.epic,
    coins: 10000,
    frame: FrameStyle(
      [Color(0xFF2979FF), Color(0xFFFFFFFF), Color(0xFF7C4DFF), Color(0xFF00E5FF)],
      glow: Color(0xFF448AFF),
      fx: FrameFx.spin,
    ),
  ),
  ShopItem(
    id: 'frame_rainbow',
    slot: ShopSlot.frame,
    name: 'قوس قزح',
    rarity: Rarity.epic,
    coins: 15000,
    frame: FrameStyle(
      [Color(0xFFFF1744), Color(0xFFFFEA00), Color(0xFF00E676), Color(0xFF00B0FF), Color(0xFFD500F9)],
      glow: Color(0xFFFFFFFF),
      fx: FrameFx.spin,
    ),
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
    id: 'frame_blood',
    slot: ShopSlot.frame,
    name: 'دم الخونة',
    rarity: Rarity.epic,
    diamonds: 20,
    frame: FrameStyle(
      [Color(0xFFB71C1C), Color(0xFF1A0000), Color(0xFFFF1744)],
      glow: Color(0xFFFF1744),
      fx: FrameFx.pulse,
    ),
  ),
  ShopItem(
    id: 'frame_king',
    slot: ShopSlot.frame,
    name: 'الملك',
    rarity: Rarity.legendary,
    diamonds: 40,
    frame: FrameStyle(
      [Color(0xFFFFD54F), Color(0xFFFF8F00), Color(0xFFFFF8E1), Color(0xFFFFB300)],
      glow: Color(0xFFFFC107),
      fx: FrameFx.sparkle,
    ),
  ),
  ShopItem(
    id: 'frame_galaxy',
    slot: ShopSlot.frame,
    name: 'مجرة',
    rarity: Rarity.legendary,
    diamonds: 45,
    frame: FrameStyle(
      [Color(0xFF7C4DFF), Color(0xFFFF4081), Color(0xFF18FFFF), Color(0xFF311B92)],
      glow: Color(0xFFB388FF),
      fx: FrameFx.sparkle,
    ),
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
  ShopItem(id: 'table_majlis', slot: ShopSlot.table, name: 'المجلس', rarity: Rarity.common, table: TableSkin.majlis),
  ShopItem(
    id: 'table_sand',
    slot: ShopSlot.table,
    name: 'رمال',
    rarity: Rarity.rare,
    coins: 6000,
    table: TableSkin.of('sand'),
  ),
  ShopItem(
    id: 'table_oasis',
    slot: ShopSlot.table,
    name: 'واحة',
    rarity: Rarity.rare,
    coins: 8000,
    table: TableSkin.of('oasis'),
  ),
  ShopItem(
    id: 'table_night',
    slot: ShopSlot.table,
    name: 'ليل نجد',
    rarity: Rarity.epic,
    coins: 15000,
    table: TableSkin.of('night'),
  ),
  ShopItem(
    id: 'table_palace',
    slot: ShopSlot.table,
    name: 'القصر',
    rarity: Rarity.epic,
    diamonds: 25,
    table: TableSkin.of('palace'),
  ),
  ShopItem(
    id: 'table_gold',
    slot: ShopSlot.table,
    name: 'الذهب الأسود',
    rarity: Rarity.legendary,
    diamonds: 50,
    table: TableSkin.of('gold'),
  ),
  ShopItem(
    id: 'avatar_detective',
    slot: ShopSlot.avatar,
    name: 'المحقق',
    rarity: Rarity.rare,
    coins: 6000,
    avatar: 'detective',
  ),
  ShopItem(
    id: 'avatar_falconer',
    slot: ShopSlot.avatar,
    name: 'الصقّار',
    rarity: Rarity.epic,
    coins: 12000,
    avatar: 'falconer',
  ),
  ShopItem(
    id: 'avatar_lady_gold',
    slot: ShopSlot.avatar,
    name: 'الأميرة',
    rarity: Rarity.epic,
    coins: 12000,
    avatar: 'lady_gold',
  ),
  ShopItem(
    id: 'avatar_assassin',
    slot: ShopSlot.avatar,
    name: 'الملثّم',
    rarity: Rarity.epic,
    diamonds: 20,
    avatar: 'assassin',
  ),
  ShopItem(
    id: 'avatar_emir',
    slot: ShopSlot.avatar,
    name: 'الأمير',
    rarity: Rarity.legendary,
    diamonds: 35,
    avatar: 'emir',
  ),
  ShopItem(
    id: 'avatar_sultana',
    slot: ShopSlot.avatar,
    name: 'السلطانة',
    rarity: Rarity.legendary,
    diamonds: 35,
    avatar: 'sultana',
  ),
  ShopItem(
    id: 'pack_emoji',
    slot: ShopSlot.reactions,
    name: 'إيموجي زيادة',
    rarity: Rarity.rare,
    coins: 2500,
    preview: '🔥 💀 🤡 😱',
  ),
  ShopItem(
    id: 'pack_phrases',
    slot: ShopSlot.reactions,
    name: 'سوالف المجلس',
    rarity: Rarity.epic,
    coins: 4000,
    preview: 'متأكد ١٠٠٪\nفلان خاين!',
  ),
  ShopItem(
    id: 'pack_vip',
    slot: ShopSlot.reactions,
    name: 'الفخامة',
    rarity: Rarity.legendary,
    diamonds: 12,
    preview: '🗡️ طعنني!\n🍿 ☕ 🦅',
  ),
];

ShopItem? shopItem(String? id) => shopItems.where((i) => i.id == id).firstOrNull;

FrameStyle? frameStyle(String? id) => shopItem(id)?.frame;

CardSkin cardSkin(String? id) => shopItem(id)?.cards ?? _classicCards;

TableSkin tableSkin(String? id) => shopItem(id)?.table ?? TableSkin.majlis;

/// الشخصيات المميزة من المتجر (نفس functions/src/profile.ts → PREMIUM_AVATARS).
final premiumAvatars = [
  for (final i in shopItems)
    if (i.avatar != null) i.avatar!,
];

/// باقات الجواهر (تحتاج ربط Google Play Billing قبل ما تشتغل).
const diamondPacks = [
  (diamonds: 100, price: '٤٫٩٩ ريال', bonus: ''),
  (diamonds: 550, price: '١٩٫٩٩ ريال', bonus: '+١٠٪'),
  (diamonds: 1200, price: '٣٩٫٩٩ ريال', bonus: '+٢٠٪'),
];
