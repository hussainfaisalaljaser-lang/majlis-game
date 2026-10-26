import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/room.dart';
import '../screens/friends_screen.dart';
import '../screens/game_screen.dart';
import 'backend.dart';
import 'links.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

/// يعلم الشاشات لما ترجع لها من صفحة فوقها (مثل الرئيسية بعد اللعبة).
final routeObserver = RouteObserver<ModalRoute<void>>();

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
    // (دعوات الأصدقاء تطلع نافذة من ملفه في LinkWatcher، فما نكررها هنا.)
    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      final kind = m.data['kind'];
      if (n == null || kind == 'invite' || _isOnGame(m.data['code'])) return;
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${n.title ?? ''}\n${n.body ?? ''}'),
          action: kind == 'friend'
              ? SnackBarAction(label: 'شوف', onPressed: _openFriends)
              : m.data['code'] == null
              ? null
              : SnackBarAction(label: 'افتح', onPressed: () => _open(m.data['code'])),
        ),
      );
    });

    // ضغط على الإشعار: نفتح الطاولة، أو ندخل روم الدعوة، أو صفحة الأصدقاء.
    FirebaseMessaging.onMessageOpenedApp.listen(_tapped);
    final initial = await messaging.getInitialMessage();
    if (initial != null) _tapped(initial);
  }

  static void _tapped(RemoteMessage m) {
    final code = m.data['code'];
    switch (m.data['kind']) {
      case 'invite' when code is String:
        Links.joinInvite(code);
      case 'friend':
        _openFriends();
      default:
        _open(code);
    }
  }

  static void _openFriends() => navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => FriendsScreen(tab: Backend.instance.profile.value.friendReqs.isNotEmpty ? 1 : 0)),
  );

  static String? _currentGame;

  /// شاشة اللعب تسجل نفسها هنا عشان ما نزعجك بإشعار عن الطاولة اللي أنت فيها.
  static void setCurrentGame(String? code) => _currentGame = code;

  static bool _isOnGame(Object? code) => code != null && code == _currentGame;

  /// اللاعب في طاولة الحين (ما نطلعه منها لرابط دعوة مثلاً).
  static bool get inGame => _currentGame != null;

  static Future<void> _open(Object? code) async {
    if (code is! String || _isOnGame(code)) return;
    final room = await Backend.instance.watchRoom(code).first;
    if (room?.status != RoomStatus.playing) return;
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => GameScreen(code: code)));
  }
}
