import 'package:flutter/material.dart';

import '../theme.dart';
import 'design.dart';
import 'design_game.dart';

/// قطع النوافذ المنبثقة داخل اللعبة (سجل اللعبة، الردود، المشاركة…): لوح خشب بحافة ذهبية وعنوان ذهبي.
/// كلها بنفس لغة الفيديو: حدود بنية غامقة، وذهب، وخشب.

/// لوحة نافذة تطلع من تحت (Bottom sheet): خشب غامق بزوايا علوية مدورة وحافة ذهبية.
/// النوافذ اللي تستخدمها تخلي خلفية الشيت شفافة، واللوحة ترسم نفسها.
class SheetPanel extends StatelessWidget {
  const SheetPanel({super.key, required this.child, this.radius = 26});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius + 3)),
        color: gameInk,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .6), blurRadius: 18, offset: const Offset(0, -4))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2.5, 2.5, 2.5, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius + .5)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE08A), Color(0xFFD9A030), Color(0xFF9A6418)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3.5, 3.5, 3.5, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(radius - 3)),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFF2B190E),
                  image: DecorationImage(image: AssetImage(DesignAssets.woodPanel), fit: BoxFit.cover),
                ),
                child: CustomPaint(painter: _SheetFramePainter(radius - 3), child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// خط داخلي بني فاتح (مثل لوحة الدردشة بالتصميم) وقوس صغير بالزاويتين العلويتين.
class _SheetFramePainter extends CustomPainter {
  const _SheetFramePainter(this.radius);

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 7.0;
    final r = (radius - inset).clamp(4.0, 60.0);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF86613B).withValues(alpha: .85);
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(inset, h)
      ..lineTo(inset, inset + r)
      ..arcToPoint(Offset(inset + r, inset), radius: Radius.circular(r))
      ..lineTo(w - inset - r, inset)
      ..arcToPoint(Offset(w - inset, inset + r), radius: Radius.circular(r))
      ..lineTo(w - inset, h);
    canvas.drawPath(path, p);
    final a = (size.shortestSide * .12).clamp(12.0, 26.0);
    for (final (x, sx) in [(inset, 1.0), (w - inset, -1.0)]) {
      canvas.save();
      canvas.translate(x, inset);
      canvas.scale(sx, 1);
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: a), 0, 1.5708, false, p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SheetFramePainter old) => old.radius != radius;
}

/// مقبض السحب فوق النافذة (قطعة خشب صغيرة بحد غامق).
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 7,
    decoration: BoxDecoration(
      color: const Color(0xFF8A6038),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: gameInk, width: 1.6),
    ),
  );
}

/// عنوان النافذة: أيقونة وعنوان ذهبي بحد بني، وتحته خط فيه معين ذهبي (مثل «دردشة الديوان»).
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key, this.icon, this.size = 24, this.rule = true});

  final String text;
  final Widget? icon;
  final double size;

  /// الخط اللي تحت العنوان.
  final bool rule;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Flexible(child: GoldTitle(text, size: size)),
        ],
      ),
      if (rule)
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: TitleRule(width: size * 8),
        ),
    ],
  );
}

/// خط رفيع غامق يخف من الأطراف وفي نصه معين ذهبي.
class TitleRule extends StatelessWidget {
  const TitleRule({super.key, this.width = 180});

  final double width;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(width, 12), painter: const _RulePainter());
}

class _RulePainter extends CustomPainter {
  const _RulePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final line = Paint()
      ..strokeWidth = 2.4
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          gameInk.withValues(alpha: .85),
          gameInk.withValues(alpha: .85),
          Colors.transparent,
        ],
        stops: const [0, .22, .78, 1],
      ).createShader(Offset.zero & size);
    canvas.drawLine(Offset(0, c.dy), Offset(size.width, c.dy), line);
    final d = size.height * .5;
    final diamond = Path()
      ..moveTo(c.dx, c.dy - d)
      ..lineTo(c.dx + d, c.dy)
      ..lineTo(c.dx, c.dy + d)
      ..lineTo(c.dx - d, c.dy)
      ..close();
    canvas.drawPath(diamond, Paint()..color = AppColors.gold);
    canvas.drawPath(
      diamond,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..color = gameInk,
    );
  }

  @override
  bool shouldRepaint(_RulePainter old) => false;
}

/// حبة نص غامقة بحد بني (ملاحظة صغيرة: «مقفل»، «انضاف للمفضلة»…).
class NotePill extends StatelessWidget {
  const NotePill(this.text, {super.key, this.icon, this.color = const Color(0xFFE7CFA6), this.size = 12.5});

  final String text;
  final Widget? icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: size * .8, vertical: size * .25),
    decoration: BoxDecoration(
      color: const Color(0xFF1E120B).withValues(alpha: .92),
      borderRadius: BorderRadius.circular(40),
      border: Border.all(color: const Color(0xFF6B4A2C), width: 1.6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[icon!, SizedBox(width: size * .35)],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w700, height: 1.3),
          ),
        ),
      ],
    ),
  );
}
