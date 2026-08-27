import 'package:cloud_firestore/cloud_firestore.dart';

enum StoreItemType { frame, entry, entryEffect, fancyId }

class StoreItem {
  final String id;
  final String name;
  final String imagePath;
  final double price;
  final StoreItemType type;

  StoreItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'price': price,
    'type': type.name,
  };

  factory StoreItem.fromJson(Map<String, dynamic> json) => StoreItem(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    imagePath: json['imagePath'] ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    type: StoreItemType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => StoreItemType.frame,
    ),
  );

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'price': price,
    'type': type.name,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory StoreItem.fromFirestore(String id, Map<String, dynamic> data) => StoreItem(
    id: id,
    name: data['name'] ?? '',
    imagePath: data['imagePath'] ?? '',
    price: (data['price'] as num?)?.toDouble() ?? 0.0,
    type: StoreItemType.values.firstWhere(
      (e) => e.name == data['type'],
      orElse: () => StoreItemType.frame,
    ),
  );
}
