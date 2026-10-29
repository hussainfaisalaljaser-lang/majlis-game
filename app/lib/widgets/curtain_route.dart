import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/sounds.dart';
import 'fx.dart';

/// صفحة تنفتح بستارة المسرح: تنسدل على الصفحة اللي قبلها، وتنفتح على الجديدة (والرجوع بنفس الطريقة).
/// بدل القفزة المفاجئة بين الشاشات. مع «حركات خفيفة» تصير تلاشي عادي.
Route<T> curtainRoute<T>(WidgetBuilder builder, {RouteSettings? settings}) => PageRouteBuilder<T>(
  settings: settings,
  transitionDuration: const Duration(milliseconds: 900),
  reverseTransitionDuration: const Duration(milliseconds: 760),
  pageBuilder: (context, _, _) => builder(context),
  transitionsBuilder: (context, animation, _, child) => CurtainTransition(animation: animation, child: child),
);

/// أول نص الحركة: الستارة مسدلة بالكامل والصفحة مخفية، وبعدها تنفتح. مع صوت قماش وضربة خفيفة.
class CurtainTransition extends StatefulWidget {
  const CurtainTransition({super.key, required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<CurtainTransition> createState() => _CurtainTransitionState();
}

class _CurtainTransitionState extends State<CurtainTransition> {
  late double _prev = widget.animation.value;

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_tick);
    widget.animation.addStatusListener(_status);
    if (widget.animation.status == AnimationStatus.forward) Sounds.play('whoosh', volume: .7);
  }

  @override
  void dispose() {
    widget.animation.removeListener(_tick);
    widget.animation.removeStatusListener(_status);
    super.dispose();
  }

  void _status(AnimationStatus s) {
    if (s == AnimationStatus.reverse) Sounds.play('whoosh', volume: .7);
  }

  void _tick() {
    final v = widget.animation.value;
    if ((_prev < .5 && v >= .5) || (_prev > .5 && v <= .5)) {
      Sounds.play('thud_red', volume: .5);
      Sounds.play('whoosh', volume: .6);
    }
    _prev = v;
  }

  @override
  Widget build(BuildContext context) {
    if (FxClock.lite.value) return FadeTransition(opacity: widget.animation, child: widget.child);
    return AnimatedBuilder(
      animation: widget.animation,
      child: widget.child,
      builder: (context, child) {
        final v = widget.animation.value;
        final shown = v >= .5;
        final closed = Curves.easeInOut.transform(1 - (2 * v - 1).abs());
        return Stack(
          fit: StackFit.expand,
          children: [
            // الصفحة تنبني من أول لحظة (عشان ما تتأخر) بس ما تبان إلا لما تنسدل الستارة كاملة
            IgnorePointer(
              ignoring: !shown,
              child: Opacity(opacity: shown ? 1 : 0, child: child),
            ),
            if (closed > 0) IgnorePointer(child: CustomPaint(painter: CurtainPainter(closed))),
          ],
        );
      },
    );
  }
}

/// ستارة مخمل حمرا بطيات وشراشيب ذهبية. [closed] من ٠ (مفتوحة) لـ١ (مسدلة).
class CurtainPainter extends CustomPainter {
  const CurtainPainter(this.closed);

  final double closed;

  @override
  void paint(Canvas canvas, Size s) {
    if (closed <= 0) return;
    final u = s.height / 540;
    final pw = (s.width / 2 + 4) * closed;
    const folds = 7;
    for (final left in [true, false]) {
      final x0 = left ? 0.0 : s.width - pw;
      final rect = Rect.fromLTWH(x0, 0, pw, s.height);
      // ظل الستارة على الصفحة
      final edge = left ? x0 + pw : x0;
      final shadow = Rect.fromLTWH(left ? edge : edge - 46 * u, 0, 46 * u, s.height);
      canvas.drawRect(
        shadow,
        Paint()
          ..shader = ui.Gradient.linear(
            left ? shadow.centerLeft : shadow.centerRight,
            left ? shadow.centerRight : shadow.centerLeft,
            [const Color(0x66000000), const Color(0x00000000)],
          ),
      );
      canvas.save();
      canvas.clipRect(rect);
      final fw = pw / folds;
      for (var i = 0; i < folds; i++) {
        final r = Rect.fromLTWH(x0 + i * fw, 0, fw + .6, s.height);
        canvas.drawRect(
          r,
          Paint()
            ..shader = ui.Gradient.linear(
              r.centerLeft,
              r.centerRight,
              const [Color(0xFF4A0A10), Color(0xFFB5222C), Color(0xFFD03A3E), Color(0xFF8E141C), Color(0xFF45090F)],
              const [0, .3, .5, .75, 1],
            ),
        );
      }
      for (var i = 1; i < folds; i++) {
        canvas.drawLine(
          Offset(x0 + i * fw, 0),
          Offset(x0 + i * fw, s.height),
          Paint()
            ..color = const Color(0x22000000)
            ..strokeWidth = 1.5,
        );
      }
      // حافة الذيل المموجة
      final hem = Path()..moveTo(x0, s.height);
      for (var x = 0.0; x <= pw; x += 6) {
        hem.lineTo(x0 + x, s.height - (10 + 7 * math.sin(x / math.max(pw, 1) * math.pi * folds)) * u);
      }
      hem
        ..lineTo(x0 + pw, s.height)
        ..close();
      canvas.drawPath(hem, Paint()..color = const Color(0x55000000));
      canvas.restore();
      // الشراشيب الذهبية على الحافة الداخلية
      final ex = left ? x0 + pw : x0;
      final band = 4 * u;
      canvas.drawRect(
        Rect.fromLTWH(ex - band, 0, band * 2, s.height),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(ex - band, 0),
            Offset(ex + band, 0),
            const [Color(0xFFB9782C), Color(0xFFFFE9A0), Color(0xFFB9782C)],
            const [0, .5, 1],
          ),
      );
      for (var y = 14.0 * u; y < s.height; y += 22 * u) {
        canvas.drawCircle(Offset(ex, y), 3.4 * u, Paint()..color = const Color(0xFFF6C84C));
      }
    }
    // عمود الستارة الذهبي فوق
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s.width, 12 * u),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, 12 * u), const [Color(0xFFFFE9A0), Color(0xFFB9782C)]),
    );
  }

  @override
  bool shouldRepaint(CurtainPainter old) => old.closed != closed;
}
