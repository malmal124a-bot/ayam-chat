import 'package:flutter/material.dart';

class ProfileItem {
  final String titleKey;
  final IconData icon;
  final String? assetPath;

  ProfileItem({
    required this.titleKey,
    required this.icon,
    this.assetPath,
  });

  static List<ProfileItem> get items => [
    ProfileItem(titleKey: 'family', icon: Icons.group_outlined, assetPath: 'assets/images/ic_family_entrance.png'),
    ProfileItem(titleKey: 'cp', icon: Icons.favorite_outlined, assetPath: 'assets/images/Untitled-1_0005_icon_cp.png'),
    ProfileItem(titleKey: 'medals', icon: Icons.military_tech_outlined, assetPath: 'assets/images/icon_medal.png'),
    ProfileItem(titleKey: 'level', icon: Icons.trending_up_rounded, assetPath: 'assets/images/icon_level.png'),
    ProfileItem(titleKey: 'leaderboard', icon: Icons.emoji_events_outlined, assetPath: 'assets/images/ranking_entry.png'),
    ProfileItem(titleKey: 'host_agency', icon: Icons.supervisor_account_rounded, assetPath: 'assets/images/icon_host.png'),
    ProfileItem(titleKey: 'invitation_code', icon: Icons.qr_code_2_rounded, assetPath: 'assets/images/icon_recharge.png'),
    ProfileItem(titleKey: 'tasks', icon: Icons.task_alt_rounded, assetPath: 'assets/images/icon_bro.png'),
    ProfileItem(titleKey: 'help_center', icon: Icons.smart_toy_outlined, assetPath: 'assets/images/icon_contact_us.png'),
    ProfileItem(titleKey: 'settings', icon: Icons.settings_outlined, assetPath: 'assets/images/icon_setting.png'),
    ProfileItem(titleKey: 'policy', icon: Icons.privacy_tip_outlined, assetPath: 'assets/images/icon_bd_center.png'),
  ];
}
