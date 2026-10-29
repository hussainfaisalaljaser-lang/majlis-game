import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../theme.dart';
import '../common.dart';
import '../design_game.dart';
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
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 6),
            const Gfx('chaos', size: 22),
            const SizedBox(width: 3),
            const Text(
              'الفوضى',
              style: TextStyle(color: Color(0xFFF1DDBB), fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            for (var i = 0; i < 3; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 16,
                height: 16,
                margin: const EdgeInsetsDirectional.only(end: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < view.electionTracker ? AppColors.gold : const Color(0xFF2B190E),
                  border: Border.all(
                    color: i < view.electionTracker ? AppColors.goldLight : const Color(0xFF8A5E3B),
                    width: 2,
                  ),
                  boxShadow: i < view.electionTracker
                      ? [BoxShadow(color: AppColors.gold.withValues(alpha: .7), blurRadius: 8)]
                      : null,
                ),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF241209).withValues(alpha: .9),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                'سحب ${arabicNumber(view.drawPileCount)}، رمي ${arabicNumber(view.discardPileCount)}',
                style: const TextStyle(color: Color(0xFFFFF3DA), fontSize: 12.5, fontWeight: FontWeight.w800),
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
    final main = loyal ? const Color(0xFF4B8CF5) : const Color(0xFFE0485A);
    final light = loyal ? AppColors.loyalLight : AppColors.traitorLight;
    return GameHudPlank(
      radius: 14,
      padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 8, 4),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: kufi,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: light,
                    height: 1.2,
                  ),
                ),
                Text(
                  '${arabicNumber(filled)}/${arabicNumber(total)}',
                  style: const TextStyle(
                    fontFamily: kufi,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: Color(0xFFFFF3DA),
                  ),
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
    final size = last ? 40.0 : 36.0;
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
                color: const Color(0xFF1E120B),
                border: Border.all(color: last ? AppColors.gold : color, width: last ? 3 : 2.4),
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

/// النقاط مصغرة في زاوية الشاشة على لوح خشب (دوائر زرقا وحمرا). تنضغط وتطلع اللوحة كاملة.
/// [scale] مقياس الواجهة (١ = حجم التصميم).
class MiniTracks extends StatelessWidget {
  const MiniTracks({super.key, required this.view, required this.onTap, this.scale = 1});

  final GameView view;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final sc = scale;
    final dot = math.max(10.0, 23 * sc);
    final fs = math.max(12.0, 22 * sc);
    Widget row(bool loyal, int filled, int total) {
      final color = loyal ? const Color(0xFF3F78E0) : const Color(0xFFE0485A);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: fs * 2.6,
            child: Text(
              '${arabicNumber(filled)}/${arabicNumber(total)}',
              style: TextStyle(
                fontFamily: kufi,
                fontSize: fs,
                fontWeight: FontWeight.w800,
                color: loyal ? const Color(0xFF8FB4FF) : const Color(0xFFFF9FB0),
                height: 1.25,
              ),
            ),
          ),
          for (var i = 0; i < total; i++)
            Container(
              width: dot,
              height: dot,
              margin: EdgeInsetsDirectional.only(end: math.max(3.0, 6 * sc)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? null : const Color(0xFF1E120B).withValues(alpha: .35),
                gradient: i < filled
                    ? RadialGradient(
                        center: const Alignment(-.3, -.4),
                        colors: [Color.lerp(color, Colors.white, .5)!, color, Color.lerp(color, Colors.black, .35)!],
                        stops: const [0, .5, 1],
                      )
                    : null,
                border: Border.all(
                  color: i == total - 1 ? const Color(0xFFF2C14E) : color,
                  width: math.max(1.6, 2.6 * sc),
                ),
                boxShadow: i < filled ? [BoxShadow(color: color.withValues(alpha: .6), blurRadius: 5)] : null,
              ),
            ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: 'لوحة النقاط',
      excludeSemantics: true,
      child: GameHudPlank(
        onTap: onTap,
        radius: 14 * sc + 2,
        padding: EdgeInsets.fromLTRB(10 * sc, 4 * sc, 8 * sc, 4 * sc),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row(true, view.loyalPolicies, 5),
            SizedBox(height: 2 * sc),
            row(false, view.traitorPolicies, 6),
            // بعد ٣ قرارات للخونة: لو الزعيم صار وزير يفوزون. هنا بالزاوية (ما يغطي أحد)، وينبض وقت الترشيح والتصويت.
            if (view.traitorPolicies >= 3 && view.phase != Phase.gameOver) ...[
              SizedBox(height: 4 * sc),
              _LeaderDanger(
                mine: view.yourRole == Role.leader,
                active: view.phase == Phase.nomination || view.phase == Phase.election,
              ),
            ],
            if (view.electionTracker > 0) ...[
              SizedBox(height: 3 * sc),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Gfx('chaos', size: math.max(13.0, 20 * sc)),
                  const SizedBox(width: 2),
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsetsDirectional.only(end: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < view.electionTracker ? AppColors.gold : Colors.transparent,
                        border: Border.all(color: AppColors.gold, width: 1.4),
                      ),
                    ),
                ],
              ),
            ],
          ],
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
      padding: const EdgeInsetsDirectional.fromSTEB(2, 1, 8, 1),
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFF4A1018), const Color(0xFF7A1420), _c.value),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.traitor.withValues(alpha: .6 + _c.value * .4), width: 1.6),
        boxShadow: widget.active
            ? [BoxShadow(color: AppColors.traitor.withValues(alpha: .2 + _c.value * .4), blurRadius: 8)]
            : null,
      ),
      child: child,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LeaderSeal(size: 18),
        const SizedBox(width: 3),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: widget.mine ? 'لو صرت وزير ' : 'الزعيم وزير ',
                style: const TextStyle(color: AppColors.goldLight),
              ),
              const TextSpan(
                text: '= ',
                style: TextStyle(color: Color(0xFFFFF3DA)),
              ),
              const TextSpan(
                text: 'فوز الخونة',
                style: TextStyle(color: Color(0xFFFF9A9A)),
              ),
            ],
          ),
          style: const TextStyle(fontFamily: kufi, fontSize: 11, fontWeight: FontWeight.w800, height: 1.3),
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
        child: SingleChildScrollView(
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
                style: TextStyle(color: Color(0xFFF1DDBB), fontSize: 12.5, height: 1.6, fontWeight: FontWeight.w700),
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
                        Gfx(powerIcon[p]!, size: 22),
                        const SizedBox(width: 3),
                        Text(
                          powerName[p]!,
                          style: const TextStyle(color: Color(0xFFFFF3DA), fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [GameButton(label: 'تمام', height: 44, fontSize: 16, onPressed: () => Navigator.pop(context))],
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
          style: const TextStyle(fontFamily: kufi, fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFFFFF3DA)),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFE2CBA4), fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
    const plus = Text('+', style: TextStyle(color: Color(0xFFE2CBA4), fontSize: 16));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF241209).withValues(alpha: .85),
        borderRadius: BorderRadius.circular(14),
      ),
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
          const Text('=', style: TextStyle(color: Color(0xFFE2CBA4), fontSize: 16)),
          part('كل الأوراق', _total),
        ],
      ),
    );
  }
}
