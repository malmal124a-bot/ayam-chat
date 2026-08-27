import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/family_controller.dart';
import '../theme/app_theme.dart';

class FamilyTasksScreen extends StatelessWidget {
  const FamilyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyController>();

    return Scaffold(
      backgroundColor: AppTheme.nearBlackPurple,
      appBar: AppBar(
        title: const Text('مهام العائلة', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.royalGold),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.diamond_rounded, color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 4),
                  Text('${family.familyDiamonds}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: family.tasks.length,
        itemBuilder: (context, index) {
          final task = family.tasks[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('الجائزة: ${task.reward} ماسة عائلية', style: const TextStyle(color: AppTheme.royalGoldSoft, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (task.isClaimed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Text('تم الاستلام', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else if (task.isCompleted)
                      ElevatedButton(
                        onPressed: () => family.claimTaskReward(task.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          minimumSize: const Size(60, 30),
                        ),
                        child: const Text('استلام', style: TextStyle(fontSize: 11)),
                      )
                    else
                      const Icon(Icons.timer_outlined, color: Colors.white24),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(task.isCompleted ? Colors.green : AppTheme.royalGold),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(task.progress * 100).toInt()}% مكتمل',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
