import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_item.dart';
import 'inventory_controller.dart';

class StoreController extends ChangeNotifier {
  static final StoreController _instance = StoreController._internal();
  factory StoreController() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StoreController._internal() {
    debugPrint('Initializing: StoreController');
    _listenToFirestore();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InventoryController().addListener(notifyListeners);
    });
  }

  void _listenToFirestore() {
    // STRICT FIRESTORE PERSISTENCE: Clear hardcoded items and load ONLY from Firestore
    _items.clear();
    
    // Listen to store_items collection for real-time catalog updates
    _firestore.collection('store_items').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        
        final itemId = change.doc.id;
        final existingIndex = _items.indexWhere((item) => item.id == itemId);
        
        if (change.type == DocumentChangeType.added || change.type ==DocumentChangeType.modified) {
          // Update or add item from Firestore - STRICT: Always use Firestore price
          final updatedItem = StoreItem(
            id: itemId,
            name: data['name']?.toString() ?? 'Unknown',
            imagePath: data['imagePath']?.toString() ?? '',
            price: (data['price'] ?? 0.0).toDouble(),
            type: _parseStoreItemType(data['type']?.toString()),
          );
          
          if (existingIndex != -1) {
            _items[existingIndex] = updatedItem;
          } else {
            _items.add(updatedItem);
          }
          
          debugPrint('STORE: Item updated from Firestore: ${updatedItem.name} (Price: ${updatedItem.price})');
        } else if (change.type == DocumentChangeType.removed) {
          // Remove item if deleted from Firestore
          if (existingIndex != -1) {
            _items.removeAt(existingIndex);
            debugPrint('STORE: Item removed from Firestore: $itemId');
          }
        }
      }
      
      notifyListeners();
    });
    
    // Listen to gifts collection for real-time updates
    _firestore.collection('gifts').snapshots().listen((snapshot) {
      debugPrint('STORE: Gifts collection updated (${snapshot.docs.length} gifts)');
      // Gift updates are handled by GiftController
    });
  }
  
  StoreItemType _parseStoreItemType(String? typeString) {
    if (typeString == null) return StoreItemType.frame;
    
    switch (typeString.toLowerCase()) {
      case 'frame':
        return StoreItemType.frame;
      case 'entrance_effect':
      case 'entrance':
      case 'entry':
        return StoreItemType.entryEffect;
      case 'fancy_id':
      case 'fancyid':
      case 'vanity_id':
        return StoreItemType.fancyId;
      default:
        return StoreItemType.frame;
    }
  }

  // exhaustive list of all available assets
  final List<StoreItem> _items = [
    // Frames - Restored FULL LIST from assets/vip and assets/store_assets
    StoreItem(id: 'frame_admin', name: 'إطار الإدارة', imagePath: 'assets/store_assets/admin_frame.webp.webp', price: 5000, type: StoreItemType.frame),
    StoreItem(id: 'frame_cggs', name: 'إطار سي جي', imagePath: 'assets/store_assets/cggs_frame.webp.webp', price: 3000, type: StoreItemType.frame),
    StoreItem(id: 'frame_dodo', name: 'إطار دودو', imagePath: 'assets/store_assets/dodo_frame.webp.webp', price: 2000, type: StoreItemType.frame),
    StoreItem(id: 'frame_vip1', name: 'إطار VIP 1', imagePath: 'assets/vip/vip1.png', price: 1000, type: StoreItemType.frame),
    StoreItem(id: 'frame_vip2', name: 'إطار VIP 2', imagePath: 'assets/vip/vip2.png', price: 2000, type: StoreItemType.frame),
    StoreItem(id: 'frame_vip3', name: 'إطار VIP 3', imagePath: 'assets/vip/vip3.png', price: 3000, type: StoreItemType.frame),
    StoreItem(id: 'frame_1', name: 'إطار ذهبي', imagePath: 'assets/vip/1.png', price: 1500, type: StoreItemType.frame),
    StoreItem(id: 'frame_2', name: 'إطار فضي', imagePath: 'assets/vip/2.png', price: 1200, type: StoreItemType.frame),
    StoreItem(id: 'frame_3', name: 'إطار برونزي', imagePath: 'assets/vip/3.png', price: 1000, type: StoreItemType.frame),
    StoreItem(id: 'frame_12', name: 'إطار سحري', imagePath: 'assets/vip/12.png', price: 2500, type: StoreItemType.frame),
    StoreItem(id: 'frame_29', name: 'إطار ملكي', imagePath: 'assets/vip/29.png', price: 5000, type: StoreItemType.frame),
    StoreItem(id: 'frame_37', name: 'إطار الفارس', imagePath: 'assets/vip/37.png', price: 4000, type: StoreItemType.frame),
    StoreItem(id: 'frame_38', name: 'إطار النبيل', imagePath: 'assets/vip/38.png', price: 4500, type: StoreItemType.frame),
    StoreItem(id: 'frame_13_1', name: 'إطار النجوم 1', imagePath: 'assets/vip/13 (1).png', price: 3500, type: StoreItemType.frame),
    StoreItem(id: 'frame_13_2', name: 'إطار النجوم 2', imagePath: 'assets/vip/13 (2).png', price: 3500, type: StoreItemType.frame),
    StoreItem(id: 'frame_27_1', name: 'إطار الياقوت 1', imagePath: 'assets/vip/27 (1).png', price: 6000, type: StoreItemType.frame),
    StoreItem(id: 'frame_27_2', name: 'إطار الياقوت 2', imagePath: 'assets/vip/27 (2).png', price: 6000, type: StoreItemType.frame),
    StoreItem(id: 'frame_28_1', name: 'إطار الزمرد 1', imagePath: 'assets/vip/28 (1).png', price: 7000, type: StoreItemType.frame),
    StoreItem(id: 'frame_28_2', name: 'إطار الزمرد 2', imagePath: 'assets/vip/28 (2).png', price: 7000, type: StoreItemType.frame),
    StoreItem(id: 'frame_39_1', name: 'إطار الألماس 1', imagePath: 'assets/vip/39 (1).png', price: 8000, type: StoreItemType.frame),
    StoreItem(id: 'frame_39_2', name: 'إطار الألماس 2', imagePath: 'assets/vip/39 (2).png', price: 8000, type: StoreItemType.frame),
    
    // Entry Effects
    StoreItem(id: 'entry_159', name: 'تأثير 159', imagePath: 'assets/entry_effects/#159_+e+µ++¦¼.png', price: 2500, type: StoreItemType.entryEffect),
    StoreItem(id: 'entry_426', name: 'تأثير 426', imagePath: 'assets/entry_effects/#426_+¦¦8+_¦¦.png', price: 4000, type: StoreItemType.entryEffect),
    StoreItem(id: 'entry_472', name: 'تأثير 472', imagePath: 'assets/entry_effects/#472_-·-f¦8-¦.png', price: 2000, type: StoreItemType.entryEffect),

    // Fancy IDs - Full Restored VIP List
    StoreItem(id: 'id_1', name: '1', imagePath: 'assets/Asad/vip_diamond.png', price: 1000000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_7', name: '7', imagePath: 'assets/Asad/vip_diamond.png', price: 500000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_007', name: '007', imagePath: 'assets/Asad/vip_diamond.png', price: 300000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_110', name: '110', imagePath: 'assets/Asad/vip_diamond.png', price: 100000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_111', name: '111', imagePath: 'assets/Asad/vip_diamond.png', price: 150000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_222', name: '222', imagePath: 'assets/Asad/vip_diamond.png', price: 120000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_333', name: '333', imagePath: 'assets/Asad/vip_diamond.png', price: 110000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_444', name: '444', imagePath: 'assets/Asad/vip_diamond.png', price: 100000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_555', name: '555', imagePath: 'assets/Asad/vip_diamond.png', price: 130000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_666', name: '666', imagePath: 'assets/Asad/vip_diamond.png', price: 140000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_777', name: '777', imagePath: 'assets/Asad/vip_diamond.png', price: 200000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_888', name: '888', imagePath: 'assets/Asad/vip_diamond.png', price: 250000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_999', name: '999', imagePath: 'assets/Asad/vip_diamond.png', price: 300000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_1111', name: '1111', imagePath: 'assets/Asad/vip_diamond.png', price: 50000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_2222', name: '2222', imagePath: 'assets/Asad/vip_diamond.png', price: 45000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_3333', name: '3333', imagePath: 'assets/Asad/vip_diamond.png', price: 40000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_king', name: 'KING', imagePath: 'assets/Asad/vip_diamond.png', price: 100000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_love', name: 'LOVE', imagePath: 'assets/Asad/vip_diamond.png', price: 80000, type: StoreItemType.fancyId),
    StoreItem(id: 'id_star', name: 'STAR', imagePath: 'assets/Asad/vip_diamond.png', price: 70000, type: StoreItemType.fancyId),
  ];

  List<StoreItem> get items => List.unmodifiable(_items);

  List<StoreItem> getItemsByType(StoreItemType type) {
    final inventory = InventoryController();
    return _items.where((item) {
      if (item.type != type) return false;
      // Filter out owned fancy IDs to keep the list fresh
      if (type == StoreItemType.fancyId && inventory.isOwned(item.id)) {
        return false;
      }
      return true;
    }).toList();
  }

  void purchaseItem(StoreItem item) {
    InventoryController().addItem(item.id);
    // Remove fancy ID from global list upon purchase
    if (item.type == StoreItemType.fancyId) {
      _items.removeWhere((i) => i.id == item.id);
    }
    notifyListeners();
  }

  void addItem(Map<String, dynamic> item) {
    _items.add(StoreItem(
      id: item['id']?.toString() ?? 'dynamic_${DateTime.now().millisecondsSinceEpoch}',
      name: item['name']?.toString() ?? 'New Item',
      imagePath: item['imagePath']?.toString() ?? '',
      price: (item['price'] ?? 0.0).toDouble(),
      type: item['type'] ?? StoreItemType.frame,
    ));
    notifyListeners();
  }
}
