import 'package:flutter/material.dart';
import '../controllers/rewards_controller.dart';
import '../theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

class DailyRewardPopup extends StatelessWidget {
  final RewardsController rewards;
  const DailyRewardPopup({super.key, required this.rewards});

  @override
  Widget build(BuildContext context) {
    final rewardsController = rewards;
    final streak = rewardsController.streakCount;
    final size = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: size.height * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: AppTheme.royalGold, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        'daily_rewards_title'.tr(),
                        style: TextStyle(
                          color: AppTheme.darkBrown,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'streak_info'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.darkBrown.withValues(alpha: 0.6), fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: List.generate(7, (index) {
                          final day = index + 1;
                          final isToday = day == streak;
                          final isPast = day < streak;
                          
                          return Container(
                            width: 65,
                            height: 85,
                            decoration: BoxDecoration(
                              color: isToday 
                                  ? AppTheme.royalGold 
                                  : (isPast ? AppTheme.royalGold.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isToday ? AppTheme.royalGold : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Day $day',
                                  style: TextStyle(
                                    color: isToday ? Colors.white : AppTheme.darkBrown,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (day == 3 || day == 6 || day == 7)
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Placeholder(
                                      strokeWidth: 1,
                                      color: AppTheme.royalGold,
                                    ),
                                  )
                                else
                                  Icon(
                                    day == 7 ? Icons.card_giftcard_rounded : Icons.diamond_rounded,
                                    color: isToday ? Colors.white : (isPast ? AppTheme.royalGold.withValues(alpha: 0.5) : Colors.grey),
                                    size: 24,
                                  ),
                                if (isPast)
                                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: rewardsController.hasClaimedToday
                    ? null
                    : () async {
                        await rewardsController.claimReward();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('reward_claimed_success'.tr()),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.royalGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 0,
                ),
                child: Text(
                  rewardsController.hasClaimedToday 
                    ? 'claimed_label'.tr() 
                    : 'claim_now_label'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}