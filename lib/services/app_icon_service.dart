import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:realtime_client/realtime_client.dart' show PostgresChangeEvent;
import '../services/supabase_service.dart';

/// Reads icon overrides from the `app_config` table (key: `iconOverrides`).
///
/// The admin dashboard (`AppIcons` page) saves a flat map of Flutter icon keys
/// to image URLs, e.g. `{ "Icons.home": "https://.../home.png" }`. This service
/// exposes those overrides so the whole app can live-update any icon into an
/// uploaded image without the user restarting the app.
class AppIconService extends ChangeNotifier {
  AppIconService._();
  static final AppIconService instance = AppIconService._();

  bool _loaded = false;
  dynamic _subscription;

  Map<String, String> _overrides = {};

  /// Current override map: icon key -> image URL.
  Map<String, String> get overrides => Map.unmodifiable(_overrides);

  /// Load icon overrides from Supabase `app_config`.
  Future<void> load() async {
    if (_loaded) return;
    try {
      final data = await SupabaseService.client
          .from('app_config')
          .select('value')
          .eq('key', 'iconOverrides')
          .maybeSingle();

      if (data != null) {
        _overrides = _parseMap(data['value']);
      }
      _loaded = true;
      _startRealtimeSubscription();
      notifyListeners();
    } catch (e) {
      debugPrint('AppIconService: Failed to load: $e');
      _loaded = true;
    }
  }

  void _startRealtimeSubscription() {
    try {
      _subscription = SupabaseService.client
          .channel('app_config_icons')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'app_config',
            callback: (_) => _reloadFromDB(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('AppIconService: realtime subscribe failed: $e');
    }
  }

  Future<void> _reloadFromDB() async {
    try {
      final data = await SupabaseService.client
          .from('app_config')
          .select('value')
          .eq('key', 'iconOverrides')
          .maybeSingle();
      if (data != null) {
        _overrides = _parseMap(data['value']);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AppIconService: reload failed: $e');
    }
  }

  /// Force reload (e.g. after admin saves new icon overrides).
  Future<void> reload() async {
    _loaded = false;
    await load();
  }

  /// Return the override URL for an icon key, or null if none is set.
  String? overrideFor(String key) {
    final url = _overrides[key]?.trim();
    return (url != null && url.isNotEmpty) ? url : null;
  }

  Map<String, String> _parseMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) {
      return raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
        }
      } catch (_) {}
      try {
        final decoded = json.decode(Uri.decodeComponent(raw));
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
        }
      } catch (_) {}
    }
    return {};
  }
}
