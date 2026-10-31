import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/room.dart';
import '../widgets/curtain_route.dart';
import '../screens/chat_screen.dart';
import '../screens/clans_screen.dart';
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
      // السيرفر يحفظ الرمز في ملف اللاعب، والملف أول مرة ينسوى مع فتح اللعبة: ننتظره.
      await Backend.instance.untilProfileLoaded();
      if (token != null) await Backend.instance.registerPushToken(token);
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen(Backend.instance.registerPushToken);
    } catch (e) {
      debugPrint('push init failed: $e');
      return;
    }

    // والتطبيق مفتوح: نعرض الإشعار كشريط تحت بدل إشعار النظام، بس مو وأنت تلعب (يغطي الطاولة).
    // (دعوات الأصدقاء تطلع نافذة من ملفه في LinkWatcher، فما نكررها هنا.)
    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      final kind = m.data['kind'];
      if (n == null || kind == 'invite' || inGame) return;
      // رسالة من صاحب وأنا فاتح محادثته: ما يحتاج شريط.
      if (kind == 'dm' && m.data['from'] == ChatScreen.openFriend) return;
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${n.title ?? ''}\n${n.body ?? ''}'),
          action: switch (kind) {
            'friend' => SnackBarAction(label: 'شوف', onPressed: _openFriends),
            'dm' => SnackBarAction(label: 'رد', onPressed: () => _openDm(m.data['from'])),
            'clanInvite' => SnackBarAction(label: 'شوف', onPressed: _openClans),
            _ when m.data['code'] != null => SnackBarAction(label: 'افتح', onPressed: () => openGame(m.data['code'])),
            _ => null,
          },
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
      case 'dm':
        _openDm(m.data['from']);
      case 'clanInvite':
        _openClans();
      default:
        openGame(code);
    }
  }

  /// محادثة الصاحب اللي أرسل.
  static Future<void> _openDm(Object? from) async {
    if (from is! String || from == ChatScreen.openFriend) return;
    final e = await Backend.instance.fetchPlayer(from).catchError((_) => null);
    if (e == null) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen.friend(friend: (uid: from, name: e.name, avatar: e.avatar, frame: e.frame)),
      ),
    );
  }

  static void _openClans() => navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const ClansScreen()));

  static void _openFriends() => navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => FriendsScreen.forProfile(Backend.instance.profile.value)),
  );

  /// شاشات اللعب المفتوحة. لما تعيد اللعبة الشاشة الجديدة تفتح قبل ما تنقفل القديمة، فنعدّها كلها
  /// (لو حفظنا وحدة بس، القديمة تمسحها وهي تنقفل).
  static final _games = <String>[];

  /// طاولات قاعدين نفتحها (من الإشعار أو الرجوع للعبة): لين تسجل شاشتها نفسها، عشان ما تنفتح مرتين.
  static final _opening = <String>{};

  /// شاشة اللعب تسجل نفسها هنا عشان ما نزعجك بإشعار وأنت تلعب.
  static void enterGame(String code) {
    _opening.remove(code);
    _games.add(code);
  }

  static void leaveGame(String code) => _games.remove(code);

  static bool _isOnGame(Object? code) => code != null && (_games.contains(code) || _opening.contains(code));

  /// اللاعب في طاولة الحين (ما نطلعه منها لرابط دعوة، ولا نطلع له أشرطة الإشعارات).
  static bool get inGame => _games.isNotEmpty;

  /// يفتح طاولة لو اللعبة فيها شغالة (ولو مو مفتوحة أصلاً).
  static Future<void> openGame(Object? code) async {
    if (code is! String || _isOnGame(code)) return;
    _opening.add(code);
    var opened = false;
    try {
      final room = await Backend.instance.watchRoom(code).first;
      if (room?.status != RoomStatus.playing) return;
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      navigator.push(curtainRoute<void>((_) => GameScreen(code: code)));
      opened = true;
    } catch (e) {
      debugPrint('open game $code: $e');
    } finally {
      // انفتحت: تنشال من القائمة لما تسجل شاشتها نفسها (enterGame).
      if (!opened) _opening.remove(code);
    }
  }
}
