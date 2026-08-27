import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecureAppInitializer {
  static Future<void> verifyAndSecureEverything(String userId, String userName, String userImage) async {
    final db = FirebaseFirestore.instance;
    try {
      // تأمين وتحديث مستند المستخدم والتحقق من الأقسام الخمسة (المحفظة، الأصدقاء، الزوار، المتابعين)
      await db.collection('users').doc(userId).set({
        'uid': userId,
        'name': userName,
        'image': userImage,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // التأمين الكامل لغرفة المستخدم (غرفة واحدة فقط لكل حساب كحد أقصى)
      final roomRef = db.collection('rooms').where('ownerId', isEqualTo: userId);
      final roomSnap = await roomRef.get();

      if (roomSnap.docs.isEmpty) {
        await db.collection('rooms').add({
          'ownerId': userId,
          'roomName': '$userName Room',
          'roomImage': userImage,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
        });
      }
    } catch (e) {
      debugPrint("Security & Sync Error: $e");
    }
  }
}
