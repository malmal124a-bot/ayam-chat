import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rewards_controller.dart';
import '../theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

class DailyRewardPopup extends StatefulWidget {
  const DailyRewardPopup({super.key});

  @override
  State<DailyRewardPopup> createState() => _DailyRewardPopupState();
}

class _DailyRewardPopupState extends State<DailyRewardPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rewardsController = context.watch<RewardsController>();
    final streak = rewardsController.streakCount;
    final size = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 360,
              maxHeight: size.height * 0.75,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f0f23),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.royalGold.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.royalGold.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with icon and title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.royalGold,
                                AppTheme.royalGold.withValues(alpha: 0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Check-in',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Streak: $streak days',
                              style: TextStyle(
                                color: AppTheme.royalGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 7-day reward grid - compact 4-card layout
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final isToday = day == streak;
                        final isPast = day < streak;
                        final isClaimed = isPast || (isToday && rewardsController.hasClaimedToday);

                        return _buildDayCard(
                          day: day,
                          isToday: isToday,
                          isPast: isPast,
                          isClaimed: isClaimed,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Claim button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: rewardsController.hasClaimedToday
                            ? null
                            : () async {
                                await rewardsController.claimReward();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text('reward_claimed_success'.tr()),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rewardsController.hasClaimedToday
                              ? Colors.grey.withValues(alpha: 0.3)
                              : AppTheme.royalGold,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: rewardsController.hasClaimedToday ? 0 : 6,
                          shadowColor: AppTheme.royalGold.withValues(alpha: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!rewardsController.hasClaimedToday)
                              const Icon(Icons.card_giftcard_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              rewardsController.hasClaimedToday
                                  ? 'claimed_label'.tr()
                                  : 'claim_now_label'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard({
    required int day,
    required bool isToday,
    required bool isPast,
    required bool isClaimed,
  }) {
    final isSpecialDay = day == 3 || day == 6 || day == 7;
    final rewardIcon = isSpecialDay
        ? Icons.card_giftcard_rounded
        : Icons.diamond_rounded;
    final rewardAmount = isSpecialDay ? '${day * 10}' : '${day * 5}';

    return Container(
      decoration: BoxDecoration(
        gradient: isToday
            ? LinearGradient(
                colors: [
                  AppTheme.royalGold,
                  const Color(0xFFffb700),
                ],
              )
            : isClaimed
                ? LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.3),
                      Colors.green.withValues(alpha: 0.1),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? AppTheme.royalGold
              : isClaimed
                  ? Colors.green.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
          width: isToday ? 2 : 1,
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppTheme.royalGold.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Day number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isToday
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Day $day',
              style: TextStyle(
                color: isToday ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Reward icon
          Icon(
            isClaimed ? Icons.check_circle : rewardIcon,
            color: isToday
                ? Colors.white
                : isClaimed
                    ? Colors.green
                    : Colors.white54,
            size: 24,
          ),
          const SizedBox(height: 4),

          // Reward amount
          Text(
            isClaimed ? '✓' : '+$rewardAmount',
            style: TextStyle(
              color: isToday
                  ? Colors.white
                  : isClaimed
                      ? Colors.green
                      : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
