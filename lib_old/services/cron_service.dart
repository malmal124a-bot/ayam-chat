import 'dart:async';
import 'package:flutter/foundation.dart';
import '../controllers/leaderboard_controller.dart';

class CronService {
  static final CronService _instance = CronService._internal();
  factory CronService() => _instance;
  CronService._internal();

  Timer? _dailyTimer;

  void start() {
    _scheduleNextReset();
  }

  void _scheduleNextReset() {
    final now = DateTime.now();
    // Calculate 12:00 AM of the next day
    final nextReset = DateTime(now.year, now.month, now.day + 1);
    final duration = nextReset.difference(now);

    debugPrint('Scheduling Daily Reset in: ${duration.inHours}h ${duration.inMinutes % 60}m');

    _dailyTimer?.cancel();
    _dailyTimer = Timer(duration, () {
      _performReset();
      // Reschedule for the next day
      _scheduleNextReset();
    });
  }

  void _performReset() {
    debugPrint('Executing Cron Job: Daily Points Reset');
    LeaderboardController().resetDailyRankings();
  }

  void stop() {
    _dailyTimer?.cancel();
  }
}
