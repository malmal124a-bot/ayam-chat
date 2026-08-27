import 'dart:io';
import '../models/agency_model.dart';
import '../models/agency_request.dart';

abstract class AgencyRepository {
  List<dynamic> get pendingRequests;
  int get memberCount;
  bool get agencyUnlocked;

  Future<void> findAgencyById(String id);
  Future<void> joinAgency(String agencyId);
  Future<void> getPendingRequests();

  Future<List<Agency>> getAgencies();
  Future<Agency?> getAgencyById(String id);
  Future<List<AgencyRequest>> getAgencyRequests();
  Future<void> submitAgencyRequest(AgencyRequest request);
  Future<void> updateAgencyRequest(AgencyRequest request);
  Future<String> uploadIdCardImage(File file, bool isFront);
  
  // Admin methods for Agency Creation Requests
  Future<void> acceptRequest(String id);
  Future<void> rejectRequest(String id);
  
  // Invitation & Join requests (Member level)
  Future<List<AgencyInvitation>> getInvitations(String userId);
  Future<void> sendInvitation(AgencyInvitation invitation);
  Future<void> respondToInvitation(String invitationId, bool accept);
  
  Future<List<AgencyJoinRequest>> getJoinRequests(String agencyId);
  Future<void> sendJoinRequest(AgencyJoinRequest request);
  Future<void> respondToJoinRequest(String requestId, bool approve);
  
  // Charging agency methods
  Future<void> updateAgency(Agency agency);
  Future<Agency?> getMyAgency(String ownerId, {AgencyType? type});
}
