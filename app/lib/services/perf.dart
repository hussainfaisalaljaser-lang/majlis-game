import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// قياس السرعة (من أدوات المطور): كم ياخذ كل طلب للسيرفر، وكم الشاشة سلسة، وكم ياخذ فتح اللعبة،
/// وكم تاخذ شهادة قوقل (App Check). يطلع فوق اللعبة عشان تصوّره وأنت تلعب.
abstract final class Perf {
  static const _key = 'perf_overlay';

  /// يطلع القياس فوق اللعبة.
  static final enabled = ValueNotifier<bool>(false);

  /// من تشغيل اللعبة (main) لين طلعت الرئيسية.
  static final _clock = Stopwatch()..start();
  static int? startupMs;

  /// أول ملف من قاعدة البيانات بعد التشغيل.
  static int? firstDataMs;

  /// شهادة قوقل: كم أخذت، وهل نجحت.
  static ({int ms, bool ok})? appCheck;

  /// آخر ٣٠ طلب لكل نوع (بالملي ثانية).
  static final _calls = <String, List<int>>{};

  /// آخر طلب (يتحدث القياس اللي فوق اللعبة).
  static final last = ValueNotifier<({String fn, int ms, bool ok})?>(null);

  /// أدوار خلص وقتها: كم واحد كمّله منبّه السيرفر بنفسه، وكم واحد احتاج الجوال يطلبه.
  static int turnsServer = 0, turnsPhone = 0;
  static final turns = ValueNotifier<int>(0);

  static void turnEnded({required bool byServer}) {
    byServer ? turnsServer++ : turnsPhone++;
    turns.value++;
  }

  /// الرسم كل ثانية: فريمات بالثانية، ونسبة الفريمات المتأخرة، ومتوسط وقت البناء والرسم.
  static final frames = ValueNotifier<({double fps, double jank, double build, double raster})?>(null);

  static Future<void> init() async {
    try {
      enabled.value = (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (_) {}
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static Future<void> setEnabled(bool on) async {
    enabled.value = on;
    try {
      (await SharedPreferences.getInstance()).setBool(_key, on);
    } catch (_) {}
  }

  static void markStartup() => startupMs ??= _clock.elapsedMilliseconds;

  static void markFirstData() => firstDataMs ??= _clock.elapsedMilliseconds;

  static void recordCall(String fn, int ms, {bool ok = true}) {
    final list = _calls.putIfAbsent(fn, () => []);
    list.add(ms);
    if (list.length > 30) list.removeAt(0);
    last.value = (fn: fn, ms: ms, ok: ok);
  }

  /// كل الطلبات: (النوع، العدد، المتوسط، الأبطأ)، الأبطأ أول.
  static List<({String fn, int n, int avg, int max})> callStats() {
    final out = [
      for (final MapEntry(:key, :value) in _calls.entries)
        (fn: key, n: value.length, avg: value.reduce((a, b) => a + b) ~/ value.length, max: value.reduce(math.max)),
    ];
    out.sort((a, b) => b.avg.compareTo(a.avg));
    return out;
  }

  static void reset() {
    _calls.clear();
    last.value = null;
    turnsServer = turnsPhone = 0;
    turns.value++;
  }

  // ── الرسم
  static int _count = 0, _late = 0;
  static double _buildSum = 0, _rasterSum = 0;
  static final _window = Stopwatch()..start();
  static Timer? _idle;

  static void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _count++;
      _buildSum += t.buildDuration.inMicroseconds / 1000;
      _rasterSum += t.rasterDuration.inMicroseconds / 1000;
      if (t.totalSpan.inMicroseconds > 17000) _late++;
    }
    if (_window.elapsedMilliseconds >= 1000) _flush();
    // لو وقف الرسم (ما فيه حركة)، نبيّن صفر بعد ثانية.
    _idle?.cancel();
    _idle = Timer(const Duration(milliseconds: 1200), _flush);
  }

  static void _flush() {
    final secs = math.max(_window.elapsedMilliseconds / 1000, .001);
    frames.value = _count == 0
        ? (fps: 0, jank: 0, build: 0, raster: 0)
        : (fps: _count / secs, jank: _late / _count, build: _buildSum / _count, raster: _rasterSum / _count);
    _count = _late = 0;
    _buildSum = _rasterSum = 0;
    _window
      ..reset()
      ..start();
  }
}
