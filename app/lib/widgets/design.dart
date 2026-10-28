import 'package:flutter/material.dart';

import '../theme.dart';

/// قطع التصميم الجديد (خشب، مخمل، رق، ذهب): كل شاشة تبني منها عشان يكون الشكل واحد في كل مكان.
/// الخامات في assets/design (مقصوصة من صور التصميم أو مولّدة بسكربت).
abstract final class DesignAssets {
  static const woodWall = 'assets/design/wood_bg.webp';
  static const woodPanel = 'assets/design/wood_panel.webp';
  static const velvet = 'assets/design/velvet.webp';
  static const plank = 'assets/design/plank.webp';
  static const parchment = 'assets/design/parchment.webp';
  static const parchmentWide = 'assets/design/parchment_wide.webp';
  static const velvetCorner = 'assets/design/velvet_corner.png';
  static const homeBg = 'assets/design/home_bg.webp';
}

/// تدرج الذهب (الحلقات والحدود).
const goldRingColors = [Color(0xFFFFF0B8), Color(0xFFE8B54E), Color(0xFF9A6418)];

/// دائرة خشب غامق بحلقة ذهب، وفي نصها [child] (أيقونة أزرار الرئيسية والطاولة في التصميم).
class GoldCircle extends StatelessWidget {
  const GoldCircle({super.key, required this.child, this.size = 40});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .065),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: goldRingColors),
      boxShadow: [
        const BoxShadow(color: Color(0xFF160C06), spreadRadius: 2),
        BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 6, offset: const Offset(0, 3)),
      ],
    ),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [Color(0xFF3B2415), Color(0xFF221309)]),
      ),
      child: Center(child: child),
    ),
  );
}

/// حلقة ذهب حول صورة قطرها [size] (بنفس مكان حلقة PlayerAvatar)، و[gems]: أربع جواهر حمر عليها.
class GoldRingPainter extends CustomPainter {
  const GoldRingPainter({required this.size, this.gems = false});

  final double size;
  final bool gems;

  @override
  void paint(Canvas canvas, Size box) {
    final c = box.center(Offset.zero);
    final w = size * .075;
    final r = size / 2 + w / 2;
    final dark = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF24130A);
    canvas.drawCircle(c, r + w / 2 + 1, dark..strokeWidth = 2.5);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: goldRingColors,
        ).createShader(Rect.fromCircle(center: c, radius: r + w)),
    );
    canvas.drawCircle(c, size / 2, dark..strokeWidth = 2);
    if (!gems) return;
    final fill = Paint()..color = const Color(0xFFD8352A);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF3A0E08);
    for (final (dx, dy) in const [(0.0, -1.0), (1.0, 0.0), (0.0, 1.0), (-1.0, 0.0)]) {
      final p = c + Offset(dx, dy) * r;
      final gem = Path()
        ..moveTo(p.dx, p.dy - w * 1.05)
        ..lineTo(p.dx + w * .75, p.dy)
        ..lineTo(p.dx, p.dy + w * 1.05)
        ..lineTo(p.dx - w * .75, p.dy)
        ..close();
      canvas.drawPath(gem, fill);
      canvas.drawPath(gem, edge);
    }
  }

  @override
  bool shouldRepaint(GoldRingPainter old) => old.size != size || old.gems != gems;
}

/// نص بحد غامق حوله (مثل عناوين التصميم وكلام الأزرار).
class OutlinedText extends StatelessWidget {
  const OutlinedText(
    this.text, {
    super.key,
    this.size = 18,
    this.color = const Color(0xFFFFF8E8),
    this.stroke = const Color(0xFF2A1608),
    this.strokeWidth,
    this.weight = FontWeight.w800,
    this.gradient,
    this.align = TextAlign.center,
    this.maxLines,
    this.shadow = true,
    this.family = kufi,
  });

  final String text;
  final double size;
  final Color color;
  final Color stroke;
  final double? strokeWidth;
  final FontWeight weight;

  /// تدرج للحروف (مثل الذهبي في العناوين) بدال اللون.
  final List<Color>? gradient;
  final TextAlign align;
  final int? maxLines;
  final bool shadow;
  final String family;

  @override
  Widget build(BuildContext context) {
    final sw = strokeWidth ?? (size * .16).clamp(2.0, 9.0);
    final base = TextStyle(fontFamily: family, fontWeight: weight, fontSize: size, height: 1.25);
    final overflow = maxLines == null ? null : TextOverflow.ellipsis;
    Widget fill = Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
      style: base.copyWith(color: gradient == null ? color : Colors.white),
    );
    if (gradient case final g?) {
      fill = ShaderMask(
        shaderCallback: (r) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: g,
        ).createShader(r),
        child: fill,
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: align,
          maxLines: maxLines,
          overflow: overflow,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = sw
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
            shadows: shadow ? [Shadow(color: Colors.black.withValues(alpha: .5), offset: Offset(0, size * .08), blurRadius: 3)] : null,
          ),
        ),
        fill,
      ],
    );
  }
}

/// تدرج العناوين الذهبية.
const goldTitleColors = [Color(0xFFFFF0B8), Color(0xFFFFC84E), Color(0xFFE5862B)];

/// عنوان ذهبي بحد بني (مثل «المتجر» و«الدواوين» في التصميم).
class GoldTitle extends StatelessWidget {
  const GoldTitle(this.text, {super.key, this.size = 26, this.align = TextAlign.center});

  final String text;
  final double size;
  final TextAlign align;

  @override
  Widget build(BuildContext context) =>
      OutlinedText(text, size: size, gradient: goldTitleColors, stroke: const Color(0xFF3A1606), align: align);
}

/// خلفية الشاشات: جدار ألواح خشب دافي، وفوقه ضو خفيف بلون [glow] (لون الطور مثلاً).
class WoodWall extends StatelessWidget {
  const WoodWall({super.key, required this.child, this.glow});

  final Widget child;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        image: DecorationImage(image: AssetImage(DesignAssets.woodWall), fit: BoxFit.cover),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1.1),
            radius: 1.2,
            colors: [(glow ?? const Color(0xFFB4651E)).withValues(alpha: .28), Colors.transparent],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// لوحة خشب غامق بحافة بنية وقوس صغير بكل زاوية (مثل لوحة ترتيب الدواوين في التصميم).
class WoodPanel extends StatelessWidget {
  const WoodPanel({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.radius = 22});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: const Color(0xFF1F130B),
        image: const DecorationImage(image: AssetImage(DesignAssets.woodPanel), fit: BoxFit.cover),
        border: Border.all(color: const Color(0xFF0F0805), width: 2.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .45), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: CustomPaint(
        painter: _WoodFramePainter(radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _WoodFramePainter extends CustomPainter {
  const _WoodFramePainter(this.radius);

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFF86613B);
    const inset = 6.0;
    final r = (radius - inset).clamp(4.0, 60.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2), Radius.circular(r)),
      p,
    );
    // قوس بكل زاوية
    final a = (size.shortestSide * .16).clamp(14.0, 34.0);
    for (final (x, y, sx, sy) in [
      (inset, inset, 1.0, 1.0),
      (size.width - inset, inset, -1.0, 1.0),
      (inset, size.height - inset, 1.0, -1.0),
      (size.width - inset, size.height - inset, -1.0, -1.0),
    ]) {
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(sx, sy);
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: a), 0, 1.5708, false, p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WoodFramePainter old) => old.radius != radius;
}

/// لوحة مخمل أحمر بحد ذهبي وزخرفة بالزوايا (مثل لوحة الديوان في التصميم).
class VelvetPanel extends StatelessWidget {
  const VelvetPanel({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.radius = 20, this.corners = true});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// الزخرفة الذهبية بالزوايا (تنشال في اللوحات الصغيرة).
  final bool corners;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius + 3),
        color: const Color(0xFF140504),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 14, offset: const Offset(0, 7))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF45131E),
              image: const DecorationImage(image: AssetImage(DesignAssets.velvet), fit: BoxFit.cover),
              border: Border.all(color: const Color(0xFFD9A84E), width: 3),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Stack(
              children: [
                if (corners)
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final c = (box.biggest.shortestSide * .32).clamp(28.0, 72.0);
                        Widget corner(double sx, double sy) => Transform.scale(
                          scaleX: sx,
                          scaleY: sy,
                          child: Image.asset(DesignAssets.velvetCorner, width: c, height: c, fit: BoxFit.fill),
                        );
                        return Stack(
                          children: [
                            Positioned(left: 0, bottom: 0, child: corner(1, 1)),
                            Positioned(right: 0, bottom: 0, child: corner(-1, 1)),
                            Positioned(left: 0, top: 0, child: corner(1, -1)),
                            Positioned(right: 0, top: 0, child: corner(-1, -1)),
                          ],
                        );
                      },
                    ),
                  ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// كرت رق (ورق قديم) بحد بني غامق، مثل كروت غرفة التبديل.
class ParchmentCard extends StatelessWidget {
  const ParchmentCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.radius = 18, this.wide = false});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius + 5),
        color: const Color(0xFF2B190E),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .45), blurRadius: 8, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: AppColors.parchmentDark,
            image: DecorationImage(image: AssetImage(wide ? DesignAssets.parchmentWide : DesignAssets.parchment), fit: BoxFit.fill),
            border: Border.all(color: const Color(0xFF4E331F), width: 2),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: AppColors.ink),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// لوح خشب (سطر في قائمة، أو شريط رسالة).
class PlankBar extends StatelessWidget {
  const PlankBar({super.key, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8), this.radius = 14, this.gold = false});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// حد ذهبي (للسطر المختار أو المهم).
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius + 2),
        color: const Color(0xFF130B06),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: const Color(0xFF573420),
            image: const DecorationImage(image: AssetImage(DesignAssets.plank), fit: BoxFit.fill),
            border: gold ? Border.all(color: const Color(0xFFE8B54E), width: 2.5) : null,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFFFFE2B8).withValues(alpha: .08), Colors.transparent],
              stops: const [0, .35],
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// شريط أحمر بأطراف مقصوصة وعليه عنوان ذهبي (مثل «عرض اليوم» و«فازوا الأوفياء!»).
class RibbonTitle extends StatelessWidget {
  const RibbonTitle(this.text, {super.key, this.size = 24});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final h = size * 1.7;
    return SizedBox(
      height: h + 10,
      child: CustomPaint(
        painter: _RibbonPainter(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 2.2, vertical: 4),
          child: Center(child: GoldTitle(text, size: size)),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height - 10;
    final tail = h * .9;
    final dark = Paint()..color = const Color(0xFF7C1912);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF2A0B05);
    for (final s in [-1.0, 1.0]) {
      final x0 = s < 0 ? tail * .7 : size.width - tail * .7;
      final x1 = s < 0 ? 0.0 : size.width;
      final path = Path()
        ..moveTo(x0, 10)
        ..lineTo(x1, 10)
        ..lineTo(x1 - s * tail * .35, 10 + h / 2)
        ..lineTo(x1, 10 + h)
        ..lineTo(x0, 10 + h)
        ..close();
      canvas.drawPath(path, dark);
      canvas.drawPath(path, edge);
    }
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(tail * .45, 0, size.width - tail * .9, h), const Radius.circular(6));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD8432F), Color(0xFFB02A1E), Color(0xFF8A1C14)],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(body, edge);
    canvas.drawRRect(
      body.deflate(5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFF3C766).withValues(alpha: .85),
    );
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => false;
}

/// اسم على شريط غامق (تحت صور اللاعبين).
class NamePill extends StatelessWidget {
  const NamePill(this.name, {super.key, this.size = 14, this.color = const Color(0xFFFFF6E6)});

  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: size * .7, vertical: size * .12),
    decoration: BoxDecoration(color: const Color(0xFF21140B).withValues(alpha: .92), borderRadius: BorderRadius.circular(40)),
    child: Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: size, color: color, height: 1.3),
    ),
  );
}
