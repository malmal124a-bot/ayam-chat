import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class RelationshipsScreen extends StatelessWidget {
  const RelationshipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmSandBackground,
      appBar: AppBar(
        title: Text('relationships'.tr(), style: TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AppIcon('Icons.arrow_back_ios_new', icon: Icons.arrow_back_ios_new, color: AppTheme.darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon('Icons.favorite_border_rounded', icon: Icons.favorite_border_rounded, size: 80, color: Colors.pinkAccent),
            const SizedBox(height: 20),
            Text(
              'coming_soon'.tr(),
              style: TextStyle(color: AppTheme.darkBrown, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
