import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// أصوات اللعبة القصيرة. تقدر تسكتها من الإعدادات وتنحفظ في الجهاز.
abstract final class Sfx {
  static final muted = ValueNotifier<bool>(false);
  static final _players = <String, AudioPlayer>{};
  static const _key = 'sfx_muted';

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      muted.value = prefs.getBool(_key) ?? false;
    } catch (_) {}
  }

  static Future<void> toggle() async {
    muted.value = !muted.value;
    try {
      (await SharedPreferences.getInstance()).setBool(_key, muted.value);
    } catch (_) {}
  }

  /// يشغّل صوت من assets/sounds. أي خطأ (مثل متصفح يمنع الصوت) ينتجاهل.
  static void play(String name) {
    if (muted.value) return;
    try {
      final player = _players.putIfAbsent(name, () => AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      player.stop().then((_) => player.play(AssetSource('sounds/$name.ogg'), volume: .8)).catchError((_) {});
    } catch (_) {}
  }
}
