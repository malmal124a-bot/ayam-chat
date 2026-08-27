import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  owner,              // Master Control - Full financial access
  regionalManager,    // Regional operations - No financial access
  appManager,         // App operations - No financial access
  superAdmin,         // Operational with timed access
  agencyAdmin,        // Agency management
  bannerAdmin,        // Banner/store management
  moderator,          // Moderation tools
  user,               // Regular user
}

extension UserRoleExtension on UserRole {
  bool get rechargeAgency => this == UserRole.owner || this == UserRole.regionalManager;
  bool get allModerators => this == UserRole.owner || this == UserRole.regionalManager || this == UserRole.superAdmin;
}

class UserModel {
  final String id;
  final String name;
  final String profilePic;
  final String gender;
  final int level; // Account Level (primary level)
  final int currentXP; // Current XP for account level
  final int vipLevel;
  final int svipLevel; // SVIP level (0-10)
  final int wealthLevel;
  final int magicLevel;
  final int nobleLevel;
  final int wealthXP;
  final int magicXP;
  final int nobleXP;
  final int globalScore; // Aggregated points globally
  final String? activeFrame;
  final String? avatarUrl;
  final String? avatarType; // 'static', 'gif', 'lottie'
  final int followersCount;
  final int visitorsCount;
  final int friendsCount;
  final int likesCount;
  final UserRole role;
  final List<String> permissions;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? currentRoomId;
  final String? currentRoomName;
  
  // Timed access fields
  final DateTime? adminAccessExpiresAt; // When admin role expires
  final String? customNumericId; // Custom ID like 7777, 1000
  final String? deviceId; // Hardware fingerprint for bans
  final String? ipAddress; // IP address for bans
  final bool isBanned;
  final String? banReason;
  final DateTime? banExpiresAt;
  final DateTime? svipExpiresAt; // SVIP expiration
  final Map<String, DateTime>? timedStoreItems; // itemId -> expiration
  final List<String>? badges; // User badges/medals
  final bool isRechargeAgency; // Recharge Agency status
  final bool isModeratorAgency; // Moderator Agency status

  UserModel({
    required this.id,
    required this.name,
    required this.profilePic,
    required this.gender,
    required this.level,
    this.currentXP = 0,
    required this.vipLevel,
    this.svipLevel = 0,
    this.wealthLevel = 1,
    this.magicLevel = 1,
    this.nobleLevel = 1,
    this.wealthXP = 0,
    this.magicXP = 0,
    this.nobleXP = 0,
    this.globalScore = 0,
    this.activeFrame,
    this.avatarUrl,
    this.avatarType,
    this.followersCount = 0,
    this.visitorsCount = 0,
    this.friendsCount = 0,
    this.likesCount = 0,
    this.role = UserRole.user,
    this.permissions = const [],
    this.isOnline = false,
    this.lastSeen,
    this.currentRoomId,
    this.currentRoomName,
    this.adminAccessExpiresAt,
    this.customNumericId,
    this.deviceId,
    this.ipAddress,
    this.isBanned = false,
    this.banReason,
    this.banExpiresAt,
    this.svipExpiresAt,
    this.timedStoreItems,
    this.badges,
    this.isRechargeAgency = false,
    this.isModeratorAgency = false,
  });

  /// Helper method that generates a random 8-digit string ID (10000000 to 99999999).
  static String generate8DigitId() {
    final random = Random();
    int min = 10000000;
    int max = 99999999;
    return (min + random.nextInt(max - min + 1)).toString();
  }

  factory UserModel.fromController(dynamic user, dynamic inventory) {
    return UserModel(
      id: user.id,
      name: user.name,
      profilePic: user.profilePic,
      gender: user.gender,
      level: user.currentLevel,
      currentXP: user.currentXP,
      vipLevel: user.vipLevel,
      wealthLevel: user.wealthLevel,
      magicLevel: user.magicLevel,
      nobleLevel: user.nobleLevel,
      wealthXP: user.wealthXP,
      magicXP: user.magicXP,
      nobleXP: user.nobleXP,
      globalScore: user.globalScore,
      activeFrame: inventory.activeFrameId,
      avatarUrl: user.avatarUrl,
      avatarType: user.avatarType,
      followersCount: user.followersCount,
      visitorsCount: user.visitorsCount,
      friendsCount: user.friendsCount,
      likesCount: user.likesCount,
      role: user.role ?? UserRole.user,
      permissions: user.permissions ?? [],
      isOnline: user.isOnline ?? false,
      lastSeen: user.lastSeen,
      currentRoomId: user.currentRoomId,
      currentRoomName: user.currentRoomName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'profilePic': profilePic,
    'gender': gender,
    'level': level,
    'currentXP': currentXP,
    'vipLevel': vipLevel,
    'svipLevel': svipLevel,
    'wealthLevel': wealthLevel,
    'magicLevel': magicLevel,
    'nobleLevel': nobleLevel,
    'wealthXP': wealthXP,
    'magicXP': magicXP,
    'nobleXP': nobleXP,
    'globalScore': globalScore,
    'activeFrame': activeFrame,
    'avatarUrl': avatarUrl,
    'avatarType': avatarType,
    'followersCount': followersCount,
    'visitorsCount': visitorsCount,
    'friendsCount': friendsCount,
    'likesCount': likesCount,
    'role': role.name,
    'permissions': permissions,
    'isOnline': isOnline,
    'lastSeen': lastSeen?.toIso8601String(),
    'currentRoomId': currentRoomId,
    'currentRoomName': currentRoomName,
    'adminAccessExpiresAt': adminAccessExpiresAt?.toIso8601String(),
    'customNumericId': customNumericId,
    'deviceId': deviceId,
    'ipAddress': ipAddress,
    'isBanned': isBanned,
    'banReason': banReason,
    'banExpiresAt': banExpiresAt?.toIso8601String(),
    'svipExpiresAt': svipExpiresAt?.toIso8601String(),
    'timedStoreItems': timedStoreItems?.map((k, v) => MapEntry(k, v.toIso8601String())),
    'badges': badges,
    'isRechargeAgency': isRechargeAgency,
    'isModeratorAgency': isModeratorAgency,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    profilePic: json['profilePic'] ?? '',
    gender: json['gender'] ?? '',
    level: json['level'] ?? 0,
    currentXP: json['currentXP'] ?? 0,
    vipLevel: json['vipLevel'] ?? 0,
    svipLevel: json['svipLevel'] ?? 0,
    wealthLevel: json['wealthLevel'] ?? 1,
    magicLevel: json['magicLevel'] ?? 1,
    nobleLevel: json['nobleLevel'] ?? 1,
    wealthXP: json['wealthXP'] ?? 0,
    magicXP: json['magicXP'] ?? 0,
    nobleXP: json['nobleXP'] ?? 0,
    globalScore: json['globalScore'] ?? 0,
    activeFrame: json['activeFrame'],
    avatarUrl: json['avatarUrl'],
    avatarType: json['avatarType'],
    followersCount: json['followersCount'] ?? 0,
    visitorsCount: json['visitorsCount'] ?? 0,
    friendsCount: json['friendsCount'] ?? 0,
    likesCount: json['likesCount'] ?? 0,
    role: UserRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => UserRole.user,
    ),
    permissions: (json['permissions'] as List?)?.cast<String>() ?? [],
    isOnline: json['isOnline'] ?? false,
    lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
    currentRoomId: json['currentRoomId'],
    currentRoomName: json['currentRoomName'],
    adminAccessExpiresAt: json['adminAccessExpiresAt'] != null 
        ? DateTime.parse(json['adminAccessExpiresAt']) 
        : null,
    customNumericId: json['customNumericId'],
    deviceId: json['deviceId'],
    ipAddress: json['ipAddress'],
    isBanned: json['isBanned'] ?? false,
    banReason: json['banReason'],
    banExpiresAt: json['banExpiresAt'] != null 
        ? DateTime.parse(json['banExpiresAt']) 
        : null,
    svipExpiresAt: json['svipExpiresAt'] != null 
        ? DateTime.parse(json['svipExpiresAt']) 
        : null,
    timedStoreItems: json['timedStoreItems'] != null
        ? (json['timedStoreItems'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, DateTime.parse(v)),
          )
        : null,
    badges: (json['badges'] as List?)?.cast<String>(),
    isRechargeAgency: json['isRechargeAgency'] ?? false,
    isModeratorAgency: json['isModeratorAgency'] ?? false,
  );

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'profilePic': profilePic,
    'gender': gender,
    'level': level,
    'currentXP': currentXP,
    'vipLevel': vipLevel,
    'svipLevel': svipLevel,
    'wealthLevel': wealthLevel,
    'magicLevel': magicLevel,
    'nobleLevel': nobleLevel,
    'wealthXP': wealthXP,
    'magicXP': magicXP,
    'nobleXP': nobleXP,
    'globalScore': globalScore,
    'activeFrame': activeFrame,
    'avatarUrl': avatarUrl,
    'avatarType': avatarType,
    'followersCount': followersCount,
    'visitorsCount': visitorsCount,
    'friendsCount': friendsCount,
    'likesCount': likesCount,
    'role': role.name,
    'permissions': permissions,
    'isOnline': isOnline,
    'lastSeen': lastSeen ?? FieldValue.serverTimestamp(),
    'currentRoomId': currentRoomId,
    'currentRoomName': currentRoomName,
    'adminAccessExpiresAt': adminAccessExpiresAt != null 
        ? Timestamp.fromDate(adminAccessExpiresAt!) 
        : null,
    'customNumericId': customNumericId,
    'deviceId': deviceId,
    'ipAddress': ipAddress,
    'isBanned': isBanned,
    'banReason': banReason,
    'banExpiresAt': banExpiresAt != null 
        ? Timestamp.fromDate(banExpiresAt!) 
        : null,
    'svipExpiresAt': svipExpiresAt != null 
        ? Timestamp.fromDate(svipExpiresAt!) 
        : null,
    'timedStoreItems': timedStoreItems?.map(
      (k, v) => MapEntry(k, Timestamp.fromDate(v)),
    ),
    'badges': badges,
    'isRechargeAgency': isRechargeAgency,
    'isModeratorAgency': isModeratorAgency,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      profilePic: data['profilePic'] ?? '',
      gender: data['gender'] ?? '',
      level: (data['level'] as num?)?.toInt() ?? 0,
      currentXP: (data['currentXP'] as num?)?.toInt() ?? 0,
      vipLevel: (data['vipLevel'] as num?)?.toInt() ?? 0,
      svipLevel: (data['svipLevel'] as num?)?.toInt() ?? 0,
      wealthLevel: (data['wealthLevel'] as num?)?.toInt() ?? 1,
      magicLevel: (data['magicLevel'] as num?)?.toInt() ?? 1,
      nobleLevel: (data['nobleLevel'] as num?)?.toInt() ?? 1,
      wealthXP: (data['wealthXP'] as num?)?.toInt() ?? 0,
      magicXP: (data['magicXP'] as num?)?.toInt() ?? 0,
      nobleXP: (data['nobleXP'] as num?)?.toInt() ?? 0,
      globalScore: (data['globalScore'] as num?)?.toInt() ?? 0,
      activeFrame: data['activeFrame'],
      avatarUrl: data['avatarUrl'],
      avatarType: data['avatarType'],
      followersCount: (data['followersCount'] as num?)?.toInt() ?? 0,
      visitorsCount: (data['visitorsCount'] as num?)?.toInt() ?? 0,
      friendsCount: (data['friendsCount'] as num?)?.toInt() ?? 0,
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.user,
      ),
      permissions: (data['permissions'] as List?)?.cast<String>() ?? [],
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: data['lastSeen'] is Timestamp 
          ? (data['lastSeen'] as Timestamp).toDate() 
          : null,
      currentRoomId: data['currentRoomId'],
      currentRoomName: data['currentRoomName'],
      adminAccessExpiresAt: data['adminAccessExpiresAt'] is Timestamp
          ? (data['adminAccessExpiresAt'] as Timestamp).toDate()
          : null,
      customNumericId: data['customNumericId'],
      deviceId: data['deviceId'],
      ipAddress: data['ipAddress'],
      isBanned: data['isBanned'] as bool? ?? false,
      banReason: data['banReason'],
      banExpiresAt: data['banExpiresAt'] is Timestamp
          ? (data['banExpiresAt'] as Timestamp).toDate()
          : null,
      svipExpiresAt: data['svipExpiresAt'] is Timestamp
          ? (data['svipExpiresAt'] as Timestamp).toDate()
          : null,
      timedStoreItems: data['timedStoreItems'] != null
          ? (data['timedStoreItems'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, (v as Timestamp).toDate()),
            )
          : null,
      badges: (data['badges'] as List?)?.cast<String>(),
      isRechargeAgency: data['isRechargeAgency'] as bool? ?? false,
      isModeratorAgency: data['isModeratorAgency'] as bool? ?? false,
    );
  }
}
