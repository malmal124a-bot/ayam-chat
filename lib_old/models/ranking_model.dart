class RankingModel {
  final String userName;
  final String avatarUrl;
  int giftScore;
  final DateTime timestamp;

  RankingModel({
    required this.userName,
    this.avatarUrl = 'assets/Asad/bg_vip_content.png',
    required this.giftScore,
    required this.timestamp,
  });
}
