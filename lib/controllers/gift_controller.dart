import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'user_controller.dart';
import 'wallet_controller.dart';
import 'tasks_controller.dart';
import 'leaderboard_controller.dart';
import 'gift_manager.dart';
import 'rocket_controller.dart';
import '../utils/image_utils.dart';
import '../services/supabase_service.dart';
import '../services/svga_asset_service.dart';
class GiftItem {
  final String id;
  final String name;
  final int price;
  final String category;
  final bool animated;
  final String? animationPath;
  final String? svgaPath;
  final String? imagePath;
  final int minLevel;

  const GiftItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.animated = false,
    this.animationPath,
    this.svgaPath,
    this.imagePath,
    this.minLevel = 1,
  });
}

class GiftController extends ChangeNotifier {
  static final GiftController _instance = GiftController._internal();
  factory GiftController() => _instance;

  GiftController._internal() {
    debugPrint('Initializing: GiftController');
  }

  UserController get _userController => UserController();
  WalletController get _walletController => WalletController();
  TasksController get _tasksController => TasksController();
  LeaderboardController get _leaderboardController => LeaderboardController();
  RocketController get _rocketController => RocketController();

  int multiplier = 1;
  int comboCount = 0;
  List<int> targetSeats = [1];
  String targetName = 'مايك 1';
  double comboProgress = 0;
  
  Timer? _comboTimer;
  GiftItem? _lastTappedGift;
  GiftItem? get lastTappedGift => _lastTappedGift;

  bool _isDisposed = false;

  /// Categories fetched from `gift_categories` table, ordered by sort_order.
  /// Populated by CatalogService via setCategoriesFromDb().
  List<String> _dbCategories = [];

  static final Map<String, MovieEntity> _svgaCache = {};

  String getCleanPath(String path) {
    String clean = path.trim();
    if (ImageUtils.isHttpUrl(clean)) return clean;
    while (clean.startsWith('assets/assets/')) {
      clean = clean.replaceFirst('assets/assets/', 'assets/');
    }
    if (!clean.startsWith('assets/')) {
      clean = 'assets/$clean';
    }
    return clean;
  }
  
  /// Pre-caches SVGA assets for instant gift sheet opening and animation playback.
  Future<void> preCacheGifts() async {
    final parser = SVGAParser();
    for (var gift in gifts) {
      if (gift.svgaPath != null) {
        final resolved = await SvgaAssetService.instance.resolve(gift.svgaPath!);
        if (!_svgaCache.containsKey(resolved)) {
          try {
            final videoItem = ImageUtils.isHttpUrl(resolved)
                ? await parser.decodeFromURL(resolved)
                : await parser.decodeFromAssets(resolved);
            _svgaCache[resolved] = videoItem;
          } catch (e) {
            debugPrint('GiftController: Pre-cache failed for ${gift.name}: $e');
          }
        }
      }
    }
  }

  static MovieEntity? getCachedSvga(String path) => _svgaCache[_instance.getCleanPath(path)];

  @override
  void dispose() {
    _isDisposed = true;
    _comboTimer?.cancel();
    super.dispose();
  }

  void safeNotify() {
    if (_isDisposed) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  final List<int> multipliers = const [1, 7, 17, 77, 177, 777, 1777];

  final List<GiftItem> _gifts = [
    // --- شائعة (Popular) ---
    // svgaPath uses CDN URLs — resolved via SvgaAssetService
    const GiftItem(
      id: 'gift_asad_royal', 
      name: 'أسد الفخامة', 
      price: 15000, 
      svgaPath: 'assets/gifts/#2785_¦«---í-_.svga', 
      imagePath: 'assets/Asad/app_icon.jpeg', 
      category: 'شائعة', 
      animated: true
    ),
    const GiftItem(
      id: 'gift_1593', 
      name: 'وردة الحب', 
      price: 10, 
      svgaPath: 'assets/gifts/#1593_¦++¦-¦.svga', 
      imagePath: 'assets/gifts/#1593_¦++¦-¦.png',
      category: 'شائعة', 
      animated: true
    ),
    const GiftItem(
      id: 'gift_2461', 
      name: 'قلب ملكي', 
      price: 50, 
      svgaPath: 'assets/gifts/#2461_¦·+ñ-F.svga', 
      imagePath: 'assets/gifts/#2461_¦·+ñ-F.png',
      category: 'شائعة', 
      animated: true
    ),
    const GiftItem(
      id: 'gift_2487', 
      name: 'تاج العز', 
      price: 500, 
      svgaPath: 'assets/gifts/#2487_+-¦+-n¦S+f.svga', 
      imagePath: 'assets/gifts/#2487_+-¦+-n¦S+f.png',
      category: 'شائعة', 
      animated: true
    ),
    const GiftItem(
      id: 'gift_2495', 
      name: 'سيارة البرق', 
      price: 2000, 
      svgaPath: 'assets/gifts/#2495_++¦¼+±+=¦°.svga', 
      imagePath: 'assets/gifts/#2495_++¼+±+=¦°.png',
      category: 'شائعة', 
      animated: true
    ),
    const GiftItem(
      id: 'gift_2597', 
      name: 'قصر الأحلام', 
      price: 5000, 
      svgaPath: 'assets/gifts/#2597_+-¦G+«¦n.svga', 
      imagePath: 'assets/gifts/#2597_+-¦G+«¦n.png',
      category: 'شائعة', 
      animated: true
    ),
    
    // --- CP ---
    const GiftItem(
      id: 'cp_ring', 
      name: 'خاتم الأبدية', 
      price: 520, 
      svgaPath: 'assets/gifts/¦++ó.svga', 
      imagePath: 'assets/gifts/¦++ó.png',
      category: 'CP', 
      animated: true
    ),
    const GiftItem(
      id: 'cp_heart', 
      name: 'قلب المشاعر', 
      price: 1314, 
      svgaPath: 'assets/gifts/¦¦+G.svga', 
      imagePath: 'assets/gifts/¦¦+G.png',
      category: 'CP', 
      animated: true
    ),
    
    // --- الحظ (Luck) ---
    const GiftItem(
      id: 'luck_box', 
      name: 'صندوق المفاجآت', 
      price: 100, 
      svgaPath: 'assets/gifts/¦++--ª.svga', 
      imagePath: 'assets/gifts/¦++--ª.jpg',
      category: 'الحظ', 
      animated: true
    ),
    const GiftItem(
      id: 'luck_mystery', 
      name: 'الهدية الغامضة', 
      price: 500, 
      svgaPath: 'assets/gifts/¦-¦t+¦.svga', 
      imagePath: 'assets/gifts/¦-¦t+¦.png',
      category: 'الحظ', 
      animated: true
    ),
    const GiftItem(
      id: 'luck_star', 
      name: 'نجمة الحظ', 
      price: 1000, 
      svgaPath: 'assets/gifts/-¦¦«¦Ñ¦¦.svga', 
      category: 'الحظ', 
      animated: true
    ),

    // --- VIP / Aristocracy ---
    const GiftItem(
      id: 'gift_2785', 
      name: 'تنين النار', 
      price: 10000, 
      svgaPath: 'assets/gifts/#2785_¦«---í-_.svga', 
      imagePath: 'assets/gifts/#2785_¦«---í-_.png',
      category: 'المطابخ / ارستقراطية', 
      minLevel: 5, 
      animated: true
    ),
    const GiftItem(
      id: 'gift_2836', 
      name: 'سفينة الفضاء', 
      price: 25000, 
      svgaPath: 'assets/gifts/#2836_-+¦S¦8+¦¦s.svga', 
      imagePath: 'assets/gifts/#2836_-+¦S¦8+¦¦s.png',
      category: 'المطابخ / ارستقراطية', 
      minLevel: 10, 
      animated: true
    ),

    // --- الأعلام (Flags) ---
    const GiftItem(
      id: 'flag_global', 
      name: 'العلم العالمي', 
      price: 100, 
      svgaPath: 'assets/gifts/¦«--+O+S.svga', 
      category: 'الأعلام', 
      animated: true
    ),
  ];

  List<GiftItem> get gifts => List.unmodifiable(_gifts);

  /// Merges catalog gifts (managed from the admin dashboard, public.store_items)
  /// into the gift sheet. Remote gifts override local ones with the same id.
  void mergeCatalog(List<Map<String, dynamic>> rows) {
    var changed = false;
    for (final row in rows) {
      final type = row['item_type']?.toString();
      if (type != 'gift') continue;
      final id = row['id']?.toString();
      if (id == null || id.isEmpty) continue;

      final remote = GiftItem(
        id: id,
        name: row['name']?.toString() ?? 'هدية',
        price: (row['price'] ?? 0).toInt(),
        category: row['category']?.toString() ?? 'شائعة',
        animated: row['animated'] == true,
        svgaPath: row['svga_url']?.toString(),
        imagePath: row['image_url']?.toString(),
        minLevel: (row['min_level'] ?? 1).toInt(),
      );

      final index = _gifts.indexWhere((e) => e.id == id);
      if (index >= 0) {
        final old = _gifts[index];
        if (old.name != remote.name ||
            old.price != remote.price ||
            old.category != remote.category ||
            old.svgaPath != remote.svgaPath ||
            old.imagePath != remote.imagePath ||
            old.minLevel != remote.minLevel ||
            old.animated != remote.animated) {
          _gifts[index] = remote;
          changed = true;
        }
      } else {
        _gifts.add(remote);
        changed = true;
      }
    }
    if (changed) safeNotify();
  }

  /// Called by CatalogService with rows from `gift_categories` table.
  void setCategoriesFromDb(List<Map<String, dynamic>> rows) {
    _dbCategories = rows.map((r) => (r['name'] ?? '').toString()).where((n) => n.isNotEmpty).toList();
    safeNotify();
  }

  /// Ordered, de-duplicated list of gift categories (dashboard can add new ones).
  List<String> get categories {
    final seen = <String>[];
    for (final g in _gifts) {
      if (!seen.contains(g.category)) seen.add(g.category);
    }

    // If DB categories exist, use them as the primary ordered list.
    if (_dbCategories.isNotEmpty) {
      return [
        ..._dbCategories.where((c) => seen.contains(c)),
        ...seen.where((s) => !_dbCategories.contains(s)),
      ];
    }

    // Fallback: hardcoded base order.
    const base = ['شائعة', 'CP', 'الأعلام', 'الحظ', 'المطابخ / ارستقراطية', 'الغامض', 'نقاط'];
    return [
      ...base.where((b) => seen.contains(b)),
      ...seen.where((s) => !base.contains(s)),
    ];
  }

  int get walletDiamonds => _walletController.diamonds;
  int get currentLevel => _userController.currentLevel;

  bool isLocked(GiftItem item) {
    if (item.category == 'المطابخ / ارستقراطية' && _userController.vipLevel < item.minLevel) return true;
    return _userController.currentLevel < item.minLevel;
  }

  List<GiftItem> byCategory(String category) => gifts.where((e) => e.category == category).toList();

  void setMultiplier(int value) {
    multiplier = value;
    safeNotify();
  }

  void toggleTargetSeat(int seatIndex) {
    if (targetSeats.contains(seatIndex)) {
      if (targetSeats.length > 1) targetSeats.remove(seatIndex);
    } else {
      targetSeats.add(seatIndex);
    }
    targetName = targetSeats.length == 1 ? (targetSeats.first == 0 ? 'لي' : 'مايك ${targetSeats.first}') : 'متعدد (${targetSeats.length})';
    safeNotify();
  }

  void setAllTargets(List<int> seats) {
    targetSeats = List.from(seats);
    targetName = 'الكل';
    safeNotify();
  }

  void setTargetSeat(int value) {
    targetSeats = [value];
    targetName = value == 0 ? 'لي' : 'مايك $value';
    safeNotify();
  }

  int totalPrice(GiftItem item, {int comboHits = 1}) => item.price * multiplier * comboHits * targetSeats.length;

  /// Sends a gift, updates all stats instantly, and broadcasts events.
  /// NOTE: UI triggers the visual animation using context and GiftManager.
  Future<Map<String, dynamic>> sendGift(GiftItem item, {int comboHits = 1, String? roomId, String? roomName, String? roomPhoto, String? agencyName, String? agencyPhoto, String? receiverId, String? receiverName}) async {
    if (isLocked(item)) {
      return {'ok': false, 'message': 'المستوى أو الرتبة غير كافية'};
    }

    final total = totalPrice(item, comboHits: 1); 
    if (!_walletController.spendDiamonds(total)) {
      return {'ok': false, 'message': 'الرصيد غير كافٍ'};
    }
    
    // REAL-TIME UPDATES: Link transaction to stats immediately
    final xpGained = total ~/ 10;
    _userController.addXP(xpGained);
    _userController.addGlobalScore(total); 

    _leaderboardController.addGift(_userController.name, total, roomId: roomId, avatarUrl: _userController.profilePic, roomName: roomName, roomPhoto: roomPhoto, agencyName: agencyName, agencyPhoto: agencyPhoto);
    _tasksController.updateTaskProgress('send_gift', multiplier * targetSeats.length);

    // Persist gift to sent_gifts table
    try {
      final actualReceiverId = receiverId ?? SupabaseService.currentUserId ?? '';
      await SupabaseService.client.from('sent_gifts').insert({
        'gift_id': item.id,
        'gift_name': item.name,
        'sender_id': SupabaseService.currentUserId ?? '',
        'sender_name': _userController.name,
        'sender_photo_url': _userController.profilePic,
        'receiver_id': actualReceiverId,
        'room_id': roomId ?? '',
        'value': total.toDouble(),
        'count': multiplier * targetSeats.length,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // AGENCY EARNINGS: A hosting-agency member's OWN gift-sends (including
      // gifts sent to themselves) count toward their earnings/level. We credit
      // the SENDER's hosting membership, not the receiver's.
      final senderUid = SupabaseService.currentUserId ?? '';
      if (senderUid.isNotEmpty) {
        _processAgencyCommission(senderUid, total);
      }
    } catch (e) {
      debugPrint('GiftController: error persisting gift: $e');
    }
    
    // ROCKET BOOST SYSTEM: Contribute to rocket progress
    _rocketController.contributeDiamonds(total, roomId ?? '1205838', roomName ?? 'غرفة الدردشة');

    // Check for Lucky Gift Win simulation
    if (item.category == 'الحظ') {
      if (DateTime.now().millisecond % 4 == 0) {
        final luckyMulti = [10, 50, 100, 500][DateTime.now().millisecond % 4];
        GiftManager().broadcastLuckyGiftWin(
          userName: _userController.name,
          giftName: item.name,
          multiplier: luckyMulti.toString(),
          roomId: roomId ?? '1205838',
        );
      }
    }

    safeNotify();
    return {'ok': true, 'message': 'تم إرسال ${item.name} بنجاح'};
  }

  void tapCombo(GiftItem? item) {
    if (item == null || isLocked(item)) return;
    
    if (_lastTappedGift?.id != item.id) {
      resetCombo();
      _lastTappedGift = item;
    }

    comboCount += 1;
    comboProgress = 1.0;
    
    _comboTimer?.cancel();
    _comboTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      comboProgress -= 0.0167;
      if (comboProgress <= 0) {
        timer.cancel();
        resetCombo();
      } else {
        safeNotify();
      }
    });
    
    safeNotify();
  }

  void resetCombo() {
    _comboTimer?.cancel();
    comboCount = 0;
    comboProgress = 0;
    safeNotify();
  }

  void clearAnimation() {
    GiftManager().clearAnimation();
    safeNotify();
  }

  /// Credits the SENDER's hosting-agency membership with gift-send earnings.
  /// Includes gifts the host sends to themselves. Also refreshes level/target
  /// and refreshes the hosting agency screen.
  Future<void> _processAgencyCommission(String memberUserId, int giftValue) async {
    try {
      // 1. Find which hosting agency the sender belongs to
      final membership = await SupabaseService.client
          .from('host_agency_members')
          .select('agency_id, user_id')
          .eq('user_id', memberUserId)
          .eq('status', 'active')
          .maybeSingle();
      if (membership == null) return;

      final agencyId = membership['agency_id'] as String;

      // 2. Get commission settings - per-agency first, fallback to global
      double giftEntryPercent = 100.0;
      try {
        final settings = await SupabaseService.client
            .from('agency_commission_settings')
            .select('*')
            .eq('agency_id', agencyId)
            .maybeSingle();
        if (settings != null) {
          giftEntryPercent = (settings['gift_entry_percent'] as num?)?.toDouble() ?? 100.0;
        } else {
          final globalSettings = await SupabaseService.client
              .from('commission_settings')
              .select('*')
              .inFilter('key', ['gift_entry_percent']);
          for (final gs in globalSettings) {
            if (gs['key'] == 'gift_entry_percent') {
              giftEntryPercent = (gs['value'] as num?)?.toDouble() ?? 100.0;
            }
          }
        }
      } catch (_) {}

      // 3. Host earnings from this gift (sender gets the full entry percent)
      final hostEarnings = (giftValue * giftEntryPercent / 100).toInt();

      // 4. Add earnings to the sender's host member record
      if (hostEarnings > 0) {
        try {
          final member = await SupabaseService.client
              .from('host_agency_members')
              .select('diamonds_earned_cumulative, diamonds_earned_monthly, diamonds_balance')
              .eq('agency_id', agencyId)
              .eq('user_id', memberUserId)
              .maybeSingle();
          if (member != null) {
            final newCumulative = (member['diamonds_earned_cumulative'] ?? 0) + hostEarnings;
            final newBalance = (member['diamonds_balance'] ?? 0) + hostEarnings;
            await SupabaseService.client.from('host_agency_members').update({
              'diamonds_earned_cumulative': newCumulative,
              'diamonds_earned_monthly': (member['diamonds_earned_monthly'] ?? 0) + hostEarnings,
              'diamonds_balance': newBalance,
            }).eq('agency_id', agencyId).eq('user_id', memberUserId);

            // Recompute level/target based on cumulative earnings.
            await _recomputeHostLevel(agencyId, memberUserId, newCumulative);
          }
        } catch (_) {}
      }

      debugPrint('Host agency earnings credited: agency=$agencyId, member=$memberUserId, earnings=$hostEarnings');
    } catch (e) {
      debugPrint('Error processing agency earnings: $e');
    }
  }

  /// Recomputes a host member's level/target from host_profit_levels based on
  /// their cumulative earnings (level stored as numeric sort_order, matching
  /// the backend resolveLevel behaviour).
  Future<void> _recomputeHostLevel(String agencyId, String memberUserId, int cumulative) async {
    try {
      // Load all profit levels ordered by sort_order.
      final levels = await SupabaseService.client
          .from('host_profit_levels')
          .select('*')
          .order('sort_order');
      int lvl = 0;
      int target = 5000;
      String? periodType = 'weekly';
      for (final l in levels) {
        final min = (l['min_cumulative_coins'] as num?)?.toInt() ?? 0;
        if (cumulative >= min) {
          lvl = (l['sort_order'] as num?)?.toInt() ?? (lvl + 1);
          target = (l['target'] as num?)?.toInt() ?? 5000;
          periodType = (l['period_type'] as String?) ?? 'weekly';
        }
      }

      // Period start/end.
      String? periodStart, periodEnd;
      final now = DateTime.now();
      if (periodType == 'monthly') {
        periodStart = DateTime(now.year, now.month, 1).toIso8601String();
        periodEnd = DateTime(now.year, now.month + 1, 0).toIso8601String();
      } else if (periodType == 'weekly') {
        final monday = now.subtract(Duration(days: now.weekday - 1));
        periodStart = DateTime(monday.year, monday.month, monday.day).toIso8601String();
        periodEnd = monday.add(const Duration(days: 7)).toIso8601String();
      }

      await SupabaseService.client.from('host_agency_members').update({
        'level': lvl,
        'target': target,
        'period_type': periodType,
        'period_start': periodStart,
        'period_end': periodEnd,
      }).eq('agency_id', agencyId).eq('user_id', memberUserId);
    } catch (_) {}
  }
}
