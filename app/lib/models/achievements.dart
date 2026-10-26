import 'package:flutter/material.dart';

import 'catalog.dart';

/// إنجاز: يتقدم مع إحصائية ([stat]) بعد كل لعبة، وله ٣ درجات (برونزي، فضي، ذهبي).
class Achievement {
  const Achievement(
    this.id, {
    required this.stat,
    required this.tiers,
    required this.name,
    required this.desc,
    required this.icon,
  });

  final String id;
  final String stat;
  final List<int> tiers;
  final String name;

  /// فيه {n}: الرقم المطلوب للدرجة الجاية.
  final String desc;
  final String icon;

  String descFor(int tier) => desc.replaceAll('{n}', _arabic(tiers[tier.clamp(0, tiers.length - 1)]));

  static String _arabic(int n) => n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();
}

/// أسماء الدرجات وألوانها: ١ برونزي، ٢ فضي، ٣ ذهبي.
const tierNames = ['', 'برونزي', 'فضي', 'ذهبي'];
const tierColors = [Color(0xFF6B6490), Color(0xFFCD7F32), Color(0xFFC9D1DC), Color(0xFFF2C14E)];

Achievement? achievementById(String id) => achievements.where((a) => a.id == id).firstOrNull;

/// رتبة تصنيف (برونزي، فضي، ذهبي، ماسي، أسطوري): أقل نقاط لها، ومكافأة أول وصول في الموسم.
class RankTier {
  const RankTier(
    this.index, {
    required this.id,
    required this.name,
    required this.min,
    required this.coins,
    required this.diamonds,
    required this.color,
  });

  final int index;
  final String id;
  final String name;
  final int min;
  final int coins;
  final int diamonds;
  final Color color;

  /// الرتبة لهذي النقاط.
  static RankTier of(int points) => rankTiers.lastWhere((t) => points >= t.min);

  /// الرتبة اللي بعدها (null لو أعلى رتبة).
  RankTier? get next => index + 1 < rankTiers.length ? rankTiers[index + 1] : null;
}
