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
  static const _volumeKey = 'sfx_volume';

  /// مستوى صوت الراوي (٠–١).
  static final volume = ValueNotifier<double>(1);

  /// مشغّل الجملة اللي تنقال الحين. كل جملة لها مشغّل جديد: لو نفس المشغّل يوقف جملة ويبدأ اللي بعدها
  /// على طول، أمر الإيقاف ينضيع على أندرويد (تكمل الجملة القديمة لما تقلب صفحة في الشرح).
  static AudioPlayer? _player;
  static final _queue = Queue<String>();
  static bool _speaking = false;

  /// الجملة اللي تنقال الحين تخلص لما يكمل الملف أو ننقطعها (hush).
  static Completer<void>? _done;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      muted.value = prefs.getBool(_key) ?? false;
      volume.value = (prefs.getDouble(_volumeKey) ?? 1).clamp(0.0, 1.0);
    } catch (_) {}
    // لما يطلع من التطبيق يسكت الراوي على طول.
    Music.visible.addListener(() {
      if (!Music.visible.value) hush();
    });
  }

  /// يغيّر مستوى الراوي. [save] false وهو يسحب الشريط، وبعدها يحفظ مرة وحدة.
  static Future<void> setVolume(double v, {bool save = true}) async {
    volume.value = v.clamp(0.0, 1.0);
    _player?.setVolume(volume.value).catchError((_) {});
    if (!save) return;
    try {
      (await SharedPreferences.getInstance()).setDouble(_volumeKey, volume.value);
    } catch (_) {}
  }

  static Future<void> toggle() async {
    muted.value = !muted.value;
    if (muted.value) hush();
    try {
      (await SharedPreferences.getInstance()).setBool(_key, muted.value);
    } catch (_) {}
  }

  /// يقول جملة من assets/voice. لو الراوي يتكلم، تنتظر دورها لين يخلص (ما يقطع جملة بجملة).
  /// السيرفر يعطي وقت بين الأحداث، فالطابور ما يطول. أي خطأ (ملف ناقص أو متصفح يمنع الصوت) ينتجاهل.
  static void say(String line) {
    // برا التطبيق ما يتكلم الراوي (اللعبة تكمل بالبوتات وهو برا).
    if (muted.value || !Music.visible.value) return;
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
    // نعرف إن الجملة خلصت من onPlayerComplete، فما نحتاج متابعة مكانها كل فريم (تثقّل الرسم).
    final player = _player = AudioPlayer()..positionUpdater = null;
    StreamSubscription<void>? sub;
    try {
      sub = player.onPlayerComplete.listen((_) => _finish(done));
      await player.play(AssetSource('voice/$line.mp3'), volume: volume.value);
      // جمل الشرح أطول شوي (لين ١٠ ثواني).
      await done.future.timeout(const Duration(seconds: 12));
    } catch (_) {}
    await sub?.cancel();
    if (identical(_player, player)) _player = null;
    player.dispose().catchError((_) {});
    _next();
  }
}
