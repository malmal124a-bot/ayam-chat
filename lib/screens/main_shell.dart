import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'rooms_home_screen.dart';
import '../controllers/rewards_controller.dart';
import '../widgets/daily_reward_popup.dart';
import '../widgets/app_icon.dart';

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Pressing back on the main screen fully closes the app instead of
        // just sending it to the background.
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
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
          items: [
            BottomNavigationBarItem(
              icon: AppIcon('Icons.home', icon: Icons.home_outlined),
              activeIcon: AppIcon('Icons.home_active', icon: Icons.home_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: AppIcon('Icons.chat', icon: Icons.forum_outlined),
              activeIcon: AppIcon('Icons.chat_active', icon: Icons.forum_rounded),
              label: 'الدردشة',
            ),
            BottomNavigationBarItem(
              icon: AppIcon('Icons.person', icon: Icons.person_outline_rounded),
              activeIcon: AppIcon('Icons.person_active', icon: Icons.person_rounded),
              label: 'أنا',
            ),
          ],
        ),
      ),
      ),
    );
  }
}
