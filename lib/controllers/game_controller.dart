import 'package:flutter/material.dart';

enum GameCategory { betting, entertainment }

class GameModel {
  final String id;
  final String title;
  final IconData icon;
  final String? imageAsset; // Added for custom icons
  final Color themeColor;
  final GameCategory category;

  const GameModel({
    required this.id,
    required this.title,
    required this.icon,
    this.imageAsset,
    required this.themeColor,
    required this.category,
  });
}

class GameController extends ChangeNotifier {
  static final GameController _instance = GameController._internal();
  factory GameController() => _instance;

  GameController._internal() {
    debugPrint('Initializing: GameController');
  }

  // --- HIDING GAME 77 FROM UI AS PER INSTRUCTION (Logic preserved via comments) ---
  final List<GameModel> games = const [
    // --- Tab 1: ألعاب مراهنات (Betting/Luck Games) ---
    /* 
    GameModel(
      id: 'lucky_77',
      title: '77 الحظ',
      icon: Icons.casino_rounded,
      imageAsset: 'assets/icons/lucky_77_logo.png',
      themeColor: Colors.amber,
      category: GameCategory.betting,
    ),
    */
    
    // --- Tab 2: ألعاب ترفيهية (Casual/Entertainment Games) ---
    // Add more games here when ready
  ];

  List<GameModel> get bettingGames => games.where((g) => g.category == GameCategory.betting).toList();
  List<GameModel> get entertainmentGames => games.where((g) => g.category == GameCategory.entertainment).toList();

  void safeNotify() => notifyListeners();
}
