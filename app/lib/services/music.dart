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
  static const _volumeKey = 'music_volume';

  /// مستوى اللاعب (٠–١): ٠٫٥ هو المستوى الأصلي، فوقه أعلى وتحته أخفض، و٠ يسكتها.
  static final volume = ValueNotifier<double>(.5);

  static double get _level => _volume * volume.value * 2;
  static double get _duckedLevel => _duckedVolume * volume.value * 2;

  static AudioPlayer? _player;
  static String? _track;

  /// المقطع اللي في المشغّل فعلاً (يختلف عن [_track] لو تغيّر وهو برا التطبيق).
  static String? _playing;
  static bool _ducked = false;
  // ignore: unused_field
  static AppLifecycleListener? _lifecycle;

  /// التطبيق ظاهر قدام اللاعب. لما يطلع منه ما نشغّل شي (لا موسيقى ولا راوي) لين يرجع.
  static final visible = ValueNotifier<bool>(true);

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      muted.value = prefs.getBool(_key) ?? false;
      volume.value = (prefs.getDouble(_volumeKey) ?? .5).clamp(0.0, 1.0);
    } catch (_) {}
    _lifecycle = AppLifecycleListener(
      onHide: () {
        visible.value = false;
        _player?.pause().catchError((_) {});
      },
      onShow: () {
        visible.value = true;
        if (muted.value || _track == null) return;
        // لو تغيّر المقطع وهو برا، نشغّل الجديد من أوله.
        if (_player == null || _playing != _track) {
          _start();
        } else {
          _player?.resume().catchError((_) {});
        }
      },
      // قفّل التطبيق كله: نوقف الصوت ونفكه.
      onDetach: () {
        visible.value = false;
        _player?.dispose().catchError((_) {});
        _player = null;
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
    // وهو برا التطبيق (مثلاً بدت اللعبة من غرفة الانتظار): تبدأ لما يرجع.
    if (track == null || muted.value || !visible.value) return;
    try {
      // ما نحتاج مكان الأغنية. متابعته (كل فريم افتراضياً) تخلي الشاشة كلها تنرسم ٦٠ مرة بالثانية طول ما الموسيقى شغالة.
      final player = _player ??= AudioPlayer()
        ..positionUpdater = null
        ..setReleaseMode(ReleaseMode.loop);
      await player.stop();
      _playing = track;
      await player.play(AssetSource('music/$track.mp3'), volume: _ducked ? _duckedLevel : _level);
    } catch (_) {}
  }

  /// الراوي يتكلم: نخفض الموسيقى عشان تنسمع الجملة.
  static void duck(bool on) {
    if (_ducked == on) return;
    _ducked = on;
    _player?.setVolume(on ? _duckedLevel : _level).catchError((_) {});
  }

  /// يغيّر مستوى الموسيقى. [save] false وهو يسحب الشريط، وبعدها يحفظ مرة وحدة.
  static Future<void> setVolume(double v, {bool save = true}) async {
    volume.value = v.clamp(0.0, 1.0);
    _player?.setVolume(_ducked ? _duckedLevel : _level).catchError((_) {});
    if (!save) return;
    try {
      (await SharedPreferences.getInstance()).setDouble(_volumeKey, volume.value);
    } catch (_) {}
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
