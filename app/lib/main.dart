import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/frame_gallery.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/backend.dart';
import 'services/capture.dart';
import 'services/links.dart';
import 'services/presence.dart';
import 'services/push.dart';
import 'services/music.dart';
import 'services/sfx.dart';
import 'services/sounds.dart';
import 'services/telemetry.dart';
import 'widgets/fx.dart';
import 'widgets/splash.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // أول شي نسمع للروابط، عشان ما يفوتنا رابط الدعوة اللي فتح اللعبة.
  Links.init();
  // في نسخة التجربة على الويب نفعّل طبقة الوصول، عشان الاختبارات الآلية تقدر تضغط الأزرار بأسمائها.
  if (kIsWeb && const bool.fromEnvironment('USE_EMULATOR')) {
    SemanticsBinding.instance.ensureSemantics();
    installCaptureHook();
    if (Uri.base.queryParameters.containsKey('gallery')) return runApp(const FrameGalleryApp());
  }
  // اللعبة بالعرض، مثل ألعاب الطاولة. ونخفي أشرطة النظام عشان الشاشة كلها للعبة.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // أول شي: كل مشغّلات الصوت تشتغل مع بعض (موسيقى وراوي ومؤثرات) بدون ما أحد ياخذ تركيز الصوت من الثاني
  await Sounds.init();
  await Future.wait([Backend.instance.init(), Sfx.init(), Music.init(), FxClock.init()]);
  await Telemetry.init();
  Music.play('menu');
  runApp(const MajlisApp());
  // حالة اتصالي لأصحابي وربعي في الديوان.
  PresenceService.instance.start();
  await Push.init();
}

class MajlisApp extends StatelessWidget {
  const MajlisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مجلس الخونة',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      scaffoldMessengerKey: messengerKey,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _Gate(),
    );
  }
}

/// أول مرة: الترحيب (قوقل أو ضيف) واختيار الاسم والصورة. بعدها: الرئيسية.
/// صفحة التحميل تبقى ظاهرة ٢٫٤ ثانية على الأقل عند تشغيل اللعبة (حتى لو الملف جاهز بسرعة)، عشان تنشاف.
class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  /// أقل مدة نعرض فيها صفحة التحميل أول ما تفتح اللعبة.
  static const _minSplash = Duration(milliseconds: 2400);

  bool _held = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_minSplash, () {
      if (mounted) setState(() => _held = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = Backend.instance;
    if (!backend.isReady) return const HomeScreen();
    return ValueListenableBuilder(
      valueListenable: backend.profileLoaded,
      builder: (context, loaded, _) => !loaded || _held
          ? const SplashView()
          : ValueListenableBuilder(
              valueListenable: backend.profile,
              builder: (context, p, _) => p.setupDone ? const HomeScreen() : const WelcomeScreen(),
            ),
    );
  }
}
