import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/leaderboard_controller.dart';
import '../../theme/app_theme.dart';
import '../../models/ranking_model.dart';

class RoomLeaderboardSheet extends StatelessWidget {
  final String roomId;

  const RoomLeaderboardSheet({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              indicatorColor: AppTheme.royalGold,
              labelColor: AppTheme.royalGold,
              unselectedLabelColor: Colors.white54,
              indicator: BoxDecoration(
                color: AppTheme.royalGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              tabs: const [
                Tab(text: 'يومي'),
                Tab(text: 'أسبوعي'),
                Tab(text: 'شهري'),
              ],
            ),
            Expanded(
              child: Consumer<LeaderboardController>(
                builder: (context, controller, child) {
                  return TabBarView(
                    children: [
                      _LeaderboardList(rankings: controller.getRoomUserRankings(roomId, period: 'daily')),
                      _LeaderboardList(rankings: controller.getRoomUserRankings(roomId, period: 'weekly')),
                      _LeaderboardList(rankings: controller.getRoomUserRankings(roomId, period: 'monthly')),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<RankingModel> rankings;
  const _LeaderboardList({required this.rankings});

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) {
      return const Center(child: Text('لا يوجد بيانات حالياً', style: TextStyle(color: Colors.white54)));
    }

    final topThree = rankings.take(3).toList();
    final remaining = rankings.skip(3).take(17).toList();

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
    // Reorder for Podium: 🥈 🥇 🥉 (2, 1, 3)
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
              backgroundImage: _getSafeProvider(user.avatarUrl),
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
            backgroundImage: _getSafeProvider(user.avatarUrl),
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

// Helper for safe image loading
ImageProvider _getSafeProvider(String? path) {
  const String fallback = 'assets/Asad/room.jpg';
  if (path == null || path.isEmpty) {
    return const AssetImage(fallback);
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  if (path.startsWith('assets/')) {
    return AssetImage(path);
  }
  return const AssetImage(fallback);
}
