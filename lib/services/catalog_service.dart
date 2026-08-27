import 'package:flutter/foundation.dart';
import '../controllers/gift_controller.dart';
import '../controllers/store_controller.dart';
import '../models/store_item.dart';
import 'supabase_service.dart';

/// Bridges the admin dashboard catalog (public.store_items) into the app.
///
/// The dashboard (admincore-dashboard) manages gifts, frames, entry effects
/// and fancy IDs in the `store_items` table (assets uploaded to Cloudinary).
/// This service fetches those rows so everything added in the dashboard
/// shows up in the app store/gift sheet automatically.
class CatalogService {
  CatalogService._();

  static Future<List<Map<String, dynamic>>> fetchStoreItems({bool includeInactive = false}) async {
    var query = SupabaseService.client.from('store_items').select();
    if (!includeInactive) query = query.eq('is_active', true);
    final rows = await query.order('order');
    return rows;
  }

  /// Merges catalog rows into [StoreController] (frames / entry effects / fancy IDs).
  static Future<void> refreshStore() async {
    try {
      final rows = await fetchStoreItems();
      StoreController().mergeCatalog(rows);
    } catch (e) {
      debugPrint('CatalogService: refreshStore failed: $e');
    }
  }

  /// Merges catalog rows into [GiftController] (animated gifts).
  static Future<void> refreshGifts() async {
    try {
      final rows = await SupabaseService.client
          .from('store_items')
          .select()
          .eq('item_type', 'gift')
          .eq('is_active', true)
          .order('order');
      GiftController().mergeCatalog(rows);
    } catch (e) {
      debugPrint('CatalogService: refreshGifts failed: $e');
    }
    // Fetch category definitions from the gift_categories table so the app
    // reflects the dashboard's category names, ordering and any new additions.
    try {
      final catRows = await SupabaseService.client
          .from('gift_categories')
          .select('id,name,sort_order')
          .order('sort_order');
      GiftController().setCategoriesFromDb(catRows);
    } catch (e) {
      debugPrint('CatalogService: refreshGifts categories fetch failed: $e');
    }
  }

  static Future<void> refreshAll() async {
    await Future.wait([refreshStore(), refreshGifts()]);
  }

  static StoreItemType storeTypeFrom(String? raw) {
    switch (raw) {
      case 'entryEffect':
      case 'entry':
        return StoreItemType.entryEffect;
      case 'fancyId':
        return StoreItemType.fancyId;
      case 'frame':
        return StoreItemType.frame;
      default:
        return StoreItemType.frame;
    }
  }
}
