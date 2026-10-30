import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/anim_rigs.dart';
import 'perf.dart';

/// تحميل مسبق لصور اللعبة (الأيقونات، الخلفيات، الملصقات) وقت صفحة التحميل: تنفك وتنحط بذاكرة الصور،
/// فالصفحات والمتجر والطاولة تفتح بدون ما تنتظر الصورة. [progress] من ٠ لين ١ (يعرضه شريط التحميل).
/// الملصقات والشخصيات تكمل بعد ما تطلع الرئيسية (اللعبة تفتح أسرع، والمتجر والطاولة يلقونها جاهزة).
class Preload {
  Preload._();

  static final progress = ValueNotifier<double>(0);
  static Future<void>? _run;

  /// التجهيز ورا الرئيسية (الملصقات والشخصيات وطبقاتها): كم صورة خلصت من كم، ومتى خلص (من تشغيل اللعبة).
  /// يطلع في القياس فوق اللعبة.
  static final background = ValueNotifier<({int done, int total, int? doneMs})>((done: 0, total: 0, doneMs: null));

  /// التنقل بين الصفحات يوقف التجهيز شوي: فك الصور ورفعها لكرت الشاشة ينافس حركة التنقل.
  static final navObserver = _PauseOnNav();
  static DateTime _pausedUntil = DateTime(0);

  /// يشتغل مرة وحدة بالجلسة (لو انطلب ثاني مرة يرجع نفس العمل). يخلص لما تجهز صور الصفحات، والملصقات وراه.
  static Future<void> run(BuildContext context, {String? avatar}) => _run ??= _go(context, avatar);

  static bool _wanted(String a) =>
      (a.startsWith('assets/icons/') ||
          a.startsWith('assets/design/') ||
          a.startsWith('assets/images/') ||
          a.startsWith('assets/stickers/')) &&
      (a.endsWith('.png') || a.endsWith('.webp'));

  static Future<void> _go(BuildContext context, String? avatar) async {
    // ذاكرة الصور تكفي كل اللي نحمّله (الافتراضي ١٠٠ ميجا ويطرد منها)
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = math.max(cache.maximumSizeBytes, 256 << 20);
    cache.maximumSize = math.max(cache.maximumSize, 2000);
    var first = <String>[];
    var later = <String>[];
    var layers = <String>[];
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      first = [
        // صورتك أول، وبعدها الأيقونات والخلفيات اللي تبان بالرئيسية والصفحات
        if (avatar != null && avatar.isNotEmpty) 'assets/avatars/$avatar.webp',
        for (final a in manifest.listAssets())
          if (_wanted(a) && !a.startsWith('assets/stickers/')) a,
      ];
      later = [
        for (final a in manifest.listAssets())
          if (_wanted(a) && a.startsWith('assets/stickers/')) a,
        // الشخصيات (المتجر والملفات والطاولة).
        for (final a in manifest.listAssets())
          if (a.startsWith('assets/avatars/') && !a.startsWith('assets/avatars/anim/') && a.endsWith('.webp')) a,
      ];
      // طبقات الشخصيات المتحركة بحجم المتجر (anim_rigs.dart)، لو بطاقة المتجر (٧٤، item_preview.dart) فعلاً
      // تعرضها بهالحجم بهالجوال.
      if (animLayerCacheWidth(74 * 1.2) != null) {
        layers = [
          for (final a in manifest.listAssets())
            if (a.startsWith('assets/avatars/anim/') && a.endsWith('.webp')) a,
        ];
      }
    } catch (_) {}
    if (!context.mounted) return;
    await _decode(context, first, workers: 4, onProgress: (p) => progress.value = p);
    progress.value = 1;
    // الملصقات والشخصيات بعد ما تطلع الرئيسية، بعامل واحد ويوقف وقت التنقل، عشان ما يثقّل الحركة.
    if (context.mounted) {
      final total = later.length + layers.length;
      var done = 0;
      void tick(double _) {
        done++;
        background.value = (done: done, total: total, doneMs: done >= total ? Perf.sinceStart : null);
      }

      background.value = (done: 0, total: total, doneMs: total == 0 ? Perf.sinceStart : null);
      unawaited(
        _decode(context, later, workers: 1, onProgress: tick, pausable: true).then((_) {
          if (context.mounted) return _decode(context, layers, workers: 1, onProgress: tick, pausable: true, small: true);
        }),
      );
    }
  }

  /// [small]: بحجم طبقات المتجر ([animLayerSmall])، نفس اللي يطلبه Image.asset هناك عشان يلقاها جاهزة.
  static Future<void> _decode(
    BuildContext context,
    List<String> paths, {
    required int workers,
    void Function(double)? onProgress,
    bool pausable = false,
    bool small = false,
  }) async {
    final queue = Queue.of(paths);
    final total = math.max(1, paths.length);
    var done = 0;
    Future<void> worker() async {
      while (queue.isNotEmpty) {
        while (pausable && DateTime.now().isBefore(_pausedUntil)) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        final path = queue.removeFirst();
        try {
          final ImageProvider image = small
              ? ResizeImage(AssetImage(path), width: animLayerSmall)
              : AssetImage(path);
          if (context.mounted) await precacheImage(image, context);
        } catch (_) {}
        onProgress?.call(++done / total);
      }
    }

    await Future.wait([for (var i = 0; i < workers; i++) worker()]);
  }
}

/// صفحة انفتحت أو رجعنا لصفحة: التجهيز يوقف لين تخلص حركة التنقل وأول فريمات الصفحة.
class _PauseOnNav extends NavigatorObserver {
  void _pause(Route<dynamic> route) {
    if (route is PageRoute) Preload._pausedUntil = DateTime.now().add(const Duration(milliseconds: 900));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _pause(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _pause(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _pause(newRoute);
  }
}
