import 'package:flutter/material.dart';
import '../controllers/user_controller.dart';
import '../controllers/vip_controller.dart';
import '../controllers/wallet_controller.dart';

class VipLevelsScreen extends StatefulWidget {
  const VipLevelsScreen({super.key});

  @override
  State<VipLevelsScreen> createState() => _VipLevelsScreenState();
}

class _VipLevelsScreenState extends State<VipLevelsScreen> {
  final UserController userController = UserController();
  final VipController vipController = VipController();
  final WalletController walletController = WalletController();

  @override
  void initState() {
    super.initState();
    userController.addListener(_refresh);
    vipController.addListener(_refresh);
    walletController.addListener(_refresh);
  }

  @override
  void dispose() {
    userController.removeListener(_refresh);
    vipController.removeListener(_refresh);
    walletController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _handleUpgrade(int targetLevel) {
    final theme = Theme.of(context);
    if (!vipController.canUpgradeToLevel(targetLevel)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يمكنك فقط الترقية إلى المستوى التالي')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        shape: theme.dialogTheme.shape,
        title: Text('تأكيد الترقية', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الترقية من VIP ${userController.vipLevel} إلى VIP $targetLevel',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 12),
            Text(
              'التكلفة: ${vipController.getUpgradeCost(userController.vipLevel)} ماسة',
              style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'رصيدك الحالي: ${walletController.diamonds} ماسة',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.54))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              final result = vipController.buyVIPUpgrade();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result)),
              );
            },
            child: const Text('ترقية', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLevel = userController.vipLevel;
    final nextLevel = currentLevel < 10 ? currentLevel + 1 : 10;
    final upgradeCost = vipController.getUpgradeCost(currentLevel);
    final canUpgrade = vipController.canUpgradeToLevel(nextLevel);
    final hasEnoughDiamonds = vipController.hasEnoughDiamondsForUpgrade(nextLevel);
    
    final levels = [
      ('VIP 1', 'شارة أساسية + تمييز الاسم'),
      ('VIP 2', 'إطار خفيف + دخول مميز'),
      ('VIP 3', 'مايك مميز + فقاعة دردشة'),
      ('VIP 4', 'شعار دخول أفضل + ترتيب أعلى'),
      ('VIP 5', 'بطاقة عرض خاصة + حماية بسيطة'),
      ('VIP 6', 'قفل مايك فاخر + تمييز داخل الغرفة'),
      ('VIP 7', 'دخولية أقوى + إطار ذهبي'),
      ('VIP 8', 'هوية ملكية كاملة + مزايا حصرية'),
      ('VIP 9', 'أولوية دعم فني + هدايا شهرية'),
      ('VIP 10', 'لقب أسطوري + تحكم كامل بالإعدادات'),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'مستويات VIP', 
          style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Current User VIP Status Header with Progress
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.cardColor, theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [theme.colorScheme.secondary, theme.colorScheme.tertiary]),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: userController.profilePic.startsWith('assets/')
                            ? AssetImage(userController.profilePic) as ImageProvider
                            : null,
                        backgroundColor: theme.cardColor,
                        child: userController.profilePic.isEmpty ? Icon(Icons.person, color: theme.colorScheme.onSurface) : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userController.name,
                            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'رتبتك الحالية: ${userController.vipRank}',
                              style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (currentLevel < 10) ...[
                  const SizedBox(height: 20),
                  // Progress Bar to Next Level
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'التقدم إلى VIP $nextLevel',
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                          ),
                          Text(
                            '$currentLevel/10',
                            style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: currentLevel / 10,
                          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Upgrade Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (canUpgrade && hasEnoughDiamonds) ? () => _handleUpgrade(nextLevel) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (canUpgrade && hasEnoughDiamonds) ? theme.colorScheme.secondary : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                            foregroundColor: (canUpgrade && hasEnoughDiamonds) ? Colors.black : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                canUpgrade ? 'ترقية إلى VIP $nextLevel' : 'مغلق',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (canUpgrade) ...[
                                const SizedBox(height: 4),
                                Text(
                                  hasEnoughDiamonds ? '$upgradeCost ماسة' : 'رصيد غير كافٍ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: hasEnoughDiamonds ? Colors.black.withValues(alpha: 0.7) : theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified, color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'لقد وصلت إلى أعلى مستوى VIP!',
                          style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.secondary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'مزايا العضوية الملكية',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: levels.length,
              itemBuilder: (_, i) {
                final level = i + 1;
                bool isCurrent = level == currentLevel;
                bool isNext = level == nextLevel;
                bool isLocked = level > nextLevel;
                bool canUpgradeThis = vipController.canUpgradeToLevel(level);
                bool hasEnoughDiamondsThis = vipController.hasEnoughDiamondsForUpgrade(level);
                final cost = vipController.getUpgradeCost(level - 1);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isCurrent ? theme.colorScheme.secondary : theme.colorScheme.secondary.withValues(alpha: 0.1),
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isCurrent 
                                ? [theme.colorScheme.tertiary, theme.colorScheme.secondary]
                                : (isNext ? [theme.scaffoldBackgroundColor, theme.scaffoldBackgroundColor.withValues(alpha: 0.7)] : [theme.colorScheme.onSurface.withValues(alpha: 0.1), theme.colorScheme.onSurface.withValues(alpha: 0.05)]),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$level', 
                            style: TextStyle(color: isCurrent || isNext ? Colors.black : theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              levels[i].$1, 
                              style: TextStyle(
                                color: isCurrent ? theme.colorScheme.onSurface : (isNext ? theme.colorScheme.secondary : theme.colorScheme.onSurface.withValues(alpha: 0.7)), 
                                fontWeight: FontWeight.bold, 
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              levels[i].$2, 
                              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Icon(Icons.verified, color: theme.colorScheme.secondary)
                      else if (isNext && canUpgradeThis)
                        ElevatedButton(
                          onPressed: hasEnoughDiamondsThis ? () => _handleUpgrade(level) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasEnoughDiamondsThis ? theme.colorScheme.secondary : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                            foregroundColor: hasEnoughDiamondsThis ? Colors.black : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            '$cost ماسة',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        )
                      else if (isLocked)
                        Icon(Icons.lock_outline, color: theme.colorScheme.onSurface.withValues(alpha: 0.24))
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
