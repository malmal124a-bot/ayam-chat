import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoomTextChatWidget extends StatelessWidget {
  final String roomId;
  final TextEditingController _controller = TextEditingController();

  RoomTextChatWidget({super.key, required this.roomId});

  void _sendMessage(String userId, String userName) async {
    if (_controller.text.trim().isEmpty) return;

    final messageText = _controller.text.trim();
    _controller.clear();

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'senderId': userId,
      'senderName': userName,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text', // يمكن أن تكون 'text' أو 'image'
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .doc(roomId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!.docs;

              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(
                      msg['senderName'] ?? 'مستخدم',
                      style: const TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                    subtitle: Text(
                      msg['text'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالة...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.amber),
                onPressed: () => _sendMessage('current_user_id', 'اسم المستخدم'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
