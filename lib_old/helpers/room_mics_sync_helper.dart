import 'package:cloud_firestore/cloud_firestore.dart';

class RoomMicsSyncHelper {
  
  // دالة صعود المستخدم على مايك معين داخل الروم وتحديث حالته لحظياً
  static Future<void> occupyMic({
    required String roomId,
    required int micIndex,
    required String userId,
    required String userName,
    required String userAvatar,
  }) async {
    final firestore = FirebaseFirestore.instance;
    
    // تحديث قاعدة البيانات بأن هذا المايك أصبح مشغولا بهذا المستخدم
    await firestore.collection('rooms').doc(roomId).collection('mics').doc('mic_$micIndex').set({
      'isOccupied': true,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'micIndex': micIndex,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // دالة نزول المستخدم من المايك
  static Future<void> leaveMic({
    required String roomId,
    required int micIndex,
  }) async {
    final firestore = FirebaseFirestore.instance;
    
    await firestore.collection('rooms').doc(roomId).collection('mics').doc('mic_$micIndex').set({
      'isOccupied': false,
      'userId': null,
      'userName': null,
      'userAvatar': null,
      'joinedAt': null,
    }, SetOptions(merge: true));
  }
}
