import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FramePhase, PlatformDispatcher;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
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

  /// كم مر من تشغيل اللعبة (ms).
  static int get sinceStart => _clock.elapsedMilliseconds;

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
      _navFrame(t);
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

  // ── التنقل بين الصفحات
  /// آخر تنقل: لأي صفحة، وأول فريم بعده (بناء الصفحة الجديدة ورسمها)، وخلال حركة التنقل: أبطأ فريم
  /// وكم فريم تأخر من كم.
  static final nav = ValueNotifier<({String page, double build, double raster, double worst, int late, int count})?>(
    null,
  );

  /// يتسجل في MaterialApp: يعرف متى انفتحت صفحة أو رجعنا لصفحة.
  static final navObserver = _NavProbe();

  /// حركة التنقل ٤٥٠ms (FadeForwards)، ونحسب شوي بعدها.
  static const _navWindowUs = 600000;
  static int? _navAfter, _navStart;
  static String _navPage = '';
  static double _navBuild = 0, _navRaster = 0, _navWorst = 0;
  static int _navCount = 0, _navLate = 0;
  static Timer? _navTimer;

  static void _navStarted(String page) {
    if (!enabled.value) return;
    // الفريمات اللي بعد آخر فريم بدأ هي فريمات التنقل (نفس ترقيم FrameTiming).
    _navAfter = PlatformDispatcher.instance.frameData.frameNumber;
    _navStart = null;
    _navPage = page;
    _navBuild = _navRaster = _navWorst = 0;
    _navCount = _navLate = 0;
    _navTimer?.cancel();
    _navTimer = Timer(const Duration(milliseconds: 1500), _navFlush);
  }

  static void _navFrame(FrameTiming t) {
    final after = _navAfter;
    if (after == null || t.frameNumber <= after) return;
    final start = t.timestampInMicroseconds(FramePhase.buildStart);
    final build = t.buildDuration.inMicroseconds / 1000, raster = t.rasterDuration.inMicroseconds / 1000;
    if (_navStart == null) {
      _navStart = start;
      _navBuild = build;
      _navRaster = raster;
    }
    if (start - _navStart! > _navWindowUs) return _navFlush();
    _navCount++;
    _navWorst = math.max(_navWorst, math.max(build, raster));
    if (t.buildDuration.inMicroseconds > _budgetUs || t.rasterDuration.inMicroseconds > _budgetUs) _navLate++;
  }

  static void _navFlush() {
    _navTimer?.cancel();
    if (_navAfter == null || _navCount == 0) return;
    _navAfter = null;
    nav.value = (
      page: _navPage,
      build: _navBuild,
      raster: _navRaster,
      worst: _navWorst,
      late: _navLate,
      count: _navCount,
    );
  }
}

class _NavProbe extends NavigatorObserver {
  // بس الصفحات (مو النوافذ الصغيرة فوقها).
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _started(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _started(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _started(newRoute);

  /// اسم الصفحة اللي بتطلع (أول ودجت اسمه …Screen فيها)، بعد ما تنبني.
  void _started(Route<dynamic>? route) {
    if (route is! PageRoute || !Perf.enabled.value) return;
    Perf._navStarted('');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String? found;
      void visit(Element e, int depth) {
        if (found != null || depth > 8) return;
        final name = e.widget.runtimeType.toString();
        if (name.endsWith('Screen')) {
          found = name;
          return;
        }
        e.visitChildren((c) => visit(c, depth + 1));
      }

      final context = route.subtreeContext;
      if (context is Element) visit(context, 0);
      Perf._navPage = found ?? route.settings.name ?? '';
    });
  }
}
