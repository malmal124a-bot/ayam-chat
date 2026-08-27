import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

/// Level configuration read from Supabase `level_config` table.
class LevelData {
  final int level;
  final String type; // wealth, recharge, gems
  final String title;
  final int minExp;
  final int maxExp;
  final String? imageUrl;
  final String? frameUrl;
  final String? badgeUrl;
  final String? progressColor;
  final String? boxImageUrl;
  final Map<String, dynamic> rewards;

  const LevelData({
    required this.level,
    required this.type,
    required this.title,
    required this.minExp,
    required this.maxExp,
    this.imageUrl,
    this.frameUrl,
    this.badgeUrl,
    this.progressColor,
    this.boxImageUrl,
    this.rewards = const {},
  });

  factory LevelData.fromMap(Map<String, dynamic> m) {
    return LevelData(
      level: m['level'] ?? 0,
      type: m['type'] ?? 'wealth',
      title: m['title'] ?? 'Level ${m['level']}',
      minExp: m['min_exp'] ?? 0,
      maxExp: m['max_exp'] ?? 0,
      imageUrl: m['image_url'],
      frameUrl: m['frame_url'],
      badgeUrl: m['badge_url'],
      progressColor: m['progress_color'],
      boxImageUrl: m['box_image_url'],
      rewards: m['rewards'] is Map ? Map<String, dynamic>.from(m['rewards']) : {},
    );
  }
}

/// Reads level configuration from Supabase `level_config` table.
class LevelService extends ChangeNotifier {
  LevelService._();
  static final LevelService instance = LevelService._();

  bool _loaded = false;
  Map<String, List<LevelData>> _levels = {};

  List<LevelData> get wealthLevels => _levels['wealth'] ?? [];
  List<LevelData> get rechargeLevels => _levels['recharge'] ?? [];
  List<LevelData> get gemsLevels => _levels['gems'] ?? [];

  List<LevelData> getLevelsByType(String type) => _levels[type] ?? [];

  /// Get the level data for a specific level number and type.
  LevelData? getLevel(String type, int level) {
    final list = _levels[type];
    if (list == null) return null;
    try {
      return list.firstWhere((l) => l.level == level);
    } catch (_) {
      return null;
    }
  }

  /// Find which level a given XP amount falls into for a type.
  LevelData? getLevelForXP(String type, int xp) {
    final list = _levels[type];
    if (list == null || list.isEmpty) return null;
    LevelData? current;
    for (final l in list) {
      if (xp >= l.minExp) {
        current = l;
      } else {
        break;
      }
    }
    return current;
  }

  /// Load levels from Supabase.
  Future<void> loadLevels() async {
    if (_loaded) return;
    try {
      final data = await SupabaseService.client
          .from('level_config')
          .select('*')
          .order('level');

      if (data.isEmpty) {
        _loaded = true;
        return;
      }

      final map = <String, List<LevelData>>{};
      for (final row in data) {
        final type = row['type']?.toString() ?? 'wealth';
        map.putIfAbsent(type, () => []).add(LevelData.fromMap(row));
      }
      _levels = map;
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('LevelService: Failed to load: $e');
      _loaded = true;
    }
  }

  Future<void> reloadLevels() async {
    _loaded = false;
    await loadLevels();
  }
}
