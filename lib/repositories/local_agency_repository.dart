import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/agency_model.dart';
import '../models/agency_request.dart';
import 'agency_repository.dart';
import '../controllers/wallet_controller.dart';
import '../services/cloudinary_service.dart';

class LocalAgencyRepository implements AgencyRepository {
  static const String _agenciesKey = 'local_agencies';
  static const String _requestsKey = 'agency_requests';
  static const String _invitationsKey = 'agency_invitations';
  static const String _joinRequestsKey = 'agency_join_requests';

  List<Agency> _agencies = [];
  final List<AgencyRequest> _creationRequests = [];
  final List<AgencyInvitation> _invitations = [];
  final List<AgencyJoinRequest> _joinRequests = [];
  
  final List<dynamic> _pendingRequests = [];
  final List<dynamic> _members = [];
  bool _isUnlocked = false;

  LocalAgencyRepository() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final agenciesJson = prefs.getStringList(_agenciesKey);
      if (agenciesJson != null) {
        _agencies = agenciesJson.map((json) => Agency.fromJson(jsonDecode(json))).toList();
      } else {
        _agencies = [
          Agency(id: '1001', name: 'Elite Charging Agency', ownerId: '101', description: 'Fast and reliable charging services', agencyType: AgencyType.charging),
          Agency(id: '1002', name: 'Arab Falcons', ownerId: '102', description: 'Join the best modife agency', agencyType: AgencyType.modife),
          Agency(id: '1003', name: 'Ayam Team Hosting', ownerId: '103', description: 'Official moderator agency', agencyType: AgencyType.modife),
        ];
      }

      final requestsJson = prefs.getStringList(_requestsKey);
      if (requestsJson != null) {
        _creationRequests.clear();
        _creationRequests.addAll(requestsJson.map((json) => AgencyRequest.fromJson(jsonDecode(json))));
        _pendingRequests.clear();
        _pendingRequests.addAll(_creationRequests.where((r) => r.status == AgencyRequestStatus.pending));
      }

      final invitationsJson = prefs.getStringList(_invitationsKey);
      if (invitationsJson != null) {
        _invitations.clear();
        _invitations.addAll(invitationsJson.map((json) => AgencyInvitation.fromJson(jsonDecode(json))));
      }

      final joinRequestsJson = prefs.getStringList(_joinRequestsKey);
      if (joinRequestsJson != null) {
        _joinRequests.clear();
        _joinRequests.addAll(joinRequestsJson.map((json) => AgencyJoinRequest.fromJson(jsonDecode(json))));
      }
      
      _isUnlocked = WalletController().getTotalRecharged() >= 100.0;
      
    } catch (e) {
      print('Error loading from storage: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final agenciesJson = _agencies.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_agenciesKey, agenciesJson);
      final requestsJson = _creationRequests.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_requestsKey, requestsJson);
      final invitationsJson = _invitations.map((i) => jsonEncode(i.toJson())).toList();
      await prefs.setStringList(_invitationsKey, invitationsJson);
      final joinRequestsJson = _joinRequests.map((j) => jsonEncode(j.toJson())).toList();
      await prefs.setStringList(_joinRequestsKey, joinRequestsJson);
    } catch (e) {
      print('Error saving to storage: $e');
    }
  }

  @override
  List<dynamic> get pendingRequests => _pendingRequests;

  @override
  int get memberCount => _members.length;

  @override
  bool get agencyUnlocked => _isUnlocked;

  @override
  Future<void> acceptRequest(String id) async {
    final requestIndex = _creationRequests.indexWhere((r) => r.userId == id);
    if (requestIndex != -1) {
      final request = _creationRequests[requestIndex];
      request.status = AgencyRequestStatus.approved;
      _pendingRequests.removeWhere((r) => (r is AgencyRequest && r.userId == id));
      _members.add(request);
      
      _agencies.add(Agency(
        id: (1000 + _agencies.length + 1).toString(),
        name: request.agencyName,
        ownerId: id,
        description: request.description,
        agencyType: AgencyType.modife,
      ));
      
      await _saveToStorage();
    }
  }

  @override
  Future<void> rejectRequest(String id) async {
    final requestIndex = _creationRequests.indexWhere((r) => r.userId == id);
    if (requestIndex != -1) {
      _creationRequests[requestIndex].status = AgencyRequestStatus.rejected;
      _pendingRequests.removeWhere((r) => (r is AgencyRequest && r.userId == id));
      await _saveToStorage();
    }
  }

  @override
  Future<void> getPendingRequests() async {
    await _loadFromStorage();
  }

  @override
  Future<void> findAgencyById(String id) async {
    await getAgencyById(id);
  }

  @override
  Future<void> joinAgency(String agencyId) async {}

  @override
  Future<List<Agency>> getAgencies() async {
    return _agencies;
  }

  @override
  Future<Agency?> getAgencyById(String id) async {
    try {
      return _agencies.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AgencyRequest>> getAgencyRequests() async {
    return _creationRequests;
  }

  @override
  Future<void> submitAgencyRequest(AgencyRequest request) async {
    _creationRequests.add(request);
    _pendingRequests.add(request);
    await _saveToStorage();
  }

  @override
  Future<void> updateAgencyRequest(AgencyRequest request) async {
    final index = _creationRequests.indexWhere((r) => r.userId == request.userId && r.agencyName == request.agencyName);
    if (index != -1) {
      _creationRequests[index] = request;
      await _saveToStorage();
    }
  }

  @override
  Future<String> uploadIdCardImage(File file, bool isFront) async {
    try {
      final bytes = await file.readAsBytes();
      final name = file.path.split('/').last.split('\\').last;
      return await CloudinaryService.uploadImageBytes(
        bytes,
        fileName: name,
        folder: 'id_cards',
      );
    } catch (e) {
      return file.path;
    }
  }

  @override
  Future<List<AgencyInvitation>> getInvitations(String userId) async {
    return _invitations.where((i) => i.modifeId == userId).toList();
  }

  @override
  Future<void> sendInvitation(AgencyInvitation invitation) async {
    _invitations.add(invitation);
    await _saveToStorage();
  }

  @override
  Future<void> respondToInvitation(String invitationId, bool accept) async {
    await _saveToStorage();
  }

  @override
  Future<List<AgencyJoinRequest>> getJoinRequests(String agencyId) async {
    return _joinRequests.where((r) => r.agencyId == agencyId).toList();
  }

  @override
  Future<void> sendJoinRequest(AgencyJoinRequest request) async {
    _joinRequests.add(request);
    await _saveToStorage();
  }

  @override
  Future<void> respondToJoinRequest(String requestId, bool approve) async {
    await _saveToStorage();
  }

  @override
  Future<void> updateAgency(Agency agency) async {
    final index = _agencies.indexWhere((a) => a.id == agency.id);
    if (index != -1) {
      _agencies[index] = agency;
    } else {
      _agencies.add(agency);
    }
    await _saveToStorage();
  }

  @override
  Future<Agency?> getMyAgency(String ownerId, {AgencyType? type}) async {
    try {
      if (type != null) {
        return _agencies.firstWhere((a) => a.ownerId == ownerId && a.agencyType == type);
      }
      return _agencies.firstWhere((a) => a.ownerId == ownerId);
    } catch (_) {
      return null;
    }
  }
}
