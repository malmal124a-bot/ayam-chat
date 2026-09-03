import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class FamilyStoreScreen extends StatelessWidget {
  const FamilyStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearBlackPurple,
      appBar: AppBar(
        title: Text('متجر العائلة', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.royalGold),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon('Icons.store', icon: Icons.store, size: 60, color: Colors.white24),
            SizedBox(height: 16),
            Text('المتجر قيد التطوير', style: TextStyle(color: Colors.white38, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
