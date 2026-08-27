import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

/// Badge data read from Supabase `badges` table.
class BadgeData {
  final String id;
  final String name;
  final String nameAr;
  final String nameEn;
  final String description;
  final String descriptionAr;
  final String descriptionEn;
  final String? iconAsset;
  final String? imageUrl;
  final String? svgaUrl;
  final String? unlockCondition;
  final int sortOrder;
  final bool isActive;
  final String type; // admin, level
  final String? levelType;
  final int? levelNumber;

  const BadgeData({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.nameEn = '',
    this.description = '',
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.iconAsset,
    this.imageUrl,
    this.svgaUrl,
    this.unlockCondition,
    this.sortOrder = 0,
    this.isActive = true,
    this.type = '',
    this.levelType,
    this.levelNumber,
  });

  factory BadgeData.fromMap(Map<String, dynamic> m) {
    return BadgeData(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      nameAr: m['name_ar']?.toString() ?? '',
      nameEn: m['name_en']?.toString() ?? '',
      description: m['description']?.toString() ?? '',
      descriptionAr: m['description_ar']?.toString() ?? '',
      descriptionEn: m['description_en']?.toString() ?? '',
      iconAsset: m['icon_asset']?.toString(),
      imageUrl: m['image_url']?.toString(),
      svgaUrl: m['svga_url']?.toString(),
      unlockCondition: m['unlock_condition']?.toString(),
      sortOrder: m['sort_order'] ?? 0,
      isActive: m['is_active'] ?? true,
      type: m['type']?.toString() ?? '',
      levelType: m['level_type']?.toString(),
      levelNumber: m['level_number'],
    );
  }

  String get displayName => nameAr.isNotEmpty ? nameAr : (nameEn.isNotEmpty ? nameEn : name);
  String get displayDescription => descriptionAr.isNotEmpty ? descriptionAr : (descriptionEn.isNotEmpty ? descriptionEn : description);
}

/// Necklace data read from Supabase `necklaces` table.
class NecklaceData {
  final String id;
  final String name;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String? svgaUrl;
  final String? imageUrl;
  final int price;
  final int sortOrder;
  final bool isActive;
  final String type;
  final int requiredRechargeLevel;

  const NecklaceData({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.nameEn = '',
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.svgaUrl,
    this.imageUrl,
    this.price = 0,
    this.sortOrder = 0,
    this.isActive = true,
    this.type = '',
    this.requiredRechargeLevel = 0,
  });

  factory NecklaceData.fromMap(Map<String, dynamic> m) {
    return NecklaceData(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      nameAr: m['name_ar']?.toString() ?? '',
      nameEn: m['name_en']?.toString() ?? '',
      descriptionAr: m['description_ar']?.toString() ?? '',
      descriptionEn: m['description_en']?.toString() ?? '',
      svgaUrl: m['svga_url']?.toString(),
      imageUrl: m['image_url']?.toString(),
      price: m['price'] ?? 0,
      sortOrder: m['sort_order'] ?? 0,
      isActive: m['is_active'] ?? true,
      type: m['type']?.toString() ?? '',
      requiredRechargeLevel: m['required_recharge_level'] ?? 0,
    );
  }

  String get displayName => nameAr.isNotEmpty ? nameAr : (nameEn.isNotEmpty ? nameEn : name);
}

/// Reads badges from Supabase `badges` table.
class BadgeService extends ChangeNotifier {
  BadgeService._();
  static final BadgeService instance = BadgeService._();

  bool _loaded = false;
  List<BadgeData> _badges = [];

  List<BadgeData> get badges => _badges;
  List<BadgeData> get activeBadges => _badges.where((b) => b.isActive).toList();

  /// Get badges by type.
  List<BadgeData> getByType(String type) => _badges.where((b) => b.type == type && b.isActive).toList();

  /// Get badges for a specific level.
  List<BadgeData> getByLevel(String levelType, int level) =>
      _badges.where((b) => b.type == 'level' && b.levelType == levelType && b.levelNumber == level && b.isActive).toList();

  Future<void> loadBadges() async {
    if (_loaded) return;
    try {
      final response = await SupabaseService.client
          .from('badges')
          .select('*')
          .order('sort_order');

      if (response.isEmpty) {
        _loaded = true;
        return;
      }

      _badges = response.map<BadgeData>((row) => BadgeData.fromMap(row)).toList();
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('BadgeService: Failed to load: $e');
      _loaded = true;
    }
  }

  Future<void> reloadBadges() async {
    _loaded = false;
    await loadBadges();
  }
}

/// Reads necklaces from Supabase `necklaces` table.
class NecklaceService extends ChangeNotifier {
  NecklaceService._();
  static final NecklaceService instance = NecklaceService._();

  bool _loaded = false;
  List<NecklaceData> _necklaces = [];

  List<NecklaceData> get necklaces => _necklaces;
  List<NecklaceData> get activeNecklaces => _necklaces.where((n) => n.isActive).toList();

  Future<void> loadNecklaces() async {
    if (_loaded) return;
    try {
      final response = await SupabaseService.client
          .from('necklaces')
          .select('*')
          .order('sort_order');

      if (response.isEmpty) {
        _loaded = true;
        return;
      }

      _necklaces = response.map<NecklaceData>((row) => NecklaceData.fromMap(row)).toList();
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('NecklaceService: Failed to load: $e');
      _loaded = true;
    }
  }

  Future<void> reloadNecklaces() async {
    _loaded = false;
    await loadNecklaces();
  }
}
