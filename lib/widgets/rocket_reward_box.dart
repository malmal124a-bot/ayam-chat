import 'package:flutter/material.dart';
import '../controllers/rocket_controller.dart';

class RocketRewardBox extends StatefulWidget {
  final VoidCallback onClaimed;

  const RocketRewardBox({Key? key, required this.onClaimed}) : super(key: key);

  @override
  State<RocketRewardBox> createState() => _RocketRewardBoxState();
}

class _RocketRewardBoxState extends State<RocketRewardBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 10 * _controller.value),
          child: GestureDetector(
            onTap: () {
              final result = RocketController().claimReward();
              if (result['ok']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
                widget.onClaimed();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/Asad/gift_box.png', // Assuming this exists or using a fallback
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.card_giftcard,
                  color: Colors.yellow,
                  size: 50,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
