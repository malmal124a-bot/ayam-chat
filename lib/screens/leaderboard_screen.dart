import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/leaderboard_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
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
          title: Text(
            'متصدري الغرفة',
            style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
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
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.nearBlackPurple,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
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
              Tab(text: 'المستخدمين'),
              Tab(text: 'الغرف'),
              Tab(text: 'الوكالات'),
            ],
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/Asad/bg_ranking.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppTheme.nearBlackPurple, Color(0xFF121222)],
                    ),
                  ),
                ),
              ),
            ),
            Consumer<LeaderboardController>(
              builder: (context, controller, child) {
                return TabBarView(
                  children: [
                    // Tab 1: User rankings (Top 10)
                    _LeaderboardContent(rankings: controller.globalUserRankings),
                    // Tab 2: Room rankings (Top 30)
                    _RoomRankingContent(rankings: controller.getGlobalRoomRankings()),
                    // Tab 3: Agency rankings (Top 10)
                    _AgencyRankingContent(rankings: controller.getGlobalAgencyRankings()),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon('Icons.emoji_events_outlined', icon: Icons.emoji_events_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('لا يوجد بيانات حالياً', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );
    }

    final topThree = rankings.take(3).toList();
    final remaining = rankings.skip(3).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          _Podium(topThree: topThree),
          const SizedBox(height: 20),
          ...remaining.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _LeaderboardItem(item: item, rank: index + 4);
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _RoomRankingContent extends StatelessWidget {
  final List<RankingModel> rankings;
  const _RoomRankingContent({required this.rankings});

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon('Icons.meeting_room_outlined', icon: Icons.meeting_room_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('لا يوجد غرف حالياً', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );
    }

    final topThree = rankings.take(3).toList();
    final remaining = rankings.skip(3).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          _Podium(topThree: topThree, isRoom: true),
          const SizedBox(height: 20),
          ...remaining.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _LeaderboardItem(item: item, rank: index + 4, isRoom: true);
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _AgencyRankingContent extends StatelessWidget {
  final List<RankingModel> rankings;
  const _AgencyRankingContent({required this.rankings});

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon('Icons.business_outlined', icon: Icons.business_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('لا يوجد وكالات حالياً', style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );
    }

    final topThree = rankings.take(3).toList();
    final remaining = rankings.skip(3).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          _Podium(topThree: topThree, isAgency: true),
          const SizedBox(height: 20),
          ...remaining.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _LeaderboardItem(item: item, rank: index + 4, isAgency: true);
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<RankingModel> topThree;
  final bool isRoom;
  final bool isAgency;
  const _Podium({required this.topThree, this.isRoom = false, this.isAgency = false});

  @override
  Widget build(BuildContext context) {
    final first = topThree.isNotEmpty ? topThree[0] : null;
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return SizedBox(
      height: 280,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null) _PodiumBadge(user: second, rank: 2, isMain: false, isRoom: isRoom, isAgency: isAgency),
          const SizedBox(width: 12),
          if (first != null) _PodiumBadge(user: first, rank: 1, isMain: true, isRoom: isRoom, isAgency: isAgency),
          const SizedBox(width: 12),
          if (third != null) _PodiumBadge(user: third, rank: 3, isMain: false, isRoom: isRoom, isAgency: isAgency),
        ],
      ),
    );
  }
}

class _PodiumBadge extends StatelessWidget {
  final RankingModel user;
  final int rank;
  final bool isMain;
  final bool isRoom;
  final bool isAgency;
  const _PodiumBadge({required this.user, required this.rank, required this.isMain, this.isRoom = false, this.isAgency = false});

  @override
  Widget build(BuildContext context) {
    final badgeColor = rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey : const Color(0xFFCD7F32));
    final badgeSize = isMain ? 100.0 : 80.0;
    final avatarSize = isMain ? 40.0 : 32.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: badgeColor, width: 4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [badgeColor.withValues(alpha: 0.3), badgeColor.withValues(alpha: 0.1)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMain ? 8.0 : 6.0),
            child: CircleAvatar(
              radius: avatarSize,
              backgroundImage: _getSafeImageProvider(user.avatarUrl),
              backgroundColor: Colors.grey,
              child: isRoom
                  ? AppIcon('Icons.meeting_room', icon: Icons.meeting_room, size: avatarSize, color: Colors.white)
                  : isAgency
                      ? AppIcon('Icons.business', icon: Icons.business, size: avatarSize, color: Colors.white)
                      : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
          child: Text(
            'TOP $rank',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: isMain ? 14 : 12),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.userName,
          style: TextStyle(color: Colors.white, fontWeight: isMain ? FontWeight.bold : FontWeight.normal, fontSize: isMain ? 14 : 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${user.giftScore}',
          style: TextStyle(color: AppTheme.royalGold, fontSize: isMain ? 14 : 12, fontWeight: FontWeight.bold),
        ),
        if (isRoom || isAgency)
          Text(
            isRoom ? 'ماسة في الغرفة' : 'ماسة في الوكالة',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
          ),
      ],
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final RankingModel item;
  final int rank;
  final bool isRoom;
  final bool isAgency;
  const _LeaderboardItem({required this.item, required this.rank, this.isRoom = false, this.isAgency = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [const Color(0xFF2A1B0E).withValues(alpha: 0.8), const Color(0xFF4A2C1A).withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB703).withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.royalGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('$rank', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 22,
            backgroundImage: _getSafeImageProvider(item.avatarUrl),
            backgroundColor: Colors.grey,
            child: isRoom
                ? const AppIcon('Icons.meeting_room', icon: Icons.meeting_room, size: 22, color: Colors.white)
                : isAgency
                    ? const AppIcon('Icons.business', icon: Icons.business, size: 22, color: Colors.white)
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.userName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.giftScore}',
                style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'ماسة',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
  return AssetImage(path);
}