import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction_model.dart' as tx;

enum AgencyType { modife, charging }

class AgencyMember {
  final String userId;
  final String name;
  final String joinDate;
  double earnings;
  bool isOnline;

  AgencyMember({
    required this.userId,
    required this.name,
    required this.joinDate,
    this.earnings = 0.0,
    this.isOnline = false,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'joinDate': joinDate,
    'earnings': earnings,
    'isOnline': isOnline,
  };

  factory AgencyMember.fromJson(Map<String, dynamic> json) => AgencyMember(
    userId: json['userId'] ?? '',
    name: json['name'] ?? '',
    joinDate: json['joinDate'] ?? '',
    earnings: (json['earnings'] as num?)?.toDouble() ?? 0.0,
    isOnline: json['isOnline'] ?? false,
  );

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'name': name,
    'joinDate': joinDate,
    'earnings': earnings,
    'isOnline': isOnline,
  };

  factory AgencyMember.fromFirestore(Map<String, dynamic> data) => AgencyMember(
    userId: data['userId'] ?? '',
    name: data['name'] ?? '',
    joinDate: data['joinDate'] ?? '',
    earnings: (data['earnings'] as num?)?.toDouble() ?? 0.0,
    isOnline: data['isOnline'] as bool? ?? false,
  );
}

class AgencyInvitation {
  final String agencyId;
  final String agencyName;
  final String inviterId;
  final String modifeId; 
  final DateTime timestamp;
  bool isAccepted;

  AgencyInvitation({
    required this.agencyId,
    required this.agencyName,
    required this.inviterId,
    required this.modifeId,
    required this.timestamp,
    this.isAccepted = false,
  });

  Map<String, dynamic> toJson() => {
    'agencyId': agencyId,
    'agencyName': agencyName,
    'inviterId': inviterId,
    'modifeId': modifeId,
    'timestamp': timestamp.toIso8601String(),
    'isAccepted': isAccepted,
  };

  factory AgencyInvitation.fromJson(Map<String, dynamic> json) => AgencyInvitation(
    agencyId: json['agencyId'] ?? '',
    agencyName: json['agencyName'] ?? '',
    inviterId: json['inviterId'] ?? '',
    modifeId: json['modifeId'] ?? json['hostId'] ?? '', 
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    isAccepted: json['isAccepted'] ?? false,
  );

  Map<String, dynamic> toFirestore() => {
    'agencyId': agencyId,
    'agencyName': agencyName,
    'inviterId': inviterId,
    'modifeId': modifeId,
    'timestamp': Timestamp.fromDate(timestamp),
    'isAccepted': isAccepted,
  };

  factory AgencyInvitation.fromFirestore(Map<String, dynamic> data) => AgencyInvitation(
    agencyId: data['agencyId'] ?? '',
    agencyName: data['agencyName'] ?? '',
    inviterId: data['inviterId'] ?? '',
    modifeId: data['modifeId'] ?? data['hostId'] ?? '', 
    timestamp: data['timestamp'] is Timestamp ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
    isAccepted: data['isAccepted'] as bool? ?? false,
  );
}

class AgencyJoinRequest {
  final String userId;
  final String userName;
  final String agencyId;
  final DateTime timestamp;

  AgencyJoinRequest({
    required this.userId,
    required this.userName,
    required this.agencyId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'agencyId': agencyId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AgencyJoinRequest.fromJson(Map<String, dynamic> json) => AgencyJoinRequest(
    userId: json['userId'] ?? '',
    userName: json['userName'] ?? '',
    agencyId: json['agencyId'] ?? '',
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
  );

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'userName': userName,
    'agencyId': agencyId,
    'timestamp': Timestamp.fromDate(timestamp),
  };

  factory AgencyJoinRequest.fromFirestore(Map<String, dynamic> data) => AgencyJoinRequest(
    userId: data['userId'] ?? '',
    userName: data['userName'] ?? '',
    agencyId: data['agencyId'] ?? '',
    timestamp: data['timestamp'] is Timestamp ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
  );
}

class Agency {
  final String id;
  final String name;
  final String ownerId;
  final String description;
  final AgencyType agencyType;
  List<AgencyMember> members;
  double totalEarnings;
  final double rating;
  final String? personalName;
  final String? nationalId;
  List<String> paymentMethods;
  Map<String, int> chargingPackages;
  List<tx.Transaction> chargingLogs;
  bool isActivated;

  Agency({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.description,
    required this.agencyType,
    List<AgencyMember>? members,
    this.totalEarnings = 0.0,
    this.rating = 5.0,
    this.personalName,
    this.nationalId,
    List<String>? paymentMethods,
    Map<String, int>? chargingPackages,
    List<tx.Transaction>? chargingLogs,
    this.isActivated = false,
  }) : members = members ?? [],
       paymentMethods = paymentMethods ?? [],
       chargingPackages = chargingPackages ?? {
         '500': 500,
         '1000': 1000,
         '2000': 2000,
         '5000': 5000,
       },
       chargingLogs = chargingLogs ?? [];

  // Compatibility getter for screens using .type
  AgencyType get type => agencyType;

  int get memberCount => members.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ownerId': ownerId,
    'description': description,
    'agencyType': agencyType.name,
    'members': members.map((m) => m.toJson()).toList(),
    'totalEarnings': totalEarnings,
    'rating': rating,
    'personalName': personalName,
    'nationalId': nationalId,
    'paymentMethods': paymentMethods,
    'chargingPackages': chargingPackages,
    'chargingLogs': chargingLogs.map((t) => t.toJson()).toList(),
    'isActivated': isActivated,
  };

  factory Agency.fromJson(Map<String, dynamic> json) => Agency(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    ownerId: json['ownerId'] ?? '',
    description: json['description'] ?? '',
    agencyType: AgencyType.values.firstWhere(
      (e) => e.name == (json['agencyType'] ?? json['type'] ?? ''),
      orElse: () => AgencyType.modife,
    ),
    members: (json['members'] as List?)?.map((m) => AgencyMember.fromJson(m)).toList() ?? [],
    totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
    rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
    personalName: json['personalName'],
    nationalId: json['nationalId'],
    paymentMethods: (json['paymentMethods'] as List?)?.cast<String>() ?? [],
    chargingPackages: (json['chargingPackages'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, value as int),
    ) ?? {
      '500': 500,
      '1000': 1000,
      '2000': 2000,
      '5000': 5000,
    },
    chargingLogs: (json['chargingLogs'] as List?)?.map((t) => tx.Transaction.fromJson(t)).toList() ?? [],
    isActivated: json['isActivated'] ?? false,
  );

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'ownerId': ownerId,
    'description': description,
    'agencyType': agencyType.name,
    'members': members.map((m) => m.toFirestore()).toList(),
    'totalEarnings': totalEarnings,
    'rating': rating,
    'personalName': personalName,
    'nationalId': nationalId,
    'paymentMethods': paymentMethods,
    'chargingPackages': chargingPackages,
    'chargingLogs': chargingLogs.map((t) => t.toFirestore()).toList(),
    'isActivated': isActivated,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory Agency.fromFirestore(String id, Map<String, dynamic> data) => Agency(
    id: id,
    name: data['name'] ?? '',
    ownerId: data['ownerId'] ?? '',
    description: data['description'] ?? '',
    agencyType: AgencyType.values.firstWhere(
      (e) => e.name == (data['agencyType'] ?? data['type'] ?? ''),
      orElse: () => AgencyType.modife,
    ),
    members: (data['members'] as List?)?.map((m) => AgencyMember.fromFirestore(m)).toList() ?? [],
    totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
    rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
    personalName: data['personalName'],
    nationalId: data['nationalId'],
    paymentMethods: (data['paymentMethods'] as List?)?.cast<String>() ?? [],
    chargingPackages: (data['chargingPackages'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, value as int),
    ) ?? {
      '500': 500,
      '1000': 1000,
      '2000': 2000,
      '5000': 5000,
    },
    chargingLogs: (data['chargingLogs'] as List?)?.map((t) => tx.Transaction.fromFirestore(t)).toList() ?? [],
    isActivated: data['isActivated'] as bool? ?? false,
  );
}
