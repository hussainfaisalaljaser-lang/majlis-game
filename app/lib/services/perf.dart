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

  /// يبدأ من أول سطر في main ([begin]).
  static final _clock = Stopwatch();

  /// من تشغيل اللعبة لين طلعت أول صفحة (الرئيسية، أو الترحيب لو لاعب جديد).
  static int? startupMs;

  /// من تشغيل اللعبة لين وصل ملف اللاعب من قاعدة البيانات.
  static int? firstDataMs;

  /// شهادة قوقل: كم أخذت، وهل نجحت.
  static ({int ms, bool ok})? appCheck;

  /// آخر ٣٠ طلب لكل نوع (بالملي ثانية): الوقت كامل، وكم منه شغل السيرفر نفسه (الباقي الطريق).
  static final _calls = <String, List<int>>{};
  static final _server = <String, List<int>>{};

  /// آخر طلب (يتحدث القياس اللي فوق اللعبة). [server]: شغل السيرفر (null لو ما رجعه)، و[parts] أجزاؤه.
  static final last = ValueNotifier<({String fn, int ms, bool ok, int? server, String? parts})?>(null);

  /// أدوار خلص وقتها: كم واحد كمّله منبّه السيرفر بنفسه، وكم واحد احتاج الجوال يطلبه.
  static int turnsServer = 0, turnsPhone = 0;
  static final turns = ValueNotifier<int>(0);

  static void turnEnded({required bool byServer}) {
    byServer ? turnsServer++ : turnsPhone++;
    turns.value++;
  }

  /// الرسم كل ثانية: فريمات بالثانية، ونسبة الفريمات المتأخرة (البناء أو الرسم أخذ أكثر من وقت الفريم)،
  /// ومتوسط وقت البناء والرسم.
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

  /// أول سطر في main.
  static void begin() => _clock.start();

  static void markStartup() => startupMs ??= _clock.elapsedMilliseconds;

  static void markFirstData() => firstDataMs ??= _clock.elapsedMilliseconds;

  static void recordCall(String fn, int ms, {bool ok = true, int? server, String? parts}) {
    _keep(_calls, fn, ms);
    if (server != null) _keep(_server, fn, server);
    last.value = (fn: fn, ms: ms, ok: ok, server: server, parts: parts);
  }

  /// أجزاء شغل السيرفر من الرد (_t): الحفظ، والمنبّه والإشعار (يمشون مع بعض بعد الحفظ).
  static String? partsOf(Object? t) {
    if (t is! Map) return null;
    final out = [
      for (final (key, label) in const [('work', 'الحفظ'), ('tick', 'المنبّه'), ('push', 'الإشعار')])
        if (t[key] is num) '$label ${(t[key] as num).round()}',
    ];
    return out.isEmpty ? null : out.join(' · ');
  }

  static void _keep(Map<String, List<int>> lists, String fn, int ms) {
    final list = lists.putIfAbsent(fn, () => []);
    list.add(ms);
    if (list.length > 30) list.removeAt(0);
  }

  static int _avg(List<int> list) => list.reduce((a, b) => a + b) ~/ list.length;

  /// كل الطلبات: (النوع، العدد، المتوسط، الأبطأ، متوسط شغل السيرفر)، الأبطأ أول.
  static List<({String fn, int n, int avg, int max, int? server})> callStats() {
    final out = [
      for (final MapEntry(:key, :value) in _calls.entries)
        (
          fn: key,
          n: value.length,
          avg: _avg(value),
          max: value.reduce(math.max),
          server: _server[key] == null ? null : _avg(_server[key]!),
        ),
    ];
    out.sort((a, b) => b.avg.compareTo(a.avg));
    return out;
  }

  static void reset() {
    _calls.clear();
    _server.clear();
    last.value = null;
    turnsServer = turnsPhone = 0;
    turns.value++;
  }

  // ── الرسم
  static const _budgetUs = 16700;
  static int _count = 0, _late = 0;
  static double _buildSum = 0, _rasterSum = 0;
  static final _window = Stopwatch()..start();
  static Timer? _idle;

  static void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _count++;
      _buildSum += t.buildDuration.inMicroseconds / 1000;
      _rasterSum += t.rasterDuration.inMicroseconds / 1000;
      // البناء والرسم يشتغلون بنفس الوقت (كل واحد على فريم)، فالفريم يتأخر لو واحد منهم تعدّى ١٦٫٧ms.
      if (t.buildDuration.inMicroseconds > _budgetUs || t.rasterDuration.inMicroseconds > _budgetUs) _late++;
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
