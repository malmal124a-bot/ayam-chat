import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/family_controller.dart';
import '../theme/app_theme.dart';

class FamilyRequestsScreen extends StatelessWidget {
  const FamilyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyController>();
    
    return Scaffold(
      backgroundColor: AppTheme.nearBlackPurple,
      appBar: AppBar(
        title: const Text('طلبات الانضمام', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.royalGold),
      ),
      body: family.joinRequests.isEmpty
          ? const Center(
              child: Text('لا توجد طلبات معلقة', style: TextStyle(color: Colors.white38)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: family.joinRequests.length,
              itemBuilder: (context, index) {
                final request = family.joinRequests[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(request.avatar),
                    ),
                    title: Text(request.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => family.acceptJoinRequest(request.userId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.redAccent),
                          onPressed: () => family.rejectJoinRequest(request.userId),
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
