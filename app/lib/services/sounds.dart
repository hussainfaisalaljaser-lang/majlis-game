import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'music.dart';
import 'sfx.dart';

/// مؤثرات لحظات الطاولة (assets/sfx، مولّدة بالكود من tools/sfx/make_sfx.py): طبل، قلب كرت، ختم، رعد…
/// تنكتم مع زر الصوت (نفس الراوي)، وما تشتغل والتطبيق برا. قصيرة، فنشغّلها على مشغّلات جاهزة بالدور.
abstract final class Sounds {
  /// اختبارات التصوير ما فيها مشغّل صوت، فنسكتها.
  static bool silent = false;

  /// كل ملفات assets/sfx (اختبار يتأكد إنها نفس اللي في المجلد).
  static const all = [
    'whoosh',
    'flip',
    'drum',
    'drum2',
    'yes',
    'no',
    'stamp',
    'thud_red',
    'crack',
    'shatter',
    'lamp_out',
    'shield',
    'heartbeat',
    'sting_traitor',
    'sting_loyal',
    'sting_leader',
    'win',
    'sparkle',
    'mask_drop',
    'tick',
    'thunder',
    'fire',
    'ice',
    'wings',
    'ghost',
    'gong',
    'airy',
    'puff',
    'coin',
    'level',
  ];

  /// يجهّز الملفات من أول ما تبدأ اللعبة، عشان أول مرة يشتغل فيها صوت ما يتأخر عن لحظته.
  static void warm() {
    if (silent) return;
    try {
      AudioCache.instance.loadAll([for (final n in all) 'sfx/$n.wav']).catchError((_) => <Uri>[]);
    } catch (_) {}
  }

  /// سياق الصوت لكل اللعبة: ما يطلب «تركيز الصوت» من أندرويد. بدون هذا كل مشغّل جديد (مؤثر أو جملة راوي)
  /// ياخذ التركيز من الباقين، فتوقف الموسيقى والراوي كل ما يشتغل مؤثر.
  static final _context = AudioContext(android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none));

  /// يخلي كل المشغّلات اللي تنفتح بعدها تشتغل مع بعض بدون ما توقف بعض (يُستدعى مرة وحدة من main).
  static Future<void> init() async {
    if (silent) return;
    try {
      volume.value = ((await SharedPreferences.getInstance()).getDouble(_volumeKey) ?? .35).clamp(0.0, 1.0);
    } catch (_) {}
    try {
      await AudioPlayer.global.setAudioContext(_context);
    } catch (_) {}
  }

  static const _volumeKey = 'fx_volume';

  /// مستوى المؤثرات (٠–١) من إعدادات اللاعب. ملفات الصوت نفسها بأعلى مستوى، فهذا اللي يحدد قد إيش تنسمع.
  static final volume = ValueNotifier<double>(.35);

  /// يغيّر مستوى المؤثرات. [save] false وهو يسحب الشريط، وبعدها يحفظ مرة وحدة.
  static Future<void> setVolume(double v, {bool save = true}) async {
    volume.value = v.clamp(0.0, 1.0);
    if (!save) return;
    try {
      (await SharedPreferences.getInstance()).setDouble(_volumeKey, volume.value);
    } catch (_) {}
  }

  static const _pool = 6;
  static final _players = <AudioPlayer>[];
  static int _next = 0;

  /// يشغّل [name] (اسم ملف في assets/sfx بدون .wav). [volume] من ٠ لـ١. أي خطأ ينتجاهل.
  static void play(String name, {double volume = 1}) {
    if (silent || Sfx.muted.value || !Music.visible.value) return;
    try {
      final player = _players.length < _pool
          ? (AudioPlayer()
              ..positionUpdater = null
              ..setAudioContext(_context)
              ..setPlayerMode(PlayerMode.lowLatency))
          : _players[_next];
      if (_players.length < _pool) _players.add(player);
      _next = (_next + 1) % _pool;
      player
          .play(AssetSource('sfx/$name.wav'), volume: (volume * Sounds.volume.value).clamp(0.0, 1.0))
          .catchError((_) {});
    } catch (_) {}
  }
}
