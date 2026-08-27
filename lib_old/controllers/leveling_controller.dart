import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLevel {
  final int level;
  final int currentExp;
  final int expToNextLevel;
  final String levelTitle;
  final int vipLevel;

  UserLevel({
    required this.level,
    required this.currentExp,
    required this.expToNextLevel,
    required this.levelTitle,
    required this.vipLevel,
  });

  double get progress => expToNextLevel > 0 ? currentExp / expToNextLevel : 1.0;
}

class LevelingController extends ChangeNotifier {
  int _diamonds = 0;
  int _coins = 0;
  int _totalRecharged = 0;
  int _totalGiftsSent = 0;
  int _totalGiftsReceived = 0;
  int _currentLevel = 1;
  int _currentVipLevel = 0;
  int _currentExp = 0;
  bool _isLoading = false;
  String? _errorMessage;

  int get diamonds => _diamonds;
  int get coins => _coins;
  int get totalRecharged => _totalRecharged;
  int get totalGiftsSent => _totalGiftsSent;
  int get totalGiftsReceived => _totalGiftsReceived;
  int get currentLevel => _currentLevel;
  int get currentVipLevel => _currentVipLevel;
  int get currentExp => _currentExp;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Level thresholds (experience points needed for each level)
  static const Map<int, int> _levelThresholds = {
    1: 0,
    2: 100,
    3: 300,
    4: 600,
    5: 1000,
    6: 1500,
    7: 2100,
    8: 2800,
    9: 3600,
    10: 4500,
    11: 5500,
    12: 6600,
    13: 7800,
    14: 9100,
    15: 10500,
    16: 12000,
    17: 13600,
    18: 15300,
    19: 17100,
    20: 19000,
  };

  // VIP thresholds (diamonds needed for each VIP level)
  static const Map<int, int> _vipThresholds = {
    0: 0,
    1: 100,
    2: 500,
    3: 1500,
    4: 3000,
    5: 5000,
    6: 8000,
    7: 12000,
    8: 17000,
    9: 23000,
    10: 30000,
  };

  // Level titles
  static const List<String> _levelTitles = [
    'مبتدئ',
    'مستجد',
    'متعلم',
    'ماهر',
    'خبير',
    'محترف',
    'أسطورة',
    'سوبر ستار',
    'نجم',
    'ملك',
    'إمبراطور',
    'إله',
    'حاكم',
    'قائد',
    'بطل',
    'فارس',
    'محارب',
    'حارس',
    'حكيم',
    'خالد',
  ];

  LevelingController() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _diamonds = prefs.getInt('diamonds') ?? 0;
      _coins = prefs.getInt('coins') ?? 0;
      _totalRecharged = prefs.getInt('total_recharged') ?? 0;
      _totalGiftsSent = prefs.getInt('total_gifts_sent') ?? 0;
      _totalGiftsReceived = prefs.getInt('total_gifts_received') ?? 0;
      _currentLevel = prefs.getInt('current_level') ?? 1;
      _currentVipLevel = prefs.getInt('current_vip_level') ?? 0;
      _currentExp = prefs.getInt('current_exp') ?? 0;
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  UserLevel getUserLevel() {
    final expToNext = _getExpForNextLevel(_currentLevel);
    final title = _currentLevel <= _levelTitles.length 
        ? _levelTitles[_currentLevel - 1] 
        : 'خالد';
    
    return UserLevel(
      level: _currentLevel,
      currentExp: _currentExp,
      expToNextLevel: expToNext,
      levelTitle: title,
      vipLevel: _currentVipLevel,
    );
  }

  int _getExpForNextLevel(int currentLevel) {
    if (currentLevel >= _levelThresholds.length) {
      return 0; // Max level
    }
    final nextLevel = currentLevel + 1;
    return _levelThresholds[nextLevel] ?? 0;
  }

  Future<bool> rechargeDiamonds(int amount) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      _diamonds += amount;
      _totalRecharged += amount;
      
      // Add experience based on recharge amount (1 exp per 10 diamonds)
      final expGained = amount ~/ 10;
      await _addExperience(expGained);
      
      // Check VIP level progression
      await _checkVipLevelProgression();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('diamonds', _diamonds);
      await prefs.setInt('total_recharged', _totalRecharged);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendGift(int diamondCost) async {
    if (_diamonds < diamondCost) {
      _errorMessage = 'Insufficient diamonds';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate API call
      
      _diamonds -= diamondCost;
      _totalGiftsSent += diamondCost;
      
      // Add experience based on gift value (1 exp per 5 diamonds)
      final expGained = diamondCost ~/ 5;
      await _addExperience(expGained);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('diamonds', _diamonds);
      await prefs.setInt('total_gifts_sent', _totalGiftsSent);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> receiveGift(int diamondValue) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate API call
      
      _diamonds += diamondValue;
      _totalGiftsReceived += diamondValue;
      
      // Add experience based on received gift value (1 exp per 10 diamonds)
      final expGained = diamondValue ~/ 10;
      await _addExperience(expGained);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('diamonds', _diamonds);
      await prefs.setInt('total_gifts_received', _totalGiftsReceived);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _addExperience(int exp) async {
    _currentExp += exp;
    
    // Check for level up
    while (_currentLevel < _levelThresholds.length) {
      final expNeeded = _getExpForNextLevel(_currentLevel);
      if (expNeeded > 0 && _currentExp >= expNeeded) {
        _currentExp -= expNeeded;
        _currentLevel++;
      } else {
        break;
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_exp', _currentExp);
    await prefs.setInt('current_level', _currentLevel);
  }

  Future<void> _checkVipLevelProgression() async {
    // Check if total recharged qualifies for higher VIP level
    for (int i = _vipThresholds.length - 1; i > _currentVipLevel; i--) {
      if (_totalRecharged >= (_vipThresholds[i] ?? 0)) {
        _currentVipLevel = i;
        break;
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_vip_level', _currentVipLevel);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
