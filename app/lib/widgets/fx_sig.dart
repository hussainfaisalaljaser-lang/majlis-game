import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/shop.dart';
import 'fx.dart';

/// رسومات الإطارات الخاصة: كل إطار ملحمي وأسطوري له رسمة وحركة ما تتكرر في غيره
/// (بدال خلطة الحركات العامة في [FramePainter]). كل رسمة طبقتين: ورا الصورة وقدامها.
enum SigLayer { back, front }

/// اللحظات الخاصة للإطارات الأسطورية: انفجار قصير لما يصير شي (يقعد على الطاولة، يصير رئيس، يفوز،
/// أو يفتح المعاينة في المتجر). المفتاح غالباً رقم اللاعب.
abstract final class Moments {
  static final events = ValueNotifier<(String, int)?>(null);

  static void trigger(String key) => events.value = (key, DateTime.now().microsecondsSinceEpoch);
}

/// كم تطول اللحظة الخاصة (ثواني).
const momentSeconds = 1.8;

/// رسام الإطار الخاص حسب [FrameStyle.sig]، أو null لو الإطار عادي.
CustomPainter? sigFramePainter(
  FrameStyle style,
  ValueListenable<double> time, {
  required double avatar,
  required SigLayer layer,
  ValueListenable<double?>? moment,
}) => switch (style.sig) {
  'fire' => FireFrame(time, avatar: avatar, layer: layer),
  'galaxy' => GalaxyFrame(time, avatar: avatar, layer: layer, moment: moment),
  _ => null,
};

double _frac(double x) => x - x.floorToDouble();

/// ضجيج ناعم (مجموع موجات) بين ٠ و١: للهب والوميض.
double _noise(double x, int i) =>
    .5 + .25 * math.sin(x * 1.7 + i * 2.1) + .15 * math.sin(x * 3.3 + i * 1.3) + .1 * math.sin(x * 7.1 + i * .7);

Offset _dir(double a) => Offset(math.cos(a), math.sin(a));

// ═════════════ نار (ملحمي) ═════════════

/// نار: ألسنة لهب تطلع من الحلقة وتميل لفوق (أطول فوق وأقصر تحت)، وتوهج حرارة،
/// وشرار يطير لفوق ويختفي. الحلقة نفسها جمر يغلي.
class FireFrame extends CustomPainter {
  FireFrame(this.time, {required this.avatar, required this.layer}) : super(repaint: time);

  final ValueListenable<double> time;

  /// قطر الصورة.
  final double avatar;
  final SigLayer layer;

  static const _white = Color(0xFFFFF8E1);
  static const _yellow = Color(0xFFFFD54F);
  static const _orange = Color(0xFFFF8F00);
  static const _red = Color(0xFFE53935);
  static const _deep = Color(0xFF8E1B10);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final c = size.center(Offset.zero);
    final r = avatar / 2;
    final ring = math.max(2.5, avatar * .075);
    if (layer == SigLayer.back) {
      _halo(canvas, c, r, t);
      _tongues(canvas, c, r, t, ring, back: true);
    } else {
      _ring(canvas, c, r, t, ring);
      _tongues(canvas, c, r, t, ring, back: false);
      _embers(canvas, c, r, t);
    }
  }

  void _halo(Canvas canvas, Offset c, double r, double t) {
    final flicker = .8 + .2 * _noise(t * 2.2, 3);
    canvas.drawCircle(
      c,
      r * 1.62,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _orange.withValues(alpha: .55 * flicker),
            _red.withValues(alpha: .28 * flicker),
            _red.withValues(alpha: 0),
          ],
          stops: const [.58, .78, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.62)),
    );
  }

  /// لسان لهب (قطرة مقلوبة): قاعدة مدوّرة، وراس يتمايل.
  static void _addTongue(Path path, Offset base, Offset dir, double h, double width, double sway) {
    final side = Offset(-dir.dy, dir.dx);
    final tip = base + dir * h + side * sway;
    final l = base - side * width / 2, rr = base + side * width / 2;
    final c1 = base + dir * h * .38 - side * width * .62 + side * sway * .15;
    final c2 = base + dir * h * .74 - side * width * .18 + side * sway * .65;
    final c3 = base + dir * h * .74 + side * width * .18 + side * sway * .65;
    final c4 = base + dir * h * .38 + side * width * .62 + side * sway * .15;
    final bottom = base - dir * width * .4;
    path
      ..moveTo(l.dx, l.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, tip.dx, tip.dy)
      ..cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, rr.dx, rr.dy)
      ..quadraticBezierTo(bottom.dx, bottom.dy, l.dx, l.dy)
      ..close();
  }

  /// النار بثلاث طبقات، كل طبقة مسار واحد: حمرا ناعمة برا (ورا الصورة)، وبرتقالية، وصفرا بيضا جوا.
  /// الألسنة أطول فوق وأقصر تحت، وتميل لفوق، وتطلع منها شعل صغيرة تطير وتختفي.
  void _tongues(Canvas canvas, Offset c, double r, double t, double ring, {required bool back}) {
    final n = avatar < 80 ? 13 : 18;
    final layers = back ? const [(1.0, 0)] : const [(.68, 1), (.4, 2)];
    for (final (k, layer) in layers) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final a = i * math.pi * 2 / n + rnd(i, 9) * .25;
        final up = (1 - math.sin(a)) / 2;
        final reach = .22 + .78 * up * up;
        final flick = .55 + .45 * _noise(t * 2.8 + i * .9, i);
        final h = r * .78 * reach * flick * k;
        if (h < r * .05) continue;
        final radial = _dir(a);
        final dir = Offset(radial.dx * .55, radial.dy * .55 - .85);
        final d = dir / dir.distance;
        final base = c + radial * (r + ring * (.3 + .2 * layer));
        final sway = (math.sin(t * 3.6 + i * 1.9) * .18 + math.sin(t * 7.3 + i) * .05) * h;
        final width = r * (.34 + .12 * rnd(i, 4)) * (.8 + .2 * flick) * (.55 + .45 * k);
        _addTongue(path, base, d, h, width, sway);
        // شعلة صغيرة تنفصل من الألسنة الفوقانية وتطير
        if (up > .55 && layer < 2) {
          final p = _frac(t * .9 + rnd(i, 6));
          final wisp = base + d * h * (.85 + p * .5) + Offset(math.sin(p * 5 + i) * r * .04, -p * r * .28);
          final wh = r * .16 * k * (1 - p);
          if (wh > r * .02) _addTongue(path, wisp, const Offset(0, -1), wh, wh * .55, math.sin(t * 6 + i) * wh * .3);
        }
      }
      final rect = Rect.fromCircle(center: c, radius: r * 1.8);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: switch (layer) {
            0 => [_orange, _red, _deep.withValues(alpha: .85), _deep.withValues(alpha: 0)],
            1 => [_yellow, _orange.withValues(alpha: .9), _red.withValues(alpha: .4), _red.withValues(alpha: 0)],
            _ => [_white, _yellow.withValues(alpha: .9), _orange.withValues(alpha: .25), _orange.withValues(alpha: 0)],
          },
          stops: switch (layer) {
            0 => const [.5, .66, .82, 1],
            1 => const [.52, .64, .76, .9],
            _ => const [.54, .6, .68, .76],
          },
        ).createShader(rect);
      if (layer == 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(.6, r * .035));
      } else {
        paint.blendMode = BlendMode.plus;
      }
      canvas.drawPath(path, paint);
    }
  }

  void _ring(Canvas canvas, Offset c, double r, double t, double ring) {
    final rect = Rect.fromCircle(center: c, radius: r + ring);
    final mid = r + ring / 2;
    // الجمر: ألوان تمشي ببطء حول الحلقة
    canvas.drawCircle(
      c,
      mid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring
        ..shader = SweepGradient(
          colors: const [_deep, _red, _orange, _yellow, _orange, _red, _deep, _red, _orange, _deep],
          transform: GradientRotation(t * .35),
        ).createShader(rect),
    );
    // خط حار داخل الحلقة يرجف
    final hot = .55 + .45 * _noise(t * 5, 7);
    canvas.drawCircle(
      c,
      mid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, ring * .28)
        ..color = _yellow.withValues(alpha: .35 + .45 * hot)
        ..blendMode = BlendMode.plus,
    );
    // حافة غامقة داخلية تعطي عمق
    canvas.drawCircle(
      c,
      r + math.max(.5, ring * .08),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, ring * .2)
        ..color = Colors.black.withValues(alpha: .45),
    );
  }

  void _embers(Canvas canvas, Offset c, double r, double t) {
    final n = avatar < 80 ? 10 : 18;
    final p = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < n; i++) {
      final speed = .35 + rnd(i, 2) * .3;
      final life = _frac(t * speed + rnd(i, 1));
      // تبدأ من النص الفوقاني غالباً
      final a = -math.pi / 2 + (rnd(i, 3) - .5) * math.pi * 1.5;
      final start = c + _dir(a) * r * 1.05;
      final pos =
          start +
          Offset(
            math.sin(life * 6 + i) * r * .07 + (rnd(i, 4) - .5) * r * .3 * life,
            -life * r * (.7 + rnd(i, 5) * .6),
          );
      final fade = life < .15 ? life / .15 : 1 - (life - .15) / .85;
      final s = math.max(.9, avatar * .016) * (1.1 - life * .6);
      final col = Color.lerp(_yellow, _red, life)!;
      p.color = col.withValues(alpha: .35 * fade);
      canvas.drawCircle(pos, s * 2.4, p);
      p.color = Color.lerp(_white, col, life)!.withValues(alpha: .95 * fade);
      canvas.drawCircle(pos, s, p);
    }
  }

  @override
  bool shouldRepaint(FireFrame old) => old.avatar != avatar || old.layer != layer;
}

// ═════════════ مجرة (أسطوري) ═════════════

/// مجرة: سديم ملوّن وأذرع مجرة حلزونية من نجوم تدور ورا الصورة، وكوكبين يلفون حولها (يمرون
/// قدامها وورها)، ونجوم تلمع. اللحظة الخاصة: انفجار نجمي (ومضة وموجة تنتشر وشرار يطير).
class GalaxyFrame extends CustomPainter {
  GalaxyFrame(this.time, {required this.avatar, required this.layer, this.moment})
    : super(repaint: Listenable.merge([time, ?moment]));

  final ValueListenable<double> time;
  final double avatar;
  final SigLayer layer;

  /// وقت بداية اللحظة الخاصة (بنفس ساعة [time])، أو null.
  final ValueListenable<double?>? moment;

  static const _violet = Color(0xFF7C4DFF);
  static const _pink = Color(0xFFFF4081);
  static const _cyan = Color(0xFF18FFFF);
  static const _ice = Color(0xFFE0F7FF);

  /// تقدم اللحظة الخاصة بين ٠ و١، أو null لو ما فيه لحظة.
  double? _burst(double t) {
    final m = moment?.value;
    if (m == null) return null;
    final p = (t - m) / momentSeconds;
    return p >= 0 && p <= 1 ? p : null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final c = size.center(Offset.zero);
    final r = avatar / 2;
    final ring = math.max(2.5, avatar * .07);
    final burst = _burst(t);
    // اللحظة: الأذرع تنتفخ وتضوي وترجع
    final swell = burst == null ? 0.0 : math.sin(burst * math.pi);
    if (layer == SigLayer.back) {
      _nebula(canvas, c, r, t, swell);
      _arms(canvas, c, r, t, swell);
      _planets(canvas, c, r, t, front: false);
    } else {
      _ring(canvas, c, r, t, ring, swell);
      _planets(canvas, c, r, t, front: true);
      _twinkles(canvas, c, r, t);
      if (burst != null) _supernova(canvas, c, r, ring, burst);
    }
  }

  void _nebula(Canvas canvas, Offset c, double r, double t, double swell) {
    final blobs = [(_violet, 0.0, .5), (_pink, 2.1, .38), (_cyan, 4.2, .3)];
    for (final (col, phase, alpha) in blobs) {
      final a = t * .18 + phase;
      final pos = c + _dir(a) * r * .32;
      final rad = r * (1.55 + .12 * math.sin(t * .7 + phase) + swell * .35);
      canvas.drawCircle(
        pos,
        rad,
        Paint()
          ..shader = RadialGradient(
            colors: [
              col.withValues(alpha: alpha * (1 + swell * .6)),
              col.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: pos, radius: rad)),
      );
    }
  }

  /// أذرع المجرة: كل ذراع خط حلزوني مضيء (توهج + خط ملوّن يخف لآخره) وعليه نجوم تلمع.
  void _arms(Canvas canvas, Offset c, double r, double t, double swell) {
    const arms = 3;
    const steps = 26;
    final stars = avatar < 80 ? 7 : 12;
    final p = Paint()..blendMode = BlendMode.plus;
    for (var k = 0; k < arms; k++) {
      final path = Path();
      Offset at(double f) {
        final a = k * math.pi * 2 / arms + f * 2.5 + t * .22;
        return c + _dir(a) * r * (.97 + f * (.62 + swell * .32));
      }

      for (var j = 0; j <= steps; j++) {
        final q = at(j / steps);
        j == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
      }
      final from = at(0), to = at(1);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * (.2 + swell * .1)
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [
              _violet.withValues(alpha: .45 + swell * .3),
              _pink.withValues(alpha: .25),
              _pink.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromPoints(from, to))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .08)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, r * .045)
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [
              _ice.withValues(alpha: .95),
              _cyan.withValues(alpha: .7),
              _violet.withValues(alpha: .45),
              _pink.withValues(alpha: 0),
            ],
            stops: const [0, .25, .6, 1],
          ).createShader(Rect.fromPoints(from, to))
          ..blendMode = BlendMode.plus,
      );
      for (var j = 0; j < stars; j++) {
        final f = (j + rnd(j, k + 3) * .6) / stars;
        final tw = math.pow((math.sin(t * 3.2 + j * 2.3 + k * 1.1) + 1) / 2, 2).toDouble();
        final q = at(f) + _dir(rnd(j, k + 7) * math.pi * 2) * r * .05;
        final s = math.max(.7, avatar * .012) * (1.3 - f * .6) * (.7 + tw * .6);
        p.color = Colors.white.withValues(alpha: (.35 + .65 * tw) * (1 - f * .5));
        canvas.drawCircle(q, s, p);
      }
    }
    // غبار نجوم خفيف بين الأذرع
    final dust = avatar < 80 ? 12 : 22;
    for (var i = 0; i < dust; i++) {
      final a = rnd(i, 11) * math.pi * 2 + t * (.1 + rnd(i, 12) * .08);
      final rad = r * (1.04 + rnd(i, 13) * .55);
      final tw = (math.sin(t * 2.4 + i * 1.3) + 1) / 2;
      p.color = _ice.withValues(alpha: .2 + .5 * tw);
      canvas.drawCircle(c + _dir(a) * rad, math.max(.5, avatar * .006), p);
    }
  }

  /// مكان الكوكب على مداره المايل، وهل هو قدام الصورة.
  (Offset, double, bool) _orbit(Offset c, double r, double a, double rx, double ry, double tilt) {
    final x = math.cos(a) * r * rx, y = math.sin(a) * r * ry;
    final pos = c + Offset(x * math.cos(tilt) - y * math.sin(tilt), x * math.sin(tilt) + y * math.cos(tilt));
    return (pos, math.sin(a), math.sin(a) > 0);
  }

  void _planets(Canvas canvas, Offset c, double r, double t, {required bool front}) {
    // الكوكب الكبير بحلقة (مثل زحل)
    final (p1, d1, f1) = _orbit(c, r, t * .5, 1.36, .66, -.28);
    if (f1 == front) _giant(canvas, p1, avatar * .075 * (1 + .18 * d1), d1);
    // قمر صغير
    final (p2, d2, f2) = _orbit(c, r, -t * .85 + 2.2, 1.24, .6, .32);
    if (f2 == front) {
      final s = avatar * .035 * (1 + .2 * d2);
      canvas.drawCircle(
        p2,
        s,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.4, -.5),
            colors: const [Colors.white, _cyan, Color(0xFF006064)],
          ).createShader(Rect.fromCircle(center: p2, radius: s)),
      );
      canvas.drawCircle(
        p2,
        s * 2.6,
        Paint()
          ..color = _cyan.withValues(alpha: .18)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  void _giant(Canvas canvas, Offset p, double s, double depth) {
    final ringRect = Rect.fromCenter(center: p, width: s * 4.2, height: s * 1.25);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.7, s * .32)
      ..color = const Color(0xFFFFE0B2).withValues(alpha: .85);
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(-.35);
    canvas.translate(-p.dx, -p.dy);
    // نص الحلقة اللي ورا الكوكب
    canvas.drawArc(ringRect, math.pi, math.pi, false, ringPaint);
    canvas.drawCircle(
      p,
      s,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.45),
          colors: [Color(0xFFFFE0F0), _pink, Color(0xFF6A1B9A)],
          stops: [0, .5, 1],
        ).createShader(Rect.fromCircle(center: p, radius: s)),
    );
    // خطوط الكوكب
    final band = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.5, s * .18)
      ..color = Colors.white.withValues(alpha: .18);
    canvas.drawArc(Rect.fromCircle(center: p, radius: s * .8), .3, 2.4, false, band);
    // نص الحلقة اللي قدامه
    canvas.drawArc(ringRect, 0, math.pi, false, ringPaint);
    canvas.restore();
  }

  void _ring(Canvas canvas, Offset c, double r, double t, double ring, double swell) {
    final rect = Rect.fromCircle(center: c, radius: r + ring);
    final mid = r + ring / 2;
    canvas.drawCircle(
      c,
      mid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring * 1.9
        ..color = _violet.withValues(alpha: .35 + swell * .4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring * (1 + swell)),
    );
    canvas.drawCircle(
      c,
      mid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring
        ..shader = SweepGradient(
          colors: const [Color(0xFF1A0B3D), _violet, _pink, Color(0xFF1A0B3D), _cyan, _violet, Color(0xFF1A0B3D)],
          transform: GradientRotation(t * .6),
        ).createShader(rect),
    );
    // نجوم صغيرة على الحلقة تلمع
    final p = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi * 2 / 10 + t * .6;
      final tw = math.pow((math.sin(t * 4 + i * 2.7) + 1) / 2, 3).toDouble();
      p.color = Colors.white.withValues(alpha: .25 + .75 * tw);
      canvas.drawCircle(c + _dir(a) * mid, math.max(.6, ring * (.16 + tw * .2)), p);
    }
    canvas.drawCircle(
      c,
      r + math.max(.5, ring * .1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, ring * .18)
        ..color = _ice.withValues(alpha: .55),
    );
  }

  void _twinkles(Canvas canvas, Offset c, double r, double t) {
    const n = 6;
    for (var i = 0; i < n; i++) {
      final a = i * math.pi * 2 / n + .4 + rnd(i, 21) * .5;
      final tw = math.pow((math.sin(t * 2.1 + i * 1.9) + 1) / 2, 2).toDouble();
      final pos = c + _dir(a) * r * (1.28 + rnd(i, 22) * .3);
      final s = avatar * (.03 + tw * .045);
      canvas.drawPath(
        star4(pos, s * 1.8),
        Paint()
          ..color = _ice.withValues(alpha: .25 * tw)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawPath(star4(pos, s), Paint()..color = Colors.white.withValues(alpha: .35 + .65 * tw));
    }
  }

  /// الانفجار النجمي: ومضة، وموجة ملوّنة تنتشر، وشرار يطير لبرا.
  void _supernova(Canvas canvas, Offset c, double r, double ring, double m) {
    final ease = Curves.easeOutCubic.transform(m);
    final fade = 1 - m;
    // ومضة على الصورة
    canvas.drawCircle(
      c,
      r * 1.1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: .85 * fade * fade),
            _cyan.withValues(alpha: .35 * fade),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.1))
        ..blendMode = BlendMode.plus,
    );
    // موجتين ملوّنة تنتشر
    for (final (delay, col) in [(0.0, _cyan), (.14, _pink)]) {
      final k = ((m - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final rad = r * (1 + Curves.easeOutCubic.transform(k) * 1.05);
      final width = math.max(.8, ring * .55 * (1 - k));
      canvas.drawCircle(
        c,
        rad,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 4
          ..color = col.withValues(alpha: .35 * (1 - k))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 2)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        c,
        rad,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = Color.lerp(_ice, col, k)!.withValues(alpha: (1 - k) * .9)
          ..blendMode = BlendMode.plus,
      );
    }
    // شرار
    final n = avatar < 80 ? 14 : 26;
    final p = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < n; i++) {
      final a = i * math.pi * 2 / n + rnd(i, 31) * .4;
      final dist = r * (1 + ease * (.55 + rnd(i, 32) * .7));
      final pos = c + _dir(a) * dist;
      final col = [_cyan, _pink, _violet, Colors.white][i % 4];
      p.color = col.withValues(alpha: fade);
      canvas.drawCircle(pos, math.max(.8, avatar * .014) * (1.4 - ease), p);
      // ذيل الشرارة
      canvas.drawLine(
        pos,
        c + _dir(a) * (dist - r * .18 * fade),
        Paint()
          ..color = col.withValues(alpha: .5 * fade)
          ..strokeWidth = math.max(.6, avatar * .008)
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus,
      );
    }
  }

  @override
  bool shouldRepaint(GalaxyFrame old) => old.avatar != avatar || old.layer != layer || old.moment != moment;
}
