import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomNavigationHelper {
  // دالة إنشاء أو فتح غرفة المستخدم (غرفة واحدة فقط لكل حساب) والتحقق من الربط
  static Future<void> openOrCreateUserRoom(BuildContext context, String userId, String userName, String userImage) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Use userId as roomId for one-to-one matching
      final roomId = userId;
      
      // 1. التحقق مما إذا كانت الغرفة موجودة مسبقاً لهذا المستخدم مع timeout لمنع التجمد
      final roomDoc = await firestore
          .collection('rooms')
          .doc(roomId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout querying room document');
            },
          );

      if (!roomDoc.exists) {
        // 2. إذا لم تكن موجودة، يتم إنشاء غرفة جديدة باستخدام userId كـ roomId
        await firestore.collection('rooms').doc(roomId).set({
          'roomId': roomId,
          'ownerId': userId,
          'roomName': '$userName\'s Room',
          'roomImage': userImage, // Base64 string
          'createdAt': FieldValue.serverTimestamp(),
          'active': true,
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Timeout creating room document');
          },
        );
      }

      // 4. الانتقال الفوري لشاشة الغرفة الفعلية (Room Screen) بعد نجاح الربط
      if (context.mounted) {
        Navigator.pushNamed(
          context,
          '/room_screen',
          arguments: {
            'roomId': roomId,
            'roomName': '$userName\'s Room',
            'roomCover': userImage,
            'isOwner': true,
          },
        );
      }
    } on FirebaseException catch (e) {
      debugPrint("Firebase Error opening room: ${e.code} - ${e.message}");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في قاعدة البيانات: ${e.message}')),
        );
      }
    } catch (e) {
      debugPrint("Error opening room: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في فتح الغرفة: $e')),
        );
      }
    }
  }

  // دالة التعامل مع زر الرجوع (Back Button) داخل الروم
  static Future<bool> handleRoomBackPress(BuildContext context) async {
    // إظهار نافذة الاختيارين (خروج نهائي أو احتفاظ) بدلاً من الخروج المفاجئ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          'خروج من الغرفة',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'اختر طريقتك للخروج من الغرفة:',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        actions: [
          // زر الخروج النهائي
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق النافذة
              Navigator.of(context).pop(); // الخروج للصفحة الرئيسية للرومات
            },
            child: const Text('خروج نهائي', style: TextStyle(color: Colors.red)),
          ),
          // زر الاحتفاظ والخروج (تصغير لعوامة)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق النافذة
              // هنا يتم تصغير الروم لشاشة مصغرة (عائمة) والرجوع للرئيسية
              Navigator.of(context).pop(); 
            },
            child: const Text('احتفاظ وخروج', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    // إرجاع false لمنع الخروج التلقائي المباشر من التطبيق
    return false;
  }
}
