import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'design.dart';
import 'fx.dart';

/// خلفية اللعبة: جدار ألواح خشب دافي (التصميم الجديد)، وفوقه ضو خفيف بلون [glow].
class NightBackground extends StatelessWidget {
  const NightBackground({super.key, required this.child, this.glow});

  final Widget child;
  final Color? glow;

  @override
  Widget build(BuildContext context) => WoodWall(glow: glow, child: child);
}

/// صفحة بخلفية الليل.
class NightScaffold extends StatelessWidget {
  const NightScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.glow,
    this.background,
    this.shade = .65,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Color? glow;

  /// رسمة ورا الشاشة بدال الليل (مثل مكان الطاولة)، ومعها ظل يخلي الكلام يبان.
  final Widget? background;

  /// قوة الظل اللي فوق [background] (٠ بدون ظل).
  final double shade;

  @override
  Widget build(BuildContext context) {
    if (background case final bg?) {
      return Stack(
        children: [
          Positioned.fill(child: bg),
          if (shade > 0) Positioned.fill(child: ColoredBox(color: Colors.black.withValues(alpha: shade))),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: appBar,
            body: body,
            bottomNavigationBar: bottomNavigationBar,
          ),
        ],
      );
    }
    return NightBackground(
      glow: glow,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

enum ButtonTone { gold, green, red, purple, ghost }

/// زر ألعاب ممتلئ: تدرج لامع، وحافة فاتحة، وظل تحت ينضغط لما تضغطه.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = ButtonTone.gold,
    this.icon,
    this.height = 54,
    this.fontSize = 19,
    this.semantics,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonTone tone;
  final Widget? icon;
  final double height;
  final double fontSize;
  final String? semantics;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> with TickerProviderStateMixin {
  bool _down = false;

  /// بعد ما تشيل إصبعك: الزر يرجع بنطة صغيرة.
  late final _release = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  /// موجة تطلع من مكان إصبعك.
  late final _ripple = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  Offset _touch = Offset.zero;

  /// (تدرج اللون، الحد الغامق، ظل العمق تحت، لون الكلام). الأساسي أحمر برتقالي مثل «البس» في التصميم.
  static const _tones = {
    ButtonTone.gold: (
      [Color(0xFFF36C44), Color(0xFFD6411F), Color(0xFFA7281A)],
      Color(0xFF4C0D04),
      Color(0xFF7A1A0C),
      Color(0xFFFFF8E8),
    ),
    ButtonTone.green: (
      [Color(0xFF8BDB59), Color(0xFF4FAB31), Color(0xFF2E781D)],
      Color(0xFF143A0B),
      Color(0xFF1F5513),
      Color(0xFFFFF8E8),
    ),
    ButtonTone.red: (
      [Color(0xFFE8584A), Color(0xFFB8231A), Color(0xFF7E140E)],
      Color(0xFF3E0805),
      Color(0xFF5E0E09),
      Color(0xFFFFF8E8),
    ),
    ButtonTone.purple: (
      [Color(0xFF66B9F8), Color(0xFF2F83D9), Color(0xFF1B59A3)],
      Color(0xFF0B2953),
      Color(0xFF123F7A),
      Color(0xFFFFF8E8),
    ),
  };

  @override
  void dispose() {
    _release.dispose();
    _ripple.dispose();
    super.dispose();
  }

  void _press(TapDownDetails d) {
    setState(() {
      _down = true;
      _touch = d.localPosition;
    });
    if (!FxClock.lite.value) _ripple.forward(from: 0);
  }

  void _lift() {
    if (!_down) return;
    setState(() => _down = false);
    if (!FxClock.lite.value) _release.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final ghost = widget.tone == ButtonTone.ghost;
    final t = _tones[widget.tone];
    final depth = ghost ? 0.0 : (_down ? 1.0 : 3.0);
    final fg = ghost ? AppColors.text : t!.$4;
    final outline = ghost ? const Color(0xFF130B06) : t!.$2;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semantics ?? widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? _press : null,
        onTapCancel: _lift,
        onTapUp: enabled ? (_) => _lift() : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : .45,
          child: AnimatedBuilder(
            animation: Listenable.merge([_release, _ripple]),
            builder: (context, child) {
              // ينضغط وينزل لتحت، ولما تشيل إصبعك يرجع بنطة.
              final r = _release.value;
              final scale = _down ? .95 : 1 + .045 * math.sin(r * math.pi) * (1 - r);
              return Transform.scale(scale: scale, child: child);
            },
            child: CustomPaint(
              foregroundPainter: _RipplePainter(_ripple, _touch, top: 5 - depth, height: widget.height),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 70),
                height: widget.height,
                margin: EdgeInsets.only(top: 5 - depth, bottom: depth),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: ghost
                      ? null
                      : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: t!.$1, stops: const [0, .55, 1]),
                  color: ghost ? const Color(0xFF2A1A10).withValues(alpha: .88) : null,
                  border: Border.all(color: ghost ? const Color(0xFF8A6038) : outline, width: 3),
                  boxShadow: ghost
                      ? [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 8, offset: const Offset(0, 3))]
                      : [
                          BoxShadow(color: t!.$3, offset: Offset(0, depth)),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .38),
                            blurRadius: 8,
                            offset: Offset(0, depth + 3),
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // لمعة مدورة فوق الزر (مثل أزرار التصميم): شريط فاتح داخل الحد.
                    if (!ghost)
                      Positioned(
                        left: 6,
                        right: 6,
                        top: 3,
                        height: widget.height * .34,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.height * .2),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white.withValues(alpha: .34), Colors.white.withValues(alpha: .12)],
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 8)],
                          Flexible(
                            child: OutlinedText(
                              widget.label,
                              maxLines: 1,
                              size: widget.fontSize,
                              color: fg,
                              stroke: outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// موجة بيضاء تتوسع من مكان الضغطة وتختفي (داخل حدود الزر).
class _RipplePainter extends CustomPainter {
  _RipplePainter(this.p, this.at, {required this.top, required this.height}) : super(repaint: p);

  final Animation<double> p;
  final Offset at;

  /// مكان الزر نفسه داخل المساحة (فوقه فراغ ينضغط فيه).
  final double top, height;

  @override
  void paint(Canvas canvas, Size size) {
    final v = p.value;
    if (v <= 0 || v >= 1) return;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, top, size.width, height), const Radius.circular(14)));
    canvas.drawCircle(at, 12 + v * size.width * .9, Paint()..color = Colors.white.withValues(alpha: .35 * (1 - v)));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.at != at || old.top != top || old.height != height;
}

/// نص ذهبي متدرج للعناوين.
class GoldText extends StatelessWidget {
  const GoldText(this.text, {super.key, this.size = 30, this.align = TextAlign.center});

  final String text;
  final double size;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => GoldTitle(text, size: size, align: align);
}

/// أيقونة من أيقونات اللعبة (بيضاء) بلون تختاره.
class GameIcon extends StatelessWidget {
  const GameIcon(this.name, {super.key, this.size = 24, this.color = AppColors.text});

  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/icons/ic_$name.png',
    width: size,
    height: size,
    color: color,
    filterQuality: FilterQuality.medium,
  );
}

/// لوحة داكنة بحافة خفيفة.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? const Color(0xFF241509) : null,
        image: gradient == null
            ? DecorationImage(
                image: const AssetImage(DesignAssets.woodPanel),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: .15), BlendMode.darken),
              )
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? const Color(0xFF7E5A36), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

/// ختم شمعي (الأوفياء أو الخونة).
class Seal extends StatelessWidget {
  const Seal({super.key, required this.loyal, this.size = 56});

  final bool loyal;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/seal_${loyal ? 'loyal' : 'traitor'}.png', width: size, height: size);
}

/// ختم زعيم الخونة: ختم الخونة وعليه تاج.
class LeaderSeal extends StatelessWidget {
  const LeaderSeal({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset('assets/images/seal_leader.png', width: size, height: size);
}
