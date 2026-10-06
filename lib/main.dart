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

        // Master PRD Design Tokens
        const royalBlue = Color(0xFF2563EB);
        const electricIndigo = Color(0xFF5B5FC7);
        const emeraldGreen = Color(0xFF10B981);
        const crimson = Color(0xFFEF4444);
        const softOffWhite = Color(0xFFF8FAFC);

        final baseTextTheme = GoogleFonts.poppinsTextTheme(
          isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
        );

        final themeData = ThemeData(
          useMaterial3: true,
          brightness: isDark ? Brightness.dark : Brightness.light,
          primaryColor: royalBlue,
          colorScheme: ColorScheme.fromSeed(
            seedColor: royalBlue,
            brightness: isDark ? Brightness.dark : Brightness.light,
            primary: royalBlue,
            secondary: electricIndigo,
            tertiary: emeraldGreen,
            error: crimson,
            surface: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
          scaffoldBackgroundColor: isDark ? const Color(0xFF0F172A) : softOffWhite,
          textTheme: appData.isHindi ? GoogleFonts.notoSansDevanagariTextTheme(baseTextTheme) : baseTextTheme,
          appBarTheme: AppBarTheme(
            backgroundColor: isDark ? const Color(0xFF1E293B) : royalBlue,
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
