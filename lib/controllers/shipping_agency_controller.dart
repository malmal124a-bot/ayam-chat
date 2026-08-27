import 'package:flutter/material.dart';
import 'package:ayam_chat/models/agency_model.dart';
import 'package:ayam_chat/models/transaction_model.dart';
import 'package:ayam_chat/repositories/agency_repository.dart';
import 'package:ayam_chat/repositories/local_agency_repository.dart';
import 'package:ayam_chat/services/agency_api_service.dart';
import 'package:ayam_chat/controllers/user_controller.dart';
import 'package:ayam_chat/controllers/wallet_controller.dart';
import 'package:easy_localization/easy_localization.dart';

class ShippingAgencyController extends ChangeNotifier {
  final AgencyRepository _repository;

  ShippingAgencyController([AgencyRepository? repository])
      : _repository = repository ?? LocalAgencyRepository() {
    debugPrint('Initializing: ShippingAgencyController');
    _loadInitialData();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Agency? _myShippingAgency;
  Agency? get myShippingAgency => _myShippingAgency;

  int _walletBalance = 0;
  int get walletBalance => _walletBalance;

  double get activationRequiredAmount => 100.0;

  Future<void> _loadInitialData() async {
    final user = UserController();
    if (user.isOnline) {
      // Try Supabase first (agency opened by admin)
      try {
        final agencyData = await AgencyApiService().getMyAgency(user.id);
        if (agencyData != null) {
          _myShippingAgency = Agency(
            id: agencyData['id'] ?? '',
            name: agencyData['name'] ?? '',
            ownerId: agencyData['owner_id'] ?? user.id,
            description: agencyData['description'] ?? '',
            agencyType: AgencyType.charging,
            isActivated: agencyData['is_activated'] ?? false,
            totalEarnings: (agencyData['total_earnings'] as num?)?.toDouble() ?? 0,
            rating: (agencyData['rating'] as num?)?.toDouble() ?? 5,
          );

          // Load wallet from backend using the agency_id from Supabase
          try {
            final wallet = await AgencyApiService().getWallet(agencyData['id']);
            _walletBalance = (wallet['diamonds_balance'] as num?)?.toInt() ?? 0;
          } catch (_) {}

          // Make sure isAgent is true
          if (!user.isAgent) user.toggleAgentStatus(true);

          notifyListeners();
          return;
        }
      } catch (_) {}

      // Fallback: local storage
      _myShippingAgency = await _repository.getMyAgency(user.id, type: AgencyType.charging);

      // Load wallet from backend
      try {
        final agencyId = 'AG${user.numericId}';
        final wallet = await AgencyApiService().getWallet(agencyId);
        _walletBalance = (wallet['diamonds_balance'] as num?)?.toInt() ?? 0;
      } catch (_) {}

      notifyListeners();
    }
  }

  Map<String, dynamic> autoActivateAgency() {
    final wallet = WalletController();
    final user = UserController();

    if (wallet.balance < activationRequiredAmount) {
      return {'ok': false, 'message': 'insufficient_liquidity'.tr()};
    }

    user.toggleAgentStatus(true);
    activateAgency(activationRequiredAmount.toInt());

    return {'ok': true, 'message': 'agency_activated_success'.tr()};
  }

  Future<String> activateAgency(int packageAmount) async {
    final user = UserController();

    _myShippingAgency ??= Agency(
      id: 'TEMP',
      name: 'Shipping Portal - ${user.name}',
      ownerId: user.id,
      description: 'Authorized Shipping Agency',
      agencyType: AgencyType.charging,
    );

    if (_myShippingAgency!.isActivated) return 'Already activated.';

    final wallet = WalletController();
    if (wallet.balance < packageAmount) return 'Insufficient balance.';

    wallet.spendBalance(packageAmount.toDouble());

    final agencyId = 'AG${user.numericId}';

    // Try to open agency in Supabase via backend
    try {
      final result = await AgencyApiService().openForUser(
        targetNumericId: user.numericId,
        agencyName: 'وكالة ${user.name}',
        agencyType: 'shipping',
      );
      if (result['ok'] == true && result['agency_id'] != null) {
        _myShippingAgency = Agency(
          id: result['agency_id'],
          name: _myShippingAgency!.name,
          ownerId: _myShippingAgency!.ownerId,
          description: _myShippingAgency!.description,
          agencyType: AgencyType.charging,
          isActivated: true,
          paymentMethods: ['usdt', 'vodafone', 'bank'],
          chargingLogs: [],
        );
        await _repository.updateAgency(_myShippingAgency!);
        notifyListeners();
        return 'success';
      }
    } catch (e) {
      debugPrint('Supabase agency open failed, falling back to local: $e');
    }

    // Fallback: local activation
    // Create wallet in backend
    try {
      await AgencyApiService().topUp(agencyId, 0);
    } catch (_) {}

    _myShippingAgency = Agency(
      id: agencyId,
      name: _myShippingAgency!.name,
      ownerId: _myShippingAgency!.ownerId,
      description: _myShippingAgency!.description,
      agencyType: AgencyType.charging,
      members: _myShippingAgency!.members,
      totalEarnings: _myShippingAgency!.totalEarnings,
      rating: _myShippingAgency!.rating,
      paymentMethods: ['usdt', 'vodafone', 'bank'],
      chargingPackages: _myShippingAgency!.chargingPackages,
      chargingLogs: [],
      isActivated: true,
    );

    await _repository.updateAgency(_myShippingAgency!);
    notifyListeners();
    return 'success';
  }

  /// Process recharge through the backend (atomic operation)
  Future<Map<String, dynamic>> processRecharge(String targetId, int diamonds) async {
    if (_myShippingAgency == null || !_myShippingAgency!.isActivated) {
      return {'ok': false, 'error': 'الوكالة غير مفعلة'};
    }

    final user = UserController();
    final agencyId = 'AG${user.numericId}';

    try {
      final result = await AgencyApiService().recharge(
        agencyId: agencyId,
        targetUserId: targetId,
        targetNumericId: targetId,
        diamonds: diamonds,
        costDiamonds: diamonds,
      );

      if (result['ok'] == true) {
        _walletBalance = (result['remaining_balance'] as num?)?.toInt() ?? _walletBalance;
        _myShippingAgency!.totalEarnings += diamonds.toDouble();

        _myShippingAgency!.chargingLogs.insert(0, Transaction(
          id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
          targetId: targetId,
          amount: diamonds.toDouble(),
          date: DateTime.now(),
          status: TransactionStatus.completed,
          description: 'شحن وكالة عبر السيرفر',
        ));

        await _repository.updateAgency(_myShippingAgency!);
        notifyListeners();
        return {'ok': true, 'message': 'تم الشحن بنجاح'};
      } else {
        return {'ok': false, 'error': result['error'] ?? 'فشلت العملية'};
      }
    } catch (e) {
      debugPrint('Shipping recharge API failed: $e');
      return {'ok': false, 'error': 'تعذر الاتصال بالسيرفر: $e'};
    }
  }

  /// Process withdrawal through the backend (atomic operation)
  Future<Map<String, dynamic>> processWithdraw(String sourceUserId, int diamonds) async {
    final user = UserController();
    final agencyId = 'AG${user.numericId}';

    try {
      final result = await AgencyApiService().withdraw(
        agencyId: agencyId,
        sourceUserId: sourceUserId,
        sourceNumericId: sourceUserId,
        diamonds: diamonds,
      );

      if (result['ok'] == true) {
        _walletBalance += diamonds;
        notifyListeners();
        return {'ok': true, 'message': 'تم السحب بنجاح'};
      } else {
        return {'ok': false, 'error': result['error'] ?? 'فشلت العملية'};
      }
    } catch (e) {
      debugPrint('Shipping withdraw API failed: $e');
      return {'ok': false, 'error': 'تعذر الاتصال بالسيرفر: $e'};
    }
  }

  Future<void> processChargingTransaction(String targetId, int amount) async {
    if (_myShippingAgency == null || !_myShippingAgency!.isActivated) return;

    final transaction = Transaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      targetId: targetId,
      amount: amount.toDouble(),
      date: DateTime.now(),
      status: TransactionStatus.completed,
      description: 'شحن وكالة - خصم جملة',
    );

    _myShippingAgency!.chargingLogs.add(transaction);
    _myShippingAgency!.totalEarnings += amount.toDouble();

    await _repository.updateAgency(_myShippingAgency!);
    notifyListeners();
  }

  List<Transaction> getChargingLogs() => _myShippingAgency?.chargingLogs ?? [];
}
