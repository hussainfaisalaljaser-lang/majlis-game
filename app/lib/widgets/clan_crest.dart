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
        child: PlayerAvatar(avatar: emblem, size: size * .5, animate: false),
      ),
    ),
  );
}

class _ShieldPainter extends CustomPainter {
  _ShieldPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final shield = Path()
      ..moveTo(w * .5, 0)
      ..lineTo(w, h * .14)
      ..lineTo(w * .94, h * .6)
      ..quadraticBezierTo(w * .8, h * .88, w * .5, h)
      ..quadraticBezierTo(w * .2, h * .88, w * .06, h * .6)
      ..lineTo(0, h * .14)
      ..close();
    canvas.drawPath(
      shield,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, .25)!, Color.lerp(color, Colors.black, .45)!],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      shield,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .06
        ..color = AppColors.gold,
    );
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
        style: TextStyle(color: tag.tint, fontWeight: FontWeight.w800, fontSize: 12.5),
      ),
    ],
  );
}
