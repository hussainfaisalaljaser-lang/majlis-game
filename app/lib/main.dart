import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'theme.dart';

void main() => runApp(const MajlisApp());

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
      home: const HomeScreen(),
    );
  }
}
