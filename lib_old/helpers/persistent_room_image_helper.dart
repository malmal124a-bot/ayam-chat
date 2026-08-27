import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class PersistentRoomImageHelper {
  
  // دالة لجلب وعرض صورة الغرفة الثابتة من قاعدة البيانات
  static Widget getPersistentRoomImage({
    required String roomId,
    double radius = 30,
    BoxFit fit = BoxFit.cover,
  }) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(roomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return CircleAvatar(
            radius: radius,
            child: const Icon(Icons.room),
          );
        }

        final roomData = snapshot.data!.data() as Map<String, dynamic>;
        final String roomImage = roomData['roomImage'] ?? '';

        if (roomImage.isEmpty) {
          return CircleAvatar(
            radius: radius,
            child: const Icon(Icons.room),
          );
        }

        // دعم عرض الصور سواء كانت Base64 أو رابط شبكي
        ImageProvider imageProvider;
        if (roomImage.startsWith('data:image')) {
          try {
            final base64Str = roomImage.split(',').last;
            final bytes = base64Decode(base64Str);
            imageProvider = MemoryImage(bytes);
          } catch (e) {
	    imageProvider = const AssetImage('assets/Asad/room.jpg'); // احتياطي لو حدث خطأ
          }
        } else if (roomImage.startsWith('http')) {
          imageProvider = NetworkImage(roomImage);
        } else if (roomImage.startsWith('assets/')) {
          imageProvider = AssetImage(roomImage);
        } else {
          imageProvider = const AssetImage('assets/Asad/room.jpg');
        }

        return CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        );
      },
    );
  }
}
