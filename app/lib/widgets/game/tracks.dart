import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../theme.dart';
import '../common.dart';
import '../fx.dart';
import '../ui.dart';

/// أيقونة كل قدرة (assets/icons/gfx_*.png).
const powerIcon = {
  Power.investigate: 'search',
  Power.peek: 'eye',
  Power.specialElection: 'ballot',
  Power.execute: 'dagger',
};

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
          icons: const [null, null, null, null, 'trophy'],
        ),
        const SizedBox(height: 6),
        _Track(
          label: 'الخونة',
          filled: view.traitorPolicies,
          total: 6,
          loyal: false,
          icons: [
            for (final (i, p) in view.traitorTrackPowers.indexed) i == 5 ? 'skull' : (p == null ? null : powerIcon[p]),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 6),
            const Gfx('chaos', size: 20),
            const SizedBox(width: 3),
            const Text(
              'الفوضى',
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
                'سحب ${arabicNumber(view.drawPileCount)} · رمي ${arabicNumber(view.discardPileCount)}',
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
            if (!filled && icon != null) Gfx(icon!, size: last ? 24 : 20),
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
              // بعد ٣ قرارات للخونة: لو الزعيم صار وزير يفوزون. هنا بالزاوية (ما يغطي أحد)، وينبض وقت الترشيح والتصويت.
              if (view.traitorPolicies >= 3 && view.phase != Phase.gameOver) ...[
                const SizedBox(height: 4),
                _LeaderDanger(
                  mine: view.yourRole == Role.leader,
                  active: view.phase == Phase.nomination || view.phase == Phase.election,
                ),
              ],
              if (view.electionTracker > 0) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Gfx('chaos', size: 13),
                    const SizedBox(width: 2),
                    for (var i = 0; i < 3; i++)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsetsDirectional.only(end: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < view.electionTracker ? AppColors.gold : Colors.transparent,
                          border: Border.all(color: AppColors.gold, width: 1),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// سطر «الزعيم وزير = فوز الخونة» تحت المسار الأحمر. [active] وقت الترشيح والتصويت: ينبض عشان ينتبه له الكل.
class _LeaderDanger extends StatefulWidget {
  const _LeaderDanger({required this.mine, required this.active});

  final bool mine;
  final bool active;

  @override
  State<_LeaderDanger> createState() => _LeaderDangerState();
}

class _LeaderDangerState extends State<_LeaderDanger> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_LeaderDanger old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    if (widget.active && !FxClock.lite.value) {
      _c.repeat(reverse: true);
    } else {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Container(
      padding: const EdgeInsetsDirectional.fromSTEB(2, 1, 7, 1),
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFF3A0A12), const Color(0xFF6B111C), _c.value),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.traitor.withValues(alpha: .6 + _c.value * .4)),
        boxShadow: widget.active
            ? [BoxShadow(color: AppColors.traitor.withValues(alpha: .2 + _c.value * .4), blurRadius: 8)]
            : null,
      ),
      child: child,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LeaderSeal(size: 17),
        const SizedBox(width: 3),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: widget.mine ? 'لو صرت وزير ' : 'الزعيم وزير ',
                style: const TextStyle(color: AppColors.gold),
              ),
              const TextSpan(text: '= '),
              const TextSpan(
                text: 'فوز الخونة',
                style: TextStyle(color: Color(0xFFFF8A8A)),
              ),
            ],
          ),
          style: const TextStyle(fontFamily: kufi, fontSize: 10.5, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
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
            const SizedBox(height: 10),
            _DeckSum(view: view),
            const SizedBox(height: 10),
            const Text(
              '٥ قرارات زرقا = فوز الأوفياء · ٦ حمرا = فوز الخونة\nكل قرار أحمر يعطي الرئيس قدرة:',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.6),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                for (final p in powerIcon.keys)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Gfx(powerIcon[p]!, size: 20),
                      const SizedBox(width: 3),
                      Text(powerName[p]!, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تمام'))],
    ),
  );
}

/// وين الـ١٧ ورقة الحين: السحب + الرمي + اللي مشت على اللوحة + اللي بيد الرئيس أو الوزير.
class _DeckSum extends StatelessWidget {
  const _DeckSum({required this.view});

  final GameView view;

  static const _total = 17;

  @override
  Widget build(BuildContext context) {
    final board = view.loyalPolicies + view.traitorPolicies;
    final inHand = _total - view.drawPileCount - view.discardPileCount - board;
    Widget part(String label, int n) => Column(
      children: [
        Text(
          arabicNumber(n),
          style: const TextStyle(fontFamily: kufi, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    );
    const plus = Text('+', style: TextStyle(color: AppColors.muted, fontSize: 16));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF0E0A1E), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          part('السحب', view.drawPileCount),
          plus,
          part('الرمي', view.discardPileCount),
          plus,
          part('على اللوحة', board),
          plus,
          part('باليد', inHand),
          const Text('=', style: TextStyle(color: AppColors.muted, fontSize: 16)),
          part('كل الأوراق', _total),
        ],
      ),
    );
  }
}
