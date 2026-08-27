import 'package:flutter/material.dart';
import '../models/store_item.dart';
import 'alpha_gift_player.dart';

class EntryEffectPlayer extends StatefulWidget {
  final StoreItem item;
  final String userName;
  final VoidCallback onFinished;

  const EntryEffectPlayer({
    super.key,
    required this.item,
    required this.userName,
    required this.onFinished,
  });

  @override
  State<EntryEffectPlayer> createState() => _EntryEffectPlayerState();
}

class _EntryEffectPlayerState extends State<EntryEffectPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10.0),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 80.0),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 10.0),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onFinished());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getSvgaPath(String pngPath) {
    // Mapping logic based on available assets and user instructions
    if (pngPath.contains('#159')) return 'assets/entry_effects/#159_+e+µ++¦¼_rand.svga';
    if (pngPath.contains('#426')) return 'assets/entry_effects/#426_+¦¦8+_¦¦.svga';
    if (pngPath.contains('#472')) return 'assets/entry_effects/#472_-·-f¦8-¦.svga';
    
    // Default fallback: Replace .png with .svga or follow _cand pattern if exists
    return pngPath.replaceAll('.png', '.svga');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full screen SVGA animation
        Positioned.fill(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AlphaGiftPlayer(
              svgaPath: _getSvgaPath(widget.item.imagePath),
              onFinished: () {}, // Handled by _controller
            ),
          ),
        ),
        
        // Entry Text Overlay
        Align(
          alignment: const Alignment(0, 0.3),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                      shadows: [Shadow(blurRadius: 10.0, color: Colors.black)],
                    ),
                  ),
                  Text(
                    'دخل الغرفة بـ ${widget.item.name}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
