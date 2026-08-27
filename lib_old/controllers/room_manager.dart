import 'package:flutter/material.dart';
import 'package:ayam_chat/controllers/inventory_controller.dart';
import 'package:ayam_chat/controllers/store_controller.dart';
import 'package:ayam_chat/models/store_item.dart';

class RoomManager extends ChangeNotifier {
  static final RoomManager _instance = RoomManager._internal();
  factory RoomManager() => _instance;

  RoomManager._internal() {
    debugPrint('Initializing: RoomManager');
  }

  StoreItem? _currentEntryEffect;
  StoreItem? get currentEntryEffect => _currentEntryEffect;

  /// Triggered when a user joins a room.
  /// Checks the inventory for an active entry effect and sets it for display.
  void joinRoom() {
    final String? activeEffectId = InventoryController().activeEntryEffectId;
    if (activeEffectId != null) {
      final items = StoreController().items;
      final index = items.indexWhere((item) => item.id == activeEffectId);
      if (index != -1) {
        _currentEntryEffect = items[index];
        notifyListeners();
      } else {
        _currentEntryEffect = null;
      }
    } else {
      _currentEntryEffect = null;
    }
  }

  void clearEntryEffect() {
    _currentEntryEffect = null;
    notifyListeners();
  }
}
