import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/preload.dart';
import '../widgets/draw_flags.dart';
import 'shop_screen.dart';

/// «قياس الرسم والتنقل» (أدوات المطور): يقيس على جوال اللاعب نفسه وين يروح وقت الرسم.
/// يرجع للرئيسية، ويستنى التجهيز ورا الرئيسية يخلص، وبعدين:
/// يقيس رسم الرئيسية، ورسم المتجر كامل وبدون كل جزء بالدور (خلفية الليل، الكروت، الحركة، ظل النصوص،
/// رسومات الأغراض) بتبويب العروض والشخصيات.
/// يرجع سطور النتيجة (تطلع بنافذة يصورها اللاعب).
abstract final class DrawBench {
  static bool running = false;

  static Future<List<String>> run(NavigatorState nav) async {
    running = true;
    final out = <String>[];
    try {
      nav.popUntil((r) => r.isFirst);
      await _wait(1000);
      final started = DateTime.now();
      while (Preload.background.value.doneMs == null && DateTime.now().difference(started).inSeconds < 90) {
        await _wait(500);
      }
      final bg = Preload.background.value;
      out.add(
        bg.doneMs == null
            ? 'التجهيز ورا الرئيسية: ما خلص (${bg.done} من ${bg.total})'
            : 'التجهيز ورا الرئيسية: خلص بعد ${(bg.doneMs! / 1000).toStringAsFixed(1)}ث من التشغيل (${bg.total} صورة)',
      );

      // الرئيسية نفسها: كم ياخذ رسمها كل فريم
      final keep = OverlayEntry(builder: (_) => const _KeepDrawing());
      nav.overlay!.insert(keep);
      await _wait(800);
      out.add('رسم الرئيسية بكل فريم (ms): ${await _sample(const Duration(seconds: 2))}');
      keep.remove();
      await _wait(500);

      // رسم المتجر بكل حالة (بدون حركة تنقل): كل حالة تشيل جزء، عشان نعرف وين يروح الوقت.
      final variant = ValueNotifier((key: 0, tab: ShopScreen.offersTab, still: false));
      unawaited(
        nav.push(
          PageRouteBuilder<void>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, _, _) => ValueListenableBuilder(
              valueListenable: variant,
              builder: (_, v, _) => Stack(
                children: [
                  TickerMode(
                    enabled: !v.still,
                    child: KeyedSubtree(
                      key: ValueKey(v.key),
                      child: ShopScreen(initialTab: v.tab),
                    ),
                  ),
                  const _KeepDrawing(),
                ],
              ),
            ),
          ),
        ),
      );
      const offers = ShopScreen.offersTab, avatars = ShopScreen.avatarsTab;
      final cases = <(String, int, bool, void Function())>[
        ('العروض كامل', offers, false, () {}),
        ('العروض والخلفية واقفة', offers, false, () => DrawFlags.nightSky = 1),
        ('العروض بدون الخلفية', offers, false, () => DrawFlags.nightSky = 2),
        ('العروض وكل شي واقف', offers, true, () {}),
        ('بدون الكروت (إطار الصفحة بس)', offers, false, () => DrawFlags.shopContent = false),
        (
          'بدون الكروت وبدون الخلفية',
          offers,
          false,
          () {
            DrawFlags.shopContent = false;
            DrawFlags.nightSky = 2;
          },
        ),
        ('الشخصيات كامل', avatars, false, () {}),
        ('الشخصيات وكل شي واقف', avatars, true, () {}),
        ('الشخصيات بدون ظل النصوص', avatars, false, () => DrawFlags.textShadows = false),
        ('الشخصيات بدون رسومات الأغراض', avatars, false, () => DrawFlags.itemArt = false),
      ];
      out.add('رسم المتجر بكل فريم (ms):');
      for (final (i, (name, tab, still, apply)) in cases.indexed) {
        DrawFlags.reset();
        apply();
        variant.value = (key: i + 1, tab: tab, still: still);
        await _wait(1200);
        out.add('  $name: ${await _sample(const Duration(seconds: 2))}');
      }
      DrawFlags.reset();
      nav.pop();
    } finally {
      DrawFlags.reset();
      running = false;
    }
    return out;
  }

  static Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  /// متوسط الرسم والبناء لكل فريم خلال [d]، و٩٠٪ من الفريمات تحت كم.
  static Future<String> _sample(Duration d) async {
    final raster = <double>[], build = <double>[];
    void onTimings(List<FrameTiming> ts) {
      for (final t in ts) {
        raster.add(t.rasterDuration.inMicroseconds / 1000);
        build.add(t.buildDuration.inMicroseconds / 1000);
      }
    }

    SchedulerBinding.instance.addTimingsCallback(onTimings);
    await Future<void>.delayed(d);
    SchedulerBinding.instance.removeTimingsCallback(onTimings);
    String stat(List<double> xs) {
      if (xs.isEmpty) return '…';
      xs.sort();
      final avg = xs.reduce((a, b) => a + b) / xs.length;
      return '${avg.toStringAsFixed(1)} (٩٠٪ تحت ${xs[(xs.length * .9).floor().clamp(0, xs.length - 1)].toStringAsFixed(1)})';
    }

    return 'رسم ${stat(raster)} · بناء ${stat(build)}';
  }
}

/// نقطة شبه مخفية تتغير كل فريم: الشاشة ترسم كل فريم حتى لو المتجر واقف، عشان نقيس رسمه كامل.
class _KeepDrawing extends StatefulWidget {
  const _KeepDrawing();

  @override
  State<_KeepDrawing> createState() => _KeepDrawingState();
}

class _KeepDrawingState extends State<_KeepDrawing> with SingleTickerProviderStateMixin {
  final _tick = ValueNotifier(0);
  late final _ticker = createTicker((_) => _tick.value++)..start();

  @override
  void initState() {
    super.initState();
    _ticker; // يبدأ على طول
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    top: 0,
    width: 2,
    height: 2,
    child: IgnorePointer(child: CustomPaint(painter: _Dot(_tick))),
  );
}

class _Dot extends CustomPainter {
  _Dot(this.tick) : super(repaint: tick);

  final ValueNotifier<int> tick;

  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(0, 0, 0, tick.value.isEven ? .01 : .02));

  @override
  bool shouldRepaint(_Dot old) => false;
}
