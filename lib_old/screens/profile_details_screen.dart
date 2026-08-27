import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/store_controller.dart';
import '../controllers/gift_controller.dart';
import '../widgets/gift_sheet_widget.dart';

class ProfileDetailsScreen extends StatelessWidget {
  final String? userId;
  final String? userName;
  
  const ProfileDetailsScreen({
    super.key,
    this.userId,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserController>();
    final auth = context.watch<AuthController>();
    final inventory = context.watch<InventoryController>();
    final store = context.watch<StoreController>();
    
    final String displayName = userName ?? user.name;
    final String displayId = userId ?? user.id;
    final String displayPic = user.profilePic;
    final int vipLevel = user.vipLevel;
    final int svipLevel = auth.svipLevel;
    final bool isVip = vipLevel > 0;
    
    String? framePath;
    if (inventory.activeFrameId != null) {
      final items = store.items;
      final index = items.indexWhere((item) => item.id == inventory.activeFrameId);
      if (index != -1) framePath = items[index].imagePath;
    }
    
    Color vipColor = isVip 
        ? (AuthController.vipColors[vipLevel] ?? theme.colorScheme.secondary)
        : theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 260,
              decoration: const BoxDecoration(
                image: DecorationImage(image: AssetImage('assets/Asad/bg_header.png'), fit: BoxFit.cover),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.white)),
                  const SizedBox(height: 40),
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        _buildAvatar(displayPic, framePath, isVip, vipColor, theme),
                        const SizedBox(height: 14),
                        Text(displayName, style: TextStyle(color: isVip ? vipColor : theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 22)),
                        const SizedBox(height: 6),
                        Text('ID: $displayId', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14)),
                        const SizedBox(height: 12),
                        _buildBadges(context, user, vipLevel, svipLevel, vipColor, theme),
                        const SizedBox(height: 24),
                        _info(context, 'المستوى', '${user.currentLevel}'),
                        _info(context, 'الوسام', user.currentBadge),
                        _info(context, 'الماسات', user.diamonds.toString()),
                        const SizedBox(height: 24),
                        _buildActionButtons(context, user, displayId),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String pic, String? frame, bool isVip, Color vipColor, ThemeData theme) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: isVip ? vipColor : theme.colorScheme.secondary, width: 3),
            image: DecorationImage(
              image: pic.startsWith('http') ? NetworkImage(pic) as ImageProvider : AssetImage(pic),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (frame != null)
          Positioned(
            top: -18, left: -18, right: -18, bottom: -18,
            child: Image.asset(frame, fit: BoxFit.contain),
          ),
      ],
    );
  }

  Widget _buildBadges(BuildContext context, UserController user, int vip, int svip, Color vipColor, ThemeData theme) {
    return Wrap(
      spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
      children: [
        if (vip > 0) _badge('VIP $vip', vipColor, Icons.star_rounded),
        if (svip > 0) _badge('SVIP $svip', Colors.orange, Icons.workspace_premium),
        _badge('Lv.${user.currentLevel}', theme.colorScheme.tertiary, Icons.military_tech),
      ],
    );
  }

  Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _info(BuildContext context, String k, String v) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(v, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserController user, String targetId) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _actionBtn(context, Icons.message_rounded, 'رسالة', theme.colorScheme.secondary, () {})),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn(context, Icons.person_add_rounded, 'إضافة', Colors.blue, () {})),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _actionBtn(context, Icons.favorite_rounded, 'متابعة', Colors.pink, () {})),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn(context, Icons.card_giftcard_rounded, 'إرسال هدية', Colors.amber, () {
              showComprehensiveGiftSheet(context, GiftController(), (msg, target, combo) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إرسال $msg')));
              }, roomId: targetId, roomController: null);
            })),
          ],
        ),
        const SizedBox(height: 10),
        _actionBtn(context, Icons.mic_rounded, 'إدارة المايك في الروم', Colors.green, () {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال دعوة للمايك')));
        }, fullWidth: true),
      ],
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap, {bool fullWidth = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
