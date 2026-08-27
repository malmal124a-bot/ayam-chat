import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/relationship.dart';
import 'broadcast_controller.dart';

class RelationshipController extends ChangeNotifier {
  List<Relationship> _relationships = [];
  List<FriendRequest> _friendRequests = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  String? _currentUserName;
  final BroadcastController _broadcastController = BroadcastController();

  List<Relationship> get relationships => _relationships;
  List<FriendRequest> get friendRequests => _friendRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;

  RelationshipController() {
    _loadData();
  }

  void setCurrentUser(String userId, String userName) {
    _currentUserId = userId;
    _currentUserName = userName;
    notifyListeners();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load relationships
      final relationshipsJson = prefs.getStringList('relationships') ?? [];
      _relationships = relationshipsJson.map((json) {
        final parts = json.split('|');
        return Relationship(
          id: parts[0],
          userId1: parts[1],
          userId2: parts[2],
          userName1: parts[3],
          userName2: parts[4],
          createdAt: DateTime.parse(parts[5]),
          relationshipLevel: int.tryParse(parts[6]) ?? 1,
        );
      }).toList();
      
      // Load friend requests
      final requestsJson = prefs.getStringList('friend_requests') ?? [];
      _friendRequests = requestsJson.map((json) {
        final parts = json.split('|');
        return FriendRequest(
          id: parts[0],
          fromUserId: parts[1],
          fromUserName: parts[2],
          toUserId: parts[3],
          toUserName: parts[4],
          createdAt: DateTime.parse(parts[5]),
          status: parts[6],
        );
      }).toList();
      
      // Load current user
      _currentUserId = prefs.getString('current_user_id');
      _currentUserName = prefs.getString('current_user_name');
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendFriendRequest({
    required String toUserId,
    required String toUserName,
  }) async {
    if (_currentUserId == null || _currentUserName == null) {
      _errorMessage = 'Current user not set';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      // Check if request already exists
      if (_friendRequests.any((req) => req.fromUserId == _currentUserId && req.toUserId == toUserId && req.status == 'pending')) {
        _errorMessage = 'Request already sent';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final request = FriendRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fromUserId: _currentUserId!,
        fromUserName: _currentUserName!,
        toUserId: toUserId,
        toUserName: toUserName,
        createdAt: DateTime.now(),
        status: 'pending',
      );
      
      _friendRequests.add(request);
      
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = _friendRequests.map((req) => 
        '${req.id}|${req.fromUserId}|${req.fromUserName}|${req.toUserId}|${req.toUserName}|${req.createdAt.toIso8601String()}|${req.status}'
      ).toList();
      await prefs.setStringList('friend_requests', requestsJson);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptFriendRequest(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      final requestIndex = _friendRequests.indexWhere((req) => req.id == requestId);
      if (requestIndex == -1) {
        _errorMessage = 'Request not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final request = _friendRequests[requestIndex];
      
      // Update request status
      _friendRequests[requestIndex] = FriendRequest(
        id: request.id,
        fromUserId: request.fromUserId,
        fromUserName: request.fromUserName,
        toUserId: request.toUserId,
        toUserName: request.toUserName,
        createdAt: request.createdAt,
        status: 'accepted',
      );
      
      // Create relationship
      final relationship = Relationship(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId1: request.fromUserId,
        userId2: request.toUserId,
        userName1: request.fromUserName,
        userName2: request.toUserName,
        createdAt: DateTime.now(),
        relationshipLevel: 1,
      );
      
      _relationships.add(relationship);
      
      // Broadcast the relationship success
      await _broadcastController.addRelationshipBroadcast(request.fromUserName, request.toUserName);
      
      final prefs = await SharedPreferences.getInstance();
      
      // Save relationships
      final relationshipsJson = _relationships.map((rel) => 
        '${rel.id}|${rel.userId1}|${rel.userId2}|${rel.userName1}|${rel.userName2}|${rel.createdAt.toIso8601String()}|${rel.relationshipLevel}'
      ).toList();
      await prefs.setStringList('relationships', relationshipsJson);
      
      // Save friend requests
      final requestsJson = _friendRequests.map((req) => 
        '${req.id}|${req.fromUserId}|${req.fromUserName}|${req.toUserId}|${req.toUserName}|${req.createdAt.toIso8601String()}|${req.status}'
      ).toList();
      await prefs.setStringList('friend_requests', requestsJson);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectFriendRequest(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      final requestIndex = _friendRequests.indexWhere((req) => req.id == requestId);
      if (requestIndex == -1) {
        _errorMessage = 'Request not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // Update request status
      _friendRequests[requestIndex] = FriendRequest(
        id: _friendRequests[requestIndex].id,
        fromUserId: _friendRequests[requestIndex].fromUserId,
        fromUserName: _friendRequests[requestIndex].fromUserName,
        toUserId: _friendRequests[requestIndex].toUserId,
        toUserName: _friendRequests[requestIndex].toUserName,
        createdAt: _friendRequests[requestIndex].createdAt,
        status: 'rejected',
      );
      
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = _friendRequests.map((req) => 
        '${req.id}|${req.fromUserId}|${req.fromUserName}|${req.toUserId}|${req.toUserName}|${req.createdAt.toIso8601String()}|${req.status}'
      ).toList();
      await prefs.setStringList('friend_requests', requestsJson);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<FriendRequest> getPendingRequestsForUser(String userId) {
    return _friendRequests.where((req) => req.toUserId == userId && req.status == 'pending').toList();
  }

  List<Relationship> getRelationshipsForUser(String userId) {
    return _relationships.where((rel) => rel.userId1 == userId || rel.userId2 == userId).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
