import 'package:flutter/foundation.dart';
import '../../models/agency_model.dart';
import '../../models/transaction_model.dart' as tx;
import '../repositories/local_agency_repository.dart';
import 'package:ayam_chat/services/agency_id_generator.dart';
import 'package:ayam_chat/controllers/user_controller.dart';
import 'package:ayam_chat/controllers/wallet_controller.dart';
import 'package:easy_localization/easy_localization.dart';

class ShippingAgencyController extends ChangeNotifier {
  // final AgencyRepository _repository;
  final LocalAgencyRepository _repository;

  ShippingAgencyController([LocalAgencyRepository? repository]) 
      : _repository = repository ?? LocalAgencyRepository() {
    debugPrint('Initializing: ShippingAgencyController');
    _loadInitialData();
  }

  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  Agency? _myShippingAgency;
  Agency? get myShippingAgency => _myShippingAgency;

  double get activationRequiredAmount => 100.0;

  Future<void> _loadInitialData() async {
    final user = UserController();
    if (user.isOnline) {
      // Use specifically the charging type
      _myShippingAgency = await _repository.getMyAgency(user.id, type: AgencyType.charging);
      notifyListeners();
    }
  }

  Map<String, dynamic> autoActivateAgency() {
    final wallet = WalletController();
    final user = UserController();
    
    if (wallet.balance.value < activationRequiredAmount) {
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
    if (wallet.balance.value < packageAmount) return 'Insufficient balance.';

    wallet.spendBalance(packageAmount.toDouble());
    
    final agencyId = await AgencyIdGenerator.generateUniqueId();

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

  Future<void> processChargingTransaction(String targetId, int amount) async {
    if (_myShippingAgency == null || !_myShippingAgency!.isActivated) return;

    final transaction = tx.Transaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      targetId: targetId,
      amount: amount.toDouble(),
      date: DateTime.now(),
      status: tx.TransactionStatus.completed,
      description: 'شحن وكالة - خصم جملة',
    );

    _myShippingAgency!.chargingLogs.add(transaction);
    _myShippingAgency!.totalEarnings += amount.toDouble();

    await _repository.updateAgency(_myShippingAgency!);
    notifyListeners();
  }

  List<tx.Transaction> getChargingLogs() => _myShippingAgency?.chargingLogs ?? [];
}
