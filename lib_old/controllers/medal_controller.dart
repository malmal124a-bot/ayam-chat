import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medal_model.dart';
import '../repositories/medal_repository.dart';
import '../repositories/local_medal_repository.dart';
import 'user_controller.dart';

class MedalController extends ChangeNotifier {
  static final MedalController _instance = MedalController._internal();
  factory MedalController() => _instance;
  
  final MedalRepository _repository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MedalController._internal() : _repository = LocalMedalRepository() {
    debugPrint('Initializing: MedalController');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedals();
      _listenToFirestore();
    });
  }

  void _listenToFirestore() {
    final userId = UserController().id;
    if (userId.isEmpty) return;
    
    // Listen to user's medals document
    _firestore.collection('users').doc(userId).collection('medals')
        .doc('owned')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final ownedIds = data['ownedMedalIds'] as List<dynamic>?;
          if (ownedIds != null) {
            _ownedMedalIds = ownedIds.cast<String>().toSet();
            final equippedIds = data['equippedMedalIds'] as List<dynamic>?;
            if (equippedIds != null) {
              _equippedMedalIds.clear();
              _equippedMedalIds.addAll(equippedIds.cast<String>());
            }
            notifyListeners();
          }
        }
      }
    });
  }

  List<Medal> _allMedals = [];
  Set<String> _ownedMedalIds = {};
  String? _selectedMedalId;
  
  // New: Multiple slots for equipped medals (Max 4)
  final List<String> _equippedMedalIds = [];

  final Set<String> _newlyUnlockedIds = {};

  List<Medal> get allMedals => _allMedals;
  Set<String> get ownedMedalIds => _ownedMedalIds;
  
  Medal? get selectedMedal => _allMedals.firstWhere(
    (m) => m.id == _selectedMedalId, 
    orElse: () => _allMedals.isNotEmpty ? _allMedals.first : Medal(id: '', nameKey: '', iconPath: '', type: MedalType.milestone, descriptionKey: '')
  );

  List<Medal> get equippedMedals {
    return _equippedMedalIds.map((id) => _allMedals.firstWhere((m) => m.id == id)).toList();
  }

  Set<String> get newlyUnlockedIds => _newlyUnlockedIds;

  Future<void> _loadMedals() async {
    try {
      _allMedals = await _repository.getAllMedals().timeout(const Duration(seconds: 5));
      final user = UserController();
      if (user.isOnline) {
        final owned = await _repository.getOwnedMedalIds(user.id).timeout(const Duration(seconds: 5));
        _ownedMedalIds = owned.toSet();
        if (_ownedMedalIds.isNotEmpty && _selectedMedalId == null) {
          _selectedMedalId = _ownedMedalIds.first;
          // Auto-equip first few as a display
          _equippedMedalIds.clear();
          _equippedMedalIds.addAll(_ownedMedalIds.take(4));
        }
      }
    } catch (e) {
      debugPrint('Error loading medals: $e');
    } finally {
      notifyListeners();
    }
  }

  bool isOwned(String id) => _ownedMedalIds.contains(id);
  bool isEquipped(String id) => _equippedMedalIds.contains(id);

  void selectMedal(String id) {
    if (isOwned(id)) {
      _selectedMedalId = id;
      notifyListeners();
    }
  }

  void toggleEquip(String id) {
    if (!isOwned(id)) return;

    if (_equippedMedalIds.contains(id)) {
      _equippedMedalIds.remove(id);
    } else {
      if (_equippedMedalIds.length < 4) {
        _equippedMedalIds.add(id);
      } else {
        // Replace the last one if full
        _equippedMedalIds.removeLast();
        _equippedMedalIds.add(id);
      }
    }
    _saveToFirestore();
    notifyListeners();
  }

  Future<void> _saveToFirestore() async {
    try {
      final userId = UserController().id;
      if (userId.isEmpty) return;
      
      await _firestore.collection('users').doc(userId).collection('medals')
          .doc('owned')
          .set({
        'ownedMedalIds': _ownedMedalIds.toList(),
        'equippedMedalIds': _equippedMedalIds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving medals to Firestore: $e');
    }
  }

  List<Medal> getMedalsByType(MedalType type) {
    return _allMedals.where((m) => m.type == type).toList();
  }

  void checkMedalUnlocks(int currentDiamonds) {
    bool newlyUnlocked = false;
    final user = UserController();
    final userId = user.id;

    if (currentDiamonds >= 100000000 && !isOwned('medal_100m')) {
      _unlockMedal(userId, 'medal_100m');
      newlyUnlocked = true;
    }
    if (currentDiamonds >= 110000000 && !isOwned('medal_110m')) {
      _unlockMedal(userId, 'medal_110m');
      newlyUnlocked = true;
    }

    if (newlyUnlocked) {
      notifyListeners();
    }
  }

  void _unlockMedal(String userId, String id) async {
    if (!_ownedMedalIds.contains(id)) {
      _ownedMedalIds.add(id);
      _newlyUnlockedIds.add(id);
      try {
        await _repository.saveOwnedMedal(userId, id).timeout(const Duration(seconds: 5));
        
        // Save to Firestore
        await _firestore.collection('users').doc(userId).collection('medals')
            .doc('owned')
            .set({
          'ownedMedalIds': _ownedMedalIds.toList(),
          'equippedMedalIds': _equippedMedalIds,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // Grant automatic reward upon milestone completion
        // Add reward logic here if needed
      } catch (e) {
        debugPrint('Error saving owned medal: $e');
      }
    }
  }

  void clearNewlyUnlocked(String id) {
    if (_newlyUnlockedIds.contains(id)) {
      _newlyUnlockedIds.remove(id);
      notifyListeners();
    }
  }
}
