import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/screen_visual_service.dart';

/// App theme — all brand colors are dynamic getters that read from
/// ThemeService at runtime.  Screens that use AppTheme.royalGold,
/// AppTheme.nearBlackPurple, etc. will automatically reflect admin
/// dashboard color changes without any code modification.
class AppTheme {
  // ── Fallback defaults (used when ThemeService is not yet loaded) ──
  static const Color _fallbackCard     = Color(0xFF6F4E37);
  static const Color _fallbackBg       = Color(0xFF1A1A2E);
  static const Color _fallbackGold     = Color(0xFFB9F2FF);
  static const Color _fallbackGoldSoft = Color(0xFF70D1FF);
  static const Color _fallbackAccent   = Color(0xFFB9F2FF);

  // ── Brand Colors (now dynamic from admin dashboard) ──
  static Color get coffeeDark      => ThemeService.instance.cardColorParsed;
  static Color get darkPurple      => ThemeService.instance.primaryBgColor;
  static Color get nearBlackPurple => ThemeService.instance.primaryBgColor;
  static Color get diamondBlue     => ThemeService.instance.goldColorParsed;
  static Color get diamondBlueSoft => ThemeService.instance.accentColorParsed;

  // ── Mappings (most-used aliases) ──
  static Color get background         => ThemeService.instance.primaryBgColor;
  static Color get surface            => ThemeService.instance.cardColorParsed;
  static Color get toypurple          => ThemeService.instance.primaryBgColor;
  static Color get darkBrown          => ThemeService.instance.cardColorParsed;
  static Color get warmSandBackground => ThemeService.instance.primaryBgColor;
  static Color get card               => ThemeService.instance.cardColorParsed;
  static Color get royalPurpleDark    => ThemeService.instance.primaryBgColor;
  static Color get royalPurple        => ThemeService.instance.primaryBgColor;
  static Color get royalPurpleLight   => const Color(0xFF7E57C2);

  // ── Semantic (stay constant — not themed) ──
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error   = Colors.redAccent;
  static const Color info    = Colors.blueAccent;

  // ── VIP tier colors (stay constant) ──
  static const Color vipGrey       = Colors.grey;
  static const Color vipBlue       = Colors.blue;
  static const Color vipLightBlue  = Colors.lightBlueAccent;
  static const Color vipPurple     = Colors.purple;
  static Color get   vipDeepPurple => Colors.deepPurpleAccent;
  static const Color vipAmber      = Colors.amber;
  static const Color vipOrange     = Colors.orange;
  static const Color vipRed        = Colors.red;
  static const Color vipDeepOrange = Colors.deepOrange;

  // ── Gold aliases (dynamic) ──
  static Color get royalGold     => ThemeService.instance.goldColorParsed;
  static Color get royalGoldSoft => ThemeService.instance.accentColorParsed;

  // ── Shortcuts (new — preferred for new code) ──
  static Color get dynBackground  => ThemeService.instance.primaryBgColor;
  static Color get dynCard        => ThemeService.instance.cardColorParsed;
  static Color get dynGold        => ThemeService.instance.goldColorParsed;
  static Color get dynButton      => ThemeService.instance.buttonColorParsed;
  static Color get dynButtonText  => ThemeService.instance.buttonTextColorParsed;
  static Color get dynHeader      => ThemeService.instance.headerColorParsed;
  static Color get dynTabBar      => ThemeService.instance.tabBarColorParsed;
  static Color get dynAccent      => ThemeService.instance.accentColorParsed;
  static Color get dynTextPrimary => ThemeService.instance.textPrimaryColor;
  static Color get dynTextSecondary => ThemeService.instance.textSecondaryColor;

  /// Get a screen title from ThemeService, or fallback to default.
  static String screenTitle(String key, String fallback) =>
      ThemeService.instance.getScreenTitle(key, fallback);

  /// Get the ScreenVisual for a given screen key.
  static ScreenVisual screenVisual(String key) =>
      ScreenVisualService.instance.getScreen(key);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ThemeService.instance.primaryBgColor,
        primaryColor: ThemeService.instance.cardColorParsed,
        cardColor: ThemeService.instance.cardColorParsed,
        canvasColor: ThemeService.instance.cardColorParsed,
        colorScheme: ColorScheme.dark(
          primary: ThemeService.instance.cardColorParsed,
          onPrimary: Colors.white,
          secondary: ThemeService.instance.goldColorParsed,
          onSecondary: Colors.black,
          surface: ThemeService.instance.cardColorParsed,
          onSurface: Colors.white,
          error: error,
          onError: Colors.white,
          tertiary: ThemeService.instance.accentColorParsed,
          surfaceContainerHighest: ThemeService.instance.primaryBgColor,
          primaryContainer: success,
          secondaryContainer: warning,
          tertiaryContainer: info,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: ThemeService.instance.headerColorParsed,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: ThemeService.instance.textPrimaryColor, fontSize: 14),
          bodyMedium: TextStyle(color: ThemeService.instance.textPrimaryColor, fontSize: 14),
          bodySmall: TextStyle(color: ThemeService.instance.textSecondaryColor, fontSize: 12),
          titleLarge: TextStyle(color: ThemeService.instance.textPrimaryColor, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: ThemeService.instance.textPrimaryColor, fontWeight: FontWeight.w700),
          titleSmall: TextStyle(color: ThemeService.instance.textPrimaryColor, fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(color: ThemeService.instance.textPrimaryColor, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: ThemeService.instance.textPrimaryColor, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: ThemeService.instance.textPrimaryColor, fontWeight: FontWeight.bold),
          labelLarge: TextStyle(color: ThemeService.instance.textPrimaryColor),
          labelMedium: TextStyle(color: ThemeService.instance.textPrimaryColor),
          labelSmall: TextStyle(color: ThemeService.instance.textSecondaryColor),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: ThemeService.instance.tabBarColorParsed,
          selectedItemColor: ThemeService.instance.goldColorParsed,
          unselectedItemColor: Colors.white70,
          selectedIconTheme: IconThemeData(color: ThemeService.instance.goldColorParsed),
          unselectedIconTheme: const IconThemeData(color: Colors.white70),
          type: BottomNavigationBarType.fixed,
          elevation: 10,
        ),
        cardTheme: CardThemeData(
          color: ThemeService.instance.cardColorParsed,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeService.instance.buttonColorParsed,
            foregroundColor: ThemeService.instance.buttonTextColorParsed,
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
        tabBarTheme: TabBarThemeData(
          labelColor: ThemeService.instance.goldColorParsed,
          unselectedLabelColor: Colors.white60,
          indicatorColor: ThemeService.instance.goldColorParsed,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: ThemeService.instance.primaryBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: ThemeService.instance.goldColorParsed, width: 1),
          ),
        ),
      );
}
