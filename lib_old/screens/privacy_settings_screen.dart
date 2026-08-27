import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/privacy_controller.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // تغيير للخلفية البيضاء لضمان الوضوح
      appBar: AppBar(
        title: Text('privacy'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<PrivacyController>(
        builder: (context, privacy, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPrivacySection(
                  context,
                  'profile_visible'.tr(),
                  'profile_visible_desc'.tr(),
                  privacy.profileVisible,
                  (value) => privacy.setProfileVisible(value),
                ),
                const SizedBox(height: 16),
                _buildPrivacySection(
                  context,
                  'show_online_status'.tr(),
                  'online_status_desc'.tr(),
                  privacy.showOnlineStatus,
                  (value) => privacy.setShowOnlineStatus(value),
                ),
                const SizedBox(height: 16),
                _buildPrivacySection(
                  context,
                  'allow_direct_messages'.tr(),
                  'direct_messages_desc'.tr(),
                  privacy.allowDirectMessages,
                  (value) => privacy.setAllowDirectMessages(value),
                ),
                const SizedBox(height: 16),
                _buildPrivacySection(
                  context,
                  'show_last_seen'.tr(),
                  'last_seen_desc'.tr(),
                  privacy.showLastSeen,
                  (value) => privacy.setShowLastSeen(value),
                ),
                const SizedBox(height: 16),
                _buildPrivacySection(
                  context,
                  'allow_friend_requests'.tr(),
                  'friend_requests_desc'.tr(),
                  privacy.allowFriendRequests,
                  (value) => privacy.setAllowFriendRequests(value),
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrivacySection(
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
