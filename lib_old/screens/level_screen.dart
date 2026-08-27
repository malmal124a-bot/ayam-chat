import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/user_controller.dart';
import '../theme/app_theme.dart';

class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserController>();

    return Scaffold(
      backgroundColor: AppTheme.nearBlackPurple,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'نظام المستويات'.tr(),
          style: const TextStyle(
            color: AppTheme.royalGold,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.royalGold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.nearBlackPurple,
              AppTheme.darkPurple.withValues(alpha: 0.8),
              AppTheme.nearBlackPurple,
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: kToolbarHeight + 40, left: 20, right: 20, bottom: 40),
          child: Column(
            children: [
              _buildTierCard(
                context,
                title: 'مستوى الثروة'.tr(),
                subtitle: 'شحن أساسي'.tr(),
                level: user.wealthLevel,
                xp: user.wealthXP,
                progress: user.wealthProgress,
                maxLevel: 100,
                iconPath: 'assets/images/icon_recharge.png',
                baseColor: Colors.orangeAccent,
                accentColor: Colors.amber,
                description: 'يزداد هذا المستوى بناءً على إجمالي عمليات الشحن الأساسية الخاصة بك.',
              ),
              const SizedBox(height: 25),
              _buildTierCard(
                context,
                title: 'مستوى السحر'.tr(),
                subtitle: 'استقبال دعم'.tr(),
                level: user.magicLevel,
                xp: user.magicXP,
                progress: user.magicProgress,
                maxLevel: 150,
                iconPath: 'assets/images/icon_received.png',
                baseColor: Colors.purpleAccent,
                accentColor: Colors.deepPurpleAccent,
                description: 'يعبر هذا المستوى عن مدى شعبيتك والدعم الذي تتلقاه من الأصدقاء.',
              ),
              const SizedBox(height: 25),
              _buildTierCard(
                context,
                title: 'المستوى الذهبي'.tr(),
                subtitle: 'شحن فئات عالية'.tr(),
                level: user.nobleLevel,
                xp: user.nobleXP,
                progress: user.nobleProgress,
                maxLevel: 200,
                iconPath: 'assets/images/icon_level.png',
                baseColor: AppTheme.royalGold,
                accentColor: const Color(0xFFFFF8E1),
                isPremium: true,
                description: 'المستوى الفاخر المخصص لكبار الشخصيات، يزداد بشحن الفئات المرتفعة.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int level,
    required int xp,
    required double progress,
    required int maxLevel,
    required String iconPath,
    required Color baseColor,
    required Color accentColor,
    required String description,
    bool isPremium = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium 
            ? [const Color(0xFF3E2723), const Color(0xFF1A1A2E)]
            : [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isPremium ? AppTheme.royalGold.withValues(alpha: 0.8) : baseColor.withValues(alpha: 0.3),
          width: isPremium ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? AppTheme.royalGold : baseColor).withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isPremium)
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.workspace_premium, size: 120, color: AppTheme.royalGold.withValues(alpha: 0.05)),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: baseColor.withValues(alpha: 0.2)),
                      ),
                      child: Image.asset(
                        iconPath,
                        width: 45,
                        height: 45,
                        errorBuilder: (c, e, s) => Icon(Icons.stars, color: baseColor, size: 45),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isPremium ? AppTheme.royalGold : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(color: baseColor.withValues(alpha: 0.7), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'Lv.$level',
                          style: TextStyle(
                            color: isPremium ? AppTheme.royalGold : baseColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'MAX $maxLevel',
                          style: const TextStyle(color: Colors.white24, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تقدم المستوى',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(color: baseColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(baseColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'XP: $xp',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withValues(alpha: 0.05)),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                ),
                if (isPremium) ...[
                   const SizedBox(height: 15),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       color: AppTheme.royalGold.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.2)),
                     ),
                     child: const Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(Icons.auto_awesome, color: AppTheme.royalGold, size: 14),
                         SizedBox(width: 6),
                         Text(
                           'مميزات النخبة مفعلة',
                           style: TextStyle(color: AppTheme.royalGold, fontSize: 11, fontWeight: FontWeight.bold),
                         ),
                       ],
                     ),
                   ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
