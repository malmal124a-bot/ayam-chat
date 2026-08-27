import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/family_controller.dart';
import '../theme/app_theme.dart';

class FamilyMembersScreen extends StatelessWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyController>();
    
    return Scaffold(
      backgroundColor: AppTheme.nearBlackPurple,
      appBar: AppBar(
        title: const Text('أعضاء العائلة', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.royalGold),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: family.members.length,
        itemBuilder: (context, index) {
          final member = family.members[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.2)),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: AssetImage(member.avatar),
              ),
              title: Text(member.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(member.role, style: TextStyle(color: member.role == 'Owner' ? AppTheme.royalGold : Colors.white70)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('المساهمة', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Text('${member.contribution}', style: const TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
