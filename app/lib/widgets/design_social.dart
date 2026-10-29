import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import 'common.dart';
import 'design.dart';
import 'fx.dart';

/// قطع شاشات الدواوين والأصدقاء والدردشة والملف والنوافذ (التصميم الجديد).
/// كل الأسماء تبدأ بـ Soc عشان ما تتعارض مع قطع غيرها.

// ألوان ثابتة من لقطات التصميم.
const socInk = Color(0xFF3A230F);
const socOutline = Color(0xFF2A1608);
const socCream = Color(0xFFFFF8E8);
const socMuted = Color(0xFFB8A58C);
const socGoldHi = Color(0xFFFFE08A);
const socGreenText = Color(0xFF7ED957);
const socOrangeText = Color(0xFFF5A623);

/// ألوان الأزرار اللامعة (التدرج من فوق، الحد الغامق، ظل العمق).
enum SocTone {
  green([Color(0xFF8BDB59), Color(0xFF4FAB31), Color(0xFF2E781D)], Color(0xFF143A0B), Color(0xFF1F5513)),
  blue([Color(0xFF66B9F8), Color(0xFF2F83D9), Color(0xFF1B59A3)], Color(0xFF0B2953), Color(0xFF123F7A)),
  orange([Color(0xFFFFB84A), Color(0xFFF0861B), Color(0xFFD0680A)], Color(0xFF55260A), Color(0xFF8A4306)),
  red([Color(0xFFF2694A), Color(0xFFD6411F), Color(0xFFA7281A)], Color(0xFF4C0D04), Color(0xFF7A1A0C)),
  grey([Color(0xFFD5D0CA), Color(0xFFA29D97), Color(0xFF75706B)], Color(0xFF2E2A28), Color(0xFF4A4643));

  const SocTone(this.colors, this.outline, this.depth);

  final List<Color> colors;
  final Color outline;
  final Color depth;
}

/// زر لامع بحد غامق وعمق تحت (مثل أزرار «ادعُ» و«تفرّج» و«اطلع» في التصميم).
class SocButton extends StatefulWidget {
  const SocButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = SocTone.green,
    this.icon,
    this.height = 36,
    this.fontSize,
    this.width,
    this.semantics,
    this.padding = 14,
  });

  final String label;
  final VoidCallback? onPressed;
  final SocTone tone;
  final Widget? icon;
  final double height;
  final double? fontSize;
  final double? width;
  final String? semantics;
  final double padding;

  @override
  State<SocButton> createState() => _SocButtonState();
}

class _SocButtonState extends State<SocButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tone;
    final enabled = widget.onPressed != null;
    final depth = _down ? 1.0 : (widget.height * .07).clamp(2.2, 4.5);
    final size = widget.fontSize ?? (widget.height * .46).clamp(12.0, 22.0);
    final radius = (widget.height * .3).clamp(8.0, 14.0);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semantics ?? widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : .5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            width: widget.width,
            height: widget.height,
            margin: EdgeInsets.only(top: 5 - depth, bottom: depth),
            padding: EdgeInsets.symmetric(horizontal: widget.padding),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: t.colors,
                stops: const [0, .55, 1],
              ),
              border: Border.all(color: t.outline, width: 2.2),
              boxShadow: [
                BoxShadow(color: t.depth, offset: Offset(0, depth)),
                BoxShadow(color: t.outline, offset: Offset(0, depth + 1.2)),
                BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 8, offset: Offset(0, depth + 4)),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // لمعة مدوّرة فوق الزر (مثل أزرار التصميم)
                Positioned(
                  left: 5,
                  right: 5,
                  top: 2.5,
                  height: widget.height * .34,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius * .7),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white.withValues(alpha: .42), Colors.white.withValues(alpha: .1)],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[widget.icon!, SizedBox(width: size * .35)],
                    Flexible(
                      child: OutlinedText(widget.label, maxLines: 1, size: size, stroke: t.outline, strokeWidth: size * .2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// عدّاد أحمر صغير (طلبات، رسائل ما انقرت).
class SocBadge extends StatelessWidget {
  const SocBadge(this.count, {super.key, this.size = 20});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minWidth: size),
    height: size,
    padding: EdgeInsets.symmetric(horizontal: size * .22),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF6A55), Color(0xFFD02A1C)],
      ),
      border: Border.all(color: const Color(0xFF3A0A05), width: 2),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 3, offset: const Offset(0, 1.5))],
    ),
    child: count <= 0
        ? null
        : Text(
            arabicNumber(count),
            style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: size * .56, color: Colors.white, height: 1.05),
          ),
  );
}

/// نقطة الحالة على صورة اللاعب: خضرا متصل، برتقالية يلعب، رمادية غير متصل.
class SocDot extends StatelessWidget {
  const SocDot(this.color, {super.key, this.size = 13});

  final Color color;
  final double size;

  static const online = Color(0xFF5ED13A);
  static const playing = Color(0xFFF5A623);
  static const offline = Color(0xFF9C948C);

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: const Color(0xFF3A230F), width: size * .16),
    ),
  );
}

/// حلقة صورة اللاعب: ذهب (الشيخ والأصحاب) أو أزرق (العضو العادي).
enum SocRing {
  gold(goldRingColors),
  blue([Color(0xFF9CCBFF), Color(0xFF3F7FD0), Color(0xFF1B4C96)]);

  const SocRing(this.colors);

  final List<Color> colors;
}

/// صورة لاعب بحلقة (ذهب أو أزرق)، ونقطة حالة اختيارية على طرفها. لو عنده إطار من المتجر يطلع إطاره.
class SocAvatar extends StatelessWidget {
  const SocAvatar({
    super.key,
    required this.avatar,
    this.style,
    this.size = 56,
    this.ring = SocRing.gold,
    this.dot,
    this.animate = false,
    this.gems = false,
  });

  final String avatar;
  final FrameStyle? style;
  final double size;
  final SocRing ring;
  final Color? dot;
  final bool animate;
  final bool gems;

  @override
  Widget build(BuildContext context) {
    final Widget face = style != null
        ? PlayerAvatar(avatar: avatar, style: style, size: size, animate: animate)
        : Stack(
            alignment: Alignment.center,
            children: [
              PlayerAvatar(avatar: avatar, frame: Colors.transparent, size: size, animate: animate),
              Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: _SocRingPainter(size, ring.colors, gems))),
              ),
            ],
          );
    if (dot == null) return face;
    final outer = size * 1.14;
    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: face),
          PositionedDirectional(
            end: outer * .02,
            bottom: outer * .02,
            child: SocDot(dot!, size: (size * .26).clamp(10.0, 18.0)),
          ),
        ],
      ),
    );
  }
}

class _SocRingPainter extends CustomPainter {
  const _SocRingPainter(this.size, this.colors, this.gems);

  final double size;
  final List<Color> colors;
  final bool gems;

  @override
  void paint(Canvas canvas, Size box) {
    if (colors == goldRingColors) return GoldRingPainter(size: size, gems: gems).paint(canvas, box);
    final c = box.center(Offset.zero);
    final w = size * .075;
    final r = size / 2 + w / 2;
    final dark = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF0E1B3A);
    canvas.drawCircle(c, r + w / 2 + 1, dark..strokeWidth = 2.5);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(Rect.fromCircle(center: c, radius: r + w)),
    );
    canvas.drawCircle(c, size / 2, dark..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_SocRingPainter old) => old.size != size || old.colors != colors || old.gems != gems;
}

/// تاج ذهبي صغير فوق صورة شيخ الديوان.
class SocCrown extends StatelessWidget {
  const SocCrown({super.key, this.width = 44});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * .72,
    child: CustomPaint(painter: _CrownPainter()),
  );
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final body = Path()
      ..moveTo(w * .06, h * .92)
      ..lineTo(0, h * .22)
      ..lineTo(w * .27, h * .52)
      ..lineTo(w * .5, 0)
      ..lineTo(w * .73, h * .52)
      ..lineTo(w, h * .22)
      ..lineTo(w * .94, h * .92)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0A8), Color(0xFFFFC23E), Color(0xFFD98A12)],
        ).createShader(Offset.zero & s),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF4A2406),
    );
    // جوهرة حمرا بالنص
    final gem = Path()
      ..moveTo(w * .5, h * .42)
      ..lineTo(w * .58, h * .62)
      ..lineTo(w * .5, h * .82)
      ..lineTo(w * .42, h * .62)
      ..close();
    canvas.drawPath(gem, Paint()..color = const Color(0xFFD8352A));
    canvas.drawPath(
      gem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF4A0E08),
    );
  }

  @override
  bool shouldRepaint(_CrownPainter old) => false;
}

/// سهم الرجوع الذهبي (يمين الشاشة بالعربي).
class SocBackArrow extends StatelessWidget {
  const SocBackArrow({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'رجوع',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      child: const SizedBox(width: 48, height: 40, child: CustomPaint(painter: _ArrowPainter())),
    ),
  );
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter();

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final c = h / 2;
    final p = Path()
      ..moveTo(w * .14, c)
      ..lineTo(w * .86, c)
      ..moveTo(w * .56, c - h * .27)
      ..lineTo(w * .86, c)
      ..lineTo(w * .56, c + h * .27)
      ..moveTo(w * .14, c - h * .2)
      ..lineTo(w * .3, c)
      ..lineTo(w * .14, c + h * .2);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF3A1606),
    );
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE9A0), Color(0xFFF2A92E)],
        ).createShader(Offset.zero & s),
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => false;
}

/// شريط الشاشة: سهم الرجوع، وأيقونة وعنوان ذهبي، والفلوس (اختياري) على الطرف الثاني.
class SocHeader extends StatelessWidget {
  const SocHeader({super.key, required this.title, this.icon, this.currency = true, this.onBack, this.trailing, this.back = true});

  final String title;
  final Widget? icon;
  final bool currency;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// سهم الرجوع (يخفى في الصفحة اللي ما وراها شي، مثل اختيار الاسم أول مرة).
  final bool back;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: currency ? 52 : 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            if (back) ...[SocBackArrow(onTap: onBack), const SizedBox(width: 6)] else const SizedBox(width: 10),
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: GoldTitle(title, size: 26),
              ),
            ),
            const Spacer(),
            if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
            if (currency)
              ValueListenableBuilder(
                valueListenable: Backend.instance.profile,
                builder: (context, p, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CurrencyPill(icon: 'coin', amount: p.coins, infinite: p.dev),
                    const SizedBox(width: 6),
                    CurrencyPill(icon: 'gem', amount: p.diamonds, infinite: p.dev),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// صفحة بالجدار الخشبي والشريط اللي فوق ([SocHeader])، وتحته [body].
class SocScaffold extends StatelessWidget {
  const SocScaffold({
    super.key,
    required this.title,
    required this.body,
    this.icon,
    this.currency = true,
    this.onBack,
    this.trailing,
    this.glow,
    this.background,
    this.shade = .55,
    this.back = true,
  });

  final String title;
  final Widget body;
  final Widget? icon;
  final bool currency;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool back;
  final Color? glow;

  /// رسمة ورا الصفحة (مثل مكان الطاولة) بدال الجدار.
  final Widget? background;
  final double shade;

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            SocHeader(title: title, icon: icon, currency: currency, onBack: onBack, trailing: trailing, back: back),
            Expanded(child: body),
          ],
        ),
      ),
    );
    if (background case final bg?) {
      return Stack(
        children: [
          Positioned.fill(child: bg),
          if (shade > 0) Positioned.fill(child: ColoredBox(color: Colors.black.withValues(alpha: shade))),
          content,
        ],
      );
    }
    return WoodWall(glow: glow, child: content);
  }
}

/// صفحة من لوحتين: [side] (خشب) على الشمال بالعربي، و[main] (مخمل) على اليمين، مثل شاشتي الدواوين والأصدقاء.
class SocTwoPanels extends StatelessWidget {
  const SocTwoPanels({super.key, required this.main, required this.side, this.mainFlex = 11, this.sideFlex = 10});

  final Widget main;
  final Widget side;
  final int mainFlex;
  final int sideFlex;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: mainFlex, child: main),
        const SizedBox(width: 10),
        Expanded(flex: sideFlex, child: side),
      ],
    ),
  );
}

/// أبجد: سطر عنوان صغير بخط كوفي كريمي (مثل «ترتيب الدواوين هالأسبوع»).
class SocPanelTitle extends StatelessWidget {
  const SocPanelTitle(this.text, {super.key, this.size = 17, this.gold = false});

  final String text;
  final double size;
  final bool gold;

  @override
  Widget build(BuildContext context) => gold
      ? GoldTitle(text, size: size)
      : Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: size, color: socCream, height: 1.25),
        );
}

/// عنوان لوحة ذهبي كبير وتحته خط غامق ومعين ذهبي بالنص (عنوان «دردشة الديوان»).
class SocDiamondTitle extends StatelessWidget {
  const SocDiamondTitle(this.text, {super.key, this.size = 27});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GoldTitle(text, size: size),
      const SizedBox(height: 2),
      const SizedBox(height: 12, child: CustomPaint(size: Size.fromHeight(12), painter: _DiamondLinePainter())),
    ],
  );
}

class _DiamondLinePainter extends CustomPainter {
  const _DiamondLinePainter();

  @override
  void paint(Canvas canvas, Size s) {
    final y = s.height / 2;
    final inset = s.width * .02;
    canvas.drawLine(
      Offset(inset, y),
      Offset(s.width - inset, y),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2A150A),
    );
    final d = Path()
      ..moveTo(s.width / 2, y - 6)
      ..lineTo(s.width / 2 + 6, y)
      ..lineTo(s.width / 2, y + 6)
      ..lineTo(s.width / 2 - 6, y)
      ..close();
    canvas.drawPath(d, Paint()..color = const Color(0xFFF2B33E));
    canvas.drawPath(
      d,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF4A2406),
    );
  }

  @override
  bool shouldRepaint(_DiamondLinePainter old) => false;
}

/// لوح خشب غامق بسطر (قائمة الأصدقاء، الدواوين…): تدرج بني بتعريق خفيف، وحد ذهبي لو [selected].
class SocPlankRow extends StatelessWidget {
  const SocPlankRow({
    super.key,
    required this.child,
    this.selected = false,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(10, 7, 10, 7),
    this.radius = 12,
    this.semantics,
  });

  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    Widget row = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F3828), Color(0xFF402819), Color(0xFF38211A)],
          stops: [0, .35, 1],
        ),
        border: Border.all(color: selected ? const Color(0xFFE8B54E) : const Color(0xFF1B0F08), width: selected ? 2.5 : 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: CustomPaint(
        painter: const _GrainPainter(),
        child: Padding(padding: padding, child: child),
      ),
    );
    if (onTap != null) {
      row = Semantics(
        button: true,
        label: semantics,
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: row),
      );
    }
    return row;
  }
}

/// تعريق الخشب: خطوط أفقية رفيعة باهتة.
class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final dark = Paint()
      ..strokeWidth = 1
      ..color = Colors.black.withValues(alpha: .13);
    final light = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFFFFE2B8).withValues(alpha: .05);
    final lines = (size.height / 9).clamp(2, 14).round();
    for (var i = 1; i <= lines; i++) {
      final y = size.height * i / (lines + 1) + rnd.nextDouble() * 3;
      final x0 = rnd.nextDouble() * size.width * .2;
      final x1 = size.width * (.7 + rnd.nextDouble() * .3);
      canvas.drawLine(Offset(x0, y), Offset(x1, y), i.isEven ? dark : light);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => false;
}

/// تبويب: حبة خشب غامقة، أو برتقالية لامعة لو مختار. [badge] عدّاد أحمر على الزاوية.
class SocTabPill extends StatelessWidget {
  const SocTabPill({super.key, required this.label, required this.selected, required this.onTap, this.badge = 0, this.height = 34});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;
  final double height;

  @override
  Widget build(BuildContext context) {
    final size = (height * .48).clamp(12.0, 20.0);
    final pill = selected
        ? Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height * .34),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: SocTone.orange.colors,
                stops: const [0, .55, 1],
              ),
              border: Border.all(color: SocTone.orange.outline, width: 2),
              boxShadow: [
                BoxShadow(color: SocTone.orange.depth, offset: const Offset(0, 2.5)),
                BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 6, offset: const Offset(0, 4)),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height * .3),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withValues(alpha: .34), Colors.white.withValues(alpha: .06), Colors.transparent],
                stops: const [0, .4, .41],
              ),
            ),
            child: OutlinedText(label, size: size, maxLines: 1, stroke: SocTone.orange.outline),
          )
        : Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height * .34),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4A3123), Color(0xFF3A231B), Color(0xFF2E1C14)],
              ),
              border: Border.all(color: const Color(0xFF160B06), width: 2),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: kufi,
                fontWeight: FontWeight.w800,
                fontSize: size,
                color: const Color(0xFFEFE2CC),
                height: 1.25,
              ),
            ),
          );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            pill,
            if (badge > 0) PositionedDirectional(top: -7, end: -5, child: SocBadge(badge, size: 19)),
          ],
        ),
      ),
    );
  }
}

/// شارة صغيرة ملونة (المستوى، العدد، طريقة الدخول).
enum SocChipKind {
  gold(Color(0xFF6C4022), Color(0xFFD9A04A), Color(0xFFFFD27A)),
  blue(Color(0xFF263057), Color(0xFF5370B8), Color(0xFFB9CBFF)),
  green(Color(0xFF45512B), Color(0xFF8AA24A), Color(0xFFE2EBA8)),
  orange(Color(0xFF6A3418), Color(0xFFE08A3C), Color(0xFFFFC38A));

  const SocChipKind(this.fill, this.edge, this.text);

  final Color fill;
  final Color edge;
  final Color text;
}

class SocChip extends StatelessWidget {
  const SocChip(this.text, {super.key, this.kind = SocChipKind.gold, this.size = 12.5});

  final String text;
  final SocChipKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: size * .85, vertical: size * .12),
    decoration: BoxDecoration(
      color: kind.fill,
      borderRadius: BorderRadius.circular(size * 1.2),
      border: Border.all(color: kind.edge, width: 1.6),
    ),
    child: Text(
      text,
      maxLines: 1,
      style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: size, color: kind.text, height: 1.3),
    ),
  );
}

/// شريط التقدم: ذهب لامع على مجرى حبل (هدف الأسبوع) أو مجرى غامق ([rope] = false).
class SocBar extends StatelessWidget {
  const SocBar({super.key, required this.value, this.height = 11, this.rope = true, this.colors = const [Color(0xFFFFE08A), Color(0xFFF0A92B)]});

  final double value;
  final double height;
  final bool rope;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: CustomPaint(
      size: Size.fromHeight(height),
      painter: _BarPainter(value.clamp(0.0, 1.0), rope, colors, Directionality.of(context)),
    ),
  );
}

class _BarPainter extends CustomPainter {
  const _BarPainter(this.value, this.rope, this.colors, this.dir);

  final double value;
  final bool rope;
  final List<Color> colors;
  final TextDirection dir;

  @override
  void paint(Canvas canvas, Size s) {
    final r = Radius.circular(s.height / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & s, r);
    if (rope) {
      canvas.save();
      canvas.clipRRect(track);
      canvas.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC79A3E), Color(0xFF8F6320)],
          ).createShader(Offset.zero & s),
      );
      // فتلة الحبل: خطوط مائلة
      final line = Paint()
        ..strokeWidth = 1.6
        ..color = const Color(0xFF3F2509).withValues(alpha: .75);
      for (var x = -s.height; x < s.width + s.height; x += 5) {
        canvas.drawLine(Offset(x, s.height), Offset(x + s.height * .9, 0), line);
      }
      canvas.restore();
    } else {
      canvas.drawRRect(track, Paint()..color = const Color(0xFF1B0D07));
    }
    if (value > 0) {
      final w = math.max(s.height, s.width * value);
      final left = dir == TextDirection.rtl ? s.width - w : 0.0;
      final fill = RRect.fromRectAndRadius(Rect.fromLTWH(left, 0, w, s.height), r);
      canvas.drawRRect(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ).createShader(fill.outerRect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left + 3, 1.5, w - 6, s.height * .3), r),
        Paint()..color = Colors.white.withValues(alpha: .35),
      );
      canvas.drawRRect(
        fill,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFF4A2A08),
      );
    }
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF241006),
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.value != value || old.rope != rope || old.colors != colors || old.dir != dir;
}

/// حقل كتابة غامق محفور (البحث، الاسم، الرسالة…).
InputDecoration socInput({String? hint, String? label, String? error, Widget? prefix, bool dense = true}) => InputDecoration(
  hintText: hint,
  labelText: label,
  errorText: error,
  isDense: dense,
  counterText: '',
  prefixIcon: prefix,
  filled: true,
  fillColor: const Color(0xFF1B0F09),
  hintStyle: const TextStyle(color: Color(0xFF8E7A62), fontWeight: FontWeight.w700),
  labelStyle: const TextStyle(color: socMuted, fontWeight: FontWeight.w700),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFF5E4029), width: 2),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE8B54E), width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE0594A), width: 2),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE0594A), width: 2),
  ),
);

/// بطاقة لوح غامق (بدل Panel) لمحتوى اللوحات الخشبية: خلفية بنية وحد رفيع.
class SocCard extends StatelessWidget {
  const SocCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.gold = false, this.tint, this.radius = 14});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool gold;
  final Color? tint;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(const Color(0xFF4A3223), tint ?? const Color(0xFF4A3223), tint == null ? 0 : .35)!,
          Color.lerp(const Color(0xFF34201A), tint ?? const Color(0xFF34201A), tint == null ? 0 : .35)!,
        ],
      ),
      border: Border.all(color: gold ? const Color(0xFFE8B54E) : const Color(0xFF1B0F08), width: gold ? 2.2 : 2),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 4, offset: const Offset(0, 2))],
    ),
    child: Padding(padding: padding, child: child),
  );
}

/// فقاعة دردشة على رق: حد بني غامق وظل، وذيل صغير على الزاوية الفوقية (يمين لكلام غيرك، يسار لكلامك).
class SocBubble extends StatelessWidget {
  const SocBubble({super.key, required this.child, this.mine = false, this.tail = true, this.padding = const EdgeInsets.fromLTRB(12, 6, 12, 7)});

  final Widget child;
  final bool mine;
  final bool tail;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFD2BA8E),
        image: const DecorationImage(image: AssetImage(DesignAssets.parchmentWide), fit: BoxFit.cover),
        border: Border.all(color: const Color(0xFF4A2F1C), width: 2.2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 4, offset: const Offset(0, 3))],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: socInk),
        child: Padding(padding: padding, child: child),
      ),
    );
    if (!tail) return box;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        box,
        // نتعدل على لغة الصفحة: الشمال لكلامك، واليمين لكلام غيرك
        Positioned(
          top: 6,
          right: mine ? null : -7,
          left: mine ? -7 : null,
          child: CustomPaint(size: const Size(8, 10), painter: _TailPainter(!mine)),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.right);

  final bool right;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Path();
    if (right) {
      p
        ..moveTo(0, 0)
        ..lineTo(s.width, 0)
        ..lineTo(0, s.height)
        ..close();
    } else {
      p
        ..moveTo(s.width, 0)
        ..lineTo(0, 0)
        ..lineTo(s.width, s.height)
        ..close();
    }
    canvas.drawPath(p, Paint()..color = const Color(0xFF4A2F1C));
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.right != right;
}

/// شريط كتابة الرسالة: لوح خشب فيه ختم الملصقات، وحقل غامق، وزر إرسال أخضر دائري.
class SocChatInput extends StatelessWidget {
  const SocChatInput({
    super.key,
    required this.controller,
    required this.focus,
    required this.sending,
    required this.onSend,
    required this.onStickers,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onStickers;

  @override
  Widget build(BuildContext context) => PlankBar(
    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
    radius: 12,
    child: Row(
      children: [
        Semantics(
          button: true,
          label: 'ملصقات',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: sending ? null : onStickers,
            child: const GoldCircle(size: 38, child: SocSeal(size: 22)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E110B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF120A06), width: 2),
            ),
            child: TextField(
              controller: controller,
              focusNode: focus,
              maxLength: 200,
              minLines: 1,
              maxLines: 2,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 14.5, color: socCream),
              decoration: const InputDecoration(
                hintText: 'اكتب رسالة…',
                hintStyle: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF8C7860)),
                counterText: '',
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: 'أرسل',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: sending ? null : onSend,
            child: Opacity(opacity: sending ? .5 : 1, child: const SocSendButton()),
          ),
        ),
      ],
    ),
  );
}

/// زر الإرسال: دائرة خضرا لامعة وفيها مثلث أبيض يشير لجهة الإرسال.
class SocSendButton extends StatelessWidget {
  const SocSendButton({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _SendPainter()));
}

class _SendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2 - 1.5;
    canvas.drawCircle(c + const Offset(0, 2), r, Paint()..color = const Color(0xFF1F5513));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8BDB59), Color(0xFF3F9A28), Color(0xFF2E781D)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFF143A0B),
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 3),
      math.pi * 1.1,
      math.pi * .8,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .35),
    );
    final t = Path()
      ..moveTo(c.dx - r * .42, c.dy)
      ..lineTo(c.dx + r * .3, c.dy - r * .5)
      ..lineTo(c.dx + r * .3, c.dy + r * .5)
      ..close();
    canvas.drawPath(t, Paint()..color = Colors.white);
    canvas.drawPath(
      t,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF143A0B),
    );
  }

  @override
  bool shouldRepaint(_SendPainter old) => false;
}

/// ختم شمع أحمر مسنن (زر الملصقات).
class SocSeal extends StatelessWidget {
  const SocSeal({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _SealPainter()));
}

class _SealPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2;
    final star = Path();
    const n = 14;
    for (var i = 0; i < n * 2; i++) {
      final a = math.pi * i / n;
      final rr = i.isEven ? r : r * .86;
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.3, -.4),
          colors: [Color(0xFFE5513C), Color(0xFFA81D12)],
        ).createShader(Offset.zero & s),
    );
    canvas.drawPath(
      star,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF4A0E08),
    );
    canvas.drawCircle(
      c,
      r * .5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF6E150C),
    );
  }

  @override
  bool shouldRepaint(_SealPainter old) => false;
}

/// أشعة الشمس ورا الصورة (ورا نوافذ الهدايا). تدور ببطء.
class SocRays extends StatelessWidget {
  const SocRays({super.key, this.color = const Color(0xFFFFF8E2), this.opacity = .62, this.count = 14});

  final Color color;
  final double opacity;
  final int count;

  @override
  Widget build(BuildContext context) => FxClock(
    builder: (context, t) => CustomPaint(painter: _RaysPainter(t, color.withValues(alpha: opacity), count)),
  );
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.time, this.color, this.count) : super(repaint: time);

  final ValueListenable<double> time;
  final Color color;
  final int count;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.longestSide;
    final paint = Paint()..color = color;
    final step = math.pi * 2 / count;
    final rot = time.value * .12;
    for (var i = 0; i < count; i++) {
      final a = rot + i * step;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r)
        ..lineTo(c.dx + math.cos(a + step * .5) * r, c.dy + math.sin(a + step * .5) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color || old.count != count;
}

/// بطاقة نافذة: رق بحد ذهبي داخلي وشريط أحمر عنوانه فوق (مثل نافذة «إطارك الجديد»).
class SocPopupCard extends StatelessWidget {
  const SocPopupCard({
    super.key,
    required this.title,
    required this.child,
    this.width = 460,
    this.rays = false,
    this.raysAt = const Alignment(0, -.35),
    this.padding = const EdgeInsets.fromLTRB(24, 30, 24, 20),
    this.titleSize = 20,
    this.scroll = true,
  });

  final String title;
  final Widget child;
  final double width;

  /// أشعة الشمس ورا المحتوى.
  final bool rays;
  final Alignment raysAt;
  final EdgeInsets padding;
  final double titleSize;

  /// المحتوى يتمرر لو أطول من الشاشة (طفّه لو المحتوى فيه Expanded أو Flexible).
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * .9;
    return Padding(
      padding: EdgeInsets.only(top: titleSize * 1.1),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: maxH),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            ParchmentCard(
              padding: EdgeInsets.zero,
              radius: 22,
              child: Stack(
                children: [
                  if (rays)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Align(
                          alignment: raysAt,
                          child: const OverflowBox(
                            maxWidth: 1200,
                            maxHeight: 1200,
                            child: SizedBox(width: 1200, height: 1200, child: SocRays()),
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD9A84E), width: 2),
                        ),
                      ),
                    ),
                  ),
                  Padding(padding: padding, child: scroll ? SingleChildScrollView(child: child) : child),
                ],
              ),
            ),
            Positioned(
              top: -titleSize * 1.1,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width - 16),
                child: FittedBox(fit: BoxFit.scaleDown, child: RibbonTitle(title, size: titleSize)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// يفتح نافذة بالشكل الجديد: بطاقة رق وشريط عنوان أحمر. ترجع اللي تقفل فيه.
Future<T?> showSocDialog<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  double width = 460,
  bool rays = false,
  Alignment raysAt = const Alignment(0, -.35),
  bool dismissible = true,
  EdgeInsets padding = const EdgeInsets.fromLTRB(24, 30, 24, 20),
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: dismissible,
  barrierLabel: title,
  barrierColor: Colors.black.withValues(alpha: .7),
  transitionDuration: const Duration(milliseconds: 260),
  transitionBuilder: (context, a, _, child) => ScaleTransition(
    scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
    child: FadeTransition(opacity: a, child: child),
  ),
  pageBuilder: (context, _, _) => SafeArea(
    child: Center(
      child: Material(
        color: Colors.transparent,
        child: SocPopupCard(
          title: title,
          width: width,
          rays: rays,
          raysAt: raysAt,
          padding: padding,
          child: Builder(builder: builder),
        ),
      ),
    ),
  ),
);

/// نص عادي داخل النوافذ (بني غامق على الرق).
class SocPopupText extends StatelessWidget {
  const SocPopupText(this.text, {super.key, this.size = 15, this.muted = false, this.weight = FontWeight.w800});

  final String text;
  final double size;
  final bool muted;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: kufi,
      fontSize: size,
      height: 1.5,
      fontWeight: weight,
      color: muted ? const Color(0xFF7A5A3A) : socInk,
    ),
  );
}

/// نافذة تأكيد: سؤال وزرين ([yes] لونه أحمر لو [danger]). ترجع true لو وافق.
Future<bool> socConfirm(
  BuildContext context, {
  required String title,
  String? body,
  String yes = 'تمام',
  String no = 'لا',
  bool danger = false,
}) async =>
    await showSocDialog<bool>(
      context,
      title: title,
      width: 420,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (body != null) ...[SocPopupText(body, size: 14.5), const SizedBox(height: 14)],
          SocActions(
            children: [
              SocButton(label: no, tone: SocTone.grey, height: 42, fontSize: 16, onPressed: () => Navigator.pop(context, false)),
              SocButton(
                label: yes,
                tone: danger ? SocTone.red : SocTone.green,
                height: 42,
                fontSize: 16,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ],
      ),
    ) ??
    false;

/// صف أزرار النافذة: كل زر بعرض متساوي.
class SocActions extends StatelessWidget {
  const SocActions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (i, c) in children.indexed) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(child: c),
      ],
    ],
  );
}

/// خانة تبديل (مفتاح) بالشكل الذهبي.
class SocSwitch extends StatelessWidget {
  const SocSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 50,
      height: 28,
      padding: const EdgeInsets.all(2.5),
      alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: value ? const Color(0xFF3F9A28) : const Color(0xFF1E110B),
        border: Border.all(color: value ? const Color(0xFF143A0B) : const Color(0xFF120A06), width: 2),
      ),
      child: Container(
        width: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0B8), Color(0xFFD9A040)],
          ),
          border: Border.all(color: const Color(0xFF4A2A08), width: 1.6),
        ),
      ),
    ),
  );
}

/// حقل كتابة على الرق (داخل النوافذ): خلفية رق غامقة وحد بني.
InputDecoration socParchInput({String? hint, String? label, String? error, bool dense = true}) => InputDecoration(
  hintText: hint,
  labelText: label,
  errorText: error,
  isDense: dense,
  counterText: '',
  filled: true,
  fillColor: const Color(0xFFF5E8C8),
  hintStyle: const TextStyle(color: Color(0xFFA48A62), fontWeight: FontWeight.w700),
  labelStyle: const TextStyle(color: Color(0xFF7A5A3A), fontWeight: FontWeight.w700),
  errorStyle: const TextStyle(color: Color(0xFFB3261E), fontWeight: FontWeight.w800),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFF8A6038), width: 2),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFD08A1E), width: 2.4),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFB3261E), width: 2),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFB3261E), width: 2),
  ),
);

/// اختيار من عدة خيارات بحبات (بدل SegmentedButton): المختار برتقالي لامع. [light] لو على رق.
class SocSegments<T> extends StatelessWidget {
  const SocSegments({super.key, required this.options, required this.value, required this.onChanged, this.light = false, this.height = 34});

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool light;
  final double height;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (i, (v, label)) in options.indexed) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: v == value
              ? SocTabPill(label: label, selected: true, onTap: () => onChanged(v), height: height)
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(v),
                  child: Container(
                    height: height,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(height * .34),
                      color: light ? const Color(0xFFE6D2A6) : const Color(0xFF3A231B),
                      border: Border.all(color: light ? const Color(0xFF8A6038) : const Color(0xFF160B06), width: 2),
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: kufi,
                        fontWeight: FontWeight.w800,
                        fontSize: (height * .45).clamp(12.0, 18.0),
                        color: light ? socInk : const Color(0xFFEFE2CC),
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    ],
  );
}

/// علامة صح خضرا في دائرة بحد غامق (على البطاقات اللي انستلمت أو خلصت).
class SocCheck extends StatelessWidget {
  const SocCheck({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _CheckPainter()));
}

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2 - 1;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7ED957), Color(0xFF2E8B1F)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = const Color(0xFF143A0B),
    );
    final tick = Path()
      ..moveTo(c.dx - r * .46, c.dy + r * .02)
      ..lineTo(c.dx - r * .1, c.dy + r * .4)
      ..lineTo(c.dx + r * .5, c.dy - r * .34);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(tick, line..strokeWidth = r * .5..color = const Color(0xFF143A0B));
    canvas.drawPath(tick, line..strokeWidth = r * .3..color = Colors.white);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => false;
}


/// صندوق خشب بأحزمة ذهب وقفل (صندوق هدف الأسبوع)، مرسوم بالكود.
class SocChest extends StatelessWidget {
  const SocChest({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size * .86, child: CustomPaint(painter: _ChestPainter()));
}

class _ChestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final dark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF2A1608);
    // الغطا (مقوّس) والجسم
    final lid = Path()
      ..moveTo(w * .04, h * .46)
      ..quadraticBezierTo(w * .04, h * .06, w * .5, h * .06)
      ..quadraticBezierTo(w * .96, h * .06, w * .96, h * .46)
      ..close();
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * .04, h * .44, w * .92, h * .52), const Radius.circular(4));
    final wood = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB8773A), Color(0xFF7A4A22)],
      ).createShader(Offset.zero & s);
    canvas.drawRRect(body, wood);
    canvas.drawPath(lid, wood);
    // خطوط الألواح
    final grain = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFF3F2208).withValues(alpha: .55);
    for (final y in [.62, .78]) {
      canvas.drawLine(Offset(w * .08, h * y), Offset(w * .92, h * y), grain);
    }
    // أحزمة الذهب
    final gold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE9A0), Color(0xFFD99A2B)],
      ).createShader(Offset.zero & s);
    for (final x in [.2, .74]) {
      final band = Rect.fromLTWH(w * x, h * .08, w * .08, h * .86);
      canvas.drawRect(band, gold);
      canvas.drawRect(band, dark..strokeWidth = 1.4);
    }
    final rim = Rect.fromLTWH(w * .02, h * .4, w * .96, h * .08);
    canvas.drawRect(rim, gold);
    canvas.drawRect(rim, dark..strokeWidth = 1.4);
    canvas.drawRRect(body, dark..strokeWidth = 2.2);
    canvas.drawPath(lid, dark..strokeWidth = 2.2);
    // القفل
    final lock = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * .5, h * .5), width: w * .2, height: h * .26), const Radius.circular(3));
    canvas.drawRRect(lock, gold);
    canvas.drawRRect(lock, dark..strokeWidth = 1.6);
    canvas.drawCircle(Offset(w * .5, h * .49), w * .025, Paint()..color = const Color(0xFF3A1606));
  }

  @override
  bool shouldRepaint(_ChestPainter old) => false;
}
