import 'package:flutter/material.dart';
import '../../controllers/room_ui_controller.dart';

class AudioTabWidget extends StatelessWidget {
  final RoomUiController controller;

  const AudioTabWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إعدادات المايكات والصوت',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMicOption(
                    icon: controller.isUserMicEnabled ? Icons.mic : Icons.mic_none,
                    label: 'فتح المايك',
                    color: controller.isUserMicEnabled ? Colors.green : Colors.white38,
                    onTap: () => controller.toggleUserMic(),
                  ),
                  _buildMicOption(
                    icon: controller.isUserMuted ? Icons.mic_off : Icons.mic_off_outlined,
                    label: 'كتم المايك',
                    color: controller.isUserMuted ? Colors.red : Colors.white38,
                    onTap: () => controller.toggleUserMute(),
                  ),
                  _buildMicOption(
                    icon: controller.isRoomAudioEnabled ? Icons.volume_up : Icons.volume_off,
                    label: 'مستوى الصوت',
                    color: controller.isRoomAudioEnabled ? Colors.amber : Colors.white38,
                    onTap: () => controller.toggleRoomAudio(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMicOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
