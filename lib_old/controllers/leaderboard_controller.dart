import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ranking_model.dart';

class LeaderboardController extends ChangeNotifier {
  static final LeaderboardController _instance = LeaderboardController._internal();
  factory LeaderboardController() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LeaderboardController._internal() {
    debugPrint('Initializing: LeaderboardController');
    _listenToFirestore();
  }

  void _listenToFirestore() {
    // Listen to rankings collection for real-time updates
    _firestore.collection('rankings')
        .orderBy('giftScore', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
      _globalRankings.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _globalRankings.add(RankingModel(
          userName: data['userName'] ?? '',
          avatarUrl: data['avatarUrl'] ?? '',
          giftScore: (data['giftScore'] as num?)?.toInt() ?? 0,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      }
      notifyListeners();
    });

    // Listen to daily rankings
    _firestore.collection('daily_rankings')
        .orderBy('giftScore', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
      _dailyRankings.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _dailyRankings.add(RankingModel(
          userName: data['userName'] ?? '',
          avatarUrl: data['avatarUrl'] ?? '',
          giftScore: (data['giftScore'] as num?)?.toInt() ?? 0,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      }
      notifyListeners();
    });
  }

  final List<RankingModel> _dailyRankings = [];
  final List<RankingModel> _weeklyRankings = [];
  final List<RankingModel> _monthlyRankings = [];
  final List<RankingModel> _globalRankings = [];
  final List<RankingModel> _globalRoomRankings = [];

  // Room Rankings per period: { "roomId": { "daily": [...], "weekly": [...], "monthly": [...] } }
  final Map<String, Map<String, List<RankingModel>>> _roomRankingsByPeriod = {};

  List<RankingModel> get dailyRankings => _getSortedList(_dailyRankings);
  List<RankingModel> get weeklyRankings => _getSortedList(_weeklyRankings);
  List<RankingModel> get monthlyRankings => _getSortedList(_monthlyRankings);
  List<RankingModel> get globalRankings => _getSortedList(_globalRankings);
  List<RankingModel> get globalRoomRankings => _getSortedList(_globalRoomRankings);

  List<RankingModel> getRoomUserRankings(String roomId, {String period = 'daily'}) {
    if (!_roomRankingsByPeriod.containsKey(roomId)) {
      _roomRankingsByPeriod[roomId] = {
        'daily': [],
        'weekly': [],
        'monthly': [],
      };
    }
    return _getSortedList(_roomRankingsByPeriod[roomId]?[period] ?? []);
  }

  int getGlobalRank(String userName) {
    final sorted = globalRankings;
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].userName == userName) return i + 1;
    }
    return 0;
  }

  List<RankingModel> _getSortedList(List<RankingModel> list) {
    final sorted = List<RankingModel>.from(list);
    sorted.sort((a, b) => b.giftScore.compareTo(a.giftScore));
    return sorted;
  }

  void addGift(String userName, int amount, {String? roomId, String? userId, String? avatarUrl}) {
    _updateList(_dailyRankings, userName, amount, avatarUrl);
    _updateList(_weeklyRankings, userName, amount, avatarUrl);
    _updateList(_monthlyRankings, userName, amount, avatarUrl);
    _updateList(_globalRankings, userName, amount, avatarUrl);
    
    // Save to Firestore
    _saveGiftToFirestore(userName, amount, userId, avatarUrl);
    
    if (roomId != null) {
      if (!_roomRankingsByPeriod.containsKey(roomId)) {
        _roomRankingsByPeriod[roomId] = {
          'daily': [],
          'weekly': [],
          'monthly': [],
        };
      }
      _updateList(_roomRankingsByPeriod[roomId]!['daily']!, userName, amount, avatarUrl);
      _updateList(_roomRankingsByPeriod[roomId]!['weekly']!, userName, amount, avatarUrl);
      _updateList(_roomRankingsByPeriod[roomId]!['monthly']!, userName, amount, avatarUrl);
    }
    notifyListeners();
  }

  Future<void> _saveGiftToFirestore(String userName, int amount, String? userId, String? avatarUrl) async {
    try {
      // Update global rankings
      final rankingRef = _firestore.collection('rankings').doc(userId ?? userName);
      await rankingRef.set({
        'userName': userName,
        'avatarUrl': avatarUrl ?? '',
        'giftScore': FieldValue.increment(amount),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update daily rankings
      final dailyRef = _firestore.collection('daily_rankings').doc(userId ?? userName);
      await dailyRef.set({
        'userName': userName,
        'avatarUrl': avatarUrl ?? '',
        'giftScore': FieldValue.increment(amount),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving gift to Firestore: $e');
    }
  }

  void addRoomPoints(dynamic roomId, [dynamic userId, int? points]) {
    // Safe fallback method
    final String rId = roomId?.toString() ?? '';
    if (rId.isEmpty) return;

    // Handle flexible arguments safely
    int actualPoints = 0;
    String actualUserId = '';

    if (points != null) {
      actualPoints = points;
      actualUserId = userId?.toString() ?? '';
    } else if (userId is int) {
      actualPoints = userId;
    } else if (userId != null) {
      actualUserId = userId.toString();
    }

    if (!_roomRankingsByPeriod.containsKey(rId)) {
      _roomRankingsByPeriod[rId] = {
        'daily': [],
        'weekly': [],
        'monthly': [],
      };
    }
    
    // Update global room score
    final roomIndex = _globalRoomRankings.indexWhere((r) => r.userName == rId);
    if (roomIndex != -1) {
      _globalRoomRankings[roomIndex].giftScore += actualPoints;
    } else {
      _globalRoomRankings.add(RankingModel(
        userName: rId,
        giftScore: actualPoints,
        timestamp: DateTime.now(),
      ));
    }

    // Update user rankings within the room
    if (actualUserId.isNotEmpty) {
      _updateList(_roomRankingsByPeriod[rId]!['daily']!, actualUserId, actualPoints, null);
      _updateList(_roomRankingsByPeriod[rId]!['weekly']!, actualUserId, actualPoints, null);
      _updateList(_roomRankingsByPeriod[rId]!['monthly']!, actualUserId, actualPoints, null);
    }

    notifyListeners();
  }

  void resetDailyRankings() {
    _dailyRankings.clear();
    _roomRankingsByPeriod.forEach((roomId, periods) {
      periods['daily']?.clear();
    });
    notifyListeners();
  }

  void _updateList(List<RankingModel> list, String userName, int amount, String? avatarUrl) {
    final index = list.indexWhere((element) => element.userName == userName);
    if (index != -1) {
      list[index].giftScore += amount;
    } else {
      list.add(RankingModel(
        userName: userName,
        avatarUrl: avatarUrl ?? '',
        giftScore: amount,
        timestamp: DateTime.now(),
      ));
    }
  }
}
