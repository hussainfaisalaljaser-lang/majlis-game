import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/shop.dart';
import '../theme.dart';
import 'common.dart';
import 'design.dart';
import 'fx.dart';

/// قطع تصميم الطاولة (خيمة الصحراء، الألواح، الكروت الممزقة، الأزرار الدائرية).
/// كلها ترسم بالكود بنفس أسلوب الفيديو: حدود بنية غامقة سميكة، وتدرجات دافية، ولمعة خفيفة.

/// لون حد الرسم الكرتوني (بني شبه أسود).
const gameInk = Color(0xFF24130A);

/// حجم الخط على قد المقياس [scale] (تصميم ١٠٨٠ بالطول)، وما ينزل عن [min] عشان يبقى مقروء على الجوال.
double gameFont(double design, double scale, {double min = 11}) => math.max(min, design * scale);

/// المسرح: أكبر صندوق ١٦:٩ يناسب المساحة المتاحة، وفيه الطاولة كلها بإحداثيات التصميم (١٩٢٠×١٠٨٠).
/// الخلفية (السما والرمل) تمتد بكامل الشاشة، والباقي يتحرك مع الصندوق على أي جوال.
class Stage {
  /// [safe] حواف الشاشة اللي ما ينفع نرسم فيها (النوتش)، والمسرح يتوسط الباقي.
  factory Stage(Size size, [EdgeInsets safe = EdgeInsets.zero]) {
    final avail = Rect.fromLTRB(safe.left, safe.top, size.width - safe.right, size.height - safe.bottom);
    final s = math.max(.01, math.min(avail.width / 1920, avail.height / 1080));
    return Stage._(size, s, Rect.fromCenter(center: avail.center, width: 1920 * s, height: 1080 * s));
  }

  const Stage._(this.size, this.s, this.box);

  final Size size;

  /// مقياس التصميم للشاشة (كم بكسل لكل وحدة تصميم).
  final double s;
  final Rect box;

  /// نقطة تصميم على الشاشة.
  Offset at(double x, double y) => Offset(box.left + x * s, box.top + y * s);

  /// مستطيل تصميم على الشاشة.
  Rect rect(double x0, double y0, double x1, double y1) => Rect.fromPoints(at(x0, y0), at(x1, y1));
}

/// ذهبي فاتح للأطراف العالية.
const gameGold = [Color(0xFFFFF0B8), Color(0xFFF6C84C), Color(0xFFC98A1E)];

// ───────── ألوان حلقة اللاعب

/// لون خلفية الشخصيات المجانية (حلقتها تاخذ نفس اللون فاتح، مثل صور الطاولة في التصميم).
const _avatarBg = {
  'amber': Color(0xFFB54A05),
  'cool': Color(0xFF097E5D),
  'desert': Color(0xFFAE4108),
  'falcon': Color(0xFF2C41A1),
  'hawk': Color(0xFF911D1E),
  'jasmine': Color(0xFF248537),
  'masked': Color(0xFF31353A),
  'merchant': Color(0xFF0E6F7E),
  'night': Color(0xFF2D45AA),
  'pearl': Color(0xFF9D2150),
  'rose': Color(0xFF7C2C90),
  'scholar': Color(0xFF5033AE),
  'shadow': Color(0xFF3E2685),
  'sheikh': Color(0xFF875E08),
  'sky': Color(0xFF0F7A8A),
  'youth': Color(0xFFB47500),
};

/// ألوان حلقة الشخصية: (فوق، تحت). الشخصيات المميزة (بخلفية مرسومة) حلقتها ذهبية.
(Color, Color) avatarRingColors(String avatar) {
  final bg = _avatarBg[avatar];
  if (bg == null) return (goldRingColors[0], goldRingColors[2]);
  return (Color.lerp(bg, Colors.white, .5)!, Color.lerp(bg, Colors.white, .2)!);
}

/// حلقة لاعب على الطاولة: دائرة سميكة بحد غامق ولمعة، ولونها من لون الشخصية.
class TableRingPainter extends CustomPainter {
  const TableRingPainter({required this.size, required this.top, required this.bottom, this.edge = gameInk});

  /// قطر الصورة (بدون الحلقة).
  final double size;
  final Color top, bottom, edge;

  @override
  void paint(Canvas canvas, Size box) {
    final c = box.center(Offset.zero);
    final w = size * .1;
    final r = size / 2 + w / 2;
    final dark = Paint()
      ..style = PaintingStyle.stroke
      ..color = edge;
    canvas.drawCircle(c, r + w / 2 + .8, dark..strokeWidth = math.max(2.2, size * .03));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(Rect.fromCircle(center: c, radius: r + w)),
    );
    canvas.drawCircle(c, size / 2, dark..strokeWidth = math.max(1.8, size * .025));
    // لمعة على القوس العلوي
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      math.pi * 1.12,
      math.pi * .5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .28
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .55),
    );
  }

  @override
  bool shouldRepaint(TableRingPainter old) => old.size != size || old.top != top || old.bottom != bottom;
}

/// صورة لاعب على الطاولة: حلقة بلون الشخصية، أو إطاره من المتجر لو عنده. [size] القطر الكامل مع الحلقة.
/// [ring] يغلب لون الحلقة (ذهبي للرئيس، أحمر للخائن اللي تعرفه…).
class TableAvatar extends StatelessWidget {
  const TableAvatar({
    super.key,
    required this.avatar,
    required this.size,
    this.style,
    this.ring,
    this.glow,
    this.dead = false,
    this.momentKey,
    this.animate = true,
  });

  final String avatar;
  final double size;
  final FrameStyle? style;

  /// لون يغلب لون الحلقة.
  final Color? ring;

  /// توهج حول الصورة (للإطار المشترى يبان فوقه).
  final Color? glow;
  final bool dead;
  final String? momentKey;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    // قطر الصورة: PlayerAvatar يحط حلقته برا الصورة (٧٪ من كل جهة).
    final photo = size / 1.2;
    if (style != null && ring == null) {
      return PlayerAvatar(
        avatar: avatar,
        style: style,
        highlight: glow,
        size: photo,
        dead: dead,
        momentKey: momentKey,
        animate: animate,
      );
    }
    final (top, bottom) = ring == null ? avatarRingColors(avatar) : (Color.lerp(ring!, Colors.white, .45)!, ring!);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (glow != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: glow!.withValues(alpha: .8), blurRadius: size * .22, spreadRadius: size * .02),
                  ],
                ),
              ),
            ),
          PlayerAvatar(
            avatar: avatar,
            frame: Colors.transparent,
            size: photo,
            dead: dead,
            momentKey: momentKey,
            animate: animate,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: TableRingPainter(size: photo, top: top, bottom: bottom),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// حلقة بيضاء رقيقة تنبض حول اللاعب اللي تقدر تختاره (مثل التصميم).
class PulseRing extends StatefulWidget {
  const PulseRing({super.key, required this.size, this.color = const Color(0xFFFFF3C4)});

  final double size;
  final Color color;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (!FxClock.lite.value) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final p = FxClock.lite.value ? .5 : _c.value;
        final r = widget.size * (.58 + .2 * p);
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _PulsePainter(r, widget.color.withValues(alpha: .85 * (1 - p)), widget.size),
        );
      },
    ),
  );
}

class _PulsePainter extends CustomPainter {
  const _PulsePainter(this.r, this.color, this.size);

  final double r, size;
  final Color color;

  @override
  void paint(Canvas canvas, Size box) {
    canvas.drawCircle(
      box.center(Offset.zero),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, size * .02)
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.r != r || old.color != color;
}

// ───────── الأزرار الدائرية

/// زر دائري خشبي بحلقة بنية ذهبية (إعدادات، صوت، تفاعل…). [child] الأيقونة في نصه.
class GameRoundButton extends StatefulWidget {
  const GameRoundButton({
    super.key,
    required this.child,
    required this.onTap,
    this.size = 56,
    this.semantics,
    this.active = false,
    this.glow,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double size;
  final String? semantics;

  /// الزر شغال الحين (يتوهج بلون [glow] أو الذهبي).
  final bool active;
  final Color? glow;

  @override
  State<GameRoundButton> createState() => _GameRoundButtonState();
}

class _GameRoundButtonState extends State<GameRoundButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Semantics(
      button: true,
      label: widget.semantics,
      excludeSemantics: widget.semantics != null,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _down ? .92 : 1,
          duration: const Duration(milliseconds: 90),
          child: SizedBox(
            width: s,
            height: s,
            child: CustomPaint(
              painter: _RoundButtonPainter(active: widget.active, glow: widget.glow ?? AppColors.gold),
              child: Padding(
                padding: EdgeInsets.all(s * .2),
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButtonPainter extends CustomPainter {
  const _RoundButtonPainter({required this.active, required this.glow});

  final bool active;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1;
    if (active) {
      canvas.drawCircle(
        c,
        r + 3,
        Paint()
          ..color = glow.withValues(alpha: .55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .22),
      );
    }
    canvas.drawCircle(
      c + Offset(0, r * .08),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: .4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .1),
    );
    canvas.drawCircle(c, r, Paint()..color = gameInk);
    canvas.drawCircle(
      c,
      r * .94,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: active
              ? const [Color(0xFFFFE9A0), Color(0xFFD9A030), Color(0xFF9A6418)]
              : const [Color(0xFFC79A5C), Color(0xFF8E6234), Color(0xFF583519)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(c, r * .74, Paint()..color = gameInk);
    canvas.drawCircle(
      c,
      r * .7,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.4),
          colors: [Color(0xFF6A4328), Color(0xFF3B2314)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * .6),
      math.pi * 1.15,
      math.pi * .45,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * .07
        ..color = Colors.white.withValues(alpha: .16),
    );
  }

  @override
  bool shouldRepaint(_RoundButtonPainter old) => old.active != active || old.glow != glow;
}

// ───────── الألواح

/// لوح الرسالة تحت الطاولة: خشب غامق بحافة فاتحة وظل، وفي طرفه أيقونة (مثل شريط «اختار الكرت اللي بترميه»).
class GamePlank extends StatelessWidget {
  const GamePlank({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    this.radius = 16,
    this.dim = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// لوح باهت (رسالة حالة عادية مو تعليمات).
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius + 3),
        color: const Color(0xFF1B0E07),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius + 1),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF8A5E3B), Color(0xFF6B4528), Color(0xFF55341D)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3.5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius - 2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF50301D), dim ? const Color(0xFF38221A) : const Color(0xFF3C2415)],
                ),
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// لوح التصميم العلوي (لوحة المسارات ولوحة الجولة): خشب بحافة بنية أو ذهبية.
class GameHudPlank extends StatelessWidget {
  const GameHudPlank({
    super.key,
    required this.child,
    this.gold = false,
    this.padding = const EdgeInsets.all(8),
    this.radius = 16,
    this.onTap,
  });

  final Widget child;
  final bool gold;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final edge = gold
        ? const [Color(0xFFFFE08A), Color(0xFFD9A030), Color(0xFF9A6418)]
        : const [Color(0xFFB58355), Color(0xFF8A5C37), Color(0xFF6A4326)];
    final plank = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius + 3),
        color: gameInk,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius + .5),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: edge),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3.5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius - 3),
                color: const Color(0xFF2B190E),
                border: Border.all(color: const Color(0xFF1B0E07), width: 1.5),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF5A381F), Color(0xFF442A17)],
                ),
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
    if (onTap == null) return plank;
    return GestureDetector(onTap: onTap, child: plank);
  }
}

/// شريط ذهبي بأطراف مدببة (مثل «الرئيس» تحت صورة الرئيس). [colors] تدرج الشريط.
class GoldRibbonLabel extends StatelessWidget {
  const GoldRibbonLabel(
    this.text, {
    super.key,
    this.size = 22,
    this.colors = const [Color(0xFFFFE9A0), Color(0xFFF2C14E), Color(0xFFD29A2A)],
    this.ink = const Color(0xFF3A2400),
  });

  final String text;
  final double size;
  final List<Color> colors;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final tip = size * .55;
    return CustomPaint(
      painter: _RibbonLabelPainter(tip: tip, colors: colors),
      child: Padding(
        padding: EdgeInsets.fromLTRB(tip + size * .5, size * .14, tip + size * .5, size * .2),
        child: Text(
          '- $text -',
          maxLines: 1,
          style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: size, color: ink, height: 1.2),
        ),
      ),
    );
  }
}

class _RibbonLabelPainter extends CustomPainter {
  const _RibbonLabelPainter({required this.tip, required this.colors});

  final double tip;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Path()
      ..moveTo(tip, 2)
      ..lineTo(w - tip, 2)
      ..lineTo(w - 1, h / 2)
      ..lineTo(w - tip, h - 2)
      ..lineTo(tip, h - 2)
      ..lineTo(1, h / 2)
      ..close();
    canvas.drawPath(
      body.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(Offset.zero & size),
    );
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF5A3A0C);
    canvas.drawPath(body, edge);
    // خط داخلي رفيع وزخرفة صغيرة بالطرفين
    canvas.drawPath(
      Path()
        ..moveTo(tip, 5.5)
        ..lineTo(w - tip, 5.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: .55),
    );
    for (final x in [tip * .55, w - tip * .55]) {
      canvas.drawCircle(Offset(x, h / 2), 2.4, Paint()..color = const Color(0xFF7A5014));
    }
  }

  @override
  bool shouldRepaint(_RibbonLabelPainter old) => old.tip != tip || old.colors != colors;
}

// ───────── أشعة الشمس

/// أشعة فاتحة تدور بالبطء خلف النوافذ المنبثقة (بطاقة الدور، الفوز…).
class SunRays extends StatefulWidget {
  const SunRays({super.key, this.color = const Color(0xFFFFE9A8), this.rays = 14, this.opacity = .2, this.spin = true});

  final Color color;
  final int rays;
  final double opacity;
  final bool spin;

  @override
  State<SunRays> createState() => _SunRaysState();
}

class _SunRaysState extends State<SunRays> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 40));

  @override
  void initState() {
    super.initState();
    if (widget.spin && !FxClock.lite.value) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: SunRaysPainter(
          color: widget.color,
          rays: widget.rays,
          opacity: widget.opacity,
          turn: _c.value * 2 * math.pi,
        ),
      ),
    ),
  );
}

class SunRaysPainter extends CustomPainter {
  const SunRaysPainter({required this.color, required this.rays, required this.opacity, required this.turn});

  final Color color;
  final int rays;
  final double opacity, turn;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final len = size.longestSide;
    final step = 2 * math.pi / rays;
    final fill = Paint()..color = color.withValues(alpha: opacity);
    for (var k = 0; k < rays; k++) {
      final a = turn + k * step;
      final half = step * .26;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a - half) * len, c.dy + math.sin(a - half) * len)
          ..lineTo(c.dx + math.cos(a + half) * len, c.dy + math.sin(a + half) * len)
          ..close(),
        fill,
      );
    }
    canvas.drawCircle(
      c,
      size.shortestSide * .55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity * 1.4),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: size.shortestSide * .55)),
    );
  }

  @override
  bool shouldRepaint(SunRaysPainter old) => old.turn != turn || old.color != color || old.opacity != opacity;
}

// ───────── الكروت الممزقة

/// أنواع الكروت على الطاولة: قرار أوفياء (أزرق)، قرار خونة (أحمر)، كومة السحب (أزرق مقلوب)، كومة الرمي (بنفسجي).
enum GameCardKind { loyal, traitor, draw, discard }

/// مسار مستطيل بحافة ممزقة (مثل الكروت في التصميم): نقط على المحيط تنزاح بشكل ثابت.
Path tornRect(Rect r, double radius, double jitter, int seed) {
  final base = Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)));
  final metric = base.computeMetrics().first;
  final step = math.max(4.0, r.shortestSide * .075);
  final n = (metric.length / step).floor();
  final out = Path();
  for (var i = 0; i < n; i++) {
    final t = metric.getTangentForOffset(metric.length * i / n)!;
    final nx = t.vector.dy, ny = -t.vector.dx;
    var j = (rnd(i, seed) - .5) * 2 * jitter;
    // نتفة أكبر هنا وهناك
    if (rnd(i, seed + 7) > .93) j -= jitter * 1.6;
    final p = t.position + Offset(nx, ny) * j;
    if (i == 0) {
      out.moveTo(p.dx, p.dy);
    } else {
      out.lineTo(p.dx, p.dy);
    }
  }
  return out..close();
}

/// وجه كرت بالتصميم الجديد. [stamp] (٠–١) لمشهد الختم: الرمز ينزل على الكرت من فوق.
/// [colors] يغلب ألوان النوع (مثل أشكال الكروت من المتجر): (حافة، جسم فوق، جسم تحت، رمز).
class GameCardFace extends StatelessWidget {
  const GameCardFace({
    super.key,
    required this.kind,
    this.width = 130,
    this.stamp,
    this.colors,
    this.emblem,
    this.glow = false,
  });

  final GameCardKind kind;
  final double width;
  final double? stamp;
  final (Color, Color, Color)? colors;

  /// رمز من المتجر (assets/icons/gfx_card_*.png) بدال الرمز الأصلي.
  final String? emblem;
  final bool glow;

  double get height => width * 1.46;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: CustomPaint(
      painter: GameCardPainter(kind: kind, stamp: stamp, colors: colors, glow: glow),
      child: emblem == null
          ? null
          : Align(
              alignment: const Alignment(0, -.04),
              child: Opacity(
                opacity: (stamp ?? 1).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1 + (1 - (stamp ?? 1)) * 1.6,
                  child: Image.asset('assets/icons/gfx_card_$emblem.png', width: width * .56, height: width * .56),
                ),
              ),
            ),
    ),
  );
}

class GameCardPainter extends CustomPainter {
  const GameCardPainter({required this.kind, this.stamp, this.colors, this.glow = false});

  final GameCardKind kind;
  final double? stamp;
  final (Color, Color, Color)? colors;
  final bool glow;

  /// (حافة الورق، جسم فوق، جسم تحت، لون الرمز).
  (Color, Color, Color, Color) get _palette => switch (kind) {
    GameCardKind.loyal || GameCardKind.draw => (
      const Color(0xFFD9B66C),
      const Color(0xFF4A74B0),
      const Color(0xFF2D5190),
      const Color(0xFFF4C447),
    ),
    GameCardKind.traitor => (
      const Color(0xFFE76B3A),
      const Color(0xFFD64A32),
      const Color(0xFFAE2C1C),
      const Color(0xFFFFE6C8),
    ),
    GameCardKind.discard => (
      const Color(0xFFB59A78),
      const Color(0xFF5B3A78),
      const Color(0xFF3F2559),
      const Color(0xFFC7A97E),
    ),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final u = w / 130;
    var (edge, top, bottom, mark) = _palette;
    if (colors case (final e, final t, final b)?) {
      edge = e;
      top = t;
      bottom = b;
    }
    final seed = kind.index * 11 + 3;
    final rect = Offset.zero & size;
    final outer = tornRect(rect.deflate(1.5 * u), 9 * u, 1.6 * u, seed);
    if (glow) {
      canvas.drawPath(
        outer,
        Paint()
          ..color = AppColors.gold.withValues(alpha: .8)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * u),
      );
    }
    canvas.drawPath(
      outer.shift(Offset(0, 3 * u)),
      Paint()
        ..color = Colors.black.withValues(alpha: .38)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.5 * u),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(edge, Colors.white, .22)!, edge, Color.lerp(edge, Colors.black, .22)!],
        ).createShader(rect),
    );
    // جسم الكرت
    final inset = 7.5 * u;
    final bodyRect = rect.deflate(inset);
    final body = RRect.fromRectAndRadius(bodyRect, Radius.circular(5 * u));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(bodyRect),
    );
    canvas.save();
    canvas.clipRRect(body);
    // بقع ورق قديم
    for (var i = 0; i < 9; i++) {
      final c = Offset(
        bodyRect.left + rnd(i, seed + 1) * bodyRect.width,
        bodyRect.top + rnd(i, seed + 2) * bodyRect.height,
      );
      final r = (8 + rnd(i, seed + 3) * 20) * u;
      canvas.drawOval(
        Rect.fromCenter(center: c, width: r * 2, height: r * (1.1 + rnd(i, seed + 4))),
        Paint()..color = (i.isEven ? Colors.white : Colors.black).withValues(alpha: .05 + .06 * rnd(i, seed + 5)),
      );
    }
    // تحبير خفيف على الأطراف
    canvas.drawRRect(
      body.deflate(1.2 * u),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * u
        ..color = Colors.black.withValues(alpha: .13)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * u),
    );
    canvas.restore();
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * u
        ..color = Colors.black.withValues(alpha: .55),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * u
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF2A1A10),
    );
    // الرمز
    final k = stamp ?? 1;
    if (k <= 0) return;
    canvas.save();
    canvas.translate(w / 2, size.height * .49);
    final sc = 1 + (1 - k) * 1.6;
    canvas.scale(sc);
    canvas.rotate((1 - k) * .9);
    final layer = k < 1 ? Rect.fromCenter(center: Offset.zero, width: w * 2, height: w * 2) : null;
    if (layer != null) canvas.saveLayer(layer, Paint()..color = Color.fromRGBO(255, 255, 255, k));
    switch (kind) {
      case GameCardKind.loyal || GameCardKind.draw:
        paintCompassStar(canvas, w * .36, mark, const Color(0xFF3D2A0A));
      case GameCardKind.traitor:
        paintCompassStar(canvas, w * .36, const Color(0xFF8E1A14), const Color(0xFF3B0A08), inner: false);
        paintDagger(canvas, w * .46);
      case GameCardKind.discard:
        paintCrest(canvas, w * .3, mark);
    }
    if (layer != null) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(GameCardPainter old) =>
      old.kind != kind || old.stamp != stamp || old.glow != glow || old.colors != colors;
}

/// نجمة بوصلة ثمانية (رمز كرت الأوفياء): الرؤوس الأربعة الرئيسية أطول من الباقي.
void paintCompassStar(Canvas canvas, double r, Color fill, Color edge, {bool inner = true}) {
  Path star(double scale, double rot) {
    final p = Path();
    for (var i = 0; i < 16; i++) {
      final a = rot + i * math.pi / 8 - math.pi / 2;
      final rr = (i.isEven ? (i % 4 == 0 ? 1.0 : .74) : .47) * r * scale;
      final pt = Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  final shape = star(1, 0);
  canvas.drawPath(shape.shift(Offset(0, r * .06)), Paint()..color = Colors.black.withValues(alpha: .35));
  canvas.drawPath(
    shape,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(fill, Colors.white, .35)!, fill, Color.lerp(fill, Colors.black, .35)!],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
  );
  canvas.drawPath(
    shape,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .045
      ..strokeJoin = StrokeJoin.round
      ..color = edge,
  );
  if (!inner) return;
  final small = star(.55, math.pi / 8);
  canvas.drawPath(small, Paint()..color = Color.lerp(fill, Colors.white, .45)!.withValues(alpha: .9));
  canvas.drawPath(
    small,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .03
      ..strokeJoin = StrokeJoin.round
      ..color = edge.withValues(alpha: .7),
  );
  canvas.drawCircle(Offset.zero, r * .13, Paint()..color = edge.withValues(alpha: .8));
}

/// خنجر عمودي (رمز كرت الخونة).
void paintDagger(Canvas canvas, double h) {
  final bw = h * .13;
  final blade = Path()
    ..moveTo(0, -h * .5)
    ..lineTo(bw, -h * .26)
    ..lineTo(bw * .9, h * .12)
    ..lineTo(-bw * .9, h * .12)
    ..lineTo(-bw, -h * .26)
    ..close();
  final hilt = Paint()..color = const Color(0xFFE9B23A);
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = h * .035
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0xFF3B0A08);
  canvas.drawPath(
    blade,
    Paint()
      ..shader = const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFD9D2C8), Color(0xFF9C9488)])
          .createShader(Rect.fromLTWH(-bw, -h * .5, bw * 2, h * .62)),
  );
  canvas.drawPath(blade, line);
  canvas.drawLine(
    Offset(0, -h * .45),
    Offset(0, h * .08),
    Paint()
      ..color = Colors.black.withValues(alpha: .18)
      ..strokeWidth = h * .02,
  );
  final guard = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(0, h * .15), width: h * .46, height: h * .08),
    Radius.circular(h * .04),
  );
  canvas.drawRRect(guard, hilt);
  canvas.drawRRect(guard, line);
  final grip = RRect.fromRectAndRadius(Rect.fromLTWH(-h * .045, h * .19, h * .09, h * .2), Radius.circular(h * .03));
  canvas.drawRRect(grip, hilt);
  canvas.drawRRect(grip, line);
  canvas.drawCircle(Offset(0, h * .43), h * .06, hilt);
  canvas.drawCircle(Offset(0, h * .43), h * .06, line);
}

/// شعار كومة الرمي: معين بلفة ريشة.
void paintCrest(Canvas canvas, double r, Color color) {
  final p = Path()
    ..moveTo(0, -r)
    ..lineTo(r * .9, 0)
    ..lineTo(0, r)
    ..lineTo(-r * .9, 0)
    ..close();
  canvas.drawPath(p, Paint()..color = color.withValues(alpha: .28));
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * .1
    ..strokeJoin = StrokeJoin.round
    ..color = color.withValues(alpha: .85);
  canvas.drawPath(p, stroke);
  canvas.drawPath(
    Path()
      ..moveTo(-r * .45, r * .5)
      ..quadraticBezierTo(-r * .1, -r * .2, r * .5, -r * .62)
      ..quadraticBezierTo(r * .55, -r * .05, -r * .05, r * .3)
      ..close(),
    Paint()..color = color.withValues(alpha: .9),
  );
  canvas.drawLine(Offset(-r * .55, r * .62), Offset(r * .15, -r * .1), stroke..strokeCap = StrokeCap.round);
}

// ───────── بطاقات التصويت

/// ورقة تصويت جنب اللاعب: رق بحد بني، علامة صح خضرا (موافق) أو غلط حمرا (رافض) وتحتها الكلمة.
class VoteBadgeCard extends StatelessWidget {
  const VoteBadgeCard({super.key, required this.yes, this.width = 96, this.label, this.icon});

  final bool yes;
  final double width;

  /// كلمة غير الافتراضية (مثل «ألغى» للقاضي).
  final String? label;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final color = yes ? const Color(0xFF2E9A3C) : const Color(0xFFD23A2E);
    final h = width * 1.25;
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * .14),
        color: const Color(0xFF3A2314),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .45), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: EdgeInsets.all(width * .035),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * .11),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEBD6A8), Color(0xFFD8BB86)],
          ),
          border: Border.all(color: const Color(0xFF8E6A3C), width: width * .02),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: width * .56,
              height: width * .5,
              child: icon ?? CustomPaint(painter: VoteMarkPainter(yes: yes)),
            ),
            SizedBox(height: width * .02),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label ?? (yes ? 'موافق' : 'رافض'),
                style: TextStyle(
                  fontFamily: kufi,
                  fontWeight: FontWeight.w800,
                  fontSize: width * .21,
                  color: color,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// علامة صح أو غلط كرتونية: خط سميك بحد غامق ولمعة.
class VoteMarkPainter extends CustomPainter {
  const VoteMarkPainter({required this.yes});

  final bool yes;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path();
    if (yes) {
      path
        ..moveTo(w * .08, h * .55)
        ..lineTo(w * .38, h * .88)
        ..lineTo(w * .94, h * .12);
    } else {
      path
        ..moveTo(w * .14, h * .1)
        ..lineTo(w * .86, h * .9)
        ..moveTo(w * .86, h * .1)
        ..lineTo(w * .14, h * .9);
    }
    final t = w * .2;
    Paint line(double width, Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = c;
    canvas.drawPath(path.shift(Offset(0, h * .03)), line(t + w * .07, Colors.black.withValues(alpha: .25)));
    canvas.drawPath(path, line(t + w * .07, yes ? const Color(0xFF12501A) : const Color(0xFF5A100C)));
    canvas.drawPath(path, line(t, yes ? const Color(0xFF3FBF4B) : const Color(0xFFE0382B)));
    canvas.drawPath(path.shift(Offset(-w * .02, -h * .03)), line(t * .3, Colors.white.withValues(alpha: .35)));
  }

  @override
  bool shouldRepaint(VoteMarkPainter old) => old.yes != yes;
}

// ───────── راية الخروج

/// راية حمرا معلقة فوق يمين (زر الخروج): أيقونة الباب وكلمة «خروج».
class ExitBanner extends StatelessWidget {
  const ExitBanner({super.key, required this.onTap, this.width = 64});

  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 1.28;
    return Semantics(
      button: true,
      label: 'خروج من اللعبة',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: h,
          child: CustomPaint(
            painter: const _BannerPainter(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(width * .08, h * .12, width * .08, h * .2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Gfx('exit', size: width * .52),
                  OutlinedText('خروج', size: width * .22, strokeWidth: math.max(2, width * .05)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  const _BannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cut = h * .12;
    final flag = Path()
      ..moveTo(1, 3)
      ..lineTo(w - 1, 3)
      ..lineTo(w - 1, h - 3)
      ..lineTo(w / 2, h - cut - 3)
      ..lineTo(1, h - 3)
      ..close();
    canvas.drawPath(
      flag.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: .4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      flag,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC8302E), Color(0xFFA32223), Color(0xFF7E1519)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      flag,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF3A0A0C),
    );
    canvas.drawPath(
      Path()
        ..moveTo(6, 9)
        ..lineTo(w - 6, 9)
        ..lineTo(w - 6, h - cut - 6)
        ..lineTo(w / 2, h - cut * 2 - 4)
        ..lineTo(6, h - cut - 6)
        ..close(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFF08A70).withValues(alpha: .6),
    );
    // عمود تعليق ذهبي فوق
    final rod = RRect.fromRectAndRadius(Rect.fromLTWH(-3, 0, w + 6, 6), const Radius.circular(3));
    canvas.drawRRect(rod, Paint()..color = const Color(0xFFD9A030));
    canvas.drawRRect(
      rod,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = gameInk,
    );
  }

  @override
  bool shouldRepaint(_BannerPainter old) => false;
}

// ───────── أيقونات مرسومة

/// ترس الإعدادات: ذهبي بحد غامق.
class GearIcon extends StatelessWidget {
  const GearIcon({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: const _GearPainter());
}

class _GearPainter extends CustomPainter {
  const _GearPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final path = Path();
    const teeth = 8;
    for (var i = 0; i < teeth * 2; i++) {
      final a0 = i * math.pi / teeth - math.pi / teeth / 2;
      final rr = i.isEven ? r * .98 : r * .74;
      final p0 = c + Offset(math.cos(a0), math.sin(a0)) * rr;
      final p1 = c + Offset(math.cos(a0 + math.pi / teeth * .55), math.sin(a0 + math.pi / teeth * .55)) * rr;
      i == 0 ? path.moveTo(p0.dx, p0.dy) : path.lineTo(p0.dx, p0.dy);
      path.lineTo(p1.dx, p1.dy);
    }
    path.close();
    final hole = Path()..addOval(Rect.fromCircle(center: c, radius: r * .34));
    final gear = Path.combine(PathOperation.difference, path, hole);
    canvas.drawPath(gear.shift(Offset(0, r * .06)), Paint()..color = Colors.black.withValues(alpha: .35));
    canvas.drawPath(
      gear,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE08A), Color(0xFFE5A32E), Color(0xFFB4741A)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      gear,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, r * .1)
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF4A2A08),
    );
  }

  @override
  bool shouldRepaint(_GearPainter old) => false;
}

/// خلفية دائرة لونها تدرج، لعلامات صغيرة (شارات الأعداد).
BoxDecoration gameBadgeDecoration(Color a, Color b) => BoxDecoration(
  shape: BoxShape.circle,
  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [a, b]),
  border: Border.all(color: gameInk, width: 2),
);
