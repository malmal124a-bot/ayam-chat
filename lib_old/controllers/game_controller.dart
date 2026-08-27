import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_controller.dart';
import 'wallet_controller.dart';

enum GameCategory { betting, entertainment }

class GameModel {
  final String id;
  final String title;
  final IconData icon;
  final String? imageAsset;
  final Color themeColor;
  final GameCategory category;
  final int entryFee;

  const GameModel({
    required this.id,
    required this.title,
    required this.icon,
    this.imageAsset,
    required this.themeColor,
    required this.category,
    this.entryFee = 0,
  });
}

class GameSession {
  final String id;
  final String gameId;
  final String gameTitle;
  final String userId;
  final String userName;
  final int betAmount;
  final int winAmount;
  final bool isWin;
  final DateTime createdAt;
  final int durationSeconds;

  GameSession({
    required this.id,
    required this.gameId,
    required this.gameTitle,
    required this.userId,
    required this.userName,
    required this.betAmount,
    required this.winAmount,
    required this.isWin,
    required this.createdAt,
    this.durationSeconds = 0,
  });
}

class GameController extends ChangeNotifier {
  static final GameController _instance = GameController._internal();
  factory GameController() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GameController._internal() {
    debugPrint('Initializing: GameController');
    _listenToFirestore();
  }

  void _listenToFirestore() {
    final userId = UserController().id;
    if (userId.isEmpty) return;
    
    // Listen to user's game history
    _firestore.collection('users').doc(userId).collection('game_history')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      _gameHistory.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _gameHistory.add(GameSession(
          id: doc.id,
          gameId: data['gameId'] ?? '',
          gameTitle: data['gameTitle'] ?? '',
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? '',
          betAmount: (data['betAmount'] as num?)?.toInt() ?? 0,
          winAmount: (data['winAmount'] as num?)?.toInt() ?? 0,
          isWin: data['isWin'] as bool? ?? false,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
        ));
      }
      _updateStats();
      notifyListeners();
    });

    // Listen to global game leaderboard
    _firestore.collection('game_leaderboard')
        .orderBy('totalWins', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
      _leaderboard.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _leaderboard.add({
          'userId': doc.id,
          'userName': data['userName'] ?? '',
          'totalWins': (data['totalWins'] as num?)?.toInt() ?? 0,
          'totalLosses': (data['totalLosses'] as num?)?.toInt() ?? 0,
          'totalEarnings': (data['totalEarnings'] as num?)?.toInt() ?? 0,
        });
      }
      notifyListeners();
    });
  }

  final List<GameModel> games = const [
    // Add new games here when ready
  ];

  final List<GameSession> _gameHistory = [];
  final List<Map<String, dynamic>> _leaderboard = [];
  
  int _totalWins = 0;
  int _totalLosses = 0;
  int _totalEarnings = 0;

  List<GameSession> get gameHistory => _gameHistory;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  int get totalWins => _totalWins;
  int get totalLosses => _totalLosses;
  int get totalEarnings => _totalEarnings;

  List<GameModel> get bettingGames => games.where((g) => g.category == GameCategory.betting).toList();
  List<GameModel> get entertainmentGames => games.where((g) => g.category == GameCategory.entertainment).toList();

  void _updateStats() {
    _totalWins = _gameHistory.where((s) => s.isWin).length;
    _totalLosses = _gameHistory.where((s) => !s.isWin).length;
    _totalEarnings = _gameHistory.fold(0, (int total, GameSession session) => total + session.winAmount - session.betAmount);
  }

  Future<void> recordGameSession({
    required String gameId,
    required String gameTitle,
    required int betAmount,
    required int winAmount,
    required bool isWin,
    int durationSeconds = 0,
  }) async {
    try {
      final user = UserController();
      final wallet = WalletController();
      
      // Update wallet balance
      if (isWin) {
        wallet.addDiamonds(winAmount);
      } else {
        wallet.spendDiamonds(betAmount);
      }

      // Save to Firestore
      await _firestore.collection('users').doc(user.id).collection('game_history')
          .add({
        'gameId': gameId,
        'gameTitle': gameTitle,
        'userId': user.id,
        'userName': user.name,
        'betAmount': betAmount,
        'winAmount': winAmount,
        'isWin': isWin,
        'durationSeconds': durationSeconds,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update global leaderboard
      await _firestore.collection('game_leaderboard').doc(user.id).set({
        'userName': user.name,
        'totalWins': FieldValue.increment(isWin ? 1 : 0),
        'totalLosses': FieldValue.increment(isWin ? 0 : 1),
        'totalEarnings': FieldValue.increment(winAmount - betAmount),
        'lastPlayed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error recording game session: $e');
    }
  }

  Future<void> createGameSession({
    required String gameId,
    required String gameTitle,
    required String roomId,
    required List<String> playerIds,
  }) async {
    try {
      await _firestore.collection('game_sessions').add({
        'gameId': gameId,
        'gameTitle': gameTitle,
        'roomId': roomId,
        'playerIds': playerIds,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating game session: $e');
    }
  }

  Future<void> joinGameSession(String sessionId, String userId) async {
    try {
      await _firestore.collection('game_sessions').doc(sessionId).update({
        'playerIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error joining game session: $e');
    }
  }

  void safeNotify() => notifyListeners();
}
