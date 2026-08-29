import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../services/agency_api_service.dart';
import '../services/cloudinary_service.dart';
import '../services/supabase_service.dart';

class HostAgencyController extends ChangeNotifier {
  final _client = Supabase.instance.client;
  RealtimeChannel? _agencySubscription;

  // Agency data
  Map<String, dynamic>? _agency;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _joinRequests = [];
  List<Map<String, dynamic>> _giftHistory = [];
  List<Map<String, dynamic>> _rechargeLogs = [];
  List<Map<String, dynamic>> _withdrawalLogs = [];
  Map<String, dynamic>? _wallet;
  Map<String, dynamic>? _selectedMemberDetail;
  Map<String, dynamic>? _openRequest; // agency_open_requests row
  List<Map<String, dynamic>> _openAgencies = []; // browseable open agencies
  List<String> _requestedAgencyIds = []; // agency ids the user already requested
  bool _isLoading = false;
  String? _errorMessage;
  bool _agencyDeleted = false;
  String? _deletionMessage;

  // Getters
  Map<String, dynamic>? get agency => _agency;
  List<Map<String, dynamic>> get members => _members;
  List<Map<String, dynamic>> get joinRequests => _joinRequests;
  List<Map<String, dynamic>> get giftHistory => _giftHistory;
  List<Map<String, dynamic>> get rechargeLogs => _rechargeLogs;
  List<Map<String, dynamic>> get withdrawalLogs => _withdrawalLogs;
  Map<String, dynamic>? get wallet => _wallet;
  Map<String, dynamic>? get selectedMemberDetail => _selectedMemberDetail;
  Map<String, dynamic>? get openRequest => _openRequest;
  String get openRequestStatus => _openRequest?['status']?.toString() ?? 'none';
  bool get hasOpenRequest =>
      _openRequest != null && (_openRequest!['status'] == 'pending');
  bool get openRequestApproved =>
      _openRequest != null && (_openRequest!['status'] == 'approved');
  bool get openRequestRejected =>
      _openRequest != null && (_openRequest!['status'] == 'rejected');
  List<Map<String, dynamic>> get openAgencies => _openAgencies;
  List<String> get requestedAgencyIds => _requestedAgencyIds;
  bool hasRequestedAgency(String agencyId) => _requestedAgencyIds.contains(agencyId);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get agencyDeleted => _agencyDeleted;
  String? get deletionMessage => _deletionMessage;

  int get diamondsBalance => (_wallet?['diamonds_balance'] as num?)?.toInt() ?? 0;
  int get totalRecharged => (_wallet?['total_recharged'] as num?)?.toInt() ?? 0;
  int get totalWithdrawn => (_wallet?['total_withdrawn'] as num?)?.toInt() ?? 0;
  String get agencyName => _agency?['name'] ?? 'وكالة';
  String get agencyType => _agency?['agency_type'] ?? 'mixed';
  bool get isOwner => _agency?['owner_id'] == _client.auth.currentUser?.id;

  HostAgencyController() {
    _loadData();
  }

  void _subscribeToAgencyChanges() async {
    _agencySubscription?.unsubscribe();
    final agencyId = _agency?['id'] as String?;
    if (agencyId == null) return;

    await SupabaseService.ensureValidSession();
    _agencySubscription = _client
        .channel('agency-$agencyId')
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'agencies',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: agencyId,
          ),
          callback: (payload) {
            _agency = null;
            _agencyDeleted = true;
            _deletionMessage = 'تم إغلاق وكالتك بواسطة الإدارة';
            _members.clear();
            _joinRequests.clear();
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'agencies',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: agencyId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            final isActivated = newRecord['is_activated'] as bool? ?? true;
            if (!isActivated) {
              _agency = null;
              _agencyDeleted = true;
              _deletionMessage = 'تم تعطيل وكالتك بواسطة الإدارة';
              _members.clear();
              _joinRequests.clear();
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;

      // Find agency owned by current user
      final agencyData = await _client
          .from('agencies')
          .select('*')
          .eq('owner_id', uid)
          .eq('is_activated', true)
          .maybeSingle();

      if (agencyData == null) {
        // Maybe user is a member of another agency
        final membership = await _client
            .from('host_agency_members')
            .select('agency_id, role')
            .eq('user_id', uid)
            .eq('status', 'active')
            .maybeSingle();

        if (membership != null) {
          final memberAgency = await _client
              .from('agencies')
              .select('*')
              .eq('id', membership['agency_id'])
              .maybeSingle();
          _agency = memberAgency;
        }
      } else {
        _agency = agencyData;
      }

      if (_agency != null) {
        final agencyId = _agency!['id'] as String;

        // Load members with user data
        final membersData = await _client
            .from('host_agency_members')
            .select('*')
            .eq('agency_id', agencyId);

        // Load user data separately for each member
        _members = [];
        for (final m in (membersData as List)) {
          final userId = (m['user_id'] ?? '').toString();
          Map<String, dynamic>? userData;
          if (userId.isNotEmpty) {
            try {
              userData = await _client
                  .from('users')
                  .select('auth_uid, numeric_id, name, photo_url, diamonds, total_recharged')
                  .eq('auth_uid', userId)
                  .maybeSingle();
            } catch (_) {}
          }
          _members.add({
            'id': m['user_id'] ?? '',
            'auth_uid': userData?['auth_uid'] ?? m['user_id'],
            'name': userData?['name'] ?? 'عضو',
            'numeric_id': userData?['numeric_id'] ?? '',
            'photo_url': userData?['photo_url'] ?? '',
            'diamonds': userData?['diamonds'] ?? 0,
            'total_recharged': userData?['total_recharged'] ?? 0,
            'earnings': m['diamonds_earned_cumulative'] ?? 0,
            'monthly_earnings': m['diamonds_earned_monthly'] ?? 0,
            'balance': m['diamonds_balance'] ?? 0,
            'status': m['status'] ?? 'active',
            'role': m['role'] ?? 'host',
            'joined_at': m['joined_at'] ?? '',
            'trial_ends_at': m['trial_ends_at'],
          });
        }

        // Load wallet
        try {
          _wallet = await AgencyApiService().getWallet(agencyId);
        } catch (_) {
          _wallet = {'diamonds_balance': 0, 'total_recharged': 0, 'total_withdrawn': 0};
        }

        // Load join requests (pending + invited)
        final requestsData = await _client
            .from('host_agency_join_requests')
            .select('*, users:users!host_agency_join_requests_user_id_fkey(name, numeric_id, photo_url)')
            .eq('agency_id', agencyId)
            .inFilter('status', ['pending', 'invited']);

        _joinRequests = (requestsData as List).map((r) {
          final user = r['users'] as Map<String, dynamic>?;
          return {
            ...r as Map<String, dynamic>,
            'user_name': user?['name'] ?? 'مستخدم',
            'user_numeric_id': user?['numeric_id'] ?? '',
            'user_photo': user?['photo_url'] ?? '',
          };
        }).toList();

        // Load recharge logs
        final rechargesData = await _client
            .from('agency_recharges')
            .select('*')
            .eq('agency_id', agencyId)
            .order('created_at', ascending: false)
            .limit(50);
        _rechargeLogs = List<Map<String, dynamic>>.from(rechargesData as List);

        // Load withdrawal logs
        final withdrawalsData = await _client
            .from('agency_withdrawals')
            .select('*')
            .eq('agency_id', agencyId)
            .order('created_at', ascending: false)
            .limit(50);
        _withdrawalLogs = List<Map<String, dynamic>>.from(withdrawalsData as List);

        // Load gift history for agency members
        final memberIds = _members.map((m) => m['auth_uid'] as String).toList();
        if (memberIds.isNotEmpty) {
          try {
            final giftsData = await _client
                .from('sent_gifts')
                .select('*')
                .or('sender_id.in.(${memberIds.join(',')}),receiver_id.in.(${memberIds.join(',')})')
                .order('created_at', ascending: false)
                .limit(100);
            _giftHistory = List<Map<String, dynamic>>.from(giftsData as List);
          } catch (_) {
            _giftHistory = [];
          }
        }
      }

      _errorMessage = null;
      _agencyDeleted = false;
      _deletionMessage = null;

      // If user owns no agency, remember their latest open-request status
      // (pending / rejected) so the screen can show the right state.
      if (_agency == null) {
        try {
          _openRequest = await AgencyApiService().getMyOpenRequest();
        } catch (e) {
          _openRequest = null;
        }
        // Also load the list of open agencies the user can browse & join.
        await _fetchOpenAgencies();
      } else {
        _openRequest = null;
      }

      _subscribeToAgencyChanges();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('HostAgencyController: load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchOpenAgencies() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;

      final data = await _client
          .from('agencies')
          .select('id, name, photo_url, description, owner_id, agency_type, created_at')
          .eq('is_activated', true)
          .eq('agency_type', 'hosting')
          .neq('owner_id', uid)
          .order('created_at', ascending: false)
          .limit(50);

      _openAgencies = List<Map<String, dynamic>>.from(data as List);

      // Mark which agencies the user already requested to join
      final requested = await _client
          .from('host_agency_join_requests')
          .select('agency_id')
          .eq('user_id', uid)
          .inFilter('status', ['pending', 'invited']);
      _requestedAgencyIds =
          (requested as List).map((r) => (r['agency_id'] ?? '').toString()).toList();
    } catch (e) {
      debugPrint('HostAgencyController: fetchOpenAgencies error: $e');
    }
    notifyListeners();
  }

  /// Public refresh for the open-agencies browse list.
  Future<void> refreshOpenAgencies() => _fetchOpenAgencies();

  /// Request to join a hosting agency. Returns an error string, or null on success.
  Future<String?> requestJoinAgency(String agencyId) async {
    try {
      await AgencyApiService().requestJoin(agencyId: agencyId);
      if (!_requestedAgencyIds.contains(agencyId)) {
        _requestedAgencyIds.add(agencyId);
      }
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> loadMemberDetail(String memberUserId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load member's gifts (if table exists)
      List<dynamic> gifts = [];
      try {
        gifts = await _client
            .from('sent_gifts')
            .select('*')
            .or('sender_id.eq.$memberUserId,receiver_id.eq.$memberUserId')
            .order('created_at', ascending: false)
            .limit(50);
      } catch (_) {}

      // Load member's recharge records where they were recharged by this agency
      final agencyId = _agency?['id'] as String? ?? '';
      final recharges = await _client
          .from('agency_recharges')
          .select('*')
          .eq('agency_id', agencyId)
          .eq('target_user_id', memberUserId)
          .order('created_at', ascending: false)
          .limit(50);

      // Load member's withdrawals from this agency
      final withdrawals = await _client
          .from('agency_withdrawals')
          .select('*')
          .eq('agency_id', agencyId)
          .eq('source_user_id', memberUserId)
          .order('created_at', ascending: false)
          .limit(50);

      // Load member info
      final userInfo = await _client
          .from('users')
          .select('name, numeric_id, photo_url, diamonds, balance, total_recharged, is_agent')
          .eq('auth_uid', memberUserId)
          .maybeSingle();

      _selectedMemberDetail = {
        'user_id': memberUserId,
        'info': userInfo,
        'gifts': gifts,
        'recharges': recharges,
        'withdrawals': withdrawals,
        'total_gifts_sent': gifts.where((g) => g['sender_id'] == memberUserId).fold<int>(0, (sum, g) => sum + ((g['diamonds'] as num?)?.toInt() ?? 0)),
        'total_gifts_received': gifts.where((g) => g['receiver_id'] == memberUserId).fold<int>(0, (sum, g) => sum + ((g['diamonds'] as num?)?.toInt() ?? 0)),
        'total_recharged': recharges.fold<int>(0, (sum, r) => sum + ((r['diamonds'] as num?)?.toInt() ?? 0)),
        'total_withdrawn': withdrawals.fold<int>(0, (sum, w) => sum + ((w['diamonds'] as num?)?.toInt() ?? 0)),
      };
    } catch (e) {
      debugPrint('loadMemberDetail error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMemberDetail() {
    _selectedMemberDetail = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> approveJoinRequest(String requestId, String userId) async {
    try {
      final agencyId = _agency?['id'] as String?;
      if (agencyId == null) return {'ok': false, 'message': 'لا توجد وكالة'};

      // Add member
      await _client.from('host_agency_members').insert({
        'agency_id': agencyId,
        'user_id': userId,
        'role': 'host',
        'status': 'active',
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Update request status
      await _client
          .from('host_agency_join_requests')
          .update({'status': 'approved'})
          .eq('id', requestId);

      _joinRequests.removeWhere((r) => r['id'] == requestId);
      notifyListeners();

      await _loadData();
      return {'ok': true, 'message': 'تم قبول العضو بنجاح'};
    } catch (e) {
      return {'ok': false, 'message': 'فشل: $e'};
    }
  }

  Future<Map<String, dynamic>> rejectJoinRequest(String requestId) async {
    try {
      await _client
          .from('host_agency_join_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId);

      _joinRequests.removeWhere((r) => r['id'] == requestId);
      notifyListeners();
      return {'ok': true, 'message': 'تم رفض الطلب'};
    } catch (e) {
      return {'ok': false, 'message': 'فشل: $e'};
    }
  }

  Future<Map<String, dynamic>> removeMember(String memberUserId) async {
    try {
      final agencyId = _agency?['id'] as String;
      await _client
          .from('host_agency_members')
          .update({'status': 'kicked'})
          .eq('agency_id', agencyId)
          .eq('user_id', memberUserId);

      _members.removeWhere((m) => m['id'] == memberUserId);
      notifyListeners();
      return {'ok': true, 'message': 'تم إزالة العضو'};
    } catch (e) {
      return {'ok': false, 'message': 'فشل: $e'};
    }
  }

  Future<Map<String, dynamic>> leaveAgency() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return {'ok': false, 'message': 'غير مسجل الدخول'};

      final agencyId = _agency?['id'] as String;
      await _client
          .from('host_agency_members')
          .update({'status': 'left'})
          .eq('agency_id', agencyId)
          .eq('user_id', uid);

      _agency = null;
      _members.clear();
      notifyListeners();
      return {'ok': true, 'message': 'تم الانسحاب من الوكالة'};
    } catch (e) {
      return {'ok': false, 'message': 'فشل: $e'};
    }
  }

  Future<Map<String, dynamic>> transferEarningsToAgent(int diamonds, String targetNumericId) async {
    try {
      final agencyId = _agency?['id'] as String?;
      if (agencyId == null || diamonds <= 0) {
        return {'ok': false, 'message': 'بيانات غير صحيحة'};
      }

      // Find target user
      final targetUser = await _client
          .from('users')
          .select('auth_uid, numeric_id, name')
          .eq('numeric_id', targetNumericId)
          .maybeSingle();

      if (targetUser == null) {
        return {'ok': false, 'message': 'المستخدم غير موجود'};
      }

      final result = await AgencyApiService().recharge(
        agencyId: agencyId,
        targetUserId: targetUser['auth_uid'],
        targetNumericId: targetNumericId,
        diamonds: diamonds,
        costDiamonds: diamonds,
      );

      if (result['ok'] == true) {
        await _loadData();
        return {'ok': true, 'message': 'تم التحويل بنجاح. الرصيد المتبقي: ${result['remaining_balance'] ?? 0}'};
      }

      return {'ok': false, 'message': 'فشل التحويل'};
    } catch (e) {
      return {'ok': false, 'message': 'خطأ: $e'};
    }
  }

  Future<void> refresh() async {
    await _loadData();
  }

  /// Invite another user (by numeric id) to join this agency. The backend
  /// sends them a notification (DM) with the agency & agent name; they can
  /// accept or reject from their agency screen.
  Future<Map<String, dynamic>> inviteMember(String targetNumericId) async {
    final agencyId = _agency?['id'] as String?;
    if (agencyId == null) return {'ok': false, 'message': 'لا توجد وكالة'};
    if (targetNumericId.trim().isEmpty) {
      return {'ok': false, 'message': 'يرجى إدخال آيدي المستخدم'};
    }
    try {
      final result = await AgencyApiService().inviteMember(
        agencyId: agencyId,
        targetNumericId: targetNumericId.trim(),
      );
      if (result['ok'] == true) {
        await _loadData();
        return {'ok': true, 'message': 'تم إرسال الدعوة بنجاح'};
      }
      return {'ok': false, 'message': result['error'] ?? 'فشل إرسال الدعوة'};
    } catch (e) {
      return {'ok': false, 'message': 'حدث خطأ: $e'};
    }
  }

  /// Upload an image (agency photo or ID card) to Cloudinary and return its URL.
  Future<String> uploadImageBytes(
      Uint8List bytes, String fileName, {String folder = 'agency_open'}) async {
    return CloudinaryService.uploadImageBytes(bytes,
        folder: folder, fileName: fileName);
  }

  /// Submit the user's own hosting-agency open request for admin approval.
  Future<Map<String, dynamic>> submitOpenRequest({
    required String agencyName,
    required String agencyId,
    String phone = '',
    String photoUrl = '',
    String idCardUrl = '',
  }) async {
    try {
      final result = await AgencyApiService().submitOpenRequest(
        agencyName: agencyName,
        agencyId: agencyId,
        phone: phone,
        photoUrl: photoUrl,
        idCardUrl: idCardUrl,
      );
      if (result['ok'] == true) {
        await _loadData();
        return {'ok': true, 'message': 'تم إرسال طلبك بنجاح، جاري مراجعة الإدارة'};
      }
      return {'ok': false, 'message': result['error'] ?? 'حدث خطأ، حاول مرة أخرى'};
    } catch (e) {
      return {'ok': false, 'message': 'حدث خطأ: $e'};
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _agencySubscription?.unsubscribe();
    super.dispose();
  }
}
