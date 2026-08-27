import 'package:flutter/material.dart';

class RoomBottomDockWidget extends StatelessWidget {
  final bool micEnabled;
  final bool isMuted;
  final bool roomAudioEnabled;
  final bool isUserOnMic;
  final bool canManageRoom;
  final VoidCallback onMicToggle;
  final VoidCallback onMuteToggle;
  final VoidCallback onAudioToggle;
  final VoidCallback onChatTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onGiftTap;
  final VoidCallback onMessagesTap;
  final VoidCallback onEmotionsTap;

  const RoomBottomDockWidget({
    super.key,
    required this.micEnabled,
    required this.isMuted,
    required this.roomAudioEnabled,
    required this.isUserOnMic,
    required this.canManageRoom,
    required this.onMicToggle,
    required this.onMuteToggle,
    required this.onAudioToggle,
    required this.onChatTap,
    required this.onSettingsTap,
    required this.onGiftTap,
    required this.onMessagesTap,
    required this.onEmotionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          // 1. Chat Input Field
          Expanded(
            child: GestureDetector(
              onTap: onChatTap,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Image.asset('assets/Asad/func_chat.png', width: 16, height: 16, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 16)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'قل شيئاً...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Action Icons Row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dockAssetIcon('assets/Asad/icon_fun_gift.png', onGiftTap),
              const SizedBox(width: 4),
              _dockAssetIcon('assets/Asad/func_chat.png', onMessagesTap),
              const SizedBox(width: 4),
              if (isUserOnMic) ...[
                _dockAssetIcon('assets/Asad/func_emoji.png', onEmotionsTap),
                const SizedBox(width: 4),
              ],
              if (canManageRoom) ...[
                _dockAssetIcon('assets/Asad/func_room_more.png', onSettingsTap),
                const SizedBox(width: 4),
              ],
              _dockAssetIcon(
                isMuted ? 'assets/Asad/func_voice_silence.png' : 'assets/Asad/func_voice.png',
                onMuteToggle,
              ),
              const SizedBox(width: 4),
              _dockAssetIcon(
                roomAudioEnabled ? 'assets/Asad/func_unmute.png' : 'assets/Asad/func_mute.png',
                onAudioToggle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dockAssetIcon(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to generic icon if asset not found
            return const Icon(
              Icons.error_outline,
              color: Colors.white54,
              size: 18,
            );
          },
        ),
      ),
    );
  }
}
