import 'package:flutter/foundation.dart';
import 'package:ayam_chat/controllers/wallet_controller.dart';
import 'package:ayam_chat/controllers/store_controller.dart';
import 'package:ayam_chat/controllers/room_ui_controller.dart';
import 'package:ayam_chat/models/store_item.dart';

class AdminController extends ChangeNotifier {
  static final AdminController _instance = AdminController._internal();
  factory AdminController() => _instance;
  
  AdminController._internal() {
    debugPrint('Initializing: AdminController');
  }

  // Use lazy getters to avoid circular initialization issues
  WalletController get _walletController => WalletController();
  StoreController get _storeController => StoreController();
  RoomUiController get _roomController => RoomUiController();

  void adjustBalance(double amount) {
    _walletController.addBalance(amount);
  }

  void addFrame({required String name, required String assetPath, required double price}) {
    _storeController.addItem({
      'id': 'dynamic_frame_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'imagePath': assetPath,
      'price': price,
      'type': StoreItemType.frame,
    });
  }

  void addEntryEffect({required String name, required String assetPath, required double price}) {
    _storeController.addItem({
      'id': 'dynamic_entry_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'imagePath': assetPath,
      'price': price,
      'type': StoreItemType.entryEffect,
    });
  }

  void addPremiumId({required String fancyId, required double price}) {
    _storeController.addItem({
      'id': 'dynamic_id_${DateTime.now().millisecondsSinceEpoch}',
      'name': fancyId,
      'imagePath': 'assets/Asad/vip_coin.png',
      'price': price,
      'type': StoreItemType.fancyId,
    });
  }

  // Room Lifecycle Management Methods (Admin Only)

  /// Admin-only method to destroy a room permanently
  /// This will set isPersistent: false and isActive: false
  void destroyRoom(String roomId) {
    _roomController.roomId = roomId;
    _roomController.destroyRoom(requesterId: 'admin', isAdmin: true);
    notifyListeners();
    debugPrint('Admin: Room $roomId destroyed permanently');
  }

  /// Admin-only method to close a room temporarily
  /// Room becomes inactive but persists in database
  void closeRoom(String roomId) {
    _roomController.roomId = roomId;
    _roomController.closeRoom(requesterId: 'admin', isAdmin: true);
    notifyListeners();
    debugPrint('Admin: Room $roomId closed (inactive but persistent)');
  }

  /// Admin-only method to reopen a closed room
  void reopenRoom(String roomId) {
    _roomController.roomId = roomId;
    _roomController.reopenRoom(requesterId: 'admin', isAdmin: true);
    notifyListeners();
    debugPrint('Admin: Room $roomId reopened');
  }
}
