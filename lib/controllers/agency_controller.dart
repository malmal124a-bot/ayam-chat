import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ayam_chat/models/agency_model.dart';
import 'package:ayam_chat/models/agency_request.dart';
import 'package:ayam_chat/repositories/agency_repository.dart';
import 'package:ayam_chat/repositories/local_agency_repository.dart';
import 'package:ayam_chat/services/agency_api_service.dart';
import 'package:ayam_chat/controllers/user_controller.dart';
import 'package:ayam_chat/controllers/wallet_controller.dart';
import '../models/transaction_model.dart';

class SupporterInfo {
  final String userId;
  final String name;
  final double amount;
  final DateTime lastSupport;

  SupporterInfo({
    required this.userId,
    required this.name,
    required this.amount,
    required this.lastSupport,
  });
}

class AgencyController extends ChangeNotifier {
  final AgencyRepository _repository;

  AgencyController([AgencyRepository? repository]) : _repository = repository ?? LocalAgencyRepository() {
    debugPrint('Initializing: AgencyController (Modife System)');
    _loadInitialData();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Agency> _agencies = [];
  List<AgencyInvitation> _invitations = [];
  List<AgencyJoinRequest> _joinRequests = [];
  Agency? _myOwnedAgency;
  Agency? _joinedAgency;
  Agency? _searchedAgency;

  Agency? get myAgency => _myOwnedAgency;
  Agency? get joinedAgency => _joinedAgency;
  Agency? get searchedAgency => _searchedAgency;
  List<Agency> get agencies => _agencies;
  List<AgencyInvitation> get invitations => _invitations;
  List<AgencyJoinRequest> get joinRequests => _joinRequests;

  // Modife Specific Targets & Earnings
  double hostMonthlyTarget = 50000.0;
  double agencyMonthlyTarget = 500000.0;

  double get hostCurrentProgress {
    final user = UserController();
    if (_joinedAgency != null) {
      try {
        final member = _joinedAgency!.members.firstWhere((m) => m.userId == user.id);
        return member.earnings;
      } catch (_) {}
    }
    return _hostEarnings[user.id] ?? 0.0;
  }

  double get agencyCurrentProgress {
    if (_myOwnedAgency == null) return 0.0;
    return _myOwnedAgency!.totalEarnings;
  }

  // Dummy earnings storage for users not in agencies or for fallback
  final Map<String, double> _hostEarnings = {};

  void _deductEarnings(String userId, double amount) {
    bool deducted = false;
    if (_joinedAgency != null) {
      try {
        final member = _joinedAgency!.members.firstWhere((m) => m.userId == userId);
        member.earnings -= amount;
        _repository.updateAgency(_joinedAgency!);
        deducted = true;
      } catch (_) {}
    }
    
    if (!deducted) {
      _hostEarnings[userId] = (hostCurrentProgress) - amount;
    }
    notifyListeners();
  }

  // Task 1: Search Agency by 4-digit code
  Future<void> searchAgencyByCode(String code) async {
    _isLoading = true;
    _searchedAgency = null;
    notifyListeners();

    try {
      final result = await _repository.getAgencyById(code);
      if (result != null && result.agencyType == AgencyType.modife) {
        _searchedAgency = result;
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchedAgency = null;
    notifyListeners();
  }

  // Task 3: Swap Diamonds (Points to Diamonds)
  Map<String, dynamic> swapDiamonds(int amount) {
    final user = UserController();
    final wallet = WalletController();
    double currentEarnings = hostCurrentProgress;

    if (amount > currentEarnings) {
      return {'ok': false, 'message': 'الرصيد غير كافٍ للتبديل'};
    }

    wallet.addDiamonds(amount);
    _deductEarnings(user.id, amount.toDouble());

    return {
      'ok': true,
      'message': 'تم تبديل $amount نقطة بـ $amount ماسة بنجاح'
    };
  }

  // Alias for backward compatibility
  Map<String, dynamic> swapCoins(int amount) => swapDiamonds(amount);

  // Task 3: Withdraw (Points to Wallet Balance) - ONLY if target reached
  Map<String, dynamic> withdrawEarnings(double amount) {
    final user = UserController();
    final wallet = WalletController();
    double currentEarnings = hostCurrentProgress;

    if (currentEarnings < hostMonthlyTarget) {
      return {
        'ok': false,
        'message': 'يجب الوصول للتارجت الشهري (${hostMonthlyTarget.toInt()}) لتتمكن من الفك (سحب الرصيد)'
      };
    }

    if (amount > currentEarnings || amount <= 0) {
      return {'ok': false, 'message': 'الرصيد غير كافٍ للسحب'};
    }

    double netAmount = amount * 0.90; // 10% commission
    wallet.addBalance(netAmount, description: 'فك تارجت موديف (خصم 10% عمولة)');
    _deductEarnings(user.id, amount);

    return {
      'ok': true,
      'message': 'تم فك $amount نقطة بنجاح. تم إضافة $netAmount\$ إلى محفظتك بعد خصم عمولة 10%.',
      'net': netAmount
    };
  }

  // IMPLEMENT: Withdraw full target
  Future<Map<String, dynamic>> withdrawTarget() async {
    return withdrawEarnings(hostCurrentProgress);
  }

  // IMPLEMENT: Sell target points to shipping agent
  Future<Map<String, dynamic>> sellTargetToAgent(double amount) async {
    final user = UserController();
    final wallet = WalletController();
    double currentEarnings = hostCurrentProgress;

    if (amount > currentEarnings || amount <= 0) {
      return {'ok': false, 'message': 'النقاط غير كافية للبيع'};
    }

    // Process: Convert points to liquidity for the agency system (1000 points = 1 USD)
    double usdValue = amount / 1000;
    
    _deductEarnings(user.id, amount);
    
    // Host gets paid in wallet balance
    wallet.addBalance(usdValue, description: 'بيع تارجت لوكيل الشحن');
    
    // Add to global agency balance liquidity
    wallet.addAgencyBalance(usdValue, description: 'شحن وكالة - شراء تارجت من الموديف: ${user.name}');

    // Record in local agency charging logs if user owns an agency
    if (_myOwnedAgency != null) {
      final tx = Transaction(
        id: 'sale_${DateTime.now().millisecondsSinceEpoch}',
        targetId: 'Agent',
        amount: usdValue,
        date: DateTime.now(),
        status: TransactionStatus.completed,
        description: 'بيع تارجت من الهوست: ${user.name}',
      );
      _myOwnedAgency!.chargingLogs.insert(0, tx);
      await _repository.updateAgency(_myOwnedAgency!);
    }

    return {
      'ok': true,
      'message': 'تم بيع $amount نقطة لوكيل الشحن بنجاح مقابل $usdValue\$.',
    };
  }

  Future<void> getPendingRequests() async {
    notifyListeners();
  }

  Future<void> approveRequest(String id) async {
    notifyListeners();
  }

  Future<void> rejectRequest(String id) async {
    notifyListeners();
  }

  Future<void> verifyRequest(String id) async {
    notifyListeners();
  }

  Future<void> chargeAgency() async {
    notifyListeners();
  }

  Future<void> getCharging() async {
    notifyListeners();
  }

  // Compatibility helpers and other methods

  // Used by admin_dashboard_screen.dart and admin_agency_requests_screen.dart
  List<dynamic> get pendingRequests => _repository.pendingRequests;

  Future<void> denyRequest(dynamic idOrRequest) {
    final String id = idOrRequest is AgencyRequest ? idOrRequest.userId : idOrRequest.toString();
    return rejectRequest(id);
  }

  Agency? findAgencyById(String id) {
    try {
      return _agencies.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<String> uploadCardImage(File file, bool isFront) async {
    return await _repository.uploadIdCardImage(file, isFront);
  }

  Future<void> activateAgency(int amount) async {
    notifyListeners();
  }

  List<AgencyJoinRequest> getPendingJoinRequestsForAgency(String agencyId) {
    return _joinRequests.where((r) => r.agencyId == agencyId).toList();
  }

  Future<void> sendInvite(String userId) async {
    if (_myOwnedAgency == null) return;
    final invite = AgencyInvitation(
      agencyId: _myOwnedAgency!.id,
      agencyName: _myOwnedAgency!.name,
      inviterId: UserController().id,
      modifeId: userId,
      timestamp: DateTime.now(),
    );
    await _repository.sendInvitation(invite);
    notifyListeners();
  }

  Future<void> processChargingTransaction(String targetId, int amount) async {
    notifyListeners();
  }

  List<dynamic> getChargingLogs() {
    return _myOwnedAgency?.chargingLogs ?? [];
  }

  // --- INTERNAL LOGIC ---

  Future<void> _loadInitialData() async {
    try {
      _isLoading = true;
      notifyListeners();
      await refreshAgencies();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAgencies() async {
    try {
      _agencies = await _repository.getAgencies();
      final user = UserController();
      if (user.isOnline) {
        // Try Supabase first
        try {
          final agencyData = await AgencyApiService().getMyAgency(user.id);
          if (agencyData != null && _myOwnedAgency == null) {
            _myOwnedAgency = Agency(
              id: agencyData['id'] ?? '',
              name: agencyData['name'] ?? '',
              ownerId: agencyData['owner_id'] ?? user.id,
              description: agencyData['description'] ?? '',
              agencyType: AgencyType.modife,
              isActivated: agencyData['is_activated'] ?? false,
              totalEarnings: (agencyData['total_earnings'] as num?)?.toDouble() ?? 0,
            );
            if (!user.isAgent) user.toggleAgentStatus(true);
          }
        } catch (_) {}

        _myOwnedAgency ??= await _repository.getMyAgency(user.id, type: AgencyType.modife);

        try {
          _joinedAgency = _agencies.firstWhere(
                (a) => a.members.any((m) => m.userId == user.id),
          );
        } catch (_) {
          _joinedAgency = null;
        }

        if (_myOwnedAgency != null) {
          _joinRequests = await _repository.getJoinRequests(_myOwnedAgency!.id);
        }
        _invitations = await _repository.getInvitations(user.id);
      }
    } catch (e) {
      debugPrint('Error refreshing modife agencies: $e');
    }
    notifyListeners();
  }

  Future<void> requestToJoinAgency(String agencyId) async {
    final user = UserController();
    final request = AgencyJoinRequest(
      userId: user.id,
      userName: user.name,
      agencyId: agencyId,
      timestamp: DateTime.now(),
    );
    await _repository.sendJoinRequest(request);
    await refreshAgencies();
  }

  Future<void> respondToJoinRequest(AgencyJoinRequest request, bool approve) async {
    await _repository.respondToJoinRequest(request.userId, approve);
    if (approve) {
      if (_myOwnedAgency != null) {
        _myOwnedAgency!.members.add(AgencyMember(
          userId: request.userId,
          name: request.userName,
          joinDate: DateTime.now().toString(),
        ));
        await _repository.updateAgency(_myOwnedAgency!);
      }
    }
    await refreshAgencies();
  }

  Future<void> submitAgencyRequest({
    required String agencyName,
    required String personalName,
    required String nationalId,
    required String phoneNumber,
    required String whatsappLink,
    required String idCardFrontUrl,
    required String idCardBackUrl,
    String email = '',
    String contactInfo = '',
    String description = '',
    int? selectedTier,
  }) async {
    final request = AgencyRequest(
      userId: UserController().id,
      agencyName: agencyName,
      personalName: personalName,
      email: email,
      nationalId: nationalId,
      phoneNumber: phoneNumber,
      whatsappLink: whatsappLink,
      contactInfo: contactInfo.isEmpty ? phoneNumber : contactInfo,
      description: description,
      idCardFrontUrl: idCardFrontUrl,
      idCardBackUrl: idCardBackUrl,
      selectedTier: selectedTier,
    );
    await _repository.submitAgencyRequest(request);
    notifyListeners();
  }

  List<SupporterInfo> getSupporters(String hostId) {
    return [
      SupporterInfo(userId: '101', name: 'الداعم الأول', amount: 5000, lastSupport: DateTime.now()),
      SupporterInfo(userId: '102', name: 'الداعم الثاني', amount: 3000, lastSupport: DateTime.now().subtract(const Duration(hours: 5))),
      SupporterInfo(userId: '103', name: 'الداعم الثالث', amount: 1500, lastSupport: DateTime.now().subtract(const Duration(days: 1))),
    ];
  }
}
