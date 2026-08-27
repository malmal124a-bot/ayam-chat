import 'dart:async';
import 'package:flutter/material.dart';

class GameLoadingScreen extends StatefulWidget {
  final String gameTitle;
  final Widget nextScreen;
  final String logoAsset;

  const GameLoadingScreen({
    super.key,
    required this.gameTitle,
    required this.nextScreen,
    required this.logoAsset,
  });

  @override
  State<GameLoadingScreen> createState() => _GameLoadingScreenState();
}

class _GameLoadingScreenState extends State<GameLoadingScreen> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() {
    const duration = Duration(milliseconds: 50);
    _timer = Timer.periodic(duration, (timer) {
      setState(() {
        _progress += 0.02;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _timer?.cancel();
          _navigateToGame();
        }
      });
    });
  }

  void _navigateToGame() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => widget.nextScreen),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000B18),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(widget.logoAsset, width: 150, height: 150),
            const SizedBox(height: 40),
            Text(
              widget.gameTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white12,
                color: const Color(0xFFFFD700),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'جاري تحميل اللعبة...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
