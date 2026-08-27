import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MedalType { vip, milestone, event }

class Medal {
  final String id;
  final String nameKey;
  final String iconPath;
  final MedalType type;
  final String descriptionKey;

  Medal({
    required this.id,
    required this.nameKey,
    required this.iconPath,
    required this.type,
    required this.descriptionKey,
  });

  String get name => tr(nameKey);
  String get description => tr(descriptionKey);

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameKey': nameKey,
    'iconPath': iconPath,
    'type': type.name,
    'descriptionKey': descriptionKey,
  };

  factory Medal.fromJson(Map<String, dynamic> json) => Medal(
    id: json['id'],
    nameKey: json['nameKey'],
    iconPath: json['iconPath'],
    type: MedalType.values.firstWhere((e) => e.name == json['type'], orElse: () => MedalType.milestone),
    descriptionKey: json['descriptionKey'],
  );

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'nameKey': nameKey,
    'iconPath': iconPath,
    'type': type.name,
    'descriptionKey': descriptionKey,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory Medal.fromFirestore(String id, Map<String, dynamic> data) => Medal(
    id: id,
    nameKey: data['nameKey'] ?? '',
    iconPath: data['iconPath'] ?? '',
    type: MedalType.values.firstWhere((e) => e.name == data['type'], orElse: () => MedalType.milestone),
    descriptionKey: data['descriptionKey'] ?? '',
  );
}
