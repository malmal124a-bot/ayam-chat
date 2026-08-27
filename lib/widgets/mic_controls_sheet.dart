import 'package:flutter/material.dart';
import '../models/mic_seat.dart';

class MicControlsSheet extends StatelessWidget {
  final MicSeat seat;
  final bool isMe;
  final bool canManage;
  final bool isTargetMod;
  final Function(int) onJoin;
  final Function(int) onLeave;
  final Function(int) onToggleMute;
  final Function(int) onToggleLock;
  final Function(int) onKickToAudience;
  final Function(int) onInvite;
  final Function(int)? onBan;

  const MicControlsSheet({
    super.key,
    required this.seat,
    required this.isMe,
    required this.canManage,
    this.isTargetMod = false,
    required this.onJoin,
    required this.onLeave,
    required this.onToggleMute,
    required this.onToggleLock,
    required this.onKickToAudience,
    required this.onInvite,
    this.onBan,
  });

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF2C221E);
    const Color textColor = Colors.white;

    final bool seatEmpty = seat.userName == null || seat.userName!.isEmpty;
    final bool isLocked = seat.isLocked;
    final bool canManageTarget = canManage && !isMe && !isTargetMod;

    return Container(
      decoration: const BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 45,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),

              // Seat owner name header
              if (!seatEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    seat.userName ?? '',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),

              // 1. Empty seat: Take Mic
              if (seatEmpty && !isLocked)
                _buildActionItem(context, "أخذ المايك", textColor, () {
                  onJoin(seat.index);
                }),

              // 1b. Empty seat but LOCKED: Show locked message for regular users
              if (seatEmpty && isLocked && !canManage)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.redAccent, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'المقعد مغلق',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),

              // 1c. Empty seat LOCKED but owner/mod: Show unlock option
              if (seatEmpty && isLocked && canManage)
                _buildActionItem(context, "فتح المقعد", Colors.green, () {
                  onToggleLock(seat.index);
                }),

              // 2. My seat: Leave Mic
              if (isMe)
                _buildActionItem(context, "النزول من المايك", textColor, () {
                  onLeave(seat.index);
                }),

              // 3. Owner/Mod viewing another user's seat
              if (canManageTarget) ...[
                // Mute/Unmute
                _buildActionItem(
                  context,
                  seat.isMuted ? "فتح المايك (إلغاء الكتم)" : "كتم المايك",
                  seat.isMuted ? Colors.green : Colors.orange,
                  () => onToggleMute(seat.index),
                ),

                // Lock/Unlock (only for occupied seats; empty locked seats handled above)
                if (!seatEmpty)
                  _buildActionItem(
                    context,
                    seat.isLocked ? "فتح المقعد" : "قفل المقعد",
                    Colors.blue,
                    () => onToggleLock(seat.index),
                  ),

                // Kick to audience
                if (!seatEmpty)
                  _buildActionItem(context, "طرد من المقعد", Colors.deepOrange, () {
                    onKickToAudience(seat.index);
                  }),

                // Ban from room
                if (onBan != null && !seatEmpty)
                  _buildActionItem(context, "حظر نهائي من الغرفة", Colors.red, () {
                    onBan!(seat.index);
                  }),
              ],

              // 4. Regular user viewing another user's seat: No actions
              if (!isMe && !canManage)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'لا تملك صلاحية التحكم',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),

              const Divider(color: Colors.white10),

              // Cancel
              _buildActionItem(context, "إلغاء", Colors.redAccent, () {}),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String title, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }
}
