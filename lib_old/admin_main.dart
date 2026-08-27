import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options.dart';
import 'admin/screens/admin_login_screen.dart';
import 'admin/screens/admin_dashboard_screen.dart';
import 'admin/controllers/admin_auth_controller.dart';

// Direct Dart seeding function
Future<void> seedFirestoreDirectly() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    print('=== DIRECT DART SEEDING STARTED ===');
    
    // Seed Gifts with actual asset paths from assets/gifts/
    final gifts = [
      {
        'id': 'gift_1593',
        'name': 'وردة',
        'price': 10,
        'category': 'popular',
        'format': 'svga',
        'imagePath': 'assets/gifts/#1593_¦++¦-¦.png',
        'animationPath': 'assets/gifts/#1593_¦++¦-¦.svga',
        'isLuckGift': false,
        'winProbability': 0,
        'expirationDays': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'gift_2461',
        'name': 'سيارة',
        'price': 500,
        'category': 'vip',
        'format': 'svga',
        'imagePath': 'assets/gifts/#2461_¦·+ñ-F.png',
        'animationPath': 'assets/gifts/#2461_¦·+ñ-F.svga',
        'isLuckGift': false,
        'winProbability': 0,
        'expirationDays': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'gift_2487',
        'name': 'قلب',
        'price': 100,
        'category': 'popular',
        'format': 'svga',
        'imagePath': 'assets/gifts/#2487_+-¦+-n¦S+f.png',
        'animationPath': 'assets/gifts/#2487_+-¦+-n¦S+f.svga',
        'isLuckGift': false,
        'winProbability': 0,
        'expirationDays': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'gift_2495',
        'name': 'نجوم',
        'price': 200,
        'category': 'popular',
        'format': 'svga',
        'imagePath': 'assets/gifts/#2495_++¦¼+±+=¦°.png',
        'animationPath': 'assets/gifts/#2495_++¦¼+±+=¦°.svga',
        'isLuckGift': false,
        'winProbability': 0,
        'expirationDays': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'gift_2597',
        'name': 'زهرة',
        'price': 50,
        'category': 'popular',
        'format': 'svga',
        'imagePath': 'assets/gifts/#2597_+-¦G+«¦n.png',
        'animationPath': 'assets/gifts/#2597_+-¦G+«¦n.svga',
        'isLuckGift': false,
        'winProbability': 0,
        'expirationDays': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'gift_2785',
        'name': 'فراشة',
        'price': 150,
        'category': 'popular',
        'format': 'svga',
        'imagePath': 'assets/gifts/#2785_¦«---í-_.png',
        'animationPath': 'assets/gifts/#2785_¦«---í-_.svga',
        'isLuckGift': false,
        'winProbability': 0,
        'expirationDays': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'gift_2836',
        'name': 'قمر',
        'price': 300,
        'category': 'vip',
        'format': 'svga',
        'imagePath': 'assets/gifts/#2836_-+¦S¦8+¦¦s.png',
        'animationPath': 'assets/gifts/#2836_-+¦S¦8+¦¦s.svga',
        'isLuckGift': false,
        'winProbability': 0,
        'expirationDays': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'gift_lucky_rose',
        'name': 'وردة الحظ',
        'price': 100,
        'category': 'luck',
        'format': 'svga',
        'imagePath': 'assets/gifts/¦++--ª.jpg',
        'animationPath': 'assets/gifts/¦++--ª.svga',
        'isLuckGift': true,
        'winProbability': 80,
        'expirationDays': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'gift_crown',
        'name': 'تاج',
        'price': 1000,
        'category': 'vip',
        'format': 'svga',
        'imagePath': 'assets/gifts/¦++ó.png',
        'animationPath': 'assets/gifts/¦++ó.svga',
        'isLuckGift': false,
        'winProbability': 0,
        'expirationDays': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var gift in gifts) {
      await firestore.collection('gifts').doc(gift['id'] as String).set(gift);
      print('Seeded gift: ${gift['name']} (ID: ${gift['id']})');
    }
    print('Gifts seeded successfully (${gifts.length} items)');

    // Seed Store Items with actual asset paths from assets/vip/ and assets/store_assets/
    final storeItems = [
      // Frames from assets/vip/
      {
        'id': 'frame_vip1',
        'name': 'إطار VIP 1',
        'type': 'frame',
        'price': 1000,
        'imagePath': 'assets/vip/vip1.png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_vip2',
        'name': 'إطار VIP 2',
        'type': 'frame',
        'price': 2000,
        'imagePath': 'assets/vip/vip2.png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_vip3',
        'name': 'إطار VIP 3',
        'type': 'frame',
        'price': 3000,
        'imagePath': 'assets/vip/vip3.png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_1',
        'name': 'إطار ذهبي',
        'type': 'frame',
        'price': 1500,
        'imagePath': 'assets/vip/1.png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_2',
        'name': 'إطار فضي',
        'type': 'frame',
        'price': 1200,
        'imagePath': 'assets/vip/2.png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_3',
        'name': 'إطار برونزي',
        'type': 'frame',
        'price': 1000,
        'imagePath': 'assets/vip/3.png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_12',
        'name': 'إطار سحري',
        'type': 'frame',
        'price': 2500,
        'imagePath': 'assets/vip/12.png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_29',
        'name': 'إطار ملكي',
        'type': 'frame',
        'price': 5000,
        'imagePath': 'assets/vip/29.png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_37',
        'name': 'إطار الفارس',
        'type': 'frame',
        'price': 4000,
        'imagePath': 'assets/vip/37.png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_38',
        'name': 'إطار النبيل',
        'type': 'frame',
        'price': 4500,
        'imagePath': 'assets/vip/38.png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_13_1',
        'name': 'إطار النجوم 1',
        'type': 'frame',
        'price': 3500,
        'imagePath': 'assets/vip/13 (1).png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_13_2',
        'name': 'إطار النجوم 2',
        'type': 'frame',
        'price': 3500,
        'imagePath': 'assets/vip/13 (2).png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_27_1',
        'name': 'إطار الياقوت 1',
        'type': 'frame',
        'price': 6000,
        'imagePath': 'assets/vip/27 (1).png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_27_2',
        'name': 'إطار الياقوت 2',
        'type': 'frame',
        'price': 6000,
        'imagePath': 'assets/vip/27 (2).png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_28_1',
        'name': 'إطار الزمرد 1',
        'type': 'frame',
        'price': 7000,
        'imagePath': 'assets/vip/28 (1).png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_28_2',
        'name': 'إطار الزمرد 2',
        'type': 'frame',
        'price': 7000,
        'imagePath': 'assets/vip/28 (2).png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_39_1',
        'name': 'إطار الألماس 1',
        'type': 'frame',
        'price': 8000,
        'imagePath': 'assets/vip/39 (1).png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_39_2',
        'name': 'إطار الألماس 2',
        'type': 'frame',
        'price': 8000,
        'imagePath': 'assets/vip/39 (2).png',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      // Frames from assets/store_assets/
      {
        'id': 'frame_admin',
        'name': 'إطار الإدارة',
        'type': 'frame',
        'price': 5000,
        'imagePath': 'assets/store_assets/admin_frame.webp.webp',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_cggs',
        'name': 'إطار سي جي',
        'type': 'frame',
        'price': 3000,
        'imagePath': 'assets/store_assets/cggs_frame.webp.webp',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'frame_dodo',
        'name': 'إطار دودو',
        'type': 'frame',
        'price': 2000,
        'imagePath': 'assets/store_assets/dodo_frame.webp.webp',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      // Tags from assets/store_assets/
      {
        'id': 'tag_activities',
        'name': 'شارة الأنشطة',
        'type': 'tag',
        'price': 500,
        'imagePath': 'assets/store_assets/activities_tag.webp.webp',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'tag_agency',
        'name': 'شارة الوكالة',
        'type': 'tag',
        'price': 1000,
        'imagePath': 'assets/store_assets/agency_tag.webp.webp',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'tag_bd',
        'name': 'شارة BD',
        'type': 'tag',
        'price': 500,
        'imagePath': 'assets/store_assets/bd_tag.webp.webp',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'tag_helper',
        'name': 'شارة المساعد',
        'type': 'tag',
        'price': 500,
        'imagePath': 'assets/store_assets/helper_tag.webp.webp',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'tag_host',
        'name': 'شارة المضيف',
        'type': 'tag',
        'price': 500,
        'imagePath': 'assets/store_assets/host_tag.webp.webp',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'tag_supporter',
        'name': 'شارة الداعم',
        'type': 'tag',
        'price': 500,
        'imagePath': 'assets/store_assets/supporter_tag.webp.webp',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      // Entrance Effects from assets/entry_effects/ (lightweight PNG thumbnails only)
      {
        'id': 'entrance_159',
        'name': 'دخولية النجوم',
        'type': 'entrance_effect',
        'category': 'entrance_effect',
        'price': 2000,
        'imagePath': 'assets/entry_effects/#159_+e+µ++¦¼.png',
        'animationPath': 'assets/entry_effects/#159_+e+µ++¦¼_rand.svga',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'entrance_426',
        'name': 'دخولية القلوب',
        'type': 'entrance_effect',
        'category': 'entrance_effect',
        'price': 1500,
        'imagePath': 'assets/entry_effects/#426_+¦¦8+_¦¦.png',
        'animationPath': 'assets/entry_effects/#426_+¦¦8+_¦¦.svga',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'entrance_472',
        'name': 'دخولية الزهور',
        'type': 'entrance_effect',
        'category': 'entrance_effect',
        'price': 1800,
        'imagePath': 'assets/entry_effects/#472_-·-f¦8-¦.png',
        'animationPath': 'assets/entry_effects/#472_-·-f¦8-¦.svga',
        'expirationDays': 30,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var item in storeItems) {
      await firestore.collection('store_items').doc(item['id'] as String).set(item);
      print('Seeded store item: ${item['name']} (ID: ${item['id']})');
    }
    print('Store items seeded successfully (${storeItems.length} items)');

    print('=== DIRECT DART SEEDING COMPLETE ===');
  } catch (e) {
    print('Error during direct seeding: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable Firebase Auth persistence for admin sessions
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  
  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();
  
  // Seed Firestore directly with Dart code
  await seedFirestoreDirectly();
  
  // Initialize Admin Auth Controller
  final adminAuthController = AdminAuthController();
  await adminAuthController.init();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('tr'),
        Locale('hi'),
        Locale('pt'),
        Locale('ru'),
        Locale('zh'),
      ],
      path: 'assets/translations',
      startLocale: const Locale('ar'),
      fallbackLocale: const Locale('ar'),
      child: AdminPortal(adminAuthController: adminAuthController),
    ),
  );
}

class AdminPortal extends StatelessWidget {
  final AdminAuthController adminAuthController;
  
  const AdminPortal({
    super.key,
    required this.adminAuthController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayam Chat Admin Portal',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: const Locale('ar'), // Force Arabic locale
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: ListenableBuilder(
        listenable: adminAuthController,
        builder: (context, child) {
          if (adminAuthController.isAdminLoggedIn) {
            return AdminDashboardScreen(adminAuthController: adminAuthController);
          }
          return AdminLoginScreen(adminAuthController: adminAuthController);
        },
      ),
    );
  }
}
