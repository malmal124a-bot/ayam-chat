import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/security_controller.dart';

class AccountSecurityScreen extends StatelessWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // تم التغيير للأبيض لضمان الرؤية والوضوح
      appBar: AppBar(
        title: Text('account_security'.tr(), style: const TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkBrown),
      ),
      body: Consumer<SecurityController>(
        builder: (context, security, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSecuritySection(
                  context,
                  'two_factor_auth'.tr(),
                  'two_factor_desc'.tr(),
                  security.twoFactorEnabled,
                  (value) => security.setTwoFactorEnabled(value),
                ),
                const SizedBox(height: 16),
                _buildSecuritySection(
                  context,
                  'biometric_login'.tr(),
                  'biometric_desc'.tr(),
                  security.biometricEnabled,
                  (value) => security.setBiometricEnabled(value),
                ),
                const SizedBox(height: 16),
                _buildSecuritySection(
                  context,
                  'login_alerts'.tr(),
                  'login_alerts_desc'.tr(),
                  security.loginAlerts,
                  (value) => security.setLoginAlerts(value),
                ),
                const SizedBox(height: 16),
                _buildSecuritySection(
                  context,
                  'password_change_alerts'.tr(),
                  'password_change_desc'.tr(),
                  security.passwordChangeAlert,
                  (value) => security.setPasswordChangeAlert(value),
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecuritySection(
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(title, style: const TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: TextStyle(color: AppTheme.darkBrown.withValues(alpha: 0.5), fontSize: 12)),
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.royalGold,
        ),
      ),
    );
  }
}
