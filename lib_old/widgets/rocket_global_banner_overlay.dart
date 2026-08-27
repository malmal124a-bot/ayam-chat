import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rocket_controller.dart';
import '../constants/rocket_assets.dart';
import '../screens/voice_room_screen.dart';
import 'alpha_gift_player.dart';

class RocketGlobalBannerOverlay extends StatelessWidget {
  const RocketGlobalBannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RocketController>(
      builder: (context, rocketCtrl, _) {
        final message = rocketCtrl.globalAnnouncement;
        if (message == null) return const SizedBox.shrink();

        return Stack(
          children: [
            // 1. Global Rocket Explosion Animation originating from center
            if (rocketCtrl.showLocalAnimation && rocketCtrl.launchedStageNumber != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: SizedBox(
                      width: 450,
                      height: 450,
                      child: AlphaGiftPlayer(
                        svgaPath: RocketSvgaAssets.getExplosionSvga(rocketCtrl.launchedStageNumber!),
                      ),
                    ),
                  ),
                ),
              ),

            // 2. Smooth animated top banner
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  if (rocketCtrl.activeRoomId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VoiceRoomScreen(
                          roomId: rocketCtrl.activeRoomId,
                          roomName: rocketCtrl.activeRoomName ?? "غرفة الصاروخ",
                        ),
                      ),
                    );
                  }
                },
                child: SizedBox(
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Banner Background SVGA
                      AlphaGiftPlayer(
                        svgaPath: RocketSvgaAssets.getBroadcastSvga(rocketCtrl.launchedStageNumber ?? 1),
                      ),
                      
                      // Marquee Text Overlay
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: SizedBox(
                          height: 24,
                          child: MarqueeWidget(text: message),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class MarqueeWidget extends StatefulWidget {
  final String text;
  const MarqueeWidget({super.key, required this.text});

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      double maxScroll = _scrollController.position.maxScrollExtent;
      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: maxScroll.toInt() * 35),
        curve: Curves.linear,
      );
      if (!mounted) return;
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Text(
          widget.text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 250),
      ],
    );
  }
}
