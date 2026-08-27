import 'dart:math';

enum UserRole {
  user,
  admin,
  owner,
  regionalManager,
  appManager,
  superAdmin,
  agencyAdmin,
  bannerAdmin,
  moderator,
}

class UserModel {
  final String id; // Supabase Auth UID
  final String numericId; // 6-digit Profile ID
  final String name;
  final String profilePic;
  final String gender;
  final String country;
  final int level; 
  final int currentXP; 
  final int vipLevel;
  final int wealthLevel;
  final int magicLevel;
  final int nobleLevel;
  final int wealthXP;
  final int magicXP;
  final int nobleXP;
  final int globalScore; 
  final String? equippedFrameUrl; 
  final String? avatarUrl;
  final String? avatarType; 
  final UserRole role;
  final String? currentRoomId;

  UserModel({
    required this.id,
    required this.numericId,
    required this.name,
    required this.profilePic,
    required this.gender,
    this.country = '',
    required this.level,
    this.currentXP = 0,
    required this.vipLevel,
    this.wealthLevel = 1,
    this.magicLevel = 1,
    this.nobleLevel = 1,
    this.wealthXP = 0,
    this.magicXP = 0,
    this.nobleXP = 0,
    this.globalScore = 0,
    this.equippedFrameUrl,
    this.avatarUrl,
    this.avatarType,
    this.role = UserRole.user,
    this.currentRoomId,
  });

  static String generate6DigitId() {
    final random = Random();
    int min = 100000;
    int max = 999999;
    return (min + random.nextInt(max - min + 1)).toString();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'numeric_id': numericId,
    'name': name,
    'profilePic': profilePic,
    'gender': gender,
    'country': country,
    'level': level,
    'currentXP': currentXP,
    'vipLevel': vipLevel,
    'wealthLevel': wealthLevel,
    'magicLevel': magicLevel,
    'nobleLevel': nobleLevel,
    'wealthXP': wealthXP,
    'magicXP': magicXP,
    'nobleXP': nobleXP,
    'globalScore': globalScore,
    'equippedFrameUrl': equippedFrameUrl,
    'avatarUrl': avatarUrl,
    'avatarType': avatarType,
    'role': role.name,
    'currentRoomId': currentRoomId,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    numericId: json['numeric_id'] ?? json['userId'] ?? '',
    name: json['name'] ?? '',
    profilePic: json['profilePic'] ?? '',
    gender: json['gender'] ?? '',
    country: json['country'] ?? '',
    level: json['level'] ?? 0,
    currentXP: json['currentXP'] ?? 0,
    vipLevel: json['vipLevel'] ?? 0,
    wealthLevel: json['wealthLevel'] ?? 1,
    magicLevel: json['magicLevel'] ?? 1,
    nobleLevel: json['nobleLevel'] ?? 1,
    wealthXP: json['wealthXP'] ?? 0,
    magicXP: json['magicXP'] ?? 0,
    nobleXP: json['nobleXP'] ?? 0,
    globalScore: json['globalScore'] ?? 0,
    equippedFrameUrl: json['equippedFrameUrl'],
    avatarUrl: json['avatarUrl'],
    avatarType: json['avatarType'],
    role: UserRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => UserRole.user,
    ),
    currentRoomId: json['currentRoomId'],
  );

  factory UserModel.fromSupabase(Map<String, dynamic> json) => UserModel(
    id: json['auth_uid'] ?? json['id'] ?? '',
    numericId: json['numeric_id'] ?? json['userId'] ?? '',
    name: json['name'] ?? '',
    profilePic: json['photo_url'] ?? json['profilePic'] ?? '',
    gender: json['gender'] ?? '',
    country: json['country'] ?? '',
    level: (json['level'] ?? 0) as int,
    currentXP: (json['current_xp'] ?? 0) as int,
    vipLevel: (json['vip_level'] ?? 0) as int,
    wealthLevel: (json['wealth_level'] ?? 1) as int,
    magicLevel: (json['magic_level'] ?? 1) as int,
    nobleLevel: (json['noble_level'] ?? 1) as int,
    wealthXP: (json['wealth_xp'] ?? 0) as int,
    magicXP: (json['magic_xp'] ?? 0) as int,
    nobleXP: (json['noble_xp'] ?? 0) as int,
    globalScore: (json['global_score'] ?? 0) as int,
    equippedFrameUrl: json['equipped_frame_url'],
    avatarUrl: json['avatar_url'],
    avatarType: json['avatar_type'],
    role: UserRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => UserRole.user,
    ),
    currentRoomId: json['current_room_id'],
  );
}