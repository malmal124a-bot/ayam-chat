import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mic_seat.dart';
import '../../controllers/room_ui_controller.dart';
import '../../controllers/gift_controller.dart';
import '../../controllers/user_controller.dart';
import '../gift_sheet_widget.dart';
import '../../screens/messages_screen.dart';

/// Role-Based User Profile Bottom Sheet
void showRoomUserProfileSheet(BuildContext context, {
  required MicSeat seat,
  required bool isCurrentUserOwner,
  required bool isCurrentUserAdmin,
  required RoomUiController controller,
  required TextEditingController? chatInputController,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: controller),
        ChangeNotifierProvider.value(value: GiftController()),
        ChangeNotifierProvider.value(value: UserController()),
      ],
      child: RoomUserProfileSheet(
        seat: seat,
        isCurrentUserOwner: isCurrentUserOwner,
        isCurrentUserAdmin: isCurrentUserAdmin,
        chatInputController: chatInputController,
      ),
    ),
  );
}

class RoomUserProfileSheet extends StatelessWidget {
  final MicSeat seat;
  final bool isCurrentUserOwner;
  final bool isCurrentUserAdmin;
  final TextEditingController? chatInputController;

  const RoomUserProfileSheet({
    super.key,
    required this.seat,
    required this.isCurrentUserOwner,
    required this.isCurrentUserAdmin,
    this.chatInputController,
  });

  void _snack(BuildContext context, String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openGiftSheet(BuildContext context, RoomUiController roomController) {
    final giftController = Provider.of<GiftController>(context, listen: false);
    final userController = Provider.of<UserController>(context, listen: false);
    
    giftController.setTargetSeat(seat.index);
    
    showComprehensiveGiftSheet(
      context, 
      giftController, 
      (msg, target, combo) {
        roomController.addMessage("أرسل $msg x$combo", giftName: msg, giftCount: combo);
      }, 
      roomId: roomController.roomId,
      roomController: roomController,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RoomUiController>();
    final userController = context.watch<UserController>();
    final bool canManage = controller.canManageRoom;
    final bool isMe = seat.userId == userController.numericId;
    final bool isTargetMod = controller.isModerator(seat.userId ?? '');
    final bool isTargetOwner = seat.userId == controller.roomId;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          CircleAvatar(
            radius: 46,
            backgroundColor: Colors.amber.withValues(alpha: 0.15),
            child: CircleAvatar(
              radius: 40,
              backgroundImage: RoomUiController.getSafeImageProvider(seat.userProfilePic),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            seat.userName ?? 'مستخدم',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            'ID: ${seat.userId ?? '---'}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoStat('المستوى', '${seat.userLevel}'),
              _infoStat('المساهمات', '${seat.contributionScore}'),
              _infoStat('الأوسمة', '3'),
            ],
          ),
          const SizedBox(height: 20),
          
          // User Badges Display
          _buildBadgesSection(seat.badges ?? []),
          const SizedBox(height: 30),
          
          if (isMe)
            _buildMyActions(context, controller)
          else if (canManage)
            _buildOwnerAdminActions(context, controller)
          else
            _buildMemberActions(context, controller),
        ],
      ),
    );
  }

  Widget _infoStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Cairo'),
        ),
      ],
    );
  }

  Widget _buildBadgesSection(List<String> userBadges) {
    // Display badges based on user level, contributions, and provided badges
    final List<Map<String, dynamic>> badges = [];
    
    // Add badges from user profile if available
    for (final badge in userBadges) {
      IconData icon;
      Color color;
      String name;
      
      switch (badge.toLowerCase()) {
        case 'vip':
          icon = Icons.workspace_premium;
          color = Colors.amber;
          name = 'VIP';
          break;
        case 'admin':
          icon = Icons.admin_panel_settings;
          color = Colors.red;
          name = 'Admin';
          break;
        case 'moderator':
          icon = Icons.shield;
          color = Colors.blue;
          name = 'Moderator';
          break;
        case 'legend':
          icon = Icons.emoji_events;
          color = Colors.yellow;
          name = 'Legend';
          break;
        case 'elite':
          icon = Icons.military_tech;
          color = Colors.orange;
          name = 'Elite';
          break;
        default:
          icon = Icons.star;
          color = Colors.purple;
          name = badge;
      }
      
      badges.add({'icon': icon, 'color': color, 'name': name});
    }
    
    // Add automatic badges based on level and contributions
    if (seat.userLevel >= 50 && !badges.any((b) => b['name'] == 'Elite')) {
      badges.add({'icon': Icons.military_tech, 'color': Colors.amber, 'name': 'Elite'});
    }
    if (seat.contributionScore >= 1000 && !badges.any((b) => b['name'] == 'Star')) {
      badges.add({'icon': Icons.star, 'color': Colors.orange, 'name': 'Star'});
    }
    if (seat.userLevel >= 100 && !badges.any((b) => b['name'] == 'Legend')) {
      badges.add({'icon': Icons.emoji_events, 'color': Colors.yellow, 'name': 'Legend'});
    }
    
    if (badges.isEmpty) {
      badges.add({'icon': Icons.workspace_premium, 'color': Colors.grey, 'name': 'Member'});
    }
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: badges.map((badge) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (badge['color'] as Color).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (badge['color'] as Color).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badge['icon'] as IconData, color: badge['color'] as Color, size: 16),
            const SizedBox(width: 6),
            Text(
              badge['name'] as String,
              style: TextStyle(
                color: badge['color'] as Color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildMyActions(BuildContext context, RoomUiController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionItem(
          Icons.exit_to_app_rounded, 
          'مغادرة المايك', 
          Colors.redAccent, 
          () {
            controller.kickUserFromSeat(seat.index);
            Navigator.pop(context);
            _snack(context, 'تمت مغادرة المايك');
          }
        ),
        _actionItem(Icons.person_rounded, 'الملف الشخصي', Colors.blue, () {
          Navigator.pop(context);
          _snack(context, 'فتح الملف الشخصي الكامل');
        }),
      ],
    );
  }

  Widget _buildOwnerAdminActions(BuildContext context, RoomUiController controller) {
    final bool isTargetOwner = seat.userId == controller.roomId;
    final bool isTargetMod = controller.isModerator(seat.userId ?? '');
    final bool canManageThisTarget = !isTargetOwner && !isTargetMod;

    return Column(
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            if (canManageThisTarget) ...[
              _actionItem(
                Icons.mic_external_on_rounded,
                'قفل المقعد',
                Colors.blue,
                () {
                  controller.toggleSeatLock(seat.index);
                  _snack(context, seat.isLocked ? 'تم فتح المقعد' : 'تم قفل المقعد');
                }
              ),
              _actionItem(
                Icons.mic_off_rounded,
                seat.isMuted ? 'فك الكتم' : 'كتم الصوت',
                seat.isMuted ? Colors.green : Colors.orange,
                () {
                  controller.toggleSeatMute(seat.index, forceMute: !seat.isMuted);
                  _snack(context, seat.isMuted ? 'تم إلغاء كتم المستخدم' : 'تم كتم المستخدم');
                }
              ),
              _actionItem(
                Icons.exit_to_app_rounded,
                'طرد من المقعد',
                Colors.deepOrange,
                () {
                  controller.kickUserToAudience(seat.index);
                  Navigator.pop(context);
                  _snack(context, 'تم إنزال المستخدم للجمهور');
                }
              ),
            ],
            if (controller.isRoomOwner && !isTargetOwner) ...[
              _actionItem(
                isTargetMod ? Icons.remove_moderator : Icons.admin_panel_settings,
                isTargetMod ? 'إلغاء المشرفية' : 'تعيين مشرف',
                isTargetMod ? Colors.orange : Colors.purple,
                () {
                  if (isTargetMod) {
                    controller.removeModerator(seat.userId ?? '');
                    _snack(context, 'تم إلغاء المشرفية');
                  } else {
                    controller.assignModerator(seat.userId ?? '');
                    _snack(context, 'تم تعيين المستخدم كمشرف');
                  }
                }
              ),
              _actionItem(
                Icons.block,
                'حظر نهائي',
                Colors.red,
                () {
                  controller.banUser(seat.userId ?? '', seat.userName ?? 'مستخدم');
                  controller.kickUserToAudience(seat.index);
                  Navigator.pop(context);
                  _snack(context, 'تم حظر المستخدم من الغرفة');
                }
              ),
            ],
            _actionItem(Icons.card_giftcard, 'إرسال هدية', Colors.pink, () {
              Navigator.pop(context);
              _openGiftSheet(context, controller);
            }),
            _actionItem(Icons.message_rounded, 'رسالة', Colors.teal, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildMemberActions(BuildContext context, RoomUiController controller) {
    final bool following = controller.isFollowing(seat.userId ?? '');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionItem(
          following ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
          'متابعة', 
          following ? Colors.red : Colors.blue, 
          () {
            controller.toggleFollow(seat.userId ?? '');
            _snack(context, following ? 'تم إلغاء المتابعة' : 'تمت المتابعة');
          }
        ),
        _actionItem(Icons.alternate_email_rounded, '@ذكر', Colors.green, () {
          Navigator.pop(context);
          if (chatInputController != null && seat.userName != null) {
            final currentText = chatInputController!.text;
            final mention = '@${seat.userName}';
            chatInputController!.text = currentText.isEmpty ? mention : '$currentText $mention';
            chatInputController!.selection = TextSelection.fromPosition(
              TextPosition(offset: chatInputController!.text.length),
            );
            _snack(context, 'تم إضافة @${seat.userName} إلى الدردشة');
          } else {
            _snack(context, 'تعذر إضافة الذكر');
          }
        }),
        _actionItem(Icons.message_rounded, 'الرسائل', Colors.teal, () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
        }),
        _actionItem(Icons.card_giftcard, 'إرسال هدية', Colors.pink, () {
          Navigator.pop(context);
          _openGiftSheet(context, controller);
        }),
        _actionItem(Icons.report_gmailerrorred_rounded, 'الإبلاغ', Colors.red, () {
          Navigator.pop(context);
          _snack(context, 'تم إرسال البلاغ');
        }),
      ],
    );
  }

  Widget _actionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Cairo'),
          ),
        ],
      ),
    );
  }
}
