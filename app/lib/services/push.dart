import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/room.dart';
import '../screens/game_screen.dart';
import 'backend.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

/// الإشعارات: لما يجي دورك أو تبدأ اللعبة والتطبيق مقفول أو بالخلفية.
abstract final class Push {
  static Future<void> init() async {
    if (kIsWeb || !Backend.instance.isReady) return;
    final messaging = FirebaseMessaging.instance;
    try {
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      // register()/onRegistered الجديدة ترجع معرّف تثبيت (FID) بدل رمز التسجيل، والسيرفر يرسل
      // بالرمز عن طريق getMessaging().sendEach({token}). نخلي الطريقة الحالية لين ننقل السيرفر.
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) await Backend.instance.registerPushToken(token);
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen(Backend.instance.registerPushToken);
    } catch (e) {
      debugPrint('push init failed: $e');
      return;
    }

    // والتطبيق مفتوح: نعرض الإشعار كشريط تحت بدل إشعار النظام.
    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n == null || _isOnGame(m.data['code'])) return;
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${n.title ?? ''}\n${n.body ?? ''}'),
          action: m.data['code'] == null ? null : SnackBarAction(label: 'افتح', onPressed: () => _open(m.data['code'])),
        ),
      );
    });

    // ضغط على الإشعار: نفتح الطاولة.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data['code']));
    final initial = await messaging.getInitialMessage();
    if (initial != null) _open(initial.data['code']);
  }

  static String? _currentGame;

  /// شاشة اللعب تسجل نفسها هنا عشان ما نزعجك بإشعار عن الطاولة اللي أنت فيها.
  static void setCurrentGame(String? code) => _currentGame = code;

  static bool _isOnGame(Object? code) => code != null && code == _currentGame;

  static Future<void> _open(Object? code) async {
    if (code is! String || _isOnGame(code)) return;
    final room = await Backend.instance.watchRoom(code).first;
    if (room?.status != RoomStatus.playing) return;
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => GameScreen(code: code)));
  }
}
