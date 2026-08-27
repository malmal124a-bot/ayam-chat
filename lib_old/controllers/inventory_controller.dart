import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_controller.dart';

class InventoryController extends ChangeNotifier {
  static final InventoryController _instance = InventoryController._internal();
  factory InventoryController() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  InventoryController._internal() {
    debugPrint('Initializing: InventoryController');
    _loadFromPrefs();
    _listenToFirestore();
  }

  final List<String> _ownedItemIds = [];
  String? _activeFrameId;
  String? _activeEntryEffectId;

  List<String> get ownedItemIds => List.unmodifiable(_ownedItemIds);
  String? get activeFrameId => _activeFrameId;
  String? get activeEntryEffectId => _activeEntryEffectId;

  void _listenToFirestore() {
    final userId = UserController().id;
    _firestore.collection('users').doc(userId).collection('inventory')
        .doc('items')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final List<dynamic> items = data['ownedItems'] ?? [];
          _ownedItemIds.clear();
          _ownedItemIds.addAll(items.cast<String>());
          _activeFrameId = data['activeFrameId'];
          _activeEntryEffectId = data['activeEntryEffectId'];
          notifyListeners();
        }
      }
    });
  }

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
      if (_activeEntryEffectId != null) await prefs.setString('active_entry_effect', _activeEntryEffectId ?? '');
    } catch (e) {
      debugPrint('Error saving inventory: $e');
    }
  }

  Future<void> _saveToFirestore() async {
    try {
      final userId = UserController().id;
      await _firestore.collection('users').doc(userId).collection('inventory')
          .doc('items')
          .set({
        'ownedItems': _ownedItemIds,
        'activeFrameId': _activeFrameId,
        'activeEntryEffectId': _activeEntryEffectId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving inventory to Firestore: $e');
    }
  }

  void addItem(String itemId) {
    if (!_ownedItemIds.contains(itemId)) {
      _ownedItemIds.add(itemId);
      _saveToPrefs();
      _saveToFirestore();
      notifyListeners();
    }
  }

  bool isOwned(String itemId) {
    return _ownedItemIds.contains(itemId);
  }

  void setActiveFrame(String? frameId) {
    _activeFrameId = frameId;
    _saveToPrefs();
    _saveToFirestore();
    notifyListeners();
  }

  void setActiveEntryEffect(String? effectId) {
    _activeEntryEffectId = effectId;
    _saveToPrefs();
    _saveToFirestore();
    notifyListeners();
  }
}
