import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MicSettingsHelper {
  // دالة لتحديث وحفظ حالة المايك (مفتوح/مقفل/أو إعدادات الذبذبة) في قاعدة البيانات رسمياً
  static Future<void> updateMicStateInFirestore({
    required String roomId,
    required String userId,
    required bool isMicOn,
    required double volumeLevel,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('participants')
          .doc(userId)
          .set({
        'isMicOn': isMicOn,
        'volumeLevel': volumeLevel,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating mic state: $e');
    }
  }
}
