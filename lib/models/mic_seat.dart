class MicSeat {
  final int index;
  final String? userName;
  final String? userId; // This is the 6-digit numeric ID for display
  final String? uid;    // This is the unique Supabase Auth UID for Anti-Clone logic
  final String? userProfilePic;
  final String? avatarFrame; 
  final int userLevel;
  final int contributionScore;
  final bool isVip;
  final bool isSvip; 
  final bool isLocked;
  final bool isMuted;
  final bool isSpeaking;
  final bool hasRequest;
  final bool isOwner;
  final String userRole;
  final List<String>? badges; 

  const MicSeat({
    required this.index,
    this.userName,
    this.userId,
    this.uid,
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
    String? uid,
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
      uid: uid ?? this.uid,
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
    'uid': uid,
    'userProfilePic': userProfilePic,
    'avatarFrame': avatarFrame,
    'userLevel': userLevel,
    'isVip': isVip,
    'isSvip': isSvip,
    'isLocked': isLocked,
    'isMuted': isMuted,
    'isSpeaking': isSpeaking,
    'userRole': userRole,
  };
}
