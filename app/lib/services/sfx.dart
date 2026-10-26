import 'dart:async';
import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'music.dart';

/// صوت الراوي: جمل عربية قصيرة في لحظات اللعبة المهمة (assets/voice، مولّدة من tools/voice).
/// تقدر تسكته من زر الصوت وينحفظ في الجهاز.
abstract final class Sfx {
  static final muted = ValueNotifier<bool>(false);
  static const _key = 'sfx_muted';
  static AudioPlayer? _player;
  static final _queue = Queue<String>();
  static bool _speaking = false;

  /// الجملة اللي تنقال الحين تخلص لما يكمل الملف أو ننقطعها (hush).
  static Completer<void>? _done;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      muted.value = prefs.getBool(_key) ?? false;
    } catch (_) {}
  }

  static Future<void> toggle() async {
    muted.value = !muted.value;
    if (muted.value) {
      _queue.clear();
      _player?.stop().catchError((_) {});
    }
    try {
      (await SharedPreferences.getInstance()).setBool(_key, muted.value);
    } catch (_) {}
  }

  /// يقول جملة من assets/voice. لو الراوي يتكلم، تنتظر دورها لين يخلص (ما يقطع جملة بجملة).
  /// السيرفر يعطي وقت بين الأحداث، فالطابور ما يطول. أي خطأ (ملف ناقص أو متصفح يمنع الصوت) ينتجاهل.
  static void say(String line) {
    if (muted.value) return;
    if (_queue.length >= 4) _queue.removeFirst();
    _queue.add(line);
    if (!_speaking) _next();
  }

  /// يسكت الراوي على طول ويمسح اللي ينتظر (مثل لما تقلب صفحة في الشرح).
  static void hush() {
    _queue.clear();
    _player?.stop().catchError((_) {});
    _finish(_done);
  }

  static void _finish(Completer<void>? c) {
    if (c != null && !c.isCompleted) c.complete();
  }

  static Future<void> _next() async {
    if (_queue.isEmpty || muted.value) {
      _speaking = false;
      Music.duck(false);
      return;
    }
    _speaking = true;
    Music.duck(true);
    final line = _queue.removeFirst();
    // في نسخة التجربة على المحاكي نطبع كل جملة، عشان الاختبارات تتأكد من التوقيت.
    if (const bool.fromEnvironment('USE_EMULATOR')) {
      debugPrint('narrator: $line ${DateTime.now().millisecondsSinceEpoch}');
    }
    final done = _done = Completer<void>();
    StreamSubscription<void>? sub;
    try {
      // نعرف إن الجملة خلصت من onPlayerComplete، فما نحتاج متابعة مكانها كل فريم (تثقّل الرسم).
      final player = _player ??= AudioPlayer()
        ..positionUpdater = null
        ..setReleaseMode(ReleaseMode.stop);
      sub = player.onPlayerComplete.listen((_) => _finish(done));
      await player.play(AssetSource('voice/$line.mp3'));
      // جمل الشرح أطول شوي (لين ١٠ ثواني).
      await done.future.timeout(const Duration(seconds: 12));
    } catch (_) {}
    await sub?.cancel();
    _next();
  }
}
