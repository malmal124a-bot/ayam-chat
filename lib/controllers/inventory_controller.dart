import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store_item.dart';
import 'store_controller.dart';
import 'room_ui_controller.dart';
import 'user_controller.dart';

class InventoryController extends ChangeNotifier {
  static final InventoryController _instance = InventoryController._internal();
  factory InventoryController() => _instance;

  InventoryController._internal() {
    debugPrint('Initializing: InventoryController');
    _loadFromPrefs();
  }

  final List<String> _ownedItemIds = [];
  String? _activeFrameId;
  String? _equippedFrameUrl; // Actual URL/path of equipped frame
  String? _activeEntryEffectId;

  List<String> get ownedItemIds => List.unmodifiable(_ownedItemIds);
  String? get activeFrameId => _activeFrameId;
  String? get equippedFrameUrl => _equippedFrameUrl;
  String? get activeEntryEffectId => _activeEntryEffectId;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 5));
      final String? ownedJson = prefs.getString('owned_items');
      if (ownedJson != null) {
        final List<dynamic> decoded = jsonDecode(ownedJson);
        _ownedItemIds.clear();
        _ownedItemIds.addAll(decoded.cast<String>());
      }
      _activeFrameId = prefs.getString('active_frame');
      _equippedFrameUrl = prefs.getString('equipped_frame_url');
      _activeEntryEffectId = prefs.getString('active_entry_effect');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading inventory: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      await prefs.setString('owned_items', jsonEncode(_ownedItemIds));
      if (_activeFrameId != null) await prefs.setString('active_frame', _activeFrameId ?? '');
      if (_equippedFrameUrl != null) await prefs.setString('equipped_frame_url', _equippedFrameUrl ?? '');
      if (_activeEntryEffectId != null) await prefs.setString('active_entry_effect', _activeEntryEffectId ?? '');
    } catch (e) {
      debugPrint('Error saving inventory: $e');
    }
  }

  void addItem(String itemId) {
    if (!_ownedItemIds.contains(itemId)) {
      _ownedItemIds.add(itemId);
      _saveToPrefs();
      notifyListeners();
    }
  }

  bool isOwned(String itemId) {
    return _ownedItemIds.contains(itemId);
  }

  void setActiveFrame(String? frameId) {
    _activeFrameId = frameId;
    // Look up the frame's image path from StoreController
    if (frameId != null) {
      final storeController = StoreController();
      final frameItem = storeController.items.firstWhere(
        (item) => item.id == frameId,
        orElse: () => storeController.items.firstWhere(
          (item) => item.type == StoreItemType.frame,
          orElse: () => StoreItem(id: '', name: '', imagePath: '', price: 0, type: StoreItemType.frame),
        ),
      );
      _equippedFrameUrl = frameItem.displayUrl;
    } else {
      _equippedFrameUrl = null;
    }
    _saveToPrefs();
    notifyListeners();
    
    // Update room UI to reflect the equipped frame change in real-time
    _updateRoomFrame();
  }

  void _updateRoomFrame() {
    try {
      final userController = UserController();
      final roomController = RoomUiController();
      final userId = userController.id;
      
      // Update the user's frame in the room's userAvatarFrames map
      if (_equippedFrameUrl != null) {
        roomController.userAvatarFrames[userId] = _equippedFrameUrl!;
      } else {
        roomController.userAvatarFrames.remove(userId);
      }
      
      // Update the user's mic seat if they're seated
      final allSeats = roomController.allSeats;
      for (int i = 0; i < allSeats.length; i++) {
        if (allSeats[i].userId == userId) {
          allSeats[i] = allSeats[i].copyWith(
            avatarFrame: _equippedFrameUrl,
          );
          break;
        }
      }
      
      roomController.safeNotify();
    } catch (e) {
      debugPrint('Error updating room frame: $e');
    }
  }

  void setActiveEntryEffect(String? effectId) {
    _activeEntryEffectId = effectId;
    _saveToPrefs();
    notifyListeners();
  }
}
