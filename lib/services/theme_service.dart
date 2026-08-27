import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:realtime_client/realtime_client.dart' show PostgresChangeEvent;
import '../services/supabase_service.dart';

/// Reads color customization from the `app_config` table and provides
/// a live [ThemeData] that updates whenever the admin dashboard saves new colors.
class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  bool _loaded = false;
  dynamic _subscription;

  // Current color values (fallback = original AppTheme defaults)
  String primaryBg = '#1A1A2E';
  String textPrimary = '#FFFFFF';
  String textSecondary = '#9BA1B6';
  String goldColor = '#B9F2FF';
  String buttonColor = '#6F4E37';
  String buttonTextColor = '#FFFFFF';
  String headerColor = '#1A1A2E';
  String tabBarColor = '#6F4E37';
  String cardColor = '#6F4E37';
  String accentColor = '#B9F2FF';

  // Screen title overrides
  Map<String, String> screenTitles = {};

  /// Load colors from Supabase `app_config` table.
  Future<void> loadColors() async {
    if (_loaded) return;
    try {
      final rows = await SupabaseService.client
          .from('app_config')
          .select('key, value');

      _applyRows(rows);
      _loaded = true;
      _startRealtimeSubscription();
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeService: Failed to load colors: $e');
      _loaded = true;
    }
  }

  void _applyRows(List<dynamic> rows) {
    for (final row in rows) {
      final key = row['key']?.toString() ?? '';
      final raw = row['value'];

      if (key == 'colorCustomize') {
        final map = _parseJson(raw);
        if (map.isNotEmpty) {
          primaryBg = map['primaryBg']?.toString() ?? primaryBg;
          textPrimary = map['textPrimary']?.toString() ?? textPrimary;
          textSecondary = map['textSecondary']?.toString() ?? textSecondary;
          goldColor = map['goldColor']?.toString() ?? goldColor;
          buttonColor = map['buttonColor']?.toString() ?? buttonColor;
          buttonTextColor = map['buttonTextColor']?.toString() ?? buttonTextColor;
          headerColor = map['headerColor']?.toString() ?? headerColor;
          tabBarColor = map['tabBarColor']?.toString() ?? tabBarColor;
          cardColor = map['cardColor']?.toString() ?? cardColor;
          accentColor = map['accentColor']?.toString() ?? accentColor;
        }
      }

      if (key == 'screenTitles') {
        final map = _parseJson(raw);
        screenTitles = map.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      }
    }
  }

  void _startRealtimeSubscription() {
    try {
      _subscription = SupabaseService.client
          .channel('app_config_theme')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'app_config',
            callback: (_) => _reloadFromDB(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('ThemeService: realtime subscribe failed: $e');
    }
  }

  Future<void> _reloadFromDB() async {
    try {
      final rows = await SupabaseService.client
          .from('app_config')
          .select('key, value');
      _applyRows(rows);
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeService: reload failed: $e');
    }
  }

  /// Force reload (e.g. after admin saves new colors).
  Future<void> reloadColors() async {
    _loaded = false;
    await loadColors();
  }

  Map<String, dynamic> _parseJson(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {}
      try {
        final decoded = json.decode(Uri.decodeComponent(raw));
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {}
    }
    return {};
  }

  /// Get a screen title override, or fallback to default.
  String getScreenTitle(String key, String fallback) {
    return screenTitles[key]?.isNotEmpty == true ? screenTitles[key]! : fallback;
  }

  /// Parse hex color string to Flutter Color.
  static Color hexToColor(String hex) {
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    try {
      return Color(int.parse('0x$h'));
    } catch (_) {
      return Colors.white;
    }
  }

  // --- Computed colors for quick access ---
  Color get primaryBgColor => hexToColor(primaryBg);
  Color get textPrimaryColor => hexToColor(textPrimary);
  Color get textSecondaryColor => hexToColor(textSecondary);
  Color get goldColorParsed => hexToColor(goldColor);
  Color get buttonColorParsed => hexToColor(buttonColor);
  Color get buttonTextColorParsed => hexToColor(buttonTextColor);
  Color get headerColorParsed => hexToColor(headerColor);
  Color get tabBarColorParsed => hexToColor(tabBarColor);
  Color get cardColorParsed => hexToColor(cardColor);
  Color get accentColorParsed => hexToColor(accentColor);

  /// Build a complete ThemeData from the loaded colors.
  ThemeData get theme {
    final bg = primaryBgColor;
    final card = cardColorParsed;
    final gold = goldColorParsed;
    final btn = buttonColorParsed;
    final btnText = buttonTextColorParsed;
    final headerBg = headerColorParsed;
    final tabBg = tabBarColorParsed;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: card,
      cardColor: card,
      canvasColor: card,
      colorScheme: ColorScheme.dark(
        primary: card,
        onPrimary: Colors.white,
        secondary: gold,
        onSecondary: Colors.black,
        surface: card,
        onSurface: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        tertiary: accentColorParsed,
        surfaceContainerHighest: bg,
        primaryContainer: Colors.green,
        secondaryContainer: Colors.orange,
        tertiaryContainer: Colors.blueAccent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: headerBg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimaryColor, fontSize: 14),
        bodyMedium: TextStyle(color: textPrimaryColor, fontSize: 14),
        bodySmall: TextStyle(color: textSecondaryColor, fontSize: 12),
        titleLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w700),
        titleSmall: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
        labelLarge: TextStyle(color: textPrimaryColor),
        labelMedium: TextStyle(color: textPrimaryColor),
        labelSmall: TextStyle(color: textSecondaryColor),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tabBg,
        selectedItemColor: gold,
        unselectedItemColor: Colors.white70,
        selectedIconTheme: IconThemeData(color: gold),
        unselectedIconTheme: const IconThemeData(color: Colors.white70),
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: btn,
          foregroundColor: btnText,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white, textColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(color: Colors.white12, thickness: 1),
      tabBarTheme: TabBarThemeData(
        labelColor: gold,
        unselectedLabelColor: Colors.white60,
        indicatorColor: gold,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: gold, width: 1),
        ),
      ),
    );
  }
}
