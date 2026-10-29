import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../common.dart' show arabicNumber;
import 'epic.dart' show FireFrame;
import 'epic2.dart' show bolt;
import 'kit.dart';

// الإطارات الأسطورية: حركة من أكثر من طبقة، وأفخم شي في اللعبة، ولكل واحد لحظة خاصة (burst).

/// شرار يطير لبرا من المركز وقت اللحظة الخاصة.
void sparks(
  Canvas canvas,
  Offset c,
  double r,
  double m,
  List<Color> colors, {
  int n = 20,
  double from = 1,
  double size = 1.5,
}) {
  final ease = Curves.easeOutCubic.transform(m);
  final fade = 1 - m;
  for (var i = 0; i < n; i++) {
    final a = i * math.pi * 2 / n + rnd(i, 31) * .4;
    final dist = r * (from + ease * (.55 + rnd(i, 32) * .7));
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
      size * (1.4 - ease),
      Paint()
        ..color = col.withValues(alpha: fade)
        ..blendMode = BlendMode.plus,
    );
  }
}
// ═════════════ أسطورة المجلس (مستوى ٥٠) ═════════════

/// أسطورة المجلس: عنقاء من نار ملوّنة (ذهبي ووردي وبنفسجي): كل كم ثانية ينفرد جناحينها حول الصورة
/// ويرفرفون ويرجعون ينطوون، وذيل نار تحت، والحلقة نار ملوّنة يطير منها شرار.
/// اللحظة: الجناحين ينفردون على آخرهم وتطير ريش نار لبرا.
class PhoenixFrame extends FrameArt {
  PhoenixFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _gold = Color(0xFFFFD54F);
  static const _pink = Color(0xFFFF4081);
  static const _violet = Color(0xFF7C4DFF);
  static const _cyan = Color(0xFF18FFFF);
  static const _white = Color(0xFFFFF8E1);

  double _open(double t) {
    final p = frac(t / 6);
    var open = 0.0;
    if (p < .18) {
      open = Curves.easeOutBack.transform(p / .18);
    } else if (p < .6) {
      open = 1;
    } else if (p < .8) {
      open = 1 - Curves.easeInOut.transform((p - .6) / .2);
    }
    final b = burst(t);
    return b == null ? open : math.max(open, hump(b) * 1.15);
  }

  @override
  void back(Canvas canvas, Offset c, double t) {
    final open = _open(t);
    final shader = RadialGradient(
      colors: [_white, _gold, _pink, _violet.withValues(alpha: .7), _violet.withValues(alpha: 0)],
      stops: const [.3, .45, .62, .82, 1],
    ).createShader(Rect.fromCircle(center: c, radius: r * 2.1));
    if (open > .02) {
      final m = small ? 6 : 8;
      for (final side in const [-1, 1]) {
        final anchor = c + Offset(side * r * .45, -r * .12);
        final path = Path();
        for (var k = 0; k < m; k++) {
          final s = k / (m - 1);
          final base = -.12 + -1.25 * s + .06 * math.sin(t * 5 + k) * open;
          final a = side == 1 ? base : math.pi - base;
          final len = r * (1.0 + .6 * (1 - (s - .4).abs())) * open;
          if (len < r * .05) continue;
          FireFrame.tongue(
            path,
            anchor + dir(a) * r * .45,
            dir(a),
            len,
            r * .24 * (1 - s * .3),
            math.sin(t * 4 + k) * len * .08,
          );
        }
        canvas.drawPath(
          path,
          Paint()
            ..shader = shader
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(.5, r * .02)),
        );
      }
    }
    // ذيل النار تحت
    final tail = Path();
    for (var k = 0; k < 3; k++) {
      final a = math.pi / 2 + (k - 1) * .28;
      FireFrame.tongue(
        tail,
        c + dir(a) * r * .95,
        dir(a),
        r * (.42 + .08 * math.sin(t * 3 + k)),
        r * .2,
        math.sin(t * 2.6 + k * 2) * r * .06,
      );
    }
    canvas.drawPath(
      tail,
      Paint()
        ..shader = RadialGradient(
          colors: [_cyan, _violet.withValues(alpha: .75), _violet.withValues(alpha: 0)],
          stops: const [.55, .75, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.5))
        ..blendMode = BlendMode.plus,
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final open = _open(t);
    glowRing(canvas, c, _pink.withValues(alpha: .25 + .3 * open));
    sweepRing(canvas, c, const [_violet, _pink, _gold, _white, _gold, _pink, _violet, _cyan], turn: t * .6);
    line(canvas, c, r, _white.withValues(alpha: .55));
    for (var i = 0; i < (small ? 9 : 15); i++) {
      final life = frac(t * (.4 + rnd(i, 2) * .3) + rnd(i, 1));
      final a = -math.pi / 2 + (rnd(i, 3) - .5) * math.pi * 1.6;
      final pos = c + dir(a) * r * 1.08 + Offset(math.sin(life * 5 + i) * r * .06, -life * r * .7);
      dot(
        canvas,
        pos,
        math.max(.8, avatar * .014) * (1.1 - life * .6),
        [_gold, _pink, _cyan][i % 3],
        life < .15 ? life / .15 : 1 - life,
      );
    }
    final b = burst(t);
    if (b != null) {
      final path = Path();
      final ease = Curves.easeOutCubic.transform(b);
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6 + .2;
        FireFrame.tongue(path, c + dir(a) * r * (1.1 + ease * .7), dir(a), r * .28 * (1 - b), r * .12 * (1 - b), 0);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = _gold.withValues(alpha: 1 - b)
          ..blendMode = BlendMode.plus,
      );
    }
  }
}

// ═════════════ عاصفة الموسم ═════════════

/// عاصفة الموسم: غيوم داكنة تلف حول الصورة مثل الدوامة، والبرق يومض جواها ويضويها، ومطر ينزل،
/// وريح بيضا تمشي معها. اللحظة: صاعقة كبيرة تنزل من فوق على الحلقة، والغيوم تضوي والدوامة تسرع.
class StormFrame extends FrameArt {
  StormFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _sky = Color(0xFF0EA5E9);
  static const _night = Color(0xFF1E1B4B);
  static const _ice = Color(0xFFE0F2FE);
  static const _cloud = Color(0xFF2B3550);
  static const _cloudL = Color(0xFF8391AA);

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
    // مطر مايل ينزل
    final rain = Paint()
      ..strokeWidth = hair
      ..strokeCap = StrokeCap.round
      ..color = _ice.withValues(alpha: .35);
    for (var i = 0; i < (small ? 8 : 16); i++) {
      final x = c.dx + (rnd(i, 9) - .5) * r * 2.6;
      final y = c.dy + r * (-.2 + frac(t * 1.5 + rnd(i, 10)) * 1.8);
      canvas.drawLine(Offset(x, y), Offset(x - ring * .35, y + ring * 1.1), rain);
    }
    _clouds(canvas, c, t, front: false);
    // برق بين الغيوم
    final flash = _flash(t);
    if (flash > 0) {
      final a = _flashAt(t), seg = (t / _every).floor();
      bolt(
        canvas,
        [
          for (var q = 0; q <= 5; q++)
            c + dir(a + q * .09) * r * (1.5 - q * .06) + dir(rnd(seg * 7 + q, 6) * 6.3) * ring * .5,
        ],
        hair * 1.4,
        _sky,
        flash,
      );
    }
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final s = _spin(t);
    final flash = _flash(t);
    sweepRing(canvas, c, const [_night, Color(0xFF1E3A8A), _night, Color(0xFF0C4A6E)], turn: -s * .5);
    line(canvas, c, r + ring, _sky.withValues(alpha: .55 + .45 * flash));
    line(canvas, c, r, _ice.withValues(alpha: .5));
    _clouds(canvas, c, t, front: true);
    // الريح
    final wind = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair
      ..strokeCap = StrokeCap.round
      ..color = _ice.withValues(alpha: .5);
    for (var i = 0; i < (small ? 4 : 7); i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * (1.25 + .3 * rnd(i, 7))),
        s * 1.6 + i * .9 + rnd(i, 8),
        .35,
        false,
        wind,
      );
    }
    final b = burst(t);
    if (b != null && b < .45) {
      final k = 1 - b / .45;
      final seed = (moment?.value ?? 0).floor();
      final from = c + Offset(r * .25, -r * 2.1), to = c + Offset(0, -(r + ring));
      bolt(
        canvas,
        [
          for (var q = 0; q <= 7; q++)
            Offset.lerp(from, to, q / 7)! +
                (q == 0 || q == 7 ? Offset.zero : Offset((rnd(seed + q, 3) - .5) * r * .35, 0)),
        ],
        hair * 2.2,
        _sky,
        k,
      );
      halo(canvas, c, r * 1.4, [_ice.withValues(alpha: .5 * k), _ice.withValues(alpha: 0)]);
    }
  }

  /// كتلة غيوم حول الحلقة: كرات منفوخة تلف، بعضها قدام الصورة وأغلبها وراها. اللي جنب البرق تضوي.
  void _clouds(Canvas canvas, Offset c, double t, {required bool front}) {
    final s = _spin(t);
    final flash = _flash(t), at = _flashAt(t);
    final b = burst(t);
    final lit = b == null ? 0.0 : math.pow(1 - b, 2).toDouble();
    // صفين متداخلين (برا ثم جوا) عشان تطلع كتلة غيم منفوشة، مو كرات.
    final n = small ? 10 : 18;
    for (final row in const [1, 0]) {
      for (var i = 0; i < n; i++) {
        if ((row == 0 && i % 3 == 1) != front) continue;
        final ang = (i + row * .5) * 2 * math.pi / n + s * .35 + (rnd(i, 1 + row) - .5) * .25;
        final pos = c + dir(ang) * r * (1.17 + .17 * row + .04 * rnd(i, 2) + .03 * math.sin(s * 1.1 + i));
        final rad = r * (.17 + .1 * rnd(i, 3 + row)) * (front ? .85 : 1);
        final d = (ang - at) % (2 * math.pi);
        final close = math.max(0.0, 1 - math.min(d, 2 * math.pi - d) / 1.3);
        final glow = math.max(flash * close, lit);
        final shade = row == 1 ? .8 : 1.0;
        canvas.drawCircle(
          pos,
          rad,
          Paint()
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, rad * .12)
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(Color.lerp(_cloud, _cloudL, shade)!, _ice, glow * .75)!,
                Color.lerp(_cloud, _cloudL, glow * .7)!,
              ],
            ).createShader(Rect.fromCircle(center: pos, radius: rad)),
        );
      }
    }
  }
}

// ═════════════ احتفال الموسم الأول ═════════════

/// احتفال الموسم الأول: ألعاب نارية تنطلق من حول الصورة وتنفجر بألوان الموسم (ذهبي وفيروزي وبنفسجي)،
/// كل وحدة بوقت. اللحظة: ثلاث انفجارات كبيرة مع بعض ومطر لمعات ذهب.
class FireworksFrame extends FrameArt {
  FireworksFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _gold = Color(0xFFFCD34D);
  static const _teal = Color(0xFF0F766E);
  static const _mint = Color(0xFF5EEAD4);
  static const _violet = Color(0xFFA78BFA);
  static const _colors = [_gold, _mint, Colors.white, _violet];

  static const _slots = [(-2.4, 2.9, .0), (-1.15, 3.3, .45), (.15, 2.7, .2), (2.85, 3.1, .7)];

  @override
  void back(Canvas canvas, Offset c, double t) {
    halo(
      canvas,
      c,
      r * 1.6,
      [Colors.transparent, _violet.withValues(alpha: .12), _teal.withValues(alpha: .14), Colors.transparent],
      stops: const [.6, .72, .86, 1],
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    sweepRing(canvas, c, const [_teal, Color(0xFF134E4A), _teal, Color(0xFF115E59)]);
    line(canvas, c, r + ring, _gold, width: hair * 1.2);
    line(canvas, c, r, _gold.withValues(alpha: .7));
    for (var k = 0; k < 5; k++) {
      canvas.drawPath(star5(c + dir(k * 2 * math.pi / 5 + .3) * mid, ring * .42), Paint()..color = _gold);
    }
    for (final (i, (a, period, phase)) in _slots.indexed) {
      if (small && i == 3) continue;
      // كل إطلاق بلون ومكان مختلف شوي
      final cycle = (t / period + phase).floor();
      final p = frac(t / period + phase);
      final color = _colors[(i + cycle) % _colors.length];
      final at = a + (rnd(cycle, i + 20) - .5) * .5;
      if (p > .22 && p < .5) {
        // الحلقة تنور بلون الانفجار اللي جنبها
        final k = 1 - (p - .22) / .28;
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: mid),
          at - .5,
          1.0,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = ring * 1.2
            ..blendMode = BlendMode.plus
            ..shader = SweepGradient(
              startAngle: at - .5,
              endAngle: at + .5,
              colors: [
                color.withValues(alpha: 0),
                color.withValues(alpha: .6 * k),
                color.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: c, radius: mid)),
        );
      }
      _firework(canvas, c, at, p, color, i * 7 + cycle, r * .55);
    }
    final b = burst(t);
    if (b != null) {
      for (final (i, a) in const [-2.6, -.5, 1.9].indexed) {
        _firework(canvas, c, a, .22 + b * .78, _colors[(i + 1) % _colors.length], i + 7, r * .6);
      }
      // مطر لمعات ذهب
      for (var i = 0; i < (small ? 12 : 22); i++) {
        final x = (rnd(i, 41) - .5) * r * 3;
        final y = -r * 1.5 + (rnd(i, 42) * .4 + b) * r * 2.8;
        final tw = math.pow((math.sin(t * 9 + i * 2) + 1) / 2, 2).toDouble();
        dot(canvas, c + Offset(x, y), hair * 1.2, _gold, (1 - b) * (.4 + .6 * tw));
      }
    }
  }

  /// صاروخ يطلع ([p] < ٠٫٢٢) وبعدين ينفجر كرة شرار تنزل شوي وتختفي.
  void _firework(Canvas canvas, Offset c, double a, double p, Color color, int i, double size) {
    final launch = c + dir(a) * r * 1.05, center = c + dir(a) * r * 1.42;
    if (p < .22) {
      final q = Curves.easeOut.transform(p / .22);
      final pos = Offset.lerp(launch, center, q)!;
      canvas.drawLine(
        Offset.lerp(launch, center, math.max(0, q - .25))!,
        pos,
        Paint()
          ..color = _gold.withValues(alpha: .6)
          ..strokeWidth = hair
          ..strokeCap = StrokeCap.round,
      );
      dot(canvas, pos, hair * 1.3, _gold, 1);
      return;
    }
    final b = (p - .22) / .78;
    final ease = Curves.easeOutCubic.transform(b);
    final alpha = math.pow(1 - b, 1.3).toDouble();
    if (b < .15) {
      halo(canvas, center, size * .9, [
        Colors.white.withValues(alpha: .75 * (1 - b / .15)),
        color.withValues(alpha: 0),
      ]);
    }
    final m = small ? 12 : 18;
    final spark = small ? ring * .2 : hair * 1.7;
    final fall = Offset(0, size * .45 * b * b);
    for (var j = 0; j < m; j++) {
      final ang = j * 2 * math.pi / m + rnd(i, j) * .3;
      final pos = center + dir(ang) * size * (.15 + .85 * ease) + fall;
      canvas.drawLine(
        center + dir(ang) * size * (.15 + .6 * ease) + fall * .8,
        pos,
        Paint()
          ..color = color.withValues(alpha: .6 * alpha)
          ..strokeWidth = spark * .8
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus,
      );
      dot(
        canvas,
        pos,
        spark * (1 - b * .4),
        color,
        alpha * (b > .65 && rnd(i * 31 + j, (p * 40).floor()) < .4 ? .3 : 1),
      );
    }
  }
}

// ═════════════ أبطال الأسبوع ═════════════

/// أبطال الأسبوع: إكليل غار (ذهبي أو فضي أو برونزي) يحضن الصورة من تحت ومفتوح من فوق، وشريطة
/// وميدالية فيها المركز تتمرجح وتلمع، وحولها قصاصات احتفال (الأول) أو لمعات صقيع (الثاني) أو جمر (الثالث).
/// اللحظة: الميدالية تومض وينفجر حولها نفس النوع.
class ChampionFrame extends FrameArt {
  ChampionFrame(super.time, {required super.avatar, required super.layer, super.moment, required this.rank});

  final int rank;

  static const _metals = {
    1: [Color(0xFF8A6100), Color(0xFFFFD700), Color(0xFFFFF59D)],
    2: [Color(0xFF475569), Color(0xFFCBD5E1), Color(0xFFFFFFFF)],
    3: [Color(0xFF6D3C14), Color(0xFFE0A060), Color(0xFFFFD7A8)],
  };
  static const _ribbons = {1: Color(0xFFD32F2F), 2: Color(0xFF1E40AF), 3: Color(0xFF2E7D32)};

  List<Color> get _m => _metals[rank]!;

  static final _digits = <String, TextPainter>{};

  @override
  void back(Canvas canvas, Offset c, double t) {
    halo(
      canvas,
      c,
      r * 1.5,
      [_m[1].withValues(alpha: 0), _m[1].withValues(alpha: .22), _m[1].withValues(alpha: 0)],
      stops: const [.62, .8, 1],
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final m = _m;
    sweepRing(canvas, c, [m[0], m[1], m[2], m[1], m[0], m[1]], turn: t * .2);
    line(canvas, c, r + ring, m[0]);
    line(canvas, c, r, m[2].withValues(alpha: .7));
    _particles(canvas, c, t);
    for (final side in const [-1, 1]) {
      _branch(canvas, c, t, side);
    }
    _medal(canvas, c, t);
    final b = burst(t);
    if (b != null) {
      final colors = switch (rank) {
        1 => [m[1], _ribbons[1]!, Colors.white, m[2]],
        2 => [Colors.white, const Color(0xFFBAE6FD), m[1]],
        _ => [const Color(0xFFFFB74D), const Color(0xFFFF7043), m[2]],
      };
      sparks(canvas, c, r, b, colors, n: small ? 14 : 24, size: math.max(1, avatar * .016));
    }
  }

  /// غصن غار: من تحت ويلف على جنب الصورة لين قبل فوق بشوي، وعليه أوراق أزواج.
  void _branch(Canvas canvas, Offset c, double t, int side) {
    final m = _m;
    final rad = r * 1.24;
    const span = 2.17;
    final stem = Path();
    for (var j = 0; j <= 24; j++) {
      final a = math.pi / 2 - side * (.15 + j / 24 * span);
      final q = c + dir(a) * rad;
      j == 0 ? stem.moveTo(q.dx, q.dy) : stem.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair * 1.3
        ..color = m[0],
    );
    final n = small ? 7 : 10;
    for (var k = 0; k < n; k++) {
      final s = (k + .5) / n;
      final a = math.pi / 2 - side * (.15 + s * span);
      final p = c + dir(a) * rad;
      final along = dir(a - side * math.pi / 2);
      final len = ring * 1.55 * (1 - s * .35);
      final sway = .06 * math.sin(t * 1.5 + k * .6);
      for (final out in const [1, -1]) {
        final d = rot(along, out * side * -.6 + sway);
        _leaf(canvas, p, d, len, m);
      }
    }
  }

  void _leaf(Canvas canvas, Offset base, Offset d, double len, List<Color> m) {
    final tip = base + d * len, side = perp(d) * len * .3;
    final mid = base + d * len * .5;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo((mid + side).dx, (mid + side).dy, tip.dx, tip.dy)
        ..quadraticBezierTo((mid - side).dx, (mid - side).dy, base.dx, base.dy)
        ..close(),
      Paint()..shader = ui.Gradient.linear(base + side, tip - side, [m[2], m[1], m[0]], [0, .5, 1]),
    );
    canvas.drawLine(
      base,
      tip,
      Paint()
        ..color = m[0].withValues(alpha: .6)
        ..strokeWidth = hair * .6,
    );
  }

  /// الشريطة والميدالية تحت.
  void _medal(Canvas canvas, Offset c, double t) {
    final m = _m;
    final knot = c + Offset(0, r + ring * .55);
    final ribbon = Paint()..color = _ribbons[rank]!;
    for (final side in const [-1, 1]) {
      canvas.drawPath(
        poly([knot, knot + Offset(side * ring * 1.3, -ring * .55), knot + Offset(side * ring * 1.3, ring * .55)]),
        ribbon,
      );
    }
    final swing = .08 * math.sin(t * 1.8);
    canvas.save();
    canvas.translate(knot.dx, knot.dy);
    canvas.rotate(swing);
    final cr = ring * 1.05;
    final center = Offset(0, ring * .45 + cr);
    canvas.drawRect(Rect.fromLTRB(-ring * .35, 0, ring * .35, center.dy - cr * .6), ribbon);
    canvas.drawCircle(center + Offset(cr * .08, cr * .12), cr, Paint()..color = Colors.black.withValues(alpha: .3));
    canvas.drawCircle(
      center,
      cr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.4),
          colors: [m[2], m[1], m[0]],
        ).createShader(Rect.fromCircle(center: center, radius: cr)),
    );
    canvas.drawCircle(
      center,
      cr * .8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = m[0].withValues(alpha: .7),
    );
    final digit = _digits.putIfAbsent('$rank:${cr.toStringAsFixed(1)}', () {
      return TextPainter(
        text: TextSpan(
          text: arabicNumber(rank),
          style: TextStyle(fontFamily: kufi, fontSize: cr * 1.25, fontWeight: FontWeight.w700, color: m[0], height: 1),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
    });
    digit.paint(canvas, center - Offset(digit.width / 2, digit.height / 2));
    // لمعة تمر على الميدالية كل شوي
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

  void _particles(Canvas canvas, Offset c, double t) {
    final n = small ? 9 : 15;
    for (var i = 0; i < n; i++) {
      switch (rank) {
        case 1:
          // قصاصات تنزل وتتقلب
          final life = frac(t * (.18 + rnd(i, 1) * .12) + rnd(i, 2));
          final x = (rnd(i, 3) - .5) * r * 3.1 + math.sin(t * 1.5 + i) * r * .1;
          final y = -r * 1.6 + life * r * 3.1;
          if (Offset(x, y).distance < r * 1.15) continue;
          final col = [_m[1], _ribbons[1]!, Colors.white, _m[2]][i % 4];
          canvas.save();
          canvas.translate(c.dx + x, c.dy + y);
          canvas.rotate(t * (2 + rnd(i, 4) * 3) + i);
          canvas.scale(math.cos(t * 4 + i).abs() * .8 + .2, 1);
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: ring * .55, height: ring * .32),
            Paint()..color = col.withValues(alpha: .9 * hump(life)),
          );
          canvas.restore();
        case 2:
          // لمعات صقيع تلمع وتتلاشى
          final tw = math.pow((math.sin(t * 2.2 + i * 2.1) + 1) / 2, 3).toDouble();
          final a = rnd(i, 5) * 2 * math.pi + t * .05;
          sparkle(
            canvas,
            c + dir(a) * r * (1.25 + .3 * rnd(i, 6)),
            ring * (.25 + .4 * tw),
            const Color(0xFFBAE6FD),
            tw,
          );
        default:
          // جمر يطلع لفوق
          final life = frac(t * (.3 + rnd(i, 7) * .25) + rnd(i, 8));
          final a = math.pi / 2 + (rnd(i, 9) - .5) * math.pi * 1.8;
          final pos = c + dir(a) * r * 1.2 + Offset(math.sin(life * 5 + i) * r * .06, -life * r * .8);
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

  @override
  bool shouldRepaint(ChampionFrame old) => super.shouldRepaint(old) || old.rank != rank;
}
