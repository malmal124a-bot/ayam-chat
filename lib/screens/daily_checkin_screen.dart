import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/daily_checkin_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class DailyCheckinScreen extends StatelessWidget {
  const DailyCheckinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DailyCheckinController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B08),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Daily Check-in', style: TextStyle(color: AppTheme.royalGold)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildStreakHeader(controller.streak.value),
                const SizedBox(height: 30),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final isClaimed = controller.claims[index];
                    final isCurrentDay = (controller.streak.value % 7) == index && controller.canClaimToday.value;
                    
                    return _buildDayCard(index + 1, isClaimed, isCurrentDay);
                  },
                ),
                const SizedBox(height: 30),
                _buildClaimButton(controller),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStreakHeader(int streak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F180B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.royalGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const AppIcon('Icons.local_fire_department', icon: Icons.local_fire_department, color: Colors.orange, size: 40),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Check-in Streak', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              Text('$streak days', style: TextStyle(color: AppTheme.royalGold, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(int day, bool isClaimed, bool isCurrentDay) {
    return Container(
      decoration: BoxDecoration(
        color: isClaimed ? AppTheme.royalGold.withOpacity(0.1) : Color(0xFF1F180B),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isCurrentDay ? AppTheme.royalGold : (isClaimed ? AppTheme.royalGold.withOpacity(0.5) : Colors.white10),
          width: isCurrentDay ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Day $day', style: TextStyle(color: isClaimed ? AppTheme.royalGold : Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Icon(
            isClaimed ? Icons.check_circle : Icons.card_giftcard,
            color: isClaimed ? Colors.green : (isCurrentDay ? AppTheme.royalGold : Colors.white24),
            size: 30,
          ),
          const SizedBox(height: 8),
          Text('+${day * 10}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildClaimButton(DailyCheckinController controller) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: controller.canClaimToday.value ? () => controller.claimReward() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.royalGold,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          controller.canClaimToday.value ? 'Claim Now' : 'Already Claimed',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
