import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'medal_controller.dart';
import 'user_controller.dart';
import 'auth_controller.dart';
import 'inventory_controller.dart';
import '../services/supabase_service.dart';
import '../services/agency_api_service.dart';
import '../models/transaction_model.dart';
import '../models/store_item.dart';

class WalletController extends ChangeNotifier {
  static final WalletController _instance = WalletController._internal();
  factory WalletController() => _instance;

  WalletController._internal() {
    debugPrint('Initializing: WalletController');
    _loadFromPrefs();
  }

  bool _isDisposed = false;

  double _balance = 0.0;
  double _agencyBalance = 0.0;
  int _diamonds = 0;        
  int _coins = 0; // Added for Daily Check-in system
  double _totalRecharged = 0.0;
  List<Transaction> _transactions = [];

  double get balance => _balance;
  double get agencyBalance => _agencyBalance;
  int get diamonds => _diamonds;
  int get coins => _coins;
  List<Transaction> get transactions => List.unmodifiable(_transactions);

  double getTotalRecharged() => _totalRecharged;
  String getLevelIconPath() => UserController().getLevelIconPath();
  String get currentBadgeIcon => UserController().currentBadgeIcon;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _balance = prefs.getDouble('wallet_balance') ?? 0.0;
      _agencyBalance = prefs.getDouble('agency_balance') ?? 0.0;
      _diamonds = prefs.getInt('wallet_diamonds') ?? prefs.getInt('wallet_coins') ?? 0;
      _coins = prefs.getInt('user_coins_gold') ?? 0;
      _totalRecharged = prefs.getDouble('total_recharged') ?? 0.0;
      
      final String? transactionsJson = prefs.getString('transaction_history');
      if (transactionsJson != null) {
        final List<dynamic> decoded = jsonDecode(transactionsJson);
        _transactions = decoded.map((item) => Transaction.fromJson(item)).toList();
      }
      safeNotify();
    } catch (e) {
      debugPrint('Error loading wallet: $e');
    }
    // Then fetch fresh data from Supabase (overwrites stale local values)
    _loadFromSupabase();
  }

  /// Loads wallet data from Supabase on startup / login so dashboard edits
  /// (admin adding diamonds/coins) are reflected immediately.
  Future<void> _loadFromSupabase() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    try {
      final row = await SupabaseService.client
          .from('users')
          .select('diamonds, coins, balance, total_recharged')
          .eq('auth_uid', uid)
          .maybeSingle();
      if (row == null) return;

      _diamonds = (row['diamonds'] ?? _diamonds) as int;
      _coins = (row['coins'] ?? _coins) as int;
      _balance = ((row['balance'] ?? _balance) as num).toDouble();
      _totalRecharged = ((row['total_recharged'] ?? _totalRecharged) as num).toDouble();

      _saveToPrefs();
      safeNotify();
    } catch (e) {
      debugPrint('WalletController: _loadFromSupabase failed: $e');
    }
  }

  /// Called by UserController's realtime subscription when the dashboard
  /// edits diamonds/coins. Updates local state + persists to prefs.
  void syncFromRow(Map<String, dynamic> data) {
    var changed = false;
    if (data['diamonds'] != null && data['diamonds'] != _diamonds) {
      _diamonds = data['diamonds'] as int;
      changed = true;
    }
    if (data['coins'] != null && data['coins'] != _coins) {
      _coins = data['coins'] as int;
      changed = true;
    }
    if (data['balance'] != null) {
      final newBalance = ((data['balance'] as num?)?.toDouble());
      if (newBalance != null && newBalance != _balance) {
        _balance = newBalance;
        changed = true;
      }
    }
    if (data['total_recharged'] != null) {
      final newTotal = ((data['total_recharged'] as num?)?.toDouble());
      if (newTotal != null && newTotal != _totalRecharged) {
        _totalRecharged = newTotal;
        changed = true;
      }
    }
    if (changed) {
      _saveToPrefs();
      safeNotify();
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('wallet_balance', _balance);
      await prefs.setDouble('agency_balance', _agencyBalance);
      await prefs.setInt('wallet_diamonds', _diamonds);
      await prefs.setInt('user_coins_gold', _coins);
      await prefs.setDouble('total_recharged', _totalRecharged);
      
      final String encoded = jsonEncode(_transactions.map((t) => t.toJson()).toList());
      await prefs.setString('transaction_history', encoded);
    } catch (e) {
      debugPrint('Error saving wallet: $e');
    }
  }

  void addBalance(double amount, {String? description, String? method}) {
    if (amount <= 0 || amount.isNaN || amount.isInfinite) return;
    
    _balance += amount;
    _totalRecharged += amount;
    
    final int rate = AuthController().currentDiamondRate;
    int diamondsToAdd = (amount * rate).toInt();
    _diamonds += diamondsToAdd;

    UserController().onRechargePerformed(amount);

    _transactions.insert(0, Transaction(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      targetId: 'Self',
      amount: amount,
      date: DateTime.now(),
      status: TransactionStatus.completed,
      description: description ?? (method != null ? 'Recharge via $method' : 'Direct Recharge'),
    ));

    _syncToSupabase();
    _saveToPrefs();
    UserController().updateVipFromRecharge(_totalRecharged);
    MedalController().checkMedalUnlocks(_diamonds);
    safeNotify();
  }

  void addCoins(dynamic amount) {
    final int val = amount is int ? amount : (int.tryParse(amount.toString()) ?? 0);
    if (val <= 0) return;
    _coins += val;
    _syncToSupabase();
    _saveToPrefs();
    safeNotify();
  }

  void addDiamonds(int amount) {
    if (amount <= 0) return;
    _diamonds += amount;
    _syncToSupabase();
    _saveToPrefs();
    MedalController().checkMedalUnlocks(_diamonds);
    safeNotify();
  }

  bool spendDiamonds(int amount) {
    if (amount <= 0 || _diamonds < amount) return false;
    _diamonds -= amount;
    _syncToSupabase();
    _saveToPrefs();
    safeNotify();
    return true;
  }

  /// Withdraw diamonds from another user via the backend (atomic).
  /// Returns {ok, message/error}.
  Future<Map<String, dynamic>> withdrawFromUser(String sourceUserId, int diamonds, {String? agencyId}) async {
    if (diamonds <= 0) return {'ok': false, 'error': 'المبلغ غير صالح'};

    final user = UserController();
    final resolvedAgencyId = agencyId ?? 'AG${user.numericId}';

    try {
      final result = await AgencyApiService().withdraw(
        agencyId: resolvedAgencyId,
        sourceUserId: sourceUserId,
        sourceNumericId: sourceUserId,
        diamonds: diamonds,
      );
      if (result['ok'] == true) {
        // Update local wallet state
        _loadFromSupabase();
        return {'ok': true, 'message': result['message'] ?? 'تم السحب بنجاح'};
      }
      return result;
    } catch (e) {
      debugPrint('withdrawFromUser failed: $e');
      return {'ok': false, 'error': 'تعذر الاتصال بالسيرفر'};
    }
  }

  void _syncToSupabase() {
    final uid = SupabaseService.currentUserId;
    if (uid != null) {
      SupabaseService.client.from('users').update({
        'balance': _balance,
        'diamonds': _diamonds,
        'coins': _coins,
        'total_recharged': _totalRecharged,
      }).eq('auth_uid', uid).then((_) {}).catchError((_) {});
    }
  }

  void addAgencyBalance(double amount, {String? description}) {
    if (amount <= 0) return;
    _agencyBalance += amount;
    _saveToPrefs();
    safeNotify();
  }

  void addDiamondsToUser(String targetId, int amount, double costUsd) {
    if (amount <= 0 || _agencyBalance < costUsd) return;
    _agencyBalance -= costUsd;
    if (targetId == UserController().id) {
      _diamonds += amount;
    }
    _saveToPrefs();
    _syncToSupabase();
    safeNotify();
  }

  bool spendBalance(double amount) {
    if (amount <= 0 || _balance < amount) return false;
    _balance -= amount;
    _saveToPrefs();
    _syncToSupabase();
    safeNotify();
    return true;
  }

  bool buyItem(StoreItem item) {
    int price = item.price.toInt();
    if (spendDiamonds(price)) {
      InventoryController().addItem(item.id);
      return true;
    }
    return false;
  }
}
