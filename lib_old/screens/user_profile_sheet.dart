import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserProfileSheet extends StatefulWidget {
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final int age;
  final String gender;
  final String? flag;
  final int vipLevel;
  final bool isHost;
  final int followers;
  final int following;
  final int receivedItems;
  final int sentItems;
  final String? bio;
  final String? lifePhotoUrl;
  final int vipDays;
  final String? partnerName;
  final String? partnerAvatar;
  final String? agencyName;
  final String? agencyAvatar;
  final String? agencyId;
  final String? familyName;
  final String? familyAvatar;
  final String? familyId;

  const UserProfileSheet({
    super.key,
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    required this.age,
    required this.gender,
    this.flag,
    required this.vipLevel,
    this.isHost = false,
    required this.followers,
    required this.following,
    required this.receivedItems,
    required this.sentItems,
    this.bio,
    this.lifePhotoUrl,
    required this.vipDays,
    this.partnerName,
    this.partnerAvatar,
    this.agencyName,
    this.agencyAvatar,
    this.agencyId,
    this.familyName,
    this.familyAvatar,
    this.familyId,
  });

  @override
  State<UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<UserProfileSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Color constants
  static const Color primaryBackground = Color(0xFF10141D);
  static const Color secondaryBackground = Color(0xFF1B2230);
  static const Color goldenColor = Color(0xFFE0A94E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A96A6);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primaryBackground,
      child: Column(
        children: [
          // Header Card
          _buildHeaderCard(),
          
          // Stats Row
          _buildStatsRow(),
          
          // Action Bar
          _buildActionBar(),
          
          // Tab Bar
          _buildTabBar(),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInformationTab(),
                _buildMomentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: secondaryBackground,
        border: Border(bottom: BorderSide(color: goldenColor.withValues(alpha: 0.3), width: 1)),
      ),
      child: Column(
        children: [
          // Avatar with frame
          Stack(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundImage: widget.avatarUrl != null 
                    ? NetworkImage(widget.avatarUrl!) 
                    : null,
                child: widget.avatarUrl == null 
                    ? const Icon(Icons.person, size: 45, color: textSecondary)
                    : null,
              ),
              // Avatar frame
              Positioned.fill(
                child: Image.asset(
                  'assets/images/frame_vip_${widget.vipLevel}.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/frame_default.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Nickname
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.nickname,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              // Age/Gender Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.gender == 'male' 
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.pink.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      widget.gender == 'male' 
                          ? 'assets/images/icon_male.png'
                          : 'assets/images/icon_female.png',
                      width: 12,
                      height: 12,
                      errorBuilder: (_, __, ___) => Icon(
                        widget.gender == 'male' ? Icons.male : Icons.female,
                        color: widget.gender == 'male' ? Colors.blue : Colors.pink,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.age}',
                      style: TextStyle(
                        color: widget.gender == 'male' ? Colors.blue : Colors.pink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Flag
              if (widget.flag != null)
                Image.asset(
                  widget.flag!,
                  width: 24,
                  height: 16,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // VIP Badge and User ID
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // VIP Badge
              Image.asset(
                'assets/images/vip_${widget.vipLevel}.png',
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 12),
              // User ID with copy
              Row(
                children: [
                  Text(
                    'ID: ${widget.userId}',
                    style: const TextStyle(color: textSecondary, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.userId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ المعرف')),
                      );
                    },
                    child: Image.asset(
                      'assets/images/icon_copy.png',
                      width: 16,
                      height: 16,
                      errorBuilder: (_, __, ___) => const Icon(Icons.copy, color: goldenColor, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Host Tag
          if (widget.isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    goldenColor.withValues(alpha: 0.3),
                    Colors.orange.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: goldenColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/icon_host.png',
                    width: 16,
                    height: 16,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'مضيف',
                    style: TextStyle(color: goldenColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: secondaryBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn('متابعين', widget.followers),
          _buildStatColumn('متابعة', widget.following),
          _buildStatColumn('تم الاستلام', widget.receivedItems),
          _buildStatColumn('إرسال', widget.sentItems),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Follow Button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم المتابعة')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text(
                'متابعة',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Message Button
          Container(
            decoration: BoxDecoration(
              color: secondaryBackground,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Image.asset(
                'assets/images/icon_message.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(Icons.message, color: goldenColor),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('رسالة')),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          
          // Send Gift Button
          Container(
            decoration: BoxDecoration(
              color: secondaryBackground,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Image.asset(
                'assets/images/icon_gift.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard, color: goldenColor),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('إرسال هدية')),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          
          // More Options
          Container(
            decoration: BoxDecoration(
              color: secondaryBackground,
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton<String>(
              icon: Image.asset(
                'assets/images/icon_more.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(Icons.more_horiz, color: goldenColor),
              ),
              onSelected: (value) {
                if (value == 'block') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حظر المستخدم')),
                  );
                } else if (value == 'report') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم الإبلاغ عن المستخدم')),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'block', child: Text('مستخدم محظور')),
                const PopupMenuItem(value: 'report', child: Text('إبلاغ')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: secondaryBackground,
        border: Border(bottom: BorderSide(color: goldenColor.withValues(alpha: 0.3), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: goldenColor,
        labelColor: goldenColor,
        unselectedLabelColor: textSecondary,
        tabs: const [
          Tab(text: 'معلومات'),
          Tab(text: 'لحظات'),
        ],
      ),
    );
  }

  Widget _buildInformationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bio Section
        _buildSectionCard(
          'السيرة الذاتية',
          widget.bio ?? 'لا توجد سيرة ذاتية',
          'assets/images/icon_bio.png',
          Icons.person_outline,
        ),
        const SizedBox(height: 16),
        
        // Life Photo
        _buildLifePhotoSection(),
        const SizedBox(height: 16),
        
        // VIP Identity Banner
        _buildVipBanner(),
        const SizedBox(height: 16),
        
        // CP Banner
        _buildCpBanner(),
        const SizedBox(height: 16),
        
        // Family Card
        _buildFamilyCard(),
        const SizedBox(height: 16),
        
        // Wallet / Wealth Section
        _buildWalletSection(),
        const SizedBox(height: 16),
        
        // Supporters & Agency
        _buildSupportersAndAgency(),
        const SizedBox(height: 16),
        
        // Badges
        _buildHorizontalSection('وسام', 'assets/images/icon_badge.png', Icons.military_tech, [
          _itemPlaceholder('وسام 1'),
          _itemPlaceholder('وسام 2'),
          _itemPlaceholder('وسام 3'),
        ]),
        const SizedBox(height: 16),
        
        // Entrance Vehicles
        _buildHorizontalSection('دخولي', 'assets/images/icon_entrance.png', Icons.directions_car, [
          _itemPlaceholder('دخولي 1'),
          _itemPlaceholder('دخولي 2'),
          _itemPlaceholder('دخولي 3'),
        ]),
        const SizedBox(height: 16),
        
        // Head Frames
        _buildHorizontalSection('أغطية الرأس', 'assets/images/icon_frame.png', Icons.face, [
          _itemPlaceholder('غطاء 1'),
          _itemPlaceholder('غطاء 2'),
          _itemPlaceholder('غطاء 3'),
        ]),
        const SizedBox(height: 16),
        
        // Received Gifts Grid
        _buildReceivedGiftsGrid(),
        const SizedBox(height: 16),
        
        // Bottom Action Options
        _buildActionOptions(),
        const SizedBox(height: 16),
        
        // Gift Gallery / Store Section
        _buildGiftGallerySection(),
      ],
    );
  }

  Widget _buildGiftGallerySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/icon_store.png',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.store, color: goldenColor, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'معرض الهدايا',
                style: TextStyle(color: goldenColor, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/icon_backpack.png',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.backpack, color: goldenColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGiftCategory('أزرق', 'assets/images/gift_blue.png', Icons.card_giftcard),
              _buildGiftCategory('أحمر', 'assets/images/gift_red.png', Icons.favorite),
              _buildGiftCategory('ذهبي', 'assets/images/gift_gold.png', Icons.star),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGiftCategory(String label, String assetPath, IconData fallbackIcon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            assetPath,
            width: 30,
            height: 30,
            errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: goldenColor, size: 30),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildActionOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildActionOption(
            'تعديل الملف الشخصي',
            'assets/images/icon_edit_profile.png',
            Icons.edit,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تعديل الملف الشخصي')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionOption(
            'إعدادات',
            'assets/images/icon_settings.png',
            Icons.settings,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الإعدادات')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionOption(
            'مشاركة الملف الشخصي',
            'assets/images/icon_share.png',
            Icons.share,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('مشاركة الملف الشخصي')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionOption(String title, String assetPath, IconData fallbackIcon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Image.asset(
            assetPath,
            width: 24,
            height: 24,
            errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: goldenColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: textPrimary, fontSize: 14),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, String content, String assetPath, IconData fallbackIcon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                assetPath,
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: goldenColor, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: goldenColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(color: textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildLifePhotoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/life_photo.png',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.photo_camera, color: goldenColor, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'صورة الحياة',
                style: TextStyle(color: goldenColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.lifePhotoUrl != null && widget.lifePhotoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.lifePhotoUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _EmptyPlaceholder('لا يوجد صور'),
              ),
            )
          else
            const _EmptyPlaceholder('لا يوجد صور'),
        ],
      ),
    );
  }

  Widget _buildVipBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            goldenColor.withValues(alpha: 0.3),
            Colors.orange.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: goldenColor, width: 1),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/icon_vip.png',
            width: 32,
            height: 32,
            errorBuilder: (_, __, ___) => const Icon(Icons.workspace_premium, color: goldenColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VIP عضوية',
                  style: TextStyle(color: goldenColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.vipDays} يوم متبقي',
                  style: const TextStyle(color: textPrimary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.vipDays / 30,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(goldenColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCpBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.withValues(alpha: 0.2),
            goldenColor.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.pink.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // CP Level Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.pink, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'CP Lv.1',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Partner Avatar with Gold/Pink Frame
          if (widget.partnerAvatar != null)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.pink,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  widget.partnerAvatar!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withValues(alpha: 0.3),
                border: Border.all(
                  color: Colors.pink.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.favorite_border,
                color: Colors.pink,
                size: 24,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الشراكة',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                if (widget.partnerName != null)
                  Text(
                    widget.partnerName!,
                    style: const TextStyle(color: textSecondary, fontSize: 12),
                  )
                else
                  const Text(
                    'غير مرتبط',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
          // Connection Status Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/icon_cp_heart.png',
              width: 20,
              height: 20,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.favorite,
                color: Colors.pink,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/icon_family.png',
            width: 32,
            height: 32,
            errorBuilder: (_, __, ___) => const Icon(Icons.home, color: Colors.purple, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'العائلة',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                if (widget.familyName != null)
                  Text(
                    widget.familyName!,
                    style: const TextStyle(color: textSecondary, fontSize: 12),
                  )
                else
                  const Text(
                    'غير منتمي لعائلة',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (widget.familyAvatar != null)
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(widget.familyAvatar!),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.purple.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Image.asset(
                'assets/images/icon_family_default.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.home_outlined,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.2),
            Colors.cyan.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/icon_wallet.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, color: goldenColor, size: 24),
              ),
              const SizedBox(width: 8),
              const Text(
                'المحفظة',
                style: TextStyle(color: goldenColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWalletItem('coins', '25,680', 'assets/images/icon_coins.png', Icons.monetization_on),
              _buildWalletItem('diamonds', '12,580', 'assets/images/icon_diamonds.png', Icons.diamond),
              _buildWalletItem('vip', 'Lv.${widget.vipLevel}', 'assets/images/icon_vip_small.png', Icons.workspace_premium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletItem(String type, String value, String assetPath, IconData fallbackIcon) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white12,
            shape: BoxShape.circle,
            border: Border.all(
              color: goldenColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Image.asset(
            assetPath,
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: goldenColor, size: 20),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSupportersAndAgency() {
    return Column(
      children: [
        // Supporters
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: secondaryBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/icon_supporters.png',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.people, color: goldenColor, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'داعمون',
                style: TextStyle(color: goldenColor, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Text('0', style: TextStyle(color: textPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Agency
        if (widget.agencyName != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: secondaryBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/icon_agency.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => const Icon(Icons.business, color: goldenColor, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'وكالة',
                      style: TextStyle(color: goldenColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (widget.agencyAvatar != null)
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(widget.agencyAvatar!),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.agencyName!,
                            style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                          ),
                          if (widget.agencyId != null)
                            Text(
                              'ID: ${widget.agencyId}',
                              style: const TextStyle(color: textSecondary, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('التقدم بطلب للانضمام')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: goldenColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    'التقدم بطلب للانضمام',
                    style: TextStyle(color: goldenColor),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: secondaryBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/icon_agency.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.business, color: goldenColor, size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'وكالة',
                  style: TextStyle(color: goldenColor, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Text('غير منتمي', style: TextStyle(color: textSecondary)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHorizontalSection(String title, String assetPath, IconData fallbackIcon, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                assetPath,
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: goldenColor, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: goldenColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: items[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemPlaceholder(String label) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: textSecondary, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildReceivedGiftsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/icon_gift_received.png',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard, color: goldenColor, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'الهدايا المستلمة',
                style: TextStyle(color: goldenColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
            children: List.generate(8, (index) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.brown.withValues(alpha: 0.6),
                      goldenColor.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/icon_gift_item.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.card_giftcard,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 24,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'x${(index + 1) * 2}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/icon_moments_empty.png',
            width: 64,
            height: 64,
            errorBuilder: (_, __, ___) => Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد لحظات حتى الآن',
            style: TextStyle(color: textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final String text;
  
  const _EmptyPlaceholder(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white38),
        ),
      ),
    );
  }
}