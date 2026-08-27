import 'dart:typed_data';

enum MessageType { text, image, video, audio, file }

class ChatMessage {
  final String id;
  final String? text;
  final MessageType type;
  final bool isUser;
  final DateTime timestamp;
  final String? mediaPath;
  final Uint8List? mediaBytes;
  final String? fileName;

  ChatMessage({
    required this.id,
    this.text,
    required this.type,
    required this.isUser,
    required this.timestamp,
    this.mediaPath,
    this.mediaBytes,
    this.fileName,
  });
}
