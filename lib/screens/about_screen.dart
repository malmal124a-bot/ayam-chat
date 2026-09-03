import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.royalPurpleDark,
      appBar: AppBar(
        title: Text('about'.tr(), style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.royalGold, width: 2),
              ),
              child: AppIcon('Icons.chat_bubble_rounded', icon: Icons.chat_bubble_rounded, size: 60, color: AppTheme.royalGold),
            ),
            const SizedBox(height: 24),
            Text('app_name'.tr(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('version'.tr(), style: const TextStyle(color: Colors.white60, fontSize: 16)),
            const SizedBox(height: 32),
            _buildInfoCard(
              'description'.tr(),
              'description_text'.tr(),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'features'.tr(),
              'features_text'.tr(),
            ),
            const SizedBox(height: 32),
            _buildLinkTile(
              context,
              'terms'.tr(),
              'terms_desc'.tr(),
              () => _launchUrl('https://example.com/terms'),
            ),
            const SizedBox(height: 12),
            _buildLinkTile(
              context,
              'privacy_policy'.tr(),
              'privacy_desc'.tr(),
              () => _launchUrl('https://example.com/privacy'),
            ),
            const SizedBox(height: 12),
            _buildLinkTile(
              context,
              'support'.tr(),
              'support_desc'.tr(),
              () => _launchUrl('https://example.com/support'),
            ),
            const SizedBox(height: 32),
            Text('© 2024 Ayam Chat. All rights reserved.', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildLinkTile(BuildContext context, String title, String subtitle, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.14)),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        trailing: AppIcon('Icons.arrow_forward_ios', icon: Icons.arrow_forward_ios, color: AppTheme.royalGold, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
