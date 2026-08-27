import 'package:flutter/material.dart';

// 2. تصميم ودجت المايك مع تأثير الذبذبة/الرعشة عند الكلام (Audio Wave Ripple Effect)
class AnimatedMicWidget extends StatefulWidget {
  final bool isSpeaking;
  final String? userAvatar;
  final String userName;
  final VoidCallback onTap;

  const AnimatedMicWidget({
    super.key,
    required this.isSpeaking,
    this.userAvatar,
    required this.userName,
    required this.onTap,
  });

  @override
  State<AnimatedMicWidget> createState() => _AnimatedMicWidgetState();
}

class _AnimatedMicWidgetState extends State<AnimatedMicWidget> with SingleTickerProviderStateMixin {
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
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.all(widget.isSpeaking ? 4.0 * _controller.value + 2 : 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSpeaking ? Colors.amberAccent : Colors.grey.withValues(alpha: 0.5),
                    width: widget.isSpeaking ? 3.0 : 1.5,
                  ),
                  boxShadow: widget.isSpeaking
                      ? [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.6 * _controller.value),
                            blurRadius: 10 * _controller.value,
                            spreadRadius: 4 * _controller.value,
                          )
                        ]
                      : [],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: widget.userAvatar != null && widget.userAvatar!.isNotEmpty
                      ? NetworkImage(widget.userAvatar!)
                      : null,
                  child: widget.userAvatar == null || widget.userAvatar!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            widget.userName,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
