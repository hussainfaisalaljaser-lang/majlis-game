import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../common.dart' show arabicNumber;
import 'kit.dart';

// الإطارات الأسطورية (بأسلوب رسمات الفيديو: حد غامق، ظل بدرجتين، لمعة): أكثر من طبقة، وحركة غنية،
// ولكل واحد لحظة خاصة (burst). العنقاء والعاصفة والألعاب النارية وأبطال الأسبوع.

// ═════════════ أسطورة المجلس (مستوى ٥٠) ═════════════

/// أسطورة المجلس: عنقاء من نار: جناحين كبار من ريش لهب (قرمزي وبرتقالي وذهبي) ينفردون على جنبين الصورة
/// ويرفرفون بموجة تمر من ريشة لريشة، وعُرف لهب فوق وذيل بنفسجي تحت، والحلقة ذهب بياقوت وجوهرة فوق،
/// وشرار يطير. اللحظة: الجناحين ينفردون أكثر وتنطلق موجة وريش نار لبرا.
class PhoenixFrame extends FrameArt {
  PhoenixFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _edge = Color(0xFF4A0E22);
  static const _crimson = Color(0xFFE0264F);
  static const _orange = Color(0xFFFF7A1E);
  static const _yellow = Color(0xFFFFD23C);
  static const _core = Color(0xFFFFF3B0);
  static const _violet = Color(0xFF9B3FD4);
  static const _cyan = Color(0xFF52E8FF);

  /// مدى انفراد الجناحين (يكبر وقت اللحظة).
  double _reach(double t) {
    final b = burst(t);
    return 1 + .05 * math.sin(t * 1.3) + (b == null ? 0 : .32 * hump(b));
  }

  /// ريشة لهب بثلاث طبقات: حد غامق وتدرج، وبعدها برتقالي وأصفر من جوا، وقلب فاتح للكبيرة.
  void _feather(
    Canvas canvas,
    Offset base,
    Offset up,
    double h,
    double w,
    double lean,
    double kink, {
    List<Color> body = const [_orange, _crimson],
    bool core = true,
  }) {
    final tip = base + up * h;
    final path = flameTongue(base, up, h, w, lean, kink: kink);
    inked(canvas, path, shader: lin(base, tip, body), edge: _edge, w: math.max(.8, lw * .9));
    canvas.drawPath(
      flameTongue(base, up, h * .78, w * .6, lean * .85, kink: kink * .8),
      Paint()..shader = lin(base, tip, const [_yellow, _orange]),
    );
    if (core) canvas.drawPath(flameTongue(base, up, h * .45, w * .3, lean * .6, kink: kink * .5), Paint()..color = _core);
  }

  @override
  void back(Canvas canvas, Offset c, double t) {
    final reach = _reach(t);
    final pulse = .88 + .12 * math.sin(t * 3.4);
    final b = burst(t);
    halo(
      canvas,
      c,
      r * 2.2,
      [
        _yellow.withValues(alpha: (.42 + .3 * hump(b ?? 0)) * pulse),
        _crimson.withValues(alpha: .24 * pulse),
        Colors.transparent,
      ],
      stops: const [.42, .68, 1],
    );
    // الجناحين: ريش تتدرج من فوق (طويلة) لتحت (أقصر)، وكل ريشة ترفرف متأخرة عن اللي قبلها وراسها ينحني لفوق
    final m = small ? 6 : 9;
    for (final side in const [-1.0, 1.0]) {
      final anchor = c + Offset(side * r * .86, -r * .02);
      for (var i = 0; i < m; i++) {
        final f = i / (m - 1);
        final flap = math.sin(t * 2.1 - i * .4) * (.06 + .06 * f);
        final aR = lerpD(-1.4, .62, f) + flap;
        final a = side > 0 ? aR : math.pi - aR;
        final len = r * (.62 + .78 * math.sin(math.pi * (.1 + .8 * f))) * reach;
        final w = r * (.4 - .09 * f);
        final up = dir(a);
        final lean = -len * (.42 + .06 * math.sin(t * 2.1 - i * .4)) * up.dx;
        _feather(
          canvas,
          anchor + up * r * .1,
          up,
          len,
          w,
          lean,
          math.sin(t * 3.6 + i * 1.7) * w * .14,
          core: f > .35,
        );
      }
    }
    // عُرف اللهب فوق الحلقة
    for (final (k, (da, hh)) in const [(-.5, .4), (-.25, .62), (0.0, .95), (.25, .62), (.5, .4)].indexed) {
      final a = -math.pi / 2 + da;
      final flick = .85 + .25 * noise(t * 2.2 + k * 1.7, k);
      _feather(
        canvas,
        at(c, a, r + ring * .6),
        dir(a),
        r * hh * flick,
        r * .2,
        math.sin(t * 3 + k * 2) * r * .05,
        0,
      );
    }
    // الذيل تحت: ثلاث ريشات طويلة وردية بنفسجية
    for (final (k, (da, hh)) in const [(-.34, .65), (0.0, .95), (.34, .65)].indexed) {
      final a = math.pi / 2 + da;
      final flick = .85 + .2 * math.sin(t * 2.6 + k * 2);
      _feather(
        canvas,
        at(c, a, r + ring * .6),
        dir(a),
        r * hh * flick,
        r * .22,
        math.sin(t * 2.4 + k * 2) * r * .09,
        r * .02,
        body: const [_orange, _crimson, _violet],
        core: false,
      );
    }
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final out = r + ring * 1.3;
    band(canvas, c, r, out, goldShader(c, out), edge: _edge);
    line(canvas, c, r + lw * .9, const Color(0xFF8A4E10), width: lw * 1.2);
    gloss(canvas, c, r + ring * .85, ring * .22, from: -2.7, span: 1.2, alpha: .75);
    // ياقوت على الحلقة وجوهرة كبيرة فوق
    studs(canvas, c, r + ring * .65, small ? 6 : 8, ring * .24, const Color(0xFFFFB0B8), _crimson, const Color(0xFF8A0E2A),
        turn: math.pi / 8, edge: _edge);
    final top = at(c, -math.pi / 2, r + ring * .65);
    ball(canvas, top, ring * .78, const Color(0xFFFFC4CC), _crimson, const Color(0xFF8A0E2A), edge: _edge);
    sheen(canvas, c, t * 1.1, .45, radius: r + ring * .65, width: ring * .3, span: .8);
    // شرار طاير
    final n = small ? 8 : 14;
    for (var i = 0; i < n; i++) {
      final life = frac(t * (.35 + rnd(i, 2) * .3) + rnd(i, 1));
      final a = -math.pi / 2 + (rnd(i, 3) - .5) * math.pi * 1.7;
      final pos = at(c, a, r * 1.15) + Offset(math.sin(life * 5 + i) * r * .06, -life * r * .8);
      dot(
        canvas,
        pos,
        math.max(.8, avatar * .014) * (1.1 - life * .6),
        [_yellow, _orange, _cyan][i % 3],
        life < .15 ? life / .15 : 1 - life,
      );
    }
    final b = burst(t);
    if (b != null) {
      final e = Curves.easeOutCubic.transform(b);
      halo(canvas, c, r * 1.3, [_core.withValues(alpha: .7 * (1 - b) * (1 - b)), Colors.transparent]);
      canvas.drawCircle(
        c,
        r * (1.05 + 1.0 * e),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring * 1.4 * (1 - b)
          ..color = _yellow.withValues(alpha: .7 * (1 - b)),
      );
      for (var i = 0; i < (small ? 8 : 12); i++) {
        final a = i * 2 * math.pi / (small ? 8 : 12) + .2;
        canvas.drawPath(
          flameTongue(at(c, a, r * (1.1 + e * .8)), dir(a), r * .3 * (1 - b), r * .13 * (1 - b), 0),
          Paint()..color = [_yellow, _orange, _crimson][i % 3].withValues(alpha: 1 - b),
        );
      }
      burstSparks(canvas, c, b, const [_yellow, _orange, _core, _cyan], n: small ? 12 : 20);
    }
  }
}

// ═════════════ عاصفة الموسم ═════════════

/// عاصفة الموسم: دوامة غيوم داكنة منفوخة بحد غامق (صفين يلفون عكس بعض)، والبرق يومض جواها ويضويها،
/// ومطر ينزل، وريح بيضا تلف معها. اللحظة: صاعقة كبيرة تنزل من فوق على الحلقة، والغيوم تضوي والدوامة تسرع.
class StormFrame extends FrameArt {
  StormFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _line = Color(0xFF0B1230);
  static const _dark = Color(0xFF414D78);
  static const _mid = Color(0xFF55649A);
  static const _light = Color(0xFFB6C4E0);
  static const _ice = Color(0xFFE0F2FE);
  static const _sky = Color(0xFF38BDF8);

  /// كل كم ثانية يومض البرق.
  static const _every = 1.7;

  /// الدوامة تسرع وقت اللحظة.
  double _spin(double t) {
    final b = burst(t);
    return t + (b == null ? 0 : Curves.easeOut.transform(b) * 2.5);
  }

  /// قوة ومضة البرق الحين (تومض مرتين ورا بعض).
  double _flash(double t) {
    final q = t % _every;
    if (q < .12) return 1 - q / .12;
    if (q > .18 && q < .34) return .7 * (1 - (q - .18) / .16);
    return 0;
  }

  /// وين البرق هالمرة (زاوية).
  double _flashAt(double t) => rnd((t / _every).floor(), 4) * 2 * math.pi;

  @override
  void back(Canvas canvas, Offset c, double t) {
    final flash = _flash(t);
    halo(
      canvas,
      c,
      r * 1.95,
      [
        const Color(0xFF1E3A8A).withValues(alpha: .5 + .2 * flash),
        const Color(0xFF1E1B4B).withValues(alpha: .25),
        Colors.transparent,
      ],
      stops: const [.45, .72, 1],
    );
    // مطر مايل ينزل
    final rain = Paint()
      ..strokeWidth = math.max(.8, lw * .8)
      ..strokeCap = StrokeCap.round
      ..color = _ice.withValues(alpha: .45);
    for (var i = 0; i < (small ? 8 : 16); i++) {
      final x = c.dx + (rnd(i, 9) - .5) * r * 2.8;
      final y = c.dy + r * (-1.4 + frac(t * 1.5 + rnd(i, 10)) * 3.2);
      canvas.drawLine(Offset(x, y), Offset(x - ring * .4, y + ring * 1.2), rain);
    }
    _puffs(canvas, _ring(c, t), t);
    // برق بين الغيوم
    if (flash > 0) {
      final a = _flashAt(t), seg = (t / _every).floor();
      _bolt(canvas, at(c, a, r + ring * 3.6), at(c, a + .1, r + ring * .8), seg, flash);
    }
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final s = _spin(t);
    final flash = _flash(t);
    final out = r + ring * .9;
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(-r * .5, -r), c + Offset(r * .5, r), const [Color(0xFF3F4F86), Color(0xFF232C55), Color(0xFF121735)]),
      edge: _line,
    );
    line(canvas, c, r + lw * 1.3, Color.lerp(_sky, Colors.white, flash)!.withValues(alpha: .6 + .4 * flash), width: math.max(.8, lw * .9));
    gloss(canvas, c, r + ring * .5, ring * .16, from: -2.6, span: 1.0, alpha: .4);
    // عناقيد غيم قدامية (٤ كتل متداخلة) تعبر فوق الحلقة وتعطي عمق
    final fronts = <_Puff>[];
    for (var k = 0; k < (small ? 1 : 2); k++) {
      final base = s * .5 + 1.2 + k * math.pi;
      for (final (i, size) in const [.75, 1.2, 1.0, .7].indexed) {
        final ang = base + (i - 1.5) * .2;
        fronts.add(_Puff(at(c, ang, r + ring * (i.isEven ? 1.0 : 1.35) + ring * .2 * math.sin(s + k)), ring * 1.2 * size, _glow(t, ang), true));
      }
    }
    _puffs(canvas, fronts, t);
    // ريح بيضا ملتفة
    final wind = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, lw * .9)
      ..strokeCap = StrokeCap.round
      ..color = _ice.withValues(alpha: .55);
    for (var i = 0; i < (small ? 4 : 7); i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * (1.3 + .32 * rnd(i, 7))),
        s * 1.6 + i * .9 + rnd(i, 8),
        .4,
        false,
        wind,
      );
    }
    final b = burst(t);
    if (b != null && b < .45) {
      final k = 1 - b / .45;
      final seed = (moment?.value ?? 0).floor();
      _bolt(canvas, c + Offset(r * .25, -r * 2.1), c + Offset(0, -(r + ring)), seed, k, big: true);
      halo(canvas, c, r * 1.4, [_ice.withValues(alpha: .5 * k), _ice.withValues(alpha: 0)]);
    }
    if (b != null) {
      canvas.drawCircle(
        c,
        r * (1.1 + .9 * Curves.easeOutCubic.transform(b)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring * (1 - b)
          ..color = _ice.withValues(alpha: .6 * (1 - b)),
      );
    }
  }

  /// صاعقة من [a] لـ[b]: حد غامق وتوهج أزرق وقلب أبيض.
  void _bolt(Canvas canvas, Offset a, Offset b, int seed, double k, {bool big = false}) {
    final path = zigzag(a, b, big ? 7 : 5, ring * (big ? .7 : .55), seed * 7);
    final f = big ? 2.2 : 1.0;
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * 3.4 * f
        ..strokeJoin = StrokeJoin.round
        ..color = _line.withValues(alpha: .55 * k),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * 2.2 * f
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = _sky.withValues(alpha: .85 * k),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * 1.0 * f
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: k),
    );
  }

  /// إضاءة الغيمة اللي بزاوية [ang]: الغيوم القريبة من البرق تضوي، وكلها تضوي وقت اللحظة.
  double _glow(double t, double ang) {
    final b = burst(t);
    final lit = b == null ? 0.0 : math.pow(1 - b, 2).toDouble();
    final d = (ang - _flashAt(t)) % (2 * math.pi);
    final close = math.max(0.0, 1 - math.min(d, 2 * math.pi - d) / 1.3);
    return math.max(_flash(t) * close, lit);
  }

  /// صفين غيوم (براني وجوّاني) يلفون عكس بعض عشان تطلع دوامة.
  List<_Puff> _ring(Offset c, double t) {
    final s = _spin(t);
    final list = <_Puff>[];
    final outer = small ? 12 : 18, inner = small ? 8 : 12;
    for (var i = 0; i < outer; i++) {
      final ang = i * 2 * math.pi / outer + s * .32 + (rnd(i, 1) - .5) * .25;
      final d = r + ring * 2.3 + ring * .12 * math.sin(s * 1.1 + i);
      list.add(_Puff(at(c, ang, d), ring * (1.4 + .6 * rnd(i, 3)), _glow(t, ang), false));
    }
    for (var i = 0; i < inner; i++) {
      final ang = (i + .5) * 2 * math.pi / inner - s * .45 + (rnd(i, 2) - .5) * .3;
      final d = r + ring * 1.1 + ring * .1 * math.sin(s * 1.3 + i * 2);
      list.add(_Puff(at(c, ang, d), ring * (1.5 + .4 * rnd(i, 4)), _glow(t, ang), false));
    }
    return list;
  }

  /// يرسم كتل الغيم: الحد الغامق على الطرف بس (دوائر أكبر شوي تحت التعبية)، ودرجتين، وبقع فاتحة باتجاه الضو.
  void _puffs(Canvas canvas, List<_Puff> puffs, double t) {
    final edge = Paint()..color = _line;
    for (final p in puffs) {
      canvas.drawCircle(p.pos, p.rad + lw * .9, edge);
    }
    for (final p in puffs) {
      final base = p.front ? Color.lerp(_dark, _mid, .6)! : _dark;
      canvas.drawCircle(p.pos, p.rad, Paint()..color = Color.lerp(base, _ice, p.glow * .8)!);
    }
    for (final (i, p) in puffs.indexed) {
      if (i.isOdd && !p.front) continue;
      canvas.drawCircle(
        p.pos + Offset(-p.rad * .22, -p.rad * .28),
        p.rad * .58,
        Paint()..color = Color.lerp(_light, Colors.white, p.glow)!.withValues(alpha: .32 + .4 * p.glow),
      );
    }
  }
}

/// كتلة غيم: مكانها ونصف قطرها وإضاءتها، وهل هي قدامية.
class _Puff {
  const _Puff(this.pos, this.rad, this.glow, this.front);

  final Offset pos;
  final double rad;
  final double glow;
  final bool front;
}

// ═════════════ احتفال الموسم الأول ═════════════

/// احتفال الموسم الأول: حلقة فيروزية بأضواء احتفال تتلاحق عليها ونجوم ذهب، وألعاب نارية ملونة تنطلق
/// وتنفجر حواليها (بعضها ورا الصورة وبعضها قدامها) بشرارات بحد غامق وذيل ينزل.
/// اللحظة: ثلاث انفجارات كبيرة مع بعض ومطر لمعات ذهب وموجة.
class FireworksFrame extends FrameArt {
  FireworksFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _gold = Color(0xFFFFC93C);
  static const _pink = Color(0xFFFF5C8A);
  static const _cyan = Color(0xFF46E0F0);
  static const _violet = Color(0xFFA78BFA);
  static const _lime = Color(0xFF8BE35A);
  static const _navy = Color(0xFF0A1F3A);
  static const _teal = Color(0xFF11615C);
  static const _colors = [_gold, _pink, _cyan, _violet, Colors.white, _lime];

  /// الإطلاقات: زاوية، دورة (ثواني)، تأخير، وهل هي ورا الصورة.
  static const _slots = [
    (-2.4, 3.0, .0, false),
    (-1.15, 3.4, .45, true),
    (.15, 2.8, .2, false),
    (2.85, 3.2, .7, true),
    (1.5, 3.6, .3, false),
  ];

  @override
  void back(Canvas canvas, Offset c, double t) {
    halo(
      canvas,
      c,
      r * 1.9,
      [_violet.withValues(alpha: .26), _teal.withValues(alpha: .16), Colors.transparent],
      stops: const [.5, .74, 1],
    );
    _shots(canvas, c, t, behind: true);
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final out = r + ring * 1.25;
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(-r * .5, -r), c + Offset(r * .5, r), const [Color(0xFF2AA79B), _teal, Color(0xFF0A3A3A)]),
      edge: const Color(0xFF04181A),
    );
    line(canvas, c, r + lw * 1.1, _gold, width: math.max(.8, lw * .9));
    line(canvas, c, out - lw * 1.1, _gold.withValues(alpha: .9), width: math.max(.8, lw * .8));
    gloss(canvas, c, r + ring * .8, ring * .18, from: -2.7, span: 1.1, alpha: .5);
    // أضواء احتفال تتلاحق على الحلقة
    final n = small ? 10 : 16;
    const lights = [_gold, _pink, _cyan];
    for (var i = 0; i < n; i++) {
      final col = lights[i % 3];
      final bright = .35 + .65 * math.max(0.0, math.sin(t * 4 - i * .8));
      final p = at(c, -math.pi / 2 + (i + .5) * 2 * math.pi / n, r + ring * .62);
      ball(
        canvas,
        p,
        ring * .26,
        Color.lerp(const Color(0xFF14403E), Colors.white, bright * .7)!,
        Color.lerp(const Color(0xFF14403E), col, bright)!,
        Color.lerp(const Color(0xFF0A2524), col, bright * .5)!,
        edge: const Color(0xFF04181A),
        w: lw * .6,
        shine: .5 * bright,
      );
    }
    // نجوم ذهب برا الحلقة
    for (var k = 0; k < 4; k++) {
      final p = at(c, -math.pi / 2 + k * math.pi / 2 + math.pi / 4, out + ring * .1);
      inked(
        canvas,
        star5(p, ring * .75, turn: -math.pi / 2 + k * math.pi / 2),
        shader: lin(p - Offset(0, ring), p + Offset(0, ring), const [Color(0xFFFFEF9C), Color(0xFFF2B53A)]),
        w: math.max(.8, lw * .85),
      );
    }
    _shots(canvas, c, t, behind: false);
    final b = burst(t);
    if (b != null) {
      for (final (i, a) in const [-2.6, -.5, 1.9].indexed) {
        _burst(canvas, at(c, a, r * 1.05), at(c, a, r * 1.45), .22 + b * .78, _colors[(i + 1) % _colors.length], i + 7, r * .62, 1);
      }
      canvas.drawCircle(
        c,
        r * (1.1 + .9 * Curves.easeOutCubic.transform(b)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring * (1 - b)
          ..color = _gold.withValues(alpha: .6 * (1 - b)),
      );
      // مطر لمعات ذهب
      for (var i = 0; i < (small ? 12 : 22); i++) {
        final x = (rnd(i, 41) - .5) * r * 3;
        final y = -r * 1.5 + (rnd(i, 42) * .4 + b) * r * 2.8;
        final tw = math.pow((math.sin(t * 9 + i * 2) + 1) / 2, 2).toDouble();
        dot(canvas, c + Offset(x, y), math.max(.8, hair * 1.2), _gold, (1 - b) * (.4 + .6 * tw));
      }
    }
  }

  /// الإطلاقات العادية: اللي ورا الصورة أو اللي قدامها.
  void _shots(Canvas canvas, Offset c, double t, {required bool behind}) {
    for (final (i, (a, period, phase, back)) in _slots.indexed) {
      if (back != behind) continue;
      if (small && i >= 3) continue;
      final cycle = (t / period + phase).floor();
      final p = frac(t / period + phase);
      final col = _colors[(i + cycle) % _colors.length];
      final ang = a + (rnd(cycle, i + 20) - .5) * .5;
      _burst(
        canvas,
        at(c, ang, r * 1.05),
        at(c, ang, r * (back ? 1.55 : 1.42)),
        p,
        col,
        i * 7 + cycle,
        r * (back ? .8 : .66),
        back ? .9 : 1,
      );
    }
  }

  /// صاروخ يطلع ([p] < ٠٫٢٢) وبعدين ينفجر نجمة شرارات بحد غامق، تنزل شوي وتختفي.
  void _burst(Canvas canvas, Offset launch, Offset center, double p, Color color, int seed, double size, double alpha) {
    final spark = math.max(1.3, avatar * .024);
    if (p < .22) {
      final q = Curves.easeOut.transform(p / .22);
      final pos = Offset.lerp(launch, center, q)!;
      canvas.drawLine(
        Offset.lerp(launch, center, math.max(0, q - .3))!,
        pos,
        Paint()
          ..strokeWidth = math.max(1, lw * 1.2)
          ..strokeCap = StrokeCap.round
          ..shader = lin(Offset.lerp(launch, center, math.max(0, q - .3))!, pos, [_gold.withValues(alpha: 0), _gold]),
      );
      dot(canvas, pos, spark * .8, _gold, alpha);
      return;
    }
    final b = (p - .22) / .78;
    final e = Curves.easeOutCubic.transform(b);
    final fade = (b < .4 ? 1.0 : math.pow(1 - (b - .4) / .6, 1.2).toDouble()) * alpha;
    if (fade < .03) return;
    if (b < .16) {
      final k = 1 - b / .16;
      halo(canvas, center, size * .8, [color.withValues(alpha: .45 * k), color.withValues(alpha: 0)]);
      canvas.drawPath(star8(center, size * .3 * (1 + b * 2)), Paint()..color = Colors.white.withValues(alpha: .85 * k));
    }
    final m = small ? 10 : 14;
    final fall = Offset(0, size * .5 * b * b);
    final rays = Path();
    final tips = <Offset>[];
    for (var j = 0; j < m; j++) {
      final ang = j * 2 * math.pi / m + (rnd(seed, j) - .5) * .2;
      final long = j.isEven ? 1.0 : .72;
      final from = center + dir(ang) * size * (.12 + .5 * e * long) + fall * .8;
      final to = center + dir(ang) * size * (.2 + .85 * e * long) + fall;
      rays.moveTo(from.dx, from.dy);
      rays.lineTo(to.dx, to.dy);
      tips.add(to);
    }
    canvas.drawPath(
      rays,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = spark * 2.9
        ..color = _navy.withValues(alpha: .55 * fade),
    );
    canvas.drawPath(
      rays,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = spark * 1.5
        ..color = color.withValues(alpha: fade),
    );
    final dotSize = spark * 2.2 * (1 - b * .3);
    canvas.drawPoints(
      ui.PointMode.points,
      tips,
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = dotSize + lw * 1.4
        ..color = _navy.withValues(alpha: .7 * fade),
    );
    canvas.drawPoints(
      ui.PointMode.points,
      tips,
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = dotSize
        ..color = Color.lerp(color, Colors.white, .25)!.withValues(alpha: fade),
    );
    // حلقة ثانية أصغر من شرارات بيضا تلمع
    if (!small && b > .3) {
      final inner = <Offset>[
        for (var j = 0; j < m; j++)
          center + dir((j + .5) * 2 * math.pi / m) * size * (.1 + .45 * e) + fall * .6,
      ];
      canvas.drawPoints(
        ui.PointMode.points,
        inner,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = spark * 1.3
          ..color = Colors.white.withValues(alpha: fade * (b > .6 ? .5 : 1)),
      );
    }
  }
}

// ═════════════ أبطال الأسبوع ═════════════

/// ألوان معدن الإطار (ذهب أو فضة أو برونز) والشريطة.
class _Metal {
  const _Metal(this.light, this.base, this.dark, this.edge, this.ribbon, this.ribbonDark);

  final Color light, base, dark, edge, ribbon, ribbonDark;
}

/// أبطال الأسبوع: إكليل غار (ذهبي أو فضي أو برونزي) بأوراق من درجتين وحد غامق يحضن الصورة من تحت ومفتوح
/// من فوق، وميدالية بشريطة فيها المركز تتمرجح وتلمع، وحولها قصاصات احتفال (الأول) أو لمعات صقيع (الثاني)
/// أو جمر (الثالث). الإكليل والحلقة يترسمون مرة وحدة ويتخزنون (ما يتعاد رسمهم كل فريم).
/// اللحظة: الميدالية تومض وينفجر حولها نفس النوع.
class ChampionFrame extends FrameArt {
  ChampionFrame(super.time, {required super.avatar, required super.layer, super.moment, required this.rank});

  final int rank;

  static const _metals = {
    1: _Metal(Color(0xFFFFF3A8), Color(0xFFF7C62E), Color(0xFFB87A10), Color(0xFF4A2A06), Color(0xFFD93A3A), Color(0xFF8E1A1A)),
    2: _Metal(Color(0xFFFFFFFF), Color(0xFFCBD5E1), Color(0xFF6B7A90), Color(0xFF2A3347), Color(0xFF3B6FE0), Color(0xFF1A3A9A)),
    3: _Metal(Color(0xFFFFD3A0), Color(0xFFD88A45), Color(0xFF8A4A1B), Color(0xFF3A1C08), Color(0xFF3BAE55), Color(0xFF1B6B2E)),
  };

  _Metal get _m => _metals[rank]!;

  /// الإكليل والحلقة المرسومين (حسب الرتبة وحجم الصورة)، عشان ما يتعاد رسمهم كل فريم.
  static final _cache = <String, ui.Picture>{};
  static final _digits = <String, (TextPainter, TextPainter)>{};

  @override
  void back(Canvas canvas, Offset c, double t) {
    final m = _m;
    halo(
      canvas,
      c,
      r * 1.6,
      [m.base.withValues(alpha: .0), m.base.withValues(alpha: .26), m.base.withValues(alpha: 0)],
      stops: const [.6, .78, 1],
    );
    _particles(canvas, c, t, behind: true);
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final m = _m;
    // الحلقة والإكليل (مخزنين)
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.drawPicture(_wreath());
    canvas.restore();
    // لمعة تمر على الحلقة كل شوي
    final g = (t % 4.0) / 1.2;
    if (g < 1) sheen(canvas, c, -math.pi * .9 + ease(g) * math.pi * 2, .7 * hump(g), radius: r + ring * .45, width: ring * .4);
    _particles(canvas, c, t, behind: false);
    _medal(canvas, c, t);
    final b = burst(t);
    if (b != null) {
      final colors = switch (rank) {
        1 => [m.base, m.ribbon, Colors.white, m.light],
        2 => [Colors.white, const Color(0xFFBAE6FD), m.base],
        _ => [const Color(0xFFFFB74D), const Color(0xFFFF7043), m.light],
      };
      canvas.drawCircle(
        c,
        r * (1.1 + .8 * Curves.easeOutCubic.transform(b)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring * (1 - b)
          ..color = m.light.withValues(alpha: .7 * (1 - b)),
      );
      burstSparks(canvas, c, b, colors, n: small ? 14 : 24);
    }
  }

  ui.Picture _wreath() {
    final key = '$rank:${avatar.toStringAsFixed(1)}';
    final hit = _cache[key];
    if (hit != null) return hit;
    final rec = ui.PictureRecorder();
    _drawWreath(Canvas(rec), Offset.zero);
    final pic = rec.endRecording();
    if (_cache.length >= 40) _cache.remove(_cache.keys.first);
    return _cache[key] = pic;
  }

  void _drawWreath(Canvas canvas, Offset c) {
    final m = _m;
    // الحلقة المعدنية
    final out = r + ring * .9;
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(-r * .4, -r), c + Offset(r * .4, r), [m.light, m.base, m.dark], const [0, .45, 1]),
      edge: m.edge,
    );
    gloss(canvas, c, r + ring * .45, ring * .2, from: -2.7, span: 1.2, alpha: .75);
    for (final side in const [-1, 1]) {
      _branch(canvas, c, side);
    }
  }

  /// غصن غار: من تحت ويلف على جنب الصورة لين قبل فوق بشوي، وعليه أوراق أزواج بدرجتين.
  void _branch(Canvas canvas, Offset c, int side) {
    final m = _m;
    final rad = r + ring * 1.65;
    const span = 2.2;
    final stem = Path();
    for (var j = 0; j <= 24; j++) {
      final a = math.pi / 2 - side * (.12 + j / 24 * span);
      final q = at(c, a, rad);
      j == 0 ? stem.moveTo(q.dx, q.dy) : stem.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = ring * .34 + lw * 2
        ..color = m.edge,
    );
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = ring * .34
        ..color = m.dark,
    );
    final n = small ? 7 : 10;
    // الأوراق البرانية أول وبعدها الجوانية
    for (final out in const [1.0, -1.0]) {
      for (var k = 0; k < n; k++) {
        final s = (k + .5) / n;
        final a = math.pi / 2 - side * (.12 + s * span);
        final radial = dir(a);
        final tangent = perp(radial) * -side.toDouble();
        final base = at(c, a, rad);
        final d = unit(tangent * .8 + radial * (out * .6));
        final len = ring * 2.5 * (1 - s * .3) * (out > 0 ? 1 : .88);
        _leaf(canvas, base, d, len);
      }
    }
    // توت صغير على الغصن
    for (var k = 1; k < n; k += 3) {
      final s = (k + .5) / n;
      final a = math.pi / 2 - side * (.12 + s * span);
      ball(canvas, at(c, a, rad), ring * .24, m.light, m.base, m.dark, edge: m.edge, w: lw * .7, shine: .6);
    }
  }

  /// ورقة غار: شكل مدبب، نصفها فاتح ونصفها غامق، وعرق في النص، وحد غامق.
  void _leaf(Canvas canvas, Offset base, Offset d, double len) {
    final m = _m;
    final w = len * .3;
    final tip = base + d * len;
    var n = perp(d);
    // الضو من فوق اليسار: النص اللي يواجهه فاتح
    if (n.dx + n.dy > 0) n = -n;
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        base.dx + d.dx * len * .25 + n.dx * w * 1.3,
        base.dy + d.dy * len * .25 + n.dy * w * 1.3,
        base.dx + d.dx * len * .7 + n.dx * w,
        base.dy + d.dy * len * .7 + n.dy * w,
        tip.dx,
        tip.dy,
      )
      ..cubicTo(
        base.dx + d.dx * len * .7 - n.dx * w,
        base.dy + d.dy * len * .7 - n.dy * w,
        base.dx + d.dx * len * .25 - n.dx * w * 1.3,
        base.dy + d.dy * len * .25 - n.dy * w * 1.3,
        base.dx,
        base.dy,
      )
      ..close();
    final mid = base + d * len * .5;
    inked(
      canvas,
      path,
      shader: lin(mid + n * w, mid - n * w, [m.light, m.base, m.base, m.dark], const [0, .5, .5, 1]),
      edge: m.edge,
      w: math.max(.8, lw * .85),
    );
    canvas.drawLine(
      base + d * len * .08,
      tip - d * len * .12,
      Paint()
        ..color = m.edge.withValues(alpha: .55)
        ..strokeWidth = math.max(.6, hair * .8)
        ..strokeCap = StrokeCap.round,
    );
  }

  /// الشريطة والميدالية تحت: تتمرجح، وعليها المركز بالأرقام العربية، ولمعة تمر.
  void _medal(Canvas canvas, Offset c, double t) {
    final m = _m;
    final knot = c + Offset(0, r + ring * 1.25);
    final cr = ring * 2.0;
    final cy = ring * .3 + cr;
    canvas.save();
    canvas.translate(knot.dx, knot.dy);
    canvas.rotate(.08 * math.sin(t * 1.8));
    // ذيلين الشريطة (مشقوقين) وشريط يوصل للحلقة
    for (final side in const [-1.0, 1.0]) {
      final ribbon = Path()
        ..moveTo(side * cr * .1, cy - cr * .2)
        ..lineTo(side * cr * .95, cy - cr * .1)
        ..lineTo(side * cr * 1.15, cy + cr * 1.75)
        ..lineTo(side * cr * .72, cy + cr * 1.4)
        ..lineTo(side * cr * .3, cy + cr * 1.8)
        ..close();
      inked(
        canvas,
        ribbon,
        shader: lin(Offset(side * cr * .1, cy), Offset(side * cr * 1.15, cy + cr * 1.8), [m.ribbon, m.ribbonDark]),
        edge: m.edge,
        w: math.max(.8, lw * .85),
      );
    }
    inked(
      canvas,
      Path()..addRect(Rect.fromLTRB(-ring * .38, -ring * .2, ring * .38, cy - cr * .5)),
      shader: lin(Offset(-ring * .4, 0), Offset(ring * .4, 0), [m.ribbon, m.ribbonDark]),
      edge: m.edge,
      w: math.max(.8, lw * .85),
    );
    final center = Offset(0, cy);
    // الميدالية: حافة لامعة وقرص غاطس
    ball(canvas, center, cr, m.light, m.base, m.dark, edge: m.edge, w: lw * 1.1, shine: .5);
    canvas.drawCircle(
      center,
      cr * .72,
      Paint()..shader = lin(center + Offset(-cr * .5, -cr * .6), center + Offset(cr * .5, cr * .6), [m.dark, m.base, m.light], const [0, .55, 1]),
    );
    canvas.drawCircle(
      center,
      cr * .72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, lw * .8)
        ..color = m.edge.withValues(alpha: .8),
    );
    final (fill, edge) = _digits.putIfAbsent('$rank:${cr.toStringAsFixed(1)}', () {
      TextStyle style(Paint? foreground) => TextStyle(
        fontFamily: kufi,
        fontSize: cr * 1.2,
        fontWeight: FontWeight.w800,
        height: 1,
        color: foreground == null ? m.light : null,
        foreground: foreground,
      );
      TextPainter make(TextStyle s) => TextPainter(
        text: TextSpan(text: arabicNumber(rank), style: s),
        textDirection: TextDirection.rtl,
      )..layout();
      return (
        make(style(null)),
        make(
          style(
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(1.2, cr * .22)
              ..strokeJoin = StrokeJoin.round
              ..color = m.edge,
          ),
        ),
      );
    });
    final pos = center - Offset(fill.width / 2, fill.height / 2);
    edge.paint(canvas, pos);
    fill.paint(canvas, pos);
    // لمعة تمر على الميدالية كل شوي، وتومض وقت اللحظة
    final g = (t % 2.6) / .7;
    final b = burst(t);
    if (g < 1 || b != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: cr)));
      if (g < 1) {
        final x = center.dx - cr * 1.5 + g * cr * 3;
        canvas.drawPath(
          poly([
            Offset(x, center.dy - cr),
            Offset(x + cr * .5, center.dy - cr),
            Offset(x - cr * .2, center.dy + cr),
            Offset(x - cr * .7, center.dy + cr),
          ]),
          Paint()..color = Colors.white.withValues(alpha: .55),
        );
      }
      if (b != null) canvas.drawCircle(center, cr, Paint()..color = Colors.white.withValues(alpha: .8 * (1 - b)));
      canvas.restore();
    }
    canvas.restore();
  }

  /// جزيئات الاحتفال: الأول قصاصات، والثاني صقيع، والثالث جمر. نصفها ورا الصورة ونصفها قدامها.
  void _particles(Canvas canvas, Offset c, double t, {required bool behind}) {
    final m = _m;
    final n = small ? 9 : 15;
    for (var i = 0; i < n; i++) {
      if ((i.isEven) != behind) continue;
      switch (rank) {
        case 1:
          // قصاصات تنزل وتتقلب
          final life = frac(t * (.18 + rnd(i, 1) * .12) + rnd(i, 2));
          final x = (rnd(i, 3) - .5) * r * 3.1 + math.sin(t * 1.5 + i) * r * .1;
          final y = -r * 1.6 + life * r * 3.1;
          if (Offset(x, y).distance < r * 1.2) continue;
          final col = [m.base, m.ribbon, Colors.white, m.light][i % 4];
          canvas.save();
          canvas.translate(c.dx + x, c.dy + y);
          canvas.rotate(t * (2 + rnd(i, 4) * 3) + i);
          canvas.scale(math.cos(t * 4 + i).abs() * .8 + .2, 1);
          final rect = Rect.fromCenter(center: Offset.zero, width: ring * .6, height: ring * .36);
          canvas.drawRect(rect, Paint()..color = col.withValues(alpha: .95 * hump(life)));
          canvas.drawRect(
            rect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(.6, lw * .5)
              ..color = m.edge.withValues(alpha: .6 * hump(life)),
          );
          canvas.restore();
        case 2:
          // لمعات صقيع: نجمة بيضا وبعضها رقاقة ثلج صغيرة
          final tw = math.pow((math.sin(t * 2.2 + i * 2.1) + 1) / 2, 3).toDouble();
          final a = rnd(i, 5) * 2 * math.pi + t * .05;
          final p = at(c, a, r * (1.3 + .3 * rnd(i, 6)));
          if (i % 4 == 0 && !small) {
            _flake(canvas, p, ring * (.55 + .25 * tw), t * .4 + i, tw);
          } else {
            sparkle(canvas, p, ring * (.25 + .4 * tw), const Color(0xFFBAE6FD), tw);
          }
        default:
          // جمر يطلع لفوق
          final life = frac(t * (.3 + rnd(i, 7) * .25) + rnd(i, 8));
          final a = math.pi / 2 + (rnd(i, 9) - .5) * math.pi * 1.8;
          final pos = at(c, a, r * 1.25) + Offset(math.sin(life * 5 + i) * r * .06, -life * r * .8);
          dot(
            canvas,
            pos,
            math.max(.8, avatar * .013),
            Color.lerp(const Color(0xFFFFB74D), const Color(0xFFFF7043), life)!,
            life < .2 ? life / .2 : 1 - life,
          );
      }
    }
  }

  /// رقاقة ثلج صغيرة بيضا بحد أزرق.
  void _flake(Canvas canvas, Offset p, double len, double turn, double alpha) {
    if (alpha < .05) return;
    final arms = Path();
    for (var k = 0; k < 6; k++) {
      final d = dir(turn + k * math.pi / 3);
      final tip = p + d * len;
      arms.moveTo(p.dx, p.dy);
      arms.lineTo(tip.dx, tip.dy);
      final q = p + d * len * .55;
      for (final s in const [-1.0, 1.0]) {
        final e = q + rot(d, s * .9) * len * .35;
        arms.moveTo(q.dx, q.dy);
        arms.lineTo(e.dx, e.dy);
      }
    }
    final w = math.max(.9, len * .17);
    canvas.drawPath(
      arms,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w + lw * 1.2
        ..color = const Color(0xFF1B4F86).withValues(alpha: alpha),
    );
    canvas.drawPath(
      arms,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w
        ..color = Colors.white.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(ChampionFrame old) => super.shouldRepaint(old) || old.rank != rank;
}
