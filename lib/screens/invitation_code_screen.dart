import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/invite_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class InvitationCodeScreen extends StatefulWidget {
  const InvitationCodeScreen({super.key});

  @override
  State<InvitationCodeScreen> createState() => _InvitationCodeScreenState();
}

class _InvitationCodeScreenState extends State<InvitationCodeScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleSubmit(InviteController controller) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final success = await controller.submitCode(code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'code_submitted_success'.tr() : 'code_invalid'.tr()),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) _codeController.clear();
    }
  }

  void _handleShare(BuildContext context, String code) async {
    final message = "join_me_on_ayam".tr(args: [code]);
    final whatsappUrl = Uri.parse("whatsapp://send?text=$message");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      Clipboard.setData(ClipboardData(text: message));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('copy_success'.tr() + ": " + 'share_msg_copied'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearBlackPurple,
      appBar: AppBar(
        title: Text('invitation_code'.tr(), style: TextStyle(color: AppTheme.royalGold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AppIcon('Icons.arrow_back_ios', icon: Icons.arrow_back_ios, color: AppTheme.royalGold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<InviteController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promotional Motivational Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.royalGold.withValues(alpha: 0.2), Colors.transparent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppIcon('Icons.stars_rounded', icon: Icons.stars_rounded, color: AppTheme.royalGold, size: 28),
                          Expanded(
                            child: Text(
                              'invite_friends_title'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'what_do_you_get'.tr(),
                        style: TextStyle(
                          color: AppTheme.royalGold,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRewardItem('reward_point_1'.tr()),
                      _buildRewardItem('reward_point_2'.tr()),
                      _buildRewardItem('reward_point_3'.tr()),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // My Code Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.nearBlackPurple.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'my_invite_code'.tr(),
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.myInviteCode,
                            style: TextStyle(
                              color: AppTheme.royalGold,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          IconButton(
                            icon: AppIcon('Icons.copy', icon: Icons.copy, color: AppTheme.royalGold, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: controller.myInviteCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('copy_success'.tr())),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 160,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleShare(context, controller.myInviteCode),
                          icon: const AppIcon('Icons.share_rounded', icon: Icons.share_rounded, size: 18),
                          label: Text('share'.tr()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Enter Friend's Code Section
                Text(
                  'enter_invite_code'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'invite_reward_msg'.tr(),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  enabled: !controller.isCodeSubmitted,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ABCD123',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: AppTheme.royalGold, width: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: controller.isCodeSubmitted ? null : () => _handleSubmit(controller),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.royalGold,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      controller.isCodeSubmitted ? 'claimed'.tr() : 'submit_code'.tr(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon('Icons.check_circle_outline', icon: Icons.check_circle_outline, color: AppTheme.royalGold, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}