import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'draw_flags.dart';
import 'fx.dart';

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

/// علامة المشجب: خطاف ومثلث، بحد غامق. هي أيقونة «غرفة التبديل» الوحيدة في اللعبة كلها.
class HangerPainter extends CustomPainter {
  const HangerPainter({this.color = const Color(0xFF3A1A05)});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final path = Path()
      ..moveTo(w * .5, h * .38)
      ..lineTo(w * .5, h * .3)
      ..cubicTo(w * .5, h * .12, w * .66, h * .1, w * .66, h * .22)
      ..moveTo(w * .5, h * .38)
      ..lineTo(w * .06, h * .84)
      ..lineTo(w * .94, h * .84)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(HangerPainter old) => old.color != color;
}

/// أيقونة «غرفة التبديل»: دائرة ذهبية فيها المشجب. نفس الشكل في الرئيسية والمتجر وملفي وغرفة التبديل نفسها.
class HangerBadge extends StatelessWidget {
  const HangerBadge({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: goldRingColors),
      border: Border.all(color: const Color(0xFF2A1608), width: math.max(1.4, size * .058)),
    ),
    child: CustomPaint(size: Size.square(size * .6), painter: const HangerPainter()),
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
      style: base.copyWith(
        color: gradient == null
            ? color
            : DrawFlags.titleGradients
            ? Colors.white
            : gradient![1],
      ),
    );
    if (gradient case final g? when DrawFlags.titleGradients) {
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
            shadows: shadow && DrawFlags.textShadows ? [Shadow(color: Colors.black.withValues(alpha: .5), offset: Offset(0, size * .08), blurRadius: 3)] : null,
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

/// خلفية الشاشات: ليل الخيمة. نجوم تلمع، وهلال، وبقع ضو دافية (بلون [glow]) تتحرك ببطء.
class WoodWall extends StatelessWidget {
  const WoodWall({super.key, required this.child, this.glow});

  final Widget child;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1030), Color(0xFF1D1730), Color(0xFF2E1B13)],
          stops: [0, .55, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: FxClock(
              builder: (context, time) => CustomPaint(painter: _NightTentPainter(time, glow ?? const Color(0xFFFFB05A))),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _NightTentPainter extends CustomPainter {
  _NightTentPainter(this.time, this.glow) : super(repaint: time);

  final ValueListenable<double> time;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final w = size.width, h = size.height;
    final p = Paint();
    // نجوم تلمع
    for (var i = 0; i < 70; i++) {
      final x = rnd(i, 1) * w, y = rnd(i, 2) * h * .8;
      final tw = .5 + .5 * math.sin(t * (.9 + rnd(i, 3) * 2.2) + rnd(i, 4) * 6.3);
      p.color = Colors.white.withValues(alpha: .12 + .6 * tw * tw);
      canvas.drawCircle(Offset(x, y), .6 + rnd(i, 5) * 1.5 + tw * .5, p);
      if (i % 9 == 0 && tw > .8) {
        p
          ..strokeWidth = .8
          ..color = Colors.white.withValues(alpha: .5 * tw);
        canvas.drawLine(Offset(x - 5, y), Offset(x + 5, y), p);
        canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), p);
      }
    }
    // هلال فوق على الجنب
    final c = Offset(w * .9, h * .13);
    final r = math.min(w, h) * .045;
    canvas.drawCircle(
      c,
      r * 4,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFE9A8).withValues(alpha: .16 + .04 * math.sin(t * .8)), const Color(0x00FFE9A8)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 4)),
    );
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()..addOval(Rect.fromCircle(center: c + Offset(r * .45, -r * .3), radius: r * .88)),
    );
    canvas.drawPath(moon, Paint()..color = const Color(0xFFF6D77A).withValues(alpha: .9));
    // بقع ضو دافية تطوف ببطء (فوانيس بعيدة)
    for (var i = 0; i < 5; i++) {
      final bx = w * (.12 + .76 * rnd(i, 21)) + math.sin(t * .22 + i * 1.7) * w * .04;
      final by = h * (.3 + .6 * rnd(i, 22)) + math.cos(t * .18 + i) * h * .03;
      final br = math.min(w, h) * (.16 + .1 * rnd(i, 23));
      canvas.drawCircle(
        Offset(bx, by),
        br,
        Paint()
          ..shader = RadialGradient(
            colors: [glow.withValues(alpha: .1 + .04 * math.sin(t * .6 + i)), glow.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: Offset(bx, by), radius: br)),
      );
    }
    // ضباب أرضي دافي تحت
    canvas.drawRect(
      Rect.fromLTWH(0, h * .75, w, h * .25),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0x00C27A3A), const Color(0xFFC27A3A).withValues(alpha: .1)],
        ).createShader(Rect.fromLTWH(0, h * .75, w, h * .25)),
    );
  }

  @override
  bool shouldRepaint(_NightTentPainter old) => old.glow != glow;
}

/// لوحة ليل الخيمة: زجاج غامق شفاف بحد ذهبي رفيع وعلامات بالزوايا (مكان لوحات الخشب الرمادية).
class WoodPanel extends StatelessWidget {
  const WoodPanel({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.radius = 22});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => _GlassPanel(
    radius: radius,
    padding: padding,
    colors: const [Color(0xCC2A1C28), Color(0xDD150C12)],
    child: child,
  );
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, required this.padding, required this.radius, required this.colors, this.corners = true});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<Color> colors;
  final bool corners;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
      border: Border.all(color: const Color(0xFFE8B54E).withValues(alpha: .6), width: 1.8),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .45), blurRadius: 14, offset: const Offset(0, 6))],
    ),
    child: CustomPaint(
      painter: _GlassFramePainter(radius, corners),
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// خط ذهبي خفيف داخل اللوحة، وعلامة L بكل زاوية.
class _GlassFramePainter extends CustomPainter {
  const _GlassFramePainter(this.radius, this.corners);

  final double radius;
  final bool corners;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 6.0;
    final r = (radius - inset).clamp(4.0, 60.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
        Radius.circular(r),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFE8B54E).withValues(alpha: .22),
    );
    if (!corners) return;
    final a = (size.shortestSide * .12).clamp(12.0, 26.0);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF2C75A).withValues(alpha: .85);
    for (final (x, y, sx, sy) in [
      (inset + 3, inset + 3, 1.0, 1.0),
      (size.width - inset - 3, inset + 3, -1.0, 1.0),
      (inset + 3, size.height - inset - 3, 1.0, -1.0),
      (size.width - inset - 3, size.height - inset - 3, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + sy * a)
          ..lineTo(x, y)
          ..lineTo(x + sx * a, y),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_GlassFramePainter old) => old.radius != radius || old.corners != corners;
}

/// لوحة خمرية (زجاج ليل الخيمة بدرجة أدفأ): للألواح المهمة مثل «خاص» وعرض اليوم.
class VelvetPanel extends StatelessWidget {
  const VelvetPanel({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.radius = 20, this.corners = true});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// علامات الزوايا الذهبية (تنشال في اللوحات الصغيرة).
  final bool corners;

  @override
  Widget build(BuildContext context) => _GlassPanel(
    radius: radius,
    padding: padding,
    corners: corners,
    colors: const [Color(0xDD4A1626), Color(0xEE24090F)],
    child: child,
  );
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

/// شريط خمري غامق بحد ذهبي وأطراف مقصوصة، وعليه عنوان ذهبي (مثل «القائمة» و«الهدية اليومية»).
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
        // جسم الشريط فوق والأذيال تنزل ١٠ تحت، فالكلام يتوسط الجسم (مو الارتفاع كله)
        child: Padding(
          padding: EdgeInsets.fromLTRB(size * 1.1, 0, size * 1.1, 10),
          // يصغر لو الشريط ضاق (الشاشات الصغيرة) بدل ما ينقطع
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: GoldTitle(text, size: size)),
          ),
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
    // شريط خمري غامق بحد ذهبي، يليق مع ليل الخيمة (بدل الأحمر الفاقع)
    final wineTail = Paint()..color = const Color(0xFF2C0A12);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFD9A441);
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
      canvas.drawPath(path, wineTail);
      canvas.drawPath(path, edge..strokeWidth = 1.8);
    }
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(tail * .45, 0, size.width - tail * .9, h), const Radius.circular(8));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5E1A2B), Color(0xFF3E0F1C), Color(0xFF260810)],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(body, edge..strokeWidth = 2.4);
    canvas.drawRRect(
      body.deflate(5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFF3C766).withValues(alpha: .5),
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

/// شريط الشاشات الداخلية (مثل التصميم): السهم والعنوان والأيقونة على اليمين، وعلى اليسار الجواهر والذهب وأزرار صغيرة.
/// ما له خلفية: الجدار الخشب اللي وراه هو الخلفية. [pills]: القطع اللي على اليسار (من اليمين لليسار).
class DesignAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DesignAppBar({super.key, required this.title, this.icon, this.pills = const [], this.onBack});

  final String title;

  /// أيقونة جنب العنوان (مثل بسطة المتجر).
  final Widget? icon;
  final List<Widget> pills;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(54);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 54,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'رجوع',
                excludeSemantics: true,
                child: BackArrow(onTap: onBack, height: 32),
              ),
              const SizedBox(width: 6),
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              OutlinedText(title, size: 30, stroke: const Color(0xFF5A1A10), strokeWidth: 5),
              const Spacer(),
              for (final (i, w) in pills.indexed) ...[if (i > 0) const SizedBox(width: 8), w],
            ],
          ),
        ),
      ),
    );
  }
}

/// سهم الرجوع الوحيد في اللعبة (مثل الفيديو): سهم قصير مليان وبعده علامة »، ذهبي بتدرج وحد بني غامق.
/// يشير لليمين لأن الشاشات عربية والرجوع جهة اليمين. كل الشاشات تستخدمه (ما أحد يرسم سهم لنفسه).
class BackArrow extends StatelessWidget {
  const BackArrow({super.key, this.onTap, this.height = 30});

  /// لو ما انعطى: يرجع للشاشة اللي قبل.
  final VoidCallback? onTap;

  /// ارتفاع الرسمة؛ العرض يتبعه.
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'رجوع',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      // مساحة اللمس أكبر من الرسمة شوي
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: CustomPaint(size: Size(height * BackArrowPainter.aspect, height), painter: const BackArrowPainter()),
      ),
    ),
  );
}

class BackArrowPainter extends CustomPainter {
  const BackArrowPainter();

  /// العرض ÷ الارتفاع.
  static const aspect = 1.16;

  @override
  void paint(Canvas canvas, Size size) {
    // الرسمة على لوحة ١٠٠×٨٨
    final k = size.height / 88;
    canvas.translate((size.width - 100 * k) / 2, 0);
    canvas.scale(k);
    // السهم القصير (جسم وراس مثلث)
    final arrow = Path()
      ..moveTo(3, 35)
      ..lineTo(35, 35)
      ..lineTo(35, 26)
      ..lineTo(58, 44)
      ..lineTo(35, 62)
      ..lineTo(35, 53)
      ..lineTo(3, 53)
      ..close();
    // علامة » (خط مكسور بسماكة)
    final chevron = Path()
      ..moveTo(55, 11)
      ..lineTo(88, 44)
      ..lineTo(55, 77);
    const stroke = 15.0;
    const edge = 4.0;
    Paint line(double w, {Color? color, Shader? shader}) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color ?? const Color(0xFF000000)
      ..shader = shader;
    // ظل خفيف تحت، ثم الحد البني الغامق
    for (final (shift, color) in [(3.0, const Color(0x66000000)), (0.0, const Color(0xFF4A1810))]) {
      canvas.save();
      canvas.translate(0, shift);
      canvas.drawPath(arrow, line(edge * 2, color: color));
      canvas.drawPath(chevron, line(stroke + edge * 2, color: color));
      canvas.restore();
    }
    // التعبئة الذهبية: تدرج من الكريم لفوق للنحاسي لتحت
    final gold = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF8E3A6), Color(0xFFE2B160), Color(0xFFB9782C)],
      stops: [0, .5, 1],
    ).createShader(const Rect.fromLTWH(0, 0, 100, 88));
    canvas.drawPath(arrow, Paint()..shader = gold);
    canvas.drawPath(chevron, line(stroke, shader: gold));
    // لمعة رفيعة على الحافة العليا
    final shine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xCCFFF6D6);
    canvas.drawPath(
      Path()
        ..moveTo(6, 37.5)
        ..lineTo(33, 37.5),
      shine,
    );
    canvas.drawPath(
      Path()
        ..moveTo(59, 7.5)
        ..lineTo(90, 38.5),
      shine,
    );
  }

  @override
  bool shouldRepaint(BackArrowPainter old) => false;
}

/// حبة غامقة مدورة بكلام وأيقونة (مثل «غرفة التبديل» جنب الفلوس فوق).
class DesignPill extends StatelessWidget {
  const DesignPill({super.key, required this.label, this.icon, this.onTap});

  final String label;
  final Widget? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      height: 30,
      padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 14, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0F08).withValues(alpha: .78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5A3B22), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 7)],
          Text(
            label,
            style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.goldLight, height: 1.2),
          ),
        ],
      ),
    );
    return onTap == null ? pill : GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: pill);
  }
}
