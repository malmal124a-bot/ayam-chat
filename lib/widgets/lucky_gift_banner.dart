import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/gift_manager.dart';
import 'app_icon.dart';

class LuckyGiftBanner extends StatelessWidget {
  const LuckyGiftBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // We use context.watch to rebuild when GiftManager notifies
    final manager = context.watch<GiftManager>();
    final win = manager.luckyGiftWins.isNotEmpty ? manager.luckyGiftWins.last : null;

    // The Positioned must be a direct child of the Stack where LuckyGiftBanner is used.
    // If we use AnimatedSwitcher here, it must be inside the Positioned.
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        reverseDuration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0), // Slide in from right
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        child: win == null
            ? const SizedBox.shrink()
            : _BannerContent(win: win, key: ValueKey(win.uniqueId)),
      ),
    );
  }
}

class _BannerContent extends StatelessWidget {
  final LuckyGiftWinInfo win;
  const _BannerContent({required this.win, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade700,
            Colors.deepPurpleAccent,
            Colors.blue.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          const Text("🎉", style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                "User ${win.userName} won ${win.multiplier} on ${win.giftName} in Room ${win.roomId}!",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          const AppIcon('Icons.stars', icon: Icons.stars, color: Colors.amber, size: 20),
        ],
      ),
    );
  }
}
