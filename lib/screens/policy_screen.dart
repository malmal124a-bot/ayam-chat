import 'package:flutter/material.dart';
import '../controllers/policy_controller.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final policyController = PolicyController();

    return Scaffold(
      backgroundColor: AppTheme.royalPurpleDark,
      appBar: AppBar(
        title: Text(
          'الخصوصية والسياسة',
          style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionTitle('سياسة الخصوصية'),
            const SizedBox(height: 12),
            _buildContentText(policyController.privacyPolicy),
            const Divider(height: 40, color: Colors.white10),
            _buildSectionTitle('شروط الاستخدام'),
            const SizedBox(height: 12),
            _buildContentText(policyController.termsOfService),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.royalGold,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildContentText(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 15,
        height: 1.6,
      ),
    );
  }
}