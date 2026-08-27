import 'package:flutter/material.dart';
import '../models/mic_seat.dart';

class MicControlsSheet extends StatelessWidget {
  final MicSeat seat;
  final bool isMe;
  final bool canManage;
  final Function(int) onJoin;
  final Function(int) onLeave;
  final Function(int) onToggleMute;
  final Function(int) onToggleLock;
  final Function(int) onKickToAudience;
  final Function(int) onInvite;

  const MicControlsSheet({
    super.key,
    required this.seat,
    required this.isMe,
    required this.canManage,
    required this.onJoin,
    required this.onLeave,
    required this.onToggleMute,
    required this.onToggleLock,
    required this.onKickToAudience,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF2C221E); // Dark Coffee
    const Color textColor = Colors.white;

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
              
              // 1. Take Mic (أخذ المايك)
              _buildActionItem(context, "أخذ المايك", textColor, () {
                onJoin(seat.index);
              }),

              // 2. Leave Mic (النزول من المايك) - Single Leave Mic button
              _buildActionItem(context, "النزول من المايك", textColor, () {
                onLeave(seat.index);
              }),

              // 3. Mute/Unmute Mic (كتم / فتح المايك) - Functional mute/unmute for any user
              _buildActionItem(context, seat.isMuted ? "فتح المايك" : "كتم المايك", textColor, () {
                onToggleMute(seat.index);
              }),

              // 4. Lock/Unlock Mic (قفل / فتح المايك)
              _buildActionItem(context, seat.isLocked ? "فتح المايك" : "قفل المايك", textColor, () {
                onToggleLock(seat.index);
              }),

              // 5. Seat Settings / Kick (إعدادات المايك / الطرد)
              _buildActionItem(context, "إعدادات المايك / الطرد", textColor, () {
                onKickToAudience(seat.index);
              }),

              const Divider(color: Colors.white10),

              // Cancel (إلغاء)
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
