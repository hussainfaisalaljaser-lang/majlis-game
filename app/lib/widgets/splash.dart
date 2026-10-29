import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'design.dart';

/// شاشة الافتتاح (مثل أول الفيديو): اسم اللعبة بالذهب على خلفية الخيمة المطموسة، وخط زخرفي تحته.
/// [loading]: دائرة تحميل صغيرة تحت (لما ننتظر السيرفر).
class SplashView extends StatelessWidget {
  const SplashView({super.key, this.loading = true});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: const Image(image: AssetImage(DesignAssets.homeBg), fit: BoxFit.cover),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.1,
                colors: [Color(0x00160A05), Color(0xB3160A05)],
                stops: [.35, 1],
              ),
            ),
          ),
          // ضو دافي ورا العنوان
          const Center(
            child: SizedBox(
              width: 460,
              height: 300,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [Color(0x66FFC85A), Color(0x00FFC85A)]),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FittedBox(fit: BoxFit.scaleDown, child: GoldTitle('مجلس الخونة', size: 82)),
                const SizedBox(height: 4),
                const _Divider(),
                SizedBox(height: loading ? 22 : 0),
                if (loading)
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.gold),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// خط بني بنص منه معين ذهبي.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 280,
    height: 16,
    child: CustomPaint(painter: _DividerPainter()),
  );
}

class _DividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawLine(
      Offset(0, c.dy),
      Offset(size.width, c.dy),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF4A2A12),
    );
    final d = Path()
      ..moveTo(c.dx, c.dy - 7)
      ..lineTo(c.dx + 7, c.dy)
      ..lineTo(c.dx, c.dy + 7)
      ..lineTo(c.dx - 7, c.dy)
      ..close();
    canvas.drawPath(
      d,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: goldRingColors,
        ).createShader(Rect.fromCenter(center: c, width: 14, height: 14)),
    );
    canvas.drawPath(
      d,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF4A2A12),
    );
  }

  @override
  bool shouldRepaint(_DividerPainter old) => false;
}
