enum TransactionStatus { pending, completed, failed, cancelled }

class Transaction {
  final String id;
  final String targetId;
  final double amount;
  final DateTime date;
  final TransactionStatus status;
  final String? description;

  Transaction({
    required this.id,
    required this.targetId,
    required this.amount,
    required this.date,
    this.status = TransactionStatus.pending,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetId': targetId,
    'amount': amount,
    'date': date.toIso8601String(),
    'status': status.name,
    'description': description,
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
  );
}
