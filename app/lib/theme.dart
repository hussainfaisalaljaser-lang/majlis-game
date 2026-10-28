import 'package:flutter/material.dart';

/// ألوان التصميم: خشب بني غامق، وذهب، ومخمل أحمر، ورق قديم.
abstract final class AppColors {
  static const bg = Color(0xFF1C110A);
  static const panel = Color(0xFF2A1A10);
  static const card = Color(0xFF3A2416);
  static const line = Color(0xFF6B4A2C);
  static const text = Color(0xFFFFF3DA);
  static const muted = Color(0xFFC8AE88);

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

/// خط العناوين والأزرار (Baloo Bhaijaan 2، مثل التصميم).
const kufi = 'Baloo';

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
      // بالعرض الارتفاع غالي، فالشريط اللي فوق أنحف.
      toolbarHeight: 46,
      titleTextStyle: TextStyle(
        fontFamily: kufi,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.goldLight,
        shadows: [Shadow(color: Color(0xFF2A1608), offset: Offset(0, 2), blurRadius: 2)],
      ),
      iconTheme: IconThemeData(color: AppColors.goldLight),
    ),
    dialogTheme: const DialogThemeData(
      // نوافذ مخمل أحمر بحد ذهبي، مثل التصميم.
      backgroundColor: Color(0xFF3E0F17),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
        side: BorderSide(color: Color(0xFFD9A84E), width: 2.5),
      ),
      titleTextStyle: TextStyle(
        fontFamily: kufi,
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: AppColors.goldLight,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF3B2414),
      contentTextStyle: TextStyle(fontFamily: 'Tajawal', color: AppColors.text, fontWeight: FontWeight.w700),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: Color(0xFFB98131), width: 1.5),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: AppColors.gold,
      labelColor: AppColors.gold,
      unselectedLabelColor: AppColors.muted,
      labelStyle: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 16),
      dividerColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFD6411F),
        foregroundColor: const Color(0xFFFFF8E8),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF4C0D04), width: 2),
        ),
        textStyle: const TextStyle(fontFamily: kufi, fontSize: 18, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        backgroundColor: const Color(0xFF2A1A10).withValues(alpha: .85),
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Color(0xFF8A6038), width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontFamily: kufi, fontSize: 16, fontWeight: FontWeight.w800),
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
      fillColor: const Color(0xFF140C07).withValues(alpha: .6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
    ),
  );
}
