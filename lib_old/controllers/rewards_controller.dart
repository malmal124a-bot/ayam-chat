import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wallet_controller.dart';
import 'inventory_controller.dart';
import 'user_controller.dart';

class Reward {
  final String type; // 'diamonds' or 'frame'
  final dynamic value; // int for diamonds, String (itemId) for frame
  final String label;

  Reward({required this.type, required this.value, required this.label});
}

class RewardsController extends ChangeNotifier {
  static final RewardsController _instance = RewardsController._internal();
  factory RewardsController() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RewardsController._internal() {
    debugPrint('Initializing: RewardsController');
    _loadData();
    _listenToFirestore();
  }

  int _streakCount = 0;
  DateTime? _lastLoginDate;
  bool _hasClaimedToday = false;

  int get streakCount => _streakCount;
  bool get hasClaimedToday => _hasClaimedToday;

  void _listenToFirestore() {
    final userId = UserController().id;
    _firestore.collection('users').doc(userId).collection('daily_rewards')
        .doc('current')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          _streakCount = (data['streakCount'] as int?) ?? 0;
          _hasClaimedToday = (data['hasClaimedToday'] as bool?) ?? false;
          if (data['lastLoginDate'] != null) {
            _lastLoginDate = (data['lastLoginDate'] as Timestamp).toDate();
          }
          notifyListeners();
        }
      }
    });
  }

  Future<void> init() async {
    await _loadData();
    _checkStreak();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _streakCount = prefs.getInt('streak_count') ?? 0;
      String? lastLoginStr = prefs.getString('last_login_date');
      if (lastLoginStr != null) {
        _lastLoginDate = DateTime.parse(lastLoginStr);
      }
      
      final now = DateTime.now();
      if (_lastLoginDate != null && _isSameDay(_lastLoginDate!, now)) {
        _hasClaimedToday = prefs.getBool('claimed_today') ?? false;
      } else {
        _hasClaimedToday = false;
        await prefs.setBool('claimed_today', false);
      }
      
      // Try to load from Firestore
      final userId = UserController().id;
      final doc = await _firestore.collection('users').doc(userId)
          .collection('daily_rewards').doc('current').get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          _streakCount = (data['streakCount'] as int?) ?? _streakCount;
          _hasClaimedToday = (data['hasClaimedToday'] as bool?) ?? _hasClaimedToday;
          if (data['lastLoginDate'] != null) {
            _lastLoginDate = (data['lastLoginDate'] as Timestamp).toDate();
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading rewards data: $e');
    }
  }

  void _checkStreak() async {
    final now = DateTime.now();
    if (_lastLoginDate == null) {
      _streakCount = 1;
    } else {
      final lastDateOnly = DateTime(_lastLoginDate!.year, _lastLoginDate!.month, _lastLoginDate!.day);
      final nowDateOnly = DateTime(now.year, now.month, now.day);
      final dayDiff = nowDateOnly.difference(lastDateOnly).inDays;

      if (dayDiff == 1) {
        // Logged in the next day
        if (_streakCount >= 7) {
          _streakCount = 1;
        } else {
          _streakCount++;
        }
      } else if (dayDiff > 1) {
        // Missed a day
        _streakCount = 1;
      } else if (dayDiff == 0) {
        // Same day login, keep current streak
      }
    }
    
    _lastLoginDate = now;
    await _saveData();
    await _saveToFirestore();
    notifyListeners();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('streak_count', _streakCount);
      if (_lastLoginDate != null) {
        await prefs.setString('last_login_date', _lastLoginDate!.toIso8601String());
      }
      await prefs.setBool('claimed_today', _hasClaimedToday);
    } catch (e) {
      debugPrint('Error saving rewards data: $e');
    }
  }

  Future<void> _saveToFirestore() async {
    try {
      final userId = UserController().id;
      await _firestore.collection('users').doc(userId)
          .collection('daily_rewards').doc('current').set({
        'streakCount': _streakCount,
        'lastLoginDate': _lastLoginDate != null 
            ? Timestamp.fromDate(_lastLoginDate!) 
            : FieldValue.serverTimestamp(),
        'hasClaimedToday': _hasClaimedToday,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving rewards to Firestore: $e');
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Reward getDailyReward() {
    final random = Random();
    int chance = random.nextInt(100);

    // If it's day 7, give a better reward
    if (_streakCount == 7) {
      return Reward(type: 'diamonds', value: 100, label: '100 Diamonds (7-Day Bonus!)');
    }

    if (chance < 70) {
      // 70% chance for diamonds
      int amount = 10 + random.nextInt(41); // 10 to 50 diamonds
      return Reward(type: 'diamonds', value: amount, label: '$amount Diamonds');
    } else {
      // 30% chance for a temporary frame
      List<String> frameIds = ['frame_gold', 'frame_silver', 'frame_royal']; 
      String frameId = frameIds[random.nextInt(frameIds.length)];
      return Reward(type: 'frame', value: frameId, label: 'Special Frame');
    }
  }

  Future<void> claimReward() async {
    if (_hasClaimedToday) return;

    final reward = getDailyReward();
    if (reward.type == 'diamonds') {
      WalletController().addDiamonds(reward.value);
    } else if (reward.type == 'frame') {
      InventoryController().addItem(reward.value);
    }

    _hasClaimedToday = true;
    await _saveData();
    await _saveToFirestore();
    notifyListeners();
  }

  bool get shouldShowPopup => !_hasClaimedToday;
}
