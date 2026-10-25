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
  static final _quiet = <Completer<void>>[];

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

  /// يخلص لما يسكت الراوي (مثلاً بطاقة الدور تنتظر الترحيب يخلص قبل ما تنقلب).
  static Future<void> whenQuiet() {
    if (!_speaking) return Future.value();
    final c = Completer<void>();
    _quiet.add(c);
    return c.future;
  }

  static Future<void> _next() async {
    if (_queue.isEmpty || muted.value) {
      _speaking = false;
      Music.duck(false);
      for (final c in _quiet) {
        c.complete();
      }
      _quiet.clear();
      return;
    }
    _speaking = true;
    Music.duck(true);
    final line = _queue.removeFirst();
    // في نسخة التجربة على المحاكي نطبع كل جملة، عشان الاختبارات تتأكد من التوقيت.
    if (const bool.fromEnvironment('USE_EMULATOR')) debugPrint('narrator: $line ${DateTime.now().millisecondsSinceEpoch}');
    try {
      final player = _player ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await player.play(AssetSource('voice/$line.mp3'));
      await player.onPlayerComplete.first.timeout(const Duration(seconds: 8));
    } catch (_) {}
    _next();
  }
}
