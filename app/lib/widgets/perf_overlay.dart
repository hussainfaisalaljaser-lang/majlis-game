import 'package:flutter/material.dart';

import '../services/backend.dart';
import '../services/perf.dart';
import '../services/preload.dart';

/// القياس فوق اللعبة (من أدوات المطور): السيرفر والرسم والتشغيل. ما يتأثر باللمس.
class PerfOverlay extends StatelessWidget {
  const PerfOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Perf.enabled,
    builder: (context, on, _) => !on
        ? child
        : Stack(
            textDirection: TextDirection.rtl,
            children: [
              child,
              const Positioned(top: 2, left: 0, right: 0, child: IgnorePointer(child: Center(child: _Readout()))),
            ],
          ),
  );
}

class _Readout extends StatelessWidget {
  const _Readout();

  static const _style = TextStyle(fontSize: 10.5, height: 1.3, color: Colors.white, fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([Perf.last, Perf.frames, Perf.turns, Perf.nav, Preload.background]),
    builder: (context, _) {
      final last = Perf.last.value;
      final f = Perf.frames.value;
      final ac = Perf.appCheck;
      final cert = ac == null
          ? (storeBuild ? '…' : 'مطفية في نسخ التجربة')
          : '${ac.ms}ms ${ac.ok ? 'نجحت' : 'فشلت'}';
      final parts = last?.parts == null ? '' : ': ${last!.parts}';
      final split = last?.server == null ? '' : ' (الطريق ${last!.ms - last.server!} + شغل السيرفر ${last.server}$parts)';
      final server = last == null
          ? 'السيرفر: لسا ما فيه طلب'
          : 'السيرفر: ${last.fn} ${last.ms}ms$split${last.ok ? '' : ' (فشل)'}';
      final draw = f == null
          ? 'الرسم: …'
          : 'الرسم: ${f.fps.round()} فريم/ث · متأخر ${(f.jank * 100).round()}% · بناء ${f.build.toStringAsFixed(1)}ms · رسم ${f.raster.toStringAsFixed(1)}ms';
      String secs(int? ms) => ms == null ? '…' : '${(ms / 1000).toStringAsFixed(1)}ث';
      final bg = Preload.background.value;
      final ready = bg.total == 0
          ? ''
          : bg.doneMs == null
          ? ' · التجهيز ${bg.done} من ${bg.total}'
          : ' · التجهيز خلص ${secs(bg.doneMs)}';
      final boot =
          'التشغيل: ${secs(Perf.startupMs)} · أول بيانات ${secs(Perf.firstDataMs)}$ready · شهادة قوقل $cert';
      final alarm = 'آخر وقت الدور: السيرفر كمّل ${Perf.turnsServer} · الجوال كمّل ${Perf.turnsPhone}';
      final n = Perf.nav.value;
      String ms(double v) => '${v.round()}ms';
      final nav = n == null
          ? 'التنقل: لسا ما تنقلت'
          : 'التنقل: ${n.page} · أول فريم بناء ${ms(n.build)} رسم ${ms(n.raster)} · '
                'أبطأ ${ms(n.worst)} · متأخر ${n.late} من ${n.count}';
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: .72), borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(server, style: _style),
              Text(draw, style: _style),
              Text(boot, style: _style),
              Text(alarm, style: _style),
              Text(nav, style: _style),
            ],
          ),
        ),
      );
    },
  );
}
