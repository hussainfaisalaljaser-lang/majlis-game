import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../theme.dart';
import '../common.dart';
import '../ui.dart';

const powerEmoji = {
  Power.investigate: '🔍',
  Power.peek: '👁️',
  Power.specialElection: '🗳️',
  Power.execute: '🗡️',
};

const powerName = {
  Power.investigate: 'تحقيق',
  Power.peek: 'تلصص',
  Power.specialElection: 'انتخاب خاص',
  Power.execute: 'طرد',
};

/// مسارات القرارات: خانات تنختم لما يتمرر قرار، وعداد الفوضى.
class PolicyTracks extends StatelessWidget {
  const PolicyTracks({super.key, required this.view});

  final GameView view;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Track(
          label: 'الأوفياء',
          filled: view.loyalPolicies,
          total: 5,
          loyal: true,
          icons: const [null, null, null, null, '🏆'],
        ),
        const SizedBox(height: 5),
        _Track(
          label: 'الخونة',
          filled: view.traitorPolicies,
          total: 6,
          loyal: false,
          icons: [
            for (final (i, p) in view.traitorTrackPowers.indexed) i == 5 ? '☠️' : (p == null ? null : powerEmoji[p]),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Text('عداد الفوضى', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(width: 8),
            for (var i = 0; i < 3; i++)
              Container(
                width: 13,
                height: 13,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < view.electionTracker ? AppColors.gold : Colors.transparent,
                  border: Border.all(color: i < view.electionTracker ? AppColors.goldLight : AppColors.line, width: 1.5),
                  boxShadow: i < view.electionTracker ? [BoxShadow(color: AppColors.gold.withValues(alpha: .6), blurRadius: 6)] : null,
                ),
              ),
            const Spacer(),
            Text('🂠 ${arabicNumber(view.drawPileCount)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.label, required this.filled, required this.total, required this.loyal, required this.icons});

  final String label;
  final int filled;
  final int total;
  final bool loyal;
  final List<String?> icons;

  @override
  Widget build(BuildContext context) {
    final main = loyal ? AppColors.loyal : AppColors.traitor;
    final light = loyal ? AppColors.loyalLight : AppColors.traitorLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [(loyal ? AppColors.loyalDark : AppColors.traitorDark).withValues(alpha: .45), Colors.transparent]),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(label, style: TextStyle(fontFamily: kufi, fontSize: 13, fontWeight: FontWeight.w700, color: light)),
          ),
          for (var i = 0; i < total; i++)
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: i < filled ? 1 : 0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, v, _) => Container(
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: i < filled ? light : main.withValues(alpha: .4), width: i < filled ? 1.5 : 1.5),
                  ),
                  child: i < filled
                      ? Transform.scale(scale: v.clamp(0, 1.2), child: Seal(loyal: loyal, size: 28))
                      : (icons[i] == null ? null : Text(icons[i]!, style: const TextStyle(fontSize: 12))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
