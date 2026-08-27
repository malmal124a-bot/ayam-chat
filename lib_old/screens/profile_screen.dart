import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/wallet_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/store_controller.dart';
import '../controllers/leaderboard_controller.dart';
import '../theme/app_theme.dart';
import 'wallet_screen.dart';
import 'charging_screen.dart';
import 'store_screen.dart';
import 'vip_screen.dart';
import 'svip_portal_screen.dart';
import 'cp_screen.dart';
import 'settings_screen.dart';
import 'leaderboard_screen.dart';
import 'family_details_screen.dart';
import 'support_screen.dart';
import 'invitation_code_screen.dart';
import 'medal_screen.dart';
import 'policy_screen.dart';
import 'tasks_screen.dart';
import 'visitors_screen.dart';
import 'followers_screen.dart';
import 'friends_screen.dart';
import 'charging_agency_screen.dart';
import 'join_agency_screen.dart';
import 'host_agency_screen.dart';
import 'level_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/broadcast_ticker.dart';
import '../widgets/friend_requests_notification.dart';
import '../models/profile_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Color _getVipColor(int level, ThemeData theme) {
    if (AuthController.vipColors.containsKey(level)) {
      return AuthController.vipColors[level]!;
    }
    return theme.colorScheme.onSurface;
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserController>();
    final inventory = context.watch<InventoryController>();
    final store = context.watch<StoreController>();
    final wallet = context.watch<WalletController>();
    final auth = context.watch<AuthController>();
    final leaderboard = context.watch<LeaderboardController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Image.asset('assets/Asad/Untitled-1_0000_icon_contact_us.png', width: 24, height: 24, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.edit_outlined, color: theme.colorScheme.onSurface)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const BroadcastTicker(),
            const SizedBox(height: 100),
            _buildUserInfo(context, user, inventory, store, wallet, auth, leaderboard),
            const SizedBox(height: 30),
            _buildStatsRow(context, user),
            const SizedBox(height: 30),
            _buildWalletAndShippingSection(context, wallet),
            const SizedBox(height: 20),
            const FriendRequestsNotification(),
            const SizedBox(height: 20),
            _buildTopHeader(context, user),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    _buildMainList(context),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletAndShippingSection(BuildContext context, WalletController wallet) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(auth.currentUser?.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final diamonds = (data?['diamonds'] as num?)?.toInt() ?? wallet.diamonds.value.toInt();
                  final balance = (data?['balance'] as num?)?.toDouble() ?? wallet.balance.value.toDouble();
                  return _buildActionCard(
                    context,
                    title: 'wallet'.tr(),
                    value: '$diamonds ${'diamonds'.tr()} | ${balance.toStringAsFixed(2)}\$',
                    icon: Icons.account_balance_wallet_rounded,
                    assetPath: 'assets/images/Untitled-1_0035_icon_wallet.png',
                    color: theme.colorScheme.secondary,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
                  );
                }
                return _buildActionCard(
                  context,
                  title: 'wallet'.tr(),
                  value: '${wallet.diamonds.value.toInt()} ${'diamonds'.tr()} | ${wallet.balance.value.toStringAsFixed(2)}\$',
                  icon: Icons.account_balance_wallet_rounded,
                  assetPath: 'assets/images/Untitled-1_0035_icon_wallet.png',
                  color: theme.colorScheme.secondary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
                );
              },
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildActionCard(
              context,
              title: 'شحن',
              value: 'بوابات الشحن',
              icon: Icons.payment_rounded,
              assetPath: 'assets/images/ic_pay_gold_title 1(1).png',
              color: Colors.green,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChargingScreen())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    String? assetPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: assetPath != null
                  ? Image.asset(assetPath, width: 24, height: 24, errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 24))
                  : Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(
    BuildContext context, 
    UserController user, 
    InventoryController inventory, 
    StoreController store, 
    WalletController wallet, 
    AuthController auth,
    LeaderboardController leaderboard,
  ) {
    final theme = Theme.of(context);
    String? framePath;
    if (inventory.activeFrameId != null) {
      final items = store.items;
      final index = items.indexWhere((item) => item.id == inventory.activeFrameId);
      if (index != -1) {
        framePath = items[index].imagePath;
      }
    }

    final int vipLevel = user.vipLevel;
    final Color vipColor = _getVipColor(vipLevel, theme);
    final bool isVip = vipLevel > 0;
    
    // Global Trophy Sync
    final int globalRank = leaderboard.getGlobalRank(user.name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                context.read<AuthController>().pickAndUploadProfileImage();
              },
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: isVip ? vipColor : theme.colorScheme.secondary.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildAvatar(user),
                    ),
                  ),
                  if (framePath != null)
                    Positioned(
                      top: -12,
                      left: -12,
                      right: -12,
                      bottom: -12,
                      child: _buildFrame(framePath),
                    ),
                  // GLOBAL TROPHY ICON
                  if (globalRank > 0)
                    Positioned(
                      bottom: -5,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.royalGold,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Icon(
                          globalRank <= 3 ? Icons.emoji_events : Icons.military_tech,
                          color: Colors.black,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      color: isVip ? vipColor : theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isVip)
                        _buildBadge(context, 'VIP $vipLevel', vipColor, icon: Icons.star_rounded),
                      if (auth.svipLevel > 0)
                        _buildSvipBadge(context, auth.svipLevel),
                      
                      // GLOBAL RANK BADGE
                      if (globalRank > 0)
                        _buildBadge(
                          context, 
                          'Rank #$globalRank', 
                          AppTheme.royalGold, 
                          icon: Icons.emoji_events_rounded,
                        ),

                      _buildBadge(context, 'Lv.${user.currentLevel}', theme.colorScheme.tertiaryContainer),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${user.displayId}',
                    style: TextStyle(
                      color: isVip ? vipColor : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: isVip ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildFrame(String path) {
    return path.startsWith('http')
        ? CachedNetworkImage(imageUrl: path, fit: BoxFit.contain, errorWidget: (context, url, error) => const SizedBox())
        : Image.asset(path, fit: BoxFit.contain);
  }

  Widget _buildBadge(BuildContext context, String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, color: Colors.white, size: 10), const SizedBox(width: 4)],
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSvipBadge(BuildContext context, int level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text('SVIP $level', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, UserController user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(context, 'visitors'.tr(), user.visitorsCount.toString(), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorsScreen()));
        }),
        _buildStatItem(context, 'followers'.tr(), user.followersCount.toString(), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FollowersScreen()));
        }),
        _buildStatItem(context, 'friends'.tr(), user.friendsCount.toString(), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
        }),
      ],
    );
  }

  Widget _buildAvatar(UserController user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.id).snapshots(),
      builder: (context, snapshot) {
        String photoUrl = user.profilePic;
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          photoUrl = data?['profilePic']?.toString() ?? user.profilePic;
        }
        
        // Update user controller with latest profile pic from Firestore
        if (photoUrl != user.profilePic) {
          user.updateProfile(newPic: photoUrl);
        }
        
        if (photoUrl.startsWith('http')) {
          return CachedNetworkImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => const Icon(Icons.person, size: 40),
            placeholder: (context, url) => const Icon(Icons.person, size: 40),
          );
        }
        
        // Handle base64 images
        if (photoUrl.startsWith('data:image')) {
          try {
            final base64String = photoUrl.split(',')[1];
            final imageBytes = base64Decode(base64String);
            return Image.memory(imageBytes, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 40));
          } catch (e) {
            debugPrint('Error decoding base64 image: $e');
            return const Icon(Icons.person, size: 40);
          }
        }
        
        // Fallback to asset or default icon
        if (photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
          return Image.asset(photoUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 40));
        }
        
        return const Icon(Icons.person, size: 40);
      },
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, UserController user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTopHeaderItem(context, 'store'.tr(), SizedBox(
          width: 30, height: 30,
          child: Image.asset('assets/images/Untitled-1_0034_icon_store.png', fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: Colors.white70, size: 30),
          ),
        ), const StoreScreen()),
        _buildTopHeaderItem(context, 'VIP ${user.vipLevel}', SizedBox(
          width: 30, height: 30,
          child: Image.asset('assets/images/Untitled-1_0032_live_icon_contribute_vip_enjoy_tag.png', fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.star_rounded, color: Colors.white70, size: 30),
          ),
        ), const VipScreen()),
        _buildTopHeaderItem(context, 'SVIP', SizedBox(
          width: 38, height: 38,
          child: Image.asset('assets/images/SVIP.jpeg', fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.workspace_premium, color: Colors.white70, size: 38),
          ),
        ), const SvipPortalScreen()),
        _buildTopHeaderItem(context, 'وكالة الشحن', SizedBox(
          width: 30, height: 30,
          child: Image.asset('assets/images/icon_recharge.png', fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.local_shipping_rounded, color: Colors.white70, size: 30),
          ),
        ), const ChargingAgencyScreen()),
      ],
    );
  }

  Widget _buildTopHeaderItem(BuildContext context, String label, Widget icon, Widget screen) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Column(
        children: [
          icon,
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMainList(BuildContext context) {
    final theme = Theme.of(context);
    final items = ProfileItem.items;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => _handleNavigation(context, item.titleKey),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                item.assetPath != null
                    ? Image.asset(
                        item.assetPath!,
                        width: 36,
                        height: 36,
                        errorBuilder: (context, error, stackTrace) => Icon(item.icon, color: theme.colorScheme.secondary, size: 36),
                      )
                    : Icon(item.icon, color: theme.colorScheme.secondary, size: 36),
                const Spacer(),
                Text(
                  tr(item.titleKey),
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleNavigation(BuildContext context, String key) {
    switch (key) {
      case 'family': Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyDetailsScreen())); break;
      case 'cp': Navigator.push(context, MaterialPageRoute(builder: (_) => const CpScreen())); break;
      case 'medals': Navigator.push(context, MaterialPageRoute(builder: (_) => const MedalScreen())); break;
      case 'level': Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelScreen())); break;
      case 'leaderboard': Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())); break;
      case 'modife_agency': Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinAgencyScreen())); break;
      case 'host_agency': Navigator.push(context, MaterialPageRoute(builder: (_) => const HostAgencyScreen())); break;
      case 'invitation_code': Navigator.push(context, MaterialPageRoute(builder: (_) => const InvitationCodeScreen())); break;
      case 'help_center': Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())); break;
      case 'settings': Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); break;
      case 'policy': Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())); break;
      case 'tasks': Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen())); break;
    }
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final List<Color> colors;
  final TextStyle? style;
  const GradientText(this.text, {super.key, required this.colors, this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(colors: colors).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style),
    );
  }
}
