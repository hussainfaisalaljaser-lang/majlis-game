import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// تحميل مسبق لصور اللعبة (الأيقونات، الخلفيات، الملصقات) وقت صفحة التحميل: تنفك وتنحط بذاكرة الصور،
/// فالصفحات والمتجر والطاولة تفتح بدون ما تنتظر الصورة. [progress] من ٠ لين ١ (يعرضه شريط التحميل).
/// الملصقات ما تبان إلا لما تفتح التفاعل أو الدردشة، فتكمل بعد ما تطلع الرئيسية (اللعبة تفتح أسرع).
class Preload {
  Preload._();

  static final progress = ValueNotifier<double>(0);
  static Future<void>? _run;

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
    cache.maximumSizeBytes = math.max(cache.maximumSizeBytes, 220 << 20);
    cache.maximumSize = math.max(cache.maximumSize, 2000);
    var first = <String>[];
    var later = <String>[];
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
      ];
    } catch (_) {}
    if (!context.mounted) return;
    await _decode(context, first, workers: 4, onProgress: (p) => progress.value = p);
    progress.value = 1;
    // الملصقات بعد ما تطلع الرئيسية، بعاملين بس عشان ما تثقّل حركتها.
    if (context.mounted) unawaited(_decode(context, later, workers: 2));
  }

  static Future<void> _decode(
    BuildContext context,
    List<String> paths, {
    required int workers,
    void Function(double)? onProgress,
  }) async {
    final queue = Queue.of(paths);
    final total = math.max(1, paths.length);
    var done = 0;
    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final path = queue.removeFirst();
        try {
          if (context.mounted) await precacheImage(AssetImage(path), context);
        } catch (_) {}
        onProgress?.call(++done / total);
      }
    }

    await Future.wait([for (var i = 0; i < workers; i++) worker()]);
  }
}
