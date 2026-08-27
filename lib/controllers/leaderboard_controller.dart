import 'package:flutter/material.dart';
import '../models/ranking_model.dart';
import '../services/supabase_service.dart';

class LeaderboardController extends ChangeNotifier {
  static final LeaderboardController _instance = LeaderboardController._internal();
  factory LeaderboardController() => _instance;
  LeaderboardController._internal();

  bool _loaded = false;

  /// Load historical rankings from sent_gifts table
  Future<void> loadFromDatabase() async {
    if (_loaded) return;
    try {
      final now = DateTime.now().toUtc().add(const Duration(hours: 2));
      final todayStart = DateTime(now.year, now.month, now.day).subtract(const Duration(hours: 2));
      final sunday = now.subtract(Duration(days: now.weekday % 7));
      final weekStart = DateTime(sunday.year, sunday.month, sunday.day).subtract(const Duration(hours: 2));
      final monthStart = DateTime(now.year, now.month, 1).subtract(const Duration(hours: 2));

      final todayMs = todayStart.millisecondsSinceEpoch;
      final weekMs = weekStart.millisecondsSinceEpoch;
      final monthMs = monthStart.millisecondsSinceEpoch;

      // Load all gifts
      final allGifts = await SupabaseService.client
          .from('sent_gifts')
          .select('sender_name, sender_photo_url, room_id, value, count, timestamp')
          .order('timestamp', ascending: false);

      if (allGifts.isEmpty) {
        _loaded = true;
        return;
      }

      // Load room names/photos for room rankings
      Map<String, Map<String, String>> roomInfo = {};
      try {
        final rooms = await SupabaseService.client
            .from('rooms')
            .select('room_id, room_name, room_cover');
        for (final r in rooms) {
          roomInfo[r['room_id']?.toString() ?? ''] = {
            'name': r['room_name'] ?? '',
            'photo': r['room_cover'] ?? '',
          };
        }
      } catch (_) {}

      for (final gift in allGifts) {
        final senderName = gift['sender_name'] ?? '';
        final senderPhoto = gift['sender_photo_url'] ?? '';
        final roomId = gift['room_id'] ?? '';
        final value = (gift['value'] ?? 0).toInt();
        final timestamp = gift['timestamp'] ?? 0;

        if (senderName.isEmpty || value <= 0) continue;

        // Global user rankings (all time)
        _updateList(_globalUserRankings, senderName, value, avatarUrl: senderPhoto);

        // Room-level rankings
        if (roomId.isNotEmpty) {
          if (!_roomRankingsByPeriod.containsKey(roomId)) {
            _roomRankingsByPeriod[roomId] = {'daily': [], 'weekly': [], 'monthly': []};
          }

          // Monthly
          if (timestamp >= monthMs) {
            _updateList(_roomRankingsByPeriod[roomId]!['monthly']!, senderName, value, avatarUrl: senderPhoto);
          }
          // Weekly
          if (timestamp >= weekMs) {
            _updateList(_roomRankingsByPeriod[roomId]!['weekly']!, senderName, value, avatarUrl: senderPhoto);
          }
          // Daily
          if (timestamp >= todayMs) {
            _updateList(_roomRankingsByPeriod[roomId]!['daily']!, senderName, value, avatarUrl: senderPhoto);
          }

          // Global room ranking
          final info = roomInfo[roomId];
          _updateRoomRanking(roomId, info?['name'] ?? roomId, info?['photo'], value);
        }
      }

      _loaded = true;
      notifyListeners();
      debugPrint('LeaderboardController: Loaded ${allGifts.length} gifts from database');
    } catch (e) {
      debugPrint('LeaderboardController: Error loading from database: $e');
      _loaded = true;
    }
  }

  // Per-room user rankings: { "roomId": { "daily": [...], "weekly": [...], "monthly": [...] } }
  final Map<String, Map<String, List<RankingModel>>> _roomRankingsByPeriod = {};

  // Global user rankings (total gifts sent by each user across all rooms)
  final List<RankingModel> _globalUserRankings = [];

  // Global room rankings (total gifts per room)
  final List<RankingModel> _globalRoomRankings = [];

  // Global agency rankings (total gifts per agency)
  final List<RankingModel> _globalAgencyRankings = [];

  // Track reset timestamps
  DateTime _lastDailyReset = DateTime.now();
  DateTime _lastWeeklyReset = DateTime.now();
  DateTime _lastMonthlyReset = DateTime.now();

  // --- Getters ---

  List<RankingModel> get globalUserRankings => _getSortedList(_globalUserRankings).take(10).toList();

  List<RankingModel> getRoomUserRankings(String roomId, {String period = 'daily'}) {
    if (!_roomRankingsByPeriod.containsKey(roomId)) {
      _roomRankingsByPeriod[roomId] = {'daily': [], 'weekly': [], 'monthly': []};
    }
    final list = _roomRankingsByPeriod[roomId]?[period] ?? [];
    return _getSortedList(list);
  }

  List<RankingModel> getGlobalRoomRankings() => _getSortedList(_globalRoomRankings).take(30).toList();
  List<RankingModel> getGlobalAgencyRankings() => _getSortedList(_globalAgencyRankings).take(10).toList();

  int getGlobalRank(String userName) {
    final sorted = globalUserRankings;
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].userName == userName) return i + 1;
    }
    return 0;
  }

  // --- Core: addGift ---

  void addGift(
    String userName,
    int amount, {
    String? roomId,
    String? roomName,
    String? roomPhoto,
    String? avatarUrl,
    String? agencyName,
    String? agencyPhoto,
  }) {
    _checkAndResetPeriods();

    // Global user rankings (across all rooms)
    _updateList(_globalUserRankings, userName, amount, avatarUrl: avatarUrl);

    // Per-room user rankings (daily/weekly/monthly)
    if (roomId != null) {
      if (!_roomRankingsByPeriod.containsKey(roomId)) {
        _roomRankingsByPeriod[roomId] = {'daily': [], 'weekly': [], 'monthly': []};
      }
      _updateList(_roomRankingsByPeriod[roomId]!['daily']!, userName, amount, avatarUrl: avatarUrl);
      _updateList(_roomRankingsByPeriod[roomId]!['weekly']!, userName, amount, avatarUrl: avatarUrl);
      _updateList(_roomRankingsByPeriod[roomId]!['monthly']!, userName, amount, avatarUrl: avatarUrl);

      // Global room ranking
      _updateRoomRanking(roomId, roomName ?? roomId, roomPhoto, amount);
    }

    // Global agency ranking
    if (agencyName != null && agencyName.isNotEmpty) {
      _updateAgencyRanking(agencyName, agencyPhoto, amount);
    }

    notifyListeners();
  }

  // --- Room ranking ---

  void _updateRoomRanking(String roomId, String roomName, String? roomPhoto, int amount) {
    final index = _globalRoomRankings.indexWhere((r) => r.roomId == roomId);
    if (index != -1) {
      _globalRoomRankings[index].giftScore += amount;
    } else {
      _globalRoomRankings.add(RankingModel(
        userName: roomName,
        avatarUrl: roomPhoto ?? '',
        giftScore: amount,
        timestamp: DateTime.now(),
        roomId: roomId,
        roomPhoto: roomPhoto,
      ));
    }
  }

  // --- Agency ranking ---

  void _updateAgencyRanking(String agencyName, String? agencyPhoto, int amount) {
    final index = _globalAgencyRankings.indexWhere((r) => r.agencyName == agencyName);
    if (index != -1) {
      _globalAgencyRankings[index].giftScore += amount;
    } else {
      _globalAgencyRankings.add(RankingModel(
        userName: agencyName,
        avatarUrl: agencyPhoto ?? '',
        giftScore: amount,
        timestamp: DateTime.now(),
        agencyName: agencyName,
        agencyPhoto: agencyPhoto,
      ));
    }
  }

  // --- Period Reset Logic ---

  void _checkAndResetPeriods() {
    final now = DateTime.now();
    final egyptTime = now.toUtc().add(const Duration(hours: 2));

    // Daily reset: every day at 12:00 AM (midnight) Egypt time
    if (_lastDailyReset.day != egyptTime.day) {
      _resetDaily();
      _lastDailyReset = egyptTime;
    }

    // Weekly reset: every Sunday at 12:00 AM (midnight) Egypt time
    if (egyptTime.weekday == DateTime.sunday && _lastWeeklyReset.day != egyptTime.day && egyptTime.hour == 0) {
      _resetWeekly();
      _lastWeeklyReset = egyptTime;
    }

    // Monthly reset: every 30 or 31 days depending on the month
    final daysInMonth = DateTime(egyptTime.year, egyptTime.month + 1, 0).day;
    final daysSinceReset = egyptTime.difference(_lastMonthlyReset).inDays;
    if (daysSinceReset >= daysInMonth) {
      _resetMonthly();
      _lastMonthlyReset = egyptTime;
    }
  }

  void _resetDaily() {
    _roomRankingsByPeriod.forEach((roomId, periods) {
      periods['daily']?.clear();
    });
    debugPrint('LeaderboardController: Daily rankings reset');
  }

  void _resetWeekly() {
    _roomRankingsByPeriod.forEach((roomId, periods) {
      periods['weekly']?.clear();
    });
    debugPrint('LeaderboardController: Weekly rankings reset');
  }

  void _resetMonthly() {
    _roomRankingsByPeriod.forEach((roomId, periods) {
      periods['monthly']?.clear();
    });
    debugPrint('LeaderboardController: Monthly rankings reset');
  }

  // Keep old reset method for CronService compatibility
  void resetDailyRankings() {
    _resetDaily();
    notifyListeners();
  }

  // --- Profile Sync ---

  void syncUserProfile(String oldName, String newName, String? oldAvatar, String? newAvatar) {
    bool changed = false;

    // Update all in-memory rankings
    for (final list in [
      _globalUserRankings,
      ..._roomRankingsByPeriod.values.expand((periods) => periods.values),
    ]) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].userName == oldName) {
          list[i] = RankingModel(
            userName: newName,
            avatarUrl: newAvatar ?? list[i].avatarUrl,
            giftScore: list[i].giftScore,
            timestamp: list[i].timestamp,
          );
          changed = true;
        }
      }
    }

    if (changed) {
      notifyListeners();
    }

    // Update sent_gifts table in background
    try {
      final userId = SupabaseService.currentUserId;
      if (userId != null) {
        SupabaseService.client.from('sent_gifts').update({
          'sender_name': newName,
          if (newAvatar != null) 'sender_photo_url': newAvatar,
        }).eq('sender_id', userId);
      }
    } catch (e) {
      debugPrint('LeaderboardController: Error syncing sent_gifts: $e');
    }
  }

  // --- Helpers ---

  List<RankingModel> _getSortedList(List<RankingModel> list) {
    final sorted = List<RankingModel>.from(list);
    sorted.sort((a, b) => b.giftScore.compareTo(a.giftScore));
    return sorted;
  }

  void _updateList(List<RankingModel> list, String userName, int amount, {String? avatarUrl}) {
    final index = list.indexWhere((element) => element.userName == userName);
    if (index != -1) {
      list[index].giftScore += amount;
      if (avatarUrl != null && avatarUrl.isNotEmpty && (list[index].avatarUrl.isEmpty || list[index].avatarUrl == 'assets/Asad/bg_vip_content.png')) {
        list[index] = RankingModel(
          userName: userName,
          avatarUrl: avatarUrl,
          giftScore: list[index].giftScore,
          timestamp: list[index].timestamp,
        );
      }
    } else {
      list.add(RankingModel(
        userName: userName,
        avatarUrl: avatarUrl?.isNotEmpty == true ? avatarUrl! : 'assets/Asad/bg_vip_content.png',
        giftScore: amount,
        timestamp: DateTime.now(),
      ));
    }
  }

  // --- Period info for UI ---

  String getDailyResetTime() {
    final egyptTime = DateTime.now().toUtc().add(const Duration(hours: 2));
    final nextMidnight = DateTime(egyptTime.year, egyptTime.month, egyptTime.day + 1);
    final remaining = nextMidnight.difference(egyptTime);
    return '${remaining.inHours}س ${remaining.inMinutes % 60}د';
  }

  String getWeeklyResetTime() {
    final egyptTime = DateTime.now().toUtc().add(const Duration(hours: 2));
    final daysUntilSunday = (DateTime.sunday - egyptTime.weekday) % 7;
    final nextSunday = DateTime(egyptTime.year, egyptTime.month, egyptTime.day + daysUntilSunday);
    final remaining = nextSunday.difference(egyptTime);
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    if (days > 0) return '$days يوم $hours س';
    return '$hours س ${remaining.inMinutes % 60}د';
  }

  String getMonthlyResetTime() {
    final egyptTime = DateTime.now().toUtc().add(const Duration(hours: 2));
    final daysInMonth = DateTime(egyptTime.year, egyptTime.month + 1, 0).day;
    final daysSinceReset = egyptTime.difference(_lastMonthlyReset).inDays;
    final remaining = daysInMonth - daysSinceReset;
    return '$remaining يوم';
  }
}
