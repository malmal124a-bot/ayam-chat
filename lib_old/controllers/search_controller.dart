import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String name;
  final String? profilePic;
  final int level;
  final int vipLevel;
  final bool isOnline;
  final String? currentRoomId;
  final String? currentRoomName;
  final int followersCount;
  final int followingCount;

  UserProfile({
    required this.userId,
    required this.name,
    this.profilePic,
    required this.level,
    required this.vipLevel,
    required this.isOnline,
    this.currentRoomId,
    this.currentRoomName,
    required this.followersCount,
    required this.followingCount,
  });

  factory UserProfile.fromFirestore(String id, Map<String, dynamic> data) {
    return UserProfile(
      userId: id,
      name: data['name'] ?? '',
      profilePic: data['profilePic'],
      level: (data['level'] as num?)?.toInt() ?? 1,
      vipLevel: (data['vipLevel'] as num?)?.toInt() ?? 0,
      isOnline: data['isOnline'] as bool? ?? false,
      currentRoomId: data['currentRoomId'],
      currentRoomName: data['currentRoomName'],
      followersCount: (data['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class UserSearchController extends ChangeNotifier {
  static final UserSearchController _instance = UserSearchController._internal();
  factory UserSearchController() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserSearchController._internal() {
    debugPrint('Initializing: UserSearchController');
  }

  final List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  List<UserProfile> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;

  Future<void> searchUserById(String userId) async {
    _isSearching = true;
    _errorMessage = null;
    _searchResults.clear();
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          _searchResults.add(UserProfile.fromFirestore(doc.id, data));
        }
      } else {
        _errorMessage = 'User not found';
      }
    } catch (e) {
      _errorMessage = 'Error searching for user: $e';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> searchUserByName(String name) async {
    _isSearching = true;
    _errorMessage = null;
    _searchResults.clear();
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: name)
          .where('name', isLessThanOrEqualTo: '$name\uf8ff')
          .limit(10)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        _searchResults.add(UserProfile.fromFirestore(doc.id, data));
      }
    } catch (e) {
      _errorMessage = 'Error searching for user: $e';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearResults() {
    _searchResults.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
