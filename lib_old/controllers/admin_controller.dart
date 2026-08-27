import 'package:flutter/foundation.dart';
import 'package:ayam_chat/controllers/wallet_controller.dart';
import 'package:ayam_chat/controllers/store_controller.dart';
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
}
