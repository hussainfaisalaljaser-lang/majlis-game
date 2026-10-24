import 'package:flutter/material.dart';

/// ألوان اللعبة. نفس الألوان المستخدمة في التصاميم الأولية.
abstract final class AppColors {
  static const bg = Color(0xFF0F1220);
  static const panel = Color(0xFF181C2E);
  static const card = Color(0xFF21263D);
  static const line = Color(0xFF2E3452);
  static const text = Color(0xFFEEF0F7);
  static const muted = Color(0xFF9097B3);
  static const loyal = Color(0xFF3B82F6);
  static const traitor = Color(0xFFEF4444);
  static const gold = Color(0xFFF5B942);
  static const green = Color(0xFF22C55E);
  static const diamond = Color(0xFF5EE0FF);
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Tajawal',
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.loyal,
      error: AppColors.traitor,
      surface: AppColors.panel,
    ),
    useMaterial3: true,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: const Color(0xFF1A1A1A),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: AppColors.line, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
