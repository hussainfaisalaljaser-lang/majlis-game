import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../fx.dart';

export '../fx.dart' show glintAt, rnd, star4;

/// كل إطار له رسمتين: ورا الصورة وقدامها.
enum SigLayer { back, front }

/// اللحظات الخاصة للإطارات الأسطورية: حركة قصيرة لما يصير شي (يقعد على الطاولة، يصير رئيس، يفوز،
/// أو يفتح المعاينة في المتجر). المفتاح غالباً رقم اللاعب.
abstract final class Moments {
  static final events = ValueNotifier<(String, int)?>(null);

  static void trigger(String key) => events.value = (key, DateTime.now().microsecondsSinceEpoch);
}

/// كم تطول اللحظة الخاصة (ثواني).
const momentSeconds = 1.8;

/// الحد الغامق اللي حوالين كل شي في رسمات الفيديو (بني داكن مو أسود).
const ink = Color(0xFF2A1608);

double frac(double x) => x - x.floorToDouble();

double lerpD(double a, double b, double t) => a + (b - a) * t;

/// ضجيج ناعم (مجموع موجات) بين ٠ و١: للهب والوميض.
double noise(double x, int i) =>
    .5 + .25 * math.sin(x * 1.7 + i * 2.1) + .15 * math.sin(x * 3.3 + i * 1.3) + .1 * math.sin(x * 7.1 + i * .7);

Offset dir(double a) => Offset(math.cos(a), math.sin(a));

/// من ٠ لـ١ ويرجع ٠ (نص موجة).
double hump(double p) => p <= 0 || p >= 1 ? 0 : math.sin(p * math.pi);

/// بداية بطيئة ونهاية بطيئة (٠ لـ١).
double ease(double p) {
  final q = p.clamp(0.0, 1.0);
  return q * q * (3 - 2 * q);
}

/// مضلع مقفل من نقاط.
Path poly(List<Offset> pts) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final q in pts.skip(1)) {
    p.lineTo(q.dx, q.dy);
  }
  return p..close();
}

/// نجمة خماسية.
Path star5(Offset c, double size, {double inner = .45, double turn = -math.pi / 2}) =>
    poly([for (var i = 0; i < 10; i++) c + dir(turn + i * math.pi / 5) * (i.isEven ? size : size * inner)]);

/// نجمة ثمانية (مربعين فوق بعض).
Path star8(Offset c, double size, {double turn = 0}) =>
    poly([for (var i = 0; i < 16; i++) c + dir(turn + i * math.pi / 8) * (i.isEven ? size : size * .72)]);

/// عمودي على الاتجاه (لليسار).
Offset perp(Offset d) => Offset(-d.dy, d.dx);

/// اتجاه بطول ١.
Offset unit(Offset d) => d / d.distance;

/// يلف اتجاه بزاوية (مع عقارب الساعة على الشاشة).
Offset rot(Offset v, double a) =>
    Offset(v.dx * math.cos(a) - v.dy * math.sin(a), v.dx * math.sin(a) + v.dy * math.cos(a));

List<double> _even(int n) => [for (var i = 0; i < n; i++) n == 1 ? 0.0 : i / (n - 1)];

/// تدرج خطي بأي عدد ألوان (ui.Gradient يرمي خطأ لو الألوان أكثر من اثنين بدون نقاط، فنوزعها هنا).
Shader lin(Offset a, Offset b, List<Color> colors, [List<double>? stops]) =>
    ui.Gradient.linear(a, b, colors, stops ?? _even(colors.length));

/// تدرج دائري بأي عدد ألوان (ونقطة التركيز [focal] لو بغينا لمعة مايلة).
Shader radial(Offset c, double r, List<Color> colors, {List<double>? stops, Offset? focal, double focalRadius = 0}) =>
    ui.Gradient.radial(c, r, colors, stops ?? _even(colors.length), TileMode.clamp, null, focal, focalRadius);

/// تدرج يلف حوالين نقطة (للحلقات)، يبدأ من زاوية [turn].
Shader sweep(Offset c, List<Color> colors, {double turn = 0, List<double>? stops}) {
  final cs = [...colors, colors.first];
  final m = Matrix4.translationValues(c.dx, c.dy, 0) *
      Matrix4.rotationZ(turn) *
      Matrix4.translationValues(-c.dx, -c.dy, 0);
  return ui.Gradient.sweep(c, cs, stops ?? _even(cs.length), TileMode.clamp, 0, math.pi * 2, m.storage);
}

/// نبضة اللمعة: الحركة الخفيفة للإطارات النادرة تمشي دورة قصيرة كل كم ثانية وبعدها تقف على رسمة ثابتة.
/// [k] رقم الدورة، و[p] تقدمها (٠ لـ١، ويبقى ١ بعد ما تخلص)، و[u] = k + p بسلاسة: كل دورة تكمل خطوة
/// من الحركة (مثل دوران الرقائق) وتوقف على نفس الرسمة اللي تبدأ منها الدورة اللي بعدها.
class Beat {
  Beat(double t)
    : k = (t / glintEvery).floor(),
      p = (((t % glintEvery) / glintFor)).clamp(0.0, 1.0);

  final int k;
  final double p;

  double get u => k + ease(p);

  /// تقدم مقطع من النبضة بين [from] و[to] (٠ لـ١).
  double win(double from, double to) => ((p - from) / (to - from)).clamp(0.0, 1.0);

  /// هل النبضة ماشية الحين.
  bool get active => p > 0 && p < 1;
}

/// رسام إطار: طبقة ورا الصورة وطبقة قدامها، على لوحة بحجم الصورة مع حلقتها (ويقدر يطلع برا شوي).
abstract class FrameArt extends CustomPainter {
  FrameArt(this.time, {required this.avatar, required this.layer, this.moment})
    : super(repaint: moment == null ? time : Listenable.merge([time, moment]));

  final ValueListenable<double> time;

  /// قطر الصورة.
  final double avatar;
  final SigLayer layer;

  /// وقت بداية اللحظة الخاصة (بنفس ساعة [time])، أو null.
  final ValueListenable<double?>? moment;

  double get r => avatar / 2;

  /// سماكة الحلقة.
  double get ring => math.max(2.5, avatar * .075);

  /// نص الحلقة (من المركز).
  double get mid => r + ring / 2;

  /// صغيرة (على الطاولة): تفاصيل أقل.
  bool get small => avatar < 80;

  /// أرفع خط يبان على هالحجم.
  double get hair => math.max(.6, avatar * .008);

  /// سماكة الحد الغامق اللي حوالين الأشكال (مثل الفيديو).
  double get lw => math.max(1.0, avatar * .017);

  /// تقدم اللحظة الخاصة بين ٠ و١، أو null لو ما فيه لحظة.
  double? burst(double t) {
    final m = moment?.value;
    if (m == null) return null;
    final p = (t - m) / momentSeconds;
    return p >= 0 && p <= 1 ? p : null;
  }

  void back(Canvas canvas, Offset c, double t) {}

  void front(Canvas canvas, Offset c, double t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (layer == SigLayer.back) {
      back(canvas, c, time.value);
    } else {
      front(canvas, c, time.value);
    }
  }

  @override
  bool shouldRepaint(FrameArt old) =>
      old.runtimeType != runtimeType ||
      old.avatar != avatar ||
      old.layer != layer ||
      old.time != time ||
      old.moment != moment;

  // ───── أدوات رسم مشتركة ─────

  /// مكان على دائرة: زاوية [a] وبعد [d] من المركز.
  Offset at(Offset c, double a, double d) => c + dir(a) * d;

  /// حلقة بتدرج يلف حوالين الدائرة.
  void sweepRing(Canvas canvas, Offset c, List<Color> colors, {double turn = 0, double? width, double? radius}) {
    final rad = radius ?? mid;
    canvas.drawCircle(
      c,
      rad,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width ?? ring
        ..shader = sweep(c, colors, turn: turn),
    );
  }

  /// خط رفيع حول الدائرة (حواف الحلقة).
  void line(Canvas canvas, Offset c, double radius, Color color, {double? width}) {
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width ?? hair
        ..color = color,
    );
  }

  /// توهج ناعم على شكل حلقة.
  void glowRing(Canvas canvas, Offset c, Color color, {double radius = 0, double width = 0, double blur = 0}) {
    canvas.drawCircle(
      c,
      radius == 0 ? mid : radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width == 0 ? ring * 1.8 : width
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur == 0 ? ring : blur),
    );
  }

  /// هالة دائرية بتدرج (أرخص من البلور).
  void halo(Canvas canvas, Offset c, double radius, List<Color> colors, {List<double>? stops}) {
    canvas.drawCircle(c, radius, Paint()..shader = radial(c, radius, colors, stops: stops));
  }

  /// لمعة نجمة بأربع رؤوس مع توهجها.
  void sparkle(Canvas canvas, Offset p, double size, Color color, double alpha) {
    if (alpha <= 0) return;
    canvas.drawPath(
      star4(p, size * 1.9),
      Paint()
        ..color = color.withValues(alpha: .3 * alpha)
        ..blendMode = BlendMode.plus,
    );
    canvas.drawPath(star4(p, size), Paint()..color = Colors.white.withValues(alpha: alpha));
  }

  /// نقطة ضو (قلب أبيض وهالة ملونة).
  void dot(Canvas canvas, Offset p, double size, Color color, double alpha) {
    if (alpha <= 0) return;
    final paint = Paint()..blendMode = BlendMode.plus;
    paint.color = color.withValues(alpha: .35 * alpha);
    canvas.drawCircle(p, size * 2.4, paint);
    paint.color = Color.lerp(Colors.white, color, .35)!.withValues(alpha: alpha);
    canvas.drawCircle(p, size, paint);
  }

  // ───── رسم كرتوني: حد غامق، ظل بدرجتين، لمعة ─────

  /// شكل معبّا بلون أو تدرج وحوله حد غامق.
  void inked(Canvas canvas, Path path, {Color? fill, Shader? shader, Color edge = ink, double? w, double alpha = 1}) {
    final f = Paint();
    if (shader != null) {
      f.shader = shader;
    } else {
      f.color = fill!;
    }
    canvas.drawPath(path, f);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w ?? lw
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = edge,
    );
  }

  /// حلقة سميكة من نصف قطر [r0] لـ[r1] بتعبئة [shader] وحد غامق على الحافتين.
  void band(
    Canvas canvas,
    Offset c,
    double r0,
    double r1,
    Shader shader, {
    Color edge = ink,
    double? w,
    bool outer = true,
    bool inner = true,
  }) {
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: c, radius: r1))
        ..addOval(Rect.fromCircle(center: c, radius: r0)),
      Paint()..shader = shader,
    );
    final e = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w ?? lw
      ..color = edge;
    if (outer) canvas.drawCircle(c, r1, e);
    if (inner) canvas.drawCircle(c, r0, e);
  }

  /// تدرج ذهب للحلقات: فاتح فوق وغامق تحت (مثل حلقة الواحة في الفيديو).
  Shader goldShader(Offset c, double rad) => lin(
    c + Offset(-rad * .35, -rad),
    c + Offset(rad * .35, rad),
    const [Color(0xFFFFE98A), Color(0xFFF6BE3E), Color(0xFFD38A1F), Color(0xFF9B5A12)],
    const [0, .3, .72, 1],
  );

  /// قوس لمعة بيضاء (انعكاس على الحلقة).
  void gloss(
    Canvas canvas,
    Offset c,
    double radius,
    double width, {
    double from = -2.5,
    double span = 1.1,
    double alpha = .6,
    Color color = Colors.white,
  }) {
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: radius),
      from,
      span,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: alpha),
    );
  }

  /// كرة مجسمة (لؤلؤة، جوهرة، مسمار): تدرج دائري مايل، حد غامق، ولمعة صغيرة فوق اليسار.
  void ball(
    Canvas canvas,
    Offset p,
    double rad,
    Color light,
    Color base,
    Color dark, {
    Color edge = ink,
    double? w,
    double shine = .85,
  }) {
    canvas.drawCircle(
      p,
      rad,
      Paint()..shader = radial(p + Offset(-rad * .3, -rad * .35), rad * 1.25, [light, base, dark], stops: const [0, .5, 1]),
    );
    canvas.drawCircle(
      p,
      rad,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w ?? lw
        ..color = edge,
    );
    if (shine > 0 && rad > 1.6) {
      canvas.drawOval(
        Rect.fromCenter(center: p + Offset(-rad * .33, -rad * .4), width: rad * .55, height: rad * .38),
        Paint()..color = Colors.white.withValues(alpha: shine),
      );
    }
  }

  /// نقاط صغيرة على الحلقة (مسامير، حبّات).
  void studs(Canvas canvas, Offset c, double radius, int n, double size, Color light, Color base, Color dark,
      {double turn = 0, Color edge = ink}) {
    for (var i = 0; i < n; i++) {
      ball(canvas, at(c, turn + i * 2 * math.pi / n, radius), size, light, base, dark, edge: edge, w: lw * .7);
    }
  }

  /// لمعات بيضاء بأماكن عشوائية حول الحلقة: كل لمعة تطلع وتختفي بدورها. [u] وقت مستمر،
  /// و[n] عددها، وبين [rIn] و[rOut] من نصف القطر (مضروبين في [r]).
  void twinkles(
    Canvas canvas,
    Offset c,
    double u, {
    int n = 4,
    double rIn = 1.08,
    double rOut = 1.5,
    double size = 0,
    double speed = 1,
    Color color = Colors.white,
    int salt = 0,
  }) {
    final s = size == 0 ? math.max(1.6, avatar * .045) : size;
    for (var i = 0; i < n; i++) {
      final x = u * speed * (.55 + rnd(i, 70 + salt) * .4) + rnd(i, 71 + salt) * 7;
      final cyc = x.floor();
      final ph = frac(x);
      final a = math.pow(hump(ph), 1.4).toDouble();
      if (a <= 0) continue;
      final seed = i * 31 + cyc * 7 + salt;
      final pos = at(c, rnd(seed, 72) * math.pi * 2, r * lerpD(rIn, rOut, rnd(seed, 73)));
      sparkle(canvas, pos, s * (.6 + rnd(seed, 74) * .8) * (.7 + .3 * a), color, a);
    }
  }

  /// قوس ضو يمر على الحلقة (انعكاس) من زاوية [ang]، يطول [span] راديان.
  void sheen(Canvas canvas, Offset c, double ang, double alpha, {double? radius, double? width, double span = 1.0}) {
    if (alpha <= 0) return;
    gloss(
      canvas,
      c,
      radius ?? mid,
      width ?? ring * .5,
      from: ang - span / 2,
      span: span,
      alpha: alpha,
    );
  }

  /// لسان لهب: قاعدته [base] ويطلع باتجاه [up] بطول [h] وعرض [w]، وراسه يميل [lean] ويلتوي [kink].
  Path flameTongue(Offset base, Offset up, double h, double w, double lean, {double kink = 0}) {
    final n = perp(up);
    final tip = base + up * h + n * lean;
    final l = base - n * w / 2, rr = base + n * w / 2;
    return Path()
      ..moveTo(l.dx, l.dy)
      ..cubicTo(
        l.dx + up.dx * h * .3 - n.dx * w * .3 + n.dx * kink,
        l.dy + up.dy * h * .3 - n.dy * w * .3 + n.dy * kink,
        base.dx + up.dx * h * .72 + n.dx * (lean * .55 - w * .1),
        base.dy + up.dy * h * .72 + n.dy * (lean * .55 - w * .1),
        tip.dx,
        tip.dy,
      )
      ..cubicTo(
        base.dx + up.dx * h * .6 + n.dx * (lean * .35 + w * .55 + kink),
        base.dy + up.dy * h * .6 + n.dy * (lean * .35 + w * .55 + kink),
        rr.dx + up.dx * h * .25 + n.dx * w * .3,
        rr.dy + up.dy * h * .25 + n.dy * w * .3,
        rr.dx,
        rr.dy,
      )
      ..close();
  }

  /// سعفة نخل: من [base] باتجاه [angle] بطول [len] وعرض [wid]، وتنحني لتحت [droop]، وحافتها مسننة.
  Path frond(Offset base, double angle, double len, double wid, {double droop = .35, int teeth = 6, double notch = .55}) {
    final d = dir(angle);
    final tip = base + d * len + Offset(0, len * droop);
    final ctrl = base + d * len * .6 - Offset(0, len * .12);
    Offset spine(double s) {
      final q = 1 - s;
      return base * (q * q) + ctrl * (2 * q * s) + tip * (s * s);
    }

    final up = <Offset>[], down = <Offset>[];
    final m = teeth * 2;
    for (var i = 1; i <= m; i++) {
      final s = i / m;
      final a = spine(s - .001), b = spine(math.min(1, s + .001));
      final n = perp(unit(b - a));
      final w = wid * math.sin(math.pi * math.pow(s, .7).toDouble()) * (i.isOdd ? 1 : notch);
      up.add(spine(s) + n * w);
      down.add(spine(s) - n * w);
    }
    final p = Path()..moveTo(base.dx, base.dy);
    for (final q in up) {
      p.lineTo(q.dx, q.dy);
    }
    p.lineTo(tip.dx, tip.dy);
    for (final q in down.reversed) {
      p.lineTo(q.dx, q.dy);
    }
    return p..close();
  }

  /// خط متعرج (برق) من [a] لـ[b] بـ[n] قطع، وانحرافه [amp]، ويتغير بتغير [seed].
  Path zigzag(Offset a, Offset b, int n, double amp, int seed) {
    final d = b - a;
    final nn = perp(unit(d));
    final p = Path()..moveTo(a.dx, a.dy);
    for (var i = 1; i < n; i++) {
      final q = a + d * (i / n) + nn * ((rnd(seed + i, 91) - .5) * 2 * amp);
      p.lineTo(q.dx, q.dy);
    }
    return p..lineTo(b.dx, b.dy);
  }

  /// شرار يطير لبرا من المركز وقت اللحظة الخاصة [m] (٠ لـ١).
  void burstSparks(Canvas canvas, Offset c, double m, List<Color> colors, {int n = 20, double from = 1}) {
    final e = Curves.easeOutCubic.transform(m);
    final fade = 1 - m;
    final size = math.max(1, avatar * .016);
    for (var i = 0; i < n; i++) {
      final a = i * math.pi * 2 / n + rnd(i, 31) * .4;
      final dist = r * (from + e * (.55 + rnd(i, 32) * .7));
      final pos = c + dir(a) * dist;
      final col = colors[i % colors.length];
      canvas.drawLine(
        pos,
        c + dir(a) * (dist - r * .18 * fade),
        Paint()
          ..color = col.withValues(alpha: .5 * fade)
          ..strokeWidth = size * .6
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        pos,
        size * (1.4 - e),
        Paint()
          ..color = col.withValues(alpha: fade)
          ..blendMode = BlendMode.plus,
      );
    }
  }
}

/// الإطارات النادرة: رسمة ثابتة (مثل الفيديو)، وكل كم ثانية تتحرك نبضة قصيرة [Beat]:
/// لمعة تمر على الحلقة، ولمعات نجوم، وحركة خاصة بكل إطار (رقائق تدور، سعف يتمايل…).
abstract class RareFrame extends FrameArt {
  RareFrame(super.time, {required super.avatar, required super.layer, super.moment});

  /// لون اللمعة.
  Color get shine => Colors.white;

  /// زاوية بداية مرور لمعة الحلقة (تلف لفة كاملة بالنبضة).
  double get sheenStart => -math.pi * .9;

  /// لمعة الحلقة تمر؟ (الإطارات اللي حلقتها مو مصقولة تطفيها).
  bool get sheens => true;

  /// عدد لمعات النجوم في كل نبضة.
  int get twinkleCount => 4;

  /// المدى اللي تظهر فيه لمعات النجوم (مضروب في نصف القطر).
  (double, double) get twinkleRange => (1.1, 1.55);

  /// خلفية ورا الصورة (هالة، نخل خلف الحلقة…).
  void artBack(Canvas canvas, Offset c, Beat b) {}

  /// رسمة الإطار فوق الصورة.
  void art(Canvas canvas, Offset c, Beat b);

  @override
  void back(Canvas canvas, Offset c, double t) => artBack(canvas, c, Beat(t));

  @override
  void front(Canvas canvas, Offset c, double t) {
    final b = Beat(t);
    art(canvas, c, b);
    if (!b.active) return;
    if (sheens) {
      final ang = sheenStart + ease(b.win(0, .8)) * math.pi * 2;
      sheen(canvas, c, ang, .75 * hump(b.win(0, .8)));
    }
    final (lo, hi) = twinkleRange;
    for (var i = 0; i < twinkleCount; i++) {
      final s = rnd(i + b.k * 5, 80) * .45;
      final a = hump(b.win(s, s + .5));
      if (a <= 0) continue;
      final seed = i + b.k * 5;
      final pos = at(c, rnd(seed, 81) * math.pi * 2, r * lerpD(lo, hi, rnd(seed, 82)));
      sparkle(canvas, pos, math.max(1.8, avatar * .05) * (.7 + rnd(seed, 83) * .7), shine, a);
    }
  }
}
