import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/user_controller.dart';
import '../controllers/relationship_controller.dart';
import '../widgets/broadcast_ticker.dart';
import '../widgets/friend_requests_notification.dart';
import '../widgets/app_icon.dart';

class CpScreen extends StatefulWidget {
  const CpScreen({super.key});

  @override
  State<CpScreen> createState() => _CpScreenState();
}

class _CpScreenState extends State<CpScreen> {
  final RelationshipController _relationshipController = RelationshipController();
  
  @override
  void initState() {
    super.initState();
    _relationshipController.setCurrentUser('user1', 'المستخدم الحالي');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('CP - الشراكة', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const BroadcastTicker(),
            const SizedBox(height: 16),
            const FriendRequestsNotification(),
            const SizedBox(height: 16),
            // CP Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.withValues(alpha: 0.3),
                    Colors.red.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.pink.withValues(alpha: 0.3), width: 1),
              ),
              child: Column(
                children: [
                  // Partner Avatars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPartnerAvatar(user.profilePic, user.name, isMain: true),
                      const SizedBox(width: 20),
                      Image.asset(
                        'assets/Asad/cp_entry.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const AppIcon('Icons.favorite', icon: Icons.favorite, color: Colors.pink, size: 40),
                      ),
                      const SizedBox(width: 20),
                      _buildPartnerAvatar(null, 'في انتظار الشريك', isMain: false),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // CP Level & Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'مستوى الشراكة',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.pink.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.pink, width: 1),
                        ),
                        child: const Text(
                          'المستوى 5',
                          style: TextStyle(color: Colors.pink, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.75,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Love Intimacy Points
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'نقاط الحب',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Row(
                        children: [
                          Image.asset(
                            'assets/Asad/vip_coin.png',
                            width: 16,
                            height: 16,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const AppIcon('Icons.favorite', icon: Icons.favorite, color: Colors.pink, size: 16),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '15,420',
                            style: TextStyle(color: Colors.pink, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // CP Ring/Badge Slots
            _buildSectionTitle('حلقات وخواتم الشراكة'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCpSlot('الحلقة الذهبية', 'assets/Asad/vip_coin.png', true),
                  _buildCpSlot('الحلقة الفضية', 'assets/Asad/vip_coin.png', false),
                  _buildCpSlot('الحلقة البرونزية', 'assets/Asad/vip_coin.png', false),
                  _buildCpSlot('الحلقة الماسية', 'assets/Asad/vip_coin.png', false),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // CP Wall/Anniversary
            _buildSectionTitle('جدار الحب والذكرى'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  _buildAnniversaryCard('ذكرى شراكتنا', '2024-02-14', 365),
                  const SizedBox(height: 12),
                  _buildAnniversaryCard('ذكرى الزواج', '2024-06-20', 180),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // CP Actions
            _buildSectionTitle('إجراءات الشراكة'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCpAction(
                    Icons.add_circle_outline,
                    'دعوة شريك',
                    Colors.pink,
                    _showInvitePartnerDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCpAction(
                    Icons.favorite_border,
                    'إنهاء الشراكة',
                    Colors.red,
                    _showEndPartnershipDialog,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerAvatar(String? image, String name, {required bool isMain}) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isMain ? Colors.pink : Colors.white24,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: image != null && image.isNotEmpty
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const AppIcon('Icons.person', icon: Icons.person, size: 30),
                  )
                : const AppIcon('Icons.person_add', icon: Icons.person_add, size: 30, color: Colors.white38),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            color: isMain ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCpSlot(String name, String iconPath, bool unlocked) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: unlocked ? Colors.pink.withValues(alpha: 0.2) : Colors.white12,
            shape: BoxShape.circle,
            border: Border.all(
              color: unlocked ? Colors.pink : Colors.white24,
              width: 1,
            ),
          ),
          child: Image.asset(
            iconPath,
            width: 30,
            height: 30,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const AppIcon('Icons.lock', icon: Icons.lock, size: 20, color: Colors.white38),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            color: unlocked ? Colors.white : Colors.white38,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnniversaryCard(String title, String date, int days) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const AppIcon('Icons.card_giftcard', icon: Icons.card_giftcard, color: Colors.pink, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'باقي $days يوم',
                  style: TextStyle(color: Colors.pink, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCpAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvitePartnerDialog() {
    final TextEditingController partnerIdController = TextEditingController();
    final TextEditingController partnerNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('دعوة شريك', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: partnerIdController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'ID الشريك',
                hintText: 'أدخل ID الشريك',
                labelStyle: TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: partnerNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'اسم الشريك',
                hintText: 'أدخل اسم الشريك',
                labelStyle: TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (partnerIdController.text.isEmpty || partnerNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى ملء جميع الحقول')),
                );
                return;
              }
              
              final success = await _relationshipController.sendFriendRequest(
                toUserId: partnerIdController.text,
                toUserName: partnerNameController.text,
              );
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'تم إرسال الدعوة بنجاح' : 'فشل إرسال الدعوة'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _showEndPartnershipDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('إنهاء الشراكة', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من إنهاء الشراكة؟', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إنهاء الشراكة'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
  }
}