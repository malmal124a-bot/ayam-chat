import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'wallet_controller.dart';

class RocketStageInfo {
  final int stageNumber;
  final int targetDiamonds;
  double currentProgress; // 0.0 to 1.0

  RocketStageInfo({
    required this.stageNumber,
    required this.targetDiamonds,
    this.currentProgress = 0.0,
  });
}

class RocketController extends ChangeNotifier {
  static final RocketController _instance = RocketController._internal();
  factory RocketController() => _instance;

  RocketController._internal() {
    _initializeStages();
  }

  int _currentStageIndex = 0;
  final List<RocketStageInfo> _stages = [];
  
  // Reward Pool for the active launched rocket
  int _currentRewardPool = 0;
  int _claimsRemainingLarge = 0;
  int _claimsRemainingSmall = 0;
  String? _activeRoomId;
  String? _activeRoomName;
  int? _launchedStageNumber;

  // Level selection for the Super Prize Screen UI
  int _selectedLevel = 5;

  // Global Announcement state
  String? _globalAnnouncement;
  bool _showLocalAnimation = false;

  bool _isDisposed = false;

  void _initializeStages() {
    _stages.add(RocketStageInfo(stageNumber: 1, targetDiamonds: 5000));
    _stages.add(RocketStageInfo(stageNumber: 2, targetDiamonds: 15000));
    _stages.add(RocketStageInfo(stageNumber: 3, targetDiamonds: 50000));
    _stages.add(RocketStageInfo(stageNumber: 4, targetDiamonds: 150000));
    _stages.add(RocketStageInfo(stageNumber: 5, targetDiamonds: 500000));
  }

  RocketStageInfo get currentStage => _stages[_currentStageIndex];
  int get currentStageNumber => currentStage.stageNumber;
  int? get launchedStageNumber => _launchedStageNumber;
  double get progress => currentStage.currentProgress;
  double get progressPercentage => (progress * 100).clamp(0.0, 100.0);
  
  int get selectedLevel => _selectedLevel;
  void selectLevel(int level) {
    _selectedLevel = level;
    safeNotify();
  }

  bool get isRewardBoxVisible => _currentRewardPool > 0;
  bool get showLocalAnimation => _showLocalAnimation;
  String? get globalAnnouncement => _globalAnnouncement;
  String? get activeRoomId => _activeRoomId;
  String? get activeRoomName => _activeRoomName;

  void contributeDiamonds(int diamonds, String roomId, String roomName) {
    if (_currentStageIndex >= _stages.length) return;

    double increment = diamonds / currentStage.targetDiamonds;
    currentStage.currentProgress += increment;

    if (currentStage.currentProgress >= 1.0) {
      _launchRocket(roomId, roomName);
    } else {
      safeNotify();
    }
  }

  // Alias for backward compatibility
  void contributeCoins(int coins, String roomId, String roomName) => contributeDiamonds(coins, roomId, roomName);

  void _launchRocket(String roomId, String roomName) {
    _launchedStageNumber = currentStage.stageNumber;
    _currentRewardPool = (currentStage.targetDiamonds * 0.1).toInt();
    _claimsRemainingLarge = 6 + Random().nextInt(2); 
    _claimsRemainingSmall = 20 + Random().nextInt(11);
    _activeRoomId = roomId;
    _activeRoomName = roomName;

    // Trigger local animation flag
    _showLocalAnimation = true;
    
    // Set Global Banner message
    _globalAnnouncement = "🚀 Rocket Stage $_launchedStageNumber launched in $roomName! Join now to catch rewards!";

    // Reset progress and advance stage
    currentStage.currentProgress = 0.0;
    if (_currentStageIndex < _stages.length - 1) {
      _currentStageIndex++;
    } else {
      _currentStageIndex = 0; // Loop back to Stage 1
    }

    // Reset local animation flag after a delay
    Timer(const Duration(seconds: 8), () {
      _showLocalAnimation = false;
      safeNotify();
    });

    // Clear Global Banner after 15 seconds
    Timer(const Duration(seconds: 15), () {
      _globalAnnouncement = null;
      _launchedStageNumber = null;
      safeNotify();
    });

    // Auto-clear reward box after 60 seconds if not claimed
    Timer(const Duration(seconds: 60), () {
      _currentRewardPool = 0;
      _activeRoomId = null;
      safeNotify();
    });

    safeNotify();
  }

  Map<String, dynamic> claimReward() {
    if (!isRewardBoxVisible) return {'ok': false, 'message': 'انتهى وقت المكافأة'};

    final wallet = WalletController();
    
    int rewardAmount = 0;
    bool isLarge = false;

    if (_claimsRemainingLarge > 0) {
      rewardAmount = (_currentRewardPool ~/ 10) + Random().nextInt(50);
      _claimsRemainingLarge--;
      isLarge = true;
    } else if (_claimsRemainingSmall > 0) {
      rewardAmount = (_currentRewardPool ~/ 50) + Random().nextInt(10);
      _claimsRemainingSmall--;
    } else {
      _currentRewardPool = 0;
      safeNotify();
      return {'ok': false, 'message': 'تم استلام جميع الهدايا'};
    }

    wallet.addDiamonds(rewardAmount);
    
    if (_claimsRemainingLarge == 0 && _claimsRemainingSmall == 0) {
      _currentRewardPool = 0;
    }

    safeNotify();
    return {
      'ok': true, 
      'amount': rewardAmount, 
      'isLarge': isLarge,
      'message': 'لقد حصلت على $rewardAmount ماسة!'
    };
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (_isDisposed) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }
}
