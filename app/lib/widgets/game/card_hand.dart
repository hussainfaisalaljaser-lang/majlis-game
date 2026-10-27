import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/shop.dart';
import '../../theme.dart';
import '../fx.dart';
import '../ui.dart';
import 'game_table.dart';
import 'policy_card.dart';

/// وش يصير للكرت اللي تختاره من يدك.
enum HandTarget {
  /// الرئيس يرميه بالمجمرة.
  burn,

  /// الوزير يمرره بالختم.
  stamp,
}

/// كروتك بيدك: تطلع من تحت وتنفتح مروحة. اسحب الكرت لنص الطاولة (أو اضغطه): الرئيس يرميه
/// بالمجمرة ويحترق، والوزير يمرره بالختم. بدون [onPick] الكروت للعرض بس (كشف أول ٣ كروت).
class CardHand extends StatefulWidget {
  const CardHand({
    super.key,
    required this.cards,
    required this.hint,
    this.skin,
    this.onPick,
    this.verb = '',
    this.target = HandTarget.burn,
    this.extra,
  });

  final List<Policy> cards;
  final String hint;
  final CardSkin? skin;
  final ValueChanged<int>? onPick;

  /// الكلمة اللي قبل اسم الكرت (للقارئ والاختبارات): ارمِ كرت ١ خونة.
  final String verb;
  final HandTarget target;

  /// تحت الكروت (طلب الفيتو أو زر تمام).
  final Widget? extra;

  @override
  State<CardHand> createState() => _CardHandState();
}

class _CardHandState extends State<CardHand> with TickerProviderStateMixin {
  late final _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  late final _back = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  late final _use = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));

  /// الكرت اللي تسحبه الحين ومكانه.
  int? _drag;
  Offset _at = Offset.zero;

  /// الكرت اللي رجع لمكانه، ومن وين رجع.
  int? _returning;
  Offset _returnFrom = Offset.zero;

  /// الكرت اللي اخترته (يروح للمجمرة أو الختم)، ومن وين راح.
  int? _used;
  Offset _usedFrom = Offset.zero;

  @override
  void dispose() {
    _enter.dispose();
    _back.dispose();
    _use.dispose();
    super.dispose();
  }

  void _pick(int i, Offset from) {
    if (_used != null || widget.onPick == null) return;
    setState(() {
      _used = i;
      _usedFrom = from;
      _drag = null;
    });
    // الحركة تخلص وبعدها نرسلها (تاخذ نص ثانية بس).
    _use.forward(from: 0).then((_) {
      if (mounted) widget.onPick!(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        final target = _target(size);
        final n = widget.cards.length;
        final cardW = _cardW(size);
        final cardH = cardW * 1.45;
        final zone = _zone(size);
        Offset rest(int i) {
          final k = i - (n - 1) / 2;
          return Offset(size.width / 2 + k * (cardW + 16), size.height - cardH * .5 - 12 + k.abs() * 8);
        }

        double restAngle(int i) => (i - (n - 1) / 2) * .16;
        final heat = _drag == null ? 0.0 : (1 - ((_at - target).distance - zone) / (zone * 2.5)).clamp(0.0, 1.0);
        return AnimatedBuilder(
          animation: Listenable.merge([_enter, _back, _use]),
          builder: (context, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(color: Colors.black.withValues(alpha: .38 * _enter.value)),
                ),
              ),
              if (widget.onPick != null)
                Positioned(
                  left: target.dx - zone,
                  top: target.dy - zone,
                  width: zone * 2,
                  height: zone * 2,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: _enter.value,
                      child: widget.target == HandTarget.burn
                          ? _Brazier(heat: math.max(heat, _used == null ? 0 : _use.value))
                          : _SealZone(heat: math.max(heat, _used == null ? 0 : _use.value)),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: tablePadding.top + 4,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _enter.value,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.panel.withValues(alpha: .92),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.gold.withValues(alpha: .6), width: 1.5),
                        ),
                        child: Text(
                          widget.hint,
                          style: const TextStyle(fontFamily: kufi, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < n; i++)
                if (i != _drag && i != _used) _card(i, rest(i), restAngle(i), cardW, cardH),
              // اللي بيدك فوق الباقين.
              if (_drag case final i?) _card(i, _at, 0, cardW, cardH, lifted: true),
              if (_used case final i?) _usedCard(i, target, cardW, cardH),
              if (widget.extra case final extra?)
                Positioned(
                  bottom: 4,
                  left: size.width / 2 + (n / 2) * (cardW + 16) + 8,
                  child: Opacity(opacity: _enter.value, child: extra),
                ),
            ],
          ),
        );
      },
    );
  }

  /// المجمرة أو الختم: فوق نص الطاولة شوي، عشان ما تغطيها الكروت.
  static Offset _target(Size size) =>
      Offset(size.width / 2, tablePadding.top + (size.height - tablePadding.vertical) * .42);

  static double _cardW(Size size) => math.min(90.0, size.height * .22);

  static double _zone(Size size) => _cardW(size) * .78;

  /// كرت بمكانه بالمروحة (أو بيدك وأنت تسحبه).
  Widget _card(int i, Offset at, double angle, double w, double h, {bool lifted = false}) {
    final policy = widget.cards[i];
    // تطلع من تحت ورا بعض وتنفتح.
    final e = Curves.easeOutBack.transform(
      ((_enter.value - i * .12) / (1 - (widget.cards.length - 1) * .12)).clamp(0.0, 1.0),
    );
    var pos = Offset(at.dx, at.dy + (1 - e) * (h + 40));
    if (i == _returning && _back.isAnimating) {
      pos = Offset.lerp(_returnFrom, at, Curves.easeOut.transform(_back.value))!;
    }
    final pickable = widget.onPick != null && _used == null;
    Widget card = PolicyCard(
      policy: policy,
      skin: widget.skin,
      width: w,
      highlight: lifted,
      label: '${widget.verb} كرت ${i + 1} ${policy == Policy.loyal ? 'أوفياء' : 'خونة'}',
      onTap: pickable ? () => _pick(i, at) : null,
    );
    if (pickable) {
      card = GestureDetector(
        onPanStart: (_) => setState(() {
          _drag = i;
          _at = at;
        }),
        onPanUpdate: (d) => setState(() => _at += d.delta),
        onPanEnd: (_) => _drop(i, at),
        onPanCancel: () => _drop(i, at),
        child: card,
      );
    }
    return Positioned(
      left: pos.dx - w / 2,
      top: pos.dy - h / 2,
      width: w,
      height: h,
      child: Transform.rotate(
        angle: angle * e,
        child: Transform.scale(scale: lifted ? 1.08 : 1, child: card),
      ),
    );
  }

  /// تركت الكرت: لو فوق المجمرة أو الختم ينختار، وإلا يرجع لمكانه.
  void _drop(int i, Offset home) {
    if (_drag != i) return;
    final box = context.size;
    if (box == null) return;
    if ((_at - _target(box)).distance < _zone(box) * 1.2) return _pick(i, _at);
    setState(() {
      _drag = null;
      _returning = i;
      _returnFrom = _at;
    });
    _back.forward(from: 0);
  }

  /// الكرت المختار: يطير لنص الطاولة ويصغر. بالمجمرة يحمر ويحترق، وبالختم ينختم ويلمع.
  Widget _usedCard(int i, Offset target, double w, double h) {
    final p = _use.value;
    final fly = Curves.easeInCubic.transform((p / .55).clamp(0.0, 1.0));
    final pos = Offset.lerp(_usedFrom, target, fly)!;
    final burn = widget.target == HandTarget.burn;
    final end = ((p - .55) / .45).clamp(0.0, 1.0);
    final scale = burn ? (1 - .45 * fly) * (1 - .8 * end) : 1 - .35 * fly;
    return Positioned(
      left: pos.dx - w / 2,
      top: pos.dy - h / 2,
      width: w,
      height: h,
      child: IgnorePointer(
        child: Opacity(
          opacity: burn ? 1 - end : 1,
          child: Transform.scale(
            scale: scale,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                burn
                    ? const Color(0xFFFF6A00).withValues(alpha: .85 * end)
                    : Colors.white.withValues(alpha: .6 * math.sin(end * math.pi)),
                BlendMode.srcATop,
              ),
              child: PolicyCard(policy: widget.cards[i], skin: widget.skin, width: w),
            ),
          ),
        ),
      ),
    );
  }
}

/// المجمرة: تولع أكثر لما يقرب الكرت ([heat] ٠–١).
class _Brazier extends StatelessWidget {
  const _Brazier({required this.heat});

  final double heat;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(
        child: RepaintBoundary(
          child: FxClock(
            builder: (context, time) => CustomPaint(size: Size.infinite, painter: _BrazierPainter(time, heat)),
          ),
        ),
      ),
      const _ZoneLabel('ارمِ هنا'),
    ],
  );
}

class _BrazierPainter extends CustomPainter {
  _BrazierPainter(this.time, this.heat) : super(repaint: time);

  final ValueListenable<double> time;
  final double heat;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final s = size.height / 110;
    canvas.translate(size.width / 2, size.height * .62);
    canvas.scale(s);
    canvas.drawCircle(
      const Offset(0, -12),
      62,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF8A1F).withValues(alpha: .25 + .5 * heat),
            const Color(0x00FF8A1F),
          ],
        ).createShader(Rect.fromCircle(center: const Offset(0, -12), radius: 62)),
    );
    for (var k = 0; k < 5; k++) {
      final q = (t * (1.6 + heat) + k / 5) % 1;
      final x = (k - 2) * 9 + math.sin(t * 6 + k) * 3;
      final h = (16 + 30 * heat) * (1 - q * .4);
      canvas.drawPath(
        Path()
          ..moveTo(x - 7, -6)
          ..quadraticBezierTo(x - 4, -6 - h * .6, x, -6 - h)
          ..quadraticBezierTo(x + 4, -6 - h * .6, x + 7, -6)
          ..close(),
        Paint()..color = Color.lerp(const Color(0xFFFFD166), const Color(0xFFFF4D00), q)!.withValues(alpha: .85),
      );
    }
    final bowl = Path()
      ..moveTo(-40, -8)
      ..quadraticBezierTo(0, 36, 40, -8)
      ..close();
    canvas.drawPath(
      bowl,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8A5A00), Color(0xFFD4A017), Color(0xFF6B4300)])
            .createShader(const Rect.fromLTWH(-40, -8, 80, 32)),
    );
    canvas.drawOval(const Rect.fromLTWH(-40, -14, 80, 12), Paint()..color = const Color(0xFF3B1A0A));
    canvas.drawOval(
      const Rect.fromLTWH(-33, -12, 66, 8),
      Paint()..color = Color.lerp(const Color(0xFF7A2E0A), const Color(0xFFFF8A1F), heat)!,
    );
    canvas.drawRect(const Rect.fromLTWH(-5, 14, 10, 16), Paint()..color = const Color(0xFF6B4300));
    canvas.drawOval(const Rect.fromLTWH(-22, 26, 44, 10), Paint()..color = const Color(0xFF8A5A00));
  }

  @override
  bool shouldRepaint(_BrazierPainter old) => old.heat != heat || old.time != time;
}

/// مكان الختم (الوزير يمرر الكرت هنا): حلقة ذهبية تضوي لما يقرب الكرت.
class _SealZone extends StatelessWidget {
  const _SealZone({required this.heat});

  final double heat;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(
        child: FractionallySizedBox(
          widthFactor: .78,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xCC0B0818),
                border: Border.all(color: Color.lerp(AppColors.gold, Colors.white, heat)!, width: 3 + 2 * heat),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: .3 + .5 * heat),
                    blurRadius: 14 + 20 * heat,
                  ),
                ],
              ),
              child: const FractionallySizedBox(
                widthFactor: .5,
                heightFactor: .5,
                child: FittedBox(child: GameIcon('scroll', color: AppColors.gold)),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      const _ZoneLabel('مرّر هنا'),
    ],
  );
}

class _ZoneLabel extends StatelessWidget {
  const _ZoneLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: const Color(0xD90B0818), borderRadius: BorderRadius.circular(10)),
    child: Text(
      text,
      style: const TextStyle(fontFamily: kufi, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.goldLight),
    ),
  );
}
