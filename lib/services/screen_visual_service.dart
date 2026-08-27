import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:realtime_client/realtime_client.dart' show PostgresChangeEvent;
import '../services/supabase_service.dart';
import '../services/theme_service.dart';

/// Visual settings for a single screen section.
class ScreenVisual {
  final Color headerBgColor;
  final Color headerTextColor;
  final Color cardBgColor;
  final Color cardBorderColor;
  final Color textColor;
  final Color subTextColor;
  final Color accentColor;
  final String backgroundImage;
  final String headerBgImage;
  final String cardBgImage;
  final String lockImage;

  const ScreenVisual({
    this.headerBgColor = const Color(0xFF1A1A2E),
    this.headerTextColor = const Color(0xFFFFFFFF),
    this.cardBgColor = const Color(0xFF16213E),
    this.cardBorderColor = const Color(0xFF0F3460),
    this.textColor = const Color(0xFFFFFFFF),
    this.subTextColor = const Color(0xFFA0A0B0),
    this.accentColor = const Color(0xFFE94560),
    this.backgroundImage = '',
    this.headerBgImage = '',
    this.cardBgImage = '',
    this.lockImage = '',
  });

  static ScreenVisual fromMap(Map<String, dynamic> m) {
    return ScreenVisual(
      headerBgColor: _hex(m['headerBgColor'], '#1A1A2E'),
      headerTextColor: _hex(m['headerTextColor'], '#FFFFFF'),
      cardBgColor: _hex(m['cardBgColor'], '#16213E'),
      cardBorderColor: _hex(m['cardBorderColor'], '#0F3460'),
      textColor: _hex(m['textColor'], '#FFFFFF'),
      subTextColor: _hex(m['subTextColor'], '#A0A0B0'),
      accentColor: _hex(m['accentColor'], '#E94560'),
      backgroundImage: m['backgroundImage']?.toString() ?? '',
      headerBgImage: m['headerBgImage']?.toString() ?? '',
      cardBgImage: m['cardBgImage']?.toString() ?? '',
      lockImage: m['lockImage']?.toString() ?? '',
    );
  }

  static Color _hex(dynamic value, String fallback) {
    if (value == null || value.toString().isEmpty) {
      return ThemeService.hexToColor(fallback);
    }
    return ThemeService.hexToColor(value.toString());
  }
}

/// Reads per-screen visual customization from `app_config` (key: `screenCustomization`).
///
/// The admin dashboard saves a JSON object keyed by screen name:
/// { "agency": { "headerBgColor": "#...", ... }, "badges": { ... }, ... }
class ScreenVisualService extends ChangeNotifier {
  ScreenVisualService._();
  static final ScreenVisualService instance = ScreenVisualService._();

  bool _loaded = false;
  Map<String, ScreenVisual> _screens = {};

  /// Available screen keys matching the admin dashboard.
  static const List<String> screenKeys = [
    'agency', 'badges', 'necklaces', 'rank', 'store',
    'backpack', 'wallet', 'level', 'cp', 'signin',
    'profile', 'settings', 'rooms', 'gifts', 'chat',
  ];

  /// Default visuals for all screens.
  static final Map<String, ScreenVisual> _defaults = {
    for (final key in screenKeys) key: const ScreenVisual(),
  };

  ScreenVisual getScreen(String key) => _screens[key] ?? _defaults[key] ?? const ScreenVisual();

  /// Load screen visuals from Supabase `app_config` (key: `screenVisuals`).
  Future<void> loadVisuals() async {
    if (_loaded) return;
    try {
      final data = await SupabaseService.client
          .from('app_config')
          .select('value')
          .eq('key', 'screenVisuals')
          .maybeSingle();

      if (data != null) {
        final raw = data['value'];
        final map = _parseJson(raw);
        final result = <String, ScreenVisual>{};

        for (final key in screenKeys) {
          if (map.containsKey(key) && map[key] is Map) {
            result[key] = ScreenVisual.fromMap(
              Map<String, dynamic>.from(map[key]),
            );
          }
        }
        _screens = result;
      }

      _loaded = true;
      _startRealtimeSubscription();
      notifyListeners();
    } catch (e) {
      debugPrint('ScreenVisualService: Failed to load: $e');
      _loaded = true;
    }
  }

  void _startRealtimeSubscription() {
    try {
      SupabaseService.client
          .channel('app_config_visuals')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'app_config',
            callback: (_) => _reloadFromDB(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('ScreenVisualService: realtime subscribe failed: $e');
    }
  }

  Future<void> _reloadFromDB() async {
    try {
      final data = await SupabaseService.client
          .from('app_config')
          .select('value')
          .eq('key', 'screenVisuals')
          .maybeSingle();

      if (data != null) {
        final raw = data['value'];
        final map = _parseJson(raw);
        final result = <String, ScreenVisual>{};
        for (final key in screenKeys) {
          if (map.containsKey(key) && map[key] is Map) {
            result[key] = ScreenVisual.fromMap(
              Map<String, dynamic>.from(map[key]),
            );
          }
        }
        _screens = result;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('ScreenVisualService: reload failed: $e');
    }
  }

  /// Force reload.
  Future<void> reloadVisuals() async {
    _loaded = false;
    await loadVisuals();
  }

  Map<String, dynamic> _parseJson(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
      } catch (_) {}
      try {
        final decoded = json.decode(Uri.decodeComponent(raw));
        if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
      } catch (_) {}
    }
    return {};
  }
}
