import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class FamilyTasksScreen extends StatelessWidget {
  const FamilyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearBlackPurple,
      appBar: AppBar(
        title: Text('مهام العائلة', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.royalGold),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon('Icons.task_alt', icon: Icons.task_alt, size: 60, color: Colors.white24),
            SizedBox(height: 16),
            Text('المهام قيد التطوير', style: TextStyle(color: Colors.white38, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
