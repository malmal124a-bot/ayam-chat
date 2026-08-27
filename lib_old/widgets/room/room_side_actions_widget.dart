import 'package:flutter/material.dart';
import '../games_sheet_widget.dart';

class RoomSideActionsWidget extends StatelessWidget {
  final VoidCallback onRocketTap;

  const RoomSideActionsWidget({
    super.key,
    required this.onRocketTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rocket Icon (الصاروخ)
        _sideIcon(Icons.rocket_launch_rounded, onRocketTap),
        
        const SizedBox(height: 19), // Positioned 0.5 cm (~19px) directly above Gamepad

        // Gamepad Icon (الألعاب) - PlayStation Controller Design
        GestureDetector(
          onTap: () {
            showGamesModal(context);
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.withValues(alpha: 0.6), width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icons/gamepad.png',
                width: 35,
                height: 35,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.sports_esports,
                  color: Colors.amber,
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
