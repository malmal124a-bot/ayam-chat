import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';
import 'screens/voice_room_screen.dart';
import 'theme/app_theme.dart';
import 'controllers/user_controller.dart';
import 'controllers/inventory_controller.dart';
import 'controllers/wallet_controller.dart';
import 'controllers/gift_controller.dart';
import 'controllers/gift_manager.dart';
import 'controllers/store_controller.dart';
import 'controllers/svip_controller.dart';
import 'controllers/family_controller.dart';
import 'controllers/security_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/privacy_controller.dart';
import 'controllers/tasks_controller.dart';
import 'controllers/invite_controller.dart';
import 'controllers/agency_controller.dart';
import 'controllers/shipping_agency_controller.dart';
import 'controllers/leaderboard_controller.dart';
import 'controllers/medal_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/rewards_controller.dart';
import 'controllers/game_controller.dart';
import 'controllers/rocket_controller.dart';
import 'services/cron_service.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    
    debugPrint('Initializing Firebase...');
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
    
    // Enable Firebase Auth persistence for session survival across app restarts (web only)
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      debugPrint('Firebase Auth persistence set to LOCAL');
    }
    
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    debugPrint('User logged in status: $isLoggedIn');

    // Start Background Services
    CronService().start();
    debugPrint('Cron service started');
    
    debugPrint('Starting app...');
    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthController()),
            ChangeNotifierProvider(create: (_) => UserController()),
            ChangeNotifierProvider(create: (_) => WalletController()),
            ChangeNotifierProvider(create: (_) => InventoryController()),
            ChangeNotifierProvider(create: (_) => GiftController()),
            ChangeNotifierProvider(create: (_) => GiftManager()),
            ChangeNotifierProvider(create: (_) => StoreController()),
            ChangeNotifierProvider(create: (_) => SvipController()),
            ChangeNotifierProvider(create: (_) => FamilyController()),
            ChangeNotifierProvider(create: (_) => SecurityController()),
            ChangeNotifierProvider(create: (_) => NotificationController()),
            ChangeNotifierProvider(create: (_) => PrivacyController()),
            ChangeNotifierProvider(create: (_) => TasksController()),
            ChangeNotifierProvider(create: (_) => InviteController()),
            ChangeNotifierProvider(create: (_) => AgencyController()),
            ChangeNotifierProvider(create: (_) => ShippingAgencyController()),
            ChangeNotifierProvider(create: (_) => LeaderboardController()),
            ChangeNotifierProvider(create: (_) => MedalController()),
            ChangeNotifierProvider(create: (_) => GameController()),
            ChangeNotifierProvider(create: (_) => RocketController()),
            ChangeNotifierProvider(create: (_) => RewardsController()..init()),
          ],
          child: AyamChatApp(isLoggedIn: isLoggedIn),
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Fatal error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Run a fallback app with error display
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AyamChatApp extends StatelessWidget {
  final bool isLoggedIn;
  const AyamChatApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Colors.black, // Background color for the area outside the mobile viewport
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 375),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Ayam Chat',
                theme: AppTheme.theme,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                initialRoute: '/', // Always start at splash screen
                routes: {
                  '/': (context) => const SplashScreen(),
                  '/login': (context) => const LoginScreen(),
                  '/main_shell': (context) => const MainShell(),
                  '/room_screen': (context) {
                    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                    return VoiceRoomScreen(
                      roomId: args?['roomId'],
                      roomName: args?['roomName'],
                      roomCover: args?['roomCover'],
                      isOwner: args?['isOwner'] ?? false,
                    );
                  },
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
