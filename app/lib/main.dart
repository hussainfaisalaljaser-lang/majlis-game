import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'services/backend.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // في نسخة التجربة على الويب نفعّل طبقة الوصول، عشان الاختبارات الآلية تقدر تضغط الأزرار بأسمائها.
  if (kIsWeb && const bool.fromEnvironment('USE_EMULATOR')) SemanticsBinding.instance.ensureSemantics();
  await Backend.instance.init();
  runApp(const MajlisApp());
}

class MajlisApp extends StatelessWidget {
  const MajlisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مجلس الخونة',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _Gate(),
    );
  }
}

/// أول مرة: يطلب من اللاعب يختار اسمه وصورته. بعدها: الرئيسية.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final backend = Backend.instance;
    if (!backend.isReady) return const HomeScreen();
    return ValueListenableBuilder(
      valueListenable: backend.profileLoaded,
      builder: (context, loaded, _) => !loaded
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : ValueListenableBuilder(
              valueListenable: backend.profile,
              builder: (context, p, _) => p.setupDone ? const HomeScreen() : const EditProfileScreen(firstTime: true),
            ),
    );
  }
}
