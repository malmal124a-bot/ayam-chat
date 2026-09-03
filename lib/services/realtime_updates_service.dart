import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:realtime_client/realtime_client.dart' show PostgresChangeEvent;
import '../services/supabase_service.dart';
import '../services/theme_service.dart';
import '../services/screen_visual_service.dart';
import '../services/app_icon_service.dart';
import '../services/level_service.dart';
import '../services/badge_necklace_services.dart';

/// A live update pushed from the admin dashboard to every running client.
///
/// Every row in `app_broadcasts` is streamed through Supabase Realtime so a
/// change (announcement, config refresh, urgent notice) shows up instantly.
class RealtimeUpdate {
  final String id;
  final String type; // announcement | update | urgent | config | custom
  final String title;
  final String body;
  final String target;
  final Map<String, dynamic> payload;
  final bool isActive;
  final DateTime createdAt;

  const RealtimeUpdate({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.target,
    required this.payload,
    required this.isActive,
    required this.createdAt,
  });

  factory RealtimeUpdate.fromMap(Map<String, dynamic> m) {
    DateTime? created;
    final rawCreated = m['created_at'];
    if (rawCreated is DateTime) {
      created = rawCreated;
    } else if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated);
    }
    return RealtimeUpdate(
      id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: m['type']?.toString() ?? 'announcement',
      title: m['title']?.toString() ?? '',
      body: m['body']?.toString() ?? '',
      target: m['target']?.toString() ?? 'all',
      payload: _parseMap(m['payload']),
      isActive: m['is_active'] == true,
      createdAt: created ?? DateTime.now(),
    );
  }

  bool get isUrgent => type == 'urgent';

  static Map<String, dynamic> _parseMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
      } catch (_) {}
    }
    return {};
  }
}

/// Central service that watches the `app_broadcasts` table (and the reactive
/// config tables) and surfaces instant, in-app updates to every connected user.
///
/// - Shows a floating SnackBar for announcements / urgent notices.
/// - Automatically reloads theme / visuals / levels / badges / necklaces when
///   the admin changes config, so UI updates live without a reinstall.
class RealtimeUpdatesService extends ChangeNotifier {
  RealtimeUpdatesService._();
  static final RealtimeUpdatesService instance = RealtimeUpdatesService._();

  /// Set on [MaterialApp] so the messenger can be reached from anywhere.
  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final List<RealtimeUpdate> _history = [];
  RealtimeUpdate? _latest;
  dynamic _broadcastSub;
  dynamic _configSub;
  dynamic _storeSub;
  dynamic _roomsSub;
  bool _started = false;

  List<RealtimeUpdate> get history => List.unmodifiable(_history);
  RealtimeUpdate? get latest => _latest;

  /// Call once after [SupabaseService.initialize].
  void start() {
    if (_started) return;
    _started = true;
    _subscribeBroadcasts();
    _subscribeAppConfig();
    _subscribeStoreItems();
    _subscribeRooms();
    _fetchLatestBroadcast();
  }

  Future<void> _fetchLatestBroadcast() async {
    try {
      final data = await SupabaseService.client
          .from('app_broadcasts')
          .select('*')
          .order('created_at', ascending: false)
          .limit(1);
      if (data.isEmpty) return;
      _pushUpdate(RealtimeUpdate.fromMap(data.first), fromNetwork: false);
    } catch (e) {
      debugPrint('RealtimeUpdatesService: fetch latest failed: $e');
    }
  }

  void _subscribeBroadcasts() {
    try {
      _broadcastSub = SupabaseService.client
          .channel('realtime_updates')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'app_broadcasts',
            callback: (payload) {
              final record = payload.newRecord;
              if (record.isNotEmpty) {
                _pushUpdate(RealtimeUpdate.fromMap(record));
              } else {
                _fetchLatestBroadcast();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('RealtimeUpdatesService: broadcast subscribe failed: $e');
    }
  }

  void _subscribeAppConfig() {
    try {
      _configSub = SupabaseService.client
          .channel('realtime_updates_config')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'app_config',
            callback: (_) => _reloadReactiveConfig(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('RealtimeUpdatesService: app_config subscribe failed: $e');
    }
  }

  void _subscribeStoreItems() {
    try {
      _storeSub = SupabaseService.client
          .channel('realtime_updates_store')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'store_items',
            callback: (_) => _reloadReactiveConfig(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('RealtimeUpdatesService: store subscribe failed: $e');
    }
  }

  void _subscribeRooms() {
    try {
      _roomsSub = SupabaseService.client
          .channel('realtime_updates_rooms')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'rooms',
            callback: (_) => _reloadReactiveConfig(),
          )
          .subscribe();
    } catch (e) {
      debugPrint('RealtimeUpdatesService: rooms subscribe failed: $e');
    }
  }

  /// Reload every reactive, admin-driven service so the UI updates instantly.
  Future<void> _reloadReactiveConfig() async {
    try {
      await Future.wait([
        ThemeService.instance.reloadColors(),
        ScreenVisualService.instance.reloadVisuals(),
        AppIconService.instance.reload(),
        LevelService.instance.reloadLevels(),
        BadgeService.instance.reloadBadges(),
        NecklaceService.instance.reloadNecklaces(),
      ]);
      notifyListeners();
    } catch (e) {
      debugPrint('RealtimeUpdatesService: reload config failed: $e');
    }
  }

  void _pushUpdate(RealtimeUpdate update, {bool fromNetwork = true}) {
    // De-duplicate: ignore an identical latest record we already have.
    if (_latest != null &&
        _latest!.id == update.id &&
        _latest!.createdAt == update.createdAt) {
      return;
    }
    _latest = update;
    _history.insert(0, update);
    if (_history.length > 50) {
      _history.removeRange(50, _history.length);
    }
    notifyListeners();

    if (fromNetwork) {
      _showSnackBar(update);
    }
  }

  void _showSnackBar(RealtimeUpdate update) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    final title = update.title.isNotEmpty
        ? update.title
        : (update.type == 'urgent' ? 'إعلان عاجل' : 'إعلان جديد');
    final body = update.body.isNotEmpty ? update.body : '';

    final icon = update.type == 'urgent'
        ? Icons.notification_important
        : update.type == 'update'
            ? Icons.system_update_alt
            : Icons.campaign;

    messenger.showSnackBar(
      SnackBar(
        backgroundColor:
            update.type == 'urgent' ? const Color(0xFFB00020) : const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(icon, color: update.type == 'urgent' ? Colors.white : const Color(0xFFFFD700)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Manually clear the active update (e.g. user dismissed it).
  void dismissLatest() {
    _latest = null;
    notifyListeners();
  }
}
