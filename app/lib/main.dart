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
import 'services/perf.dart';
import 'services/preload.dart';
import 'services/sfx.dart';
import 'services/sounds.dart';
import 'services/telemetry.dart';
import 'widgets/fx.dart';
import 'widgets/perf_overlay.dart';
import 'widgets/splash.dart';
import 'theme.dart';

Future<void> main() async {
  // للقياس (أدوات المطور): من هنا نحسب كم ياخذ فتح اللعبة.
  Perf.begin();
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
  await Future.wait([Backend.instance.init(), Sfx.init(), Music.init(), FxClock.init(), Perf.init()]);
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
      navigatorObservers: [routeObserver, Perf.navObserver],
      scaffoldMessengerKey: messengerKey,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // قياس السرعة فوق كل الصفحات (لو شغّلته من أدوات المطور).
      builder: (context, child) => PerfOverlay(child: child ?? const SizedBox()),
      home: const _Gate(),
    );
  }
}

/// أول مرة: الترحيب (قوقل أو ضيف) واختيار الاسم والصورة. بعدها: الرئيسية.
/// صفحة التحميل وقت تشغيل اللعبة: تحمّل الصور مسبقاً (أيقونات وخلفيات وملصقات) عشان اللعبة تطلع سريعة،
/// وتبقى لين تخلص (١٫٦ ثانية على الأقل عشان تنشاف، و١٠ ثواني على الأكثر لو الجهاز بطيء).
class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  /// أقل مدة نعرض فيها صفحة التحميل، وأكثر مدة ننتظر فيها الصور.
  static const _minSplash = Duration(milliseconds: 1600);
  static const _maxSplash = Duration(seconds: 10);

  bool _held = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _warmUp());
  }

  Future<void> _warmUp() async {
    if (!mounted) return;
    final avatar = Backend.instance.profile.value.avatar;
    await Future.wait([
      Future<void>.delayed(_minSplash),
      Preload.run(context, avatar: avatar).timeout(_maxSplash, onTimeout: () {}),
    ]);
    if (mounted) setState(() => _held = false);
  }

  @override
  Widget build(BuildContext context) {
    final backend = Backend.instance;
    if (!backend.isReady) return const HomeScreen();
    return ValueListenableBuilder(
      valueListenable: backend.profileLoaded,
      builder: (context, loaded, _) {
        if (!loaded || _held) {
          return ValueListenableBuilder(
            valueListenable: backend.startupError,
            builder: (context, error, _) =>
                SplashView(progress: Preload.progress, error: error, onRetry: backend.retryStartup),
          );
        }
        // للقياس: فتح اللعبة خلص لما طلعت أول صفحة (الرئيسية، أو الترحيب لو لاعب جديد).
        if (Perf.startupMs == null) WidgetsBinding.instance.addPostFrameCallback((_) => Perf.markStartup());
        return ValueListenableBuilder(
          valueListenable: backend.profile,
          builder: (context, p, _) => p.setupDone ? const HomeScreen() : const WelcomeScreen(),
        );
      },
    );
  }
}
