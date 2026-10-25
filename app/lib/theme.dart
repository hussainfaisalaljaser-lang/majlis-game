import 'package:flutter/material.dart';

/// ألوان «ليالي المجلس»: ليل كحلي وبنفسجي، وذهب، وورق قديم.
abstract final class AppColors {
  static const bg = Color(0xFF120E24);
  static const panel = Color(0xFF1C1638);
  static const card = Color(0xFF241C46);
  static const line = Color(0xFF3B2F6B);
  static const text = Color(0xFFF5F1FF);
  static const muted = Color(0xFFA79FCB);

  static const loyal = Color(0xFF2F7CF6);
  static const loyalDark = Color(0xFF123E8F);
  static const loyalLight = Color(0xFF8FC1FF);
  static const traitor = Color(0xFFE0314B);
  static const traitorDark = Color(0xFF8E1328);
  static const traitorLight = Color(0xFFFF9AA8);

  static const gold = Color(0xFFF2C14E);
  static const goldLight = Color(0xFFFFE08A);
  static const goldDark = Color(0xFFB87A12);
  static const goldInk = Color(0xFF3A2400);

  static const parchment = Color(0xFFF6E7C8);
  static const parchmentDark = Color(0xFFE2C48E);
  static const ink = Color(0xFF3A230F);

  static const green = Color(0xFF2FBF71);
  static const diamond = Color(0xFF7DD8FF);
}

/// خط العناوين الكوفي.
const kufi = 'ReemKufi';

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
    textTheme: base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: kufi, fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.text),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.gold.withValues(alpha: .35), width: 1.5),
      ),
      titleTextStyle: const TextStyle(fontFamily: kufi, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.card,
      contentTextStyle: const TextStyle(fontFamily: 'Tajawal', color: AppColors.text, fontWeight: FontWeight.w700),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.gold.withValues(alpha: .4)),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: AppColors.gold,
      labelColor: AppColors.gold,
      unselectedLabelColor: AppColors.muted,
      labelStyle: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 15),
      dividerColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.goldInk,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: kufi, fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        backgroundColor: Colors.white.withValues(alpha: .05),
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: Colors.white.withValues(alpha: .15), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: kufi, fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.gold,
        textStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black.withValues(alpha: .25),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
    ),
  );
}
