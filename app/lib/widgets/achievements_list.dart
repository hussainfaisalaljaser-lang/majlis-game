import 'package:flutter/material.dart';

import '../models/achievements.dart';
import '../models/catalog.dart';
import '../models/profile.dart';
import '../theme.dart';
import 'badges.dart';
import 'common.dart';
import 'ui.dart';

/// كل الإنجازات في ملفك: الدرجة اللي وصلتها، ووش باقي للدرجة الجاية.
class AchievementsPanel extends StatelessWidget {
  const AchievementsPanel({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final done = achievements.where((a) => (profile.badges[a.id] ?? 0) >= a.tiers.length).length;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Gfx('trophy', size: 24),
              const SizedBox(width: 6),
              const Text(
                'الإنجازات',
                style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const Spacer(),
              Text(
                '${arabicNumber(done)} من ${arabicNumber(achievements.length)} ذهبية',
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'كل درجة لها ذهب: ${achievementRewards.map(arabicNumber).join(' ثم ')}، وتطلع في ملفك للكل',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          for (final a in achievements) _AchievementRow(achievement: a, profile: profile),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement, required this.profile});

  final Achievement achievement;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final tier = (profile.badges[a.id] ?? 0).clamp(0, a.tiers.length);
    final value = profile.stats[a.stat] ?? 0;
    final maxed = tier >= a.tiers.length;
    final goal = maxed ? a.tiers.last : a.tiers[tier];
    final from = tier == 0 ? 0 : a.tiers[tier - 1];
    final progress = maxed ? 1.0 : ((value - from) / (goal - from)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          BadgeMedal(achievement: a, tier: tier, size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(a.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                    if (tier > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        tierNames[tier],
                        style: TextStyle(color: tierColors[tier], fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      maxed ? 'مكتمل' : '${arabicNumber(value)} / ${arabicNumber(goal)}',
                      style: TextStyle(
                        color: maxed ? AppColors.gold : AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  maxed ? a.descFor(a.tiers.length - 1) : a.descFor(tier),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.black.withValues(alpha: .35),
                    color: maxed ? AppColors.gold : tierColors[(tier + 1).clamp(1, 3)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
