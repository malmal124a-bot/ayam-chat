import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoomMembersListWidget extends StatelessWidget {
  final String roomId;

  const RoomMembersListWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // جلب الأعضاء المتواجدين داخل هذه الغرفة من قاعدة البيانات
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('participants')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data!.docs;

        if (members.isEmpty) {
          return const Center(
            child: Text(
              'قائمة الأعضاء فارغة',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final memberData = members[index].data() as Map<String, dynamic>;
            final userName = memberData['userName'] ?? 'مستخدم';
            final role = memberData['role'] ?? 'member'; // 'owner', 'admin', 'member'

            // تحديد لون النقطة بناءً على الرتبة المطلوبة
            Color? dotColor;
            if (role == 'owner') {
              dotColor = Colors.red; // الأونر نقطة حمراء
            } else if (role == 'admin') {
              dotColor = Colors.amber; // الأدمن نقطة صفراء
            } else {
              dotColor = null; // العضو العادي بدون نقطة
            }

            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Row(
                children: [
                  Text(
                    userName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  if (dotColor != null)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                role == 'owner' ? 'مالك الغرفة' : (role == 'admin' ? 'مشرف' : 'عضو'),
                style: const TextStyle(color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}
