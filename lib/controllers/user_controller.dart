import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'wallet_controller.dart';
import '../models/user_model.dart';
import '../models/store_item.dart';
import '../repositories/user_repository.dart';
import '../repositories/local_user_repository.dart';
import '../services/supabase_service.dart';
import '../services/cloudinary_service.dart';
import 'leaderboard_controller.dart';

class UserController extends ChangeNotifier {
  static final UserController _instance = UserController._internal();
  factory UserController() => _instance;
  
  final UserRepository _repository;
  final SupabaseClient _client = SupabaseService.client;
  StreamSubscription<List<Map<String, dynamic>>>? _userDocSubscription;

  UserController._internal() : _repository = LocalUserRepository() {
    debugPrint('Initializing: UserController');
    init();
  }

  Future<void> init() async {
    await _checkPersistence();
    await _loadUserData();
    _listenToSupabaseChanges();
  }

  void _listenToSupabaseChanges() async {
    final userId = SupabaseService.currentUserId;
    if (userId != null) {
      await SupabaseService.ensureValidSession();
      _userDocSubscription = _client
          .from('users')
          .stream(primaryKey: ['auth_uid'])
          .eq('auth_uid', userId)
          .listen((rows) {
        if (rows.isNotEmpty) {
          final data = rows.first;

          if (data['name'] != null) name = data['name'] as String;
          if (data['photo_url'] != null) profilePic = data['photo_url'] as String;
          if (data['numeric_id'] != null) {
            id = data['numeric_id'] as String;
            numericId = data['numeric_id'] as String;
          }
          if (data['gender'] != null) gender = data['gender'] as String;
          if (data['country'] != null) country = data['country'] as String;

          WalletController().syncFromRow(data);

          debugPrint('UserController: Synced from Supabase - Name: $name, ID: $id');
          safeNotify();
        }
      });
      debugPrint('UserController: Listening to Supabase changes for user: $userId');
    }
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

  String _currentBadge = 'Beginner';
  double _combatValue = 0.0;
  bool _isLoggedIn = false;
  bool _isOnline = true; 
  bool isProfileComplete = false;
  bool _isDisposed = false;

  String name = 'Rssasa User';
  String id = '100000'; 
  String numericId = '100000'; // 6-digit Profile ID
  String profilePic = 'assets/Asad/bg_vip_content.png';
  String gender = 'Male';
  String country = '';
  DateTime? dateOfBirth = DateTime(1995, 5, 20);
  String? avatarUrl;
  String? avatarType; 

  int followersCount = 0;
  int likesCount = 0;
  int visitorsCount = 0;
  int friendsCount = 0;

  bool isAgent = false;

  @override
  void dispose() {
    _userDocSubscription?.cancel();
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
      return WalletController().diamonds;
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
    if (total >= 10000) newLevel = 10;
    else if (total >= 5000) newLevel = 9;
    else if (total >= 2500) newLevel = 8;
    else if (total >= 1000) newLevel = 7;
    else if (total >= 500) newLevel = 6;
    else if (total >= 250) newLevel = 5;
    else if (total >= 100) newLevel = 4;
    else if (total >= 50) newLevel = 3;
    else if (total >= 10) newLevel = 2;
    else if (total >= 1) newLevel = 1;

    if (newLevel > _vipLevel) {
      vipLevel = newLevel;
      _syncWithRepository();
    }
  }

  Future<void> _checkPersistence() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    isAgent = prefs.getBool('isAgent') ?? false;

    // First try to load numeric_id from Supabase if logged in
    final authUid = SupabaseService.currentUserId;
    if (authUid != null) {
      try {
        final row = await _client
            .from('users')
            .select('numeric_id')
            .eq('auth_uid', authUid)
            .maybeSingle();
        if (row != null && row['numeric_id'] != null && (row['numeric_id'] as String).isNotEmpty) {
          id = row['numeric_id'];
          numericId = row['numeric_id'];
          await prefs.setString('user_id', numericId);
          safeNotify();
          return;
        }
      } catch (e) {
        debugPrint('UserController: Failed to load numeric_id from Supabase: $e');
      }
    }

    // Fallback to local SharedPreferences
    String? savedId = prefs.getString('user_id');
    if (savedId == null || savedId.isEmpty || savedId.length != 6) {
      savedId = _generateRandom6DigitId();
      await prefs.setString('user_id', savedId);
    }
    id = savedId;
    numericId = savedId;
    
    safeNotify();
  }

  String _generateRandom6DigitId() {
    final random = Random();
    int min = 100000;
    int max = 999999;
    int generated = min + random.nextInt(max - min + 1);
    return generated.toString();
  }

  Future<void> _loadUserData() async {
    try {
      UserModel? userModel;

      // Prefer the Supabase profile row (matched by auth uid or numeric id)
      final authUid = SupabaseService.currentUserId;
      if (authUid != null) {
        final row = await _client
            .from('users')
            .select()
            .eq('auth_uid', authUid)
            .maybeSingle();
        if (row != null) {
          userModel = UserModel.fromSupabase(row);
        }
      }
      if (userModel == null) {
        final row = await _client
            .from('users')
            .select()
            .eq('numeric_id', id)
            .limit(1);
        if (row.isNotEmpty) {
          userModel = UserModel.fromSupabase(row.first);
        }
      }
      userModel ??= await _repository.getUser(id).timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      
      if (userModel != null) {
        name = userModel.name;
        profilePic = userModel.profilePic;
        gender = userModel.gender;
        country = userModel.country;
        _currentLevel = userModel.level;
        _vipLevel = userModel.vipLevel;
        _wealthLevel = userModel.wealthLevel;
        _magicLevel = userModel.magicLevel;
        _nobleLevel = userModel.nobleLevel;
        _wealthXP = userModel.wealthXP;
        _magicXP = userModel.magicXP;
        _nobleXP = userModel.nobleXP;
        _globalScore = userModel.globalScore;
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
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    try {
      final model = UserModel(
        id: userId,
        numericId: id,
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
      );
      
      await _client.from('users').upsert({
        'auth_uid': userId,
        'numeric_id': id,
        'name': name,
        'photo_url': profilePic,
        'gender': gender,
        'country': country,
        'level': _currentLevel,
        'vip_level': _vipLevel,
        'wealth_level': _wealthLevel,
        'magic_level': _magicLevel,
        'noble_level': _nobleLevel,
        'wealth_xp': _wealthXP,
        'magic_xp': _magicXP,
        'noble_xp': _nobleXP,
        'global_score': _globalScore,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'auth_uid');
      await _repository.updateUser(model).timeout(const Duration(seconds: 2));
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
    safeNotify();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _isOnline = false;

    _userDocSubscription?.cancel();
    _userDocSubscription = null;

    final uid = SupabaseService.currentUserId;
    if (uid != null) {
      try {
        await _client.from('users').update({'is_online': false}).eq('auth_uid', uid);
      } catch (_) {}
    }

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
    id = newId;
    numericId = newId;
    _syncWithRepository();
    safeNotify();
  }

  void updateProfile({String? newName, String? newGender, DateTime? newDob, String? newPic, String? newCountry}) {
    final oldName = name;
    final oldPic = profilePic;
    if (newName != null) name = newName;
    if (newGender != null) gender = newGender;
    if (newDob != null) dateOfBirth = newDob;
    if (newPic != null) profilePic = newPic;
    if (newCountry != null) country = newCountry;
    isProfileComplete = true;
    _syncWithRepository();
    safeNotify();

    // Sync rankings with new profile data
    LeaderboardController().syncUserProfile(oldName, name, oldPic, profilePic);
  }

  /// UPLOAD TO CLOUDINARY: Pick, upload and store profile photo as a URL
  Future<void> pickAndUploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 300,
        maxHeight: 300,
      );
      
      if (image != null) {
        final String url = await CloudinaryService.uploadImage(image, folder: 'avatars');
        updateProfile(newPic: url);
      }
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
    }
  }
}
