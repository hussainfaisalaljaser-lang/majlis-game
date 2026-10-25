import 'package:flutter/material.dart';

import '../models/shop.dart';
import 'fx.dart';

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

/// الشخصيات المجانية (نفس functions/src/catalog.ts → FREE_AVATARS).
const avatarIds = freeAvatars;

String avatarAsset(String id) =>
    'assets/avatars/${avatarIds.contains(id) || premiumAvatars.contains(id) ? id : 'masked'}.webp';

/// صورة اللاعب. [frame] لون للتمييز (مثل الرئيس أو المختار)، و[style] إطار من المتجر.
/// لو الاثنين موجودين، لون التمييز يغلب. الشخصيات المميزة لها خلفية متحركة تضوي.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.avatar,
    this.frame,
    this.style,
    this.size = 52,
    this.dead = false,
    this.animate = true,
  });

  final String avatar;
  final Color? frame;
  final FrameStyle? style;
  final double size;
  final bool dead;

  /// الحركات (ممكن تنطفي في القوائم الطويلة).
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final art = avatarArt(avatar);
    Widget img = Image.asset(avatarAsset(avatar), width: size, height: size, fit: BoxFit.cover);
    if (art != null) {
      img = Stack(
        children: [
          Positioned.fill(
            child: animate
                ? FxClock(builder: (context, t) => CustomPaint(painter: AvatarBgPainter(art, t)))
                : CustomPaint(painter: AvatarBgPainter(art, const AlwaysStoppedAnimation(0))),
          ),
          img,
        ],
      );
    }
    img = ClipOval(
      child: SizedBox(width: size, height: size, child: img),
    );
    if (dead) img = ColorFiltered(colorFilter: const ColorFilter.matrix(_grey), child: img);
    final style = this.style;
    final ring = size * .07;
    final outer = size + ring * 2;
    if (frame == null && style != null) {
      final painter = animate
          ? FxClock(
              builder: (context, t) => CustomPaint(painter: FramePainter(style, t, ring: ring)),
            )
          : CustomPaint(painter: FramePainter(style, const AlwaysStoppedAnimation(0), ring: ring));
      return SizedBox(
        width: outer,
        height: outer,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            img,
            Positioned.fill(
              child: RepaintBoundary(child: IgnorePointer(child: painter)),
            ),
          ],
        ),
      );
    }
    return Container(
      width: outer,
      height: outer,
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
