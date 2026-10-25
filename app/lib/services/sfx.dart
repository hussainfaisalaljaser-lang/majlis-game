import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// صوت الراوي: جمل عربية قصيرة في لحظات اللعبة المهمة (assets/voice، مولّدة من tools/voice).
/// تقدر تسكته من زر الصوت وينحفظ في الجهاز.
abstract final class Sfx {
  static final muted = ValueNotifier<bool>(false);
  static const _key = 'sfx_muted';
  static AudioPlayer? _player;
  static final _queue = Queue<String>();
  static bool _speaking = false;

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

  /// يقول جملة من assets/voice. لو الراوي يتكلم، تنتظر دورها (ونخلي اثنتين بس في الطابور
  /// عشان ما يتأخر عن اللعبة). أي خطأ (ملف ناقص أو متصفح يمنع الصوت) ينتجاهل.
  static void say(String line) {
    if (muted.value) return;
    if (_queue.length >= 2) _queue.removeFirst();
    _queue.add(line);
    if (!_speaking) _next();
  }

  static Future<void> _next() async {
    if (_queue.isEmpty || muted.value) {
      _speaking = false;
      return;
    }
    _speaking = true;
    final line = _queue.removeFirst();
    try {
      final player = _player ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await player.play(AssetSource('voice/$line.mp3'));
      await player.onPlayerComplete.first.timeout(const Duration(seconds: 6));
    } catch (_) {}
    _next();
  }
}
