import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/relationship.dart';
import 'broadcast_controller.dart';
import 'user_controller.dart';

class RelationshipController extends ChangeNotifier {
  List<Relationship> _relationships = [];
  List<FriendRequest> _friendRequests = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  String? _currentUserName;
  final BroadcastController _broadcastController = BroadcastController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Relationship> get relationships => _relationships;
  List<FriendRequest> get friendRequests => _friendRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;

  RelationshipController() {
    _currentUserId = UserController().id;
    _currentUserName = UserController().name;
    _loadData();
    _listenToFirestore();
  }

  void _listenToFirestore() {
    if (_currentUserId == null) return;
    
    // Listen to following collection
    _firestore.collection('users').doc(_currentUserId).collection('following')
        .snapshots()
        .listen((snapshot) {
      _relationships.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _relationships.add(Relationship(
          id: doc.id,
          userId1: _currentUserId!,
          userId2: data['userId'] ?? '',
          userName1: _currentUserName ?? '',
          userName2: data['userName'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          relationshipLevel: (data['relationshipLevel'] as num?)?.toInt() ?? 1,
        ));
      }
      notifyListeners();
    });

    // Listen to friend requests
    _firestore.collection('users').doc(_currentUserId).collection('friend_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      _friendRequests.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _friendRequests.add(FriendRequest(
          id: doc.id,
          fromUserId: data['fromUserId'] ?? '',
          fromUserName: data['fromUserName'] ?? '',
          toUserId: data['toUserId'] ?? '',
          toUserName: data['toUserName'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] ?? 'pending',
        ));
      }
      notifyListeners();
    });
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
      // Check if request already exists in Firestore
      final existingRequest = await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('friend_requests')
          .where('fromUserId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (existingRequest.docs.isNotEmpty) {
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
      
      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('friend_requests')
          .doc(request.id)
          .set({
        'fromUserId': request.fromUserId,
        'fromUserName': request.fromUserName,
        'toUserId': request.toUserId,
        'toUserName': request.toUserName,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
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
      final requestIndex = _friendRequests.indexWhere((req) => req.id == requestId);
      if (requestIndex == -1) {
        _errorMessage = 'Request not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final request = _friendRequests[requestIndex];
      
      // Update request status in Firestore
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'accepted'});
      
      // Create relationship in Firestore (add to following for both users)
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('following')
          .doc(request.fromUserId)
          .set({
        'userId': request.fromUserId,
        'userName': request.fromUserName,
        'createdAt': FieldValue.serverTimestamp(),
        'relationshipLevel': 1,
      });
      
      await _firestore
          .collection('users')
          .doc(request.fromUserId)
          .collection('followers')
          .doc(_currentUserId)
          .set({
        'userId': _currentUserId,
        'userName': _currentUserName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update follower counts in user documents
      await _firestore.collection('users').doc(_currentUserId).update({
        'followingCount': FieldValue.increment(1),
      });
      
      await _firestore.collection('users').doc(request.fromUserId).update({
        'followersCount': FieldValue.increment(1),
      });
      
      // Update local state
      _friendRequests[requestIndex] = FriendRequest(
        id: request.id,
        fromUserId: request.fromUserId,
        fromUserName: request.fromUserName,
        toUserId: request.toUserId,
        toUserName: request.toUserName,
        createdAt: request.createdAt,
        status: 'accepted',
      );
      
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

  Future<Map<String, dynamic>?> getPartner() async {
    if (_currentUserId == null) return null;
    
    try {
      // Query the CP/relationship collection for current user's partner
      final partnerDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('cp_partner')
          .doc('current')
          .get();
      
      if (partnerDoc.exists) {
        final data = partnerDoc.data();
        if (data != null && data['partnerId'] != null) {
          final partnerUserDoc = await _firestore.collection('users').doc(data['partnerId']).get();
          if (partnerUserDoc.exists) {
            return partnerUserDoc.data();
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting partner: $e');
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
