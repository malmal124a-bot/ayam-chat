import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';

/// Service for calling the backend Agency API.
/// Every request includes the user's Supabase JWT for authentication.
class AgencyApiService {
  static final AgencyApiService _instance = AgencyApiService._();
  factory AgencyApiService() => _instance;
  AgencyApiService._();

  /// Get current user's access token from Supabase session
  Future<String?> _getToken() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.accessToken;
  }

  /// Make an authenticated GET request
  Future<Map<String, dynamic>> _get(String path, {Map<String, String>? queryParams}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not logged in');

    var uri = Uri.parse('${AppConfig.agencyApi}$path');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    }).timeout(const Duration(seconds: 30));

    if (res.body.isEmpty) throw Exception('API error ${res.statusCode}');
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'API error');
    if (data['ok'] == false) throw Exception(data['error'] ?? 'API error');
    return data;
  }

  /// Make an authenticated POST request
  Future<Map<String, dynamic>> _post(String path, {Map<String, dynamic>? body}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not logged in');

    final uri = Uri.parse('${AppConfig.agencyApi}$path');
    final res = await http.post(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    }, body: body != null ? jsonEncode(body) : null)
        .timeout(const Duration(seconds: 30));

    if (res.body.isEmpty) throw Exception('API error ${res.statusCode}');
    final data = jsonDecode(res.body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(data['error'] ?? 'API error ${res.statusCode}');
    }
    if (data['ok'] == false) throw Exception(data['error'] ?? 'API error');
    return data;
  }

  // ─── Agency Wallet ───

  /// Get agency wallet balance
  Future<Map<String, dynamic>> getWallet(String agencyId) async {
    return _get('/wallet', queryParams: {'agency_id': agencyId});
  }

  /// Top up agency wallet
  Future<Map<String, dynamic>> topUp(String agencyId, int diamonds) async {
    return _post('/topup', body: {
      'agency_id': agencyId,
      'diamonds': diamonds,
    });
  }

  // ─── Recharge ───

  /// Recharge diamonds to a user (agent charges user)
  Future<Map<String, dynamic>> recharge({
    required String agencyId,
    required String targetUserId,
    String? targetNumericId,
    required int diamonds,
    required int costDiamonds,
  }) async {
    return _post('/recharge', body: {
      'agency_id': agencyId,
      'target_user_id': targetUserId,
      'target_numeric_id': targetNumericId,
      'diamonds': diamonds,
      'cost_diamonds': costDiamonds,
    });
  }

  // ─── Withdraw ───

  /// Withdraw diamonds from a user to agency wallet
  Future<Map<String, dynamic>> withdraw({
    required String agencyId,
    required String sourceUserId,
    String? sourceNumericId,
    required int diamonds,
  }) async {
    return _post('/withdraw', body: {
      'agency_id': agencyId,
      'source_user_id': sourceUserId,
      'source_numeric_id': sourceNumericId,
      'diamonds': diamonds,
    });
  }

  // ─── Salary ───

  /// Calculate salaries for agency members
  Future<Map<String, dynamic>> calculateSalary({
    required String agencyId,
    required List<String> userIds,
    String? periodStart,
    String? periodEnd,
  }) async {
    return _post('/salary/calculate', body: {
      'agency_id': agencyId,
      'user_ids': userIds,
      'period_start': periodStart,
      'period_end': periodEnd,
    });
  }

  /// Pay a single salary item
  Future<Map<String, dynamic>> paySalaryItem({
    required String itemId,
    required String agencyId,
  }) async {
    return _post('/salary/pay', body: {
      'item_id': itemId,
      'agency_id': agencyId,
    });
  }

  /// Pay all pending salary items in a run
  Future<Map<String, dynamic>> payAllSalaries({
    required String runId,
    required String agencyId,
  }) async {
    return _post('/salary/pay-all', body: {
      'run_id': runId,
      'agency_id': agencyId,
    });
  }

  // ─── Logs ───

  /// Get recharge logs
  Future<List<dynamic>> getRechargeLogs(String agencyId, {int limit = 50}) async {
    final data = await _get('/logs/recharges', queryParams: {
      'agency_id': agencyId,
      'limit': limit.toString(),
    });
    return data as List<dynamic>? ?? [];
  }

  /// Get withdrawal logs
  Future<List<dynamic>> getWithdrawalLogs(String agencyId, {int limit = 50}) async {
    final data = await _get('/logs/withdrawals', queryParams: {
      'agency_id': agencyId,
      'limit': limit.toString(),
    });
    return data as List<dynamic>? ?? [];
  }

  // ─── Salary Runs ───

  /// Get salary runs
  Future<List<dynamic>> getSalaryRuns(String agencyId) async {
    final data = await _get('/salary/runs', queryParams: {'agency_id': agencyId});
    return data as List<dynamic>? ?? [];
  }

  /// Get salary items for a run
  Future<List<dynamic>> getSalaryItems(String runId) async {
    final data = await _get('/salary/items', queryParams: {'run_id': runId});
    return data as List<dynamic>? ?? [];
  }

  // ─── Members ───

  /// Get agency members
  Future<List<dynamic>> getMembers(String agencyId) async {
    final data = await _get('/members', queryParams: {'agency_id': agencyId});
    return data as List<dynamic>? ?? [];
  }

  /// Invite a user (by numeric id) to join the agency. Sends them a DM.
  Future<Map<String, dynamic>> inviteMember({
    required String agencyId,
    required String targetNumericId,
  }) async {
    return _post('/invite-member', body: {
      'agency_id': agencyId,
      'target_numeric_id': targetNumericId,
    });
  }

  // ─── User Lookup ───

  /// Get a user's balance by ID
  Future<Map<String, dynamic>> getUserBalance(String uid) async {
    return _get('/user/$uid/balance');
  }

  // ─── Open Agency For User ───

  /// Open an agency for a user by their numeric_id (sends notification)
  Future<Map<String, dynamic>> openForUser({
    required String targetNumericId,
    String agencyName = '',
    String agencyType = 'shipping',
  }) async {
    return _post('/open-for-user', body: {
      'target_numeric_id': targetNumericId,
      'agency_name': agencyName,
      'agency_type': agencyType,
    });
  }

  /// Get agency by owner auth_uid from Supabase
  Future<Map<String, dynamic>?> getMyAgency(String ownerUid) async {
    try {
      final data = await _get('/my-agency', queryParams: {'owner_uid': ownerUid});
      return data;
    } catch (e) {
      return null;
    }
  }

  // ─── Host Agency Open Requests (approval-gated) ───

  /// Submit the caller's own hosting-agency open request for admin approval.
  Future<Map<String, dynamic>> submitOpenRequest({
    required String agencyName,
    required String agencyId,
    String phone = '',
    String photoUrl = '',
    String idCardUrl = '',
  }) async {
    return _post('/open-request', body: {
      'agency_name': agencyName,
      'agency_id': agencyId,
      'phone': phone,
      'photo_url': photoUrl,
      'id_card_url': idCardUrl,
    });
  }

  /// Get the caller's latest open request (or null if none).
  Future<Map<String, dynamic>?> getMyOpenRequest() async {
    try {
      final data = await _get('/my-open-request');
      final request = data['request'];
      return request is Map<String, dynamic> ? request : null;
    } catch (e) {
      return null;
    }
  }
}
