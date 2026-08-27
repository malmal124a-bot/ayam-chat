import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Unified Coffee & Purple Theme
  static const Color coffeeDark = Color(0xFF6F4E37);
  static const Color darkPurple = Color(0xFF4A148C);
  static const Color nearBlackPurple = Color(0xFF1A1A2E);
  static const Color diamondBlue = Color(0xFFB9F2FF);
  static const Color diamondBlueSoft = Color(0xFF70D1FF);

  // Mappings for consistency across the app
  static const Color background = darkPurple;
  static const Color surface = coffeeDark;
  
  // Legacy aliases mapped to the new unified colors to ensure compatibility
  static const Color toypurple = darkPurple;
  static const Color darkBrown = coffeeDark;
  static const Color warmSandBackground = darkPurple;
  static const Color card = coffeeDark;
  static const Color royalPurpleDark = darkPurple;
  static const Color royalPurple = darkPurple;
  static const Color royalPurpleLight = Color(0xFF7E57C2);

  // Semantic & VIP Colors (Master Control)
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.redAccent;
  static const Color info = Colors.blueAccent;
  
  static const Color vipGrey = Colors.grey;
  static const Color vipBlue = Colors.blue;
  static const Color vipLightBlue = Colors.lightBlueAccent;
  static const Color vipPurple = Colors.purple;
  static const Color vipDeepPurple = Colors.deepPurpleAccent;
  static const Color vipAmber = Colors.amber;
  static const Color vipOrange = Colors.orange;
  static const Color vipRed = Colors.red;
  static const Color vipDeepOrange = Colors.deepOrange;

  // Compatibility aliases (Diamonds/Gems themed)
  static const Color royalGold = diamondBlue;
  static const Color royalGoldSoft = diamondBlueSoft;

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkPurple,
        primaryColor: coffeeDark,
        cardColor: coffeeDark,
        canvasColor: coffeeDark,
        colorScheme: ColorScheme.dark(
          primary: coffeeDark,
          onPrimary: Colors.white,
          secondary: diamondBlue,
          onSecondary: Colors.black,
          surface: coffeeDark,
          onSurface: Colors.white,
          error: error,
          onError: Colors.white,
          tertiary: diamondBlueSoft,
          surfaceContainerHighest: nearBlackPurple,
          // Semantic Roles
          primaryContainer: success,
          secondaryContainer: warning,
          tertiaryContainer: info,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 14),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
          bodySmall: TextStyle(color: Colors.white, fontSize: 12),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: coffeeDark,
          selectedItemColor: diamondBlue,
          unselectedItemColor: Colors.white70,
          selectedIconTheme: IconThemeData(color: diamondBlue),
          unselectedIconTheme: IconThemeData(color: Colors.white70),
          type: BottomNavigationBarType.fixed,
          elevation: 10,
        ),
        cardTheme: CardThemeData(
          color: coffeeDark,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: coffeeDark,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Colors.white,
          textColor: Colors.white,
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.white12,
          thickness: 1,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: diamondBlue,
          unselectedLabelColor: Colors.white60,
          indicatorColor: diamondBlue,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: nearBlackPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: diamondBlue, width: 1),
          ),
        ),
      );
}
