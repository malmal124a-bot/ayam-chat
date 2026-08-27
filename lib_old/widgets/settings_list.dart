import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import '../screens/account_security_screen.dart';
import '../screens/notification_settings_screen.dart';
import '../screens/privacy_settings_screen.dart';
import '../screens/about_screen.dart';

class SettingsList extends StatelessWidget {
  const SettingsList({super.key});

  void _handleLogout(BuildContext context) async {
    final authController = context.read<AuthController>();
    final userController = context.read<UserController>();
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('logout'.tr(), style: const TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr(), style: const TextStyle(color: Colors.white))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('logout'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authController.logout();
      userController.logout();
      if (context.mounted) {
        navigator.pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SettingsTile(
            title: 'account_security'.tr(), 
            subtitle: 'إدارة الحساب وطرق الأمان',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountSecurityScreen()),
            ),
          ),
          _SettingsTile(
            title: 'notifications'.tr(), 
            subtitle: 'التحكم في التنبيهات والرسائل',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
            ),
          ),
          _SettingsTile(
            title: 'privacy'.tr(), 
            subtitle: 'إعدادات الظهور والحظر',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacySettingsScreen()),
            ),
          ),
          const _LanguageSelectorTile(),
          _SettingsTile(
            title: 'about'.tr(), 
            subtitle: 'الإصدار والمعلومات',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            ),
          ),
          const SizedBox(height: 30),
          _SettingsTile(
            title: 'logout'.tr(),
            subtitle: 'تسجيل الخروج من الحساب',
            icon: Icons.logout_rounded,
            onTap: () => _handleLogout(context),
            isDestructive: true,
          ),
          const SizedBox(height: 50), // Extra space for scrolling visibility
        ],
      ),
    );
  }
}

class _LanguageSelectorTile extends StatefulWidget {
  const _LanguageSelectorTile();
  @override
  State<_LanguageSelectorTile> createState() => _LanguageSelectorTileState();
}

class _LanguageSelectorTileState extends State<_LanguageSelectorTile> {
  final Map<String, String> _languages = {
    'ar': 'العربية',
    'en': 'English',
    'zh': '中文',
    'tr': 'Türkçe',
    'hi': 'हिन्दी',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'ru': 'Русский',
    'pt': 'Português',
  };

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.darkBrown.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('language'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(_languages[currentLocale] ?? 'English', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          trailing: DropdownButton<String>(
            value: currentLocale,
            dropdownColor: AppTheme.card,
            iconEnabledColor: AppTheme.royalGold,
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox.shrink(),
            items: _languages.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                context.setLocale(Locale(value));
                setState(() {});
              }
            },
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.title, 
    required this.subtitle, 
    this.icon = Icons.arrow_forward_ios,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.darkBrown.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            title, 
            style: TextStyle(
              color: isDestructive ? Colors.red : Colors.white, 
              fontWeight: FontWeight.bold
            )
          ),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          trailing: Icon(
            icon, 
            color: isDestructive 
              ? Colors.red.withValues(alpha: 0.5) 
              : (icon == Icons.arrow_forward_ios ? AppTheme.darkBrown.withValues(alpha: 0.3) : AppTheme.royalGold),
            size: icon == Icons.arrow_forward_ios ? 14 : 22
          ),
        ),
      ),
    );
  }
}
