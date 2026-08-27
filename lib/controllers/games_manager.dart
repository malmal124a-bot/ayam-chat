import 'package:flutter/material.dart';
import 'package:ayam_chat/screens/lucky_77_game_screen.dart';

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

  final List<GameItem> _games = [
    GameItem(
      id: 'lucky_77',
      title: 'Lucky 77',
      description: 'ماكينة الحظ للفوز بالماسات',
      icon: 'assets/icons/lucky_77_logo.png',
      screen: const Lucky77GameScreen(),
      themeColor: const Color(0xFFFFD700),
    ),
    GameItem(
      id: 'ludo',
      title: 'Ludo Classic',
      description: 'لعبة لودو الشهيرة مع الأصدقاء',
      icon: 'assets/icons/lucky_77_logo.png', // Placeholder
      screen: const Lucky77GameScreen(), // Placeholder
      themeColor: Colors.blue,
    ),
    GameItem(
      id: 'domino',
      title: 'Dominoes',
      description: 'تحدي الدومينو في غرف الصوت',
      icon: 'assets/icons/lucky_77_logo.png', // Placeholder
      screen: const Lucky77GameScreen(), // Placeholder
      themeColor: Colors.red,
    ),
  ];

  List<GameItem> get games => _games;

  void openGame(BuildContext context, String gameId) {
    final game = _games.firstWhere((g) => g.id == gameId);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => game.screen),
    );
  }
}
