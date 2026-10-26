import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'backend.dart';

/// تسجيل الأعطال (Crashlytics) وأحداث اللعب (Analytics)، عشان نعرف وش يخرب عند الناس ووين يوقفون.
/// يشتغل بس في نسخة أندرويد الحقيقية: مو الويب، ولا التجربة على المحاكي، ولا وضع التطوير.
abstract final class Telemetry {
  static FirebaseAnalytics? _analytics;
  static int _level = 0;

  static bool get _on => _analytics != null;

  /// بعد ما يتصل Firebase (Backend.init).
  static Future<void> init() async {
    if (kIsWeb || kDebugMode || const bool.fromEnvironment('USE_EMULATOR') || !Backend.instance.isReady) return;
    try {
      final crash = FirebaseCrashlytics.instance;
      await crash.setCrashlyticsCollectionEnabled(true);
      // أخطاء فلاتر (الواجهة) وأي خطأ ما انمسك في الكود.
      FlutterError.onError = crash.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        crash.recordError(error, stack, fatal: true);
        return true;
      };
      _analytics = FirebaseAnalytics.instance;
      // نربط الأعطال والأحداث برقم الحساب (مو اسمه ولا إيميله).
      FirebaseAuth.instance.authStateChanges().listen((u) {
        if (u == null) return;
        crash.setUserIdentifier(u.uid);
        _analytics?.setUserId(id: u.uid);
      });
      // طلوع المستوى: نقارن بالملف اللي قبل.
      Backend.instance.profile.addListener(() {
        final level = Backend.instance.profile.value.level;
        if (_level > 0 && level > _level) _log(() => _analytics!.logLevelUp(level: level));
        _level = level;
      });
    } catch (e) {
      debugPrint('telemetry init failed: $e');
    }
  }

  static void _log(Future<void> Function() send) {
    if (!_on) return;
    send().catchError((Object e) => debugPrint('analytics failed: $e'));
  }

  static void tutorialBegin() => _log(() => _analytics!.logTutorialBegin());

  static void tutorialComplete() => _log(() => _analytics!.logTutorialComplete());

  /// [method]: whatsapp أو copy.
  static void invite(String method) =>
      _log(() => _analytics!.logShare(contentType: 'room_invite', itemId: 'room', method: method));

  /// [via]: code (كتب الكود) أو link (رابط دعوة).
  static void joinRoom(String via) => _log(() => _analytics!.logJoinGroup(groupId: 'room', parameters: {'via': via}));

  static void spend(String item, String currency, int value) =>
      _log(() => _analytics!.logSpendVirtualCurrency(itemName: item, virtualCurrencyName: currency, value: value));

  static void gameStart({required int players, required bool tutorial, required bool bots}) => _log(
    () => _analytics!.logEvent(
      name: 'game_start',
      parameters: {'players': players, 'tutorial': tutorial ? 1 : 0, 'bots': bots ? 1 : 0},
    ),
  );

  static void gameEnd({required bool won, required String reason, required int rounds, required bool tutorial}) => _log(
    () => _analytics!.logEvent(
      name: 'game_end',
      parameters: {'won': won ? 1 : 0, 'reason': reason, 'rounds': rounds, 'tutorial': tutorial ? 1 : 0},
    ),
  );

  /// طلع من لعبة شغالة قبل لا تخلص.
  static void gameLeft({required int round, required bool tutorial}) =>
      _log(() => _analytics!.logEvent(name: 'game_left', parameters: {'round': round, 'tutorial': tutorial ? 1 : 0}));
}
