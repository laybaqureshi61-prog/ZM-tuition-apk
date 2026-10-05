import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/app_data.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ZmApp());
}

class ZmApp extends StatelessWidget {
  const ZmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData();

    return ListenableBuilder(
      listenable: appData,
      builder: (context, _) {
        final isDark = appData.isDarkMode;

        // Modern Theme Palette
        const primaryColor = Color(0xFF4F46E5); // Indigo
        const successColor = Color(0xFF22C55E); // Green
        const dangerColor = Color(0xFFEF4444); // Red
        const warningColor = Color(0xFFEAB308); // Amber/Yellow

        final baseTextTheme = GoogleFonts.poppinsTextTheme(
          isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
        );

        final themeData = ThemeData(
          useMaterial3: true,
          brightness: isDark ? Brightness.dark : Brightness.light,
          primaryColor: primaryColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryColor,
            brightness: isDark ? Brightness.dark : Brightness.light,
            primary: primaryColor,
            secondary: successColor,
            error: dangerColor,
            surface: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
          scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          textTheme: appData.isHindi ? GoogleFonts.notoSansDevanagariTextTheme(baseTextTheme) : baseTextTheme,
          appBarTheme: AppBarTheme(
            backgroundColor: isDark ? const Color(0xFF1E293B) : primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
          ),
          cardColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        );

        return MaterialApp(
          title: 'ZM Tuition Management Portal',
          debugShowCheckedModeBanner: false,
          theme: themeData,
          home: const SplashScreen(),
        );
      },
    );
  }
}
