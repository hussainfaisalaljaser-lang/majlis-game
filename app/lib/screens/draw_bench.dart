import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/perf.dart';
import '../services/preload.dart';
import '../widgets/draw_flags.dart';
import '../widgets/page_transition.dart';
import 'shop_screen.dart';

/// «قياس الرسم والتنقل» (أدوات المطور): يقيس على جوال اللاعب نفسه وين يروح وقت الرسم.
/// يرجع للرئيسية، ويستنى التجهيز ورا الرئيسية يخلص، وبعدين:
/// ١) يفتح المتجر ويرجع ٣ مرات بكل حركة (الجديدة بالصور، والأصلية).
/// ٢) يقيس رسم المتجر كامل، وبدون كل نوع رسم بالدور (ظل النصوص، تدرج العناوين، رسومات الأغراض).
/// يرجع سطور النتيجة (تطلع بنافذة يصورها اللاعب).
abstract final class DrawBench {
  static bool running = false;

  static Future<List<String>> run(NavigatorState nav) async {
    running = true;
    final wasOn = Perf.enabled.value;
    Perf.enabled.value = true; // قياس التنقل يحتاجه (بدون ما نحفظه)
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

      // ١) التنقل بين الرئيسية والمتجر بالحركتين
      for (final snap in [true, false]) {
        SmoothPageTransitionsBuilder.snapshots = snap;
        final go = <_Nav>[], back = <_Nav>[];
        for (var i = 0; i < 3; i++) {
          go.add(await _nav(() => nav.push(MaterialPageRoute<void>(builder: (_) => const ShopScreen()))));
          await _wait(800);
          back.add(await _nav(nav.pop));
          await _wait(800);
        }
        out.add('${snap ? 'الحركة الجديدة (صور)' : 'الحركة الأصلية'} (ms):\n  فتح المتجر: ${_navText(go)}\n  الرجوع: ${_navText(back)}');
      }
      SmoothPageTransitionsBuilder.snapshots = true;

      // ٢) رسم المتجر بكل حالة (بدون حركة تنقل)
      final variant = ValueNotifier(0);
      unawaited(
        nav.push(
          PageRouteBuilder<void>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, _, _) => ValueListenableBuilder(
              valueListenable: variant,
              builder: (_, v, _) => Stack(
                children: [
                  KeyedSubtree(key: ValueKey(v), child: const ShopScreen()),
                  const _KeepDrawing(),
                ],
              ),
            ),
          ),
        ),
      );
      final cases = <(String, void Function())>[
        ('المتجر كامل', () {}),
        ('بدون ظل النصوص', () => DrawFlags.textShadows = false),
        ('بدون تدرج العناوين', () => DrawFlags.titleGradients = false),
        ('بدون رسومات الأغراض', () => DrawFlags.itemArt = false),
        (
          'بدون الثلاثة',
          () {
            DrawFlags.textShadows = false;
            DrawFlags.titleGradients = false;
            DrawFlags.itemArt = false;
          },
        ),
      ];
      out.add('رسم المتجر بكل فريم (ms):');
      for (final (i, (name, apply)) in cases.indexed) {
        DrawFlags.reset();
        apply();
        variant.value = i + 1;
        await _wait(1000);
        out.add('  $name: ${await _sample(const Duration(seconds: 2))}');
      }
      DrawFlags.reset();
      nav.pop();
    } finally {
      DrawFlags.reset();
      SmoothPageTransitionsBuilder.snapshots = true;
      Perf.enabled.value = wasOn;
      running = false;
    }
    return out;
  }

  static Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  /// يسوي التنقل وينتظر قياسه من Perf (أول فريم وأبطأ فريم وكم تأخر).
  static Future<_Nav> _nav(void Function() action) async {
    final done = Completer<void>();
    void listener() {
      if (!done.isCompleted) done.complete();
    }

    Perf.nav.addListener(listener);
    action();
    await done.future.timeout(const Duration(milliseconds: 2500), onTimeout: () {});
    Perf.nav.removeListener(listener);
    return Perf.nav.value;
  }

  static String _navText(List<_Nav> list) {
    final got = list.nonNulls.toList();
    if (got.isEmpty) return 'ما انقاس';
    String ms(double v) => '${v.round()}';
    final worst = [for (final n in got) n.worst];
    final first = [for (final n in got) n.raster];
    return 'أبطأ ${worst.map(ms).join('، ')} · أول فريم ${first.map(ms).join('، ')} · '
        'متأخر ${got.fold(0, (a, n) => a + n.late)} من ${got.fold(0, (a, n) => a + n.count)}';
  }

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

typedef _Nav = ({String page, double build, double raster, double worst, int late, int count})?;

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
