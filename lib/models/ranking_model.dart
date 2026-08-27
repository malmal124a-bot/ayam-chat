class RankingModel {
  final String userName;
  final String avatarUrl;
  int giftScore;
  final DateTime timestamp;
  // Room ranking fields
  final String? roomId;
  final String? roomPhoto;
  // Agency ranking fields
  final String? agencyName;
  final String? agencyPhoto;

  RankingModel({
    required this.userName,
    this.avatarUrl = 'assets/Asad/bg_vip_content.png',
    required this.giftScore,
    required this.timestamp,
    this.roomId,
    this.roomPhoto,
    this.agencyName,
    this.agencyPhoto,
  });
}
