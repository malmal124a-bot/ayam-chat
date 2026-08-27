import 'package:flutter/material.dart';
import '../controllers/room_ui_controller.dart';

Future<void> showAdminPanel(BuildContext context, RoomUiController controller) {
  final theme = Theme.of(context);
  final passwordController = TextEditingController(text: controller.roomPassword);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.18)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('لوحة تحكم الأدمن', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('عدد المايكات النشطة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    Text('${controller.activeMicCount}', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: controller.activeMicCount.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  activeColor: theme.colorScheme.secondary,
                  inactiveColor: Colors.white10,
                  onChanged: (value) {
                    controller.setActiveMicCount(value.toInt());
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('قفل الغرفة برقم سري', theme),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      controller.lockRoomWithPassword(passwordController.text);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, foregroundColor: Colors.black),
                    child: const Text('تأكيد القفل'),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('إدارة المايكات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...controller.visibleSeats.map((seat) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text('مايك ${seat.index} • ${seat.userName ?? 'فارغ'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(
                      seat.isLocked ? 'مقفول' : (seat.isMuted ? 'مكتوم' : 'مفتوح'),
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        _smallAction('قفل', () => controller.toggleSeatLock(seat.index), theme),
                        _smallAction('كتم', () => controller.toggleSeatMute(seat.index), theme),
                        _smallAction('طرد', () => controller.kickUserFromSeat(seat.index), theme),
                        _smallAction('حظر', () => controller.banUserFromSeat(seat.index), theme),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

InputDecoration _inputDecoration(String hint, ThemeData theme) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: theme.colorScheme.background.withValues(alpha: 0.7),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.18))),
      focusedBorder: BorderSide(color: theme.colorScheme.secondary) == const BorderSide() ? null : OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: theme.colorScheme.secondary)),
    );

Widget _smallAction(String label, VoidCallback onTap, ThemeData theme) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.16)),
        ),
        child: Text(label, style: TextStyle(color: theme.colorScheme.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
