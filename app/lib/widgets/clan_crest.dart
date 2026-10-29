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
      ..lineTo(w * .96, h * .12)
      ..lineTo(w * .92, h * .58)
      ..quadraticBezierTo(w * .8, h * .86, w * .5, h)
      ..quadraticBezierTo(w * .2, h * .86, w * .08, h * .58)
      ..lineTo(w * .04, h * .12)
      ..close();
    // حافة ذهب، وفوقها وجه الدرع بلون الديوان، وحد بني غامق مثل رسم التصميم.
    final inner = shield.transform(
      (Matrix4.identity()
            ..translateByDouble(w * .5, h * .5, 0, 1)
            ..scaleByDouble(.8, .8, 1, 1)
            ..translateByDouble(-w * .5, -h * .5, 0, 1))
          .storage,
    );
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
          colors: [Color.lerp(color, Colors.white, .3)!, color, Color.lerp(color, Colors.black, .4)!],
          stops: const [0, .45, 1],
        ).createShader(Offset.zero & size),
    );
    // لمعة بالنص الفوقاني
    canvas.save();
    canvas.clipPath(inner);
    canvas.drawOval(
      Rect.fromLTWH(w * .1, -h * .22, w * .8, h * .5),
      Paint()..color = Colors.white.withValues(alpha: .2),
    );
    canvas.restore();
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
