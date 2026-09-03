import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../services/agency_api_service.dart';
import '../services/cloudinary_service.dart';
import '../services/supabase_service.dart';

class HostAgencyController extends ChangeNotifier {
  final _client = Supabase.instance.client;
  RealtimeChannel? _agencySubscription;
  RealtimeChannel? _openRequestSubscription;
  RealtimeChannel? _memberSubscription;

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
  List<Map<String, dynamic>> _incomingInvites = []; // invites addressed to me
  bool _isLoading = false;
  String? _errorMessage;
  bool _agencyDeleted = false;
  String? _deletionMessage;
  List<Map<String, dynamic>> _profitLevels = [];

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
  List<Map<String, dynamic>> get incomingInvites => _incomingInvites;
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

  /// The current user's own membership row (owner or host) inside the agency.
  Map<String, dynamic>? get currentMember {
    final uid = _client.auth.currentUser?.id;
    for (final m in _members) {
      if (m['auth_uid'] == uid) return m;
    }
    return null;
  }

  /// Current user's withdrawable earnings balance.
  int get myBalance => (currentMember?['balance'] as num?)?.toInt() ?? diamondsBalance;

  /// Current user's cumulative gift earnings (used to advance level targets).
  int get myCumulativeEarnings =>
      (currentMember?['earnings'] as num?)?.toInt() ?? myBalance;

  /// All profit levels from the board (loaded in _loadData).
  List<Map<String, dynamic>> get profitLevels => _profitLevels;

  /// Current user's target for the current level.
  int get myTarget => (currentMember?['target'] as num?)?.toInt() ?? 5000;

  /// Current user's level.
  int get myLevel => (currentMember?['level'] as num?)?.toInt() ?? 1;

  /// How much remains until the next level target is met.
  int get myRemaining => (myTarget - myBalance) < 0 ? 0 : (myTarget - myBalance);

  double get myProgress =>
      myTarget <= 0 ? 0 : ((myBalance / myTarget).clamp(0.0, 1.0)).toDouble();

  /// Aggregated agency earnings (sum over active members).
  int get agencyTotalEarnings =>
      _members.fold<int>(0, (s, m) => s + (((m['earnings'] ?? m['monthly_earnings']) as num?)?.toInt() ?? 0));
  int get agencyMonthlyEarnings =>
      _members.fold<int>(0, (s, m) => s + (((m['monthly_earnings']) as num?)?.toInt() ?? 0));
  int get agencyWithdrawableBalance =>
      _members.fold<int>(0, (s, m) => s + (((m['balance']) as num?)?.toInt() ?? 0));
  int get agencyMemberCount => _members.length;

  /// The agency's profit level resolved from its total cumulative earnings.
  Map<String, dynamic>? get agencyLevel => _resolveProfitLevel(agencyTotalEarnings);

  int get agencyLevelNumber => (agencyLevel?['level'] as num?)?.toInt() ?? 1;
  int get agencyTarget => (agencyLevel?['target'] as num?)?.toInt() ?? 5000;
  double? get agencyProfitPercent =>
      (((agencyLevel?['level_row'] as Map<String, dynamic>?)?['profit_percent']) as num?)?.toDouble();
  double get agencyTargetProgress =>
      agencyTarget <= 0 ? 0 : ((agencyTotalEarnings / agencyTarget).clamp(0.0, 1.0)).toDouble();

  /// Resolves the achieved profit level for a cumulative-earnings value from
  /// the loaded `host_profit_levels` (mirrors `_recomputeHostLevel`).
  Map<String, dynamic>? _resolveProfitLevel(int cumulative) {
    try {
      if (_profitLevels.isEmpty) return null;
      Map<String, dynamic>? achieved;
      int lvl = (_profitLevels.first['sort_order'] as num?)?.toInt() ?? 1;
      int target = (_profitLevels.first['target'] as num?)?.toInt() ?? (lvl * 5000);
      for (final l in _profitLevels) {
        final min = (l['min_cumulative_coins'] as num?)?.toInt() ?? 0;
        if (cumulative >= min) {
          lvl = (l['sort_order'] as num?)?.toInt() ?? lvl;
          target = (l['target'] as num?)?.toInt() ?? (lvl * 5000);
          achieved = l;
        }
      }
      return {'level': lvl, 'target': target, 'level_row': achieved};
    } catch (_) {
      return null;
    }
  }

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

  void _subscribeToOpenRequestChanges() {
    _openRequestSubscription?.unsubscribe();
    final uid = _client.auth.currentUser?.id;
    if (uid == null || _agency != null) return; // only listen if user has no agency

    _openRequestSubscription = _client
        .channel('agency_open_requests_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'agency_open_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'requested_by',
            value: uid,
          ),
          callback: (payload) async {
            final newStatus = payload.newRecord['status']?.toString();
            if (newStatus == 'approved') {
              // Admin approved — reload everything to show the new agency
              await _loadData();
            } else if (newStatus == 'rejected') {
              _openRequest = {
                ...?_openRequest,
                ...payload.newRecord,
              };
              notifyListeners();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'agency_open_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'requested_by',
            value: uid,
          ),
          callback: (payload) async {
            _openRequest = payload.newRecord as Map<String, dynamic>;
            notifyListeners();
          },
        )
        .subscribe();
  }

  /// Refreshes data whenever THIS user's own agency membership row changes
  /// (e.g. after a gift credits their earnings, level or target). This keeps
  /// the "أرباحي" screen in sync instead of showing stale cached values.
  void _subscribeToMemberChanges() async {
    _memberSubscription?.unsubscribe();
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await SupabaseService.ensureValidSession();
    _memberSubscription = _client
        .channel('agency-member-$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'host_agency_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (_) => _loadData(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'host_agency_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (_) => _loadData(),
        )
        .subscribe();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;

      // Load profit levels (used to resolve the agency's level/target).
      try {
        _profitLevels = List<Map<String, dynamic>>.from(
            await _client.from('host_profit_levels').select('*').order('sort_order'));
      } catch (_) {
        _profitLevels = [];
      }

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
            .eq('agency_id', agencyId)
            .eq('status', 'active');

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
          final cumulativeEarnings = (m['diamonds_earned_cumulative'] as num?)?.toInt() ?? 0;
          final memberLevelRes = _resolveProfitLevel(cumulativeEarnings);
          final resLevel = (memberLevelRes?['level'] as num?)?.toInt()
              ?? (m['level'] as num?)?.toInt() ?? 1;
          final resTarget = (memberLevelRes?['target'] as num?)?.toInt()
              ?? (m['target'] as num?)?.toInt() ?? 5000;
          _members.add({
            'id': m['user_id'] ?? '',
            'auth_uid': userData?['auth_uid'] ?? m['user_id'],
            'name': userData?['name'] ?? 'عضو',
            'numeric_id': userData?['numeric_id'] ?? '',
            'photo_url': userData?['photo_url'] ?? '',
            'diamonds': userData?['diamonds'] ?? 0,
            'total_recharged': userData?['total_recharged'] ?? 0,
            'earnings': cumulativeEarnings,
            'monthly_earnings': m['diamonds_earned_monthly'] ?? 0,
            'balance': m['diamonds_balance'] ?? 0,
            'status': m['status'] ?? 'active',
            'role': m['role'] ?? 'host',
            'joined_at': m['joined_at'] ?? '',
            'trial_ends_at': m['trial_ends_at'],
            'target': resTarget,
            'level': resLevel,
            'period_type': m['period_type'] ?? 'weekly',
            'shipping_agent_id': m['shipping_agent_id'],
            'shipping_agent_name': m['shipping_agent_name'] ?? '',
          });
        }

        // Load wallet
        try {
          _wallet = await AgencyApiService().getWallet(agencyId);
        } catch (_) {
          _wallet = {'diamonds_balance': 0, 'total_recharged': 0, 'total_withdrawn': 0};
        }

        // Load join requests (pending only). Invites the owner sent are NOT
        // shown in the owner's queue: they are delivered to the invitee, who
        // accepts or declines them on their own side.
        final requestsData = await _client
            .from('host_agency_join_requests')
            .select('*')
            .eq('agency_id', agencyId)
            .eq('status', 'pending');

        final List<Map<String, dynamic>> enrichedRequests = [];
        for (final r in (requestsData as List)) {
          final userId = (r['user_id'] ?? '').toString();
          Map<String, dynamic>? userData;
          if (userId.isNotEmpty) {
            try {
              userData = await _client
                  .from('users')
                  .select('name, numeric_id, photo_url')
                  .eq('auth_uid', userId)
                  .maybeSingle();
            } catch (_) {}
          }
          enrichedRequests.add({
            ...r as Map<String, dynamic>,
            'user_name': userData?['name'] ?? 'مستخدم',
            'user_numeric_id': userData?['numeric_id'] ?? '',
            'user_photo': userData?['photo_url'] ?? '',
          });
        }
        _joinRequests = enrichedRequests;

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
      } else {
        _openRequest = null;
      }

      // Non-owners (users who own no agency, OR are a member of one) can
      // browse the open agencies on the system. Load the list for them so it
      // shows even when the user already belongs to an agency.
      if (!isOwner) {
        await _fetchOpenAgencies();
      }

      // Load invites addressed TO me (sent by an agency owner). These are
      // accepted/declined by ME (the invitee), not by the owner. Loaded for
      // every non-owner so a member can still accept/decline new invites.
      if (!isOwner) {
        try {
          final invites = await _client
              .from('host_agency_join_requests')
              .select('*')
              .eq('user_id', uid)
              .eq('status', 'invited')
              .order('created_at', ascending: false);
          final List<Map<String, dynamic>> enriched = [];
          for (final r in (invites as List)) {
            final agencyId = (r['agency_id'] ?? '').toString();
            Map<String, dynamic>? ag;
            try {
              ag = await _client
                  .from('agencies')
                  .select('name, photo_url, owner_id')
                  .eq('id', agencyId)
                  .maybeSingle();
            } catch (_) {}
            enriched.add({
              ...r as Map<String, dynamic>,
              'agency_name': ag?['name'] ?? '',
              'agency_photo': ag?['photo_url'] ?? '',
              'owner_id': ag?['owner_id'] ?? '',
            });
          }
          _incomingInvites = enriched;
        } catch (_) {
          _incomingInvites = [];
        }
      } else {
        _incomingInvites = [];
      }

      _subscribeToAgencyChanges();
      _subscribeToOpenRequestChanges();
      _subscribeToMemberChanges();

      // Owner loads pending withdrawal + leave requests for approval.
      if (_agency != null && isOwner) {
        await loadAgencyRequests();
      }
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
          .neq('owner_id', uid)
          // Include ALL agency types. The schema default is 'modife' and many
          // open agencies are stored under that value — filtering to only
          // hosting/shipping/mixed silently hid them from the browse list.
          .inFilter('agency_type', ['modife', 'hosting', 'shipping', 'mixed'])
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

  /// Respond to an invite sent TO me. When accepted, the join request becomes
  /// 'approved' and the user is inserted as a member of the agency.
  Future<String?> respondInvite(String requestId, String agencyId, bool accept) async {
    try {
      if (accept) {
        final row = await _client
            .from('host_agency_join_requests')
            .select('agency_id')
            .eq('id', requestId)
            .maybeSingle();
        if (row == null) return 'الدعوة لم تعد موجودة';
        final targetAgency = (row['agency_id'] ?? agencyId).toString();

        final owner = await _client
            .from('agencies')
            .select('owner_id')
            .eq('id', targetAgency)
            .maybeSingle();
        final uid = _client.auth.currentUser?.id ?? '';
        await _client.from('host_agency_members').insert({
          'agency_id': targetAgency,
          'user_id': uid,
          'owner_id': owner?['owner_id'],
          'role': 'host',
          'status': 'active',
        });
        await _client
            .from('host_agency_join_requests')
            .update({'status': 'approved'})
            .eq('id', requestId);
      } else {
        await _client
            .from('host_agency_join_requests')
            .update({'status': 'declined'})
            .eq('id', requestId);
      }
      _incomingInvites.removeWhere((r) => (r['id'] ?? '').toString() == requestId);
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

  /// Send diamonds (shipment) to a user from this agency's wallet.
  /// The target is identified by their numeric id. `diamonds` is what the user
  /// receives; `cost` (default = diamonds) is what is deducted from the wallet.
  Future<Map<String, dynamic>> rechargeUser(
      String targetNumericId, int diamonds, {int? cost}) async {
    final agencyId = _agency?['id'] as String?;
    if (agencyId == null) return {'ok': false, 'message': 'لا توجد وكالة'};
    if (targetNumericId.trim().isEmpty || diamonds <= 0) {
      return {'ok': false, 'message': 'يرجى إدخال آيدي المستخدم وعدد الماس'};
    }
    final costDiamonds = (cost ?? diamonds) <= 0 ? diamonds : (cost ?? diamonds);
    try {
      // Resolve the target user's auth_uid from their numeric id
      final target = await _client
          .from('users')
          .select('auth_uid')
          .eq('numeric_id', targetNumericId.trim())
          .maybeSingle();
      if (target == null) {
        return {'ok': false, 'message': 'المستخدم غير موجود'};
      }
      final result = await AgencyApiService().recharge(
        agencyId: agencyId,
        targetUserId: target['auth_uid'],
        targetNumericId: targetNumericId.trim(),
        diamonds: diamonds,
        costDiamonds: costDiamonds,
      );
      if (result['ok'] == true) {
        await _loadData();
        return {
          'ok': true,
          'message':
              'تم شحن ${result['diamonds_charged'] ?? diamonds} ماس للمستخدم',
        };
      }
      return {'ok': false, 'message': result['error'] ?? 'فشل الشحن'};
    } catch (e) {
      return {'ok': false, 'message': 'خطأ: $e'};
    }
  }

  /// Record/pay salaries for a shipping agency (full run). Calculates a salary
  /// run for the given members, then pays all items in the run.
  Future<Map<String, dynamic>> paySalaries(List<String> memberUserIds) async {
    final agencyId = _agency?['id'] as String?;
    if (agencyId == null) return {'ok': false, 'message': 'لا توجد وكالة'};
    if (memberUserIds.isEmpty) {
      return {'ok': false, 'message': 'لا يوجد أعضاء لصرف رواتبهم'};
    }
    try {
      // 1. Calculate the salary run
      final calc = await AgencyApiService().calculateSalary(
        agencyId: agencyId,
        userIds: memberUserIds,
      );
      if (calc['ok'] == false || calc['data'] == null) {
        return {'ok': false, 'message': calc['error'] ?? 'فشل حساب الرواتب'};
      }
      final run = (calc['data'] ?? calc) as Map<String, dynamic>;
      final runId = run['id'] ?? run['run_id'];
      if (runId == null) {
        return {'ok': false, 'message': 'تعذر إنشاء جولة الرواتب'};
      }
      // 2. Pay all items in the run
      final pay = await AgencyApiService().payAllSalaries(
        runId: runId,
        agencyId: agencyId,
      );
      if (pay['ok'] == true) {
        await _loadData();
        return {'ok': true, 'message': 'تم صرف الرواتب بنجاح'};
      }
      return {'ok': false, 'message': pay['error'] ?? 'فشل صرف الرواتب'};
    } catch (e) {
      return {'ok': false, 'message': 'خطأ: $e'};
    }
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

  // ════════════════════════════════════════════════════════════
  // EARNINGS / LEVEL / WITHDRAW / LEAVE / TRANSFER
  // ════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _withdrawRequests = [];
  List<Map<String, dynamic>> _leaveRequests = [];
  List<Map<String, dynamic>> _transferRequests = [];

  List<Map<String, dynamic>> get withdrawRequests => _withdrawRequests;
  List<Map<String, dynamic>> get leaveRequests => _leaveRequests;
  List<Map<String, dynamic>> get transferRequests => _transferRequests;

  String? get shippingAgentId => _members
      .where((m) => m['auth_uid'] == _client.auth.currentUser?.id)
      .map((m) => m['shipping_agent_id']?.toString())
      .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);

  /// Member requests to withdraw their current earnings balance.
  Future<Map<String, dynamic>> requestSalaryWithdrawal() async {
    try {
      final result = await AgencyApiService().requestWithdrawal();
      await _loadData();
      return {'ok': result['ok'] == true, 'message': result['error'] ?? 'تم إرسال طلب السحب، بانتظار موافقة الوكيل'};
    } catch (e) {
      return {'ok': false, 'message': 'خطأ: $e'};
    }
  }

  /// Agent/owner: loads pending withdrawal + leave requests for the agency.
  Future<void> loadAgencyRequests() async {
    final agencyId = _agency?['id'] as String?;
    if (agencyId == null) return;
    try {
      _withdrawRequests = (await AgencyApiService().getWithdrawalRequests(agencyId))
          .map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) { _withdrawRequests = []; }
    try {
      _leaveRequests = (await AgencyApiService().getLeaveRequests(agencyId))
          .map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) { _leaveRequests = []; }
    notifyListeners();
  }

  /// Agent/owner: approve a member's salary-withdrawal request.
  Future<Map<String, dynamic>> approveWithdrawal(String requestId) async {
    try {
      final result = await AgencyApiService().approveWithdrawal(requestId);
      if (result['ok'] == true) {
        await loadAgencyRequests();
        return {'ok': true, 'message': 'تمت الموافقة على سحب الراتب'};
      }
      return {'ok': false, 'message': result['error'] ?? 'فشل الموافقة'};
    } catch (e) {
      return {'ok': false, 'message': 'خطأ: $e'};
    }
  }

  /// Agent/owner: reject a member's salary-withdrawal request.
  Future<Map<String, dynamic>> rejectWithdrawal(String requestId) async {
    try {
      final result = await AgencyApiService().rejectWithdrawal(requestId);
      if (result['ok'] == true) {
        await loadAgencyRequests();
        return {'ok': true, 'message': 'تم رفض طلب السحب'};
      }
      return {'ok': false, 'message': result['error'] ?? 'فشل الرفض'};
    } catch (e) {
      return {'ok': false, 'message': 'خطأ: $e'};
    }
  }

  /// Agent/owner: accept (or reject) a member's agency-leave request.
  Future<Map<String, dynamic>> respondLeave(String requestId, bool approve) async {
    try {
      final result = await AgencyApiService().respondLeave(requestId, approve: approve);
      if (result['ok'] == true) {
        await loadAgencyRequests();
        return {'ok': true, 'message': approve ? 'تم قبول الانسحاب من الوكالة' : 'تم رفض الانسحاب'};
      }
      return {'ok': false, 'message': result['error'] ?? 'فشل تنفيذ الطلب'};
    } catch (e) {
      return {'ok': false, 'message': 'خطأ: $e'};
    }
  }

  /// Member requests to leave the agency (needs agent approval).
  Future<Map<String, dynamic>> requestLeaveAgency() async {
    try {
      final result = await AgencyApiService().requestLeave();
      if (result['ok'] == true) {
        return {'ok': true, 'message': 'تم إرسال طلب الانسحاب، بانتظار موافقة الوكيل'};
      }
      return {'ok': false, 'message': result['error'] ?? 'فشل إرسال الطلب'};
    } catch (e) {
      return {'ok': false, 'message': 'خطأ: $e'};
    }
  }

  /// Member sets their shipping agent (by numeric id).
  Future<Map<String, dynamic>> setMyShippingAgent(String numericId) async {
    try {
      final result = await AgencyApiService().setShippingAgent(numericId.trim());
      if (result['ok'] == true) {
        await _loadData();
        return {'ok': true, 'message': 'تم ربط وكيل الشحن بنجاح'};
      }
      return {'ok': false, 'message': result['error'] ?? 'فشل ربط الوكيل'};
    } catch (e) {
      return {'ok': false, 'message': 'خطأ: $e'};
    }
  }

  /// Member requests a transfer of `amount` to their shipping agent.
  Future<Map<String, dynamic>> requestTransfer(int amount) async {
    try {
      final result = await AgencyApiService().requestTransfer(amount);
      if (result['ok'] == true) {
        await _loadData();
        return {'ok': true, 'message': 'تم إرسال طلب التحويل، بانتظار موافقة وكيل الشحن'};
      }
      return {'ok': false, 'message': result['error'] ?? 'فشل إرسال التحويل'};
    } catch (e) {
      return {'ok': false, 'message': 'خطأ: $e'};
    }
  }

  /// Shipping agent: loads transfer requests addressed to them.
  Future<void> loadMyTransferRequests() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;
      _transferRequests = (await AgencyApiService().getTransferRequests(forUserId: uid))
          .map((e) => Map<String, dynamic>.from(e as Map)).toList();
      notifyListeners();
    } catch (_) {}
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _agencySubscription?.unsubscribe();
    _openRequestSubscription?.unsubscribe();
    _memberSubscription?.unsubscribe();
    super.dispose();
  }
}
