import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rocket_controller.dart';
import '../screens/voice_room_screen.dart';
import '../constants/rocket_assets.dart';
import 'alpha_gift_player.dart';

class RocketGlobalBanner extends StatelessWidget {
  const RocketGlobalBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RocketController>(
      builder: (context, rocketCtrl, child) {
        final message = rocketCtrl.globalAnnouncement;
        if (message == null) return const SizedBox.shrink();

        return Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              if (rocketCtrl.activeRoomId != null) {
                // Navigate to the room
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
                  // BROADCAST BANNER SVGA BINDING
                  AlphaGiftPlayer(
                    svgaPath: RocketSvgaAssets.getBroadcastSvga(rocketCtrl.launchedStageNumber ?? 1),
                  ),
                  
                  // Text Overlay
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: SizedBox(
                      height: 24,
                      child: _MarqueeWidget(text: message),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MarqueeWidget extends StatefulWidget {
  final String text;
  const _MarqueeWidget({required this.text});

  @override
  State<_MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<_MarqueeWidget> with SingleTickerProviderStateMixin {
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
        duration: Duration(milliseconds: maxScroll.toInt() * 30),
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
        const SizedBox(width: 100),
      ],
    );
  }
}
