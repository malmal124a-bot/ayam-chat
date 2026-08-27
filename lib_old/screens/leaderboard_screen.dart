import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/leaderboard_controller.dart';
import '../theme/app_theme.dart';
import '../models/ranking_model.dart';

class LeaderboardScreen extends StatelessWidget {
  final String? roomId;

  const LeaderboardScreen({super.key, this.roomId});

  @override
  Widget build(BuildContext context) {
    final bool isRoomLeaderboard = roomId != null;

    if (isRoomLeaderboard) {
      return Scaffold(
        backgroundColor: AppTheme.nearBlackPurple,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'متصدري الغرفة',
            style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.nearBlackPurple, Color(0xFF121222)],
            ),
          ),
          child: Consumer<LeaderboardController>(
            builder: (context, controller, child) {
              final rankings = controller.getRoomUserRankings(roomId!);
              return _LeaderboardContent(rankings: rankings);
            },
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.nearBlackPurple,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'قائمة المتصدرين',
            style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: AppTheme.royalGold,
            labelColor: AppTheme.royalGold,
            unselectedLabelColor: Colors.white54,
            indicator: BoxDecoration(
              color: AppTheme.royalGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            tabs: const [
              Tab(text: 'Family Rank'),
              Tab(text: 'Room Rank'),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Background Asset
            Positioned.fill(
              child: Image.asset(
                'assets/Asad/bg_ranking.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppTheme.nearBlackPurple, Color(0xFF121222)],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Consumer<LeaderboardController>(
              builder: (context, controller, child) {
                return TabBarView(
                  children: [
                    _LeaderboardContent(rankings: controller.dailyRankings),
                    _LeaderboardContent(rankings: controller.weeklyRankings),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardContent extends StatelessWidget {
  final List<RankingModel> rankings;
  const _LeaderboardContent({required this.rankings});

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) {
      return const Center(child: Text('لا يوجد بيانات حالياً', style: TextStyle(color: Colors.white54)));
    }

    final topThree = rankings.take(3).toList();
    final remaining = rankings.skip(3).take(17).toList(); // Up to rank 20 total

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          _Podium(topThree: topThree),
          const SizedBox(height: 20),
          // Remaining Rankings List
          ...remaining.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            return _LeaderboardItem(user: user, rank: index + 4);
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<RankingModel> topThree;
  const _Podium({required this.topThree});

  @override
  Widget build(BuildContext context) {
    // topThree: [1st, 2nd, 3rd]
    // Layout: 2nd (Left), 1st (Center), 3rd (Right)
    final first = topThree.isNotEmpty ? topThree[0] : null;
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return SizedBox(
      height: 280,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null) _PodiumBadge(user: second, rank: 2, isMain: false),
          const SizedBox(width: 12),
          if (first != null) _PodiumBadge(user: first, rank: 1, isMain: true),
          const SizedBox(width: 12),
          if (third != null) _PodiumBadge(user: third, rank: 3, isMain: false),
        ],
      ),
    );
  }
}

class _PodiumBadge extends StatelessWidget {
  final RankingModel user;
  final int rank;
  final bool isMain;

  const _PodiumBadge({
    required this.user,
    required this.rank,
    required this.isMain,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey : const Color(0xFFCD7F32)); // Bronze
    final badgeSize = isMain ? 100.0 : 80.0;
    final avatarSize = isMain ? 40.0 : 32.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Badge Frame
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: badgeColor, width: 4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                badgeColor.withValues(alpha: 0.3),
                badgeColor.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMain ? 8.0 : 6.0),
            child: CircleAvatar(
              radius: avatarSize,
              backgroundImage: _getSafeImageProvider(user.avatarUrl),
              backgroundColor: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Rank Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'TOP $rank',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: isMain ? 14 : 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.userName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
            fontSize: isMain ? 14 : 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${user.giftScore}',
          style: TextStyle(
            color: AppTheme.royalGold,
            fontSize: isMain ? 14 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final RankingModel user;
  final int rank;
  const _LeaderboardItem({required this.user, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF2A1B0E).withValues(alpha: 0.8),
            const Color(0xFF4A2C1A).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB703).withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          // Rank Number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.royalGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: AppTheme.royalGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundImage: _getSafeImageProvider(user.avatarUrl),
            backgroundColor: Colors.grey,
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.giftScore}',
                style: const TextStyle(
                  color: AppTheme.royalGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'ماسة',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Global Safe Image Provider Helper
ImageProvider _getSafeImageProvider(String? path) {
  const String fallback = 'assets/Asad/bg_vip_content.png';
  if (path == null || path.isEmpty) {
    return const AssetImage(fallback);
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  if (path.startsWith('assets/')) {
    return AssetImage(path);
  }
  // Try treating it as a generic asset path if it doesn't match above but isn't a URL
  return AssetImage(path);
}
