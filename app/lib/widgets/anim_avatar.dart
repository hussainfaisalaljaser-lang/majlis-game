import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'anim_rigs.dart';
import 'fx.dart';

/// الشخصيات اللي تتحرك (الملحمية والأسطورية): طبقات من نفس الرسمة في `assets/avatars/anim/<id>/`
/// (tools/art/anim_avatars.py). اللوحة أكبر من الصورة بـ ٢٠٪، و٢٠٠ وحدة في الرسمة = قطر الصورة.
/// [pop] الطبقة اللي فوق الإطار (جناح يطلع برا الدائرة مثلاً)، والثانية داخل الدائرة.
/// الصقّار هنا، والباقين في anim_rigs.dart.
class AnimAvatar extends StatelessWidget {
  const AnimAvatar({super.key, required this.id, required this.size, required this.time, this.pop = false});

  final String id;
  final double size;
  final ValueListenable<double> time;
  final bool pop;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: time,
    builder: (context, _) => switch (id) {
      'falconer' => _falconer(time.value),
      // الباقين ما لهم شي يطلع برا الدائرة
      _ when pop || !AvatarRig.ids.contains(id) => const SizedBox.shrink(),
      _ => AvatarRig(id, size, time.value).build(),
    },
  );

  // ───────────── الصقّار ─────────────

  /// يرمش ويتنفس. صقره يطالع حوله ويرمش، وكل كم ثانية يفرد جناحه ويرفرف ويطيح منه ريشتين.
  Widget _falconer(double t) {
    final breath = math.sin(t * math.pi * 2 / 3.8);
    final body = Offset(0, breath * .7);
    // الرفرفة: كل ٧ ثواني تقريباً، تطول ثانية وشوي
    final f = _frac(t / 7.1);
    final flapping = f < .16;
    final env = flapping ? math.sin(f / .16 * math.pi) : 0.0;
    final lift = Offset(0, -3.2 * env) + body;
    if (pop) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          if (flapping)
            _layer(
              'falconer',
              'pop_wing',
              rot: -.35 * env + .42 * math.sin(f / .16 * math.pi * 6) * env - .1,
              pivot: const Offset(168.6, 96),
              shift: lift,
              scale: .82 + .18 * env,
            ),
          // ريشتين يطيحن بعد الرفرفة
          if (f >= .16 && f < .46) Positioned.fill(child: CustomPaint(painter: _Feathers((f - .16) / .3, size))),
        ],
      );
    }
    // الراس يطالع حوله: يلف بسرعة ويثبت، كل ١٫٧ ثانية لزاوية جديدة
    final step = (t / 1.7).floor();
    final into = Curves.easeOutBack.transform((_frac(t / 1.7) * 5).clamp(0.0, 1.0));
    double look(int k) => flapping ? -.05 : (rnd(k, 5) - .62) * .42;
    final head = look(step - 1) + (look(step) - look(step - 1)) * into;
    final manBlink = _blink(t, 4.3, .0) || _blink(t, 11.3, .52);
    final birdBlink = _blink(t + .7, 3.2, .0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _layer('falconer', 'man', shift: body, scale: 1 + breath * .004, pivot: const Offset(100, 200)),
        if (manBlink)
          _layer('falconer', 'man_blink', shift: body, scale: 1 + breath * .004, pivot: const Offset(100, 200)),
        _layer('falconer', 'tail', shift: lift),
        _layer('falconer', 'glove', shift: body),
        _layer('falconer', 'bird', shift: lift),
        if (!flapping) _layer('falconer', 'wing', shift: lift),
        _layer('falconer', 'head', rot: head, pivot: const Offset(156.6, 94), shift: lift),
        if (birdBlink) _layer('falconer', 'head_blink', rot: head, pivot: const Offset(156.6, 94), shift: lift),
      ],
    );
  }

  /// رمشة تطول ١٥٠ ملي ثانية كل [period] ثانية.
  static bool _blink(double t, double period, double at) {
    final p = _frac(t / period) - at;
    return p >= 0 && p < .15 / period;
  }

  static double _frac(double x) => x - x.floorToDouble();

  /// طبقة بنفس لوحة الرسم، ومعها دوران حول [pivot] وإزاحة [shift] (بوحدات الرسمة).
  Widget _layer(
    String id,
    String name, {
    double rot = 0,
    Offset pivot = const Offset(100, 100),
    Offset shift = Offset.zero,
    double scale = 1,
  }) {
    final k = size / 200;
    final px = (pivot.dx + 20) * k, py = (pivot.dy + 20) * k;
    final m = Matrix4.identity()
      ..translateByDouble(shift.dx * k + px, shift.dy * k + py, 0, 1)
      ..rotateZ(rot)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-px, -py, 0, 1);
    return Positioned(
      left: -size * .1,
      top: -size * .1,
      width: size * 1.2,
      height: size * 1.2,
      child: Transform(
        transform: m,
        child: Image.asset(
          'assets/avatars/anim/$id/$name.webp',
          width: size * 1.2,
          height: size * 1.2,
          cacheWidth: animLayerCacheWidth(size * 1.2),
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// ريشتين يطيحن ويتمايلن بعد ما يرفرف الصقر.
class _Feathers extends CustomPainter {
  _Feathers(this.p, this.avatar);

  final double p;
  final double avatar;

  @override
  void paint(Canvas canvas, Size size) {
    final k = avatar / 200;
    for (var i = 0; i < 2; i++) {
      final x = (190 + i * 12 + math.sin(p * 9 + i * 2) * 7) * k;
      final y = (84 + i * 6 + p * (52 + i * 10)) * k;
      final a = math.sin(p * 8 + i * 1.7) * .7 + .4;
      final fade = (1 - p).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(a);
      final len = 9 * k, w = 2.6 * k;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: w * 2, height: len * 2),
        Paint()..color = const Color(0xFF8E6A47).withValues(alpha: .95 * fade),
      );
      canvas.drawLine(
        Offset(0, -len),
        Offset(0, len * 1.25),
        Paint()
          ..color = const Color(0xFF3B2716).withValues(alpha: .8 * fade)
          ..strokeWidth = math.max(.6, .7 * k),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Feathers old) => old.p != p || old.avatar != avatar;
}
