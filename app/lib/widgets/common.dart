import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/shop.dart';
import 'anim_avatar.dart';
import 'fx.dart';
import 'fx_sig.dart';

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
/// لو الاثنين موجودين، لون التمييز يغلب. وعشان الإطار المشترى يبان دايم، استخدم [highlight] بداله:
/// توهج حول الإطار بدون ما يغطيه. الشخصيات المميزة لها خلفية متحركة تضوي، وبعضها يتحرك بنفسه.
/// [momentKey] مفتاح اللحظات الخاصة (رقم اللاعب): الإطار الأسطوري يسوي انفجاره لما ينادى.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.avatar,
    this.frame,
    this.highlight,
    this.style,
    this.size = 52,
    this.dead = false,
    this.animate = true,
    this.momentKey,
  });

  final String avatar;
  final Color? frame;
  final Color? highlight;
  final FrameStyle? style;
  final double size;
  final bool dead;

  /// الحركات (ممكن تنطفي في القوائم الطويلة).
  final bool animate;
  final String? momentKey;

  @override
  Widget build(BuildContext context) {
    // ساعة الحركات بس للي فيه شي يتحرك، والباقي صورة ثابتة ما تنرسم كل فريم.
    final style = frame == null ? this.style : null;
    final moving = avatarArt(avatar) != null || (style?.animated ?? false);
    if (!animate || !moving) return _build(const AlwaysStoppedAnimation(0), null);
    // الحركة ترسم الصورة بس كل فريم، مو الشاشة كلها اللي حولها.
    return RepaintBoundary(
      child: FxClock(
        builder: (context, t) => _MomentScope(time: t, momentKey: momentKey, builder: (moment) => _build(t, moment)),
      ),
    );
  }

  Widget _build(ValueListenable<double> t, ValueListenable<double?>? moment) {
    final art = avatarArt(avatar);
    final anim = animate ? art?.anim : null;
    Widget img = anim != null
        ? AnimAvatar(id: anim, size: size, time: t)
        : Image.asset(avatarAsset(avatar), width: size, height: size, fit: BoxFit.cover);
    if (art != null) {
      img = Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: AvatarBgPainter(art, t))),
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
    // طبقة فوق الإطار (جناح يطلع برا الدائرة مثلاً)
    final pop = anim == null || dead
        ? null
        : Positioned(
            left: ring,
            top: ring,
            width: size,
            height: size,
            child: IgnorePointer(
              child: AnimAvatar(id: anim, size: size, time: t, pop: true),
            ),
          );
    final glow = highlight == null
        ? null
        : Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: highlight!.withValues(alpha: .85),
                      blurRadius: size * .28,
                      spreadRadius: size * .05,
                    ),
                  ],
                ),
              ),
            ),
          );
    if (frame == null && style != null) {
      final back = sigFramePainter(style, t, avatar: size, layer: SigLayer.back, moment: moment);
      final front =
          sigFramePainter(style, t, avatar: size, layer: SigLayer.front, moment: moment) ??
          FramePainter(style, t, ring: ring);
      return SizedBox(
        width: outer,
        height: outer,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ?glow,
            if (back != null)
              Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: back)),
              ),
            img,
            Positioned.fill(
              child: RepaintBoundary(
                child: IgnorePointer(child: CustomPaint(painter: front)),
              ),
            ),
            ?pop,
          ],
        ),
      );
    }
    final ringed = Container(
      width: outer,
      height: outer,
      padding: EdgeInsets.all(ring),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: frame ?? highlight ?? Colors.white.withValues(alpha: .18),
        boxShadow: frame == null ? null : [BoxShadow(color: frame!.withValues(alpha: .55), blurRadius: 14)],
      ),
      child: img,
    );
    if (pop == null && glow == null) return ringed;
    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(clipBehavior: Clip.none, children: [?glow, ringed, ?pop]),
    );
  }

  static const _grey = <double>[
    .33, .33, .33, 0, 0, //
    .33, .33, .33, 0, 0,
    .33, .33, .33, 0, 0,
    0, 0, 0, .55, 0,
  ];
}

/// يسجل وقت اللحظة الخاصة (بساعة الحركات نفسها) لما تنادى بمفتاح هالصورة.
class _MomentScope extends StatefulWidget {
  const _MomentScope({required this.time, required this.momentKey, required this.builder});

  final ValueListenable<double> time;
  final String? momentKey;
  final Widget Function(ValueListenable<double?> moment) builder;

  @override
  State<_MomentScope> createState() => _MomentScopeState();
}

class _MomentScopeState extends State<_MomentScope> {
  final _at = ValueNotifier<double?>(null);

  @override
  void initState() {
    super.initState();
    Moments.events.addListener(_onEvent);
  }

  @override
  void dispose() {
    Moments.events.removeListener(_onEvent);
    _at.dispose();
    super.dispose();
  }

  void _onEvent() {
    final e = Moments.events.value;
    if (e != null && widget.momentKey != null && e.$1 == widget.momentKey) _at.value = widget.time.value;
  }

  @override
  Widget build(BuildContext context) => widget.builder(_at);
}
