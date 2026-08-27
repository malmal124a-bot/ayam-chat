import 'package:cloud_firestore/cloud_firestore.dart';

class MicSeat {
  final int index;
  final String? userName;
  final String? userId;
  final String? userProfilePic;
  final String? avatarFrame; // Added for Task 4
  final int userLevel;
  final int contributionScore;
  final bool isVip;
  final bool isSvip; // SVIP status for premium badge display
  final bool isLocked;
  final bool isMuted;
  final bool isSpeaking;
  final bool hasRequest;
  final bool isOwner;
  final String userRole;
  final List<String>? badges; // User badges for profile display

  const MicSeat({
    required this.index,
    this.userName,
    this.userId,
    this.userProfilePic,
    this.avatarFrame,
    this.userLevel = 1,
    this.contributionScore = 0,
    this.isVip = false,
    this.isSvip = false,
    this.isLocked = false,
    this.isMuted = false,
    this.isSpeaking = false,
    this.hasRequest = false,
    this.isOwner = false,
    this.userRole = 'guest',
    this.badges,
  });

  MicSeat copyWith({
    String? userName,
    String? userId,
    String? userProfilePic,
    String? avatarFrame,
    int? userLevel,
    int? contributionScore,
    bool? isVip,
    bool? isSvip,
    bool? isLocked,
    bool? isMuted,
    bool? isSpeaking,
    bool? hasRequest,
    bool? isOwner,
    String? userRole,
    List<String>? badges,
  }) {
    return MicSeat(
      index: index,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      userProfilePic: userProfilePic ?? this.userProfilePic,
      avatarFrame: avatarFrame ?? this.avatarFrame,
      userLevel: userLevel ?? this.userLevel,
      contributionScore: contributionScore ?? this.contributionScore,
      isVip: isVip ?? this.isVip,
      isSvip: isSvip ?? this.isSvip,
      isLocked: isLocked ?? this.isLocked,
      isMuted: isMuted ?? this.isMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      hasRequest: hasRequest ?? this.hasRequest,
      isOwner: isOwner ?? this.isOwner,
      userRole: userRole ?? this.userRole,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'userName': userName,
    'userId': userId,
    'userProfilePic': userProfilePic,
    'avatarFrame': avatarFrame,
    'userLevel': userLevel,
    'contributionScore': contributionScore,
    'isVip': isVip,
    'isSvip': isSvip,
    'isLocked': isLocked,
    'isMuted': isMuted,
    'isSpeaking': isSpeaking,
    'hasRequest': hasRequest,
    'isOwner': isOwner,
    'userRole': userRole,
    'badges': badges,
  };

  factory MicSeat.fromJson(Map<String, dynamic> json) => MicSeat(
    index: json['index'] ?? 0,
    userName: json['userName'],
    userId: json['userId'],
    userProfilePic: json['userProfilePic'],
    avatarFrame: json['avatarFrame'],
    userLevel: json['userLevel'] ?? 1,
    contributionScore: json['contributionScore'] ?? 0,
    isVip: json['isVip'] ?? false,
    isSvip: json['isSvip'] ?? false,
    isLocked: json['isLocked'] ?? false,
    isMuted: json['isMuted'] ?? false,
    isSpeaking: json['isSpeaking'] ?? false,
    hasRequest: json['hasRequest'] ?? false,
    isOwner: json['isOwner'] ?? false,
    userRole: json['userRole'] ?? 'guest',
    badges: (json['badges'] as List?)?.cast<String>(),
  );

  Map<String, dynamic> toFirestore() => {
    'index': index,
    'userName': userName,
    'userId': userId,
    'userProfilePic': userProfilePic,
    'avatarFrame': avatarFrame,
    'userLevel': userLevel,
    'contributionScore': contributionScore,
    'isVip': isVip,
    'isSvip': isSvip,
    'isLocked': isLocked,
    'isMuted': isMuted,
    'isSpeaking': isSpeaking,
    'hasRequest': hasRequest,
    'isOwner': isOwner,
    'userRole': userRole,
    'badges': badges,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory MicSeat.fromFirestore(Map<String, dynamic> data) => MicSeat(
    index: (data['index'] as num?)?.toInt() ?? 0,
    userName: data['userName'],
    userId: data['userId'],
    userProfilePic: data['userProfilePic'],
    avatarFrame: data['avatarFrame'],
    userLevel: (data['userLevel'] as num?)?.toInt() ?? 1,
    contributionScore: (data['contributionScore'] as num?)?.toInt() ?? 0,
    isVip: data['isVip'] as bool? ?? false,
    isSvip: data['isSvip'] as bool? ?? false,
    isLocked: data['isLocked'] as bool? ?? false,
    isMuted: data['isMuted'] as bool? ?? false,
    isSpeaking: data['isSpeaking'] as bool? ?? false,
    hasRequest: data['hasRequest'] as bool? ?? false,
    isOwner: data['isOwner'] as bool? ?? false,
    userRole: data['userRole'] ?? 'guest',
    badges: (data['badges'] as List?)?.cast<String>(),
  );
}
