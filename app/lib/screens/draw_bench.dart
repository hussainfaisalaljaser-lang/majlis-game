import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../services/preload.dart';
import '../widgets/common.dart';
import '../widgets/design_shop.dart';
import '../widgets/draw_flags.dart';
import '../widgets/ui.dart';
import 'shop_screen.dart';

/// «قياس الرسم والتنقل» (أدوات المطور): يقيس على جوال اللاعب نفسه وين يروح وقت الرسم.
/// يرجع للرئيسية، ويستنى التجهيز ورا الرئيسية يخلص، وبعدين:
/// يقيس رسم الرئيسية بالفريمات، وبعدين يرسم كل جزء كصورة بدقة الشاشة ويحسب وقته الحقيقي: الرئيسية،
/// وخلفية الليل، والشريط الجانبي (بالتغميق الجديد والقديم)، والشريط العلوي، والمتجر بتبويب العروض والشخصيات
/// كامل وبدون الخلفية أو الكروت أو رسومات الأغراض.
/// يرجع سطور النتيجة (تطلع بنافذة يصورها اللاعب).
abstract final class DrawBench {
  static bool running = false;

  static Future<List<String>> run(NavigatorState nav) async {
    running = true;
    final out = <String>[];
    try {
      ModalRoute<dynamic>? first;
      nav.popUntil((r) {
        if (r.isFirst && r is ModalRoute) first = r;
        return r.isFirst;
      });
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

      // الرئيسية نفسها: كم ياخذ رسمها كل فريم (من الشاشة)
      final keep = OverlayEntry(builder: (_) => const _KeepDrawing());
      nav.overlay!.insert(keep);
      await _wait(800);
      out.add('رسم الرئيسية بكل فريم: ${await _sample(const Duration(seconds: 2))}');
      keep.remove();
      await _wait(300);

      // كل جزء يترسم كصورة بدقة الشاشة ونحسب الوقت كامل (ما يتأثر بموعد الشاشة مثل قياس الفريمات).
      // «فاضي» = وقت قراءة الصورة نفسه، ينطرح من الباقي.
      final home = first?.subtreeContext?.findRenderObject();
      if (home is RenderRepaintBoundary) out.add('  الرئيسية: ${await _shots(home)}');
      final scene = ValueNotifier<(int, Widget)>((0, const SizedBox.expand()));
      final shot = GlobalKey();
      unawaited(
        nav.push(
          PageRouteBuilder<void>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, _, _) => ValueListenableBuilder(
              valueListenable: scene,
              builder: (_, v, _) => RepaintBoundary(
                key: shot,
                child: ColoredBox(
                  color: const Color(0xFF0D1030),
                  child: KeyedSubtree(key: ValueKey(v.$1), child: v.$2),
                ),
              ),
            ),
          ),
        ),
      );
      Widget rail() => Align(
        alignment: AlignmentDirectional.centerStart,
        child: ShopRail(
          items: const [
            ShopCategory('offers', 'العروض'),
            ShopCategory('avatar', 'الشخصيات'),
            ShopCategory('frame', 'الإطارات'),
            ShopCategory('death', 'الطرد'),
            ShopCategory('cards', 'الأوراق'),
            ShopCategory('table', 'الطاولات'),
            ShopCategory('bubble', 'الفقاعات'),
          ],
          selected: 1,
          onSelect: (_) {},
        ),
      );
      final cases = <(String, Widget, void Function())>[
        ('فاضي', const SizedBox.expand(), () {}),
        ('خلفية الليل', const NightBackground(child: SizedBox.expand()), () {}),
        ('الشريط الجانبي', rail(), () {}),
        ('الشريط الجانبي بالتغميق القديم', rail(), () => DrawFlags.oldDarken = true),
        (
          'الشريط العلوي',
          Align(
            alignment: Alignment.topCenter,
            child: ShopTopBar(
              title: 'المتجر',
              icon: const Gfx('shop', size: 34),
              trailing: [
                ShopTitleChip(label: 'غرفة التبديل', onTap: () {}),
                const ShopCurrency(icon: 'coin', amount: 20000),
                const ShopCurrency(icon: 'gem', amount: 0),
              ],
            ),
          ),
          () {},
        ),
        ('المتجر: العروض', const ShopScreen(), () {}),
        ('العروض بدون الخلفية', const ShopScreen(), () => DrawFlags.nightSky = 2),
        ('المتجر بدون الكروت', const ShopScreen(), () => DrawFlags.shopContent = false),
        ('المتجر: الشخصيات', const ShopScreen(initialTab: ShopScreen.avatarsTab), () {}),
        (
          'الشخصيات بدون رسوماتها',
          const ShopScreen(initialTab: ShopScreen.avatarsTab),
          () => DrawFlags.itemArt = false,
        ),
      ];
      for (final (i, (name, widget, apply)) in cases.indexed) {
        DrawFlags.reset();
        apply();
        scene.value = (i + 1, widget);
        await _wait(1200);
        final box = shot.currentContext?.findRenderObject();
        if (box is RenderRepaintBoundary) out.add('  $name: ${await _shots(box)}');
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

  /// يرسم [box] كصورة بدقة الشاشة ٦ مرات ويقرا بكسلاتها (لين يخلص كرت الشاشة فعلاً): الأقل والمتوسط.
  static Future<String> _shots(RenderRepaintBoundary box) async {
    final ratio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final times = <double>[];
    for (var i = 0; i < 7; i++) {
      await SchedulerBinding.instance.endOfFrame;
      if (box.debugNeedsPaint || !box.attached) continue;
      final sw = Stopwatch()..start();
      final image = await box.toImage(pixelRatio: ratio);
      await image.toByteData();
      image.dispose();
      if (i > 0) times.add(sw.elapsedMicroseconds / 1000);
    }
    if (times.isEmpty) return '…';
    times.sort();
    final avg = times.reduce((a, b) => a + b) / times.length;
    return '${times.first.round()}ms (متوسط ${avg.round()})';
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
