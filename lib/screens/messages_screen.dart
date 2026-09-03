import 'package:flutter/material.dart';
import '../controllers/dm_controller.dart';
import '../widgets/app_icon.dart';
import 'dm_chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  Widget _buildCategoryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: theme.colorScheme.secondary, size: 28),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.cardColor, width: 2),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dm = DmController();
    dm.init();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('الرسائل', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Image.asset('assets/Asad/icon_search.png', width: 24, height: 24, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => AppIcon('Icons.search', icon: Icons.search, color: theme.colorScheme.onSurface)),
            onPressed: () {},
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: dm,
        builder: (context, child) {
          final conversations = dm.conversations;
          final unreadTotal = conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCategoryButton(
                          context,
                          icon: Icons.business_center,
                          label: 'إشعارات الوكالة',
                          badgeCount: 0,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryButton(
                          context,
                          icon: Icons.notifications_active,
                          label: 'إشعارات النظام',
                          badgeCount: 0,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCategoryButton(
                          context,
                          icon: Icons.group,
                          label: 'المحادثات الخاصة',
                          badgeCount: unreadTotal,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'المحادثات الأخيرة',
                    style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              if (conversations.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        AppIcon('Icons.chat_bubble_outline', icon: Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد محادثات بعد',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final c = conversations[i];
                      final time = c.lastTime;
                      final timeLabel = time != null
                          ? '${time.hour}:${time.minute.toString().padLeft(2, '0')}'
                          : '';
                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.12)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: theme.colorScheme.surface,
                            backgroundImage: const AssetImage('assets/Asad/bg_vip_content.png'),
                          ),
                          title: Text(c.otherName, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                          subtitle: Text(c.lastText, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(timeLabel, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 11)),
                              if (c.unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: Text(c.unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          onTap: () {
                            dm.markRead(c.otherUserId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DmChatScreen(
                                  otherUserId: c.otherUserId,
                                  otherName: c.otherName,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    childCount: conversations.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
