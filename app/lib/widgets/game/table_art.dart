import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../design_game.dart';
import '../fx.dart';

/// رسمات الطاولة: السجادة بزخرفتها وحبالها وأوتادها، والبيضاوي الذهبي في نصها. كلها بإحداثيات التصميم (١٩٢٠×١٠٨٠)
/// داخل [Stage]، فتناسب أي شاشة.

/// ألوان السجادة (كل شكل طاولة من المتجر له ألوانه، والأصل الخمري مثل التصميم).
class CarpetPalette {
  const CarpetPalette({
    required this.base,
    required this.edge,
    required this.line,
    required this.oval,
    this.ovalInk = const Color(0xFF3A2400),
  });

  /// تدرج الأرضية: (الوسط، الأطراف).
  final Color base, edge;

  /// لون الزخرفة والحدود.
  final Color line;

  /// تدرج البيضاوي: (فوق، وسط، تحت).
  final (Color, Color, Color) oval;
  final Color ovalInk;

  static const majlis = CarpetPalette(
    base: Color(0xFF67241B),
    edge: Color(0xFF47160F),
    line: Color(0xFFBF8E4A),
    oval: (Color(0xFFFFE580), Color(0xFFE7BC48), Color(0xFFB8861C)),
  );

  static const _all = {
    'majlis': majlis,
    'gold': CarpetPalette(
      base: Color(0xFF2A2218),
      edge: Color(0xFF14100B),
      line: Color(0xFFE3B24D),
      oval: (Color(0xFFFFE58A), Color(0xFFE5B73C), Color(0xFFA9781A)),
    ),
    'night': CarpetPalette(
      base: Color(0xFF26337A),
      edge: Color(0xFF151D52),
      line: Color(0xFFC6D0F2),
      oval: (Color(0xFFF7F4E8), Color(0xFFD3CFBC), Color(0xFF9F9A86)),
    ),
    'oasis': CarpetPalette(
      base: Color(0xFF1F8560),
      edge: Color(0xFF0F5238),
      line: Color(0xFFE8C265),
      oval: (Color(0xFFFFE58A), Color(0xFFE7BC48), Color(0xFFB8861C)),
    ),
    'palace': CarpetPalette(
      base: Color(0xFF6A3A96),
      edge: Color(0xFF3C1D63),
      line: Color(0xFFE6CC8A),
      oval: (Color(0xFFFFE9A0), Color(0xFFE9C255), Color(0xFFBA8A28)),
    ),
    's1': CarpetPalette(
      base: Color(0xFF1B7276),
      edge: Color(0xFF0D4448),
      line: Color(0xFFE8C265),
      oval: (Color(0xFFFFE58A), Color(0xFFE7BC48), Color(0xFFB8861C)),
    ),
    'sand': CarpetPalette(
      base: Color(0xFFDDB880),
      edge: Color(0xFFB48849),
      line: Color(0xFF7A4E22),
      oval: (Color(0xFFFFF0BC), Color(0xFFF0CF78), Color(0xFFC79A3A)),
    ),
  };

  /// لون السجادة من مسار صورتها في المتجر (assets/tables/carpet_xxx.webp).
  static CarpetPalette of(String carpetAsset) {
    final id = RegExp(r'carpet_(\w+)\.').firstMatch(carpetAsset)?.group(1);
    return _all[id] ?? majlis;
  }
}

// ───────── مواقع ثابتة بإحداثيات التصميم

abstract final class TablePos {
  /// زوايا السجادة (عريضة من تحت، مثل منظور الأرض).
  static const tl = Offset(428, 292), tr = Offset(1508, 292), br = Offset(1618, 866), bl = Offset(320, 866);

  /// نص البيضاوي وحجمه.
  static const oval = Offset(958, 568);
  static const ovalRx = 296.0, ovalRy = 176.0;

  /// كومة السحب (يمين) والرمي (يسار).
  static const draw = Offset(1405, 548);
  static const discard = Offset(510, 552);
  static const pileW = 130.0;

  /// لوح الرسالة تحت.
  static const plank = Rect.fromLTWH(665, 800, 590, 92);

  /// مكان رئيس الحكومة ووزيرها داخل البيضاوي.
  static const president = Offset(1085, 535);
  static const minister = Offset(835, 535);
  static const crownBadge = Offset(958, 568);

  /// نقطة على السجادة: [u] من اليسار لليمين، [v] من فوق لتحت (٠–١).
  static Offset carpet(double u, double v) {
    final top = Offset.lerp(tl, tr, u)!;
    final bottom = Offset.lerp(bl, br, u)!;
    return Offset.lerp(top, bottom, v)!;
  }
}

Paint _stroke(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..color = c;

/// السجادة مع الأوتاد والحبال. تنرسم مرة وحدة.
class CarpetPainter extends CustomPainter {
  const CarpetPainter(this.palette);

  final CarpetPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final st = Stage(Size(size.width, size.height));
    canvas.save();
    canvas.translate(st.box.left, st.box.top);
    canvas.scale(st.s);
    final p = palette;
    // حافة السجادة بنتوءات خفيفة (قماش)
    final edge = _edge();
    canvas.drawPath(
      edge.shift(const Offset(0, 16)),
      Paint()
        ..color = Colors.black.withValues(alpha: .42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawPath(
      edge,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -.05),
          radius: .95,
          colors: [p.base, Color.lerp(p.base, p.edge, .55)!, p.edge],
          stops: const [0, .55, 1],
        ).createShader(Rect.fromLTRB(320, 292, 1618, 866)),
    );
    canvas.save();
    canvas.clipPath(edge);
    _pattern(canvas, p);
    canvas.restore();
    canvas.drawPath(edge, _stroke(const Color(0xFF260B07), 4));
    _ropes(canvas);
    canvas.restore();
  }

  Path _edge() {
    // نقط على الأضلاع الأربعة مع ازاحة ثابتة صغيرة
    final path = Path();
    var first = true;
    void side(Offset a, Offset b, int seed) {
      const n = 26;
      for (var i = 0; i < n; i++) {
        final t = i / n;
        final pt = Offset.lerp(a, b, t)! + Offset((rnd(i, seed) - .5) * 5, (rnd(i, seed + 1) - .5) * 5);
        if (first) {
          path.moveTo(pt.dx, pt.dy);
          first = false;
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
    }

    side(TablePos.tl, TablePos.tr, 1);
    side(TablePos.tr, TablePos.br, 2);
    side(TablePos.br, TablePos.bl, 3);
    side(TablePos.bl, TablePos.tl, 4);
    return path..close();
  }

  Path _frame(double du, double dv) => Path()
    ..moveTo(TablePos.carpet(du, dv).dx, TablePos.carpet(du, dv).dy)
    ..lineTo(TablePos.carpet(1 - du, dv).dx, TablePos.carpet(1 - du, dv).dy)
    ..lineTo(TablePos.carpet(1 - du, 1 - dv).dx, TablePos.carpet(1 - du, 1 - dv).dy)
    ..lineTo(TablePos.carpet(du, 1 - dv).dx, TablePos.carpet(du, 1 - dv).dy)
    ..close();

  void _pattern(Canvas canvas, CarpetPalette p) {
    final line = p.line;
    // ظل داخلي عند الأطراف
    canvas.drawPath(
      _frame(0, 0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 36
        ..color = Colors.black.withValues(alpha: .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    // إطارات الحدود
    canvas.drawPath(_frame(.026, .044), _stroke(line.withValues(alpha: .8), 2.4));
    canvas.drawPath(_frame(.04, .068), _stroke(line.withValues(alpha: .55), 1.5));
    canvas.drawPath(_frame(.092, .158), _stroke(line.withValues(alpha: .75), 2.2));
    canvas.drawPath(_frame(.104, .178), _stroke(line.withValues(alpha: .45), 1.3));
    // شريط الزخرفة بين الإطارين الأولين: غصن متموج بورقات صغيرة
    final vine = _stroke(line.withValues(alpha: .7), 1.8);
    final leaf = Paint()..color = line.withValues(alpha: .6);
    void band(Offset Function(double t) at, Offset Function(double t) nrm, int count) {
      final path = Path();
      for (var i = 0; i <= count * 6; i++) {
        final t = i / (count * 6);
        final w = math.sin(t * count * math.pi * 2);
        final pt = at(t) + nrm(t) * (w * 4.5);
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, vine);
      for (var k = 0; k < count; k++) {
        final t = (k + .25) / count;
        final c = at(t) + nrm(t) * 5;
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy)
            ..quadraticBezierTo(c.dx + nrm(t).dx * 8 + 3, c.dy + nrm(t).dy * 8 - 3, c.dx + 7, c.dy - 1)
            ..quadraticBezierTo(c.dx + 3, c.dy + 4, c.dx, c.dy),
          leaf,
        );
        canvas.drawCircle(at(t + .5 / count) - nrm(t) * 5, 1.8, leaf);
      }
    }

    band((t) => TablePos.carpet(.045 + t * .91, .056), (_) => const Offset(0, 1), 34);
    band((t) => TablePos.carpet(.045 + t * .91, .944), (_) => const Offset(0, 1), 34);
    band((t) => TablePos.carpet(.033, .08 + t * .84), (_) => const Offset(1, 0), 14);
    band((t) => TablePos.carpet(.967, .08 + t * .84), (_) => const Offset(1, 0), 14);
    // زخرفة الزوايا
    for (final (cu, cv, sx, sy) in [
      (.105, .18, 1.0, 1.0),
      (.895, .18, -1.0, 1.0),
      (.105, .82, 1.0, -1.0),
      (.895, .82, -1.0, -1.0),
    ]) {
      final o = TablePos.carpet(cu, cv);
      final ex = (TablePos.carpet(cu + .02, cv) - o) / (TablePos.carpet(cu + .02, cv) - o).distance * sx;
      final ey = (TablePos.carpet(cu, cv + .02) - o) / (TablePos.carpet(cu, cv + .02) - o).distance * sy;
      canvas.save();
      canvas.transform(Float64List.fromList([ex.dx, ex.dy, 0, 0, ey.dx, ey.dy, 0, 0, 0, 0, 1, 0, o.dx, o.dy, 0, 1]));
      _cornerOrnament(canvas, line);
      canvas.restore();
    }
    // زخرفة منتصف الأعلى والأسفل
    for (final (v, sy) in [(.135, 1.0), (.865, -1.0)]) {
      final o = TablePos.carpet(.5, v);
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.scale(1, sy);
      _crownOrnament(canvas, line);
      canvas.restore();
    }
    // زخرفة الجنبين جنب البيضاوي
    for (final (u, sx) in [(.262, 1.0), (.738, -1.0)]) {
      final o = TablePos.carpet(u, .5);
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.scale(sx, 1);
      _sideOrnament(canvas, line);
      canvas.restore();
    }
  }

  /// ورقة زاوية: زهرة صغيرة وغصنين ملفوفين على الإطارين، بإحداثيات محلية (٠،٠ عند الزاوية، والمحاور للداخل).
  void _cornerOrnament(Canvas canvas, Color c) {
    final line = _stroke(c.withValues(alpha: .8), 2);
    final soft = _stroke(c.withValues(alpha: .5), 1.4);
    final fill = Paint()..color = c.withValues(alpha: .28);
    for (final flip in [false, true]) {
      canvas.save();
      if (flip) canvas.transform(Float64List.fromList([0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]));
      final tendril = Path()
        ..moveTo(10, 8)
        ..cubicTo(48, 4, 70, 30, 104, 22)
        ..cubicTo(126, 16, 132, -2, 118, -8)
        ..cubicTo(108, -12, 100, -2, 108, 4);
      canvas.drawPath(tendril, line);
      final leaf = Path()
        ..moveTo(44, 12)
        ..quadraticBezierTo(54, 40, 82, 44)
        ..quadraticBezierTo(76, 18, 44, 12);
      canvas.drawPath(leaf, fill);
      canvas.drawPath(leaf, soft);
      canvas.drawPath(
        Path()
          ..moveTo(62, 14)
          ..quadraticBezierTo(72, 2, 90, 6)
          ..quadraticBezierTo(80, 16, 62, 14),
        fill,
      );
      canvas.restore();
    }
    // زهرة زنبق مزخرفة عند الزاوية: بتلة وسطى وبتلتين ملفوفتين وغصن صغير
    final fleur = Path()
      ..moveTo(52, 52)
      ..cubicTo(40, 36, 44, 18, 62, 8)
      ..cubicTo(70, 22, 66, 40, 52, 52)
      ..moveTo(52, 52)
      ..cubicTo(36, 40, 18, 44, 8, 62)
      ..cubicTo(22, 70, 40, 66, 52, 52);
    canvas.drawPath(fleur, fill);
    canvas.drawPath(fleur, line);
    canvas.drawPath(
      Path()
        ..moveTo(24, 24)
        ..cubicTo(44, 28, 58, 44, 56, 70)
        ..cubicTo(54, 86, 40, 90, 34, 80)
        ..cubicTo(30, 72, 38, 66, 44, 72),
      soft,
    );
    canvas.drawPath(
      Path()
        ..moveTo(24, 24)
        ..cubicTo(28, 44, 44, 58, 70, 56)
        ..cubicTo(86, 54, 90, 40, 80, 34)
        ..cubicTo(72, 30, 66, 38, 72, 44),
      soft,
    );
    canvas.drawCircle(const Offset(16, 16), 6, _stroke(c.withValues(alpha: .85), 2));
    canvas.drawCircle(const Offset(16, 16), 2.2, Paint()..color = c.withValues(alpha: .9));
    for (var k = 0; k < 5; k++) {
      final a = k * math.pi / 8;
      canvas.drawCircle(
        Offset(26 + math.cos(a) * 20, 26 + math.sin(a) * 20),
        1.6,
        Paint()..color = c.withValues(alpha: .55),
      );
    }
  }

  /// زخرفة فوق البيضاوي: قوس مدبب بينه دائرتين مزخرفتين.
  void _crownOrnament(Canvas canvas, Color c) {
    final line = _stroke(c.withValues(alpha: .8), 3);
    final soft = _stroke(c.withValues(alpha: .55), 2);
    canvas.drawPath(
      Path()
        ..moveTo(-52, 26)
        ..quadraticBezierTo(-40, -6, 0, -26)
        ..quadraticBezierTo(40, -6, 52, 26),
      line,
    );
    for (final sx in [-1.0, 1.0]) {
      final o = Offset(sx * 96, 6);
      canvas.drawCircle(o, 24, line);
      canvas.drawCircle(o, 14, soft);
      canvas.drawCircle(o, 4, Paint()..color = c.withValues(alpha: .7));
      canvas.drawPath(
        Path()
          ..moveTo(sx * 62, 28)
          ..quadraticBezierTo(sx * 74, 24, sx * 80, 18),
        soft,
      );
    }
  }

  void _sideOrnament(Canvas canvas, Color c) {
    final line = _stroke(c.withValues(alpha: .8), 3);
    canvas.drawPath(
      Path()
        ..moveTo(-40, 0)
        ..lineTo(-18, -16)
        ..lineTo(8, 0)
        ..lineTo(-18, 16)
        ..close(),
      line,
    );
    canvas.drawLine(const Offset(-40, 0), const Offset(-70, 0), line);
    canvas.drawCircle(const Offset(-76, 0), 4.5, Paint()..color = c.withValues(alpha: .8));
  }

  /// الأوتاد والحبال اللي تثبت السجادة بالأرض.
  void _ropes(Canvas canvas) {
    for (final mirror in [false, true]) {
      canvas.save();
      if (mirror) {
        canvas.translate(1920, 0);
        canvas.scale(-1, 1);
      }
      // حبال: من الوتد العلوي لوتد صغير على الجنب، ومن وتد الجنب للسجادة
      void rope(Offset a, Offset b, double sag) {
        final mid = Offset.lerp(a, b, .5)! + Offset(-sag * .4, sag);
        final path = Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
        canvas.drawPath(path, _stroke(gameInk, 13));
        canvas.drawPath(path, _stroke(const Color(0xFFCBB08A), 8.4));
        canvas.drawPath(path, _stroke(const Color(0xFF8A6E4C).withValues(alpha: .8), 2.2));
      }

      rope(const Offset(412, 318), const Offset(356, 430), 18);
      rope(const Offset(300, 716), const Offset(344, 650), 12);
      _stake(canvas, const Offset(392, 288), -.16, 1.0, wrap: true);
      _stake(canvas, const Offset(346, 452), 1.0, .72, short: true);
      _stake(canvas, const Offset(292, 724), .42, .86, short: true, wrap: true);
      _stake(canvas, const Offset(318, 884), -.1, 1.0, wrap: true);
      canvas.restore();
    }
  }

  /// وتد خشب مائل بحبل ملفوف عليه.
  void _stake(Canvas canvas, Offset base, double angle, double scale, {bool wrap = false, bool short = false}) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    canvas.scale(scale);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(8, 56), width: 70, height: 16),
      Paint()..color = Colors.black.withValues(alpha: .3),
    );
    final top = short ? -18.0 : -44.0;
    final post = Path()
      ..moveTo(-15, top)
      ..lineTo(15, top - 4)
      ..lineTo(18, 50)
      ..lineTo(-14, 54)
      ..close();
    canvas.drawPath(
      post,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF6E4A2A), Color(0xFFA07A48), Color(0xFF6E4A2A)])
            .createShader(const Rect.fromLTWH(-15, -48, 33, 100)),
    );
    canvas.drawPath(post, _stroke(gameInk, 4));
    canvas.drawLine(Offset(-3, top + 6), const Offset(-2, 46), _stroke(Colors.black.withValues(alpha: .22), 2.4));
    if (wrap) {
      for (final y in [-18.0, -4.0, 10.0]) {
        final loop = Path()
          ..moveTo(-17, y)
          ..quadraticBezierTo(0, y + 12, 19, y - 2);
        canvas.drawPath(loop, _stroke(gameInk, 8));
        canvas.drawPath(loop, _stroke(const Color(0xFFD2B98C), 4.8));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CarpetPainter old) => old.palette != palette;
}

/// البيضاوي الذهبي في نص السجادة (يعرض الرئيس والوزير).
class OvalPainter extends CustomPainter {
  const OvalPainter(this.palette);

  final CarpetPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final st = Stage(Size(size.width, size.height));
    canvas.save();
    canvas.translate(st.box.left, st.box.top);
    canvas.scale(st.s);
    final c = TablePos.oval;
    Rect r(double dx, double dy) =>
        Rect.fromCenter(center: c, width: (TablePos.ovalRx - dx) * 2, height: (TablePos.ovalRy - dy) * 2);
    final (top, mid, bottom) = palette.oval;
    final outer = r(0, 0);
    canvas.drawOval(
      outer.shift(const Offset(0, 16)),
      Paint()
        ..color = Colors.black.withValues(alpha: .45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawOval(outer, Paint()..color = const Color(0xFF3A2208));
    // الحافة المرتفعة
    canvas.drawOval(
      r(4, 4),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, mid, bottom],
          stops: const [0, .5, 1],
        ).createShader(outer),
    );
    canvas.drawOval(r(4, 4), _stroke(const Color(0xFF8A5E10).withValues(alpha: .9), 3));
    // الحقل الداخلي
    final inner = r(36, 30);
    canvas.drawOval(inner.shift(const Offset(0, 4)), Paint()..color = const Color(0xFF8A5E10).withValues(alpha: .35));
    canvas.drawOval(
      inner,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.1, -.5),
          radius: 1.1,
          colors: [Color.lerp(top, Colors.white, .35)!, mid, Color.lerp(mid, bottom, .45)!],
          stops: const [0, .55, 1],
        ).createShader(inner),
    );
    canvas.drawOval(inner, _stroke(Color.lerp(top, Colors.white, .6)!.withValues(alpha: .9), 3));
    canvas.drawOval(inner.deflate(7), _stroke(const Color(0xFF9A6A14).withValues(alpha: .35), 2));
    // لمعة على الحافة العلوية
    canvas.drawArc(r(14, 12), math.pi * 1.08, math.pi * .45, false, _stroke(Colors.white.withValues(alpha: .6), 5));
    canvas.restore();
  }

  @override
  bool shouldRepaint(OvalPainter old) => old.palette != palette;
}
