import 'package:cloud_firestore/cloud_firestore.dart';

class RoomCardSyncHelper {
  // 1. تحديث عدد المتواجدين داخل الغرفة لحظياً في قاعدة البيانات
  static Future<void> updateRoomParticipantsCount({
    required String roomId,
    required int currentCount,
  }) async {
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      'participantsCount': currentCount,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}
