import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // Brand & Palette from Reference UI (Plantland / Isometric Glassmorphic Style)
  static const Color brandTeal = Color(0xFF0C4D4A); // Deep Teal Header & Primary Buttons
  static const Color brandTealDark = Color(0xFF073836);
  static const Color brandTealLight = Color(0xFF14B8A6);
  static const Color mintBackground = Color(0xFFD2EBE6); // Pale Mint Page Background
  static const Color mintSoft = Color(0xFFE8F5F2);
  static const Color pillInputFill = Color(0xFFF2F6F5); // Crisp Rounded Pill Field Background

  // Light Theme Colors
  static const Color paperLight = Color(0xFFD2EBE6);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0C3332);
  static const Color inkPrimary = Color(0xFF0C3332);
  static const Color inkSecondary = Color(0xFF627D7B);
  static const Color line = Color(0xFFD0E3DF);

  // Dark Theme Colors (Isometric Glassmorphism from Image 2)
  static const Color paperDark = Color(0xFF0B141A); // Deep Night Space
  static const Color cardDark = Color(0xFF13222A);
  static const Color cardDarkElevated = Color(0xFF1A2E38);
  static const Color inkDark = Color(0xFFF1F7F6);
  static const Color inkSecondaryDark = Color(0xFF8AA5A2);
  static const Color lineDark = Color(0xFF223C47);

  // Brand Accents
  static const Color brandBlue = Color(0xFF0C4D4A); // Synced with brandTeal
  static const Color brandBlueLight = Color(0xFF14B8A6);
  static const Color brandBlueSoft = Color(0xFFE2F3EF);
  static const Color brandBlueSoftDark = Color(0xFF1A3836);
  static const Color accentYellow = Color(0xFFF59E0B);
  static const Color neonCyan = Color(0xFF2DD4BF); // Image 2 Isometric Glow

  // Status Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenSoft = Color(0xFFD1FAE5);
  static const Color successGreenDark = Color(0xFF059669);

  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningOrangeSoft = Color(0xFFFEF3C7);

  static const Color dangerRed = Color(0xFFE11D48);
  static const Color dangerRedSoft = Color(0xFFFFE4E6);
  static const Color dangerRedDark = Color(0xFFF43F5E);

  // Theme Controller / Notifier
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  static Future<void> initTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('app_is_dark_mode') ?? false;
      themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {}
  }

  static Future<void> toggleTheme() async {
    final nextMode = themeModeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeModeNotifier.value = nextMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_is_dark_mode', nextMode == ThemeMode.dark);
    } catch (_) {}
  }

  static bool get isDark => themeModeNotifier.value == ThemeMode.dark;

  // Light Theme (Clean Organic Mint + Deep Teal)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: paperLight,
    primaryColor: brandTeal,
    colorScheme: const ColorScheme.light(
      primary: brandTeal,
      secondary: accentYellow,
      surface: cardLight,
      error: dangerRed,
      onPrimary: Colors.white,
      onSurface: ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 2,
      shadowColor: brandTeal.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE1EFEA), width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: pillInputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Color(0xFFE2EBE9), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: brandTeal, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: dangerRed, width: 1.5),
      ),
      labelStyle: const TextStyle(color: inkSecondary, fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFF9EBCB7), fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );

  // Dark Theme (Futuristic Isometric Glassmorphic Slate from Image 2)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: paperDark,
    primaryColor: neonCyan,
    colorScheme: const ColorScheme.dark(
      primary: neonCyan,
      secondary: accentYellow,
      surface: cardDark,
      error: dangerRedDark,
      onPrimary: Colors.black,
      onSurface: inkDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: inkDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: inkDark,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 4,
      shadowColor: Colors.black.withAlpha(100),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: lineDark, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardDarkElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: lineDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: neonCyan, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: dangerRedDark, width: 1.5),
      ),
      labelStyle: const TextStyle(color: inkSecondaryDark, fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFF536D75), fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonCyan,
        foregroundColor: const Color(0xFF0A1319),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
  );
}
