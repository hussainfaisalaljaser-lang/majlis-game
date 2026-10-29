import 'package:flutter/material.dart';

import 'catalog.dart';

export 'catalog.dart';

/// كيف يتحرك الإطار: النادر ثابت ولمعة تمر كل كم ثانية، والملحمي والأسطوري يتحركون دايم.
enum FrameMotion { glint, live }

/// شكل إطار الصورة: رسمته في widgets/frames (لكل إطار رسمة ما تتكرر).
class FrameStyle {
  const FrameStyle(this.sig, {this.motion = FrameMotion.live});

  final String sig;
  final FrameMotion motion;
}

/// حركات فقاعة الكلام (widgets/fx.dart → BubblePainter).
enum BubbleFx {
  shimmer,
  glow,
  sparkle,
  flame,
  snow,
  stars,
  rainbow,
  neon,
  electric,
  sand,
  bubbles,
  steam,
  leaves,
  spin,
  smoke,
}

/// رسمة الفقاعة المصورة (widgets/design_bubbles.dart): لكل فقاعة شكلها وزخارفها وحركتها.
enum BubbleLook {
  parchment,
  gold,
  silver,
  desert,
  sea,
  ice,
  fire,
  emerald,
  night,
  coffee,
  royal,
  blood,
  neon,
  galaxy,
  rose,
  lightning,
  rainbow,
  crescent,
  lanterns,
  storm,
  starter,
  diamond,
  elite,
}

/// شكل فقاعة الكلام اللي يشوفها الكل فوق راسك.
/// [look] الرسمة المصورة؛ لو null ترسم بالألوان والحركات القديمة ([bg] و[border] و[fx]).
class BubbleStyle {
  const BubbleStyle({required this.bg, required this.border, required this.text, this.fx = const [], this.look});

  final List<Color> bg;
  final Color border;
  final Color text;
  final List<BubbleFx> fx;
  final BubbleLook? look;

  /// الرق ثابت، وباقي الرسمات تتحرك.
  bool get animated => look == null ? fx.isNotEmpty : look != BubbleLook.parchment;
}

/// خلفية الشخصيات المميزة المتحركة.
enum AvatarFx { aurora, rays, sparkle, embers, pulse, smoke, stars, bubbles }

class AvatarArt {
  const AvatarArt(this.colors, this.fx, {this.anim});

  final List<Color> colors;
  final AvatarFx fx;

  /// الشخصية نفسها تتحرك: طبقات في `assets/avatars/anim/<anim>/` (widgets/anim_avatar.dart).
  final String? anim;
}

/// شكل الكروت: ألوان الختم وإطار الكرت، والرمز (صورة في assets/icons/card_*.png).
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

/// شكل الطاولة: السجادة والصينية اللي بالنص.
class TableSkin {
  const TableSkin(this.carpet, this.tray);

  final String carpet;
  final String tray;

  static const majlis = TableSkin.of('majlis');

  const TableSkin.of(String id) : carpet = 'assets/tables/carpet_$id.webp', tray = 'assets/tables/tray_$id.webp';
}

enum ShopSlot { frame, avatar, table, cards, bubble, reactions, death }

/// افكتات الموت (widgets/death_fx.dart): تطلع على اللاعب لما ينطرد، والكل يشوفها. الافتراضي الغطا.
enum DeathFx { cloth, smoke, sand, ice, fire, lightning, ghost, gold, petals, bats }

enum Rarity {
  common('عادي', Color(0xFF9097B3)),
  rare('نادر', Color(0xFF7FB2FF)),
  epic('ملحمي', Color(0xFFC79BFF)),
  legendary('أسطوري', Color(0xFFFFC94D));

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
    this.level,
    this.champion,
    this.season,
    this.frame,
    this.bubble,
    this.death,
    this.cards,
    this.table,
    this.avatar,
    this.avatarArt,
    this.stickers,
    this.phrases = false,
    this.desc,
  });

  final String id;
  final ShopSlot slot;
  final String name;
  final Rarity rarity;
  final int? coins;
  final int? diamonds;

  /// هدية مستوى (ما ينشرى).
  final int? level;

  /// لأبطال الأسبوع (المركز).
  final int? champion;

  /// من الباتل باس.
  final String? season;

  final FrameStyle? frame;
  final BubbleStyle? bubble;
  final DeathFx? death;
  final CardSkin? cards;
  final TableSkin? table;

  /// الشخصية اللي يعطيها (assets/avatars/<الاسم>.webp).
  final String? avatar;
  final AvatarArt? avatarArt;

  /// ملصقات الباقة.
  final List<String>? stickers;

  /// باقة كلام (سوالف المجلس).
  final bool phrases;

  /// وش يسوي الغرض (تطلع في معاينة المتجر).
  final String? desc;

  bool get isDefault => coins == null && diamonds == null && level == null && champion == null && season == null;

  bool get buyable => coins != null || diamonds != null;

  /// ينلبس (إطار، كروت، طاولة، فقاعة، افكت موت)، مو شي تملكه وبس.
  bool get equippable =>
      slot == ShopSlot.frame ||
      slot == ShopSlot.cards ||
      slot == ShopSlot.table ||
      slot == ShopSlot.bubble ||
      slot == ShopSlot.death;

  /// من وين ينكسب لو ما ينشرى.
  String get source => switch (this) {
    ShopItem(level: final int l) => 'هدية مستوى $l',
    ShopItem(champion: final int c) => c == 1 ? 'لبطل الأسبوع' : (c == 2 ? 'لوصيف الأسبوع' : 'لثالث الأسبوع'),
    ShopItem(season: final String _) => 'من الباتل باس',
    _ => '',
  };
}

/// ملصق (ميم مرسوم للعبة) في assets/stickers/<المعرف>.webp.
class Sticker {
  const Sticker(this.id, this.pack, this.caption);

  final String id;
  final String pack;
  final String caption;

  String get asset => 'assets/stickers/$id.webp';
}

/// كلام سريع للطاولة. [say] فيه % مكان اسم اللاعب.
class TextReaction {
  const TextReaction(this.id, this.label, this.say, {this.target = false, this.pack, this.icon});

  final String id;
  final String label;
  final String say;
  final bool target;
  final String? pack;

  /// أيقونة صغيرة (assets/icons/gfx_<الاسم>.png).
  final String? icon;

  String text(String? name) => say.replaceAll('%', name ?? '');
}

/// مكافأة (مستوى، أو درجة في الباتل باس، أو بطولة).
class LevelReward {
  const LevelReward(this.level, {this.coins = 0, this.diamonds = 0, this.items = const []});

  final int level;
  final int coins;
  final int diamonds;
  final List<String> items;
}

/// موسم الباتل باس.
class Season {
  const Season({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.price,
    required this.fullPrice,
    required this.bonusTiers,
    required this.tierPoints,
    required this.tiers,
    required this.free,
    required this.premium,
  });

  final String id;
  final String name;
  final DateTime start;
  final DateTime end;

  /// سعر المسار المدفوع بالجواهر (ومعه [bonusTiers] درجات هدية).
  final int price;

  /// سعر الباتل باس كامل: المسار المدفوع وكل الدرجات مفتوحة على طول.
  final int fullPrice;
  final int bonusTiers;
  final int tierPoints;
  final int tiers;
  final Map<int, LevelReward> free;
  final Map<int, LevelReward> premium;

  bool get active {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  int tierFor(int points) => (points ~/ tierPoints).clamp(0, tiers);
}

final Map<String, ShopItem> _byId = {for (final i in catalog) i.id: i};

ShopItem? shopItem(String? id) => _byId[id];

/// الأغراض اللي تنشرى (للمتجر).
final shopItems = [
  for (final i in catalog)
    if (i.buyable || i.isDefault) i,
];

FrameStyle? frameStyle(String? id) => shopItem(id)?.frame;

BubbleStyle bubbleStyle(String? id) => shopItem(id)?.bubble ?? shopItem('bubble_classic')!.bubble!;

/// افكت موت اللاعب (null أو غرض مو معروف: الغطا).
DeathFx deathFxOf(String? id) => shopItem(id)?.death ?? DeathFx.cloth;

const _classicCards = CardSkin(
  loyal: [Color(0xFF5B9BFF), Color(0xFF1F4FB3)],
  traitor: [Color(0xFFF05252), Color(0xFFA32020)],
  loyalIcon: 'shield',
  traitorIcon: 'dagger',
);

CardSkin cardSkin(String? id) => shopItem(id)?.cards ?? _classicCards;

TableSkin tableSkin(String? id) => shopItem(id)?.table ?? TableSkin.majlis;

/// الشخصيات المميزة (متجر، مستويات، موسم، أبطال).
final premiumAvatars = [
  for (final i in catalog)
    if (i.avatar != null) i.avatar!,
];

final Map<String, AvatarArt> _arts = {
  for (final i in catalog)
    if (i.avatar != null) i.avatar!: i.avatarArt!,
};

/// خلفية الشخصية المتحركة (للمميزة بس).
AvatarArt? avatarArt(String avatar) => _arts[avatar];

ShopItem? avatarItem(String avatar) => shopItem('avatar_$avatar');

final Map<String, Sticker> _stickers = {for (final s in stickers) s.id: s};

Sticker? stickerById(String id) => _stickers[id];

final Map<String, TextReaction> _texts = {for (final t in textReactions) t.id: t};

TextReaction? textReaction(String id) => _texts[id];

/// باقات الجواهر (تحتاج ربط Google Play Billing قبل ما تشتغل).
const diamondPacks = [
  (diamonds: 100, price: '٤٫٩٩ ريال', bonus: ''),
  (diamonds: 550, price: '١٩٫٩٩ ريال', bonus: '+١٠٪'),
  (diamonds: 1200, price: '٣٩٫٩٩ ريال', bonus: '+٢٠٪'),
];
