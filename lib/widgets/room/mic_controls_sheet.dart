import 'package:flutter/material.dart';
import '../../models/mic_seat.dart';

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
    const Color bgColor = Color(0xFF1E1E2C);
    const Color textColor = Colors.white;

    return Container(
      decoration: const BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            
            // Fix RenderFlex Overflow Error by using Flexible + SingleChildScrollView
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. "أخذ المايك" (Take Mic) - Available for all if seat is empty and unlocked
                    if (seat.userName == null || seat.userName!.isEmpty)
                      _buildActionItem(context, "أخذ المايك", textColor, () => onJoin(seat.index)),

                    // 3. "النزول من على المايك" (Leave Mic) - Available for all if seated
                    if (seat.userName != null && seat.userName!.isNotEmpty)
                      _buildActionItem(context, "النزول من على المايك", Colors.redAccent, () => onLeave(seat.index)),

                    // OWNER-ONLY ACTIONS
                    if (canManage) ...[
                      // 2. "إقفال المايك / فتح المايك" (Lock/Unlock Mic Slot)
                      _buildActionItem(context, seat.isLocked ? "فتح المايك" : "إقفال المايك", textColor, () => onToggleLock(seat.index)),
                      
                      // 5. "عمل ميوت لأي حد" (Mute Target User)
                      if (seat.userName != null && seat.userName!.isNotEmpty)
                        _buildActionItem(context, seat.isMuted ? "إلغاء ميوت" : "عمل ميوت لأي حد", textColor, () => onToggleMute(seat.index)),
                      
                      // 4. "أنزل أي حد من على المايك" (Kick Target User from Mic)
                      if (seat.userName != null && seat.userName!.isNotEmpty)
                        _buildActionItem(context, "أنزل أي حد من على المايك", Colors.orangeAccent, () => onKickToAudience(seat.index)),
                    ],

                    const Divider(color: Colors.white10, height: 32),
                    _buildActionItem(context, "إلغاء", Colors.white54, () => Navigator.pop(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String title, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (title != "إلغاء") Navigator.pop(context);
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
