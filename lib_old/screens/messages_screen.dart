import 'package:flutter/material.dart';
import 'chat_screen.dart';

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
    final chats = List.generate(12, (i) => ('مستخدم ${i + 1}', 'آخر رسالة في الدردشة رقم ${i + 1}'));
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('الرسائل', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Image.asset('assets/Asad/icon_search.png', width: 24, height: 24, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.search, color: theme.colorScheme.onSurface)),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Category Buttons Section
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
                      badgeCount: 5,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCategoryButton(
                      context,
                      icon: Icons.notifications_active,
                      label: 'إشعارات النظام',
                      badgeCount: 3,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCategoryButton(
                      context,
                      icon: Icons.group,
                      label: 'Soulfree Team',
                      badgeCount: 2,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCategoryButton(
                      context,
                      icon: Icons.star,
                      label: 'المفضلة',
                      badgeCount: 0,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Chat History Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'المحادثات الأخيرة',
                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Container(
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
                  title: Text(chats[i].$1, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                  subtitle: Text(chats[i].$2, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                  trailing: Text('9:24', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 11)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          userName: chats[i].$1,
                          chatId: 'chat_${DateTime.now().millisecondsSinceEpoch}',
                        ),
                      ),
                    );
                  },
                ),
              ),
              childCount: chats.length,
            ),
          ),
        ],
      ),
    );
  }
}
