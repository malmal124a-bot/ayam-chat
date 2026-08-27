import 'package:flutter/material.dart';
import '../../controllers/room_ui_controller.dart';

class RoomTabWidget extends StatelessWidget {
  final RoomUiController controller;
  final VoidCallback onShowTimer;
  final VoidCallback onEditRoom;
  final VoidCallback onShowBgPicker;
  final VoidCallback onShowMicsPicker;
  final VoidCallback onShowPkBattle;

  const RoomTabWidget({
    super.key,
    required this.controller,
    required this.onShowTimer,
    required this.onEditRoom,
    required this.onShowBgPicker,
    required this.onShowMicsPicker,
    required this.onShowPkBattle,
  });

  void _snack(BuildContext context, String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return GridView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          children: [
            _gridItem(
              context,
              Icons.delete_sweep,
              'مسح التكست',
              () {
                controller.clearMessages();
                _snack(context, 'تم مسح الدردشة');
              },
            ),
            _gridItem(
              context,
              Icons.chat,
              'الدردشة',
              () {
                controller.toggleChat();
                _snack(context, controller.isChatEnabled ? 'الدردشة مفعلة' : 'الدردشة معطلة');
              },
            ),
            _gridItem(
              context,
              controller.allMicsMuted ? Icons.mic_off : Icons.mic,
              controller.allMicsMuted ? 'مايك مغلق' : 'مايك مفتوح',
              () => controller.toggleAllMicsMute(),
              isActive: !controller.allMicsMuted,
            ),
            _gridItem(
              context,
              Icons.access_time,
              'سجل الغرفة',
              onShowTimer,
            ),
            _gridItem(
              context,
              Icons.image,
              'خلفية الغرفة',
              onShowBgPicker,
            ),
            _gridItem(
              context,
              Icons.mic_external_on,
              'مايكات',
              onShowMicsPicker,
            ),
            _gridItem(
              context,
              Icons.auto_awesome,
              'تزيين الغرفة',
              () => _snack(context, 'تزيين الغرفة'),
            ),
            _gridItem(
              context,
              Icons.block,
              'سوداء',
              () => _snack(context, 'القائمة السوداء'),
            ),
            _gridItem(
              context,
              Icons.gpp_bad,
              'قائمة الطرد',
              () => _snack(context, 'قائمة الطرد'),
            ),
            _gridItem(
              context,
              Icons.volume_off,
              'قائمة الكتم',
              () => _snack(context, 'قائمة الكتم'),
            ),
            _gridItem(
              context,
              Icons.edit,
              'تعديل',
              onEditRoom,
            ),
            _gridItem(
              context,
              Icons.sports_martial_arts,
              'تحدي PK',
              onShowPkBattle,
            ),
          ],
        );
      },
    );
  }

  Widget _gridItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? Colors.amber : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? Colors.amber : Colors.white10, width: 1),
            ),
            child: Icon(icon, color: isActive ? Colors.black : Colors.amber, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
