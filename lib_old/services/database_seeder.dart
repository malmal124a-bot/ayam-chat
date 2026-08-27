import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSeeder {
  static Future<void> seedAllData() async {
    final firestore = FirebaseFirestore.instance;

    // 1. Seed Gifts (Fixed, Popular, VIP, Luck with WinRate %, Celebrity with 30-day timer)
    final List<Map<String, dynamic>> defaultGifts = [
      {
        'id': 'gift_rose_01',
        'name': 'وردة حمراء',
        'price': 10,
        'category': 'popular',
        'format': 'png',
        'image_path': 'assets/gifts/rose.png',
        'animation_path': '',
        'isLuck': false,
        'winRate': 0,
        'expirationDays': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'gift_vip_car',
        'name': 'سيارة فراري VIP',
        'price': 5000,
        'category': 'vip',
        'format': 'svga',
        'image_path': 'assets/gifts/car.png',
        'animation_path': 'assets/gifts/car.svga',
        'isLuck': false,
        'winRate': 0,
        'expirationDays': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'gift_luck_box_80',
        'name': 'صندوق الحظ الذهبي (80%)',
        'price': 100,
        'category': 'luck',
        'format': 'json',
        'image_path': 'assets/gifts/luck_box.png',
        'animation_path': 'assets/gifts/luck_box.json',
        'isLuck': true,
        'winRate': 80,
        'expirationDays': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'gift_celeb_star',
        'name': 'تاج المشاهير (شهر تلقائي)',
        'price': 2500,
        'category': 'celebrity',
        'format': 'mp4',
        'image_path': 'assets/gifts/celeb_star.png',
        'animation_path': 'assets/gifts/celeb_star.mp4',
        'isLuck': false,
        'winRate': 0,
        'expirationDays': 30,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var gift in defaultGifts) {
      await firestore.collection('gifts').doc(gift['id']).set(gift, SetOptions(merge: true));
    }

    // 2. Seed Store Items (Avatar Frames, Entrance Effects, Vanity IDs)
    final List<Map<String, dynamic>> defaultStoreItems = [
      {
        'id': 'frame_gold_crown',
        'name': 'إطار التاج الذهبي',
        'price': 1500,
        'category': 'frame',
        'durationDays': 30,
        'assetPath': 'assets/store/frames/gold_crown.png',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'entrance_dragon_king',
        'name': 'دخولية التنين الملكي',
        'price': 3000,
        'category': 'entrance_effect',
        'durationDays': 30,
        'assetPath': 'assets/store/entrances/dragon.svga',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'vanity_id_777',
        'name': 'آي دي مميز (777)',
        'price': 10000,
        'category': 'vanity_id',
        'durationDays': 30,
        'assetPath': '',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var item in defaultStoreItems) {
      await firestore.collection('store_items').doc(item['id']).set(item, SetOptions(merge: true));
    }

    // 3. Seed Banners
    final List<Map<String, dynamic>> defaultBanners = [
      {
        'id': 'banner_main_01',
        'title': 'أهلاً بكم في أيام شات',
        'imageUrl': 'assets/banners/banner_01.png',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];

    for (var banner in defaultBanners) {
      await firestore.collection('banners').doc(banner['id']).set(banner, SetOptions(merge: true));
    }
  }
}
