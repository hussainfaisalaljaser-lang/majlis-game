import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/shop.dart';

/// يحول الأرقام للأرقام العربية مع فاصل الآلاف: 12500 ← ١٢٬٥٠٠
String arabicNumber(int n) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  final raw = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buf.write('٬');
    buf.write(digits[raw.codeUnitAt(i) - 48]);
  }
  return buf.toString();
}

/// شارة العملة (ذهب أو جواهر) مع زر شحن اختياري.
/// أيقونة ملونة مرسومة للعبة (assets/icons/gfx_*.png): coin ذهب، gem جوهرة، games لعب،
/// trophy فوز، winrate نسبة الفوز، xp خبرة.
class Gfx extends StatelessWidget {
  const Gfx(this.name, {super.key, this.size = 20});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/icons/gfx_$name.png', width: size, height: size, filterQuality: FilterQuality.medium);
}

/// رقم ومعه أيقونته (مثل الذهب أو الجواهر).
class Amount extends StatelessWidget {
  const Amount(this.icon, this.text, {super.key, this.size = 18, this.style});

  final String icon;
  final String text;
  final double size;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Gfx(icon, size: size),
      const SizedBox(width: 4),
      Text(text, style: style ?? const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

class CurrencyPill extends StatelessWidget {
  const CurrencyPill({super.key, required this.icon, required this.amount, this.onAdd, this.infinite = false});

  final String icon;
  final int amount;

  /// حساب المطور: ما يخلص.
  final bool infinite;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 3, 8, 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .12), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Gfx(icon, size: 22),
          const SizedBox(width: 5),
          Text(
            infinite ? '∞' : arabicNumber(amount),
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: infinite ? 20 : 14, height: infinite ? 1 : null),
          ),
          if (onAdd != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(colors: [Color(0xFF6DE3A0), Color(0xFF1E8E52)]),
                ),
                child: const Icon(Icons.add, size: 14, color: Color(0xFF062814)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// الشخصيات المرسومة (نفس functions/src/profile.ts → AVATARS).
const avatarIds = [
  'falcon',
  'sheikh',
  'cool',
  'scholar',
  'desert',
  'hawk',
  'merchant',
  'youth',
  'pearl',
  'rose',
  'night',
  'jasmine',
  'amber',
  'sky',
  'masked',
  'shadow',
];

String avatarAsset(String id) =>
    'assets/avatars/${avatarIds.contains(id) || premiumAvatars.contains(id) ? id : 'masked'}.png';

/// صورة اللاعب. [frame] لون للتمييز (مثل الرئيس أو المختار)، و[style] إطار من المتجر.
/// لو الاثنين موجودين، لون التمييز يغلب.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.avatar, this.frame, this.style, this.size = 52, this.dead = false});

  final String avatar;
  final Color? frame;
  final FrameStyle? style;
  final double size;
  final bool dead;

  @override
  Widget build(BuildContext context) {
    Widget img = ClipOval(
      child: Image.asset(avatarAsset(avatar), width: size, height: size, fit: BoxFit.cover),
    );
    if (dead) {
      img = ColorFiltered(colorFilter: const ColorFilter.matrix(_grey), child: img);
    }
    final style = this.style;
    final ring = size * .065;
    if (frame == null && style != null) {
      if (style.fx != FrameFx.none) return _AnimatedFrame(style: style, size: size, ring: ring, child: img);
      return Container(
        width: size + ring * 2,
        height: size + ring * 2,
        padding: EdgeInsets.all(ring),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: [...style.colors, style.colors.first]),
          boxShadow: style.glow == null ? null : [BoxShadow(color: style.glow!.withValues(alpha: .6), blurRadius: 14)],
        ),
        child: img,
      );
    }
    return Container(
      width: size + ring * 2,
      height: size + ring * 2,
      padding: EdgeInsets.all(ring),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: frame ?? Colors.white.withValues(alpha: .18),
        boxShadow: frame == null ? null : [BoxShadow(color: frame!.withValues(alpha: .55), blurRadius: 14)],
      ),
      child: img,
    );
  }

  static const _grey = <double>[
    .33, .33, .33, 0, 0, //
    .33, .33, .33, 0, 0,
    .33, .33, .33, 0, 0,
    0, 0, 0, .55, 0,
  ];
}

/// إطار متحرك من المتجر: الحلقة تدور، أو التوهج ينبض، أو لمعات تلف حول الصورة.
class _AnimatedFrame extends StatefulWidget {
  const _AnimatedFrame({required this.style, required this.size, required this.ring, required this.child});

  final FrameStyle style;
  final double size;
  final double ring;
  final Widget child;

  @override
  State<_AnimatedFrame> createState() => _AnimatedFrameState();
}

class _AnimatedFrameState extends State<_AnimatedFrame> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.style.fx == FrameFx.pulse ? 1400 : 3200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final outer = widget.size + widget.ring * 2;
    final glow = style.glow ?? style.colors.first;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        // النبض: يكبر التوهج ويصغر مرتين في الدورة الواحدة.
        final beat = style.fx == FrameFx.pulse ? (math.sin(t * math.pi * 2) + 1) / 2 : .5;
        return SizedBox(
          width: outer,
          height: outer,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: outer,
                height: outer,
                padding: EdgeInsets.all(widget.ring),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [...style.colors, style.colors.first],
                    transform: GradientRotation(style.fx == FrameFx.pulse ? 0 : t * math.pi * 2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glow.withValues(alpha: .35 + beat * .5),
                      blurRadius: 10 + beat * 14,
                      spreadRadius: beat * 2,
                    ),
                  ],
                ),
                child: child,
              ),
              if (style.fx == FrameFx.sparkle)
                for (var i = 0; i < 3; i++) _spark(outer, t + i / 3, style.colors[i % style.colors.length]),
            ],
          ),
        );
      },
    );
  }

  /// لمعة تلف حول الإطار وتطفي وتشتعل.
  Widget _spark(double outer, double t, Color color) {
    final a = t * math.pi * 2;
    final r = outer / 2;
    final s = outer * .16 * (.6 + .4 * math.sin(t * math.pi * 6).abs());
    return Transform.translate(
      offset: Offset(math.cos(a) * r, math.sin(a) * r),
      child: Icon(
        Icons.auto_awesome,
        size: s,
        color: Color.lerp(color, Colors.white, .5),
        shadows: [Shadow(color: color, blurRadius: 8)],
      ),
    );
  }
}
