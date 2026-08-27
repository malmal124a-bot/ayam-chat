import 'package:cloud_firestore/cloud_firestore.dart';

class GiftActionSyncHelper {
  
  // دالة معالجة إرسال الهدية وتحديث الكاس، الصاروخ، ومستوى الحساب لحظياً
  static Future<void> sendGiftAndSyncAll({
    required String roomId,
    required String userId,
    required int giftPrice,
    required int giftXp, // نقاط الخبرة للـ Level
  }) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // 1. تحديث الكاس اليومي والأسبوعي والشهري للروم/المستخدم
    final roomDocRef = firestore.collection('rooms').doc(roomId);
    batch.set(roomDocRef, {
      'dailyScore': FieldValue.increment(giftPrice),
      'weeklyScore': FieldValue.increment(giftPrice),
      'monthlyScore': FieldValue.increment(giftPrice),
      'lastGiftTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. تحديث تقدم الصاروخ في الروم لحظياً
    batch.set(roomDocRef, {
      'rocketProgress': FieldValue.increment(giftPrice),
    }, SetOptions(merge: true));

    // 3. تحديث مستوى الحساب (Level / XP) للمستخدم
    final userDocRef = firestore.collection('users').doc(userId);
    batch.set(userDocRef, {
      'userXp': FieldValue.increment(giftXp),
      'totalSpent': FieldValue.increment(giftPrice),
    }, SetOptions(merge: true));

    // تنفيذ العملية دفعة واحدة (Batch Write) لضمان السرعة والتزامن اللحظي
    await batch.commit();
  }
}
