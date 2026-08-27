import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus { pending, completed, failed, cancelled }

class Transaction {
  final String id;
  final String targetId;
  final double amount;
  final DateTime date;
  final TransactionStatus status;
  final String? description;
  final String? type;
  final String? adminId;
  final String? adminName;

  Transaction({
    required this.id,
    required this.targetId,
    required this.amount,
    required this.date,
    this.status = TransactionStatus.pending,
    this.description,
    this.type,
    this.adminId,
    this.adminName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetId': targetId,
    'amount': amount,
    'date': date.toIso8601String(),
    'status': status.name,
    'description': description,
    'type': type,
    'adminId': adminId,
    'adminName': adminName,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] ?? '',
    targetId: json['targetId'] ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    status: TransactionStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => TransactionStatus.pending,
    ),
    description: json['description'],
    type: json['type'],
    adminId: json['adminId'],
    adminName: json['adminName'],
  );

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'targetId': targetId,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'status': status.name,
    'description': description,
    'type': type,
    'adminId': adminId,
    'adminName': adminName,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory Transaction.fromFirestore(Map<String, dynamic> data) => Transaction(
    id: data['id'] ?? '',
    targetId: data['targetId'] ?? '',
    amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
    date: data['date'] is Timestamp ? (data['date'] as Timestamp).toDate() : DateTime.now(),
    status: TransactionStatus.values.firstWhere(
      (e) => e.name == data['status'],
      orElse: () => TransactionStatus.pending,
    ),
    description: data['description'],
    type: data['type'],
    adminId: data['adminId'],
    adminName: data['adminName'],
  );
}
