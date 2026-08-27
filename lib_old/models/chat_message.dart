import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? senderId;
  final String? senderName;

  ChatMessage({
    required this.id,
    this.text,
    required this.type,
    required this.isUser,
    required this.timestamp,
    this.mediaPath,
    this.mediaBytes,
    this.fileName,
    this.senderId,
    this.senderName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'type': type.name,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'mediaPath': mediaPath,
    'fileName': fileName,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? '',
    text: json['text'],
    type: MessageType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => MessageType.text,
    ),
    isUser: json['isUser'] ?? false,
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    mediaPath: json['mediaPath'],
    fileName: json['fileName'],
  );

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'text': text,
    'type': type.name,
    'isUser': isUser,
    'timestamp': Timestamp.fromDate(timestamp),
    'mediaPath': mediaPath,
    'fileName': fileName,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> data) => ChatMessage(
    id: id,
    text: data['text'],
    type: MessageType.values.firstWhere(
      (e) => e.name == data['type'],
      orElse: () => MessageType.text,
    ),
    isUser: data['isUser'] as bool? ?? false,
    timestamp: data['timestamp'] is Timestamp ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
    mediaPath: data['mediaPath'],
    fileName: data['fileName'],
  );
}
