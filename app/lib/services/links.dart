import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/waiting_screen.dart';
import '../theme.dart';
import 'backend.dart';
import 'push.dart';
import 'telemetry.dart';

/// روابط دعوة الروم: majlis-game-1d739.web.app/r/CODE (أو majlis://room/CODE) تفتح اللعبة
/// وتدخلك الروم على طول. لو اللعبة مو محمّلة، صفحة الرابط تعطيه رابط التحميل (site/room.html).
abstract final class Links {
  static const host = 'majlis-game-1d739.web.app';

  /// رمز روم وصل من رابط، وينتظر اللاعب يوصل الرئيسية (بعد ما يسجل ويختار اسمه).
  static final pending = ValueNotifier<String?>(null);

  static String roomUrl(String code) => 'https://$host/r/$code';

  static String inviteText(String code) =>
      'تعال العب معي «مجلس الخونة»! مين الخاين فينا؟\nادخل الروم بالكود $code أو من الرابط:\n${roomUrl(code)}';

  /// نسمع للروابط من أول ما تفتح اللعبة (الرابط اللي فتحها وأي رابط بعده). في الويب: رابط الصفحة نفسها.
  static void init() {
    try {
      AppLinks().uriLinkStream.listen((uri) {
        final code = codeFrom(uri);
        if (code != null) pending.value = code;
      }, onError: (_) {});
    } catch (e) {
      debugPrint('links init failed: $e');
    }
  }

  /// رمز الروم من الرابط، أو null لو مو رابط روم. (?room=CODE نفس صفحة التحميل.)
  static String? codeFrom(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final raw = switch (uri) {
      Uri(scheme: 'majlis', host: 'room') => segments.firstOrNull,
      Uri(host: host) when segments.length >= 2 && segments.first == 'r' => segments[1],
      _ => uri.queryParameters['room'],
    };
    final code = raw?.toUpperCase();
    return code != null && RegExp(r'^[A-Z0-9]{5}$').hasMatch(code) ? code : null;
  }

  /// يفتح واتساب برسالة الدعوة (ولو مو موجود، wa.me تفتح في المتصفح).
  static Future<bool> whatsapp(String code) async {
    try {
      return await launchUrl(
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(inviteText(code))}'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> copy(String code) => Clipboard.setData(ClipboardData(text: inviteText(code)));
}

/// يدخلك الروم اللي وصلك رابطه، أول ما تكون في الرئيسية (مو وسط لعبة).
class LinkWatcher extends StatefulWidget {
  const LinkWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<LinkWatcher> createState() => _LinkWatcherState();
}

class _LinkWatcherState extends State<LinkWatcher> {
  bool _busy = false;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    Links.pending.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _retry?.cancel();
    Links.pending.removeListener(_check);
    super.dispose();
  }

  Future<void> _check() async {
    final code = Links.pending.value;
    if (code == null || _busy || !mounted || !Backend.instance.isReady) return;
    // وسط لعبة: ننتظر لين تخلص، وبعدين ندخله.
    if (Push.inGame) {
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 3), _check);
      return;
    }
    _busy = true;
    Links.pending.value = null;
    final navigator = navigatorKey.currentState;
    final messenger = messengerKey.currentState;
    if (navigator == null) {
      _busy = false;
      return;
    }
    showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(width: 16),
            Text('ندخلك روم $code…'),
          ],
        ),
      ),
    );
    try {
      await Backend.instance.joinRoom(code);
      Telemetry.joinRoom('link');
      navigator.pop();
      navigator.push(MaterialPageRoute(builder: (_) => WaitingScreen(tier: null, playerCount: 5, code: code)));
    } on BackendException catch (e) {
      navigator.pop();
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
