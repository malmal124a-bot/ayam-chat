import 'package:cloud_firestore/cloud_firestore.dart';

class RoomManagementHelper {
  
  // 1. تحديث وتخزين صورة البروفايل للمستخدم
  static Future<void> updateProfileImage({
    required String userId,
    required String base64Image,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'profileImage': base64Image,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. تحديث حالة قفل الروم أو الاحتفاظ بها
  static Future<void> updateRoomControlSettings({
    required String roomId,
    required bool isLocked,
    required bool isSaved,
  }) async {
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      'isLocked': isLocked,
      'isSaved': isSaved,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // 3. التحكم في المايكات الـ 20 (حجز المايك، فتحه، أو كتمه للمستخدم)
  static Future<void> updateMicSlotState({
    required String roomId,
    required int micIndex, // من 0 إلى 19 (إجمالي 20 مايك)
    required String? userId, // لو فاضي يبقى المايك متاح، لو فيه ID يبقى محجوز
    required bool isMicOn,
  }) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('mics')
        .doc('mic_$micIndex')
        .set({
      'micIndex': micIndex,
      'userId': userId,
      'isMicOn': isMicOn,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
