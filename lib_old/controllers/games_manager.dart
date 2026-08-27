import 'package:flutter/material.dart';

class GameItem {
  final String id;
  final String title;
  final String description;
  final String icon;
  final Widget screen;
  final Color themeColor;

  GameItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.screen,
    required this.themeColor,
  });
}

class GamesManager extends ChangeNotifier {
  static final GamesManager _instance = GamesManager._internal();
  factory GamesManager() => _instance;

  GamesManager._internal() {
    debugPrint('Initializing: GamesManager');
  }

  final List<GameItem> _games = [];

  List<GameItem> get games => _games;

  void openGame(BuildContext context, String gameId) {
    final game = _games.firstWhere((g) => g.id == gameId);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => game.screen),
    );
  }
}
