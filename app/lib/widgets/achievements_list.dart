import 'package:flutter/material.dart';

import '../models/achievements.dart';
import '../models/catalog.dart';
import '../models/profile.dart';
import '../theme.dart';
import 'badges.dart';
import 'common.dart';
import 'design.dart';
import 'design_social.dart';

/// كل الإنجازات في ملفك: الدرجة اللي وصلتها، ووش باقي للدرجة الجاية.
class AchievementsPanel extends StatelessWidget {
  const AchievementsPanel({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final done = achievements.where((a) => (profile.badges[a.id] ?? 0) >= a.tiers.length).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Gfx('trophy', size: 26),
            const SizedBox(width: 8),
            const GoldTitle('الإنجازات', size: 20),
            const Spacer(),
            Text(
              '${arabicNumber(done)} من ${arabicNumber(achievements.length)} ذهبية',
              style: const TextStyle(color: socMuted, fontSize: 13, fontFamily: kufi, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'كل درجة لها ذهب: ${achievementRewards.map(arabicNumber).join(' ثم ')}، وتطلع في ملفك للكل',
          style: const TextStyle(color: socMuted, fontSize: 12.5, fontFamily: kufi, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final a in achievements) AchievementRow(achievement: a, profile: profile),
      ],
    );
  }
}

/// سطر إنجاز على لوح: الميدالية، والاسم والوصف، وشريط التقدم للدرجة الجاية.
class AchievementRow extends StatelessWidget {
  const AchievementRow({super.key, required this.achievement, required this.profile});

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
      padding: const EdgeInsets.only(bottom: 7),
      child: SocPlankRow(
        padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
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
                      Text(
                        a.name,
                        style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 16, color: socCream, height: 1.25),
                      ),
                      if (tier > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          tierNames[tier],
                          style: TextStyle(color: tierColors[tier], fontWeight: FontWeight.w800, fontSize: 13, fontFamily: kufi),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        maxed ? 'مكتمل' : '${arabicNumber(value)} / ${arabicNumber(goal)}',
                        style: TextStyle(
                          color: maxed ? socGoldHi : socMuted,
                          fontSize: 13,
                          fontFamily: kufi,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    maxed ? a.descFor(a.tiers.length - 1) : a.descFor(tier),
                    style: const TextStyle(color: socMuted, fontSize: 12.5, fontFamily: kufi, fontWeight: FontWeight.w700, height: 1.25),
                  ),
                  const SizedBox(height: 4),
                  SocBar(
                    value: progress,
                    height: 8,
                    rope: false,
                    colors: maxed
                        ? const [Color(0xFFFFE08A), Color(0xFFF0A92B)]
                        : [Color.lerp(tierColors[(tier + 1).clamp(1, 3)], Colors.white, .35)!, tierColors[(tier + 1).clamp(1, 3)]],
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

/// تصنيفك في الموسم: رتبتك ونقاطك، وكم باقي للرتبة الجاية.
class RankPanel extends StatelessWidget {
  const RankPanel({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final points = profile.rankPoints;
    final tier = RankTier.of(points);
    final next = tier.next;
    final progress = next == null ? 1.0 : ((points - tier.min) / (next.min - tier.min)).clamp(0.0, 1.0);
    final days = season.end.difference(DateTime.now()).inDays;
    final bar = next?.color ?? tier.color;
    return SocCard(
      tint: tier.color,
      gold: true,
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      child: Row(
        children: [
          RankEmblem(tier: tier, size: 62),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OutlinedText('التصنيف: ${tier.name}', size: 19, color: Color.lerp(tier.color, Colors.white, .55)!, align: TextAlign.start),
                    const Spacer(),
                    Text(
                      next == null ? '${arabicNumber(points)} نقطة' : '${arabicNumber(points)} / ${arabicNumber(next.min)}',
                      style: const TextStyle(color: socMuted, fontSize: 13, fontFamily: kufi, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SocBar(value: progress, height: 10, rope: false, colors: [Color.lerp(bar, Colors.white, .4)!, bar]),
                const SizedBox(height: 5),
                Text(
                  next == null
                      ? 'أعلى رتبة! يتصفّر التصنيف بعد ${arabicNumber(days < 0 ? 0 : days)} يوم مع نهاية الموسم'
                      : 'الفوز في الطاولات العامة يرفعك. الرتبة الجاية ${next.name} (+${arabicNumber(next.coins)} ذهب). '
                            'يتصفّر بعد ${arabicNumber(days < 0 ? 0 : days)} يوم',
                  style: const TextStyle(color: socMuted, fontSize: 12.5, fontFamily: kufi, fontWeight: FontWeight.w700, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
