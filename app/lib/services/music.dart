import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// موسيقى الخلفية (assets/music): وحدة للقوائم ووحدة للعب، تدور بدون توقف.
/// صوتها منخفض، وتنخفض أكثر لما يتكلم الراوي، وتوقف لما تطلع من التطبيق.
abstract final class Music {
  static final muted = ValueNotifier<bool>(false);
  static const _key = 'music_muted';
  static const _volume = .28;
  static const _duckedVolume = .08;

  static AudioPlayer? _player;
  static String? _track;
  static bool _ducked = false;
  // ignore: unused_field
  static AppLifecycleListener? _lifecycle;

  static Future<void> init() async {
    try {
      muted.value = (await SharedPreferences.getInstance()).getBool(_key) ?? false;
    } catch (_) {}
    _lifecycle = AppLifecycleListener(
      onHide: () => _player?.pause().catchError((_) {}),
      onShow: () {
        if (!muted.value && _track != null) _player?.resume().catchError((_) {});
      },
    );
  }

  /// يشغّل مقطع ('menu' أو 'game'). لو هو نفسه شغال ما يعيده من البداية.
  static void play(String track) {
    if (_track == track) return;
    _track = track;
    _start();
  }

  static Future<void> _start() async {
    final track = _track;
    if (track == null || muted.value) return;
    try {
      // ما نحتاج مكان الأغنية. متابعته (كل فريم افتراضياً) تخلي الشاشة كلها تنرسم ٦٠ مرة بالثانية طول ما الموسيقى شغالة.
      final player = _player ??= AudioPlayer()
        ..positionUpdater = null
        ..setReleaseMode(ReleaseMode.loop);
      await player.stop();
      await player.play(AssetSource('music/$track.mp3'), volume: _ducked ? _duckedVolume : _volume);
    } catch (_) {}
  }

  /// الراوي يتكلم: نخفض الموسيقى عشان تنسمع الجملة.
  static void duck(bool on) {
    if (_ducked == on) return;
    _ducked = on;
    _player?.setVolume(on ? _duckedVolume : _volume).catchError((_) {});
  }

  static Future<void> toggle() async {
    muted.value = !muted.value;
    if (muted.value) {
      await _player?.stop().catchError((_) {});
    } else {
      await _start();
    }
    try {
      (await SharedPreferences.getInstance()).setBool(_key, muted.value);
    } catch (_) {}
  }
}
