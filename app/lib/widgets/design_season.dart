import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'common.dart';
import 'design.dart';
import 'fx.dart';

// قطع شاشات الموسم والتقدّم (الباتل باس، المهام، البطولة، الترتيب، الطاولات، السجل) بالتصميم الجديد:
// شريط علوي، أزرار لامعة، تبويبات خشب، شرائح تقدّم، صندوق وأشعة، عقد المسار. كل أسمائها تبدأ بـ Sn.

/// ألوان الأزرار اللامعة: (التدرج من فوق لتحت، لون الحد).
enum SnTone { orange, green, blue, red }

const _toneColors = {
  SnTone.orange: ([Color(0xFFFFC66E), Color(0xFFF59A1F), Color(0xFFD9680A)], Color(0xFF5A2D08)),
  SnTone.green: ([Color(0xFF8FE05F), Color(0xFF4DAE2E), Color(0xFF2F7E1F)], Color(0xFF143A0B)),
  SnTone.blue: ([Color(0xFF72BDF8), Color(0xFF2F86DB), Color(0xFF1C5AA6)], Color(0xFF0B2953)),
  SnTone.red: ([Color(0xFFF27B63), Color(0xFFCF3A25), Color(0xFF982314)], Color(0xFF3E0805)),
};

/// خلفية الزر اللامع: تدرج لوني وحد غامق ولمعة فوق (تستخدمها الأزرار والتبويب المختار).
BoxDecoration snGlossDecoration(SnTone tone, double radius, {bool pressed = false}) {
  final (colors, outline) = _toneColors[tone]!;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: const [0, .5, 1],
    ),
    border: Border.all(color: outline, width: 2),
    boxShadow: [
      BoxShadow(color: outline, offset: Offset(0, pressed ? 1 : 2.5)),
      BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 6, offset: Offset(0, pressed ? 2 : 5)),
    ],
  );
}

/// لمعة الزر: شريط فاتح بالنص الفوقاني (مثل أزرار التصميم).
class SnGloss extends StatelessWidget {
  const SnGloss({super.key, required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 4,
    right: 4,
    top: 3,
    height: height * .4,
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius * .8),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: .34), Colors.white.withValues(alpha: .1)],
          ),
        ),
      ),
    ),
  );
}

/// زر لامع بألوان التصميم (برتقالي وأخضر وأزرق وأحمر). يتمدد على عرض اللي حوله، وغلّفه بـ SizedBox لو تبي عرض معيّن.
class SnButton extends StatefulWidget {
  const SnButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = SnTone.orange,
    this.icon,
    this.height = 44,
    this.fontSize = 17,
    this.semantics,
  });

  final String label;
  final VoidCallback? onPressed;
  final SnTone tone;
  final Widget? icon;
  final double height;
  final double fontSize;
  final String? semantics;

  @override
  State<SnButton> createState() => _SnButtonState();
}

class _SnButtonState extends State<SnButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (_, outline) = _toneColors[widget.tone]!;
    final h = widget.height;
    final r = h * .3;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semantics ?? widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapCancel: () => _set(false),
        onTapUp: enabled ? (_) => _set(false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : .45,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 80),
            scale: _down ? .96 : 1,
            child: Container(
              height: h,
              margin: const EdgeInsets.only(bottom: 3),
              decoration: snGlossDecoration(widget.tone, r, pressed: _down),
              child: Stack(
                children: [
                  SnGloss(height: h, radius: r),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: h * .3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[widget.icon!, SizedBox(width: h * .14)],
                          Flexible(
                            child: OutlinedText(
                              widget.label,
                              maxLines: 1,
                              size: widget.fontSize,
                              stroke: outline,
                              strokeWidth: math.max(2.4, widget.fontSize * .17),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// عدّاد العملة (ذهب أو جواهر): شريط غامق فيه الرقم وأيقونته (مثل أعلى شاشات التصميم).
class SnChip extends StatelessWidget {
  const SnChip({super.key, required this.icon, required this.text, this.height = 28});

  /// اسم الأيقونة الملونة (coin أو gem).
  final String icon;
  final String text;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    constraints: BoxConstraints(minWidth: height * 2.5),
    padding: EdgeInsetsDirectional.only(start: 3, end: height * .5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(height),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2B190F), Color(0xFF1B0F08)],
      ),
      border: Border.all(color: const Color(0xFF3F2818), width: 2),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 5, offset: const Offset(0, 2))],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Gfx(icon, size: height - 6),
        SizedBox(width: height * .3),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              fontFamily: kufi,
              fontWeight: FontWeight.w800,
              fontSize: height * .6,
              height: 1.2,
              color: const Color(0xFFFFF3DA),
            ),
          ),
        ),
      ],
    ),
  );
}

/// عدّادا الذهب والجواهر جنب بعض (الجواهر على الطرف). [infinite] لحساب المطور.
class SnWallet extends StatelessWidget {
  const SnWallet({super.key, required this.coins, required this.diamonds, this.infinite = false, this.height = 28});

  final int coins;
  final int diamonds;
  final bool infinite;
  final double height;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SnChip(icon: 'coin', text: infinite ? '∞' : arabicNumber(coins), height: height),
      const SizedBox(width: 8),
      SnChip(icon: 'gem', text: infinite ? '∞' : arabicNumber(diamonds), height: height),
    ],
  );
}

/// حبّة غامقة بحافة بنية (عدّاد الوقت وأمثاله في الشريط العلوي).
class SnPill extends StatelessWidget {
  const SnPill({
    super.key,
    required this.child,
    this.height = 28,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: padding,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(height),
      color: const Color(0xFF1C1109).withValues(alpha: .94),
      border: Border.all(color: const Color(0xFF3F2818), width: 2),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 5, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}

/// سهم الرجوع الذهبي (سهم وعلامة »)، اللي بأعلى كل شاشات التصميم.
class SnBackButton extends StatelessWidget {
  const SnBackButton({super.key, this.onTap, this.size = 28});

  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => BackArrow(onTap: onTap, height: size);
}

/// الشريط العلوي: سهم الرجوع، أيقونة وعنوان ذهبي، ومنتصف ([middle]) وطرف ([trailing]، العملات عادةً).
class SnTopBar extends StatelessWidget implements PreferredSizeWidget {
  const SnTopBar({
    super.key,
    required this.title,
    this.icon,
    this.onBack,
    this.middle = const [],
    this.trailing = const [],
  });

  final String title;
  final Widget? icon;
  final VoidCallback? onBack;

  /// وسط الشريط (حبّات الوقت والأزرار). تنضغط لو ما وسعت.
  final List<Widget> middle;

  /// طرف الشريط (العملات).
  final List<Widget> trailing;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
        child: Row(
          children: [
            SnBackButton(onTap: onBack),
            const SizedBox(width: 8),
            if (icon != null) ...[icon!, const SizedBox(width: 6)],
            Flexible(flex: 0, child: GoldTitle(title, size: 26)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, w) in middle.indexed) ...[if (i > 0) const SizedBox(width: 8), w],
                    ],
                  ),
                ),
              ),
            ),
            ...trailing,
          ],
        ),
      ),
    ),
  );
}

/// زر صغير بشريط الأعلى: أيقونة وكلام على لوح خشب، وعليه شارة عدد لو فيه شي جديد.
class SnPillButton extends StatelessWidget {
  const SnPillButton({super.key, required this.label, required this.icon, required this.onTap, this.badge = 0});

  final String label;
  final String icon;
  final VoidCallback? onTap;
  final int badge;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? .5 : 1,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SnPill(
              padding: const EdgeInsetsDirectional.only(start: 4, end: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Gfx(icon, size: 22),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: kufi,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.2,
                      color: Color(0xFFF6C560),
                    ),
                  ),
                ],
              ),
            ),
            if (badge > 0) PositionedDirectional(top: -5, start: -3, child: SnBadge(badge)),
          ],
        ),
      ),
    ),
  );
}

/// دائرة حمرا برقم أبيض (عدد الإشعارات).
class SnBadge extends StatelessWidget {
  const SnBadge(this.count, {super.key, this.size = 16});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minWidth: size, minHeight: size),
    padding: EdgeInsets.symmetric(horizontal: size * .22),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: count > 99 ? BoxShape.rectangle : BoxShape.circle,
      borderRadius: count > 99 ? BorderRadius.circular(size) : null,
      gradient: const RadialGradient(center: Alignment(-.3, -.4), colors: [Color(0xFFFF6A55), Color(0xFFD02A1C)]),
      border: Border.all(color: const Color(0xFF4A0C06), width: 1.5),
    ),
    child: Text(
      arabicNumber(count),
      style: TextStyle(
        fontFamily: kufi,
        fontWeight: FontWeight.w800,
        fontSize: size * .66,
        height: 1.05,
        color: Colors.white,
      ),
    ),
  );
}

/// شريط تقدّم: مجرى غامق وتعبئة ذهبية لامعة (تبدأ من جهة البداية).
class SnProgressBar extends StatelessWidget {
  const SnProgressBar({super.key, required this.value, this.height = 8, this.green = false});

  final double value;
  final double height;

  /// تعبئة خضراء (لما يكتمل شي).
  final bool green;

  @override
  Widget build(BuildContext context) {
    final fill = green ? const [Color(0xFFA6EE7A), Color(0xFF4DAE2E)] : const [Color(0xFFF8DB86), Color(0xFFE0A642)];
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height),
        color: const Color(0xFF180D09),
        border: Border.all(color: const Color(0xFF0C0604), width: 1),
      ),
      padding: const EdgeInsets.all(1),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: value.clamp(0.0, 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: fill),
          ),
        ),
      ),
    );
  }
}

/// تبويبات: المختار برتقالي لامع، والباقي ألواح خشب غامقة، وعلى أي تبويب شارة عدد (مثل «الطلبات» في الأصدقاء).
class SnTabBar extends StatelessWidget {
  const SnTabBar({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.badges = const [],
    this.icons = const [],
    this.height = 34,
    this.fontSize = 15,
    this.spacing = 8,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  /// عدد الشارة لكل تبويب (٠ أو ناقص = بدون).
  final List<int> badges;

  /// أيقونات اختيارية قبل الاسم (أسماء gfx).
  final List<String> icons;
  final double height;
  final double fontSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final r = height * .32;
    return Row(
      children: [
        for (final (i, label) in labels.indexed) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(
            child: Semantics(
              button: true,
              selected: i == selected,
              label: label,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: height,
                      margin: const EdgeInsets.only(bottom: 3),
                      decoration: i == selected
                          ? snGlossDecoration(SnTone.orange, r)
                          : BoxDecoration(
                              borderRadius: BorderRadius.circular(r),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF4B3223), Color(0xFF35211A)],
                              ),
                              border: Border.all(color: const Color(0xFF160C07), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .35),
                                  offset: const Offset(0, 2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                      child: Stack(
                        children: [
                          if (i == selected) SnGloss(height: height, radius: r),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (i < icons.length) ...[
                                  Gfx(icons[i], size: height * .6),
                                  SizedBox(width: height * .12),
                                ],
                                Flexible(
                                  child: OutlinedText(
                                    label,
                                    maxLines: 1,
                                    size: fontSize,
                                    color: i == selected ? const Color(0xFFFFF8E8) : const Color(0xFFE6D2AE),
                                    stroke: i == selected ? const Color(0xFF5A2D08) : const Color(0xFF160C07),
                                    strokeWidth: math.max(2.0, fontSize * .15),
                                    shadow: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < badges.length && badges[i] > 0)
                      PositionedDirectional(top: -6, start: 4, child: SnBadge(badges[i])),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// تبويب عمودي جنب صف الجوائز (مجاني / ذهبي): الذهبي برتقالي لامع، والمجاني لوح خشب غامق. الكلام مقلوب لفوق.
class SnSideTab extends StatelessWidget {
  const SnSideTab({super.key, required this.label, this.gold = false, this.width = 30, this.fontSize = 14});

  final String label;
  final bool gold;
  final double width;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final r = width * .3;
    return Container(
      width: width,
      decoration: gold
          ? snGlossDecoration(SnTone.orange, r)
          : BoxDecoration(
              borderRadius: BorderRadius.circular(r),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF2E1D13), Color(0xFF47311F), Color(0xFF3A2619)],
              ),
              border: Border.all(color: const Color(0xFF150B06), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: .35), offset: const Offset(0, 2), blurRadius: 4),
              ],
            ),
      child: Stack(
        children: [
          if (gold)
            Positioned(
              top: 3,
              bottom: 3,
              left: 3,
              width: width * .38,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r * .8),
                  gradient: LinearGradient(
                    colors: [Colors.white.withValues(alpha: .34), Colors.white.withValues(alpha: .08)],
                  ),
                ),
              ),
            ),
          Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: OutlinedText(
                label,
                size: fontSize,
                maxLines: 1,
                color: const Color(0xFFFFF8E8),
                stroke: gold ? const Color(0xFF5A2D08) : const Color(0xFF150B06),
                strokeWidth: math.max(2.2, fontSize * .16),
                shadow: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// صندوق الكنز: خشب بسيور ذهب وقفل (رسم بالكود). العرض [size] والارتفاع ٠٫٩ منه.
class SnChest extends StatelessWidget {
  const SnChest({super.key, this.size = 90});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * .9,
    child: CustomPaint(painter: _ChestPainter()),
  );
}

class _ChestPainter extends CustomPainter {
  static const _line = Color(0xFF45220E);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..color = _line;
    Paint gold(Rect r) => Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF8DE8E), Color(0xFFE3B34C), Color(0xFFB98630)],
      ).createShader(r);

    final body = Path()
      ..moveTo(21, 7)
      ..lineTo(79, 7)
      ..cubicTo(90, 9, 95, 26, 94, 46)
      ..lineTo(90, 83)
      ..lineTo(10, 83)
      ..lineTo(6, 46)
      ..cubicTo(5, 26, 10, 9, 21, 7)
      ..close();
    // الخشب
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA9653E), Color(0xFF8F4E2E), Color(0xFF703C23)],
        ).createShader(const Rect.fromLTWH(0, 7, 100, 76)),
    );
    canvas.save();
    canvas.clipPath(body);
    final plank = Paint()
      ..strokeWidth = 1.2
      ..color = _line.withValues(alpha: .5);
    final shine = Paint()
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: .16);
    for (final y in [17.0, 28.0, 62.0, 73.0]) {
      canvas.drawLine(Offset(0, y), Offset(100, y), plank);
      canvas.drawLine(Offset(0, y + 1.3), Offset(100, y + 1.3), shine);
    }
    canvas.restore();
    canvas.drawPath(body, outline);

    // سيور جانبية منحنية
    final right = Path()
      ..moveTo(78, 7)
      ..cubicTo(90, 9, 95, 26, 94, 46)
      ..lineTo(90, 83)
      ..lineTo(79, 83)
      ..lineTo(82.5, 46)
      ..cubicTo(83.5, 30, 79, 16, 68, 9)
      ..close();
    final left = right.transform(
      (Matrix4.identity()
            ..translateByDouble(100, 0, 0, 1)
            ..scaleByDouble(-1, 1, 1, 1))
          .storage,
    );
    for (final p in [right, left]) {
      canvas.drawPath(p, gold(const Rect.fromLTWH(0, 7, 100, 76)));
      canvas.drawPath(p, outline);
    }

    // الحزام الأفقي
    final band = RRect.fromRectAndRadius(const Rect.fromLTWH(3, 41, 94, 15), const Radius.circular(2));
    canvas.drawRRect(band, gold(band.outerRect));
    canvas.drawRRect(band, outline);
    canvas.drawLine(
      const Offset(5, 44.6),
      const Offset(95, 44.6),
      Paint()
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: .4),
    );

    // زوايا الصندوق وسير القاع
    final bottom = RRect.fromRectAndRadius(const Rect.fromLTWH(24, 76, 52, 10), const Radius.circular(2));
    canvas.drawRRect(bottom, gold(bottom.outerRect));
    canvas.drawRRect(bottom, outline);
    final cornerL = Path()
      ..moveTo(6, 66)
      ..quadraticBezierTo(18, 68, 27, 76)
      ..lineTo(27, 87)
      ..lineTo(9, 87)
      ..close();
    final cornerR = cornerL.transform(
      (Matrix4.identity()
            ..translateByDouble(100, 0, 0, 1)
            ..scaleByDouble(-1, 1, 1, 1))
          .storage,
    );
    for (final p in [cornerL, cornerR]) {
      canvas.drawPath(p, gold(const Rect.fromLTWH(0, 66, 100, 21)));
      canvas.drawPath(p, outline);
    }

    // القفل
    final plate = RRect.fromRectAndRadius(const Rect.fromLTWH(38, 35, 24, 30), const Radius.circular(9));
    canvas.drawRRect(plate, gold(plate.outerRect));
    canvas.drawRRect(plate, outline);
    final key = Paint()..color = _line;
    canvas.drawCircle(const Offset(50, 46.5), 3.6, key);
    canvas.drawPath(
      Path()
        ..moveTo(47.6, 48)
        ..lineTo(52.4, 48)
        ..lineTo(53.4, 58)
        ..lineTo(46.6, 58)
        ..close(),
      key,
    );
    // مسامير
    final rivet = Paint()..color = _line.withValues(alpha: .7);
    for (final o in const [Offset(14, 18), Offset(86, 18), Offset(14, 62), Offset(86, 62)]) {
      canvas.drawCircle(o, 1.3, rivet);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChestPainter old) => false;
}

/// أشعة تدور ببطء ورا الصندوق (لوحة المسار الذهبي والنوافذ المنبثقة). تتوقف بالحركات الخفيفة.
class SnSunburst extends StatelessWidget {
  const SnSunburst({
    super.key,
    this.color = const Color(0xFFE9A5A0),
    this.alignment = Alignment.center,
    this.rays = 12,
    this.opacity = .34,
  });

  final Color color;

  /// مركز الأشعة داخل المساحة.
  final Alignment alignment;
  final int rays;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: FxClock(
        builder: (context, time) =>
            CustomPaint(size: Size.infinite, painter: _SunburstPainter(time, color, alignment, rays, opacity)),
      ),
    ),
  );
}

class _SunburstPainter extends CustomPainter {
  _SunburstPainter(this.time, this.color, this.alignment, this.rays, this.opacity) : super(repaint: time);

  final ValueListenable<double> time;
  final Color color;
  final Alignment alignment;
  final int rays;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final c = alignment.alongSize(size);
    final reach = size.longestSide * 1.1;
    final fade = size.shortestSide * .95;
    final step = math.pi * 2 / rays;
    final spin = time.value * .09;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity * 1.2),
          color.withValues(alpha: opacity * .8),
          color.withValues(alpha: 0),
        ],
        stops: const [0, .55, 1],
      ).createShader(Rect.fromCircle(center: c, radius: fade));
    for (var i = 0; i < rays; i++) {
      final a = spin + i * step;
      final half = step * .26;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a - half) * reach, c.dy + math.sin(a - half) * reach)
          ..lineTo(c.dx + math.cos(a + half) * reach, c.dy + math.sin(a + half) * reach)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SunburstPainter old) =>
      old.color != color || old.alignment != alignment || old.rays != rays || old.opacity != opacity;
}

/// كومة عملات ذهب (٢ إلى ٥ حبات) للجوائز.
class SnCoinPile extends StatelessWidget {
  const SnCoinPile({super.key, this.count = 3, this.size = 56});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final d = size * .52;
    // مواقع العملات من تحت لفوق (نسبة من المقاس).
    final spots = switch (count.clamp(1, 5)) {
      1 => const [Offset(.24, .24)],
      2 => const [Offset(.0, .3), Offset(.48, .3)],
      3 => const [Offset(.0, .36), Offset(.48, .36), Offset(.24, .08)],
      4 => const [Offset(.0, .4), Offset(.48, .4), Offset(.24, .22), Offset(.24, .0)],
      _ => const [Offset(.0, .42), Offset(.48, .42), Offset(.24, .3), Offset(.1, .08), Offset(.38, .08)],
    };
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (final o in spots)
            Positioned(
              left: o.dx * size,
              top: o.dy * size,
              child: Gfx('coin', size: d),
            ),
        ],
      ),
    );
  }
}

/// كم عملة في الكومة حسب المبلغ.
int snCoinCount(int coins) => coins >= 3000
    ? 5
    : coins >= 1000
    ? 4
    : coins >= 500
    ? 3
    : 2;

/// ختم أحمر (غرض الملصقات في الجوائز).
class SnSealStamp extends StatelessWidget {
  const SnSealStamp({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _StampPainter()),
  );
}

class _StampPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    // ورقة بحواف مسننة
    final paper = RRect.fromRectAndRadius(r.deflate(size.width * .06), Radius.circular(size.width * .06));
    canvas.drawRRect(paper, Paint()..color = const Color(0xFFD9B77C));
    canvas.drawRRect(
      paper,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .06
        ..color = const Color(0xFF8A6238),
    );
    final c = r.center;
    final wax = Path();
    for (var i = 0; i < 14; i++) {
      final a = i * math.pi * 2 / 14;
      final rad = size.width * (i.isEven ? .33 : .29);
      final p = c + Offset(math.cos(a), math.sin(a)) * rad;
      i == 0 ? wax.moveTo(p.dx, p.dy) : wax.lineTo(p.dx, p.dy);
    }
    wax.close();
    canvas.drawPath(
      wax,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.3, -.3),
          colors: [Color(0xFFE8654D), Color(0xFFB02A1C), Color(0xFF7A1A10)],
        ).createShader(r),
    );
    canvas.drawPath(
      wax,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .035
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF4A0E08),
    );
    canvas.drawCircle(
      c,
      size.width * .17,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .03
        ..color = const Color(0xFF8A2014),
    );
  }

  @override
  bool shouldRepaint(_StampPainter old) => false;
}

/// عقدة رقم المستوى على الحبل: الوصلت ذهبية، وما وصلت بنية، والحالية أكبر وتشع.
class SnLevelNode extends StatelessWidget {
  const SnLevelNode({super.key, required this.level, required this.reached, this.current = false, this.size = 40});

  final int level;
  final bool reached;
  final bool current;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ring = reached ? const Color(0xFFF4C860) : const Color(0xFF7C5942);
    final text = reached ? const Color(0xFFF7D372) : const Color(0xFFD2BFA2);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: reached ? const [Color(0xFF2A190C), Color(0xFF150C05)] : const [Color(0xFF34200F), Color(0xFF22130A)],
        ),
        border: Border.all(color: ring, width: math.max(2, size * (current ? .085 : .07))),
        boxShadow: [
          const BoxShadow(color: Color(0xFF120904), spreadRadius: 1.5),
          if (current) BoxShadow(color: const Color(0xFFFFD36A).withValues(alpha: .55), blurRadius: size * .3),
          BoxShadow(color: Colors.black.withValues(alpha: .45), blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(
        arabicNumber(level),
        style: TextStyle(
          fontFamily: kufi,
          fontWeight: FontWeight.w800,
          fontSize: size * (level > 9 ? .42 : .5),
          height: 1.1,
          color: text,
        ),
      ),
    );
  }
}

/// قطعة الحبل في عمود مستوى: كاملة العرض، وطرفها ناحية المستوى الأقل (يمين) ذهبي مصمت لو المستوى وصله اللاعب،
/// وناحية الأعلى (يسار) حبل مفتول لو لسا ما وصله. [first] و[last]: نهاية الحبل.
class SnRopeSegment extends StatelessWidget {
  const SnRopeSegment({
    super.key,
    required this.solidStart,
    required this.solidEnd,
    this.first = false,
    this.last = false,
    this.thickness = 8,
  });

  /// النص اللي ناحية البداية (اليمين بالعربي) مصمت؟
  final bool solidStart;
  final bool solidEnd;
  final bool first;
  final bool last;
  final double thickness;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: _RopePainter(
      solidStart,
      solidEnd,
      first,
      last,
      thickness,
      Directionality.of(context) == TextDirection.rtl,
    ),
  );
}

class _RopePainter extends CustomPainter {
  const _RopePainter(this.solidStart, this.solidEnd, this.first, this.last, this.thickness, this.rtl);

  final bool solidStart, solidEnd, first, last, rtl;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final mid = size.width / 2;
    // نص جهة البداية: بالعربي هو اليمين.
    // الأطراف الداخلية تزيد شوي عشان ما يبان فاصل بين عمود وعمود، وأطراف الحبل (الأول والأخير) مقصوصة.
    const e = .75;
    final cap = thickness * .6;
    final top = cy - thickness / 2, bottom = cy + thickness / 2;
    final startRect = rtl
        ? Rect.fromLTRB(mid, top, size.width + (first ? -cap : e), bottom)
        : Rect.fromLTRB(first ? cap : -e, top, mid, bottom);
    final endRect = rtl
        ? Rect.fromLTRB(last ? cap : -e, top, mid, bottom)
        : Rect.fromLTRB(mid, top, size.width + (last ? -cap : e), bottom);
    _bar(canvas, startRect, solidStart);
    _bar(canvas, endRect, solidEnd);
  }

  void _bar(Canvas canvas, Rect r, bool solid) {
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: solid
            ? const [Color(0xFFF8D677), Color(0xFFD7A13E), Color(0xFFBF8730)]
            : const [Color(0xFFE2B552), Color(0xFFB98A2E), Color(0xFF8E6820)],
      ).createShader(r);
    canvas.drawRect(r, fill);
    if (solid) return;
    // فتل الحبل: خطوط مائلة غامقة وفاتحة
    canvas.save();
    canvas.clipRect(r);
    final dark = Paint()
      ..strokeWidth = thickness * .2
      ..color = const Color(0xFF6B4A14).withValues(alpha: .75);
    final light = Paint()
      ..strokeWidth = thickness * .16
      ..color = const Color(0xFFFFE9A8).withValues(alpha: .55);
    final step = thickness * .75;
    for (var x = r.left - thickness; x < r.right + thickness; x += step) {
      canvas.drawLine(Offset(x, r.bottom), Offset(x + thickness * .8, r.top), dark);
      canvas.drawLine(Offset(x + step * .45, r.bottom), Offset(x + step * .45 + thickness * .8, r.top), light);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RopePainter old) =>
      old.solidStart != solidStart ||
      old.solidEnd != solidEnd ||
      old.first != first ||
      old.last != last ||
      old.thickness != thickness;
}

/// بطاقة جائزة في مسار الموسم: ورق للمجاني، ومخمل غامق بحد ذهبي للذهبي (ومعه قفل).
/// [claimed] مستلمة (تبهت وعليها علامة صح)، [locked] قفل (المسار الذهبي ما انفتح)، [ready] جاهزة للاستلام (توهج أخضر).
class SnRewardTile extends StatelessWidget {
  const SnRewardTile({
    super.key,
    required this.art,
    required this.label,
    this.gold = false,
    this.claimed = false,
    this.locked = false,
    this.ready = false,
    this.empty = false,
    this.labelColor,
    this.k = 1,
  });

  /// رسمة الجائزة (عملات، جوهرة، صندوق، شخصية…).
  final Widget art;
  final String label;
  final bool gold;
  final bool claimed;
  final bool locked;
  final bool ready;

  /// ما فيه جائزة بهالدرجة: بطاقة فاضية باهتة.
  final bool empty;
  final Color? labelColor;

  /// مقياس الأحجام (١ للشاشة الكبيرة).
  final double k;

  @override
  Widget build(BuildContext context) {
    final fontSize = math.max(9.5, 14 * k);
    final badge = 22 * k;
    if (empty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12 * k),
          color: Colors.black.withValues(alpha: .16),
          border: Border.all(color: const Color(0xFF6B4A2C).withValues(alpha: .4), width: 1.5),
        ),
      );
    }
    final body = Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4 * k, 12 * k, 4 * k, 6 * k),
          child: Column(
            children: [
              Expanded(
                child: Opacity(
                  opacity: claimed ? .5 : (locked ? .82 : 1),
                  child: FittedBox(fit: BoxFit.scaleDown, child: art),
                ),
              ),
              SizedBox(height: 4 * k),
              Opacity(
                opacity: claimed ? .6 : 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kufi,
                      fontWeight: FontWeight.w800,
                      fontSize: fontSize,
                      height: 1.15,
                      color: labelColor ?? (gold ? const Color(0xFFC9A765) : const Color(0xFF3B2410)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (claimed)
          PositionedDirectional(
            top: 4 * k,
            end: 4 * k,
            child: Gfx('check', size: badge),
          ),
        if (locked && !claimed)
          PositionedDirectional(
            top: 4 * k,
            end: 4 * k,
            child: Gfx('lock', size: badge * .8),
          ),
      ],
    );
    if (!gold) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14 * k),
          boxShadow: ready
              ? [BoxShadow(color: AppColors.green.withValues(alpha: .6), blurRadius: 12 * k, spreadRadius: 1)]
              : null,
        ),
        child: ParchmentCard(radius: 10 * k, padding: EdgeInsets.zero, child: body),
      );
    }
    final r = 11 * k;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r + 2),
        color: const Color(0xFF110405),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .45), blurRadius: 6, offset: const Offset(0, 3)),
          if (ready) BoxShadow(color: AppColors.green.withValues(alpha: .6), blurRadius: 12 * k, spreadRadius: 1),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF330B12), Color(0xFF1F060A)],
          ),
          border: Border.all(color: ready ? AppColors.green : const Color(0xFFC49A55), width: 1.6),
        ),
        child: SizedBox.expand(child: body),
      ),
    );
  }
}

/// سطر مهمة صغير على لوح خشب: العنوان وتحته شريط التقدّم، وعلى الطرف العدّاد (أو علامة صح لو خلصت).
class SnMissionPlank extends StatelessWidget {
  const SnMissionPlank({
    super.key,
    required this.title,
    required this.progress,
    required this.target,
    this.done = false,
    this.claimable = false,
    this.onTap,
    this.k = 1,
  });

  final String title;
  final int progress;
  final int target;

  /// خلصت (ذهبي الحد ومعها علامة صح).
  final bool done;

  /// خلصت وما استلمت: تلمع وتظهر «استلم».
  final bool claimable;
  final VoidCallback? onTap;
  final double k;

  @override
  Widget build(BuildContext context) {
    final fontSize = math.max(10.0, 15 * k);
    Widget end = Text(
      '${arabicNumber(progress.clamp(0, target))}/${arabicNumber(target)}',
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontFamily: kufi,
        fontWeight: FontWeight.w800,
        fontSize: fontSize,
        height: 1.1,
        color: const Color(0xFFF2B552),
      ),
    );
    if (done) end = Gfx('check', size: 28 * k);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: PlankBar(
        radius: 9 * k,
        gold: done,
        padding: EdgeInsets.symmetric(horizontal: 10 * k, vertical: 5 * k),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: kufi,
                        fontWeight: FontWeight.w800,
                        fontSize: fontSize,
                        height: 1.15,
                        color: const Color(0xFFFFF3DA),
                      ),
                    ),
                  ),
                  SizedBox(height: 4 * k),
                  SnProgressBar(value: target == 0 ? 0 : progress / target, height: math.max(6.0, 8 * k)),
                ],
              ),
            ),
            SizedBox(width: 10 * k),
            end,
          ],
        ),
      ),
    );
  }
}

/// نافذة منبثقة بالتصميم: لوحة مخمل بحد ذهبي، وعنوان شريط أحمر فوقها، وأشعة ورا (للجوائز والخيارات).
class SnPopup extends StatelessWidget {
  const SnPopup({super.key, required this.title, required this.child, this.width = 440, this.rays = true});

  final String title;
  final Widget child;
  final double width;
  final bool rays;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = math.min(width, size.width - 40);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // بدون حد الحوار الافتراضي (الحد الذهبي حولها يجي من لوحة المخمل).
      shape: const RoundedRectangleBorder(),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        width: w,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            if (rays)
              const Positioned(
                left: -90,
                right: -90,
                top: -90,
                bottom: -90,
                child: SnSunburst(color: Color(0xFFFFD58A), opacity: .2, alignment: Alignment(0, -.25)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: size.height - 50),
                child: VelvetPanel(padding: const EdgeInsets.fromLTRB(16, 30, 16, 14), corners: false, child: child),
              ),
            ),
            IntrinsicWidth(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200),
                child: RibbonTitle(title, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// دائرة رقم المركز في الترتيب: ميداليات للثلاثة الأوائل، وللباقي دائرة غامقة بحلقة ذهب.
class SnRankMedal extends StatelessWidget {
  const SnRankMedal({super.key, required this.rank, this.size = 34});

  final int rank;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (rank >= 1 && rank <= 3) return Gfx('medal$rank', size: size);
    return SnLevelNode(level: rank, reached: true, size: size * .9);
  }
}
