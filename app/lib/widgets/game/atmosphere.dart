import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/sounds.dart';
import '../design_game.dart' show Stage;
import '../fx.dart';
import '../venues.dart' show Venue;

/// جو الطاولة: كل مستوى طاولة له جو خفيف يناسبه. الطاولات الخاصة ليل هادئ.
/// مبتدئ: ليل صحراء وريح رمل خفيفة · المدينة: مطر وبرق خفيف · القصر: غبار ذهبي وأشعة · الملوك: شرر ذهبي ولمعة · النخبة: شفق أرجواني.
enum AtmoKind { night, desert, city, palace, kings, vip }

abstract final class Atmosphere {
  static AtmoKind kindFor(Venue v) => switch (v) {
    Venue.majlis => AtmoKind.night,
    Venue.desert => AtmoKind.desert,
    Venue.city => AtmoKind.city,
    Venue.palace => AtmoKind.palace,
    Venue.kings => AtmoKind.kings,
    Venue.vip => AtmoKind.vip,
  };
}

/// طبقة الجو. الخلفية ([front] false) ترسم اللي وراء الطاولة (النجوم والشفق)، والأمامية الطقس والغبار فوقها.
/// تنطفي لما تكون «حركات خفيفة» شغالة.
class TableAtmosphere extends StatefulWidget {
  const TableAtmosphere({super.key, required this.venue, this.front = false, this.safe = EdgeInsets.zero});

  final Venue venue;
  final bool front;
  final EdgeInsets safe;

  @override
  State<TableAtmosphere> createState() => _TableAtmosphereState();
}

class _TableAtmosphereState extends State<TableAtmosphere> with SingleTickerProviderStateMixin {
  late final _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: FxClock.lite,
    builder: (context, lite, _) {
      if (lite) return const SizedBox.shrink();
      final kind = Atmosphere.kindFor(widget.venue);
      return IgnorePointer(
        child: RepaintBoundary(
          child: FxClock(
            builder: (context, time) => Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _AtmoPainter(kind, time, _fade, widget.front, widget.safe)),
                if (widget.front && kind == AtmoKind.city) _ThunderSound(time: time),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// صوت الرعد بعد كل برقة (نفس جدول البرق في الرسم).
class _ThunderSound extends StatefulWidget {
  const _ThunderSound({required this.time});

  final ValueListenable<double> time;

  @override
  State<_ThunderSound> createState() => _ThunderSoundState();
}

class _ThunderSoundState extends State<_ThunderSound> {
  int _last = -1;

  @override
  void initState() {
    super.initState();
    widget.time.addListener(_check);
  }

  @override
  void dispose() {
    widget.time.removeListener(_check);
    super.dispose();
  }

  void _check() {
    final t = widget.time.value;
    final k = (t / _boltPeriod).floor();
    if (k == _last || t - _boltStart(k) < .12) return;
    // برقة فاتت من زمان (دخلنا الطاولة بعدها): ما نشغل رعدها
    final late = t - _boltStart(k) > 1.2;
    _last = k;
    if (!late) Sounds.play('thunder', volume: .6);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ───────── الرسم (بإحداثيات التصميم ١٩٢٠×١٠٨٠، نفس خلفية الطاولة) ─────────

typedef _Ext = ({double l, double t, double r, double b});

const _fires = [Offset(108, 752), Offset(1796, 752)];
const _lanterns = [Offset(243, 322), Offset(1677, 322)];
const _moon = Offset(1416, 232);

const _boltPeriod = 9.0;
double _boltStart(int k) => k * _boltPeriod + 2.0 + 4.0 * rnd(k, 61);

double _c01(double x) => x.clamp(0.0, 1.0);
double _lerp(double a, double b, double t) => a + (b - a) * t;

double _flash(double dt) {
  if (dt < 0) return 0;
  if (dt < .06) return 1;
  if (dt < .11) return .22;
  if (dt < .17) return .8;
  return math.exp(-(dt - .17) * 7);
}

class _AtmoPainter extends CustomPainter {
  _AtmoPainter(this.kind, this.time, this.fade, this.front, this.safe) : super(repaint: Listenable.merge([time, fade]));

  final AtmoKind kind;
  final ValueListenable<double> time;
  final Animation<double> fade;
  final bool front;
  final EdgeInsets safe;

  final _p = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final a = Curves.easeOut.transform(fade.value);
    if (a <= 0) return;
    final st = Stage(size, safe);
    canvas.save();
    canvas.translate(st.box.left, st.box.top);
    canvas.scale(st.s);
    final e = (
      l: -st.box.left / st.s,
      t: -st.box.top / st.s,
      r: (size.width - st.box.left) / st.s,
      b: (size.height - st.box.top) / st.s,
    );
    final t = time.value;
    switch (kind) {
      case AtmoKind.night:
        front ? _nightFront(canvas, e, t, a) : _nightBack(canvas, e, t, a);
      case AtmoKind.desert:
        front ? _sand(canvas, e, t, a * .55) : _nightBack(canvas, e, t, a);
      case AtmoKind.city:
        if (front) _rain(canvas, e, t, a * .8);
      case AtmoKind.palace:
        if (front) _palace(canvas, e, t, a);
      case AtmoKind.kings:
        if (front) _kings(canvas, e, t, a);
      case AtmoKind.vip:
        front ? _vipFront(canvas, e, t, a) : _vipBack(canvas, e, t, a);
    }
    canvas.restore();
  }

  void _glow(Canvas c, Offset at, double r, Color color, double alpha) {
    if (alpha <= 0) return;
    c.drawCircle(
      at,
      r,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(at, r, [color.withValues(alpha: alpha), color.withValues(alpha: 0)]),
    );
  }

  /// النجوم تلمع على نفس مواقع نجوم الخلفية (venues.dart → _stars).
  void _stars(Canvas c, _Ext e, double t, double a) {
    final w = e.r - e.l;
    // نفس مواقع نجوم الخلفية (venues.dart → _stars) فتلمع هي نفسها
    for (var i = 0; i < 90; i += 2) {
      final tw = .5 + .5 * math.sin(t * (1.2 + 2.6 * rnd(i, 21)) + rnd(i, 22) * 6.28);
      if (tw < .35) continue;
      final o = Offset(e.l + rnd(i, 1) * w, 192 + rnd(i, 2) * 290);
      final r = .8 + rnd(i, 3) * 1.7;
      _p.color = const Color(0xFFFFF4C8).withValues(alpha: (tw - .35) * 1.2 * a);
      c.drawCircle(o, r * (1.1 + tw), _p);
      if (r > 1.8 && tw > .8) {
        final l = 6 + 12 * tw;
        _p
          ..strokeWidth = 1.6
          ..color = Colors.white.withValues(alpha: (tw - .5) * a);
        c.drawLine(o - Offset(l, 0), o + Offset(l, 0), _p);
        c.drawLine(o - Offset(0, l), o + Offset(0, l), _p);
      }
    }
  }

  /// وراء الطاولة: النجوم تلمع على نفس مواقع نجوم الخلفية، ونيزك، وقمر ينبض، وشرار عالي من النار.
  void _nightBack(Canvas c, _Ext e, double t, double a) {
    final w = e.r - e.l;
    _stars(c, e, t, a);
    // القمر ينبض
    _glow(c, _moon, 190, const Color(0xFFFFE9A8), (.16 + .06 * math.sin(t * 1.3)) * a);
    // نيزك كل ٣٫٦ ثانية
    final k = ((t + 1.0) / 3.6).floor();
    final lt = (t + 1.0) % 3.6;
    if (lt < .8) {
      final pr = lt / .8;
      final from = Offset(e.l + (.15 + .45 * rnd(k, 9)) * w, 205 + 14 * rnd(k, 10));
      final to = from + const Offset(470, 130);
      final head = Offset.lerp(from, to, Curves.easeInOut.transform(pr))!;
      final tail = Offset.lerp(from, to, Curves.easeInOut.transform(math.max(0, pr - .3)))!;
      final f = math.sin(math.pi * pr);
      c.drawLine(
        tail,
        head,
        Paint()
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(tail, head, [
            const Color(0x00FFFFFF),
            Colors.white.withValues(alpha: .9 * f * a),
          ]),
      );
      _glow(c, head, 18, Colors.white, .8 * f * a);
    }
    // ضو النار والفوانيس يرتعش
    for (var i = 0; i < _fires.length; i++) {
      final fl = .8 + .2 * math.sin(t * 11 + i * 2) * math.sin(t * 4.3 + i);
      _glow(c, _fires[i] - const Offset(0, 40), 230, const Color(0xFFFF8A2A), .24 * fl * a);
    }
    for (var i = 0; i < _lanterns.length; i++) {
      final fl = .5 + .5 * math.sin(t * 7.3 + i * 1.9) * math.sin(t * 3.1 + i);
      _glow(c, _lanterns[i], 160, const Color(0xFFFFC25A), (.16 + .1 * fl) * a);
    }
    // شرار يطلع من النار أعلى من شرار الخلفية، وله هالة
    for (var fi = 0; fi < _fires.length; fi++) {
      final f = _fires[fi];
      for (var i = 0; i < 12; i++) {
        final life = 2.4 + 1.3 * rnd(i, 20 + fi);
        final pr = (t / life + rnd(i, 30 + fi)) % 1;
        final x = f.dx + (rnd(i, 7 + fi) - .5) * 80 + math.sin(pr * 7 + rnd(i, 8) * 6) * 32 * pr;
        final y = f.dy - 110 - pr * (280 + 180 * rnd(i, 9));
        final al = math.sin(math.pi * math.pow(pr, .7)) * a;
        final sz = _lerp(6, 1.6, pr);
        final col = Color.lerp(const Color(0xFFFFE08A), const Color(0xFFFF5A1A), pr)!;
        _p.color = col.withValues(alpha: .18 * al);
        c.drawCircle(Offset(x, y), sz * 3, _p);
        _p.color = col.withValues(alpha: .95 * al);
        c.drawCircle(Offset(x, y), sz, _p);
      }
    }
  }

  /// فوق الطاولة: تعتيم خفيف وغبار ذهبي يطير بالضو.
  void _nightFront(Canvas c, _Ext e, double t, double a) {
    final full = Rect.fromLTRB(e.l, e.t, e.r, e.b);
    c.drawRect(full, _p..color = const Color(0xFF0A1030).withValues(alpha: .1 * a));
    final w = e.r - e.l, h = e.b - e.t;
    for (var i = 0; i < 22; i++) {
      final x = e.l + ((rnd(i, 41) + t * .006 * (1 + rnd(i, 42)) + math.sin(t * .5 + i) * .01) % 1) * w;
      final y = e.t + (.34 + .6 * ((rnd(i, 43) - t * .010 * (.5 + rnd(i, 44))) % 1)) * h;
      final tw = .5 + .5 * math.sin(t * 1.7 + i);
      c.drawCircle(
        Offset(x, y),
        2 + 3 * rnd(i, 45),
        Paint()
          ..blendMode = BlendMode.plus
          ..color = const Color(0xFFFFE2A0).withValues(alpha: (.1 + .24 * tw) * a),
      );
    }
  }

  /// عاصفة رمل: تعتيم دافي وضباب يمرّ وخطوط ريح وحبّات رمل.
  void _sand(Canvas c, _Ext e, double t, double a) {
    final full = Rect.fromLTRB(e.l, e.t, e.r, e.b);
    final w = e.r - e.l, h = e.b - e.t;
    final g = .75 + .25 * math.sin(t * 1.7);
    c.drawRect(full, _p..color = const Color(0xFFC88A3C).withValues(alpha: (.25 + .08 * g) * a));
    c.drawRect(
      full,
      Paint()
        ..shader = ui.Gradient.radial(full.center, full.longestSide * .62, [
          const Color(0x00000000),
          const Color(0xFF3A2210).withValues(alpha: .5 * a),
        ]),
    );
    // ضباب يمرّ
    for (var k = 0; k < 4; k++) {
      final y = e.t + (.12 + .22 * k) * h;
      final x = e.l - 1200 + (t * (80 + 44 * k)) % (w + 1200);
      final r = Rect.fromLTWH(x, y, 1200, 180);
      c.drawRect(
        r,
        Paint()
          ..shader = ui.Gradient.linear(
            r.centerLeft,
            r.centerRight,
            [const Color(0x00E6B873), const Color(0xFFE6B873).withValues(alpha: .15 * g * a), const Color(0x00E6B873)],
            const [0, .5, 1],
          ),
      );
    }
    // خطوط الريح (دفعتين بشفافيتين)
    for (var batch = 0; batch < 2; batch++) {
      final pts = <double>[];
      for (var i = batch; i < 56; i += 2) {
        final sp = 1400 + 2200 * rnd(i, 2);
        final x = e.l - 300 + (rnd(i, 3) * (w + 800) + t * sp) % (w + 800);
        final y = e.t + rnd(i, 1) * h + math.sin(t * 2 + i) * 8;
        final len = 120 + 340 * rnd(i, 4);
        pts.addAll([x - len, y - len * .04, x, y]);
      }
      c.drawRawPoints(
        ui.PointMode.lines,
        Float32List.fromList(pts),
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = batch == 0 ? 2.2 : 3.6
          ..color = const Color(0xFFFFE6B0).withValues(alpha: (batch == 0 ? .14 : .26) * a * g),
      );
    }
    // حبّات رمل
    final grains = <double>[];
    for (var i = 0; i < 120; i++) {
      final sp = 1800 + 1800 * rnd(i, 12);
      grains.addAll([
        e.l - 100 + (rnd(i, 13) * (w + 200) + t * sp) % (w + 200),
        e.t + (rnd(i, 14) * h + math.sin(t * 3 + i) * 12) % h,
      ]);
    }
    c.drawRawPoints(
      ui.PointMode.points,
      Float32List.fromList(grains),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..color = const Color(0xFFF2CD8A).withValues(alpha: .45 * a * g),
    );
  }

  /// مطر وبرق: تعتيم بارد ومطر مائل ورذاذ على الأرض، والبرق يلمّع المشهد.
  void _rain(Canvas c, _Ext e, double t, double a) {
    final full = Rect.fromLTRB(e.l, e.t, e.r, e.b);
    final w = e.r - e.l, h = e.b - e.t;
    c.drawRect(full, _p..color = const Color(0xFF243B5E).withValues(alpha: .3 * a));
    c.drawRect(full, _p..color = const Color(0xFF06101F).withValues(alpha: .12 * a));
    for (var batch = 0; batch < 2; batch++) {
      final pts = <double>[];
      for (var i = batch; i < 150; i += 2) {
        final sp = 2200 + 1400 * rnd(i, 2);
        final y = e.t - 80 + (rnd(i, 3) * (h + 160) + t * sp) % (h + 160);
        final x = e.l - 200 + rnd(i, 1) * (w + 400) - (y - e.t) * .22;
        final len = 34 + 46 * rnd(i, 4);
        pts.addAll([x, y, x - len * .22, y + len]);
      }
      c.drawRawPoints(
        ui.PointMode.lines,
        Float32List.fromList(pts),
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = batch == 0 ? 1.8 : 2.8
          ..color = const Color(0xFFC6DCF6).withValues(alpha: (batch == 0 ? .2 : .38) * a),
      );
    }
    // رذاذ على الأرض
    for (var i = 0; i < 16; i++) {
      const life = .45;
      final cyc = t / life + rnd(i, 50);
      final pr = cyc % 1;
      final x = e.l + ((.1 + .8 * rnd(i, 51) + (cyc.floor() * .137) % .1) % 1) * w;
      final y = e.t + (.72 + .24 * rnd(i, 52)) * h;
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 8 + 32 * pr, height: 3 + 10 * pr),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFD8E8FF).withValues(alpha: (1 - pr) * .45 * a),
      );
    }
    // برق
    final k = (t / _boltPeriod).floor();
    final dt = t - _boltStart(k);
    final f = _flash(dt);
    if (f > 0) {
      c.drawRect(full, _p..color = const Color(0xFFDCE8FF).withValues(alpha: .45 * f * a));
      if (dt < .2) {
        final path = Path();
        var x = e.l + (.25 + .5 * rnd(k, 62)) * w, y = e.t;
        path.moveTo(x, y);
        for (var s = 0; s < 9; s++) {
          x += (rnd(s, 60 + k) - .5) * 104;
          y += 52 + rnd(s, 70 + k) * 40;
          path.lineTo(x, y);
        }
        c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..color = const Color(0xFFB8D0FF).withValues(alpha: .5 * f * a)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = Colors.white.withValues(alpha: _c01(f * a)),
        );
      }
    }
  }

  /// قصر: أشعة ضو ناعمة مائلة، وغبار ذهبي يطلع ويلمع.
  void _palace(Canvas c, _Ext e, double t, double a) {
    final w = e.r - e.l, h = e.b - e.t;
    for (var k = 0; k < 3; k++) {
      final x = e.l + (.16 + .3 * k) * w + math.sin(t * .35 + k * 2.1) * 40;
      final path = Path()
        ..moveTo(x, e.t)
        ..lineTo(x + 170, e.t)
        ..lineTo(x + 440, e.t + h * .78)
        ..lineTo(x + 150, e.t + h * .78)
        ..close();
      c.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(Offset(x, e.t), Offset(x + 290, e.t + h * .78), [
            const Color(0xFFFFE2A0).withValues(alpha: (.09 + .03 * math.sin(t * .8 + k)) * a),
            const Color(0x00FFE2A0),
          ]),
      );
    }
    for (var i = 0; i < 46; i++) {
      final x = e.l + ((rnd(i, 71) + math.sin(t * .3 + i) * .02) % 1) * w;
      final y = e.t + (1 - ((rnd(i, 72) + t * (.012 + .02 * rnd(i, 73))) % 1)) * h;
      final tw = .5 + .5 * math.sin(t * 2 + i);
      c.drawCircle(
        Offset(x, y),
        2 + 3 * rnd(i, 74),
        Paint()
          ..blendMode = BlendMode.plus
          ..color = const Color(0xFFFFD36A).withValues(alpha: (.15 + .35 * tw) * a),
      );
    }
  }

  /// الملوك: شرر ذهبي يطلع من تحت، ولمعة تمر بالشاشة كل ٩ ثواني.
  void _kings(Canvas c, _Ext e, double t, double a) {
    final w = e.r - e.l, h = e.b - e.t;
    for (var i = 0; i < 34; i++) {
      final pr = (t * (.07 + .1 * rnd(i, 81)) + rnd(i, 82)) % 1;
      final x = e.l + rnd(i, 83) * w + math.sin(pr * 8 + i) * 34;
      final y = e.b - pr * h * .95;
      final al = math.sin(math.pi * pr) * a;
      final sz = 2.4 + 3.4 * rnd(i, 84);
      final col = Color.lerp(const Color(0xFFFFE9A0), const Color(0xFFFFB02E), rnd(i, 85))!;
      c.drawCircle(
        Offset(x, y),
        sz * 3.2,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = col.withValues(alpha: .16 * al),
      );
      c.drawCircle(Offset(x, y), sz, _p..color = col.withValues(alpha: .9 * al));
    }
    final sp = (t % 9) / 2.6;
    if (sp < 1) {
      final x = _lerp(e.l - 400, e.r + 200, sp);
      final f = math.sin(math.pi * sp);
      final band = Path()
        ..moveTo(x, e.t)
        ..lineTo(x + 130, e.t)
        ..lineTo(x - 90, e.b)
        ..lineTo(x - 220, e.b)
        ..close();
      c.drawPath(
        band,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.linear(
            Offset(x - 60, e.t),
            Offset(x + 60, e.t),
            [const Color(0x00FFE9A0), const Color(0xFFFFE9A0).withValues(alpha: .13 * f * a), const Color(0x00FFE9A0)],
            const [0, .5, 1],
          ),
      );
    }
  }

  /// النخبة (وراء الطاولة): نجوم تلمع وشفق بنفسجي وذهبي يتموج في السما.
  void _vipBack(Canvas c, _Ext e, double t, double a) {
    _stars(c, e, t, a);
    final w = e.r - e.l;
    for (var k = 0; k < 3; k++) {
      final top = Path();
      final low = <Offset>[];
      for (var x = 0.0; x <= w; x += 40) {
        final yy = 215 + 46 * k + math.sin(x * .004 + t * (.32 + .1 * k) + k * 1.7) * 36;
        final th = 60 + 22 * math.sin(x * .006 + t * .5 + k);
        if (x == 0) {
          top.moveTo(e.l, yy);
        } else {
          top.lineTo(e.l + x, yy);
        }
        low.add(Offset(e.l + x, yy + th));
      }
      for (final o in low.reversed) {
        top.lineTo(o.dx, o.dy);
      }
      top.close();
      final col = k.isEven ? const Color(0xFFA77BFF) : const Color(0xFFFFC85A);
      c.drawPath(
        top,
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, 200.0 + 46 * k), Offset(0, 330.0 + 46 * k), [
            col.withValues(alpha: .26 * a),
            col.withValues(alpha: 0),
          ]),
      );
    }
  }

  /// النخبة (فوق الطاولة): لون بنفسجي خفيف ولمعات بنفسجية وذهبية تطير.
  void _vipFront(Canvas c, _Ext e, double t, double a) {
    final w = e.r - e.l, h = e.b - e.t;
    c.drawRect(Rect.fromLTRB(e.l, e.t, e.r, e.b), _p..color = const Color(0xFF3A1A6E).withValues(alpha: .08 * a));
    for (var i = 0; i < 26; i++) {
      final x = e.l + ((rnd(i, 91) + math.sin(t * .4 + i) * .015) % 1) * w;
      final y = e.t + (1 - ((rnd(i, 92) + t * (.01 + .018 * rnd(i, 93))) % 1)) * h;
      final tw = .5 + .5 * math.sin(t * 2.4 + i * 1.3);
      final col = i.isEven ? const Color(0xFFC9A8FF) : const Color(0xFFFFD36A);
      c.drawCircle(
        Offset(x, y),
        2 + 2.6 * rnd(i, 94),
        Paint()
          ..blendMode = BlendMode.plus
          ..color = col.withValues(alpha: (.12 + .34 * tw) * a),
      );
    }
  }

  @override
  bool shouldRepaint(_AtmoPainter old) => old.kind != kind || old.front != front || old.safe != safe;
}
