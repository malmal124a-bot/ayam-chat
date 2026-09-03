import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'package:video_player/video_player.dart';
import '../utils/image_utils.dart';
import '../services/svga_asset_service.dart';
import 'app_icon.dart';

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

bool _isVideoFile(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.webm');
}

bool _isVapFile(String path) {
  return path.toLowerCase().endsWith('.vap');
}

class _AlphaGiftPlayerState extends State<AlphaGiftPlayer> with SingleTickerProviderStateMixin {
  SVGAAnimationController? _svgaController;
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _svgaController = SVGAAnimationController(vsync: this);
    _svgaController!.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.loops != 0) {
        widget.onFinished?.call();
      }
    });
    _loadAnimation();
  }

  void _loadAnimation() async {
    final resolved = await SvgaAssetService.instance.resolve(widget.svgaPath);

    if (_isVideoFile(resolved)) {
      _loadVideo(resolved);
    } else {
      _loadSvga(resolved);
    }
  }

  void _loadVideo(String path) async {
    _isVideo = true;
    try {
      if (ImageUtils.isHttpUrl(path)) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(path));
      } else if (!kIsWeb && Platform.isAndroid) {
        // For local/asset paths on Android, try network-style loading
        _videoController = VideoPlayerController.asset(path);
      } else {
        _videoController = VideoPlayerController.asset(path);
      }

      await _videoController!.initialize();
      _videoController!.setLooping(widget.loops == 0);
      _videoController!.setVolume(0);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _videoController!.play();
        _videoController!.addListener(() {
          if (_videoController!.value.position >= _videoController!.value.duration &&
              widget.loops == 1) {
            widget.onFinished?.call();
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading video asset ($path): $e");
      widget.onFinished?.call();
    }
  }

  void _loadSvga(String path) async {
    _isVideo = false;
    final parser = SVGAParser();
    try {
      final videoItem = ImageUtils.isHttpUrl(path)
          ? await parser.decodeFromURL(path)
          : await parser.decodeFromAssets(path);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _svgaController!.videoItem = videoItem;
          if (widget.loops == 0) {
            _svgaController!.repeat();
          } else {
            _svgaController!.forward();
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading SVGA asset ($path): $e");
      widget.onFinished?.call();
    }
  }

  @override
  void dispose() {
    _svgaController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: AppIcon(
          'Icons.rocket_launch', icon: Icons.rocket_launch,
          color: Color(0xFFFFD700),
          size: 60,
        ),
      );
    }

    // Video player (MP4)
    if (_isVideo && _videoController != null && _videoController!.value.isInitialized) {
      return IgnorePointer(
        ignoring: true,
        child: SizedBox.expand(
          child: Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
      );
    }

    // SVGA player
    if (_svgaController != null && _svgaController!.videoItem != null) {
      return IgnorePointer(
        ignoring: true,
        child: SizedBox.expand(
          child: Center(
            child: SVGAImage(
              _svgaController!,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    return const Center(
      child: AppIcon(
        'Icons.rocket_launch', icon: Icons.rocket_launch,
        color: Color(0xFFFFD700),
        size: 60,
      ),
    );
  }
}
