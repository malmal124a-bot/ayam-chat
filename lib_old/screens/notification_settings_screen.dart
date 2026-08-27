import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/notification_controller.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // تم التغيير للأبيض لضمان الرؤية
      appBar: AppBar(
        title: Text('notifications'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<NotificationController>(
        builder: (context, notification, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildNotificationSection(
                  context,
                  'push_notifications'.tr(),
                  'push_desc'.tr(),
                  notification.pushNotifications,
                  (value) => notification.setPushNotifications(value),
                ),
                const SizedBox(height: 16),
                _buildNotificationSection(
                  context,
                  'message_notifications'.tr(),
                  'message_desc'.tr(),
                  notification.messageNotifications,
                  (value) => notification.setMessageNotifications(value),
                ),
                const SizedBox(height: 16),
                _buildNotificationSection(
                  context,
                  'room_notifications'.tr(),
                  'room_desc'.tr(),
                  notification.roomNotifications,
                  (value) => notification.setRoomNotifications(value),
                ),
                const SizedBox(height: 16),
                _buildNotificationSection(
                  context,
                  'gift_notifications'.tr(),
                  'gift_desc'.tr(),
                  notification.giftNotifications,
                  (value) => notification.setGiftNotifications(value),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.black12),
                const SizedBox(height: 16),
                _buildNotificationSection(
                  context,
                  'sound_enabled'.tr(),
                  'sound_desc'.tr(),
                  notification.soundEnabled,
                  (value) => notification.setSoundEnabled(value),
                ),
                const SizedBox(height: 16),
                _buildNotificationSection(
                  context,
                  'vibration_enabled'.tr(),
                  'vibration_desc'.tr(),
                  notification.vibrationEnabled,
                  (value) => notification.setVibrationEnabled(value),
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationSection(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.darkBrown.withValues(alpha: 0.1)),
        ),
        child: SwitchListTile(
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.royalGold,
        ),
      ),
    );
  }
}
