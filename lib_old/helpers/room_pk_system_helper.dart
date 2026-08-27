import 'package:cloud_firestore/cloud_firestore.dart';

class RoomPKSystemHelper {
  // بدء جولة تحدي PK جديدة وتحديث النقاط لحظياً
  static Future<void> startPKBattle({
    required String roomId1,
    required String roomId2,
  }) async {
    final pkData = {
      'room1Id': roomId1,
      'room2Id': roomId2,
      'room1Score': 0,
      'room2Score': 0,
      'status': 'active',
      'startTime': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('pk_battles').doc('${roomId1}_$roomId2').set(pkData);
  }

  // تحديث نقاط التحدي فور إرسال أي هدية
  static Future<void> updatePKScore({
    required String pkId,
    required bool isRoom1,
    required int addedScore,
  }) async {
    final field = isRoom1 ? 'room1Score' : 'room2Score';
    await FirebaseFirestore.instance.collection('pk_battles').doc(pkId).update({
      field: FieldValue.increment(addedScore),
    });
  }
}
