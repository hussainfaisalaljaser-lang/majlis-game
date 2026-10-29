import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../fx.dart' show FxClock;
import 'kit.dart';

// الإطارات الملحمية (بأسلوب رسمات الفيديو: حد غامق، ظل بدرجتين، لمعة): حركة مستمرة.
// نار ودخان وبرق وشهاب هنا، وبقية الملحمية في epic2.dart.

// ═════════════ نار ═════════════

/// نار: حلقة حمرا برتقالية بزخرفة ذهبية ونجمة أربع رؤوس، وألسنة لهب رفيعة كثيرة تلحس لفوق وتتمايل
/// (أطول فوق وأقصر تحت)، وشرار يطير لفوق، وتوهج حرارة ورا الصورة.
class FireFrame extends FrameArt {
  FireFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _dark = Color(0xFF6E1A0A);
  static const _red = Color(0xFFE5481A);
  static const _orange = Color(0xFFFF8A1E);
  static const _yellow = Color(0xFFFFD23C);
  static const _core = Color(0xFFFFF3B0);
  static const _gold = Color(0xFFFFC447);

  /// سماكة الحلقة (أنحف على الأحجام الصغيرة).
  double get _band => ring * (small ? 1.35 : 1.9);

  double get _out => r + _band;

  /// لسان لهب (قطرة مقلوبة): قاعدة مدوّرة، وراس يتمايل. (تستخدمه الأسطورية: العنقاء)
  static void tongue(Path path, Offset base, Offset d, double h, double width, double sway) {
    final side = perp(d);
    final tip = base + d * h + side * sway;
    final l = base - side * width / 2, rr = base + side * width / 2;
    final c1 = base + d * h * .38 - side * width * .62 + side * sway * .15;
    final c2 = base + d * h * .74 - side * width * .18 + side * sway * .65;
    final c3 = base + d * h * .74 + side * width * .18 + side * sway * .65;
    final c4 = base + d * h * .38 + side * width * .62 + side * sway * .15;
    final bottom = base - d * width * .4;
    path
      ..moveTo(l.dx, l.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, tip.dx, tip.dy)
      ..cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, rr.dx, rr.dy)
      ..quadraticBezierTo(bottom.dx, bottom.dy, l.dx, l.dy)
      ..close();
  }

  @override
  void back(Canvas canvas, Offset c, double t) {
    final pulse = .85 + .15 * math.sin(t * 5.1) * math.sin(t * 2.3);
    halo(
      canvas,
      c,
      r * 1.9,
      [_orange.withValues(alpha: .5 * pulse), _red.withValues(alpha: .2 * pulse), Colors.transparent],
      stops: const [.55, .78, 1],
    );
    final n = small ? 26 : 46;
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (i - n / 2 + .5) * 2 * math.pi / n + (rnd(i, 8) - .5) * .06;
      final upness = math.max(0.0, -math.sin(a));
      final flick = .7 + .55 * noise(t * 2.6 + i * 1.7, i);
      final h = _band * (.45 + 1.55 * math.pow(upness, 1.2) + .6 * rnd(i, 1)) * flick;
      final w = _band * (.38 + .25 * rnd(i, 2));
      final up = unit(dir(a) * .5 + const Offset(0, -.85));
      final lean = math.sin(t * 3.2 + i * 2.1) * _band * .4 * (.4 + upness);
      final kink = math.sin(t * 4.3 + i * 1.3) * _band * .22;
      final base = at(c, a, r + _band * .6);
      final path = flameTongue(base, up, h, w, lean, kink: kink);
      canvas.drawPath(path, Paint()..color = _orange);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, lw * .85)
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFB8300E),
      );
      canvas.drawPath(flameTongue(base, up, h * .72, w * .66, lean * .85, kink: kink * .8), Paint()..color = _yellow);
      if (h > _band * 1.1) {
        canvas.drawPath(flameTongue(base, up, h * .38, w * .34, lean * .55, kink: kink * .4), Paint()..color = _core);
      }
    }
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final out = _out;
    // نجمة أربع رؤوس (شمال وشرق وجنوب وغرب) وأصغر منها بالأقطار
    for (var k = 0; k < 8; k++) {
      final a = -math.pi / 2 + k * math.pi / 4;
      final big = k.isEven;
      final len = _band * (big ? .75 : .38);
      final w = _band * (big ? .62 : .5);
      final b0 = at(c, a, out - _band * .3);
      final tip = at(c, a, out + len);
      final side = perp(dir(a)) * w;
      final spike = Path()
        ..moveTo((b0 - side).dx, (b0 - side).dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo((b0 + side).dx, (b0 + side).dy)
        ..close();
      inked(canvas, spike, shader: lin(b0, tip, const [_red, Color(0xFF9A2410)]), edge: _dark);
    }
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(0, -out), c + Offset(0, out), const [Color(0xFFF77B2C), Color(0xFFDC3E1A), Color(0xFFA21E0E)]),
      edge: _dark,
    );
    // زخرفة منقوشة بخط ذهب: موجتين متقابلتين (ضفيرة) وحبات
    final mid = r + _band * .52;
    for (final ph in const [0.0, math.pi]) {
      final wave = Path();
      const m = 72;
      for (var i = 0; i <= m; i++) {
        final a = i * math.pi * 2 / m;
        final d = mid + math.sin(a * 12 + ph) * _band * .2;
        final p = at(c, a, d);
        i == 0 ? wave.moveTo(p.dx, p.dy) : wave.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        wave,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, lw * .8)
          ..strokeJoin = StrokeJoin.round
          ..color = _gold.withValues(alpha: .95),
      );
    }
    if (!small) {
      for (var i = 0; i < 24; i++) {
        canvas.drawCircle(at(c, (i + .5) * math.pi * 2 / 24, mid), _band * .07, Paint()..color = _core);
      }
    }
    // حافة داخلية ذهبية وانعكاس
    line(canvas, c, r + lw * .8, _gold, width: lw * 1.4);
    gloss(canvas, c, r + _band * .7, _band * .12, from: -2.6, span: 1.0, alpha: .55);
    // شرار طاير
    final n = small ? 7 : 12;
    for (var i = 0; i < n; i++) {
      final life = frac(t * (.3 + rnd(i, 3) * .25) + rnd(i, 4));
      final a = -math.pi / 2 + (rnd(i, 5) - .5) * 2.6;
      final start = at(c, a, out + _band * .4);
      final pos = start + Offset(math.sin(t * 2.4 + i * 2.7) * ring * 1.4 * life, -life * r * (.7 + .6 * rnd(i, 6)));
      dot(canvas, pos, math.max(.9, ring * (.16 + .1 * rnd(i, 7))) * (1 - life * .7), life < .5 ? _yellow : _orange, 1 - life);
    }
  }
}

// ═════════════ دخان ═════════════

/// دخان: سحابة دخان رمادية متراكمة (كتل صغيرة كثيرة بحد غامق على الطرف بس) تحيط بحلقة داكنة،
/// تتنفخ وتلتف ببطء، وخصلات تطلع من فوق، وأقواس بيضا تدور على الحلقة.
class SmokeFrame extends FrameArt {
  SmokeFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _line = Color(0xFF1B1819);
  static const _dark = Color(0xFF433E40);
  static const _mid = Color(0xFF554F51);
  static const _light = Color(0xFF7C7677);

  @override
  void back(Canvas canvas, Offset c, double t) {
    // كتل الدخان: طبقة براني (كبيرة) وطبقة جوا (أصغر وأقرب للحلقة)
    final outer = small ? 18 : 26, inner = small ? 12 : 18;
    final puffs = <(Offset, double, bool)>[];
    for (var i = 0; i < outer; i++) {
      final a = i * 2 * math.pi / outer + .25 * math.sin(t * .35 + i * 1.7);
      final d = (r + ring * 2.25) * (1 + .03 * math.sin(t * .7 + i * 2.3));
      final pr = ring * (1.05 + .55 * rnd(i, 1)) * (1 + .14 * math.sin(t * .9 + i * 1.9));
      puffs.add((at(c, a, d), pr, true));
    }
    for (var i = 0; i < inner; i++) {
      final a = (i + .5) * 2 * math.pi / inner + .3 * math.sin(t * .42 + i * 2.1);
      final d = (r + ring * 1.0) * (1 + .03 * math.sin(t * .8 + i * 1.3));
      final pr = ring * (1.4 + .4 * rnd(i, 2)) * (1 + .12 * math.sin(t * 1.1 + i * 2.6));
      puffs.add((at(c, a, d), pr, false));
    }
    // الحد: دوائر أكبر شوي بلون الحد، وبعدها التعبية تغطي الداخل فيبقى الحد على الطرف بس
    final edge = Paint()..color = _line;
    for (final (p, pr, _) in puffs) {
      canvas.drawCircle(p, pr + lw * .85, edge);
    }
    for (final (p, pr, isOuter) in puffs) {
      canvas.drawCircle(p, pr, Paint()..color = isOuter ? _dark : _mid);
    }
    // تدرج ظل خفيف باتجاه الضو (فوق اليسار): بقع فاتحة كبيرة ناعمة بدون حواف
    for (final (i, (p, pr, isOuter)) in puffs.indexed) {
      if (!isOuter && i % 2 == 0) continue;
      canvas.drawCircle(
        p + Offset(-pr * .22, -pr * .26),
        pr * .6,
        Paint()..color = _light.withValues(alpha: .35 + .15 * noise(t * .8, i)),
      );
    }
    // خصلات دخان تطلع من فوق
    for (var i = 0; i < 4; i++) {
      final life = frac(t * .22 + i / 4);
      final x = (rnd(i, 8) - .5) * r * 1.2 + math.sin(t * 1.1 + i) * ring;
      final p = c + Offset(x, -(r + ring * 2.6) - life * r * .55);
      final pr = ring * (.7 + 1.3 * life);
      final a = (1 - life) * (life < .15 ? life / .15 : 1);
      canvas.drawCircle(p, pr + lw * .9, Paint()..color = _line.withValues(alpha: a));
      canvas.drawCircle(p, pr, Paint()..color = _mid.withValues(alpha: a));
      canvas.drawCircle(p + Offset(-pr * .25, -pr * .3), pr * .45, Paint()..color = _light.withValues(alpha: .5 * a));
    }
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final out = r + ring * .8;
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(-r * .5, -r), c + Offset(r * .5, r), const [Color(0xFF6F6F79), Color(0xFF36363E), Color(0xFF1E1E24)]),
      edge: _line,
    );
    gloss(canvas, c, r + ring * .4, ring * .16, from: -2.7, span: 1.1, alpha: .4);
    // أقواس بيضا تدور
    for (var k = 0; k < 4; k++) {
      final a = t * (.45 + k * .13) * (k.isEven ? 1 : -1) + k * math.pi / 2;
      gloss(
        canvas,
        c,
        r + ring * (1.45 + .12 * math.sin(t + k)),
        math.max(1.2, lw * 1.5),
        from: a,
        span: .5,
        alpha: .8,
        color: const Color(0xFFF0E8D2),
      );
    }
  }
}

// ═════════════ برق ═════════════

/// برق: حلقة ذهب رفيعة ملفوفة بحبال كهربا متشابكة بنية ذهبية، وخيوط صفرا مخضرة تتشقق وتومض حولها،
/// وكل كم لحظة تضرب صاعقة بيضا من برا وتومض الصورة كلها.
class LightningFrame extends FrameArt {
  LightningFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _yellow = Color(0xFFFFE866);
  static const _gold = Color(0xFFFFD84A);
  static const _spark = Color(0xFF4E3410);

  /// دورة الضربة (ثواني) ومدة وميضها.
  static const _every = 1.3;
  static const _flash = .24;

  (int, double) _strike(double t) {
    final x = t / _every + .17;
    return (x.floor(), frac(x) * _every);
  }

  @override
  void back(Canvas canvas, Offset c, double t) {
    final (_, into) = _strike(t);
    final flash = into < _flash ? 1 - into / _flash : 0.0;
    halo(
      canvas,
      c,
      r * 1.75,
      [_gold.withValues(alpha: .3 + .3 * flash), _gold.withValues(alpha: .1 + .1 * flash), Colors.transparent],
      stops: const [.55, .8, 1],
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final inner = r + ring * .6;
    band(canvas, c, r, inner, goldShader(c, inner), edge: const Color(0xFF3A1E06));
    gloss(canvas, c, r + ring * .3, ring * .14, from: -2.6, span: 1.0, alpha: .7);
    // الأكاليل المتشابكة: ٤ حبال متموجة بنية بخط ذهبي رفيع فوقها، تلتف حول الحلقة
    final bucket = (t * 12).floor();
    const cords = 4;
    for (var f = 0; f < cords; f++) {
      final path = Path();
      const m = 90;
      final base = r + ring * (.95 + .22 * f);
      final ph = f * 1.9;
      for (var i = 0; i <= m; i++) {
        final a = i * math.pi * 2 / m;
        final d =
            base +
            math.sin(a * 7 + ph + t * .6) * ring * .55 +
            math.sin(a * 13 - ph) * ring * .2 +
            (rnd(bucket * 5 + i + f * 3, 11) - .5) * ring * .22;
        final p = at(c, a, d);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.6, lw * 2.6)
          ..strokeJoin = StrokeJoin.round
          ..color = _spark,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.7, lw * .8)
          ..strokeJoin = StrokeJoin.round
          ..color = f.isEven ? _gold : const Color(0xFFFFF4B0),
      );
    }
    // خيوط الكهربا: صفرا مخضرة متكسرة، تتغير كل ١٢ جزء من الثانية
    for (var f = 0; f < 1; f++) {
      final path = Path();
      const m2 = 52;
      final base = r + ring * (1.6 + .4 * f);
      for (var i = 0; i <= m2; i++) {
        final a = i * math.pi * 2 / m2 + f * .7;
        final d = base + (rnd(bucket * 3 + i * 7 + f, 13) - .5) * ring * 1.2;
        final p = at(c, a, d);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw * 2.6
          ..strokeJoin = StrokeJoin.round
          ..color = _yellow.withValues(alpha: .3),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, lw * .85)
          ..strokeJoin = StrokeJoin.round
          ..color = _yellow,
      );
    }
    // شعب قصيرة تطلع للخارج
    for (var i = 0; i < (small ? 5 : 9); i++) {
      final seed = bucket * 5 + i;
      if (rnd(seed, 12) < .3) continue;
      final a = rnd(i, 13) * math.pi * 2 + rnd(seed, 14) * .6;
      final from = at(c, a, r + ring * 2.0);
      final to = at(c, a + (rnd(seed, 15) - .5) * .3, r + ring * (2.8 + 1.6 * rnd(seed, 16)));
      canvas.drawPath(
        zigzag(from, to, 4, ring * .35, seed),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, lw * .9)
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = _yellow,
      );
    }
    // الضربة (في وضع الحركات الخفيفة الساعة واقفة، فلا نترك الصورة عالقة وهي تومض)
    final (cyc, into) = _strike(t);
    if (into < _flash && !FxClock.lite.value) {
      final k = 1 - into / _flash;
      final a = rnd(cyc, 20) * math.pi * 2;
      final from = at(c, a, r + ring * 2.2);
      final to = at(c, a + (rnd(cyc, 21) - .5) * .6, r * (1.6 + .35 * rnd(cyc, 22)));
      final bolt = zigzag(from, to, 6, ring * .9, cyc * 13);
      canvas.drawPath(
        bolt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw * 4
          ..strokeJoin = StrokeJoin.round
          ..color = _yellow.withValues(alpha: .55 * k),
      );
      canvas.drawPath(
        bolt,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw * 1.6
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: k),
      );
      // الصورة كلها تومض
      canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFFBD0).withValues(alpha: .5 * k * k));
    }
  }
}

// ═════════════ شهاب ═════════════

/// شهاب: حلقة كحلية بغبار نجوم وحافات ذهب ومسامير فضة، وسحابة نيلي ورا الحلقة، وشهب برتقالية كثيرة
/// تنزل بالزاوية بذيل ناري، وخطوط بيضا ذهبية سريعة تعبر الصورة.
class CometFrame extends FrameArt {
  CometFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _gold = Color(0xFFD9A441);
  static const _orange = Color(0xFFFF8A1E);
  static const _hot = Color(0xFFFFD23C);

  @override
  void back(Canvas canvas, Offset c, double t) {
    final pulse = .92 + .08 * math.sin(t * 1.7);
    halo(
      canvas,
      c,
      r * 1.8,
      [
        const Color(0xFF6C63F0).withValues(alpha: .6 * pulse),
        const Color(0xFF2E2F9A).withValues(alpha: .35),
        Colors.transparent,
      ],
      stops: const [.55, .78, 1],
    );
    // نجوم صغيرة ترمش بالهالة
    for (var i = 0; i < (small ? 10 : 22); i++) {
      final a = rnd(i, 1) * math.pi * 2;
      final d = r * (1.12 + .55 * rnd(i, 2));
      final tw = math.pow((math.sin(t * 2.2 + i * 2.7) + 1) / 2, 2).toDouble();
      canvas.drawCircle(
        at(c, a, d),
        math.max(.7, avatar * .008) * (.8 + rnd(i, 3)),
        Paint()..color = Colors.white.withValues(alpha: .25 + .6 * tw),
      );
    }
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final out = r + ring * 1.8;
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(-r * .5, -r), c + Offset(r * .5, r), const [Color(0xFF4F5E98), Color(0xFF232C55), Color(0xFF121735)]),
      edge: const Color(0xFF0A0C1C),
    );
    line(canvas, c, out - lw * 1.3, _gold, width: math.max(.8, lw * .9));
    line(canvas, c, r + lw * 1.3, _gold.withValues(alpha: .9), width: math.max(.8, lw * .9));
    gloss(canvas, c, r + ring * .72, ring * .16, from: -2.6, span: 1.0, alpha: .35);
    // غبار نجوم على الحلقة
    for (var i = 0; i < (small ? 18 : 40); i++) {
      final a = rnd(i, 4) * math.pi * 2;
      final tw = .45 + .55 * math.pow((math.sin(t * 1.9 + i * 1.9) + 1) / 2, 2).toDouble();
      canvas.drawCircle(
        at(c, a, r + ring * (.35 + .8 * rnd(i, 5))),
        math.max(.6, lw * .45) * (.7 + rnd(i, 6)),
        Paint()..color = Colors.white.withValues(alpha: .7 * tw),
      );
    }
    // مسامير فضة
    studs(
      canvas,
      c,
      r + ring * .9,
      5,
      ring * .5,
      Colors.white,
      const Color(0xFFC8CFE0),
      const Color(0xFF6A7390),
      turn: -math.pi / 2 + .45,
      edge: const Color(0xFF0A0C1C),
    );
    _comets(canvas, c, t);
  }

  void _comets(Canvas canvas, Offset c, double t) {
    // شهب برتقالية: تنزل من فوق اليمين لتحت اليسار، رأس متوهج وذيل مدبّب
    final fall = unit(const Offset(-.55, .83));
    final side = perp(fall);
    for (var i = 0; i < (small ? 3 : 5); i++) {
      final per = 1.7 + .37 * i;
      final x = t / per + rnd(i, 30);
      final cyc = x.floor();
      final p = frac(x);
      final start = c + Offset(r * (.3 + 1.7 * rnd(i + cyc * 5, 31)), -r * 1.7);
      final head = start + fall * (p * r * 3.6);
      final a = hump(p) * math.min(1.0, p * 6);
      final len = r * (.8 + .35 * rnd(i, 32));
      final tail = head - fall * len;
      final w = ring * (.8 + .25 * rnd(i, 33));
      canvas.drawPath(
        poly([head + side * w * .5, tail, head - side * w * .5]),
        Paint()
          ..shader = lin(head, tail, [
            _hot.withValues(alpha: .95 * a),
            _orange.withValues(alpha: .6 * a),
            _orange.withValues(alpha: 0),
          ]),
      );
      canvas.drawCircle(head, w * .95, Paint()..color = _orange.withValues(alpha: .35 * a));
      canvas.drawCircle(head, w * .55, Paint()..color = _orange.withValues(alpha: a));
      canvas.drawCircle(head, w * .3, Paint()..color = const Color(0xFFFFF3B0).withValues(alpha: a));
    }
    // خطوط بيضا ذهبية سريعة تعبر الصورة من فوق اليسار لتحت اليمين
    final streak = unit(const Offset(.74, .67));
    for (var i = 0; i < (small ? 3 : 4); i++) {
      final per = 1.4 + .45 * i;
      final x = t / per + rnd(i, 40);
      final cyc = x.floor();
      final p = frac(x);
      if (p > .6) continue;
      final q = p / .6;
      final start = c + Offset(-r * (1.55 - .9 * rnd(i + cyc * 3, 41)), -r * (1.5 - .8 * rnd(i + cyc * 3, 42)));
      final head = start + streak * (q * r * 2.9);
      final tail = head - streak * r * (.8 + .35 * rnd(i, 43));
      final a = hump(q);
      canvas.drawLine(
        head,
        tail,
        Paint()
          ..strokeWidth = math.max(1.4, lw * 2.0)
          ..strokeCap = StrokeCap.round
          ..shader = lin(head, tail, [
            const Color(0xFFFFFBE0).withValues(alpha: a),
            const Color(0xFFFFD86E).withValues(alpha: .8 * a),
            _hot.withValues(alpha: 0),
          ]),
      );
      canvas.drawCircle(head, math.max(1.5, lw * 1.9), Paint()..color = Colors.white.withValues(alpha: a));
    }
  }
}
