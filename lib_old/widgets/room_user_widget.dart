import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';

class RoomUserWidget extends StatelessWidget {
  const RoomUserWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<UserController>(
      builder: (context, user, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildProfileImage(user.profilePic),
                ),
                InkWell(
                  onTap: () => _showLevelInfo(context, user),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor.withValues(alpha: 0.54),
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.24), width: 1),
                    ),
                    child: Image.asset(
                      user.getLevelIconPath(),
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(Icons.star, size: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user.currentBadgeIcon.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _buildSafeIcon(user.currentBadgeIcon, 16),
                  ),
                Flexible(
                  child: Text(
                    user.name,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'ID: ${user.displayId}',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileImage(String path) {
    const String fallback = 'assets/Asad/room.jpg';
    if (path.isEmpty) return Image.asset(fallback, fit: BoxFit.cover);

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(fallback, fit: BoxFit.cover),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(fallback, fit: BoxFit.cover),
    );
  }

  Widget _buildSafeIcon(String path, double size) {
    if (path.isEmpty) return const SizedBox.shrink();
    if (path.startsWith('http')) {
      return Image.network(path, width: size, height: size, errorBuilder: (c, e, s) => const SizedBox.shrink());
    }
    return Image.asset(path, width: size, height: size, errorBuilder: (c, e, s) => const SizedBox.shrink());
  }

  void _showLevelInfo(BuildContext context, UserController user) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            _buildSafeIcon(user.getLevelIconPath(), 24),
            const SizedBox(width: 10),
            Text(
              'المستوى ${user.currentLevel}',
              style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('XP: ${user.currentXP.toInt()} / ${user.xpForNextLevel}',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: user.levelProgress,
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                color: theme.colorScheme.secondary,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'الوسام الحالي: ${user.currentBadge}',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: TextStyle(color: theme.colorScheme.secondary)),
          ),
        ],
      ),
    );
  }
}
