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
        title: Text('أعضاء العائلة', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.royalGold),
      ),
      body: family.members.isEmpty
          ? const Center(child: Text('لا يوجد أعضاء بعد', style: TextStyle(color: Colors.white38)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: family.members.length,
              itemBuilder: (context, index) {
                final member = family.members[index];
                final bool isOwner = member.role == 'owner';
                final bool isAdmin = member.role == 'admin';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppTheme.royalGold.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white24,
                      backgroundImage: member.avatar.isNotEmpty && member.avatar.startsWith('http')
                          ? NetworkImage(member.avatar)
                          : null,
                      child: member.avatar.isEmpty || !member.avatar.startsWith('http')
                          ? Text(member.name.isNotEmpty ? member.name[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    title: Text(member.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      isOwner ? 'المالك' : isAdmin ? 'مشرف' : 'عضو',
                      style: TextStyle(color: isOwner ? AppTheme.royalGold : isAdmin ? Colors.amberAccent : Colors.white70),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('المساهمة', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        Text('${member.contribution}', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
