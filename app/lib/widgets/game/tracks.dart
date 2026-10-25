import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../theme.dart';
import '../common.dart';

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

/// مسارات القرارات وعداد الفوضى.
class PolicyTracks extends StatelessWidget {
  const PolicyTracks({super.key, required this.view});

  final GameView view;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Track(
          label: '🔵 الأوفياء',
          filled: view.loyalPolicies,
          total: 5,
          color: AppColors.loyal,
          icons: const [null, null, null, null, '🏆'],
        ),
        const SizedBox(height: 6),
        _Track(
          label: '🔴 الخونة',
          filled: view.traitorPolicies,
          total: 6,
          color: AppColors.traitor,
          icons: [
            for (final (i, p) in view.traitorTrackPowers.indexed) i == 5 ? '☠️' : (p == null ? null : powerEmoji[p]),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Text('عداد الفوضى', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(width: 8),
            for (var i = 0; i < 3; i++)
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < view.electionTracker ? AppColors.gold : Colors.transparent,
                  border: Border.all(color: i < view.electionTracker ? AppColors.gold : AppColors.line, width: 1.5),
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
  const _Track({
    required this.label,
    required this.filled,
    required this.total,
    required this.color,
    required this.icons,
  });

  final String label;
  final int filled;
  final int total;
  final Color color;
  final List<String?> icons;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 74, child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12.5))),
        for (var i = 0; i < total; i++)
          Expanded(
            child: Container(
              height: 26,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i < filled ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: i < filled ? color : AppColors.line, width: 1.5),
              ),
              child: icons[i] == null || i < filled
                  ? null
                  : Text(icons[i]!, style: const TextStyle(fontSize: 12)),
            ),
          ),
      ],
    );
  }
}
