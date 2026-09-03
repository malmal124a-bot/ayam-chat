import 'package:flutter/material.dart';
import '../app_icon.dart';

class RoomSideActionsWidget extends StatelessWidget {
  final VoidCallback onRocketTap;
  final VoidCallback onGamesTap;

  const RoomSideActionsWidget({
    super.key,
    required this.onRocketTap,
    required this.onGamesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rocket Icon (الصاروخ)
        _sideIcon(Icons.rocket_launch_rounded, onRocketTap),
        
        const SizedBox(height: 19), // Positioned 0.5 cm (~19px) directly above Playstation Controller

        // Gamepad Icon (ذراع الألعاب) - PlayStation Controller
        GestureDetector(
          onTap: onGamesTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/icon_fun_game.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const AppIcon(
                  'Icons.sports_esports_rounded', icon: Icons.sports_esports_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sideIcon(IconData icon, VoidCallback onTap, {double size = 42}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}
