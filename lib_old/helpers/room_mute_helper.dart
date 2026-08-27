import 'package:cloud_firestore/cloud_firestore.dart';

class RoomMuteHelper {
  // دالة كتم أو إلغاء كتم المستخدم
  static Future<void> toggleUserMute({
    required String roomId,
    required int micIndex,
    required bool isMuted,
  }) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('mics')
        .doc('mic_$micIndex')
        .update({
      'isMuted': isMuted,
    });
  }
}
