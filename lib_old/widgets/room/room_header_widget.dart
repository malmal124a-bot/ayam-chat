import 'package:flutter/material.dart';

class RoomHeaderWidget extends StatelessWidget {
  final String roomName;
  final String? roomId;
  final String? roomCover;
  final int onlineCount;
  final VoidCallback onExit;
  final VoidCallback onShare;
  final VoidCallback onTrophy;
  final VoidCallback? onInfoTap;
  final VoidCallback? onOnlineCountTap;

  const RoomHeaderWidget({
    super.key,
    required this.roomName,
    this.roomId,
    this.roomCover,
    required this.onlineCount,
    required this.onExit,
    required this.onShare,
    required this.onTrophy,
    this.onInfoTap,
    this.onOnlineCountTap,
  });

  ImageProvider _getSafeImageProvider(String? path) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // Top Left: Power and Share
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                      onTap: onExit,
                      child: const Icon(Icons.power_settings_new_rounded,
                          color: Colors.white, size: 26)),
                  const SizedBox(width: 16),
                  GestureDetector(
                      onTap: onShare,
                      child: const Icon(Icons.ios_share_rounded,
                          color: Colors.white, size: 22)),
                ],
              ),

              const Spacer(),

              // Top Center-Right: Room Details & Level (My Card)
              Flexible(
                child: GestureDetector(
                  onTap: onInfoTap,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // "My Card" / Level Badge - cleanly formatted
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.amber.withValues(alpha: 0.6),
                                        width: 0.8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Text('31.6K',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Cairo')),
                                      SizedBox(width: 3),
                                      Icon(Icons.workspace_premium,
                                          color: Colors.amber, size: 10),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Room Name with Flexible to prevent overflow
                                Flexible(
                                  child: Text(
                                    roomName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Cairo'),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'ID:${roomId ?? '1205838'}',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Avatar/Cover Image
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 1),
                          image: DecorationImage(
                            image: _getSafeImageProvider(roomCover),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Trophy positioned aligned to RIGHT side directly beneath header
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onTrophy,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4), width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('105880',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo')),
                    SizedBox(width: 6),
                    Icon(Icons.emoji_events_rounded,
                        color: Colors.amber, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Online Count Badge (Clickable)
              GestureDetector(
                onTap: onOnlineCountTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded,
                          color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 4),
                      Text('$onlineCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
