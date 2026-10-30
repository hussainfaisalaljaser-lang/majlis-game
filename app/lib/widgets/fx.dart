import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shop.dart';

/// اللمعة الخفيفة للأغراض النادرة: تمر كل [glintEvery] ثانية وتطول [glintFor]، وبينها الرسمة ثابتة.
const glintEvery = 5.0;
const glintFor = 1.1;

/// تقدم اللمعة (٠–١) لو هي ماشية الحين، وإلا null.
double? glintAt(double t) {
  final into = t % glintEvery;
  return into < glintFor ? into / glintFor : null;
}

/// ساعة الحركات: تعيد الرسم كل فريم بدون ما تبني الواجهة من جديد (الرسامين يسمعون [time] مباشرة).
/// [glint]: تمشي بس وقت اللمعة (الأغراض النادرة)، وبين اللمعات واقفة فما تكلف شي.
class FxClock extends StatefulWidget {
  const FxClock({super.key, required this.builder, this.glint = false});

  final Widget Function(BuildContext context, ValueListenable<double> time) builder;
  final bool glint;

  /// للتصوير (services/capture.dart): وقت ثابت تتحكم فيه الصفحة بدال الساعة.
  static final manual = ValueNotifier<double?>(null);

  /// حركات خفيفة (من الإعدادات، للجوالات الضعيفة): كل الحركات توقف وتبقى الرسمات ثابتة.
  static final lite = ValueNotifier<bool>(false);
  static const _liteKey = 'fx_lite';

  static Future<void> init() async {
    try {
      lite.value = (await SharedPreferences.getInstance()).getBool(_liteKey) ?? false;
    } catch (_) {}
  }

  static Future<void> setLite(bool on) async {
    lite.value = on;
    try {
      (await SharedPreferences.getInstance()).setBool(_liteKey, on);
    } catch (_) {}
  }

  @override
  State<FxClock> createState() => _FxClockState();
}

/// نبضة الحركات: كل ساعات الحركة تتحدث مع بعض في نفس الفريم.
/// الجوال يرسم الشاشة كلها من جديد بكل فريم. لو الفريم خفيف تتحدث كل فريم (مثل قبل)، ولو الجوال تعبان
/// (الفريم ياخذ أكثر من ١٢ms) تتحدث ٣٠ مرة بالثانية: الزينة (نجوم، لمعات، فوانيس، إطارات) تبان نفسها،
/// والرسم ينقص للنص بدل ما يتقطع. الحركات الثانية (المشاهد، اللمس، السحب) تبقى كل فريم.
abstract final class _Pulse {
  static final _clocks = <_FxClockState>{};
  static bool _waiting = false;
  static bool _watching = false;

  /// متوسط وقت الفريم (الأطول من البناء والرسم) بالملي ثانية، وهل الجوال تعبان.
  static double _load = 0;
  static bool _slow = false;

  static void add(_FxClockState clock) {
    if (!_watching) {
      _watching = true;
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
    }
    if (_clocks.add(clock)) _arm();
  }

  static void remove(_FxClockState clock) => _clocks.remove(clock);

  static void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final us = math.max(t.buildDuration.inMicroseconds, t.rasterDuration.inMicroseconds);
      _load = _load * .9 + us / 1000 * .1;
    }
    // فرق بين الحدين عشان ما يتنقل كل شوي.
    if (!_slow && _load > 12) {
      _slow = true;
    } else if (_slow && _load < 8) {
      _slow = false;
    }
  }

  static void _arm() {
    if (_waiting || _clocks.isEmpty) return;
    _waiting = true;
    void next() => SchedulerBinding.instance.scheduleFrameCallback((_) {
      _waiting = false;
      for (final clock in _clocks.toList()) {
        clock._tick();
      }
      _arm();
    });
    // التعبان: ننتظر أقل من ٣٣ms بشوي ثم نطلب فريم، فيجي مع تحديث الشاشة اللي بعده (منتظم).
    // والتطبيق بالخلفية ما يرسم.
    if (_slow) {
      Timer(const Duration(milliseconds: 24), next);
    } else {
      next();
    }
  }
}

class _FxClockState extends State<FxClock> with SingleTickerProviderStateMixin {
  // كل حركة تبدأ من نقطة مختلفة عشان الإطارات المتشابهة ما تتحرك سوا.
  late final double _offset = math.Random().nextDouble() * 100;
  final _watch = Stopwatch()..start();
  late final ValueNotifier<double> _time = ValueNotifier(_now);

  /// للتصوير بس (services/capture.dart): كل فريم بالضبط. غيره على النبضة ([_Pulse]).
  late final Ticker _ticker = createTicker((_) => _tick());
  Timer? _wake;

  /// الصفحة مخفية (تحت صفحة ثانية): ما نحرّك.
  ValueListenable<TickerModeData>? _mode;

  double get _now => FxClock.manual.value ?? _offset + _watch.elapsedMicroseconds / 1e6;

  void _tick() => _time.value = _now;

  @override
  void initState() {
    super.initState();
    FxClock.manual.addListener(_schedule);
    FxClock.lite.addListener(_schedule);
    _schedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _watchMode();
  }

  @override
  void activate() {
    super.activate();
    _watchMode();
  }

  void _watchMode() {
    final mode = TickerMode.getValuesNotifier(context);
    if (mode == _mode) return;
    _mode?.removeListener(_schedule);
    _mode = mode..addListener(_schedule);
    _schedule();
  }

  /// تشغّل الساعة أو توقفها حسب الوضع: التصوير كل فريم، والخفيف واقف، والنادر وقت اللمعة بس.
  void _schedule() {
    _wake?.cancel();
    final t = _now;
    if (FxClock.manual.value != null || !FxClock.lite.value && !widget.glint) return _run();
    final into = t % glintEvery;
    if (FxClock.lite.value || into >= glintFor) return _rest(t, into);
    _run();
    _wake = Timer(Duration(microseconds: ((glintFor - into) * 1e6).ceil() + 20000), _schedule);
  }

  void _run() {
    if (FxClock.manual.value != null) {
      _Pulse.remove(this);
      if (!_ticker.isActive) _ticker.start();
      return;
    }
    if (_ticker.isActive) _ticker.stop();
    (_mode?.value.enabled ?? true) ? _Pulse.add(this) : _Pulse.remove(this);
  }

  /// توقف على لحظة ما فيها لمعة، وتصحى للمعة الجاية (لو مو خفيف).
  void _rest(double t, double into) {
    if (_ticker.isActive) _ticker.stop();
    _Pulse.remove(this);
    _time.value = into >= glintFor ? t : t - into + glintFor + .01;
    if (!FxClock.lite.value) {
      _wake = Timer(Duration(microseconds: ((glintEvery - _time.value % glintEvery) * 1e6).ceil()), _schedule);
    }
  }

  @override
  void dispose() {
    _wake?.cancel();
    _Pulse.remove(this);
    _mode?.removeListener(_schedule);
    FxClock.manual.removeListener(_schedule);
    FxClock.lite.removeListener(_schedule);
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _time);
}

/// رقم شبه عشوائي ثابت (نفس المدخل = نفس الرقم) بين ٠ و١.
double rnd(int i, [int salt = 0]) {
  var x = (i * 374761393 + salt * 668265263 + 1013904223) & 0x7fffffff;
  x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff;
  x = x ^ (x >> 16);
  return (x & 0xffff) / 0xffff;
}

double _frac(double x) => x - x.floorToDouble();

/// نجمة بأربع رؤوس (لمعة).
Path star4(Offset c, double r) {
  final s = r * .28;
  return Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + s * .35, c.dy - s * .35, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + s * .35, c.dy + s * .35, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - s * .35, c.dy + s * .35, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - s * .35, c.dy - s * .35, c.dx, c.dy - r)
    ..close();
}

Color _hueShift(Color c, double deg) {
  final hsv = HSVColor.fromColor(c);
  return hsv.withHue((hsv.hue + deg) % 360).toColor();
}

/// ورقة شجر.
Path _leaf(Offset c, double len, double angle) {
  final dx = math.cos(angle), dy = math.sin(angle);
  final nx = -dy, ny = dx;
  final tip = c + Offset(dx, dy) * len / 2, tail = c - Offset(dx, dy) * len / 2;
  return Path()
    ..moveTo(tail.dx, tail.dy)
    ..quadraticBezierTo(c.dx + nx * len * .35, c.dy + ny * len * .35, tip.dx, tip.dy)
    ..quadraticBezierTo(c.dx - nx * len * .35, c.dy - ny * len * .35, tail.dx, tail.dy)
    ..close();
}

/// لهب صغير يطلع باتجاه [angle].
Path _flame(Offset base, double size, double angle) {
  final dx = math.cos(angle), dy = math.sin(angle);
  final nx = -dy, ny = dx;
  final tip = base + Offset(dx, dy) * size * 1.6;
  return Path()
    ..moveTo(base.dx + nx * size * .45, base.dy + ny * size * .45)
    ..quadraticBezierTo(
      base.dx + dx * size * .9 + nx * size * .5,
      base.dy + dy * size * .9 + ny * size * .5,
      tip.dx,
      tip.dy,
    )
    ..quadraticBezierTo(
      base.dx + dx * size * .9 - nx * size * .5,
      base.dy + dy * size * .9 - ny * size * .5,
      base.dx - nx * size * .45,
      base.dy - ny * size * .45,
    )
    ..arcToPoint(Offset(base.dx + nx * size * .45, base.dy + ny * size * .45), radius: Radius.circular(size * .45))
    ..close();
}

/// خلفية الشخصيات المميزة: ألوان تضوي وتتحرك ورا الشخصية.
class AvatarBgPainter extends CustomPainter {
  AvatarBgPainter(this.art, this.time) : super(repaint: time);

  final AvatarArt art;
  final ValueListenable<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final rect = Offset.zero & size;
    final a = art.colors.first, b = art.colors.last;
    final light = Color.lerp(a, Colors.white, .45)!;
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawRect(
      rect,
      Paint()..shader = RadialGradient(center: const Alignment(0, -.25), radius: .9, colors: [a, b]).createShader(rect),
    );
    switch (art.fx) {
      case AvatarFx.aurora:
        for (var i = 0; i < 3; i++) {
          final ang = t * (.5 + i * .2) + i * 2.1;
          canvas.drawCircle(
            c + Offset(math.cos(ang), math.sin(ang)) * r * .45,
            r * .55,
            Paint()
              ..color = _hueShift(light, i * 50.0).withValues(alpha: .55)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .35),
          );
        }
      case AvatarFx.rays:
        final p = Paint()..color = Colors.white.withValues(alpha: .13);
        const n = 12;
        for (var i = 0; i < n; i++) {
          final ang = t * .4 + i * math.pi * 2 / n;
          final p1 = c + Offset(math.cos(ang - .12), math.sin(ang - .12)) * r * 1.5;
          final p2 = c + Offset(math.cos(ang + .12), math.sin(ang + .12)) * r * 1.5;
          canvas.drawPath(
            Path()
              ..moveTo(c.dx, c.dy)
              ..lineTo(p1.dx, p1.dy)
              ..lineTo(p2.dx, p2.dy)
              ..close(),
            p,
          );
        }
        canvas.drawCircle(
          c,
          r * .5,
          Paint()
            ..color = light.withValues(alpha: .35)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .3),
        );
      case AvatarFx.sparkle:
        for (var i = 0; i < 8; i++) {
          final tw = (math.sin(t * 2.5 + i * 1.9) + 1) / 2;
          final pos = Offset(rnd(i, 11) * size.width, rnd(i, 12) * size.height * .8);
          canvas.drawPath(
            star4(pos, r * (.04 + tw * .07)),
            Paint()..color = Colors.white.withValues(alpha: .2 + tw * .8),
          );
        }
      case AvatarFx.embers:
        for (var i = 0; i < 14; i++) {
          final life = _frac(t * (.25 + rnd(i) * .2) + rnd(i, 1));
          final pos = Offset(rnd(i, 2) * size.width + math.sin(t * 2 + i) * r * .05, size.height * (1.05 - life * 1.1));
          canvas.drawCircle(
            pos,
            r * (.025 + rnd(i, 3) * .03),
            Paint()..color = light.withValues(alpha: (1 - life) * .95),
          );
        }
      case AvatarFx.pulse:
        final beat = (math.sin(t * math.pi * 2 / 1.8) + 1) / 2;
        canvas.drawCircle(
          c,
          r * (.45 + beat * .25),
          Paint()
            ..color = light.withValues(alpha: .25 + beat * .35)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .35),
        );
      case AvatarFx.smoke:
        for (var i = 0; i < 5; i++) {
          final ang = t * (.2 + rnd(i) * .2) + i * 1.3;
          canvas.drawCircle(
            c + Offset(math.cos(ang) * r * .6, math.sin(ang * 1.3) * r * .5),
            r * (.35 + rnd(i, 4) * .2),
            Paint()
              ..color = light.withValues(alpha: .28)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .25),
          );
        }
      case AvatarFx.stars:
        for (var i = 0; i < 22; i++) {
          final tw = (math.sin(t * 1.8 + i * 2.3) + 1) / 2;
          canvas.drawCircle(
            Offset(rnd(i, 21) * size.width, rnd(i, 22) * size.height * .85),
            r * (.012 + rnd(i, 23) * .02),
            Paint()..color = Colors.white.withValues(alpha: .2 + tw * .8),
          );
        }
        final tw = (math.sin(t * 1.3) + 1) / 2;
        canvas.drawPath(
          star4(Offset(size.width * .2, size.height * .22), r * (.06 + tw * .04)),
          Paint()..color = Colors.white,
        );
      case AvatarFx.bubbles:
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, r * .02)
          ..color = Colors.white.withValues(alpha: .6);
        for (var i = 0; i < 9; i++) {
          final life = _frac(t * (.18 + rnd(i) * .15) + rnd(i, 1));
          final pos = Offset(rnd(i, 2) * size.width + math.sin(t * 2 + i) * r * .06, size.height * (1.1 - life * 1.2));
          canvas.drawCircle(pos, r * (.04 + rnd(i, 3) * .06), ring);
        }
    }
    // ظل خفيف تحت عشان الشخصية تبان
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .6, size.width, size.height * .4),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: .25)],
        ).createShader(Rect.fromLTWH(0, size.height * .6, size.width, size.height * .4)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(AvatarBgPainter old) => old.art != art;
}

/// شكل فقاعة الكلام: مستطيل مدوّر وتحته ذيل صغير.
Path bubblePath(Size size, {double tail = 7}) {
  final body = Rect.fromLTWH(0, 0, size.width, size.height - tail);
  final r = math.min(body.height / 2, 16.0);
  final cx = size.width / 2;
  return Path()
    ..addRRect(RRect.fromRectAndRadius(body, Radius.circular(r)))
    ..moveTo(cx - tail, body.bottom - 1)
    ..lineTo(cx, size.height)
    ..lineTo(cx + tail, body.bottom - 1)
    ..close();
}

/// رسام فقاعة الكلام القديم بالألوان والحركات (لمعة، نار، ثلج، نيون…): احتياط لأي فقاعة بدون رسمة مصورة،
/// والفقاعات اللي بالمتجر ترسمها widgets/design_bubbles.dart.
class BubblePainter extends CustomPainter {
  BubblePainter(this.style, this.time, {this.tail = 7}) : super(repaint: time);

  final BubbleStyle style;
  final ValueListenable<double> time;
  final double tail;

  bool has(BubbleFx f) => style.fx.contains(f);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final path = bubblePath(size, tail: tail);
    final body = Rect.fromLTWH(0, 0, size.width, size.height - tail);
    final h = body.height;
    final accent = style.border;

    // توهج حول الفقاعة
    if (has(BubbleFx.glow) || has(BubbleFx.neon)) {
      final beat = has(BubbleFx.neon)
          ? (rnd((t / .09).floor(), 3) < .12 ? .2 : 1.0)
          : (math.sin(t * math.pi * 2 / 1.6) + 1) / 2;
      canvas.drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: .25 + beat * .45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 + beat * 6),
      );
    } else {
      canvas.drawPath(
        path.shift(const Offset(0, 3)),
        Paint()
          ..color = Colors.black.withValues(alpha: .4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // بخار فوق (القهوة)
    if (has(BubbleFx.steam)) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .55);
      for (var i = 0; i < 3; i++) {
        final life = _frac(t * .6 + i / 3);
        final x = size.width * (.3 + i * .2);
        final y0 = -life * h * .9;
        final s = Path()..moveTo(x, y0 + 2);
        for (var k = 1; k <= 4; k++) {
          s.lineTo(x + math.sin(t * 3 + k + i) * 3, y0 - k * 3.2);
        }
        canvas.drawPath(s, p..color = Colors.white.withValues(alpha: (1 - life) * .6));
      }
    }

    // نار فوق الفقاعة
    if (has(BubbleFx.flame)) {
      final n = (size.width / 11).floor().clamp(4, 14);
      for (var i = 0; i < n; i++) {
        final life = _frac(t * 1.2 + rnd(i));
        final x = 6 + (size.width - 12) * (i + .5) / n;
        final col = Color.lerp(const Color(0xFFFFF59D), const Color(0xFFFF6D00), life)!;
        canvas.drawPath(
          _flame(Offset(x, 3 - life * 4), 5.5 * (1.2 - life * .8), -math.pi / 2),
          Paint()..color = col.withValues(alpha: (1 - life)),
        );
      }
    }

    // الخلفية
    final bg = style.bg;
    final Shader shader = has(BubbleFx.spin)
        ? SweepGradient(
            colors: [...bg, bg.first],
            transform: GradientRotation(t * .9),
          ).createShader(Rect.fromCircle(center: body.center, radius: body.width))
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bg.length > 1 ? bg : [bg.first, bg.first],
          ).createShader(body);
    canvas.drawPath(path, Paint()..shader = shader);

    canvas.save();
    canvas.clipPath(path);
    // لمعة خفيفة فوق
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h * .45), Paint()..color = Colors.white.withValues(alpha: .12));
    if (has(BubbleFx.shimmer)) {
      // شريط ضو مايل يمر على الفقاعة كل شوي.
      final x = _frac(t / 2.2) * (size.width + 90) - 45;
      final band = Rect.fromLTWH(x - 22, -4, 44, h + 8);
      canvas.save();
      canvas.translate(band.center.dx, band.center.dy);
      canvas.transform(Matrix4.skewX(-.35).storage);
      canvas.translate(-band.center.dx, -band.center.dy);
      canvas.drawRect(
        band,
        Paint()
          ..shader = const LinearGradient(colors: [Color(0x00FFFFFF), Color(0x99FFFFFF), Color(0x00FFFFFF)])
              .createShader(band),
      );
      canvas.restore();
    }
    if (has(BubbleFx.stars) || has(BubbleFx.sparkle)) {
      final n = has(BubbleFx.stars) ? 10 : 4;
      for (var i = 0; i < n; i++) {
        final tw = (math.sin(t * 2.4 + i * 1.7) + 1) / 2;
        final pos = Offset(rnd(i, 31) * size.width, rnd(i, 32) * h);
        if (has(BubbleFx.sparkle)) {
          canvas.drawPath(star4(pos, 2 + tw * 3), Paint()..color = Colors.white.withValues(alpha: .3 + tw * .7));
        } else {
          canvas.drawCircle(pos, .8 + tw * .9, Paint()..color = Colors.white.withValues(alpha: .25 + tw * .75));
        }
      }
    }
    if (has(BubbleFx.snow)) {
      for (var i = 0; i < 9; i++) {
        final y = _frac(t * (.25 + rnd(i) * .2) + rnd(i, 1)) * (h + 6) - 3;
        final x = rnd(i, 2) * size.width + math.sin(t * 1.5 + i) * 4;
        canvas.drawCircle(Offset(x, y), 1.2 + rnd(i, 3) * 1.2, Paint()..color = Colors.white.withValues(alpha: .9));
      }
    }
    if (has(BubbleFx.bubbles)) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .7);
      for (var i = 0; i < 7; i++) {
        final y = h + 4 - _frac(t * (.3 + rnd(i) * .3) + rnd(i, 1)) * (h + 8);
        final x = rnd(i, 2) * size.width + math.sin(t * 2 + i) * 3;
        canvas.drawCircle(Offset(x, y), 1.5 + rnd(i, 3) * 2, ring);
      }
    }
    if (has(BubbleFx.sand)) {
      for (var i = 0; i < 14; i++) {
        final x = _frac(t * (.12 + rnd(i) * .1) + rnd(i, 1)) * (size.width + 10) - 5;
        final y = rnd(i, 2) * h + math.sin(t * 2 + i) * 2;
        canvas.drawCircle(Offset(x, y), .8 + rnd(i, 3), Paint()..color = const Color(0xFFFFF3D6).withValues(alpha: .8));
      }
    }
    if (has(BubbleFx.leaves)) {
      for (var i = 0; i < 4; i++) {
        final x = _frac(t * (.1 + rnd(i) * .08) + rnd(i, 1)) * (size.width + 16) - 8;
        final y = h * (.2 + rnd(i, 2) * .6) + math.sin(t * 1.6 + i) * 3;
        canvas.drawPath(
          _leaf(Offset(x, y), 7, t * 2 + i),
          Paint()..color = const Color(0xFFA7F3D0).withValues(alpha: .75),
        );
      }
    }
    if (has(BubbleFx.smoke)) {
      for (var i = 0; i < 4; i++) {
        final x = _frac(t * .08 + rnd(i)) * (size.width + 30) - 15;
        canvas.drawCircle(
          Offset(x, h * (.3 + rnd(i, 2) * .5)),
          h * .45,
          Paint()
            ..color = Colors.black.withValues(alpha: .25)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .3),
        );
      }
    }
    canvas.restore();

    // الحافة
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = has(BubbleFx.rainbow) ? 2.6 : 1.6;
    if (has(BubbleFx.rainbow)) {
      border.shader = SweepGradient(
        colors: const [
          Color(0xFFFF1744),
          Color(0xFFFFEA00),
          Color(0xFF00E676),
          Color(0xFF00B0FF),
          Color(0xFFD500F9),
          Color(0xFFFF1744),
        ],
        transform: GradientRotation(t * 1.6),
      ).createShader(Rect.fromCircle(center: body.center, radius: body.width / 2));
    } else if (has(BubbleFx.neon)) {
      final flick = rnd((t / .09).floor(), 3) < .12 ? .25 : 1.0;
      border
        ..color = accent.withValues(alpha: flick)
        ..strokeWidth = 2;
    } else {
      border.color = accent;
    }
    canvas.drawPath(path, border);

    // برق على الحواف
    if (has(BubbleFx.electric)) {
      final bucket = (t / .12).floor();
      if (rnd(bucket, 9) > .25) {
        final edge = rnd(bucket, 1) < .5 ? 0.0 : h;
        final x0 = rnd(bucket, 2) * size.width * .7;
        final bolt = Path()..moveTo(x0, edge);
        for (var k = 1; k <= 6; k++) {
          bolt.lineTo(x0 + k * 6.0, edge + (rnd(bucket * 7 + k, 4) - .5) * 8);
        }
        canvas.drawPath(
          bolt,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = accent.withValues(alpha: .6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        canvas.drawPath(
          bolt,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BubblePainter old) => old.style != style;
}
