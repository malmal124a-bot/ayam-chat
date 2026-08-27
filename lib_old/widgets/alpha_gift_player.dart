import 'package:flutter/material.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';

class AlphaGiftPlayer extends StatefulWidget {
  final String svgaPath;
  final VoidCallback? onFinished;
  final int loops;

  const AlphaGiftPlayer({
    super.key,
    required this.svgaPath,
    this.onFinished,
    this.loops = 1,
  });

  @override
  State<AlphaGiftPlayer> createState() => _AlphaGiftPlayerState();
}

class _AlphaGiftPlayerState extends State<AlphaGiftPlayer> with SingleTickerProviderStateMixin {
  late SVGAAnimationController _svgaController;

  @override
  void initState() {
    super.initState();
    _svgaController = SVGAAnimationController(vsync: this);
    _svgaController.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.loops != 0) {
        widget.onFinished?.call();
      }
    });
    _loadAnimation();
  }

  void _loadAnimation() async {
    String cleanPath = widget.svgaPath.trim();
    while (cleanPath.startsWith('assets/assets/')) {
      cleanPath = cleanPath.replaceFirst('assets/assets/', 'assets/');
    }
    if (!cleanPath.startsWith('assets/')) {
      cleanPath = 'assets/$cleanPath';
    }

    final parser = SVGAParser();
    try {
      final videoItem = await parser.decodeFromAssets(cleanPath);
      if (mounted) {
        setState(() {
          _svgaController.videoItem = videoItem;
          
          // Proper SVGA looping logic:
          // Use repeat() for infinite looping (loops: 0)
          // or forward() for a single playback sequence.
          if (widget.loops == 0) {
            _svgaController.repeat();
          } else {
            _svgaController.forward();
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading SVGA asset ($cleanPath): $e");
      widget.onFinished?.call();
    }
  }

  @override
  void dispose() {
    _svgaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_svgaController.videoItem == null) {
      // Fallback display while loading or if failed
      return const Center(
        child: Icon(
          Icons.rocket_launch,
          color: Color(0xFFFFD700),
          size: 60,
        ),
      );
    }
    return IgnorePointer(
      ignoring: true,
      child: SizedBox.expand(
        child: Center(
          child: SVGAImage(
            _svgaController,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
