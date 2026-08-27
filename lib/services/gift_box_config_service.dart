import 'package:flutter/material.dart';
import 'supabase_service.dart';

/// Visual configuration of the gift sheet (صندوق الهدايا) managed from the
/// admin dashboard (admincore-dashboard) via the `app_config` key-value table.
///
/// Defaults match the previous hardcoded UI, so the app looks unchanged until
/// the admin edits the values from the dashboard.
class GiftBoxConfig {
  final Color boxBgColor;
  final double boxRadius;
  final String? boxBgImage;
  final Color tileBgColor;
  final Color tileSelectedColor;
  final double tileRadius;
  final String? tileBgImage;
  final Color tileBorderColor;
  final Color tileSelectedBorderColor;

  const GiftBoxConfig({
    this.boxBgColor = const Color(0xFF0F172A),
    this.boxRadius = 32,
    this.boxBgImage,
    this.tileBgColor = const Color(0x05FFFFFF),
    this.tileSelectedColor = const Color(0x1AFFC107),
    this.tileRadius = 16,
    this.tileBgImage,
    this.tileBorderColor = const Color(0x1AFFFFFF),
    this.tileSelectedBorderColor = const Color(0xFFFFC107),
  });

  bool get hasBoxBgImage => boxBgImage != null && boxBgImage!.isNotEmpty;
  bool get hasTileBgImage => tileBgImage != null && tileBgImage!.isNotEmpty;
}

class GiftBoxConfigService {
  GiftBoxConfigService._();

  static GiftBoxConfig _current = const GiftBoxConfig();

  static GiftBoxConfig get current => _current;

  /// Fetches the gift-box keys from `app_config` and caches them.
  /// Falls back to defaults if the table is unreachable.
  static Future<void> refresh() async {
    try {
      final rows = await SupabaseService.client.from('app_config').select('*');
      final map = <String, dynamic>{};
      for (final row in rows) {
        final key = row['key']?.toString();
        if (key == null || key.isEmpty) continue;
        map[key] = row['value'];
      }
      _current = GiftBoxConfig(
        boxBgColor: _parseColor(map['giftBoxBgColor'], const Color(0xFF0F172A)),
        boxRadius: _parseDouble(map['giftBoxRadius'], 32),
        boxBgImage: _parseString(map['giftBoxBgImage']),
        tileBgColor: _parseColor(map['giftTileBgColor'], const Color(0x05FFFFFF)),
        tileSelectedColor: _parseColor(map['giftTileSelectedColor'], const Color(0x1AFFC107)),
        tileRadius: _parseDouble(map['giftTileRadius'], 16),
        tileBgImage: _parseString(map['giftTileBgImage']),
        tileBorderColor: _parseColor(map['giftTileBorderColor'], const Color(0x1AFFFFFF)),
        tileSelectedBorderColor: _parseColor(map['giftTileSelectedBorderColor'], const Color(0xFFFFC107)),
      );
    } catch (e) {
      debugPrint('GiftBoxConfigService: refresh failed: $e');
    }
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double _parseDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    final n = double.tryParse(value.toString().trim());
    return n ?? fallback;
  }

  static Color _parseColor(dynamic value, Color fallback) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return fallback;
    final hex = raw.startsWith('#') ? raw.substring(1) : raw;
    if (hex.length == 6) {
      final rgb = int.tryParse(hex, radix: 16);
      if (rgb != null) return Color(0xFF000000 | rgb);
      return fallback;
    }
    if (hex.length == 8) {
      final argb = int.tryParse(hex, radix: 16);
      if (argb != null) return Color(argb);
      return fallback;
    }
    return fallback;
  }
}
