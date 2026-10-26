import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/backend.dart';
import 'services/capture.dart';
import 'services/links.dart';
import 'services/push.dart';
import 'services/music.dart';
import 'services/sfx.dart';
import 'services/telemetry.dart';
import 'widgets/ui.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // أول شي نسمع للروابط، عشان ما يفوتنا رابط الدعوة اللي فتح اللعبة.
  Links.init();
  // في نسخة التجربة على الويب نفعّل طبقة الوصول، عشان الاختبارات الآلية تقدر تضغط الأزرار بأسمائها.
  if (kIsWeb && const bool.fromEnvironment('USE_EMULATOR')) {
    SemanticsBinding.instance.ensureSemantics();
    installCaptureHook();
  }
  // اللعبة بالعرض، مثل ألعاب الطاولة. ونخفي أشرطة النظام عشان الشاشة كلها للعبة.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Future.wait([Backend.instance.init(), Sfx.init(), Music.init()]);
  await Telemetry.init();
  Music.play('menu');
  runApp(const MajlisApp());
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
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final backend = Backend.instance;
    if (!backend.isReady) return const HomeScreen();
    return ValueListenableBuilder(
      valueListenable: backend.profileLoaded,
      builder: (context, loaded, _) => !loaded
          ? const NightScaffold(
              body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
            )
          : ValueListenableBuilder(
              valueListenable: backend.profile,
              builder: (context, p, _) => p.setupDone ? const HomeScreen() : const WelcomeScreen(),
            ),
    );
  }
}
