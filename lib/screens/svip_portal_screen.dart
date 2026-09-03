import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/svip_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/wallet_controller.dart';
import '../widgets/app_icon.dart';

class SvipPortalScreen extends StatelessWidget {
  const SvipPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: Text('SVIP ROYAL PORTAL', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer3<SvipController, UserController, WalletController>(
        builder: (context, svip, user, wallet, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildCurrentStatus(svip),
                const SizedBox(height: 32),
                Text(
                  'SVIP PRIVILEGES',
                  style: TextStyle(color: AppTheme.royalGold, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 20),
                _buildSvipLevels(svip, wallet),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStatus(SvipController svip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E1E3F), svip.svipLevel > 0 ? svip.getSvipColor(svip.svipLevel) : const Color(0xFF2D2D5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          if (svip.svipLevel > 0) ...[
            svip.buildSvipBadge(svip.svipLevel),
            const SizedBox(height: 16),
            Text(
              'SVIP Level ${svip.svipLevel}',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ] else ...[
            const AppIcon('Icons.workspace_premium_outlined', icon: Icons.workspace_premium_outlined, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'NO SVIP STATUS',
              style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSvipLevels(SvipController svip, WalletController wallet) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final level = index + 1;
        final cost = svip.getSvipCost(level);
        final unlocked = svip.svipLevel >= level;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: unlocked ? AppTheme.royalGold.withValues(alpha: 0.3) : Colors.white10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: unlocked ? AppTheme.royalGold : Colors.white10,
                child: Text('$level', style: TextStyle(color: unlocked ? Colors.black : Colors.white38, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SVIP LEVEL $level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Cost: $cost Diamonds', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              if (!unlocked)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.royalGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final res = svip.buySvip(level);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
                  },
                  child: const Text('UPGRADE'),
                )
              else
                const AppIcon('Icons.check_circle', icon: Icons.check_circle, color: Colors.green),
            ],
          ),
        );
      },
    );
  }
}