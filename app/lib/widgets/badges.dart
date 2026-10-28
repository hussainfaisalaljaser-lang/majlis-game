import 'package:flutter/material.dart';

import '../models/achievements.dart';
import '../models/catalog.dart';
import '../theme.dart';
import 'common.dart';

/// ميدالية إنجاز: حلقة بلون الدرجة (برونزي، فضي، ذهبي) وأيقونة الإنجاز، وتحتها نجوم بعدد الدرجة.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({super.key, required this.achievement, required this.tier, this.size = 46});

  final Achievement achievement;

  /// ٠ = ما وصلها (باهتة).
  final int tier;
  final double size;

  static const _rings = [
    [Color(0xFF8D86B8), Color(0xFF4B4378), Color(0xFF2A2350)],
    [Color(0xFFF6C49A), Color(0xFFCD7F32), Color(0xFF7A4512)],
    [Color(0xFFFFFFFF), Color(0xFFC9D1DC), Color(0xFF6E7987)],
    [Color(0xFFFFE7A3), Color(0xFFF2C14E), Color(0xFFB87A12)],
  ];

  @override
  Widget build(BuildContext context) {
    final t = tier.clamp(0, 3);
    final ring = size * .1;
    return Semantics(
      label: '${achievement.name} ${tierNames[t]}',
      child: SizedBox(
        width: size,
        height: size * 1.08,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: size,
              height: size,
              padding: EdgeInsets.all(ring),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _rings[t]),
                boxShadow: [
                  if (t == 3) BoxShadow(color: AppColors.gold.withValues(alpha: .45), blurRadius: size * .3),
                  const BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0xFF3A2C7A), Color(0xFF1A1240)]),
                ),
                child: Opacity(
                  opacity: t == 0 ? .3 : 1,
                  child: Gfx(achievement.icon, size: size * .52),
                ),
              ),
            ),
            if (t > 0)
              Positioned(
                bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < t; i++)
                      Container(
                        width: size * .17,
                        height: size * .17,
                        margin: EdgeInsets.symmetric(horizontal: size * .015),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tierColors[t],
                          border: Border.all(color: AppColors.bg, width: 1.2),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// الإنجازات اللي وصلها لاعب (الأعلى درجة أول).
class BadgeStrip extends StatelessWidget {
  const BadgeStrip({super.key, required this.badges, this.size = 40, this.max = 10});

  final Map<String, int> badges;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final earned = [
      for (final a in achievements)
        if ((badges[a.id] ?? 0) > 0) (a, badges[a.id]!),
    ]..sort((x, y) => y.$2.compareTo(x.$2));
    if (earned.isEmpty) {
      return const Text('ما عنده إنجازات للحين', style: TextStyle(color: AppColors.muted, fontSize: 12.5));
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (a, t) in earned.take(max))
          Tooltip(
            message: '${a.name} (${tierNames[t]})',
            child: BadgeMedal(achievement: a, tier: t, size: size),
          ),
      ],
    );
  }
}

/// شعار رتبة التصنيف (برونزي، فضي، ذهبي، ماسي، أسطوري).
class RankEmblem extends StatelessWidget {
  const RankEmblem({super.key, required this.tier, this.size = 40});

  final RankTier tier;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'رتبة ${tier.name}',
    child: Gfx('rank_${tier.id}', size: size),
  );
}

/// الرتبة بشعارها واسمها ونقاطها (للبطاقات والقوائم).
class RankChip extends StatelessWidget {
  const RankChip({super.key, required this.points, this.size = 22});

  final int points;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = RankTier.of(points);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 2, 10, 2),
      decoration: BoxDecoration(
        color: t.color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.color.withValues(alpha: .7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RankEmblem(tier: t, size: size),
          const SizedBox(width: 4),
          Text(
            '${t.name} (${arabicNumber(points)})',
            style: TextStyle(color: t.color, fontWeight: FontWeight.w800, fontSize: size * .58),
          ),
        ],
      ),
    );
  }
}
