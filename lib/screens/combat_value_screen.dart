import 'package:flutter/material.dart';
import '../controllers/user_controller.dart';
import '../widgets/app_icon.dart';
import 'leaderboard_screen.dart';

class CombatValueScreen extends StatefulWidget {
  const CombatValueScreen({super.key});

  @override
  State<CombatValueScreen> createState() => _CombatValueScreenState();
}

class _CombatValueScreenState extends State<CombatValueScreen> {
  final UserController userController = UserController();

  @override
  void initState() {
    super.initState();
    userController.addListener(_refresh);
  }

  @override
  void dispose() {
    userController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('قيمة القتال (CP)',
            style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              AppIcon('Icons.whatshot', icon: Icons.whatshot, size: 100, color: theme.colorScheme.secondary),
              const SizedBox(height: 24),
              Text('قوتك القتالية الحالية',
                  style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 5),
                  ],
                ),
                child: Text(
                  '${userController.combatValue} CP',
                  style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontSize: 40,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    _buildInfoTile(
                        context, Icons.shopping_bag, 'شراء العناصر', 'كل 10 ماسات = 1 CP'),
                    const SizedBox(height: 12),
                    _buildInfoTile(context, Icons.account_balance_wallet,
                        'شحن الرصيد', 'كل 1 دولار = 10 CP'),
                    const SizedBox(height: 12),
                    _buildInfoTile(context, Icons.card_giftcard, 'إرسال الهدايا',
                        'تزيد القوة بناءً على قيمة الهدية'),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                icon: const AppIcon('Icons.leaderboard', icon: Icons.leaderboard),
                label: const Text('مشاهدة لوحة المتصدرين'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
      BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold)),
                Text(description,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
