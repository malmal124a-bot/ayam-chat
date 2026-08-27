import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class RoomTimerSheet extends StatefulWidget {
  const RoomTimerSheet({super.key});

  @override
  State<RoomTimerSheet> createState() => _RoomTimerSheetState();
}

class _RoomTimerSheetState extends State<RoomTimerSheet> {
  late Timer _timer;
  int _secondsRemaining = 3600; // 1 hour mock timer

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'وقت الجولة المتبقي',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            _formatTime(_secondsRemaining),
            style: TextStyle(
              color: AppTheme.royalGold,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white12, indent: 20, endIndent: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.white70, size: 20),
                SizedBox(width: 10),
                Text(
                  'سجل الفائزين السابقين',
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _HistoryItem(
                  round: 100 - index,
                  winner: ['صقر العرب', 'البرنسيسة', 'نجم الليل', 'الملك فهد', 'العنود'][index % 5],
                  prize: '${(index + 1) * 500} ماسة',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final int round;
  final String winner;
  final String prize;

  const _HistoryItem({required this.round, required this.winner, required this.prize});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الجولة #$round', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              Text(winner, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(prize, style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}