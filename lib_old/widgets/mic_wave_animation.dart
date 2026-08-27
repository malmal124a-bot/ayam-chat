import 'package:flutter/material.dart';

class MicWaveAnimation extends StatefulWidget {
  final bool isAnimating;
  final Widget child;
  final Color waveColor;

  const MicWaveAnimation({
    super.key,
    required this.isAnimating,
    required this.child,
    this.waveColor = Colors.amber,
  });

  @override
  State<MicWaveAnimation> createState() => _MicWaveAnimationState();
}

class _MicWaveAnimationState extends State<MicWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(MicWaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(
            animationValue: _animation.value,
            waveColor: widget.waveColor,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color waveColor;

  _WavePainter({
    required this.animationValue,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (animationValue <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 + 10;

    // Draw 3 concentric waves
    for (int i = 0; i < 3; i++) {
      final waveProgress = (animationValue + i * 0.33) % 1.0;
      final radius = maxRadius * waveProgress;
      final alpha = (1.0 - waveProgress) * 0.5;

      final paint = Paint()
        ..color = waveColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
