import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
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
import 'controllers/daily_checkin_controller.dart';
import 'controllers/dm_controller.dart';
import 'services/cron_service.dart';
import 'services/supabase_service.dart';
import 'services/catalog_service.dart';
import 'services/svga_asset_service.dart';
import 'services/theme_service.dart';
import 'services/screen_visual_service.dart';
import 'services/level_service.dart';
import 'services/badge_necklace_services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplashApp());
}

class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String _status = 'جاري التحميل...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _initApp());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateStatus(String msg) {
    if (mounted) setState(() => _status = msg);
  }

  Future<void> _initApp() async {
    try {
      _updateStatus('تهيئة الترجمة...');
      await EasyLocalization.ensureInitialized();

      _updateStatus('الاتصال بالخادم...');
      await SupabaseService.initialize();

      if (kIsWeb) {
        await AuthController().handleWebAuthCallback();
      }

      _updateStatus('تحميل البيانات...');
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      // Load dynamic theme colors from admin dashboard (AWAIT so theme is ready)
      await ThemeService.instance.loadColors();
      // Load screen visuals from admin dashboard
      await ScreenVisualService.instance.loadVisuals();
      // Load level configs from admin dashboard
      await LevelService.instance.loadLevels();
      // Load badges from admin dashboard
      await BadgeService.instance.loadBadges();
      // Load necklaces from admin dashboard
      await NecklaceService.instance.loadNecklaces();
      // Pre-cache SVGA animations to disk in background (non-blocking)
      SvgaAssetService.instance.preCacheAll();

      CronService().start();
      LeaderboardController().loadFromDatabase();
      CatalogService.refreshAll();

      Get.put(DailyCheckinController());

      _updateStatus('فتح التطبيق...');

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MultiProvider(
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
              ChangeNotifierProvider(create: (_) => DmController()..init()),
            ],
            child: EasyLocalization(
              supportedLocales: const [Locale('en'), Locale('ar')],
              path: 'assets/translations',
              fallbackLocale: const Locale('en'),
              child: AyamChatApp(isLoggedIn: isLoggedIn),
            ),
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Fatal init error: $e\n$st');
      if (!mounted) return;
      setState(() => _status = 'حدث خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ),
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 32),
              const Text(
                'Ayam Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD700),
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
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
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ayam Chat',
          theme: AppTheme.theme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: isLoggedIn ? const MainShell() : const LoginScreen(),
          builder: (context, child) {
            if (kIsWeb) {
              return Container(
                color: const Color(0xFF1E1E1E),
                child: Center(
                  child: SizedBox(
                    width: 370,
                    child: ClipRect(child: child),
                  ),
                ),
              );
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
