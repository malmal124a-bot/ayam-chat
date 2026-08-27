import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wallet_controller.dart';
import '../models/user_model.dart';
import '../models/store_item.dart';
import '../repositories/user_repository.dart';
import '../repositories/firebase_user_repository.dart';

class UserController extends ChangeNotifier {
  static final UserController _instance = UserController._internal();
  factory UserController() => _instance;
  
  final UserRepository _repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserController._internal() : _repository = FirebaseUserRepository() {
    debugPrint('Initializing: UserController');
    _listenToFirestore();
  }

  Future<void> init() async {
    await _checkPersistence();
    await _loadUserData();
    _listenToFirestore();
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _syncWithFirebaseUser(user);
      }
    });
  }

  void _listenToFirestore() {
    final userId = id;
    _firestore.collection('users').doc(userId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          _currentLevel = (data['level'] as num?)?.toInt() ?? _currentLevel;
          _vipLevel = (data['vipLevel'] as num?)?.toInt() ?? _vipLevel;
          _wealthLevel = (data['wealthLevel'] as num?)?.toInt() ?? _wealthLevel;
          _magicLevel = (data['magicLevel'] as num?)?.toInt() ?? _magicLevel;
          _nobleLevel = (data['nobleLevel'] as num?)?.toInt() ?? _nobleLevel;
          _wealthXP = (data['wealthXP'] as num?)?.toInt() ?? _wealthXP;
          _magicXP = (data['magicXP'] as num?)?.toInt() ?? _magicXP;
          _nobleXP = (data['nobleXP'] as num?)?.toInt() ?? _nobleXP;
          _globalScore = (data['globalScore'] as num?)?.toInt() ?? _globalScore;
          followersCount = (data['followersCount'] as num?)?.toInt() ?? followersCount;
          visitorsCount = (data['visitorsCount'] as num?)?.toInt() ?? visitorsCount;
          friendsCount = (data['friendsCount'] as num?)?.toInt() ?? friendsCount;
          likesCount = (data['likesCount'] as num?)?.toInt() ?? likesCount;
          currentRoomId = data['currentRoomId'];
          currentRoomName = data['currentRoomName'];
          _isOnline = data['isOnline'] as bool? ?? _isOnline;
          _role = UserRole.values.firstWhere(
            (e) => e.name == data['role'],
            orElse: () => UserRole.user,
          );
          _permissions = (data['permissions'] as List?)?.cast<String>() ?? [];
          
          // Unified profile avatar sync across all screens
          name = data['name']?.toString() ?? name;
          profilePic = data['profilePic']?.toString() ?? data['photoUrl']?.toString() ?? profilePic;
          avatarUrl = data['avatarUrl']?.toString() ?? avatarUrl;
          avatarType = data['avatarType']?.toString() ?? avatarType;
          gender = data['gender']?.toString() ?? gender;
          
          // Equipped vanity ID sync
          _equippedVanityId = data['equippedVanityId']?.toString() ?? _equippedVanityId;
          
          // Agency status sync
          isRechargeAgency = data['isRechargeAgency'] as bool? ?? false;
          isModeratorAgency = data['isModeratorAgency'] as bool? ?? false;
          
          vipRank = 'VIP $_vipLevel';
          safeNotify();
        }
      }
    });
  }

  int _currentXP = 0;
  int _currentLevel = 1;

  int _wealthXP = 0; 
  int _wealthLevel = 1; 
  int _magicXP = 0; 
  int _magicLevel = 1; 
  int _nobleXP = 0; 
  int _nobleLevel = 1; 
  int _globalScore = 0; 

  final String _currentBadge = 'Beginner';
  double _combatValue = 0.0;
  bool _isLoggedIn = false;
  bool _isOnline = true; 
  bool isProfileComplete = false;
  bool _isDisposed = false;

  UserRole _role = UserRole.user;
  List<String> _permissions = [];

  String name = 'Rssasa User';
  String id = '474708'; // Fixed user's actual 6-digit userId
  String _equippedVanityId = ''; // Equipped vanity ID from bag
  String profilePic = 'assets/Asad/bg_vip_content.png';
  String gender = 'Male';
  DateTime? dateOfBirth = DateTime(1995, 5, 20);
  String? avatarUrl;
  String? avatarType; 
  String? currentRoomId;
  String? currentRoomName;

  int followersCount = 0;
  int likesCount = 0;
  int visitorsCount = 0;
  int friendsCount = 0;

  bool isAgent = false;
  bool isRechargeAgency = false;
  bool isModeratorAgency = false;

  // Display ID: Returns equipped vanity ID if active, otherwise default user ID
  String get displayId => _equippedVanityId.isNotEmpty ? _equippedVanityId : id;

  @override
  void dispose() {
    _isDisposed = true;
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

  int get diamonds {
    try {
      return WalletController().diamonds.value.toInt();
    } catch (e) {
      debugPrint('Error accessing WalletController from UserController: $e');
      return 0;
    }
  }
  
  int _vipLevel = 0; 
  String vipRank = 'VIP 0';

  int get vipLevel => _vipLevel;
  set vipLevel(int value) {
    _vipLevel = value;
    vipRank = 'VIP $value';
    safeNotify();
  }

  bool get isVip => _vipLevel > 0;

  Future<void> setCurrentRoom(String? roomId, String? roomName) async {
    currentRoomId = roomId;
    currentRoomName = roomName;
    
    try {
      await _firestore.collection('users').doc(id).update({
        'currentRoomId': roomId,
        'currentRoomName': roomName,
        'isOnline': roomId != null,
      });
    } catch (e) {
      debugPrint('Error updating current room: $e');
    }
    
    safeNotify();
  }

  Future<void> leaveCurrentRoom() async {
    currentRoomId = null;
    currentRoomName = null;
    
    try {
      await _firestore.collection('users').doc(id).update({
        'currentRoomId': null,
        'currentRoomName': null,
        'isOnline': false,
      });
    } catch (e) {
      debugPrint('Error leaving current room: $e');
    }
    
    safeNotify();
  }

  int get currentXP => _currentXP;
  int get currentLevel => _currentLevel;
  int get globalScore => _globalScore;

  double get xpForNextLevel => (_currentLevel * 100.0);
  double get levelProgress => (_currentXP % 100) / 100.0;
  String get currentBadge => _currentBadge;
  
  String get currentBadgeIcon => 'assets/icons/level_${_currentLevel > 0 ? _currentLevel : 1}.png';

  String getLevelIconPath() {
    return 'assets/icons/level_${_currentLevel > 0 ? _currentLevel : 1}.png';
  }

  bool buyItem(StoreItem item) {
    bool success = WalletController().buyItem(item);
    if (success) {
      safeNotify();
    }
    return success;
  }

  int get wealthXP => _wealthXP;
  int get wealthLevel => _wealthLevel;
  int get magicXP => _magicXP;
  int get magicLevel => _magicLevel;
  int get nobleXP => _nobleXP;
  int get nobleLevel => _nobleLevel;

  int getCurrentMagicLevel() => _magicLevel;
  int getSupportReceivedLevel() => _magicLevel;
  int getWealthLevel() => _wealthLevel;
  int getNobleLevel() => _nobleLevel;

  double get combatValue => _combatValue;
  bool get isLoggedIn => _isLoggedIn;
  bool get isOnline => _isOnline;
  UserRole get role => _role;
  List<String> get permissions => List.unmodifiable(_permissions);

  bool hasPermission(String permission) => _permissions.contains(permission);
  bool hasRole(UserRole requiredRole) => _role == requiredRole || _role == UserRole.superAdmin;

  double get wealthProgress => (_wealthXP % 100) / 100.0;
  double get magicProgress => (_magicXP % 150) / 150.0;
  double get nobleProgress => (_nobleXP % 200) / 200.0;

  void addWealthXP(int amount) {
    _wealthXP += amount;
    _wealthLevel = (_wealthXP / 100).floor() + 1;
    if (_wealthLevel > 100) _wealthLevel = 100;
    _syncWithRepository();
    safeNotify();
  }

  void addMagicXP(int amount) {
    _magicXP += amount;
    _magicLevel = (_magicXP / 150).floor() + 1;
    if (_magicLevel > 150) _magicLevel = 150;
    _syncWithRepository();
    safeNotify();
  }

  void addNobleXP(int amount) {
    _nobleXP += amount;
    _nobleLevel = (_nobleXP / 200).floor() + 1;
    if (_nobleLevel > 200) _nobleLevel = 200;
    _syncWithRepository();
    safeNotify();
  }

  void onSupportReceived(int giftValue) {
    addMagicXP(giftValue);
  }

  void onRechargePerformed(double amount) {
    int diamondValue = (amount * 100).toInt(); 
    addWealthXP(diamondValue);
    if (amount >= 50.0) {
      addNobleXP(diamondValue);
    }
  }

  void updateVipFromRecharge(double total) {
    int newLevel = 0;
    if (total >= 10000) {
      newLevel = 10;
    } else if (total >= 5000) {
      newLevel = 9;
    } else if (total >= 2500) {
      newLevel = 8;
    } else if (total >= 1000) {
      newLevel = 7;
    } else if (total >= 500) {
      newLevel = 6;
    } else if (total >= 250) {
      newLevel = 5;
    } else if (total >= 100) {
      newLevel = 4;
    } else if (total >= 50) {
      newLevel = 3;
    } else if (total >= 10) {
      newLevel = 2;
    } else if (total >= 1) {
      newLevel = 1;
    }

    if (newLevel > _vipLevel) {
      vipLevel = newLevel;
      _syncWithRepository();
    }
  }

  Future<void> _checkPersistence() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = _auth.currentUser != null;
    isAgent = prefs.getBool('isAgent') ?? false;

    String? savedId = prefs.getString('user_id');
    if (savedId == null || savedId.isEmpty || savedId == '00000000') {
      savedId = await _generateUnique6DigitId();
      await prefs.setString('user_id', savedId);
      debugPrint('UserController: Generated new unique 6-digit User ID: $savedId');
    }
    id = savedId;
    
    // Firebase UID is used for authentication only, not for display ID
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      debugPrint('UserController: Firebase user authenticated, using display ID: $id');
    }
    
    safeNotify();
  }

  Future<String> _generateUnique6DigitId() async {
    final random = Random();
    int maxAttempts = 100;
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      int generated = 100000 + random.nextInt(900000); // 6-digit: 100000-999999
      String candidateId = generated.toString();
      
      // Check Firestore for uniqueness
      final snapshot = await _firestore.collection('users').doc(candidateId).get();
      if (!snapshot.exists) {
        debugPrint('UserController: Generated unique ID: $candidateId (attempt ${attempts + 1})');
        return candidateId;
      }
      
      attempts++;
    }
    
    // Fallback if all attempts fail (should be extremely rare)
    final timestampId = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    debugPrint('UserController: Using timestamp-based fallback ID: $timestampId');
    return timestampId;
  }

  Future<void> _syncWithFirebaseUser(User firebaseUser) async {
    try {
      // Firebase UID is used for authentication only, display ID remains the same
      name = firebaseUser.displayName ?? 'User';
      avatarUrl = firebaseUser.photoURL;
      _isLoggedIn = true;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      
      // Load user data from Firestore
      await _loadUserData();
      
      safeNotify();
    } catch (e) {
      debugPrint('Error syncing with Firebase user: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userModel = await _repository.getUser(id).timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      
      if (userModel != null) {
        name = userModel.name;
        profilePic = userModel.profilePic;
        gender = userModel.gender;
        _currentLevel = userModel.level;
        _vipLevel = userModel.vipLevel;
        _wealthLevel = userModel.wealthLevel;
        _magicLevel = userModel.magicLevel;
        _nobleLevel = userModel.nobleLevel;
        _wealthXP = userModel.wealthXP;
        _magicXP = userModel.magicXP;
        _nobleXP = userModel.nobleXP;
        _globalScore = userModel.globalScore;
        followersCount = userModel.followersCount;
        visitorsCount = userModel.visitorsCount;
        friendsCount = userModel.friendsCount;
        likesCount = userModel.likesCount;
        vipRank = 'VIP $_vipLevel';
        safeNotify();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void updateLeveling(int points) {
    _currentXP += points;
    _currentLevel = (_currentXP / 100).floor() + 1;
    _syncWithRepository();
    safeNotify();
  }

  /// Add XP directly to account level with automatic level-up handling
  /// This is the primary method for updating account XP from gifts and activities
  void addXP(int amount) {
    _currentXP += amount;
    _currentLevel = (_currentXP / 100).floor() + 1;
    _syncWithRepository();
    safeNotify();
  }

  void addGlobalScore(int points) {
    _globalScore += points;
    _syncWithRepository();
    safeNotify();
  }

  void _syncWithRepository() async {
    try {
      await _repository.updateUser(UserModel(
        id: id,
        name: name,
        profilePic: profilePic,
        gender: gender,
        level: _currentLevel,
        vipLevel: _vipLevel,
        wealthLevel: _wealthLevel,
        magicLevel: _magicLevel,
        nobleLevel: _nobleLevel,
        wealthXP: _wealthXP,
        magicXP: _magicXP,
        nobleXP: _nobleXP,
        globalScore: _globalScore,
      )).timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Error syncing user data: $e');
    }
  }

  void setOnlineStatus(bool online) {
    _isOnline = online;
    safeNotify();
  }

  void toggleAgentStatus(bool status) async {
    isAgent = status;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAgent', status);
    safeNotify();
  }

  Future<bool> loginWithCredentials(String username, String password) async {
    try {
      final success = await _repository.login(username, password).timeout(const Duration(seconds: 10));
      if (success) {
        _isLoggedIn = true;
        _isOnline = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await _loadUserData();
      }
      return success;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  void login() async {
    _isLoggedIn = true;
    _isOnline = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    
    // Create user in Firestore if doesn't exist
    if (_repository is FirebaseUserRepository) {
      final firebaseRepo = _repository as FirebaseUserRepository;
      await firebaseRepo.createUser(UserModel(
        id: id,
        name: name,
        profilePic: profilePic,
        gender: gender,
        level: _currentLevel,
        vipLevel: _vipLevel,
        wealthLevel: _wealthLevel,
        magicLevel: _magicLevel,
        nobleLevel: _nobleLevel,
        wealthXP: _wealthXP,
        magicXP: _magicXP,
        nobleXP: _nobleXP,
        globalScore: _globalScore,
      ));
    }
    
    safeNotify();
  }

  void logout() async {
    _isLoggedIn = false;
    _isOnline = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    safeNotify();
  }

  void simulateRecharge(int amount) {
    WalletController().addDiamonds(amount);
    onRechargePerformed(amount / 100.0);
    safeNotify();
  }

  void addCombatValue(double delta) {
    _combatValue += delta;
    safeNotify();
  }

  void setFancyId(String newId) {
    _equippedVanityId = newId;
    // Save to Firestore as equippedVanityId
    _firestore.collection('users').doc(id).update({
      'equippedVanityId': newId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _syncWithRepository();
    safeNotify();
  }

  void updateProfile({String? newName, String? newGender, DateTime? newDob, String? newPic}) {
    if (newName != null) name = newName;
    if (newGender != null) gender = newGender;
    if (newDob != null) dateOfBirth = newDob;
    if (newPic != null) profilePic = newPic;
    isProfileComplete = true;
    _syncWithRepository();
    safeNotify();
  }
}
