import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/shop.dart';
import 'design_bubbles_core.dart';
import 'fx.dart' show rnd;

/// رسمات الفقاعات المصورة: لكل فقاعة بالمتجر شكلها وزخارفها وحركتها.
/// كل شي يتحرك من الوقت [BubbleCtx.t] (ساعة FxClock)، والرسم خفيف: بدون blur ولا طبقات.

/// قالب الفقاعة حسب رسمتها.
BubbleArtSpec bubbleArtOf(BubbleLook look) => _arts[look]!;

const _arts = <BubbleLook, BubbleArtSpec>{
  BubbleLook.parchment: ParchmentArt(),
  BubbleLook.gold: GoldArt(),
  BubbleLook.silver: SilverArt(),
  BubbleLook.desert: DesertArt(),
  BubbleLook.sea: SeaArt(),
  BubbleLook.ice: IceArt(),
  BubbleLook.fire: FireArt(),
  BubbleLook.emerald: EmeraldArt(),
  BubbleLook.night: NightArt(),
  BubbleLook.coffee: CoffeeArt(),
  BubbleLook.royal: RoyalArt(),
  BubbleLook.blood: BloodArt(),
  BubbleLook.neon: NeonArt(),
  BubbleLook.galaxy: GalaxyArt(),
  BubbleLook.rose: RoseArt(),
  BubbleLook.lightning: LightningArt(),
  BubbleLook.rainbow: RainbowArt(),
  BubbleLook.crescent: CrescentArt(),
  BubbleLook.lanterns: LanternsArt(),
  BubbleLook.storm: StormArt(),
  BubbleLook.starter: StarterArt(),
  BubbleLook.diamond: DiamondArt(),
  BubbleLook.elite: EliteArt(),
};

// ───────────────────────── أدوات مشتركة بين الفقاعات ─────────────────────────

/// نقطة داخل الجسم بنسبة (x,y) من عرضه وطوله.
Offset _at(BubbleCtx c, double fx, double fy) => Offset(c.body.left + c.w * fx, c.body.top + c.h * fy);

/// خط مكسور مفتوح من نقاط.
Path _poly(List<Offset> pts) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final o in pts.skip(1)) {
    p.lineTo(o.dx, o.dy);
  }
  return p;
}

/// نجوم صغيرة تلمع داخل الجسم (ليلي، مجرة...).
void _twinkles(BubbleCtx c, int n, {Color col = Colors.white, double r = .13, int salt = 40, double speed = 2.4}) {
  for (var i = 0; i < n; i++) {
    final tw = bbTw(c.t, speed + rnd(i, salt) * 1.4, i);
    final p = _at(c, .06 + rnd(i, salt + 1) * .88, .12 + rnd(i, salt + 2) * .76);
    if (i.isEven) {
      bbSpark(c.canvas, p, c.u * (r * .4 + r * 1.1 * tw), col.withValues(alpha: .35 + .65 * tw));
    } else {
      c.canvas.drawCircle(p, c.u * (.03 + .05 * tw), bbFill(col.withValues(alpha: .3 + .7 * tw)));
    }
  }
}

/// تاج صغير ذهبي ([w] عرضه، قاعدته على [base]).
void _crown(BubbleCtx c, Offset base, double w, {Color ink = const Color(0xFF4A2A04), List<Color>? gems}) {
  final k = c.canvas;
  final s = w / 1.2;
  Offset o(double x, double y) => Offset(base.dx + x * s, base.dy + y * s);
  final path = Path()
    ..moveTo(o(-.6, 0).dx, o(-.6, 0).dy)
    ..lineTo(o(-.64, -.52).dx, o(-.64, -.52).dy)
    ..lineTo(o(-.3, -.26).dx, o(-.3, -.26).dy)
    ..lineTo(o(0, -.72).dx, o(0, -.72).dy)
    ..lineTo(o(.3, -.26).dx, o(.3, -.26).dy)
    ..lineTo(o(.64, -.52).dx, o(.64, -.52).dy)
    ..lineTo(o(.6, 0).dx, o(.6, 0).dy)
    ..close();
  k.drawPath(path, bbGrad(path.getBounds(), const [Color(0xFFFFF3A8), Color(0xFFFFC52E), Color(0xFFD98A12)]));
  k.drawPath(path, bbLine(c.ow * .9, ink));
  k.drawLine(o(-.58, -.12), o(.58, -.12), bbLine(c.ow * .5, ink.withValues(alpha: .6)));
  final g = gems ?? const [Color(0xFFFF5A6B), Color(0xFF7BE8FF), Color(0xFFFF5A6B)];
  final tips = [o(-.64, -.52), o(0, -.72), o(.64, -.52)];
  for (var i = 0; i < 3; i++) {
    k.drawCircle(tips[i], s * .1, bbFill(g[i]));
    k.drawCircle(tips[i], s * .1, bbLine(c.ow * .5, ink));
  }
  k.drawCircle(o(0, -.3), s * .08, bbFill(g[1]));
}

// ───────────────────────── رق ─────────────────────────

/// لفافة رق قديمة بحوافها الملفوفة (العادية، ثابتة).
class ParchmentArt extends BubbleArtSpec {
  const ParchmentArt();

  @override
  List<Color> get fill => const [Color(0xFFF7E8C2), Color(0xFFEBD3A0), Color(0xFFD9B777)];
  @override
  Color get ink => const Color(0xFF4A2C12);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.1, .14, .1, .06);
  @override
  double get tx => 1.3;
  @override
  bool get animated => false;

  @override
  Path shape(BubbleCtx c) {
    final b = c.body, u = c.u;
    // ورقة بحافة علوية وسفلية مموجة شوي
    final l = b.left + u * .48, r = b.right - u * .48, top = b.top + u * .06, bot = b.bottom - u * .06;
    final p = Path()..moveTo(l, top);
    const n = 6;
    for (var i = 1; i <= n; i++) {
      final x = l + (r - l) * i / n;
      p.quadraticBezierTo(x - (r - l) / n / 2, top + (i.isOdd ? -u * .07 : u * .07), x, top);
    }
    p.lineTo(r, bot);
    for (var i = n - 1; i >= 0; i--) {
      final x = l + (r - l) * i / n;
      p.quadraticBezierTo(x + (r - l) / n / 2, bot + (i.isOdd ? u * .07 : -u * .07), x, bot);
    }
    return p..close();
  }

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    // بقع قديمة
    k.drawOval(Rect.fromCenter(center: _at(c, .3, .62), width: c.w * .4, height: c.h * .85), bbFill(const Color(0x22A8742A)));
    k.drawOval(Rect.fromCenter(center: _at(c, .78, .3), width: c.w * .28, height: c.h * .6), bbFill(const Color(0x1CA8742A)));
    k.drawOval(Rect.fromCenter(center: _at(c, .55, .9), width: c.w * .22, height: c.h * .35), bbFill(const Color(0x18A8742A)));
    // حرق الأطراف
    k.drawPath(body, bbLine(u * .75, const Color(0x44A06A2A)));
    k.drawPath(body, bbLine(u * .3, const Color(0x44946020)));
    // ألياف الورق
    final f = bbLine(c.ow * .3, const Color(0x2E8A5A22));
    k.drawLine(Offset(b.left + u * .9, b.top + c.h * .26), Offset(b.left + u * 1.9, b.top + c.h * .22), f);
    k.drawLine(Offset(b.right - u * 1.7, b.bottom - c.h * .2), Offset(b.right - u * .9, b.bottom - c.h * .25), f);
    // لمعة خفيفة
    k.drawRect(Rect.fromLTRB(b.left, b.top, b.right, b.top + c.h * .3), bbFill(Colors.white.withValues(alpha: .16)));
  }

  @override
  void front(BubbleCtx c, Path body) {
    final b = c.body, u = c.u;
    final rw = u * .66;
    _roll(c, Rect.fromLTRB(b.left, b.top - u * .08, b.left + rw, b.bottom + u * .08), true);
    _roll(c, Rect.fromLTRB(b.right - rw, b.top - u * .08, b.right, b.bottom + u * .08), false);
  }

  /// طرف اللفافة الملفوف (أسطوانة بحلزون فوق).
  void _roll(BubbleCtx c, Rect r, bool left) {
    final k = c.canvas, u = c.u;
    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.width / 2));
    k.drawRRect(
      rr,
      bbGrad(
        r,
        const [Color(0xFFB98F4C), Color(0xFFF4E0AE), Color(0xFFE2C27C), Color(0xFFA67A38)],
        a: Alignment.centerLeft,
        b: Alignment.centerRight,
        stops: const [0, .32, .68, 1],
      ),
    );
    // فتحة اللفة فوق: بيضاوي غامق وفيه حلزون
    final cap = Rect.fromCenter(center: Offset(r.center.dx, r.top + r.width * .3), width: r.width * .82, height: r.width * .52);
    k.drawOval(cap, bbFill(const Color(0xFFC49A56)));
    final sp = bbLine(c.ow * .5, const Color(0xFF6A4318));
    k.drawArc(cap.deflate(r.width * .1), math.pi * .2, math.pi * 1.5, false, sp);
    k.drawArc(cap.deflate(r.width * .22), math.pi * 1.2, math.pi * 1.4, false, sp);
    k.drawOval(cap, bbLine(c.ow * .6, ink));
    // خط الربط على اللفافة
    k.drawLine(Offset(r.left + r.width * .12, r.center.dy + r.height * .12), Offset(r.right - r.width * .12, r.center.dy + r.height * .12), bbLine(c.ow * .4, const Color(0x558A5A22)));
    k.drawRRect(rr, bbLine(c.ow, ink));
    // لمعة على الأسطوانة
    k.drawLine(
      Offset(r.left + r.width * (left ? .3 : .34), r.top + r.width * .7),
      Offset(r.left + r.width * (left ? .3 : .34), r.bottom - u * .25),
      bbLine(u * .07, Colors.white.withValues(alpha: .5)),
    );
  }
}

// ───────────────────────── ذهبي ─────────────────────────

/// ذهب لامع بحافة نجمية مسننة، ولمعة تمر عليه.
class GoldArt extends BubbleArtSpec {
  const GoldArt();

  @override
  List<Color> get fill => const [Color(0xFFFFEE96), Color(0xFFFFCF40), Color(0xFFF0A31C)];
  @override
  Color get ink => const Color(0xFF6A3A05);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.42, .42, .42, .4);
  @override
  double get tx => 1.05;

  @override
  Path shape(BubbleCtx c) =>
      bbSerrated(c.body, math.min(c.h * .4, c.u * 1.1), pitch: c.u * .9, amp: c.u * .3);

  @override
  void inner(BubbleCtx c, Path body) {
    bbGloss(c, alpha: .34);
    c.canvas.drawPath(body, bbLine(c.u * .5, const Color(0x66FFF3B8)));
    // خط ذهبي داخلي
    c.canvas.drawPath(body, bbLine(c.u * .12, const Color(0xBBA8620A)));
    bbShine(c, period: 3.2, active: .55, width: 1.1, alpha: .75);
  }

  @override
  void front(BubbleCtx c, Path body) {
    final b = c.body, u = c.u;
    final pts = [Offset(b.left + u * .05, b.top - u * .02), Offset(b.right - u * .1, b.top + u * .12), Offset(b.right + u * .08, b.bottom - u * .1)];
    for (var i = 0; i < pts.length; i++) {
      final tw = bbTw(c.t, 2.8, i * 2);
      bbSpark(c.canvas, pts[i], u * (.12 + .38 * tw), Colors.white.withValues(alpha: .5 + .5 * tw));
    }
  }
}

// ───────────────────────── فضي ─────────────────────────

/// فضة مصقولة بحواف مشطوفة ومسامير.
class SilverArt extends BubbleArtSpec {
  const SilverArt();

  @override
  List<Color> get fill => const [Color(0xFFFBFCFE), Color(0xFFD5DCE6), Color(0xFFA6B1BF)];
  @override
  Color get ink => const Color(0xFF384250);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.2, .2, .2, .2);
  @override
  double get tx => 1.1;

  @override
  Path shape(BubbleCtx c) => bbChamfer(c.body, math.min(c.h * .34, c.u * .55));

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    // خطوط تنعيم المعدن
    var i = 0;
    for (var y = b.top + u * .16; y < b.bottom; y += u * .2, i++) {
      k.drawLine(Offset(b.left, y), Offset(b.right, y), bbLine(u * .05, i.isEven ? const Color(0x30FFFFFF) : const Color(0x14000000)));
    }
    // الشطف الداخلي: فوق ويسار فاتح، تحت ويمين غامق
    final d = u * .2, cc = math.min(c.h * .34, u * .55) - d * .3;
    final r = b.deflate(d);
    final light = bbLine(u * .09, const Color(0xCCFFFFFF));
    final dark = bbLine(u * .09, const Color(0x55263040));
    k.drawPath(_poly([Offset(r.left, r.bottom - cc), Offset(r.left, r.top + cc), Offset(r.left + cc, r.top), Offset(r.right - cc, r.top)]), light);
    k.drawPath(_poly([Offset(r.right - cc, r.top), Offset(r.right, r.top + cc), Offset(r.right, r.bottom - cc), Offset(r.right - cc, r.bottom), Offset(r.left + cc, r.bottom), Offset(r.left, r.bottom - cc)]), dark);
    bbShine(c, period: 4.6, active: .6, width: 1.7, alpha: .55);
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    final off = math.min(c.h * .34, u * .55) * .55 + u * .12;
    for (final o in [
      Offset(b.left + off, b.top + off),
      Offset(b.right - off, b.top + off),
      Offset(b.left + off, b.bottom - off),
      Offset(b.right - off, b.bottom - off),
    ]) {
      k.drawCircle(o, u * .11, bbFill(const Color(0xFFC9D2DD)));
      k.drawCircle(o, u * .11, bbLine(c.ow * .55, const Color(0xFF384250)));
      k.drawCircle(o.translate(-u * .03, -u * .03), u * .035, bbFill(Colors.white));
    }
    final tw = bbTw(c.t, 2.1, 1);
    bbSpark(k, Offset(b.left + u * .2, b.top + u * .12), u * (.1 + .32 * tw), Colors.white.withValues(alpha: .4 + .6 * tw));
  }
}

// ───────────────────────── صحراوي ─────────────────────────

/// رمل صحراء بكثبان، وعشبة يابسة بالزاوية تتمايل.
class DesertArt extends BubbleArtSpec {
  const DesertArt();

  @override
  List<Color> get fill => const [Color(0xFFF9E3A8), Color(0xFFE7BF72), Color(0xFFD09C4D)];
  @override
  Color get ink => const Color(0xFF6A4420);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.85, .1, .85, .5);

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    bbGloss(c, alpha: .22);
    // كثبان
    for (var l = 0; l < 2; l++) {
      final y0 = b.top + c.h * (.55 + l * .22);
      final p = Path()..moveTo(b.left - 2, y0);
      for (var x = b.left; x <= b.right + u * .4; x += u * .4) {
        p.lineTo(x, y0 + math.sin((x - b.left) / u * (.9 + l * .4) + l * 2.2) * u * .13);
      }
      p
        ..lineTo(b.right + 2, b.bottom + 2)
        ..lineTo(b.left - 2, b.bottom + 2)
        ..close();
      k.drawPath(p, bbFill(Color(l == 0 ? 0x24A8672A : 0x1CA8672A)));
    }
    // حبات رمل تمر
    for (var i = 0; i < 9; i++) {
      final x = b.left + bbFr(c.t * (.05 + rnd(i) * .06) + rnd(i, 1)) * c.w;
      final y = b.top + rnd(i, 2) * c.h + math.sin(c.t * 1.6 + i) * u * .05;
      k.drawCircle(Offset(x, y), u * (.03 + rnd(i, 3) * .035), bbFill(const Color(0xFFFFF4D2).withValues(alpha: .85)));
    }
    k.drawPath(body, bbLine(u * .4, const Color(0x2A8A5A22)));
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    // عشبة يابسة بالزاوية اليسار تحت
    final root = Offset(b.left + u * .4, b.bottom + u * .2);
    const blades = [(-1.25, .8, -.25), (-.95, 1.1, -.18), (-.62, 1.35, -.1), (-.3, 1.2, -.03), (.0, 1.4, .05), (.3, 1.1, .12), (.6, .85, .18), (.9, .55, .22)];
    for (var i = 0; i < blades.length; i++) {
      final (ang, len, bend) = blades[i];
      _blade(c, root, ang + math.sin(c.t * 1.7 + i * .8) * .08, u * len, u * .17, bend, i);
    }
    // حصاة صغيرة جنبها
    k.drawOval(Rect.fromCenter(center: root.translate(u * .95, u * .04), width: u * .34, height: u * .2), bbFill(const Color(0xFFB7894A)));
    k.drawOval(Rect.fromCenter(center: root.translate(u * .95, u * .04), width: u * .34, height: u * .2), bbLine(c.ow * .5, ink));
  }

  void _blade(BubbleCtx c, Offset root, double ang, double len, double bw, double bend, int i) {
    final dir = Offset(math.sin(ang), -math.cos(ang));
    final nrm = Offset(math.cos(ang), math.sin(ang));
    final tip = root + dir * len + nrm * bend * len;
    final ctrl = root + dir * len * .55 + nrm * bend * len * .1;
    final p = Path()
      ..moveTo(root.dx - nrm.dx * bw, root.dy - nrm.dy * bw)
      ..quadraticBezierTo(ctrl.dx - nrm.dx * bw * .4, ctrl.dy - nrm.dy * bw * .4, tip.dx, tip.dy)
      ..quadraticBezierTo(ctrl.dx + nrm.dx * bw * .4, ctrl.dy + nrm.dy * bw * .4, root.dx + nrm.dx * bw, root.dy + nrm.dy * bw)
      ..close();
    c.canvas.drawPath(p, bbGrad(p.getBounds(), i.isEven ? const [Color(0xFFF0DD7A), Color(0xFFC8AE46)] : const [Color(0xFFD9C257), Color(0xFFA68A30)]));
    c.canvas.drawPath(p, bbLine(c.ow * .6, ink));
  }
}

// ───────────────────────── بحري ─────────────────────────

/// ماء متموج بصخور رمادية بالزاوية، وأمواج تتحرك.
class SeaArt extends BubbleArtSpec {
  const SeaArt();

  @override
  List<Color> get fill => const [Color(0xFF86E0F7), Color(0xFF3AAAE0), Color(0xFF1D6BB5)];
  @override
  Color get ink => const Color(0xFF0C3258);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.95, .12, .95, .5);

  @override
  Path shape(BubbleCtx c) => bbWavy(c.body, math.min(c.h * .45, c.u * 1.2), pitch: c.u * 1.4, amp: c.u * .07);

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    bbGloss(c, alpha: .22);
    for (var l = 0; l < 2; l++) {
      final y0 = b.top + c.h * (.34 + l * .26);
      final ph = c.t * (1.5 + l * .6) + l * 2.1;
      final p = Path()..moveTo(b.left - 2, y0);
      final crest = Path()..moveTo(b.left - 2, y0);
      for (var x = b.left; x <= b.right + u * .35; x += u * .3) {
        final y = y0 + math.sin((x - b.left) / u * 1.25 + ph) * u * .12;
        p.lineTo(x, y);
        crest.lineTo(x, y);
      }
      p
        ..lineTo(b.right + 2, b.bottom + 2)
        ..lineTo(b.left - 2, b.bottom + 2)
        ..close();
      k.drawPath(p, bbFill(Colors.white.withValues(alpha: l == 0 ? .2 : .12)));
      k.drawPath(crest, bbLine(u * .09, Colors.white.withValues(alpha: l == 0 ? .8 : .5)));
    }
    // فقاعات هوا تصعد
    final ring = bbLine(u * .05, Colors.white.withValues(alpha: .75));
    for (var i = 0; i < 4; i++) {
      final life = bbFr(c.t * (.22 + rnd(i) * .12) + rnd(i, 1));
      final x = b.left + c.w * (.2 + .6 * rnd(i, 2)) + math.sin(c.t * 1.8 + i) * u * .05;
      k.drawCircle(Offset(x, b.bottom - life * c.h * 1.1), u * (.06 + rnd(i, 3) * .06), ring);
    }
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    // صخرتين رماديتين تحت اليسار
    _rock(c, Offset(b.left + u * .5, b.bottom + u * .02), u * .98, u * .7, 0);
    _rock(c, Offset(b.left + u * 1.3, b.bottom + u * .16), u * .6, u * .42, 1);
    // رذاذ أبيض يقفز على الصخور
    for (var i = 0; i < 3; i++) {
      final life = bbFr(c.t * .7 + i * .33);
      final o = Offset(b.left + u * (.2 + i * .4), b.bottom - u * .2 - math.sin(life * math.pi) * u * .4);
      k.drawCircle(o, u * .05 * (1 - life * .5), bbFill(Colors.white.withValues(alpha: .9 * (1 - life * .6))));
    }
  }

  void _rock(BubbleCtx c, Offset ctr, double w, double h, int i) {
    final k = c.canvas;
    final p = Path()
      ..moveTo(ctr.dx - w * .5, ctr.dy + h * .45)
      ..quadraticBezierTo(ctr.dx - w * .62, ctr.dy - h * .1, ctr.dx - w * .22, ctr.dy - h * .5)
      ..quadraticBezierTo(ctr.dx + w * .05, ctr.dy - h * .62, ctr.dx + w * .36, ctr.dy - h * .28)
      ..quadraticBezierTo(ctr.dx + w * .6, ctr.dy + h * .1, ctr.dx + w * .5, ctr.dy + h * .45)
      ..close();
    k.drawPath(p, bbGrad(p.getBounds(), const [Color(0xFFC6CDD6), Color(0xFF8A94A0), Color(0xFF626C78)]));
    k.drawPath(p, bbLine(c.ow * .8, const Color(0xFF2C3440)));
    k.drawArc(Rect.fromCenter(center: ctr.translate(-w * .12, -h * .12), width: w * .5, height: h * .5), math.pi * 1.05, math.pi * .55, false, bbLine(c.u * .06, Colors.white.withValues(alpha: .75)));
  }
}

// ───────────────────────── ثلجي ─────────────────────────

/// جليد بقمع جليدي يتدلى وندف ثلج تتطاير.
class IceArt extends BubbleArtSpec {
  const IceArt();

  @override
  List<Color> get fill => const [Color(0xFFF1FCFF), Color(0xFFC6ECFC), Color(0xFF93D1F3)];
  @override
  Color get ink => const Color(0xFF28618D);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.65, .3, .65, .7);

  @override
  void back(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    final n = math.max(3, (c.w / (u * .85)).floor());
    for (var i = 0; i < n; i++) {
      final x = b.left + c.w * (i + .5) / n;
      if ((x - c.tailX).abs() < u * .75) continue;
      final len = u * (.5 + .42 * rnd(i, 7));
      final wd = u * (.26 + .07 * rnd(i, 8));
      final top = b.bottom - u * .3;
      final p = Path()
        ..moveTo(x - wd, top)
        ..quadraticBezierTo(x - wd * .5, top + len * .6, x + wd * .1, top + len + u * .25)
        ..quadraticBezierTo(x + wd * .6, top + len * .6, x + wd, top)
        ..close();
      k.drawPath(p, bbGrad(p.getBounds(), const [Color(0xFFF4FDFF), Color(0xFF9ED8F5)]));
      k.drawPath(p, bbLine(c.ow * .8, ink));
      k.drawLine(Offset(x - wd * .3, top + u * .25), Offset(x - wd * .1, top + len * .75), bbLine(u * .05, Colors.white.withValues(alpha: .9)));
    }
  }

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    // غطاء صقيع أبيض فوق
    final cap = Path()..moveTo(b.left - 2, b.top - 2);
    cap.lineTo(b.right + 2, b.top - 2);
    cap.lineTo(b.right + 2, b.top + c.h * .22);
    final n = math.max(4, (c.w / (u * .5)).round());
    for (var i = n; i > 0; i--) {
      final x0 = b.left + c.w * i / n, x1 = b.left + c.w * (i - 1) / n;
      final d = c.h * (.2 + .1 * rnd(i, 4));
      cap.quadraticBezierTo((x0 + x1) / 2, b.top + d + u * .18, x1, b.top + d * .8);
    }
    cap.close();
    k.drawPath(cap, bbFill(Colors.white.withValues(alpha: .8)));
    // شقوق جليد
    final f = bbLine(u * .05, Colors.white.withValues(alpha: .65));
    k.drawPath(_poly([_at(c, .22, .95), _at(c, .3, .62), _at(c, .26, .45)]), f);
    k.drawPath(_poly([_at(c, .78, .98), _at(c, .72, .7), _at(c, .8, .5)]), f);
    bbShine(c, period: 3.6, active: .5, width: 1.0, alpha: .7);
    // ثلج ينزل جوا
    for (var i = 0; i < 6; i++) {
      final y = b.top + bbFr(c.t * (.16 + rnd(i) * .12) + rnd(i, 1)) * (c.h + u * .2);
      final x = b.left + rnd(i, 2) * c.w + math.sin(c.t * 1.2 + i) * u * .08;
      k.drawCircle(Offset(x, y), u * (.04 + rnd(i, 3) * .035), bbFill(Colors.white.withValues(alpha: .95)));
    }
  }

  @override
  void front(BubbleCtx c, Path body) {
    final b = c.body, u = c.u;
    final flakes = [
      (Offset(b.left - u * .15, b.top + u * .15), .34, 0),
      (Offset(b.right + u * .12, b.top + c.h * .3), .28, 1),
      (Offset(b.right - u * .2, b.top - u * .12), .22, 2),
      (Offset(b.left + u * .25, b.bottom - u * .02), .24, 3),
    ];
    for (final (o, s, i) in flakes) {
      _flake(c, o.translate(0, math.sin(c.t * 1.1 + i * 1.4) * u * .07), u * s, c.t * .5 * (i.isEven ? 1 : -1) + i);
    }
    // لمعة على الجليد
    final tw = bbTw(c.t, 2.3, 4);
    bbSpark(c.canvas, Offset(b.left + u * .3, b.top + u * .2), u * (.08 + .28 * tw), Colors.white.withValues(alpha: .5 + .5 * tw));
  }

  void _flake(BubbleCtx c, Offset o, double r, double ang) {
    final k = c.canvas;
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final a = ang + i * math.pi / 3;
      final d = Offset(math.cos(a), math.sin(a));
      final e = o + d * r;
      p
        ..moveTo(o.dx, o.dy)
        ..lineTo(e.dx, e.dy);
      final m = o + d * r * .6;
      final n = Offset(-d.dy, d.dx) * r * .3;
      p
        ..moveTo(m.dx + n.dx, m.dy + n.dy)
        ..lineTo(m.dx + d.dx * r * .2, m.dy + d.dy * r * .2)
        ..lineTo(m.dx - n.dx, m.dy - n.dy);
    }
    k.drawPath(p, bbLine(c.u * .2, ink));
    k.drawPath(p, bbLine(c.u * .09, Colors.white));
  }
}

// ───────────────────────── ناري ─────────────────────────

/// جسم برتقالي مصفر وحوله حلقة ألسنة لهب تتراقص.
class FireArt extends BubbleArtSpec {
  const FireArt();

  @override
  List<Color> get fill => const [Color(0xFFFFE470), Color(0xFFFFA826), Color(0xFFF2621B)];
  @override
  Color get ink => const Color(0xFF7A1F0A);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.75, 1.4, .75, .4);

  @override
  void back(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u, t = c.t;
    final pulse = .5 + .5 * math.sin(t * 5);
    k.drawCircle(b.center, c.w * .6, bbGlow(b.center, c.w * .6, const Color(0xFFFF8A1F).withValues(alpha: .3 + .15 * pulse)));
    // ألسنة اللهب فوق
    final n = math.max(4, (c.w / (u * .9)).round());
    final bw = math.min(u * .52, c.w / n * .78);
    for (var i = 0; i < n; i++) {
      final x = b.left + c.w * (i + .5) / n;
      final lean = (x - b.center.dx) / (c.w / 2); // الألسنة تتفرق للخارج مثل التاج
      final h = u * (1.05 + .6 * rnd(i, 5)) * (1.05 - lean.abs() * .25);
      _flame(c, Offset(x, b.top + u * .45), lean * .38, bw, h, i);
    }
    // ألسنة جنب ومن تحت (مايلة بره) عشان الحلقة تكمل
    _flame(c, Offset(b.left + u * .3, b.top + c.h * .4), -1.25, u * .34, u * 1.0, 20);
    _flame(c, Offset(b.right - u * .3, b.top + c.h * .4), 1.25, u * .34, u * 1.0, 21);
    _flame(c, Offset(b.left + u * .35, b.bottom - u * .35), -2.0, u * .28, u * .75, 22);
    _flame(c, Offset(b.right - u * .35, b.bottom - u * .35), 2.0, u * .28, u * .75, 23);
    _flame(c, Offset(b.left + c.w * .28, b.bottom - u * .3), math.pi, u * .24, u * .55, 24);
    _flame(c, Offset(b.right - c.w * .28, b.bottom - u * .3), math.pi, u * .24, u * .55, 25);
  }

  void _flame(BubbleCtx c, Offset base, double ang, double bw, double hgt, int i) {
    final k = c.canvas, t = c.t;
    final fl = .82 + .22 * math.sin(t * 6.8 + i * 2.1) + .1 * math.sin(t * 11 + i);
    final sway = math.sin(t * 3.4 + i * 1.7) * bw * .55;
    k.save();
    k.translate(base.dx, base.dy);
    k.rotate(ang);
    final outer = bbTongue(Offset.zero, bw, hgt * fl, sway);
    k.drawPath(outer, bbGrad(outer.getBounds(), const [Color(0xFFFF7A1A), Color(0xFFD83A14)]));
    k.drawPath(outer, bbLine(c.ow * .9, const Color(0xFF7A1F0A)));
    final mid = bbTongue(Offset(0, c.ow * .3), bw * .62, hgt * fl * .72, sway * .7);
    k.drawPath(mid, bbFill(const Color(0xFFFFB531)));
    final core = bbTongue(Offset(0, c.ow * .3), bw * .34, hgt * fl * .46, sway * .5);
    k.drawPath(core, bbFill(const Color(0xFFFFF0A0)));
    k.restore();
  }

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas;
    k.drawCircle(c.body.center.translate(0, c.h * .18), c.w * .45, bbGlow(c.body.center.translate(0, c.h * .18), c.w * .5, const Color(0xCCFFF6B0)));
    bbGloss(c, alpha: .26);
    k.drawPath(body, bbLine(c.u * .5, const Color(0x44FF5A14)));
  }

  @override
  void front(BubbleCtx c, Path body) {
    final b = c.body, u = c.u, t = c.t;
    // شرارات تطلع
    for (var i = 0; i < 4; i++) {
      final life = bbFr(t * (.45 + rnd(i) * .3) + rnd(i, 1));
      final x = b.left + c.w * (.12 + .76 * rnd(i, 2)) + math.sin(t * 3 + i) * u * .1;
      final y = b.top - life * u * 1.1;
      c.canvas.drawCircle(Offset(x, y), u * .05 * (1 - life), bbFill(const Color(0xFFFFE680).withValues(alpha: 1 - life)));
    }
  }
}

// ───────────────────────── زمردي ─────────────────────────

/// زمرد مقطوع بوجوه، وبلورات خضراء بالزوايا تلمع.
class EmeraldArt extends BubbleArtSpec {
  const EmeraldArt();

  @override
  List<Color> get fill => const [Color(0xFF74EBB0), Color(0xFF2BBB77), Color(0xFF0F7C4C)];
  @override
  Color get ink => const Color(0xFF0B3A25);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.85, .95, .85, .7);
  @override
  double get tx => 1.15;

  @override
  Path shape(BubbleCtx c) => bbChamfer(c.body, math.min(c.h * .3, c.u * .5));

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    final cc = math.min(c.h * .3, u * .5);
    final i = b.deflate(math.min(c.h * .26, u * .42));
    // وجوه الحجر
    k.drawPath(_poly([Offset(b.left + cc, b.top), Offset(b.right - cc, b.top), i.topRight, i.topLeft])..close(), bbFill(Colors.white.withValues(alpha: .2)));
    k.drawPath(_poly([Offset(b.left, b.top + cc), i.topLeft, i.bottomLeft, Offset(b.left, b.bottom - cc)])..close(), bbFill(Colors.white.withValues(alpha: .08)));
    k.drawPath(_poly([Offset(b.right, b.top + cc), i.topRight, i.bottomRight, Offset(b.right, b.bottom - cc)])..close(), bbFill(Colors.black.withValues(alpha: .1)));
    k.drawPath(_poly([Offset(b.left + cc, b.bottom), Offset(b.right - cc, b.bottom), i.bottomRight, i.bottomLeft])..close(), bbFill(Colors.black.withValues(alpha: .16)));
    final ln = bbLine(u * .06, const Color(0x66E8FFF2));
    k.drawPath(Path()..addRect(i), ln);
    k.drawLine(Offset(b.left + cc, b.top), i.topLeft, ln);
    k.drawLine(Offset(b.right - cc, b.top), i.topRight, ln);
    k.drawLine(Offset(b.left, b.bottom - cc), i.bottomLeft, ln);
    k.drawLine(Offset(b.right, b.bottom - cc), i.bottomRight, ln);
    bbShine(c, period: 3.0, active: .45, width: 1.0, alpha: .55);
  }

  @override
  void front(BubbleCtx c, Path body) {
    final b = c.body, u = c.u;
    // بلورات الزوايا (قاعدة، زاوية الميل، الطول، العرض)
    final cl = [
      (Offset(b.left + u * .2, b.top + u * .2), -.55, u * 1.1, u * .42, 0),
      (Offset(b.left + u * .1, b.top + u * .3), -1.2, u * .78, u * .34, 1),
      (Offset(b.right - u * .2, b.top + u * .2), .55, u * 1.1, u * .42, 2),
      (Offset(b.right - u * .1, b.top + u * .3), 1.2, u * .78, u * .34, 3),
      (Offset(b.left + u * .25, b.bottom - u * .2), math.pi + .55, u * .8, u * .36, 4),
      (Offset(b.right - u * .25, b.bottom - u * .2), math.pi - .55, u * .8, u * .36, 5),
    ];
    for (final (o, ang, len, wd, _) in cl) {
      _prism(c, o, ang, len, wd);
    }
    // لمعات على رؤوس أكبر أربع بلورات
    for (var i = 0; i < 4; i++) {
      final (o, ang, len, _, _) = cl[i];
      final tip = o + Offset(math.sin(ang), -math.cos(ang)) * len;
      final tw = bbTw(c.t, 2.6, i * 2);
      bbSpark(c.canvas, tip, u * (.06 + .3 * tw * tw), Colors.white.withValues(alpha: .4 + .6 * tw));
    }
  }

  void _prism(BubbleCtx c, Offset base, double ang, double len, double wd) {
    final k = c.canvas;
    k.save();
    k.translate(base.dx, base.dy);
    k.rotate(ang);
    final left = Path()
      ..moveTo(-wd / 2, 0)
      ..lineTo(-wd / 2, -len * .72)
      ..lineTo(0, -len)
      ..lineTo(0, 0)
      ..close();
    final right = Path()
      ..moveTo(0, 0)
      ..lineTo(0, -len)
      ..lineTo(wd / 2, -len * .72)
      ..lineTo(wd / 2, 0)
      ..close();
    k.drawPath(left, bbGrad(left.getBounds(), const [Color(0xFFB5FFD8), Color(0xFF48D890)]));
    k.drawPath(right, bbGrad(right.getBounds(), const [Color(0xFF2DBE78), Color(0xFF0F7A48)]));
    k.drawPath(Path.combine(PathOperation.union, left, right), bbLine(c.ow * .85, ink));
    k.drawLine(Offset(0, -len), Offset(0, 0), bbLine(c.ow * .4, ink.withValues(alpha: .5)));
    k.drawLine(Offset(-wd * .28, -len * .55), Offset(-wd * .28, -len * .15), bbLine(c.u * .05, Colors.white.withValues(alpha: .8)));
    k.restore();
  }
}

// ───────────────────────── ليلي ─────────────────────────

/// سما ليل عميقة: هلال متوهج ونجوم ترمش.
class NightArt extends BubbleArtSpec {
  const NightArt();

  @override
  List<Color> get fill => const [Color(0xFF3058B4), Color(0xFF1B3882), Color(0xFF0B1749)];
  @override
  Color get ink => const Color(0xFF050B2C);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.62, .62, .62, .1);

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas;
    bbGloss(c, alpha: .14);
    k.drawPath(body, bbLine(c.u * .45, const Color(0x558FB5FF)));
    _twinkles(c, 9, col: const Color(0xFFFFF6C8), r: .15, salt: 60);
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    // القمر فوق اليمين، وحوله هالة تنبض
    final m = Offset(b.right - u * .35, b.top + u * .02);
    final pulse = .5 + .5 * math.sin(c.t * 2.2);
    k.drawCircle(m, u * 1.5, bbGlow(m, u * 1.5, const Color(0xFFFFE9A0).withValues(alpha: .28 + .22 * pulse)));
    final cr = bbCrescent(m, u * .66, rot: -.5);
    k.drawPath(cr, bbGrad(cr.getBounds(), const [Color(0xFFFFF8CE), Color(0xFFFFD45A)]));
    k.drawPath(cr, bbLine(c.ow * .85, const Color(0xFF5A3A06)));
    // نجوم بره
    final spots = [Offset(b.left + u * .2, b.top - u * .22), Offset(b.right - u * 1.35, b.top - u * .3), Offset(b.left - u * .15, b.bottom - u * .5)];
    for (var i = 0; i < spots.length; i++) {
      final tw = bbTw(c.t, 2.3, i * 3 + 1);
      bbSpark(k, spots[i], u * (.1 + .3 * tw), Color.lerp(const Color(0xFFFFE9A0), Colors.white, tw)!.withValues(alpha: .5 + .5 * tw));
    }
  }
}

// ───────────────────────── قهوة ─────────────────────────

/// قهوة غامقة بكريمة فوق وبخار يتصاعد وحبات بن.
class CoffeeArt extends BubbleArtSpec {
  const CoffeeArt();

  @override
  List<Color> get fill => const [Color(0xFF9A6641), Color(0xFF6C3E27), Color(0xFF3F2214)];
  @override
  Color get ink => const Color(0xFF2A140A);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.5, 1.25, .5, .2);

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    // كريمة (رغوة) فوق بحافة مموجة
    final foam = Path()..moveTo(b.left - 2, b.top - 2);
    foam.lineTo(b.right + 2, b.top - 2);
    foam.lineTo(b.right + 2, b.top + c.h * .3);
    final n = math.max(4, (c.w / (u * .65)).round());
    for (var i = n; i > 0; i--) {
      final x0 = b.left + c.w * i / n, x1 = b.left + c.w * (i - 1) / n;
      foam.arcToPoint(Offset(x1, b.top + c.h * .3), radius: Radius.circular((x0 - x1) * .55), clockwise: true);
    }
    foam.close();
    k.drawPath(foam, bbGrad(Rect.fromLTRB(b.left, b.top, b.right, b.top + c.h * .45), const [Color(0xFFFFF0D4), Color(0xFFE8C896)]));
    k.drawPath(foam, bbLine(c.ow * .5, const Color(0x558A5A32)));
    bbGloss(c, alpha: .12);
    k.drawPath(body, bbLine(u * .4, const Color(0x33D7A86E)));
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u, t = c.t;
    // حبات بن بزاوية يمين تحت
    _bean(c, Offset(b.right - u * .05, b.bottom - u * .02), u * .27, .6);
    _bean(c, Offset(b.right - u * .62, b.bottom + u * .1), u * .2, -.5);
    // بخار يتصاعد
    for (var i = 0; i < 3; i++) {
      final life = bbFr(t * .42 + i * .34);
      final x0 = b.left + c.w * (.3 + .2 * i);
      final base = b.top - u * .02;
      final pts = <Offset>[];
      for (var s = 0; s <= 6; s++) {
        final f = s / 6;
        pts.add(Offset(x0 + math.sin(t * 2.4 + f * 5.2 + i * 1.7) * u * (.1 + .16 * f), base - life * u * .22 - f * u * .9));
      }
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var s = 1; s < pts.length; s++) {
        p.lineTo(pts[s].dx, pts[s].dy);
      }
      final a = (1 - life) * math.min(1.0, life * 5 + .3);
      k.drawPath(p, bbLine(u * .4 * (1 - life * .4), Colors.white.withValues(alpha: .3 * a)));
      k.drawPath(p, bbLine(u * .22 * (1 - life * .4), Colors.white.withValues(alpha: .95 * a)));
    }
  }

  void _bean(BubbleCtx c, Offset o, double r, double ang) {
    final k = c.canvas;
    k.save();
    k.translate(o.dx, o.dy);
    k.rotate(ang);
    final rect = Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 1.4);
    k.drawOval(rect, bbGrad(rect, const [Color(0xFF8A5030), Color(0xFF3E200F)]));
    k.drawOval(rect, bbLine(c.ow * .7, ink));
    k.drawPath(
      Path()
        ..moveTo(-r * .85, 0)
        ..quadraticBezierTo(0, -r * .45, r * .85, 0),
      bbLine(c.ow * .6, const Color(0xFFD7A86E)),
    );
    k.restore();
  }
}

// ───────────────────────── ملكي ─────────────────────────

/// بنفسجي ملكي بحد ذهبي وتاج، ولمعان كثير يتلألأ.
class RoyalArt extends BubbleArtSpec {
  const RoyalArt();

  @override
  List<Color> get fill => const [Color(0xFFAB6FF7), Color(0xFF7634D6), Color(0xFF451A9C)];
  @override
  Color get ink => const Color(0xFF220840);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.4, .85, .4, .3);

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas;
    bbGloss(c, alpha: .3);
    k.drawPath(body, bbLine(c.u * .38, const Color(0xCCFFD866)));
    k.drawPath(body, bbLine(c.u * .12, const Color(0x00000000)));
    // بريق متناثر
    for (var i = 0; i < 14; i++) {
      final tw = bbTw(c.t, 3 + rnd(i, 3) * 3, i);
      final p = _at(c, .05 + rnd(i, 4) * .9, .1 + rnd(i, 5) * .8);
      bbSpark(k, p, c.u * (.05 + .17 * tw), (i % 3 == 0 ? const Color(0xFFFFE27A) : Colors.white).withValues(alpha: .3 + .7 * tw));
    }
    bbShine(c, period: 3.6, active: .5, width: 1.2, alpha: .5);
  }

  @override
  void front(BubbleCtx c, Path body) {
    final b = c.body, u = c.u;
    _crown(c, Offset(b.center.dx, b.top + u * .06), u * 1.25);
    for (final (i, o) in [Offset(b.left + u * .1, b.top - u * .1), Offset(b.right + u * .02, b.bottom - u * .2)].indexed) {
      final tw = bbTw(c.t, 2.9, i * 5);
      bbSpark(c.canvas, o, u * (.1 + .36 * tw), Color.lerp(const Color(0xFFFFE27A), Colors.white, tw)!.withValues(alpha: .5 + .5 * tw));
    }
  }
}

// ───────────────────────── دموي ─────────────────────────

/// أحمر غامق بعروق حمم متوهجة، ودم يقطر.
class BloodArt extends BubbleArtSpec {
  const BloodArt();

  @override
  List<Color> get fill => const [Color(0xFF7A1119), Color(0xFF4A0A12), Color(0xFF230409)];
  @override
  Color get ink => const Color(0xFF0E0102);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.3, .5, .3, .95);

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas;
    final pulse = .5 + .5 * math.sin(c.t * 2.6);
    k.drawRect(
      Rect.fromLTRB(c.body.left, c.body.bottom - c.h * .5, c.body.right, c.body.bottom),
      bbGrad(Rect.fromLTRB(c.body.left, c.body.bottom - c.h * .5, c.body.right, c.body.bottom), [Colors.transparent, const Color(0xFFFF5A1F).withValues(alpha: .22 + .18 * pulse)]),
    );
    // عروق حمم
    final veins = [
      [_at(c, .06, .9), _at(c, .16, .62), _at(c, .12, .34), _at(c, .24, .12)],
      [_at(c, .94, .88), _at(c, .84, .58), _at(c, .9, .32), _at(c, .78, .1)],
      [_at(c, .34, 1.0), _at(c, .4, .78), _at(c, .5, .74)],
      [_at(c, .66, 1.0), _at(c, .6, .8), _at(c, .52, .76)],
      [_at(c, .45, 0), _at(c, .5, .2), _at(c, .42, .3)],
    ];
    for (final v in veins) {
      final p = _poly(v);
      k.drawPath(p, bbLine(c.u * .26, const Color(0xFFFF5A1F).withValues(alpha: .2 + .18 * pulse)));
      k.drawPath(p, bbLine(c.u * .09, Color.lerp(const Color(0xFFFF8A2B), const Color(0xFFFFE27A), pulse)!));
    }
    bbGloss(c, alpha: .1);
    k.drawPath(body, bbLine(c.u * .4, const Color(0x55D41F2A)));
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u, t = c.t;
    // قطرات دم
    final drips = [(.16, 0), (.7, 1), (.9, 2)];
    for (final (fx, i) in drips) {
      final x = b.left + c.w * fx;
      final life = bbFr(t * .3 + i * .31);
      final grow = bbClamp01(life / .7);
      final len = u * (.3 + .6 * grow * grow);
      final top = b.bottom - u * .12;
      final p = Path()
        ..moveTo(x - u * .18, top)
        ..quadraticBezierTo(x - u * .14, top + len, x, top + len + u * .14)
        ..quadraticBezierTo(x + u * .14, top + len, x + u * .18, top)
        ..close();
      k.drawPath(p, bbGrad(p.getBounds(), const [Color(0xFFD42430), Color(0xFF8A0E16)]));
      k.drawPath(p, bbLine(c.ow * .7, ink));
      k.drawCircle(Offset(x - u * .04, top + len * .55), u * .03, bbFill(Colors.white.withValues(alpha: .8)));
      if (life > .7) {
        final f = (life - .7) / .3;
        k.drawCircle(Offset(x, top + len + u * .15 + f * u * .6), u * .09 * (1 - f * .4), bbFill(const Color(0xFFC01E28).withValues(alpha: 1 - f)));
      }
    }
    // جمر يطلع
    for (var i = 0; i < 4; i++) {
      final life = bbFr(t * (.4 + rnd(i) * .3) + rnd(i, 1));
      final o = Offset(b.left + c.w * (.1 + .8 * rnd(i, 2)) + math.sin(t * 2.5 + i) * u * .08, b.top + u * .1 - life * u * .9);
      k.drawCircle(o, u * .045 * (1 - life), bbFill(const Color(0xFFFF8A2B).withValues(alpha: 1 - life)));
    }
  }
}

// ───────────────────────── نيون ─────────────────────────

/// لوحة نيون غامقة بحد سماوي يومض.
class NeonArt extends BubbleArtSpec {
  const NeonArt();

  @override
  List<Color> get fill => const [Color(0xFF18215A), Color(0xFF0C1235), Color(0xFF060A22)];
  @override
  Color get ink => const Color(0xFF02041A);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.3, .3, .3, .3);

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    // شبكة خفيفة وخط مسح يمر
    final g = bbLine(u * .03, const Color(0x1A5CF0FF));
    for (var x = b.left + u * .3; x < b.right; x += u * .6) {
      k.drawLine(Offset(x, b.top), Offset(x, b.bottom), g);
    }
    for (var y = b.top + u * .3; y < b.bottom; y += u * .6) {
      k.drawLine(Offset(b.left, y), Offset(b.right, y), g);
    }
    final sy = b.top + bbFr(c.t * .5) * (c.h + u * .6) - u * .3;
    final band = Rect.fromLTRB(b.left, sy - u * .3, b.right, sy + u * .3);
    k.drawRect(band, bbGrad(band, [Colors.transparent, const Color(0x335CF0FF), Colors.transparent]));
    bbGloss(c, alpha: .08);
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, u = c.u;
    final flick = rnd((c.t / .09).floor(), 3) < .1 ? .3 : 1.0;
    final glowA = (.18 + .1 * math.sin(c.t * 3)) * flick;
    k.drawPath(body, bbLine(u * .5, const Color(0xFF00F0FF).withValues(alpha: glowA)));
    final inner = bbPill(c.body.deflate(u * .2), u, r: math.min(c.h * .46, u * 1.25) - u * .2);
    k.drawPath(inner, bbLine(u * .2, const Color(0xFF00F0FF).withValues(alpha: .3 * flick)));
    k.drawPath(inner, bbLine(u * .07, const Color(0xFFB8FBFF).withValues(alpha: flick)));
    // قوس وردي بالزاوية
    final p = c.body.deflate(u * .38);
    k.drawPath(
      Path()
        ..moveTo(p.left, p.bottom)
        ..lineTo(p.left + u * .5, p.bottom),
      bbLine(u * .07, const Color(0xFFFF4FD8).withValues(alpha: .8 * flick)),
    );
  }
}

// ───────────────────────── مجرة ─────────────────────────

/// مجرة بسدم ملونة تدور، ونجوم، وكوكب بحلقة.
class GalaxyArt extends BubbleArtSpec {
  const GalaxyArt();

  @override
  List<Color> get fill => const [Color(0xFF2B1B73), Color(0xFF46197C), Color(0xFF123A72)];
  @override
  Color get ink => const Color(0xFF0B0624);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.65, .45, .65, .15);

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, t = c.t;
    const cols = [Color(0xFFFF5FD2), Color(0xFF5AC8FF), Color(0xFF9B6BFF)];
    for (var i = 0; i < 3; i++) {
      final o = b.center + Offset(math.cos(t * .5 + i * 2.1) * c.w * .3, math.sin(t * .6 + i * 2.1) * c.h * .22);
      k.drawCircle(o, c.h * 1.0, bbGlow(o, c.h * 1.0, cols[i].withValues(alpha: .4)));
    }
    _twinkles(c, 14, r: .13, salt: 80);
    // نيزك يمر
    final kk = bbFr(t / 5.5);
    if (kk < .12) {
      final p = kk / .12;
      final head = Offset(b.left + c.w * (.95 - p * .75), b.top + c.h * (.05 + p * .6));
      final tail = head + Offset(c.u * 1.0, -c.u * .5);
      k.drawLine(head, tail, Paint()
        ..strokeWidth = c.u * .08
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [Colors.white.withValues(alpha: 1 - p), Colors.white.withValues(alpha: 0)]).createShader(Rect.fromPoints(head, tail)));
    }
    bbGloss(c, alpha: .1);
    k.drawPath(body, bbLine(c.u * .4, const Color(0x44B49CFF)));
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    // كوكب بحلقة فوق اليسار
    final o = Offset(b.left + u * .05, b.top + u * .12);
    final r = u * .4;
    k.save();
    k.translate(o.dx, o.dy);
    k.rotate(-.45);
    final ring = Rect.fromCenter(center: Offset.zero, width: r * 3.1, height: r * 1.0);
    k.drawOval(ring, bbLine(u * .13, const Color(0xFFFFD79A)));
    k.drawOval(ring, bbLine(u * .03, ink));
    final disc = Rect.fromCircle(center: Offset.zero, radius: r);
    k.drawCircle(Offset.zero, r, bbGrad(disc, const [Color(0xFFFFC27A), Color(0xFFD65A9A)], a: Alignment.topLeft, b: Alignment.bottomRight));
    k.drawCircle(Offset.zero, r, bbLine(c.ow * .85, ink));
    k.drawArc(ring, 0, math.pi, false, bbLine(u * .13, const Color(0xFFFFD79A)));
    k.drawArc(ring, 0, math.pi, false, bbLine(u * .03, ink));
    k.restore();
    final spots = [Offset(b.right + u * .15, b.top - u * .05), Offset(b.right - u * .1, b.bottom - u * .05)];
    for (var i = 0; i < spots.length; i++) {
      final tw = bbTw(c.t, 2.5, i * 4);
      bbSpark(k, spots[i], u * (.1 + .3 * tw), Colors.white.withValues(alpha: .5 + .5 * tw));
    }
  }
}

// ───────────────────────── وردي ─────────────────────────

/// وردي حلو بقلوب تنبض وتطير.
class RoseArt extends BubbleArtSpec {
  const RoseArt();

  @override
  List<Color> get fill => const [Color(0xFFFFC6DF), Color(0xFFFF8BBB), Color(0xFFEB4F98)];
  @override
  Color get ink => const Color(0xFF7E1C4D);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.55, .5, .55, .3);

  @override
  void back(BubbleCtx c, Path body) {
    final pulse = .5 + .5 * math.sin(c.t * 3);
    c.canvas.drawCircle(c.body.center, c.w * .62, bbGlow(c.body.center, c.w * .62, const Color(0xFFFF7DB5).withValues(alpha: .25 + .2 * pulse)));
  }

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, u = c.u;
    bbGloss(c, alpha: .4);
    // قلوب باهتة منقوشة
    for (final (fx, fy, s) in [(.24, .66, .16), (.5, .8, .12), (.8, .6, .14)]) {
      k.drawPath(bbHeart(_at(c, fx, fy), u * s), bbFill(Colors.white.withValues(alpha: .2)));
    }
    for (var i = 0; i < 4; i++) {
      final tw = bbTw(c.t, 3, i);
      bbSpark(k, _at(c, .1 + rnd(i, 9) * .8, .15 + rnd(i, 10) * .7), u * (.05 + .1 * tw), Colors.white.withValues(alpha: .4 + .6 * tw));
    }
    k.drawPath(body, bbLine(u * .4, const Color(0x44FFE0EE)));
  }

  @override
  void front(BubbleCtx c, Path body) {
    final b = c.body, u = c.u, t = c.t;
    _heart(c, Offset(b.right - u * .05, b.top + u * .05), u * .42, .22, 1 + .1 * math.sin(t * 3.4));
    _heart(c, Offset(b.left + u * .1, b.bottom - u * .02), u * .3, -.3, 1 + .1 * math.sin(t * 3.4 + 1.5));
    // قلوب صغيرة تطير
    for (var i = 0; i < 3; i++) {
      final life = bbFr(t * .3 + i * .34);
      final o = Offset(b.left + c.w * (.25 + .25 * i) + math.sin(t * 2 + i) * u * .1, b.top + u * .15 - life * u * 1.0);
      final s = u * .12 * (1 - life * .3);
      c.canvas.drawPath(bbHeart(o, s), bbFill(const Color(0xFFFF5C93).withValues(alpha: 1 - life)));
    }
  }

  void _heart(BubbleCtx c, Offset o, double s, double ang, double k) {
    final cv = c.canvas;
    cv.save();
    cv.translate(o.dx, o.dy);
    cv.rotate(ang);
    cv.scale(k);
    final h = bbHeart(Offset.zero, s);
    cv.drawPath(h, bbGrad(h.getBounds(), const [Color(0xFFFF7FA8), Color(0xFFD81F65)]));
    cv.drawPath(h, bbLine(c.ow * .9, const Color(0xFF7E1C4D)));
    cv.drawOval(Rect.fromCenter(center: Offset(-s * .45, -s * .35), width: s * .38, height: s * .26), bbFill(Colors.white.withValues(alpha: .8)));
    cv.restore();
  }
}

// ───────────────────────── برق ─────────────────────────

/// نيلي كهربائي بصواعق صفراء بالجنبين وشرارات على الحواف.
class LightningArt extends BubbleArtSpec {
  const LightningArt();

  @override
  List<Color> get fill => const [Color(0xFF5448D8), Color(0xFF322D96), Color(0xFF1B1762)];
  @override
  Color get ink => const Color(0xFF0C0A3A);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.78, .35, .78, .3);
  @override
  double get tx => 1.05;

  @override
  Path shape(BubbleCtx c) => bbChamfer(c.body, math.min(c.h * .3, c.u * .5));

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas;
    bbGloss(c, alpha: .2);
    k.drawPath(body, bbLine(c.u * .4, const Color(0x558CB8FF)));
    // وميض
    final f = bbFr(c.t / 2.6);
    final flash = f < .1 ? 1 - f / .1 : (f > .16 && f < .22 ? 1 - (f - .16) / .06 : 0.0);
    if (flash > 0) k.drawRect(c.body, bbFill(Colors.white.withValues(alpha: .38 * flash)));
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u, t = c.t;
    final bucket = (t / .11).floor();
    final bright = rnd(bucket, 5) > .2 ? 1.0 : .55;
    _bolt(c, Offset(b.left - u * .2, b.center.dy), c.h * .95, -.12, bright);
    _bolt(c, Offset(b.right + u * .2, b.center.dy), c.h * .95, .12, bright);
    // شرارة تمشي على الحافة
    if (rnd(bucket, 9) > .3) {
      final top = rnd(bucket, 1) < .5;
      final y = top ? b.top : b.bottom;
      final x0 = b.left + rnd(bucket, 2) * c.w * .6 + u * .3;
      final pts = [Offset(x0, y)];
      for (var s = 1; s <= 6; s++) {
        pts.add(Offset(x0 + s * u * .3, y + (rnd(bucket * 7 + s, 4) - .5) * u * .45));
      }
      final p = _poly(pts);
      k.drawPath(p, bbLine(u * .24, const Color(0xFF6FA8FF).withValues(alpha: .5)));
      k.drawPath(p, bbLine(u * .08, Colors.white));
    }
  }

  void _bolt(BubbleCtx c, Offset ctr, double hgt, double ang, double bright) {
    final k = c.canvas;
    k.save();
    k.translate(ctr.dx, ctr.dy);
    k.rotate(ang);
    final s = hgt / 2;
    final p = Path()
      ..moveTo(s * .2, -s)
      ..lineTo(-s * .48, s * .12)
      ..lineTo(-s * .06, s * .12)
      ..lineTo(-s * .26, s)
      ..lineTo(s * .52, -s * .22)
      ..lineTo(s * .08, -s * .22)
      ..lineTo(s * .38, -s)
      ..close();
    k.drawPath(p, bbGrad(p.getBounds(), [Color.lerp(const Color(0xFFFFF8B0), Colors.white, bright - .5)!, const Color(0xFFFFC21F)]));
    k.drawPath(p, bbLine(c.ow * .9, ink));
    k.restore();
  }
}

// ───────────────────────── قوس قزح ─────────────────────────

/// سحابة بيضا بحد قوس قزح يدور، وقوس صغير فوق.
class RainbowArt extends BubbleArtSpec {
  const RainbowArt();

  static const colors = [
    Color(0xFFFF4D5E),
    Color(0xFFFFA63D),
    Color(0xFFFFE04A),
    Color(0xFF4BD26E),
    Color(0xFF3FA9FF),
    Color(0xFFB45CFF),
    Color(0xFFFF4D5E),
  ];

  @override
  List<Color> get fill => const [Color(0xFFFFFFFF), Color(0xFFE5F3FF), Color(0xFFBFDFFA)];
  @override
  Color get ink => const Color(0xFF3A4D84);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.5, .75, .5, .4);
  @override
  double get tx => 1.1;

  @override
  Path shape(BubbleCtx c) {
    final b = c.body.deflate(c.u * .06);
    return bbSerrated(b, math.min(b.height * .45, c.u * 1.2), pitch: c.u * 1.25, amp: c.u * .33, round: true);
  }

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body;
    bbGloss(c, alpha: .45);
    k.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = c.u * .62
        ..shader = SweepGradient(colors: colors, transform: GradientRotation(c.t * 1.1)).createShader(Rect.fromCircle(center: b.center, radius: c.w / 2)),
    );
    k.drawPath(body, bbLine(c.u * .2, Colors.white.withValues(alpha: .35)));
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    // قوس قزح صغير فوق اليمين
    final o = Offset(b.right - u * .75, b.top + u * .12);
    final rr = u * .62;
    final bandW = u * .1;
    k.drawArc(Rect.fromCircle(center: o, radius: rr - bandW * 2), math.pi, math.pi, false, bbLine(bandW * 5 + c.ow * 2, ink));
    for (var i = 0; i < 5; i++) {
      k.drawArc(Rect.fromCircle(center: o, radius: rr - i * bandW), math.pi, math.pi, false, bbLine(bandW * 1.05, colors[i]));
    }
    for (var i = 0; i < 3; i++) {
      final tw = bbTw(c.t, 2.8, i * 3);
      final p = [Offset(b.left + u * .15, b.top - u * .08), Offset(b.right + u * .08, b.bottom - u * .25), Offset(b.left - u * .02, b.bottom - u * .1)][i];
      bbSpark(k, p, u * (.08 + .26 * tw), colors[(i * 2 + 1) % 6].withValues(alpha: .6 + .4 * tw));
    }
  }
}

// ───────────────────────── هلال ─────────────────────────

/// أخضر مزرق ليلي، بهلال ذهبي كبير ونجمة وحد ذهبي.
class CrescentArt extends BubbleArtSpec {
  const CrescentArt();

  @override
  List<Color> get fill => const [Color(0xFF24968F), Color(0xFF106568), Color(0xFF08444F)];
  @override
  Color get ink => const Color(0xFF032630);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.62, .6, .62, .1);
  @override
  double get tx => 1.05;

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, u = c.u;
    bbGloss(c, alpha: .16);
    // نقش نقاط ذهبية باهتة
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 9; x++) {
        final p = _at(c, .08 + x * .105 + (y.isOdd ? .05 : 0), .2 + y * .3);
        k.drawCircle(p, u * .045, bbFill(const Color(0xFFFFD25A).withValues(alpha: .16)));
      }
    }
    k.drawPath(body, bbLine(u * .3, const Color(0xCCFFD25A)));
    k.drawPath(body, bbLine(u * .1, const Color(0x00000000)));
    _twinkles(c, 5, col: const Color(0xFFFFEFA8), r: .14, salt: 100);
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    final m = Offset(b.left + u * .42, b.top + u * .0);
    final pulse = .5 + .5 * math.sin(c.t * 2);
    k.drawCircle(m, u * 1.3, bbGlow(m, u * 1.3, const Color(0xFFFFE08A).withValues(alpha: .22 + .16 * pulse)));
    final cr = bbCrescent(m, u * .72, rot: .5);
    k.drawPath(cr, bbGrad(cr.getBounds(), const [Color(0xFFFFF4B8), Color(0xFFFFC93A), Color(0xFFE29A18)]));
    k.drawPath(cr, bbLine(c.ow * .85, const Color(0xFF5A3A06)));
    final s = Offset(b.left + u * 1.25, b.top - u * .08);
    final tw = bbTw(c.t, 2.2, 1);
    final st = bbStar5(s, u * (.2 + .04 * tw), rot: -math.pi / 2 + .2);
    k.drawPath(st, bbFill(const Color(0xFFFFD84A)));
    k.drawPath(st, bbLine(c.ow * .6, const Color(0xFF5A3A06)));
    bbSpark(k, Offset(b.right - u * .05, b.top - u * .1), u * (.1 + .3 * bbTw(c.t, 2.6, 4)), const Color(0xFFFFEFA8));
  }
}

// ───────────────────────── ليالي المجلس ─────────────────────────

/// نيلي مخضر ليلي، وفانوسين ذهبيين يتأرجحان وتوهجهم يرمش.
class LanternsArt extends BubbleArtSpec {
  const LanternsArt();

  @override
  List<Color> get fill => const [Color(0xFF4947BF), Color(0xFF2F3F9E), Color(0xFF138379)];
  @override
  Color get ink => const Color(0xFF0C1448);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.55, .95, .55, .12);
  @override
  double get tx => 1.25;

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas;
    bbGloss(c, alpha: .16);
    k.drawPath(body, bbLine(c.u * .3, const Color(0xBBFFD25A)));
    k.drawPath(body, bbLine(c.u * .1, const Color(0x00000000)));
    _twinkles(c, 8, col: const Color(0xFFFFF2B0), r: .15, salt: 120);
    bbShine(c, period: 4.2, active: .5, width: 1.2, alpha: .35);
  }

  @override
  void front(BubbleCtx c, Path body) {
    final b = c.body, u = c.u;
    _lantern(c, Offset(b.left + u * .5, b.top - u * .85), 0);
    _lantern(c, Offset(b.right - u * .5, b.top - u * .85), 1);
  }

  void _lantern(BubbleCtx c, Offset pivot, int i) {
    final k = c.canvas, u = c.u;
    final sw = math.sin(c.t * 1.4 + i * 1.8) * .12;
    final flick = .75 + .25 * math.sin(c.t * 7 + i * 2.2) * math.sin(c.t * 3.1 + i);
    final w = u * .7, h = u * .95;
    final top = u * .8; // رأس الفانوس تحت نقطة التعليق
    k.save();
    k.translate(pivot.dx, pivot.dy);
    k.rotate(sw);
    k.drawLine(Offset.zero, Offset(0, top), bbLine(c.ow * 1.3, const Color(0xFF1B1F5E)));
    k.drawLine(Offset.zero, Offset(0, top), bbLine(c.ow * .55, const Color(0xFFFFD25A)));
    // توهج
    final mid = Offset(0, top + h * .5);
    k.drawCircle(mid, u * 1.1, bbGlow(mid, u * 1.1, const Color(0xFFFFB84A).withValues(alpha: .42 * flick)));
    // الغطا
    final cap = Path()
      ..moveTo(-w * .26, top - h * .08)
      ..lineTo(w * .26, top - h * .08)
      ..lineTo(w * .56, top + h * .2)
      ..lineTo(-w * .56, top + h * .2)
      ..close();
    // الجسم
    final bodyR = RRect.fromRectAndRadius(Rect.fromLTRB(-w * .5, top + h * .2, w * .5, top + h * .84), Radius.circular(w * .2));
    k.drawRRect(bodyR, bbGrad(bodyR.outerRect, [Color.lerp(const Color(0xFFFFF4B8), Colors.white, flick - .5)!, const Color(0xFFFF9A2E)]));
    final rib = bbLine(c.ow * .5, const Color(0xFF4A2A04));
    k.drawLine(Offset(-w * .17, top + h * .2), Offset(-w * .17, top + h * .84), rib);
    k.drawLine(Offset(w * .17, top + h * .2), Offset(w * .17, top + h * .84), rib);
    k.drawRRect(bodyR, bbLine(c.ow * .85, const Color(0xFF4A2A04)));
    k.drawPath(cap, bbGrad(cap.getBounds(), const [Color(0xFFFFD25A), Color(0xFFD98A12)]));
    k.drawPath(cap, bbLine(c.ow * .85, const Color(0xFF4A2A04)));
    final tipP = Path()
      ..moveTo(-w * .3, top + h * .84)
      ..lineTo(w * .3, top + h * .84)
      ..lineTo(0, top + h * 1.08)
      ..close();
    k.drawPath(tipP, bbFill(const Color(0xFFE8A526)));
    k.drawPath(tipP, bbLine(c.ow * .75, const Color(0xFF4A2A04)));
    k.restore();
  }
}

// ───────────────────────── عاصفة ─────────────────────────

/// سحابة عاصفة رمادية بزرقة، برق يومض ومطر.
class StormArt extends BubbleArtSpec {
  const StormArt();

  @override
  List<Color> get fill => const [Color(0xFF7690B4), Color(0xFF4A6290), Color(0xFF2B3A62)];
  @override
  Color get ink => const Color(0xFF0F1730);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.55, .45, .55, .95);
  @override
  double get tx => 1.1;

  @override
  Path shape(BubbleCtx c) {
    final b = c.body.deflate(c.u * .06);
    return bbSerrated(b, math.min(b.height * .45, c.u * 1.2), pitch: c.u * 1.3, amp: c.u * .36, round: true);
  }

  double _flash(BubbleCtx c) {
    final f = bbFr(c.t / 3.4);
    return f < .08 ? 1 - f / .08 : (f > .13 && f < .2 ? 1 - (f - .13) / .07 : 0.0);
  }

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas;
    // غيم غامق تحت
    for (final (fx, fy, s) in [(.2, .85, .5), (.52, .95, .6), (.82, .85, .5)]) {
      k.drawOval(Rect.fromCenter(center: _at(c, fx, fy), width: c.w * s, height: c.h * .7), bbFill(Colors.black.withValues(alpha: .14)));
    }
    bbGloss(c, alpha: .14);
    k.drawPath(body, bbLine(c.u * .4, const Color(0x44B8D4FF)));
    final fl = _flash(c);
    if (fl > 0) k.drawPath(body, bbFill(Colors.white.withValues(alpha: .4 * fl)));
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u, t = c.t;
    final fl = _flash(c);
    // صاعقة صغيرة تحت اليمين
    final o = Offset(b.right - u * .6, b.bottom + u * .3);
    final s = u * .72;
    final p = Path()
      ..moveTo(o.dx + s * .2, o.dy - s * .55)
      ..lineTo(o.dx - s * .45, o.dy + s * .22)
      ..lineTo(o.dx - s * .05, o.dy + s * .22)
      ..lineTo(o.dx - s * .3, o.dy + s * .95)
      ..lineTo(o.dx + s * .5, o.dy - s * .05)
      ..lineTo(o.dx + s * .08, o.dy - s * .05)
      ..lineTo(o.dx + s * .38, o.dy - s * .55)
      ..close();
    if (fl > 0) k.drawCircle(o, u * 1.1, bbGlow(o, u * 1.1, const Color(0xFFFFF08A).withValues(alpha: .5 * fl)));
    k.drawPath(p, bbGrad(p.getBounds(), const [Color(0xFFFFF59A), Color(0xFFFFC21F)]));
    k.drawPath(p, bbLine(c.ow * .85, ink));
    // مطر
    final rain = bbLine(u * .06, const Color(0xFFA9D6FF).withValues(alpha: .9));
    for (var i = 0; i < 7; i++) {
      final x = b.left + c.w * (i + .5) / 7 + rnd(i, 2) * u * .2;
      if ((x - c.tailX).abs() < u * .55) continue;
      final life = bbFr(t * 1.3 + rnd(i, 3));
      final y = b.bottom - u * .05 + life * u * .7;
      k.drawLine(Offset(x, y), Offset(x - u * .06, y + u * .2), rain);
    }
  }
}

// ───────────────────────── نجمة المبتدئ ─────────────────────────

/// أصفر مشمس بنجمة كبيرة بالزاوية ولمعات.
class StarterArt extends BubbleArtSpec {
  const StarterArt();

  @override
  List<Color> get fill => const [Color(0xFFFFF2A6), Color(0xFFFFD34C), Color(0xFFF5A720)];
  @override
  Color get ink => const Color(0xFF7C4306);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.68, .55, .68, .2);
  @override
  double get tx => 1.15;

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, u = c.u;
    bbGloss(c, alpha: .4);
    for (final (fx, fy, s) in [(.3, .7, .14), (.56, .3, .1), (.82, .72, .13)]) {
      k.drawPath(bbStar5(_at(c, fx, fy), u * s), bbFill(Colors.white.withValues(alpha: .22)));
    }
    k.drawPath(body, bbLine(u * .4, const Color(0x55FFFBE0)));
    bbShine(c, period: 3.0, active: .5, width: 1.0, alpha: .55);
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u, t = c.t;
    final o = Offset(b.left + u * .1, b.top + u * .08);
    final sc = 1 + .08 * math.sin(t * 2.8);
    final st = bbStar5(o, u * .62 * sc, rot: -math.pi / 2 + math.sin(t * 1.3) * .14);
    k.drawPath(st, bbGrad(st.getBounds(), const [Color(0xFFFFF7B8), Color(0xFFFFC21F), Color(0xFFE88A0E)]));
    k.drawPath(st, bbLine(c.ow * 1.0, ink));
    k.drawCircle(o.translate(-u * .12, -u * .14), u * .06, bbFill(Colors.white.withValues(alpha: .85)));
    final spots = [Offset(b.right + u * .02, b.top - u * .08), Offset(b.right + u * .12, b.bottom - u * .45), Offset(b.left + u * .9, b.top - u * .22)];
    for (var i = 0; i < spots.length; i++) {
      final tw = bbTw(t, 2.7, i * 3);
      bbSpark(k, spots[i], u * (.1 + .3 * tw), Colors.white.withValues(alpha: .6 + .4 * tw));
    }
  }
}

// ───────────────────────── الألماس ─────────────────────────

/// ماسة زرقا مقطوعة بوجوه لامعة وبريق.
class DiamondArt extends BubbleArtSpec {
  const DiamondArt();

  @override
  List<Color> get fill => const [Color(0xFFE9FAFF), Color(0xFF9CDBFF), Color(0xFF4A97F4)];
  @override
  Color get ink => const Color(0xFF123E7C);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.5, .4, .5, .35);
  @override
  double get tx => 1.35;

  double _cut(BubbleCtx c) => math.min(c.h * .55, c.u * .9);

  @override
  Path shape(BubbleCtx c) {
    final b = c.body, cut = _cut(c), cy = b.center.dy;
    return Path()
      ..moveTo(b.left + cut, b.top)
      ..lineTo(b.right - cut, b.top)
      ..lineTo(b.right, cy)
      ..lineTo(b.right - cut, b.bottom)
      ..lineTo(b.left + cut, b.bottom)
      ..lineTo(b.left, cy)
      ..close();
  }

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    final cut = _cut(c), cy = b.center.dy;
    final yt = b.top + c.h * .3;
    final xl = b.left + cut * .55, xr = b.right - cut * .55;
    k.drawPath(_poly([Offset(b.left + cut, b.top), Offset(xl, yt), Offset(b.left, cy)])..close(), bbFill(Colors.white.withValues(alpha: .3)));
    k.drawPath(_poly([Offset(b.left + cut, b.top), Offset(b.right - cut, b.top), Offset(xr, yt), Offset(xl, yt)])..close(), bbFill(Colors.white.withValues(alpha: .2)));
    k.drawPath(_poly([Offset(b.right - cut, b.top), Offset(xr, yt), Offset(b.right, cy)])..close(), bbFill(Colors.black.withValues(alpha: .06)));
    k.drawPath(_poly([Offset(b.left, cy), Offset(xl, yt), Offset(xl, b.bottom - c.h * .25)])..close(), bbFill(Colors.white.withValues(alpha: .1)));
    k.drawPath(_poly([Offset(b.left + cut, b.bottom), Offset(b.right - cut, b.bottom), Offset(b.right - cut * .3, b.bottom - c.h * .3), Offset(b.left + cut * .3, b.bottom - c.h * .3)])..close(), bbFill(Colors.black.withValues(alpha: .1)));
    final ln = bbLine(u * .06, const Color(0x99FFFFFF));
    k.drawLine(Offset(xl, yt), Offset(xr, yt), ln);
    k.drawLine(Offset(b.left + cut, b.top), Offset(xl, yt), ln);
    k.drawLine(Offset(b.right - cut, b.top), Offset(xr, yt), ln);
    k.drawLine(Offset(b.left, cy), Offset(xl, yt), ln);
    k.drawLine(Offset(b.right, cy), Offset(xr, yt), ln);
    bbShine(c, period: 3.0, active: .5, width: 1.1, alpha: .7);
  }

  @override
  void front(BubbleCtx c, Path body) {
    final b = c.body, u = c.u;
    final spots = [Offset(b.left + u * .5, b.top - u * .02), Offset(b.right - u * .35, b.top + u * .12), Offset(b.right + u * .12, b.bottom - u * .35), Offset(b.left + u * .1, b.bottom - u * .2)];
    for (var i = 0; i < spots.length; i++) {
      final tw = bbTw(c.t, 2.6, i * 2 + 1);
      bbSpark(c.canvas, spots[i], u * (.08 + .34 * tw * tw), Colors.white.withValues(alpha: .5 + .5 * tw));
    }
  }
}

// ───────────────────────── صفوة المجلس ─────────────────────────

/// أسود فخم بحد ذهبي يلمع، وتاج.
class EliteArt extends BubbleArtSpec {
  const EliteArt();

  @override
  List<Color> get fill => const [Color(0xFF4B515F), Color(0xFF2A2F3A), Color(0xFF10131A)];
  @override
  Color get ink => const Color(0xFF040506);
  @override
  EdgeInsets get pad => const EdgeInsets.fromLTRB(.42, .85, .42, .25);

  @override
  void back(BubbleCtx c, Path body) {
    final pulse = .5 + .5 * math.sin(c.t * 2.4);
    c.canvas.drawCircle(c.body.center, c.w * .62, bbGlow(c.body.center, c.w * .62, const Color(0xFFFFD54F).withValues(alpha: .16 + .14 * pulse)));
  }

  @override
  void inner(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    bbGloss(c, alpha: .12);
    // حد ذهبي مزدوج
    k.drawPath(body, bbLine(u * .4, const Color(0xFFE8B83C)));
    k.drawPath(body, bbLine(u * .24, const Color(0xFF1B1E26)));
    k.drawPath(body, bbLine(u * .1, const Color(0xBBFFD66B)));
    // لمعة ذهبية تدور على الحد
    k.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * .4
        ..shader = SweepGradient(
          colors: const [Color(0x00FFF2B0), Color(0xFFFFF6C8), Color(0x00FFF2B0), Color(0x00FFF2B0)],
          stops: const [0, .08, .2, 1],
          transform: GradientRotation(c.t * 1.3),
        ).createShader(Rect.fromCircle(center: b.center, radius: c.w / 2)),
    );
  }

  @override
  void front(BubbleCtx c, Path body) {
    final k = c.canvas, b = c.body, u = c.u;
    _crown(c, Offset(b.center.dx, b.top + u * .08), u * 1.3, gems: const [Color(0xFF7BE8FF), Color(0xFFFF5A6B), Color(0xFF7BE8FF)]);
    // معينات ذهبية على الجنبين
    for (final x in [b.left + u * .02, b.right - u * .02]) {
      final d = Path()
        ..moveTo(x, b.center.dy - u * .26)
        ..lineTo(x + u * .18, b.center.dy)
        ..lineTo(x, b.center.dy + u * .26)
        ..lineTo(x - u * .18, b.center.dy)
        ..close();
      k.drawPath(d, bbGrad(d.getBounds(), const [Color(0xFFFFF0A0), Color(0xFFE0A020)]));
      k.drawPath(d, bbLine(c.ow * .7, ink));
    }
    final tw = bbTw(c.t, 2.4, 1);
    bbSpark(k, Offset(b.right - u * .4, b.top + u * .12), u * (.1 + .3 * tw), Colors.white.withValues(alpha: .5 + .5 * tw));
  }
}
