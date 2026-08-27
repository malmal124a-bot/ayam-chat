import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'rooms_home_screen.dart';
import '../controllers/rewards_controller.dart';
import '../widgets/daily_reward_popup.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int index;

  final pages = const [
    RoomsHomeScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    
    // Show Daily Reward Popup if needed - displayed on Home Screen (index 0)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final rewards = Provider.of<RewardsController>(context, listen: false);
        if (rewards.shouldShowPopup && index == 0) {
          final parentContext = context;
          showDialog(
            context: parentContext,
            barrierDismissible: false,
            builder: (_) => DailyRewardPopup(rewards: rewards),
          );
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: pages[index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
          selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
          type: theme.bottomNavigationBarTheme.type ?? BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum_rounded),
              label: 'الدردشة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'أنا',
            ),
          ],
        ),
      ),
    );
  }
}
