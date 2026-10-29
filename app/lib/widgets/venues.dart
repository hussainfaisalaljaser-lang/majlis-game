import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'design_game.dart';
import 'fx.dart';

/// المكان اللي تنلعب فيه الطاولة: خيمة الصحراء بالليل (مثل التصميم) هي الأصل، وكل مستوى يغيّر ألوانها
/// وخلفيتها البعيدة (كثبان، مدينة، أقواس قصر، أعمدة ذهب) بنفس أسلوب الرسم.
/// الرسمة الثابتة تنرسم مرة (السما والكثبان والستائر)، وطبقة حركة خفيفة (فوانيس، نار المخيم).
/// كل شي مرسوم بإحداثيات التصميم (١٩٢٠×١٠٨٠) داخل [Stage]، والسما والرمل يمتدون بكامل الشاشة.
enum Venue { majlis, desert, city, palace, kings, vip }

/// مكان الطاولة حسب مستواها (models/table_tier.dart).
Venue venueOf(String? tierId) => switch (tierId) {
  'starter' => Venue.desert,
  'city' => Venue.city,
  'palace' => Venue.palace,
  'kings' => Venue.kings,
  'vip' => Venue.vip,
  _ => Venue.majlis,
};

/// الخلفية البعيدة: كثبان، أو مدينة، أو أقواس، أو أعمدة.
enum TentMotif { dunes, skyline, arches, columns }

/// ألوان خيمة المكان.
class TentTheme {
  const TentTheme({
    required this.roof,
    required this.band,
    required this.flag,
    required this.skyTop,
    required this.skyBottom,
    required this.farLit,
    required this.farShade,
    required this.groundTop,
    required this.groundBottom,
    required this.curtain,
    required this.trim,
    this.motif = TentMotif.dunes,
    this.stars = true,
    this.moon = true,
    this.fire = const Color(0xFFFF8A1F),
    this.carpet = false,
  });

  final Color roof, band, flag;
  final Color skyTop, skyBottom;

  /// الجهة المضيئة والمظللة من الكثبان (أو الجدار البعيد).
  final Color farLit, farShade;
  final Color groundTop, groundBottom;

  /// الستارة: (الجهة البعيدة، الوسط، القريبة من الطاولة، الطيات الغامقة).
  final (Color, Color, Color, Color) curtain;

  /// زخرفة الستارة والذهب.
  final Color trim;
  final TentMotif motif;
  final bool stars, moon;
  final Color fire;
  final bool carpet;
}

const _desert = TentTheme(
  roof: Color(0xFF1E150E),
  band: Color(0xFF6E221C),
  flag: Color(0xFFF3D2AF),
  skyTop: Color(0xFF12153B),
  skyBottom: Color(0xFF2B3369),
  farLit: Color(0xFFC99A62),
  farShade: Color(0xFF9A6A42),
  groundTop: Color(0xFFB07845),
  groundBottom: Color(0xFF855632),
  curtain: (Color(0xFF7A1B18), Color(0xFFB02D22), Color(0xFFCB4331), Color(0xFF5C1210)),
  trim: Color(0xFFE5B04E),
);

TentTheme tentTheme(Venue v) => switch (v) {
  Venue.majlis || Venue.desert => _desert,
  Venue.city => const TentTheme(
    roof: Color(0xFF141A28),
    band: Color(0xFF1F4B5E),
    flag: Color(0xFFD8EEF2),
    skyTop: Color(0xFF0C1630),
    skyBottom: Color(0xFF3A4F82),
    farLit: Color(0xFF26345A),
    farShade: Color(0xFF1A2542),
    groundTop: Color(0xFF4A4A58),
    groundBottom: Color(0xFF2A2A36),
    curtain: (Color(0xFF0F4452), Color(0xFF1A6E80), Color(0xFF2A93A6), Color(0xFF0A2E38)),
    trim: Color(0xFFE5B04E),
    motif: TentMotif.skyline,
    fire: Color(0xFFFFB14A),
  ),
  Venue.palace => const TentTheme(
    roof: Color(0xFF1B1030),
    band: Color(0xFF5B2A86),
    flag: Color(0xFFEFE0FF),
    skyTop: Color(0xFF241447),
    skyBottom: Color(0xFF6A3C8F),
    farLit: Color(0xFF8E6BB0),
    farShade: Color(0xFF4B2E70),
    groundTop: Color(0xFF8B7A94),
    groundBottom: Color(0xFF55465F),
    curtain: (Color(0xFF3F1A66), Color(0xFF6A32A0), Color(0xFF8B4FC4), Color(0xFF2A1046)),
    trim: Color(0xFFF2D27A),
    motif: TentMotif.arches,
    fire: Color(0xFFFF9AC8),
  ),
  Venue.kings => const TentTheme(
    roof: Color(0xFF250C0E),
    band: Color(0xFF8E1B2B),
    flag: Color(0xFFFFE9A8),
    skyTop: Color(0xFF2B0F14),
    skyBottom: Color(0xFF6B2418),
    farLit: Color(0xFFC89A3A),
    farShade: Color(0xFF7E5A1C),
    groundTop: Color(0xFF9A7428),
    groundBottom: Color(0xFF5B4012),
    curtain: (Color(0xFF6E1020), Color(0xFFA81C34), Color(0xFFD2384F), Color(0xFF4A0A16)),
    trim: Color(0xFFFFD86A),
    motif: TentMotif.columns,
    moon: false,
  ),
  Venue.vip => const TentTheme(
    roof: Color(0xFF0A0A0E),
    band: Color(0xFF2B2230),
    flag: Color(0xFFE8C56A),
    skyTop: Color(0xFF08080D),
    skyBottom: Color(0xFF26202F),
    farLit: Color(0xFF3A3244),
    farShade: Color(0xFF1C1822),
    groundTop: Color(0xFF2E2D38),
    groundBottom: Color(0xFF14141A),
    curtain: (Color(0xFF1C1226), Color(0xFF3A2650), Color(0xFF55397A), Color(0xFF110A18)),
    trim: Color(0xFFF2C14E),
    motif: TentMotif.arches,
    fire: Color(0xFFFFD166),
  ),
};

/// الرسمة الثابتة للمكان.
CustomPainter venueBackdrop(Venue v, {EdgeInsets safe = EdgeInsets.zero}) => TentBackdropPainter(tentTheme(v), safe);

/// طبقة الحركة للمكان (فوانيس ونار). [tension] تحمّر النار والأضواء الدافية.
CustomPainter venueLights(Venue v, ValueListenable<double> time, double tension, {EdgeInsets safe = EdgeInsets.zero}) =>
    TentLightsPainter(tentTheme(v), time, tension, safe);

Paint _fill(Color c) => Paint()..color = c;

Paint _stroke(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..color = c;

/// يرسم بإحداثيات التصميم، ويعطي حدود الشاشة بنفس الإحداثيات.
typedef _Ext = ({double l, double t, double r, double b});

_Ext _enter(Canvas canvas, Size size, EdgeInsets safe) {
  final st = Stage(size, safe);
  canvas.save();
  canvas.translate(st.box.left, st.box.top);
  canvas.scale(st.s);
  return (
    l: -st.box.left / st.s,
    t: -st.box.top / st.s,
    r: (size.width - st.box.left) / st.s,
    b: (size.height - st.box.top) / st.s,
  );
}

class TentBackdropPainter extends CustomPainter {
  const TentBackdropPainter(this.theme, [this.safe = EdgeInsets.zero]);

  final TentTheme theme;
  final EdgeInsets safe;

  @override
  void paint(Canvas canvas, Size size) {
    final e = _enter(canvas, size, safe);
    final th = theme;
    // السما
    canvas.drawRect(
      Rect.fromLTRB(e.l, e.t, e.r, 640),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [th.skyTop, th.skyBottom],
        ).createShader(Rect.fromLTRB(e.l, 172, e.r, 560)),
    );
    if (th.stars) _stars(canvas, e);
    if (th.moon) _moon(canvas);
    switch (th.motif) {
      case TentMotif.dunes:
        _dunes(canvas, e, th);
      case TentMotif.skyline:
        _skyline(canvas, e, th);
      case TentMotif.arches:
        _arches(canvas, e, th);
      case TentMotif.columns:
        _columns(canvas, e, th);
    }
    _ground(canvas, e, th);
    _roof(canvas, e, th);
    for (final mirror in [false, true]) {
      canvas.save();
      if (mirror) {
        canvas.translate(1920, 0);
        canvas.scale(-1, 1);
      }
      _curtain(canvas, mirror ? 1920 - e.r : e.l, th);
      canvas.restore();
    }
    // تعتيم خفيف على الأطراف
    canvas.drawRect(
      Rect.fromLTRB(e.l, e.t, e.r, e.b),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, .1),
          radius: 1.1,
          colors: [Colors.transparent, Colors.black.withValues(alpha: .28)],
          stops: const [.6, 1],
        ).createShader(Rect.fromLTRB(e.l, e.t, e.r, e.b)),
    );
    canvas.restore();
  }

  void _stars(Canvas canvas, _Ext e) {
    final w = e.r - e.l;
    for (var i = 0; i < 90; i++) {
      final x = e.l + rnd(i, 1) * w;
      final y = 192 + rnd(i, 2) * 290;
      final r = .8 + rnd(i, 3) * 1.7;
      canvas.drawCircle(Offset(x, y), r, _fill(Colors.white.withValues(alpha: .35 + .6 * rnd(i, 4))));
    }
    for (var i = 0; i < 7; i++) {
      final c = Offset(e.l + rnd(i, 11) * w, 200 + rnd(i, 12) * 220);
      final r = 5 + rnd(i, 13) * 4;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r)
          ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
          ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
          ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r),
        _fill(const Color(0xFFFFF6D0).withValues(alpha: .85)),
      );
    }
  }

  void _moon(Canvas canvas) {
    const c = Offset(1416, 232);
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: 52)),
      Path()..addOval(Rect.fromCircle(center: c + const Offset(24, -16), radius: 46)),
    );
    canvas.drawCircle(
      c,
      100,
      Paint()
        ..shader = RadialGradient(colors: [const Color(0xFFFFE9A0).withValues(alpha: .18), const Color(0x00FFE9A0)])
            .createShader(Rect.fromCircle(center: c, radius: 100)),
    );
    canvas.drawPath(
      moon,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFF4B0), Color(0xFFF0CF63)],
        ).createShader(Rect.fromCircle(center: c, radius: 54)),
    );
    canvas.drawPath(moon, _stroke(const Color(0xFF6B4F14).withValues(alpha: .55), 2));
    // وجه نعسان: عين مغمضة وابتسامة
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(1395, 240), width: 20, height: 12),
      .15,
      math.pi * .75,
      false,
      _stroke(const Color(0xFF7A5A1A), 2.6),
    );
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(1403, 255), width: 14, height: 8),
      .2,
      math.pi * .6,
      false,
      _stroke(const Color(0xFF7A5A1A), 2.2),
    );
  }

  void _dunes(Canvas canvas, _Ext e, TentTheme th) {
    for (final mirror in [false, true]) {
      canvas.save();
      if (mirror) {
        canvas.translate(1920, 0);
        canvas.scale(-1, 1);
      }
      final l = mirror ? 1920 - e.r : e.l;
      // كثيب بعيد
      final far = Path()
        ..moveTo(l - 20, 560)
        ..cubicTo(100, 548, 230, 478, 380, 458)
        ..cubicTo(470, 448, 520, 480, 640, 540)
        ..lineTo(640, 700)
        ..lineTo(l - 20, 700)
        ..close();
      canvas.drawPath(far, _fill(th.farLit));
      // جهة الظل
      canvas.drawPath(
        Path()
          ..moveTo(380, 458)
          ..cubicTo(470, 448, 520, 480, 640, 540)
          ..lineTo(640, 700)
          ..lineTo(420, 700)
          ..cubicTo(440, 620, 420, 540, 380, 458),
        _fill(th.farShade),
      );
      canvas.drawPath(far, _stroke(Colors.black.withValues(alpha: .35), 2));
      // كثيب قريب أخفض
      final near = Path()
        ..moveTo(l - 20, 610)
        ..cubicTo(120, 580, 260, 545, 420, 560)
        ..lineTo(520, 700)
        ..lineTo(l - 20, 700)
        ..close();
      canvas.drawPath(near, _fill(Color.lerp(th.farLit, th.groundTop, .5)!));
      canvas.drawPath(
        Path()
          ..moveTo(240, 556)
          ..cubicTo(320, 548, 380, 552, 420, 560)
          ..lineTo(520, 700)
          ..lineTo(330, 700)
          ..cubicTo(330, 640, 300, 590, 240, 556),
        _fill(th.farShade.withValues(alpha: .65)),
      );
      canvas.drawPath(near, _stroke(Colors.black.withValues(alpha: .3), 2));
      canvas.restore();
    }
  }

  void _skyline(Canvas canvas, _Ext e, TentTheme th) {
    final w = e.r - e.l;
    var x = e.l - 10;
    var i = 0;
    while (x < e.r) {
      final bw = 70 + rnd(i, 21) * 80;
      final bh = 90 + rnd(i, 22) * 170;
      final rect = Rect.fromLTWH(x, 585 - bh, bw, bh + 20);
      canvas.drawRect(rect, _fill(i.isEven ? th.farLit : th.farShade));
      canvas.drawRect(rect, _stroke(Colors.black.withValues(alpha: .35), 2));
      // نوافذ مضيئة
      for (var wy = rect.top + 14; wy < 560; wy += 26) {
        for (var wx = rect.left + 10; wx < rect.right - 12; wx += 22) {
          if (rnd((wy * 31 + wx).toInt(), 23) > .55) {
            canvas.drawRect(Rect.fromLTWH(wx, wy, 9, 12), _fill(const Color(0xFFFFD27A).withValues(alpha: .85)));
          }
        }
      }
      // قبة ومنارة على بعض المباني
      if (rnd(i, 24) > .7) {
        canvas.drawArc(
          Rect.fromLTWH(x + bw * .2, rect.top - bw * .3, bw * .6, bw * .6),
          math.pi,
          math.pi,
          true,
          _fill(th.farLit),
        );
        canvas.drawLine(
          Offset(x + bw / 2, rect.top - bw * .3),
          Offset(x + bw / 2, rect.top - bw * .3 - 26),
          _stroke(const Color(0xFFE5B04E), 3),
        );
      }
      x += bw + 6;
      i++;
    }
    // توهج الأفق
    canvas.drawRect(
      Rect.fromLTRB(e.l, 470, e.r, 600),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, const Color(0xFFFFA45A).withValues(alpha: .22)],
        ).createShader(Rect.fromLTRB(e.l, 470, e.r, 600)),
    );
    assert(w > 0);
  }

  void _arches(Canvas canvas, _Ext e, TentTheme th) {
    final wall = Rect.fromLTRB(e.l, 300, e.r, 600);
    canvas.drawRect(wall, _fill(th.farShade));
    const step = 210.0;
    for (var cx = 105.0 - 10 * step; cx < e.r + step; cx += step) {
      if (cx < e.l - step) continue;
      final arch = Path()
        ..moveTo(cx - 70, 600)
        ..lineTo(cx - 70, 440)
        ..quadraticBezierTo(cx - 70, 340, cx, 320)
        ..quadraticBezierTo(cx + 70, 340, cx + 70, 440)
        ..lineTo(cx + 70, 600)
        ..close();
      canvas.drawPath(
        arch,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [th.skyTop, th.skyBottom],
          ).createShader(Rect.fromLTRB(cx - 70, 320, cx + 70, 600)),
      );
      canvas.drawPath(arch, _stroke(th.trim.withValues(alpha: .8), 5));
      canvas.drawPath(arch, _stroke(Colors.black.withValues(alpha: .4), 1.5));
    }
    canvas.drawRect(Rect.fromLTRB(e.l, 296, e.r, 308), _fill(th.trim.withValues(alpha: .8)));
  }

  void _columns(Canvas canvas, _Ext e, TentTheme th) {
    canvas.drawRect(Rect.fromLTRB(e.l, 330, e.r, 600), _fill(th.skyBottom));
    const step = 260.0;
    for (var cx = 130.0 - 10 * step; cx < e.r + step; cx += step) {
      if (cx < e.l - step) continue;
      final col = Rect.fromLTWH(cx - 34, 330, 68, 270);
      canvas.drawRect(
        col,
        Paint()..shader = LinearGradient(colors: [th.farShade, th.farLit, th.farShade]).createShader(col),
      );
      canvas.drawRect(col, _stroke(Colors.black.withValues(alpha: .4), 2));
      for (final dx in [-14.0, 0.0, 14.0]) {
        canvas.drawLine(Offset(cx + dx, 350), Offset(cx + dx, 590), _stroke(Colors.black.withValues(alpha: .18), 3));
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - 46, 316, 92, 26), const Radius.circular(6)),
        _fill(th.trim),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - 46, 316, 92, 26), const Radius.circular(6)),
        _stroke(Colors.black.withValues(alpha: .45), 2),
      );
    }
  }

  void _ground(Canvas canvas, _Ext e, TentTheme th) {
    final rect = Rect.fromLTRB(e.l, 586, e.r, e.b);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [th.groundTop, th.groundBottom],
        ).createShader(Rect.fromLTRB(e.l, 586, e.r, 1080)),
    );
    canvas.drawRect(Rect.fromLTRB(e.l, 586, e.r, 594), _fill(Colors.white.withValues(alpha: .12)));
    canvas.drawLine(Offset(e.l, 586), Offset(e.r, 586), _stroke(Colors.black.withValues(alpha: .3), 2));
    // تموجات الرمل
    final w = e.r - e.l;
    for (var k = 0; k < 11; k++) {
      final y = 640.0 + k * 46;
      final phase = rnd(k, 31) * 300;
      final path = Path()..moveTo(e.l, y);
      for (var x = e.l; x <= e.r + 120; x += 120) {
        path.quadraticBezierTo(x + 60, y + (k.isEven ? 7 : -7), x + 120, y + (rnd(k * 9 + (x ~/ 120), 32) - .5) * 5);
      }
      canvas.save();
      canvas.translate(-phase % 120, 0);
      canvas.drawPath(path, _stroke(Colors.black.withValues(alpha: .13), 3));
      canvas.drawPath(path.shift(const Offset(0, -4)), _stroke(Colors.white.withValues(alpha: .06), 2.5));
      canvas.restore();
    }
    assert(w > 0);
  }

  void _roof(Canvas canvas, _Ext e, TentTheme th) {
    canvas.drawRect(Rect.fromLTRB(e.l, e.t - 10, e.r, 154), _fill(th.roof));
    // شريط الزينة
    canvas.drawRect(Rect.fromLTRB(e.l, 150, e.r, 174), _fill(th.band));
    canvas.drawRect(Rect.fromLTRB(e.l, 150, e.r, 155), _fill(Colors.white.withValues(alpha: .12)));
    for (var x = e.l - (e.l % 21) - 21; x < e.r + 21; x += 21) {
      canvas.drawPath(
        Path()
          ..moveTo(x + 3, 173)
          ..lineTo(x + 18, 173)
          ..lineTo(x + 10.5, 157)
          ..close(),
        _fill(th.flag),
      );
    }
    canvas.drawLine(Offset(e.l, 174), Offset(e.r, 174), _stroke(Colors.black.withValues(alpha: .55), 2));
    // الطرف السفلي للسقف يتدلى بالنص
    canvas.drawPath(
      Path()
        ..moveTo(e.l, 174)
        ..lineTo(e.r, 174)
        ..lineTo(e.r, 180)
        ..quadraticBezierTo(960, 190, e.l, 180)
        ..close(),
      _fill(th.roof),
    );
    canvas.drawPath(
      Path()
        ..moveTo(e.l, 180)
        ..quadraticBezierTo(960, 190, e.r, 180),
      _stroke(Colors.black.withValues(alpha: .5), 2),
    );
  }

  /// ستارة الجهة اليسار بإحداثيات التصميم (اليمين نفسها مقلوبة). [l] أقصى امتداد للشمال.
  void _curtain(Canvas canvas, double l, TentTheme th) {
    final (far, mid, near, dark) = th.curtain;
    final top = -400.0;
    final body = Path()
      ..moveTo(l - 40, top)
      ..lineTo(240, top)
      ..lineTo(240, 100)
      ..cubicTo(236, 160, 212, 210, 170, 262)
      ..cubicTo(130, 312, 76, 376, 40, 432)
      ..lineTo(22, 448)
      ..lineTo(54, 474)
      ..cubicTo(64, 560, 66, 660, 52, 734)
      ..lineTo(28, 756)
      ..lineTo(l - 40, 756)
      ..close();
    final box = Rect.fromLTRB(l - 40, 0, 260, 760);
    canvas.save();
    canvas.drawPath(
      body.shift(const Offset(6, 6)),
      Paint()
        ..color = Colors.black.withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [far, mid, near, mid, near],
          stops: const [0, .3, .55, .8, 1],
        ).createShader(Rect.fromLTRB(0, 0, 260, 0)),
    );
    canvas.clipPath(body);
    // طيات من الأعلى لنقطة الربط
    const tie = Offset(30, 446);
    for (var i = 0; i < 8; i++) {
      final x = -30.0 + i * 38;
      final p = Path()
        ..moveTo(x, top)
        ..quadraticBezierTo(x + 40 + rnd(i, 41) * 30, 150, tie.dx + 6, tie.dy);
      canvas.drawPath(p, _stroke(dark.withValues(alpha: .38), 11));
      canvas.drawPath(p.shift(const Offset(9, 0)), _stroke(Colors.white.withValues(alpha: .08), 6));
    }
    // طيات الجزء النازل تحت الربط
    for (var i = 0; i < 3; i++) {
      final x = 8.0 + i * 18;
      canvas.drawLine(Offset(x, 474), Offset(x + 6, 750), _stroke(dark.withValues(alpha: .4), 8));
    }
    // شريط الزخرفة الذهبية على الطرف القريب
    final edge = Path()
      ..moveTo(228, 100)
      ..cubicTo(224, 160, 200, 210, 158, 262)
      ..cubicTo(118, 312, 66, 372, 40, 420);
    final m = edge.computeMetrics().first;
    final band = Path();
    final vine = Path();
    for (var d = 0.0; d <= m.length; d += 6) {
      final t = m.getTangentForOffset(d)!;
      final n = Offset(-t.vector.dy, t.vector.dx); // يمين المسار = داخل الستارة (للشمال)
      final wave = math.sin(d / 16) * 11;
      final p = t.position + n * (26 + wave);
      d == 0 ? vine.moveTo(p.dx, p.dy) : vine.lineTo(p.dx, p.dy);
      final q = t.position + n * 50;
      d == 0 ? band.moveTo(q.dx, q.dy) : band.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(edge.shift(const Offset(-24, 0)), _stroke(dark.withValues(alpha: .5), 58));
    canvas.drawPath(vine, _stroke(th.trim.withValues(alpha: .95), 3.6));
    canvas.drawPath(band, _stroke(th.trim.withValues(alpha: .8), 2.6));
    canvas.drawPath(edge.shift(const Offset(-4, 0)), _stroke(th.trim.withValues(alpha: .85), 2.6));
    for (var d = 8.0; d < m.length; d += 32) {
      final t = m.getTangentForOffset(d)!;
      final n = Offset(-t.vector.dy, t.vector.dx);
      canvas.drawCircle(t.position + n * (26 + math.sin(d / 16) * 11), 3.4, _fill(th.trim));
    }
    canvas.restore();
    canvas.drawPath(body, _stroke(const Color(0xFF200806), 4));
    // شريط الربط الذهبي
    final band2 = RRect.fromRectAndRadius(Rect.fromLTRB(l - 40, 426, 46, 462), const Radius.circular(10));
    canvas.drawRRect(
      band2,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFFFE9A0), th.trim, const Color(0xFF9A6418)],
        ).createShader(band2.outerRect),
    );
    canvas.drawRRect(band2, _stroke(const Color(0xFF4A2A08), 3));
    canvas.drawLine(const Offset(0, 436), const Offset(40, 436), _stroke(Colors.white.withValues(alpha: .5), 2));
    assert(box.width > 0);
  }

  @override
  bool shouldRepaint(TentBackdropPainter old) => old.theme != theme || old.safe != safe;
}

/// الفوانيس المعلقة ونار المخيم: ترمش وتتمايل مع الوقت، وتحمر مع التوتر.
class TentLightsPainter extends CustomPainter {
  TentLightsPainter(this.theme, this.time, this.tension, [this.safe = EdgeInsets.zero]) : super(repaint: time);

  final TentTheme theme;
  final ValueListenable<double> time;
  final double tension;
  final EdgeInsets safe;

  @override
  void paint(Canvas canvas, Size size) {
    final e = _enter(canvas, size, safe);
    final t = time.value;
    final warm = Color.lerp(const Color(0xFFFFC857), const Color(0xFFFF3B3B), tension)!;
    for (final (i, x) in [243.0, 1677.0].indexed) {
      _lantern(canvas, Offset(x, 322), e.t, t, i, warm, tension);
    }
    final fire = Color.lerp(theme.fire, const Color(0xFFFF3B3B), tension * .6)!;
    _campfire(canvas, const Offset(108, 752), t, 0, fire);
    _campfire(canvas, const Offset(1796, 752), t, 1, fire);
    canvas.restore();
  }

  /// فانوس معلق بحبل من فوق الشاشة.
  void _lantern(Canvas canvas, Offset c, double top, double t, int i, Color warm, double tension) {
    final flick =
        1 - (.1 + .5 * tension) * (.5 + .25 * math.sin(t * 9.1 + i * 2.3) + .25 * math.sin(t * 23.7 + i * 1.1));
    final sway = math.sin(t * 1.3 + i * 1.7) * 2.2;
    // الهالة
    canvas.drawCircle(
      c,
      170,
      Paint()
        ..shader = RadialGradient(
          colors: [
            warm.withValues(alpha: .42 * flick),
            warm.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: 170)),
    );
    final rope = Path()
      ..moveTo(c.dx, top)
      ..lineTo(c.dx + sway * .3, c.dy - 62);
    canvas.drawPath(rope, _stroke(gameInk, 8));
    canvas.drawPath(rope, _stroke(const Color(0xFF8A6A3C), 4.5));
    canvas.save();
    canvas.translate(c.dx + sway * .3, c.dy - 56);
    canvas.rotate(sway * .01);
    // حلقة وغطا
    canvas.drawCircle(const Offset(0, 4), 8, _stroke(gameInk, 5));
    canvas.drawCircle(const Offset(0, 4), 8, _stroke(const Color(0xFFC9A04E), 2.6));
    final cap = Path()
      ..moveTo(-16, 22)
      ..quadraticBezierTo(-8, 8, 0, 6)
      ..quadraticBezierTo(8, 8, 16, 22)
      ..close();
    canvas.drawPath(cap, _fill(const Color(0xFF5A3A1E)));
    canvas.drawPath(cap, _stroke(gameInk, 3.5));
    // الجسم الزجاجي
    final glass = Path()
      ..moveTo(-24, 22)
      ..lineTo(24, 22)
      ..quadraticBezierTo(32, 56, 22, 90)
      ..lineTo(-22, 90)
      ..quadraticBezierTo(-32, 56, -24, 22)
      ..close();
    canvas.drawPath(
      glass,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, .1),
          colors: [
            Color.lerp(warm, Colors.white, .75)!.withValues(alpha: flick),
            warm.withValues(alpha: flick),
            Color.lerp(warm, const Color(0xFFB8600A), .6)!,
          ],
        ).createShader(const Rect.fromLTWH(-32, 22, 64, 68)),
    );
    // شعلة صغيرة
    canvas.drawPath(
      Path()
        ..moveTo(0, 38)
        ..quadraticBezierTo(8, 54, 0, 70)
        ..quadraticBezierTo(-8, 54, 0, 38),
      _fill(Colors.white.withValues(alpha: .9 * flick)),
    );
    for (final x in [-10.0, 10.0]) {
      canvas.drawLine(Offset(x * 1.1, 24), Offset(x * 1.05, 90), _stroke(const Color(0xFF5A3A1E), 3.4));
    }
    canvas.drawPath(glass, _stroke(gameInk, 4));
    // القاعدة
    final base = RRect.fromRectAndRadius(const Rect.fromLTWH(-26, 88, 52, 12), const Radius.circular(5));
    canvas.drawRRect(base, _fill(const Color(0xFF8A5E2E)));
    canvas.drawRRect(base, _stroke(gameInk, 3.4));
    canvas.drawCircle(const Offset(0, 108), 5, _fill(const Color(0xFFC9A04E)));
    canvas.drawCircle(const Offset(0, 108), 5, _stroke(gameInk, 2.4));
    canvas.restore();
  }

  /// نار مخيم: حجار حواليها وألسنة لهب وشرار طاير.
  void _campfire(Canvas canvas, Offset c, double t, int i, Color fire) {
    // ضو على الرمل
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(0, 24), width: 460, height: 150),
      Paint()
        ..shader = RadialGradient(colors: [fire.withValues(alpha: .38), fire.withValues(alpha: 0)])
            .createShader(Rect.fromCenter(center: c + const Offset(0, 24), width: 460, height: 150)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(0, 46), width: 220, height: 40),
      _fill(Colors.black.withValues(alpha: .3)),
    );
    // الحجار الخلفية
    void stone(Offset p, double w, double h, Color col) {
      final r = Rect.fromCenter(center: c + p, width: w, height: h);
      canvas.drawOval(r, _fill(col));
      canvas.drawOval(r, _stroke(gameInk, 3.4));
      canvas.drawArc(r.deflate(5), math.pi * 1.1, math.pi * .5, false, _stroke(Colors.white.withValues(alpha: .25), 3));
    }

    for (final (dx, dy, w, h) in const [
      (-62.0, 18.0, 46.0, 30.0),
      (-20.0, 8.0, 46.0, 28.0),
      (28.0, 8.0, 46.0, 28.0),
      (66.0, 18.0, 44.0, 30.0),
    ]) {
      stone(Offset(dx, dy), w, h, const Color(0xFF6E6862));
    }
    // الجمر
    final embers = Rect.fromCenter(center: c + const Offset(0, 16), width: 120, height: 32);
    canvas.drawOval(embers, _fill(const Color(0xFF3A1208)));
    canvas.drawOval(
      embers.deflate(6),
      _fill(Color.lerp(const Color(0xFFB23A12), const Color(0xFFFF8A1F), .5 + .5 * math.sin(t * 6 + i))!),
    );
    // ألسنة اللهب
    void flame(double w, double h, Color col, double phase, double dx) {
      final sway = math.sin(t * 5 + phase) * w * .12;
      final hh = h * (1 + .08 * math.sin(t * 9 + phase * 2));
      final top = c + Offset(dx + sway * 1.8, 8 - hh);
      final path = Path()
        ..moveTo(c.dx + dx - w / 2, c.dy + 14)
        ..cubicTo(c.dx + dx - w * .65, c.dy - hh * .25, c.dx + dx - w * .2 + sway, c.dy - hh * .55, top.dx, top.dy)
        ..cubicTo(
          c.dx + dx + w * .25 + sway,
          c.dy - hh * .5,
          c.dx + dx + w * .7,
          c.dy - hh * .2,
          c.dx + dx + w / 2,
          c.dy + 14,
        )
        ..close();
      canvas.drawPath(path, _fill(col));
    }

    flame(80, 112, const Color(0xFFE8531A), 0, -6);
    flame(54, 84, const Color(0xFFFF8A1F), 1.3, 14);
    flame(66, 96, const Color(0xFFFFA52E), 2.1, -2);
    flame(38, 62, const Color(0xFFFFD54A), .7, 4);
    flame(20, 36, const Color(0xFFFFF4C4), 1.9, 2);
    // حجار أمامية
    for (final (dx, dy, w, h) in const [
      (-40.0, 34.0, 54.0, 34.0),
      (6.0, 38.0, 54.0, 32.0),
      (52.0, 34.0, 52.0, 32.0),
      (-86.0, 28.0, 44.0, 28.0),
      (92.0, 28.0, 44.0, 28.0),
    ]) {
      stone(Offset(dx, dy), w, h, const Color(0xFF8A847C));
    }
    // شرار
    for (var k = 0; k < 9; k++) {
      final q = (t * (.35 + rnd(k, 51 + i) * .3) + rnd(k, 52 + i)) % 1;
      final x = c.dx + (rnd(k, 53 + i) - .5) * 90 + math.sin(t * 2 + k) * 14 * q;
      final y = c.dy - 30 - q * 190;
      canvas.drawCircle(
        Offset(x, y),
        1.6 + 2.2 * (1 - q) * rnd(k, 54),
        _fill(const Color(0xFFFFC857).withValues(alpha: (1 - q) * .9)),
      );
    }
  }

  @override
  bool shouldRepaint(TentLightsPainter old) => old.tension != tension || old.theme != theme || old.safe != safe;
}
