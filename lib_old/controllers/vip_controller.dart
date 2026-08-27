import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayam_chat/controllers/user_controller.dart';
import 'package:ayam_chat/controllers/wallet_controller.dart';

class VipUpgradeRecord {
  final int fromLevel;
  final int toLevel;
  final int cost;
  final DateTime timestamp;

  VipUpgradeRecord({
    required this.fromLevel,
    required this.toLevel,
    required this.cost,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'fromLevel': fromLevel,
    'toLevel': toLevel,
    'cost': cost,
    'timestamp': timestamp.toIso8601String(),
  };

  factory VipUpgradeRecord.fromJson(Map<String, dynamic> json) => VipUpgradeRecord(
    fromLevel: json['fromLevel'],
    toLevel: json['toLevel'],
    cost: json['cost'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class VipController extends ChangeNotifier {
  static final VipController _instance = VipController._internal();
  factory VipController() => _instance;

  VipController._internal() {
    debugPrint('Initializing: VipController');
    _loadFromPrefs();
  }

  // Using lazy getters for cross-controller dependencies to prevent circular initializations
  UserController get _userController => UserController();
  WalletController get _walletController => WalletController();

  static const Map<int, int> _vipUpgradeCosts = {
    0: 50,
    1: 100,
    2: 250,
    3: 500,
    4: 1000,
    5: 2000,
    6: 3500,
    7: 5000,
    8: 7500,
    9: 10000,
  };

  List<VipUpgradeRecord> _upgradeHistory = [];

  List<VipUpgradeRecord> get upgradeHistory => _upgradeHistory;

  int getUpgradeCost(int fromLevel) {
    return _vipUpgradeCosts[fromLevel] ?? 0;
  }

  String getVipEffectPath(int level) {
    if (level <= 0) return '';
    if (level >= 1 && level <= 3) {
      return 'assets/vip/vip$level.png';
    }
    return '';
  }

  bool canUpgradeToLevel(int targetLevel) {
    final currentLevel = _userController.vipLevel;
    return targetLevel == currentLevel + 1 && currentLevel < 10;
  }

  bool hasEnoughDiamondsForUpgrade(int targetLevel) {
    final currentLevel = _userController.vipLevel;
    if (!canUpgradeToLevel(targetLevel)) return false;
    
    final cost = getUpgradeCost(currentLevel);
    return _walletController.diamonds.value >= cost;
  }

  // Alias for backward compatibility
  bool hasEnoughCoinsForUpgrade(int targetLevel) => hasEnoughDiamondsForUpgrade(targetLevel);

  String buyVIPUpgrade() {
    final currentLevel = _userController.vipLevel;
    
    if (currentLevel >= 10) {
      return 'لقد وصلت بالفعل إلى أعلى مستوى VIP!';
    }

    final targetLevel = currentLevel + 1;
    final cost = getUpgradeCost(currentLevel);

    if (_walletController.diamonds.value < cost) {
      return 'رصيدك غير كافٍ. تحتاج إلى $cost ماسة للترقية إلى VIP $targetLevel.';
    }

    if (!_walletController.spendDiamonds(cost)) {
      return 'فشل في خصم الماسات. يرجى المحاولة مرة أخرى.';
    }

    _userController.vipLevel = targetLevel;

    final record = VipUpgradeRecord(
      fromLevel: currentLevel,
      toLevel: targetLevel,
      cost: cost,
      timestamp: DateTime.now(),
    );
    _upgradeHistory.add(record);
    _saveHistoryToPrefs();
    
    notifyListeners();
    return 'تم الترقية بنجاح إلى VIP $targetLevel!';
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 5));
      final historyJson = prefs.getStringList('vip_upgrade_history') ?? [];
      
      _upgradeHistory = historyJson
          .map((json) {
            final parts = json.split('|');
            if (parts.length == 4) {
              return VipUpgradeRecord(
                fromLevel: int.parse(parts[0]),
                toLevel: int.parse(parts[1]),
                cost: int.parse(parts[2]),
                timestamp: DateTime.parse(parts[3]),
              );
            }
            return null;
          })
          .whereType<VipUpgradeRecord>()
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading VIP history: $e');
      _upgradeHistory = [];
    }
  }

  Future<void> _saveHistoryToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
      final historyJson = _upgradeHistory.map((record) {
        return '${record.fromLevel}|${record.toLevel}|${record.cost}|${record.timestamp.toIso8601String()}';
      }).toList();
      
      await prefs.setStringList('vip_upgrade_history', historyJson);
    } catch (e) {
      debugPrint('Error saving VIP history: $e');
    }
  }

  void clearHistory() {
    _upgradeHistory.clear();
    _saveHistoryToPrefs();
    notifyListeners();
  }

  int getTotalSpentOnUpgrades() {
    return _upgradeHistory.fold(0, (sum, record) => sum + record.cost);
  }
}
