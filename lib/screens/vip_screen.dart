import 'package:flutter/material.dart';
import '../controllers/vip_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/wallet_controller.dart';

class VipScreen extends StatefulWidget {
  const VipScreen({super.key});

  @override
  State<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends State<VipScreen> with SingleTickerProviderStateMixin {
  final VipController vipController = VipController();
  final UserController userController = UserController();
  final WalletController walletController = WalletController();
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    vipController.addListener(_refresh);
    userController.addListener(_refresh);
    walletController.addListener(_refresh);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    vipController.removeListener(_refresh);
    userController.removeListener(_refresh);
    walletController.removeListener(_refresh);
    _glowController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _handleUpgrade() {
    final theme = Theme.of(context);
    final currentLevel = userController.vipLevel;
    final nextLevel = currentLevel + 1;
    final cost = vipController.getUpgradeCost(currentLevel);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        shape: theme.dialogTheme.shape,
        title: Text(
          'تأكيد ترقية الملكية',
          style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل تريد الترقية إلى VIP $nextLevel مقابل $cost ماسة؟',
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.54))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: theme.colorScheme.secondary.withValues(alpha: 0.5),
            ),
            onPressed: () {
              Navigator.pop(context);
              final result = vipController.buyVIPUpgrade();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: theme.cardColor,
                  content: Text(result, style: TextStyle(color: theme.colorScheme.secondary)),
                ),
              );
            },
            child: const Text('تأكيد', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLevel = userController.vipLevel;
    final nextLevel = currentLevel < 10 ? currentLevel + 1 : null;
    final upgradeCost = nextLevel != null ? vipController.getUpgradeCost(currentLevel) : 0;
    final hasEnough = walletController.diamonds >= upgradeCost;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surfaceContainerHighest,
              theme.colorScheme.secondary.withValues(alpha: 0.1),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.4, 0.8, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.05),
                ),
              ),
            ),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildHeader(context),
                        _buildHeroBadge(context, currentLevel),
                        const SizedBox(height: 24),
                        _buildUserInfo(context),
                        const SizedBox(height: 32),
                        _buildBenefitsSection(context),
                        const SizedBox(height: 140), 
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildStickyUpgradeButton(context, nextLevel, upgradeCost, hasEnough),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          Text(
            'VIP ROYALTY',
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              shadows: [Shadow(color: theme.scaffoldBackgroundColor, blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeroBadge(BuildContext context, int level) {
    final theme = Theme.of(context);
    bool isLevel10 = level >= 10;
    
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: 300,
          height: 300,
          margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.secondary.withValues(alpha: (isLevel10 ? 0.5 : 0.3) * _glowController.value),
                blurRadius: isLevel10 ? 60 : 50,
                spreadRadius: isLevel10 ? 8 : 5,
              ),
              BoxShadow(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.2 * (1 - _glowController.value)),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.secondary,
                      theme.colorScheme.tertiary,
                      theme.colorScheme.secondary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      offset: const Offset(6, 6),
                      blurRadius: 12,
                    ),
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      offset: const Offset(-4, -4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.scaffoldBackgroundColor,
                  border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.5), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: _buildVipAnimation(context, level),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'VIP $level',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: isLevel10 ? 44 : 38,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: theme.colorScheme.secondary, blurRadius: 12),
                          Shadow(color: theme.scaffoldBackgroundColor, offset: const Offset(0, 4), blurRadius: 4),
                          if (isLevel10) Shadow(color: theme.scaffoldBackgroundColor, blurRadius: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVipAnimation(BuildContext context, int level) {
    final theme = Theme.of(context);
    return Image.asset(
      'assets/vip/vip$level.png',
      width: 200,
      height: 200,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            border: Border.all(
              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.stars_rounded,
              size: 80,
              color: theme.colorScheme.secondary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          userController.name.toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.secondary.withValues(alpha: 0.2), Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, color: theme.colorScheme.secondary, size: 16),
              const SizedBox(width: 8),
              Text(
                'PREMIUM MEMBER',
                style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    final theme = Theme.of(context);
    final List<Map<String, dynamic>> benefits = [
      {'icon': Icons.stars_rounded, 'title': 'Badge'},
      {'icon': Icons.camera_rounded, 'title': 'Frame'},
      {'icon': Icons.bolt_rounded, 'title': 'Entrance'},
      {'icon': Icons.diamond_rounded, 'title': 'Diamonds'},
      {'icon': Icons.support_agent_rounded, 'title': 'Support'},
      {'icon': Icons.vpn_key_rounded, 'title': 'Unique ID'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 16),
            child: Text(
              'EXCLUSIVE PRIVILEGES',
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: benefits.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              return _buildPremiumFeatureCard(context, benefits[index]['icon'], benefits[index]['title']);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatureCard(BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.onSurface.withValues(alpha: 0.1), theme.colorScheme.onSurface.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: theme.colorScheme.secondary, size: 28),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                title,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 11, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyUpgradeButton(BuildContext context, int? nextLevel, int cost, bool hasEnough) {
    final theme = Theme.of(context);
    if (nextLevel == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NEXT: VIP $nextLevel',
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w900),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.diamond, color: theme.colorScheme.secondary, size: 16),
                      const SizedBox(width: 6),
                      Text('$cost', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: hasEnough ? _handleUpgrade : null,
              child: Container(
                height: 64,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: hasEnough 
                      ? [theme.colorScheme.tertiary, theme.colorScheme.secondary, theme.primaryColor]
                      : [theme.colorScheme.onSurface.withValues(alpha: 0.1), theme.colorScheme.onSurface.withValues(alpha: 0.2)],
                  ),
                  boxShadow: hasEnough ? [
                    BoxShadow(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ] : [],
                  border: Border.all(color: theme.scaffoldBackgroundColor, width: 1),
                ),
                child: Center(
                  child: Text(
                    hasEnough ? 'UPGRADE NOW' : 'INSUFFICIENT BALANCE',
                    style: TextStyle(
                      color: hasEnough ? theme.colorScheme.onSecondary : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
