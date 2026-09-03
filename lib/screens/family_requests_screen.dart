import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/family_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class FamilyRequestsScreen extends StatelessWidget {
  const FamilyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyController>();

    return Scaffold(
      backgroundColor: AppTheme.nearBlackPurple,
      appBar: AppBar(
        title: Text('طلبات الدعوة المعلقة', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.royalGold),
      ),
      body: family.pendingInvites.isEmpty
          ? const Center(child: Text('لا توجد طلبات معلقة', style: TextStyle(color: Colors.white38)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: family.pendingInvites.length,
              itemBuilder: (context, index) {
                final invite = family.pendingInvites[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Text(invite.targetName.isNotEmpty ? invite.targetName[0] : '?', style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(invite.targetName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('رقم: ${invite.targetUid}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const AppIcon('Icons.check_circle', icon: Icons.check_circle, color: Colors.green),
                          onPressed: () => family.acceptInvite(invite.id),
                        ),
                        IconButton(
                          icon: const AppIcon('Icons.cancel', icon: Icons.cancel, color: Colors.redAccent),
                          onPressed: () => family.rejectInvite(invite.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
