import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MicControlPanelHelper {

  // 1. عرض لوحة تحكم المايك والبروفايل عند الضغط على المستخدم
  static void showMicControlSheet(BuildContext context, String roomId, Map<String, dynamic> micData) {
    final String userName = micData['userName'] ?? 'مستخدم';
    final String userAvatar = micData['userAvatar'] ?? '';
    final int micIndex = micData['micIndex'] ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundImage: userAvatar.isNotEmpty ? NetworkImage(userAvatar) : null,
                child: userAvatar.isEmpty ? const Icon(Icons.person, size: 35) : null,
              ),
              const SizedBox(height: 10),
              Text(
                userName,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // زرار عرض البروفايل الكامل
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () {
                  Navigator.pop(context);
                  // انتقل لصفحة البروفايل الكاملة باستخدام userId
                },
                icon: const Icon(Icons.person_outline, color: Colors.black),
                label: const Text('عرض البروفايل والبيانات', style: TextStyle(color: Colors.black)),
              ),
              const SizedBox(height: 10),

              // أزرار التحكم في المايك (كتم، إنزال من المايك)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      // إنزال المستخدم من المايك
                      await FirebaseFirestore.instance
                          .collection('rooms')
                          .doc(roomId)
                          .collection('mics')
                          .doc('mic_$micIndex')
                          .update({
                        'isOccupied': false,
                        'userId': null,
                        'userName': null,
                        'userAvatar': null,
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.mic_off, color: Colors.red),
                    label: const Text('إنزال من المايك', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
