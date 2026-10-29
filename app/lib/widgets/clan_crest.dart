import 'package:flutter/material.dart';

import '../models/clan.dart';
import '../theme.dart';
import 'common.dart';

/// شعار الديوان: درع بلونه وحافة ذهبية، وفي نصه شعاره (شخصية).
class ClanCrest extends StatelessWidget {
  const ClanCrest({super.key, required this.color, required this.emblem, this.size = 48});

  ClanCrest.of(ClanTag tag, {super.key, this.size = 48}) : color = tag.tint, emblem = tag.emblem;

  final Color color;
  final String emblem;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size * .86, size),
    painter: _ShieldPainter(color),
    child: SizedBox(
      width: size * .86,
      height: size,
      child: Align(
        alignment: const Alignment(0, -.12),
        child: PlayerAvatar(avatar: emblem, size: size * .46, animate: false),
      ),
    ),
  );
}

/// درع بقوس مجلس: رأس مدبب مثل المحراب، وحافة ذهبية، وجسم بلون الديوان بخطوط قماش خفيفة، وهلال صغير فوق.
/// الشعار (الشخصية) في ميدالية ذهبية بالنص.
class _ShieldPainter extends CustomPainter {
  _ShieldPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Path arch(double s) {
      final cx = w * .5, cy = h * .52;
      final k = s;
      double x(double v) => cx + (v - cx) * k;
      double y(double v) => cy + (v - cy) * k;
      return Path()
        ..moveTo(x(w * .5), y(h * .03))
        ..quadraticBezierTo(x(w * .93), y(h * .1), x(w * .93), y(h * .36))
        ..lineTo(x(w * .93), y(h * .6))
        ..quadraticBezierTo(x(w * .8), y(h * .86), x(w * .5), y(h))
        ..quadraticBezierTo(x(w * .2), y(h * .86), x(w * .07), y(h * .6))
        ..lineTo(x(w * .07), y(h * .36))
        ..quadraticBezierTo(x(w * .07), y(h * .1), x(w * .5), y(h * .03))
        ..close();
    }

    final shield = arch(1);
    final inner = arch(.8);
    canvas.drawPath(
      shield,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0B8), Color(0xFFE8B54E), Color(0xFF9A6418)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, .3)!, color, Color.lerp(color, Colors.black, .45)!],
          stops: const [0, .45, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    canvas.clipPath(inner);
    // خطوط قماش مائلة خفيفة
    final line = Paint()
      ..strokeWidth = (w * .05).clamp(1.0, 3.0)
      ..color = Colors.white.withValues(alpha: .09);
    for (var i = -4; i < 12; i++) {
      final x0 = i * w * .16;
      canvas.drawLine(Offset(x0, 0), Offset(x0 + w * .5, h), line);
    }
    // لمعة فوق
    canvas.drawOval(Rect.fromLTWH(w * .1, -h * .22, w * .8, h * .5), Paint()..color = Colors.white.withValues(alpha: .18));
    canvas.restore();
    // ميدالية ذهبية حول الشعار
    final c = Offset(w * .5, h * .44);
    final r = w * .3;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF1A0E07).withValues(alpha: .55));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * .06).clamp(1.5, 4.0)
        ..color = const Color(0xFFF2C75A),
    );
    // هلال صغير على رأس الدرع
    final mc = Offset(w * .5, h * .03);
    final mr = w * .1;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: mc, radius: mr)),
        Path()..addOval(Rect.fromCircle(center: mc + Offset(mr * .45, -mr * .2), radius: mr * .85)),
      ),
      Paint()..color = const Color(0xFFFFE9A0),
    );
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF2A1608);
    canvas.drawPath(shield, edge..strokeWidth = (w * .045).clamp(1.5, 4.0));
    canvas.drawPath(inner, edge..strokeWidth = (w * .03).clamp(1.2, 3.0));
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.color != color;
}

/// شارة ديوان صغيرة (الشعار والاسم) لبطاقة اللاعب.
class ClanBadge extends StatelessWidget {
  const ClanBadge({super.key, required this.tag});

  final ClanTag tag;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClanCrest.of(tag, size: 26),
      const SizedBox(width: 4),
      Text(
        tag.name,
        style: TextStyle(
          color: Color.lerp(tag.tint, Colors.white, .45),
          fontFamily: kufi,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    ],
  );
}
