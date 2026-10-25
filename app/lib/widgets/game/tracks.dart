import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../theme.dart';
import '../common.dart';
import '../ui.dart';

const powerEmoji = {Power.investigate: '🔍', Power.peek: '👁️', Power.specialElection: '🗳️', Power.execute: '🗡️'};

const powerName = {
  Power.investigate: 'تحقيق',
  Power.peek: 'تلصص',
  Power.specialElection: 'انتخاب خاص',
  Power.execute: 'طرد',
};

/// لوحة النقاط: مسار الأوفياء ومسار الخونة، كل قرار يتمرر ينختم في خانته، وتحتها عداد الفوضى والكومة.
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
        const SizedBox(height: 6),
        _Track(
          label: 'الخونة',
          filled: view.traitorPolicies,
          total: 6,
          loyal: false,
          icons: [
            for (final (i, p) in view.traitorTrackPowers.indexed) i == 5 ? '☠️' : (p == null ? null : powerEmoji[p]),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 6),
            const Text(
              '🌪️ الفوضى',
              style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            for (var i = 0; i < 3; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 14,
                height: 14,
                margin: const EdgeInsetsDirectional.only(end: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < view.electionTracker ? AppColors.gold : const Color(0xFF0E0A1E),
                  border: Border.all(
                    color: i < view.electionTracker ? AppColors.goldLight : AppColors.line,
                    width: 1.5,
                  ),
                  boxShadow: i < view.electionTracker
                      ? [BoxShadow(color: AppColors.gold.withValues(alpha: .7), blurRadius: 8)]
                      : null,
                ),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF0E0A1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                '🂠 ${arabicNumber(view.drawPileCount)} كرت',
                style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
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
    required this.loyal,
    required this.icons,
  });

  final String label;
  final int filled;
  final int total;
  final bool loyal;
  final List<String?> icons;

  @override
  Widget build(BuildContext context) {
    final main = loyal ? AppColors.loyal : AppColors.traitor;
    final light = loyal ? AppColors.loyalLight : AppColors.traitorLight;
    final dark = loyal ? AppColors.loyalDark : AppColors.traitorDark;
    return Container(
      height: 50,
      padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 8, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [dark, const Color(0xFF140F2A)],
        ),
        border: Border.all(color: main.withValues(alpha: .6), width: 1.5),
        boxShadow: [BoxShadow(color: main.withValues(alpha: .25), blurRadius: 10)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontFamily: kufi, fontSize: 12, fontWeight: FontWeight.w700, color: light),
                ),
                Text(
                  '${arabicNumber(filled)}/${arabicNumber(total)}',
                  style: const TextStyle(fontFamily: kufi, fontSize: 16, fontWeight: FontWeight.w700, height: 1.1),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // الخيط اللي يربط الخانات
                Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: main.withValues(alpha: .35), borderRadius: BorderRadius.circular(2)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < total; i++)
                      _Socket(filled: i < filled, loyal: loyal, icon: icons[i], last: i == total - 1, color: main),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// خانة دائرية: فاضية فيها رمز القدرة، أو مختومة بختم الفريق.
class _Socket extends StatelessWidget {
  const _Socket({
    required this.filled,
    required this.loyal,
    required this.icon,
    required this.last,
    required this.color,
  });

  final bool filled;
  final bool loyal;
  final String? icon;
  final bool last;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = last ? 38.0 : 34.0;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: filled ? 1 : 0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, v, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0E0A1E),
                border: Border.all(color: last ? AppColors.gold : color.withValues(alpha: .7), width: last ? 2.5 : 2),
                boxShadow: last ? [BoxShadow(color: AppColors.gold.withValues(alpha: .35), blurRadius: 8)] : null,
              ),
            ),
            if (!filled && icon != null) Text(icon!, style: TextStyle(fontSize: last ? 17 : 14)),
            if (v > 0)
              Transform.scale(
                scale: v.clamp(0, 1.25),
                child: Seal(loyal: loyal, size: size),
              ),
          ],
        ),
      ),
    );
  }
}

/// النقاط مصغرة في زاوية الشاشة. تنضغط وتطلع اللوحة كاملة.
class MiniTracks extends StatelessWidget {
  const MiniTracks({super.key, required this.view, required this.onTap});

  final GameView view;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget row(bool loyal, int filled, int total) {
      final color = loyal ? AppColors.loyal : AppColors.traitor;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '${arabicNumber(filled)}/${arabicNumber(total)}',
              style: TextStyle(
                fontFamily: kufi,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: loyal ? AppColors.loyalLight : AppColors.traitorLight,
              ),
            ),
          ),
          for (var i = 0; i < total; i++)
            Container(
              width: 13,
              height: 13,
              margin: const EdgeInsetsDirectional.only(end: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? color : const Color(0xFF0E0A1E),
                border: Border.all(color: i == total - 1 ? AppColors.gold : color.withValues(alpha: .8), width: 1.5),
                boxShadow: i < filled ? [BoxShadow(color: color.withValues(alpha: .7), blurRadius: 5)] : null,
              ),
            ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: 'لوحة النقاط',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            color: AppColors.panel.withValues(alpha: .85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withValues(alpha: .35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row(true, view.loyalPolicies, 5),
              const SizedBox(height: 4),
              row(false, view.traitorPolicies, 6),
              if (view.electionTracker > 0) ...[
                const SizedBox(height: 3),
                Text(
                  '🌪️ ${'●' * view.electionTracker}${'○' * (3 - view.electionTracker)}',
                  style: const TextStyle(fontSize: 10, color: AppColors.gold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// اللوحة كاملة: المسارات والقدرات وعداد الفوضى.
void showTracksBoard(BuildContext context, GameView view) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('لوحة النقاط', textAlign: TextAlign.center),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PolicyTracks(view: view),
            const SizedBox(height: 12),
            const Text(
              '٥ قرارات زرقا = فوز الأوفياء · ٦ حمرا = فوز الخونة\n'
              'كل قرار أحمر يعطي الرئيس قدرة: 🔍 تحقيق · 👁️ تلصص · 🗳️ انتخاب خاص · 🗡️ طرد',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.6),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تمام'))],
    ),
  );
}
