import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_controller.dart';
import 'wallet_controller.dart';
import 'tasks_controller.dart';
import 'leaderboard_controller.dart';
import 'gift_manager.dart';
import 'rocket_controller.dart';

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GiftController._internal() {
    debugPrint('Initializing: GiftController');
    _listenToFirestore();
  }

  void _listenToFirestore() {
    // Keep embedded gifts as fallback, load from Firestore for updates
    // Listen to gifts collection for catalog updates
    _firestore.collection('gifts').snapshots().listen((snapshot) {
      // Update local gifts list from Firestore when available
      if (snapshot.docs.isEmpty) {
        debugPrint('GIFT: Firestore gifts collection empty, using embedded asset gifts as fallback');
        safeNotify();
        return;
      }
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data == null) continue;
        
        final giftId = doc.id;
        final existingIndex = gifts.indexWhere((g) => g.id == giftId);
        
        final updatedGift = GiftItem(
          id: giftId,
          name: data['name']?.toString() ?? 'Unknown',
          price: (data['price'] as num?)?.toInt() ?? 0,
          category: data['category']?.toString() ?? 'شائعة',
          animated: data['animated'] as bool? ?? false,
          animationPath: data['animationPath']?.toString(),
          svgaPath: data['svgaPath']?.toString(),
          imagePath: data['imagePath']?.toString(),
          minLevel: (data['minLevel'] as num?)?.toInt() ?? 1,
        );
        
        if (existingIndex != -1) {
          gifts[existingIndex] = updatedGift;
        } else {
          gifts.add(updatedGift);
        }
        
        debugPrint('GIFT: Gift updated from Firestore: ${updatedGift.name} (Price: ${updatedGift.price})');
      }
      
      safeNotify();
    });
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

  static final Map<String, MovieEntity> _svgaCache = {};

  String getCleanPath(String path) {
    String clean = path.trim();
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
    // Cache most popular or all gifts
    for (var gift in gifts) {
      if (gift.svgaPath != null) {
        final formattedPath = getCleanPath(gift.svgaPath!);
        if (!_svgaCache.containsKey(formattedPath)) {
          try {
            final videoItem = await parser.decodeFromAssets(formattedPath);
            _svgaCache[formattedPath] = videoItem;
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

  final List<GiftItem> gifts = [
    // --- شائعة (Popular) ---
    const GiftItem(
      id: 'gift_asad_royal', 
      name: 'أسد الفخامة', 
      price: 15000, 
      svgaPath: 'assets/Asad/asad.svga', 
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

  int get walletDiamonds => _walletController.diamonds.value.toInt();
  int get currentLevel => _userController.currentLevel;

  bool isLocked(GiftItem item) {
    if (item.category == 'المطابخ / ارستقراطية' && _userController.vipLevel < item.minLevel) return true;
    return _userController.currentLevel < item.minLevel;
  }

  List<GiftItem> byCategory(String category) => gifts.where((e) => e.category == category).toList();

  Future<List<Map<String, dynamic>>> getAvailableGifts() async {
    // Return gifts as maps for the interaction widgets
    return gifts.map((gift) => {
      'id': gift.id,
      'name': gift.name,
      'price': gift.price,
      'category': gift.category,
      'animated': gift.animated,
      'imagePath': gift.imagePath,
      'svgaPath': gift.svgaPath,
      'minLevel': gift.minLevel,
    }).toList();
  }

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
  Map<String, dynamic> sendGift(GiftItem item, {int comboHits = 1, String? roomId, String? roomName, String? recipientId, String? recipientName}) {
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

    _leaderboardController.addGift(_userController.name, total, roomId: roomId);
    _tasksController.updateTaskProgress('send_gift', multiplier * targetSeats.length);
    
    // ROCKET BOOST SYSTEM: Contribute to rocket progress
    _rocketController.contributeDiamonds(total, roomId ?? '1205838', roomName ?? 'غرفة الدردشة');

    // Save gift history to Firestore
    _saveGiftToFirestore(item, total, roomId, roomName, recipientId, recipientName);

    // Update room dynamic points
    if (roomId != null) {
      _updateRoomPoints(roomId, total);
    }

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

  Future<void> _saveGiftToFirestore(GiftItem item, int totalCost, String? roomId, String? roomName, String? recipientId, String? recipientName) async {
    try {
      final userId = _userController.id;
      final giftHistoryRef = _firestore.collection('users').doc(userId).collection('gift_history');
      
      await giftHistoryRef.add({
        'giftId': item.id,
        'giftName': item.name,
        'giftPrice': item.price,
        'totalCost': totalCost,
        'multiplier': multiplier,
        'comboCount': comboCount,
        'targetSeats': targetSeats,
        'recipientId': recipientId,
        'recipientName': recipientName,
        'roomId': roomId,
        'roomName': roomName,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': userId,
        'senderName': _userController.name,
      });
    } catch (e) {
      debugPrint('Error saving gift to Firestore: $e');
    }
  }

  Future<void> _updateRoomPoints(String roomId, int points) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'dynamicPoints': FieldValue.increment(points),
        'lastActivity': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating room points: $e');
    }
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
}
