class Relationship {
  final String id;
  final String userId1;
  final String userId2;
  final String userName1;
  final String userName2;
  final DateTime createdAt;
  final int relationshipLevel;

  Relationship({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.userName1,
    required this.userName2,
    required this.createdAt,
    this.relationshipLevel = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId1': userId1,
      'userId2': userId2,
      'userName1': userName1,
      'userName2': userName2,
      'createdAt': createdAt.toIso8601String(),
      'relationshipLevel': relationshipLevel,
    };
  }

  factory Relationship.fromJson(Map<String, dynamic> json) {
    return Relationship(
      id: json['id'] as String,
      userId1: json['userId1'] as String,
      userId2: json['userId2'] as String,
      userName1: json['userName1'] as String,
      userName2: json['userName2'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      relationshipLevel: json['relationshipLevel'] as int? ?? 1,
    );
  }
}

class FriendRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final DateTime createdAt;
  final String status; // 'pending', 'accepted', 'rejected'

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String,
      toUserId: json['toUserId'] as String,
      toUserName: json['toUserName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }
}
