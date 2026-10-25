import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// خلفية اللعبة: ليل متدرج مع زخرفة عربية خفيفة تتكرر.
class NightBackground extends StatelessWidget {
  const NightBackground({super.key, required this.child, this.glow = const Color(0xFF3A2A78)});

  final Widget child;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1.2),
          radius: 1.4,
          colors: [glow, AppColors.bg],
          stops: const [0, .65],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/pattern.png'), repeat: ImageRepeat.repeat, scale: 2),
        ),
        child: child,
      ),
    );
  }
}

/// صفحة بخلفية الليل.
class NightScaffold extends StatelessWidget {
  const NightScaffold({super.key, this.appBar, required this.body, this.bottomNavigationBar, this.glow});

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return NightBackground(
      glow: glow ?? const Color(0xFF3A2A78),
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

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  static const _tones = {
    ButtonTone.gold: (
      [Color(0xFFFFE08A), Color(0xFFF2B53A), Color(0xFFD48B12)],
      Color(0xFF8E5A07),
      Color(0xFFFFF2C2),
      AppColors.goldInk,
    ),
    ButtonTone.green: (
      [Color(0xFF6DE3A0), Color(0xFF2FBF71), Color(0xFF1E8E52)],
      Color(0xFF11603A),
      Color(0xFFC8FFE0),
      Color(0xFF062814),
    ),
    ButtonTone.red: (
      [Color(0xFFFF8C98), Color(0xFFE0314B), Color(0xFFA3172D)],
      Color(0xFF6B0C1C),
      Color(0xFFFFC9D0),
      Colors.white,
    ),
    ButtonTone.purple: (
      [Color(0xFFA48BFF), Color(0xFF7C5CFF), Color(0xFF4B2DC2)],
      Color(0xFF2A1680),
      Color(0xFFDCD2FF),
      Colors.white,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final ghost = widget.tone == ButtonTone.ghost;
    final t = _tones[widget.tone];
    final depth = ghost ? 0.0 : (_down ? 1.5 : 5.0);
    final fg = ghost ? AppColors.text : t!.$4;

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
          opacity: enabled ? 1 : .45,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            height: widget.height,
            margin: EdgeInsets.only(top: 5 - depth, bottom: depth),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: ghost
                  ? null
                  : LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: t!.$1),
              color: ghost ? Colors.white.withValues(alpha: .07) : null,
              border: Border.all(color: ghost ? Colors.white.withValues(alpha: .16) : t!.$3, width: 2),
              boxShadow: ghost
                  ? null
                  : [
                      BoxShadow(color: t!.$2, offset: Offset(0, depth)),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .4),
                        blurRadius: 14,
                        offset: Offset(0, depth + 4),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kufi,
                      fontWeight: FontWeight.w700,
                      fontSize: widget.fontSize,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// نص ذهبي متدرج للعناوين.
class GoldText extends StatelessWidget {
  const GoldText(this.text, {super.key, this.size = 30, this.align = TextAlign.center});

  final String text;
  final double size;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE7A3), AppColors.gold, AppColors.goldDark],
        stops: [0, .55, 1],
      ).createShader(r),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontFamily: kufi,
          fontWeight: FontWeight.w700,
          fontSize: size,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }
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
        color: gradient == null ? Colors.white.withValues(alpha: .05) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: .1), width: 1.5),
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
