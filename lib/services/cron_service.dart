import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/leaderboard_controller.dart';

class CronService {
  static final CronService _instance = CronService._internal();
  factory CronService() => _instance;
  CronService._internal();

  Timer? _dailyTimer;
  Timer? _weeklyTimer;
  Timer? _monthlyCheckTimer;

  void start() {
    _scheduleDailyReset();
    _scheduleWeeklyReset();
    _startMonthlyCheck();
  }

  void _scheduleDailyReset() {
    final now = DateTime.now();
    // Next midnight in Egypt time (UTC+2)
    final egyptNow = now.toUtc().add(const Duration(hours: 2));
    final nextMidnight = DateTime(egyptNow.year, egyptNow.month, egyptNow.day + 1);
    // Convert back to UTC for Timer
    final nextMidnightUtc = nextMidnight.subtract(const Duration(hours: 2));
    final duration = nextMidnightUtc.isAfter(now.toUtc())
        ? nextMidnightUtc.difference(now.toUtc())
        : const Duration(hours: 24);

    debugPrint('CronService: Daily reset in ${duration.inHours}h ${duration.inMinutes % 60}m');

    _dailyTimer?.cancel();
    _dailyTimer = Timer(duration, () {
      LeaderboardController().resetDailyRankings();
      _scheduleDailyReset();
    });
  }

  void _scheduleWeeklyReset() {
    final now = DateTime.now();
    final egyptNow = now.toUtc().add(const Duration(hours: 2));
    // Days until Sunday (7 = Sunday)
    final daysUntilSunday = (7 - egyptNow.weekday) % 7;
    final daysUntilSundayTarget = daysUntilSunday == 0 ? 7 : daysUntilSunday;
    final nextSundayMidnight = DateTime(egyptNow.year, egyptNow.month, egyptNow.day + daysUntilSundayTarget);
    final nextSundayUtc = nextSundayMidnight.subtract(const Duration(hours: 2));
    final duration = nextSundayUtc.difference(now.toUtc());

    debugPrint('CronService: Weekly reset in ${duration.inDays}d ${duration.inHours % 24}h');

    _weeklyTimer?.cancel();
    _weeklyTimer = Timer(duration, () {
      LeaderboardController().resetDailyRankings(); // Also resets weekly
      _scheduleWeeklyReset();
    });
  }

  void _startMonthlyCheck() {
    // Check every hour if monthly reset is needed
    _monthlyCheckTimer?.cancel();
    _monthlyCheckTimer = Timer.periodic(const Duration(hours: 1), (_) {
      // Monthly reset logic is handled inside LeaderboardController._checkAndResetPeriods()
      LeaderboardController().getRoomUserRankings('check');
    });
  }

  void stop() {
    _dailyTimer?.cancel();
    _weeklyTimer?.cancel();
    _monthlyCheckTimer?.cancel();
  }
}
