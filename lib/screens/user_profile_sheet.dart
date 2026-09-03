import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../controllers/user_controller.dart';
import 'dm_chat_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/app_icon.dart';
import '../widgets/gift_sheet_widget.dart';
import '../controllers/gift_controller.dart';

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
  final String? authUid;

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
    this.authUid,
  });

  @override
  State<UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<UserProfileSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color primaryBackground = Color(0xFF10141D);
  static const Color secondaryBackground = Color(0xFF1B2230);
  static const Color goldenColor = Color(0xFFE0A94E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A96A6);

  late String _nickname;
  String? _avatarUrl;
  late String _gender;
  late int _age;
  late int _vipLevel;
  int _level = 1;
  String? _bio;
  String? _equippedFrameUrl;
  int _globalScore = 0;
  bool _isOwnProfile = false;

  // Real data from Supabase
  String? _agencyName;
  String? _agencyPhotoUrl;
  String? _agencyId;
  int _followersCount = 0;
  int _followingCount = 0;
  int _sentGiftsCount = 0;
  int _receivedGiftsCount = 0;
  List<Map<String, dynamic>> _receivedGifts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nickname = widget.nickname;
    _avatarUrl = widget.avatarUrl;
    _gender = widget.gender;
    _age = widget.age;
    _vipLevel = widget.vipLevel;
    _bio = widget.bio;

    final currentUser = UserController();
    _isOwnProfile = currentUser.numericId == widget.userId;

    _fetchRealProfile();
    _fetchAgency();
    _fetchGifts();
  }

  Future<void> _fetchRealProfile() async {
    try {
      var query = SupabaseService.client.from('users').select();
      if (widget.authUid != null && widget.authUid!.isNotEmpty) {
        query = query.eq('auth_uid', widget.authUid!);
      } else {
        query = query.eq('numeric_id', widget.userId);
      }
      final rows = await query.limit(1);
      if (rows.isEmpty || !mounted) return;
      final data = rows.first;
      setState(() {
        if (data['name'] != null) _nickname = data['name'] as String;
        if (data['photo_url'] != null) _avatarUrl = data['photo_url'] as String;
        if (data['gender'] != null) _gender = (data['gender'] as String).toLowerCase();
        if (data['vip_level'] != null) _vipLevel = (data['vip_level'] as num).toInt();
        if (data['level'] != null) _level = (data['level'] as num).toInt();
        if (data['global_score'] != null) _globalScore = (data['global_score'] as num).toInt();
        _bio = (data['bio'] ?? _bio) as String?;
        _equippedFrameUrl = data['equipped_frame_url'] as String?;
        final dob = data['date_of_birth'];
        if (dob != null) {
          final parsed = DateTime.tryParse(dob.toString());
          if (parsed != null) {
            _age = DateTime.now().year - parsed.year;
          }
        }
      });
    } catch (e) {
      debugPrint('UserProfileSheet: error fetching profile: $e');
    }
  }

  Future<void> _fetchAgency() async {
    try {
      final authUid = widget.authUid;
      if (authUid == null || authUid.isEmpty) return;

      final rows = await SupabaseService.client
          .from('host_agency_members')
          .select('agency_id, role')
          .eq('user_id', authUid)
          .eq('status', 'active')
          .limit(1);
      if (rows.isEmpty || !mounted) return;

      final agencyId = rows.first['agency_id']?.toString();
      if (agencyId == null) return;

      final agencyRows = await SupabaseService.client
          .from('agencies')
          .select('name, photo_url')
          .eq('id', agencyId)
          .limit(1);
      if (agencyRows.isEmpty || !mounted) return;

      final agency = agencyRows.first;
      setState(() {
        _agencyName = agency['name']?.toString();
        _agencyPhotoUrl = agency['photo_url']?.toString();
        _agencyId = agencyId;
      });
    } catch (e) {
      debugPrint('UserProfileSheet: error fetching agency: $e');
    }
  }

  Future<void> _fetchGifts() async {
    try {
      final authUid = widget.authUid;
      if (authUid == null || authUid.isEmpty) return;

      final rows = await SupabaseService.client
          .from('sent_gifts')
          .select('gift_id, gift_name, gift_image_url, count, value')
          .eq('receiver_id', authUid)
          .order('created_at', ascending: false);
      if (!mounted) return;

      final Map<String, Map<String, dynamic>> grouped = {};
      int totalReceived = 0;
      for (final row in rows) {
        final giftId = row['gift_id']?.toString() ?? '';
        final count = (row['count'] as num?)?.toInt() ?? 1;
        totalReceived += count;
        if (grouped.containsKey(giftId)) {
          grouped[giftId]!['total_count'] = ((grouped[giftId]!['total_count'] as int) + count);
        } else {
          grouped[giftId] = {
            'gift_id': giftId,
            'gift_name': row['gift_name']?.toString() ?? '',
            'gift_image_url': row['gift_image_url']?.toString(),
            'total_count': count,
            'value': (row['value'] as num?)?.toInt() ?? 0,
          };
        }
      }

      final sentRows = await SupabaseService.client
          .from('sent_gifts')
          .select('id')
          .eq('sender_id', authUid);

      if (mounted) {
        setState(() {
          _receivedGifts = grouped.values.toList();
          _receivedGiftsCount = totalReceived;
          _sentGiftsCount = sentRows.length;
        });
      }
    } catch (e) {
      debugPrint('UserProfileSheet: error fetching gifts: $e');
    }
  }

  void _openPrivateChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DmChatScreen(
          otherUserId: widget.userId,
          otherName: _nickname,
          otherPic: _avatarUrl,
        ),
      ),
    );
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
          _buildHeaderCard(),
          _buildStatsRow(),
          if (!_isOwnProfile) _buildActionBar(),
          _buildTabBar(),
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
          Stack(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                    ? const AppIcon('Icons.person', icon: Icons.person, size: 45, color: textSecondary)
                    : null,
              ),
              if (_equippedFrameUrl != null && _equippedFrameUrl!.isNotEmpty)
                Positioned.fill(
                  child: ClipOval(
                    child: Image.network(
                      _equippedFrameUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _nickname,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _gender == 'male'
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.pink.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _gender == 'male' ? Icons.male : Icons.female,
                      color: _gender == 'male' ? Colors.blue : Colors.pink,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_age',
                      style: TextStyle(
                        color: _gender == 'male' ? Colors.blue : Colors.pink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_vipLevel > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [goldenColor, Colors.orange]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'VIP $_vipLevel',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              if (_vipLevel > 0) const SizedBox(width: 8),
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
                    child: const AppIcon('Icons.copy', icon: Icons.copy, color: goldenColor, size: 14),
                  ),
                ],
              ),
            ],
          ),
          if (_isOwnProfile) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: goldenColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: goldenColor, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon('Icons.edit', icon: Icons.edit, color: goldenColor, size: 16),
                    SizedBox(width: 6),
                    Text('تعديل الملف الشخصي', style: TextStyle(color: goldenColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
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
          _buildStatColumn('المستوى', _level),
          _buildStatColumn('النقاط', _globalScore),
          _buildStatColumn('تم الاستلام', _receivedGiftsCount),
          _buildStatColumn('إرسال', _sentGiftsCount),
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
          Container(
            decoration: const BoxDecoration(color: secondaryBackground, shape: BoxShape.circle),
            child: IconButton(
              icon: const AppIcon('Icons.message', icon: Icons.message, color: goldenColor),
              onPressed: _openPrivateChat,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(color: secondaryBackground, shape: BoxShape.circle),
            child: IconButton(
              icon: const AppIcon('Icons.card_giftcard', icon: Icons.card_giftcard, color: goldenColor),
              onPressed: () {
                Navigator.pop(context);
                showComprehensiveGiftSheet(context, GiftController(), (msg, target, combo) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إرسال $msg')));
                }, roomId: widget.userId, profileUserId: widget.authUid, profileUserName: widget.nickname, profileUserPhoto: widget.avatarUrl);
              },
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
          Tab(text: 'الهدايا'),
        ],
      ),
    );
  }

  Widget _buildInformationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'السيرة الذاتية',
          _bio ?? 'لا توجد سيرة ذاتية',
          Icons.person_outline,
        ),
        const SizedBox(height: 16),

        if (_agencyName != null) ...[
          _buildAgencyCard(),
          const SizedBox(height: 16),
        ],

        _buildWalletSection(),
        const SizedBox(height: 16),

        _buildHorizontalSection('أغطية الرأس', Icons.face, [
          if (_equippedFrameUrl != null && _equippedFrameUrl!.isNotEmpty)
            _buildFrameItem(_equippedFrameUrl!)
          else
            _buildEmptyItem('لا يوجد'),
        ]),
        const SizedBox(height: 16),

        _buildReceivedGiftsGrid(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionCard(String title, String content, IconData icon) {
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
              Icon(icon, color: goldenColor, size: 20),
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

  Widget _buildAgencyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: secondaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: goldenColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          if (_agencyPhotoUrl != null && _agencyPhotoUrl!.isNotEmpty)
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(_agencyPhotoUrl!),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: goldenColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const AppIcon('Icons.business', icon: Icons.business, color: goldenColor, size: 24),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'وكالة',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  _agencyName!,
                  style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_agencyId != null)
                  Text(
                    'ID: $_agencyId',
                    style: const TextStyle(color: textSecondary, fontSize: 11),
                  ),
              ],
            ),
          ),
          AppIcon('Icons.chevron_left', icon: Icons.chevron_left, color: textSecondary),
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withValues(alpha: 0.2), Colors.cyan.withValues(alpha: 0.2)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const AppIcon('Icons.account_balance_wallet', icon: Icons.account_balance_wallet, color: goldenColor, size: 20),
              const SizedBox(width: 8),
              const Text('المحفظة', style: TextStyle(color: goldenColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWalletItem('النقاط', _globalScore.toString(), Icons.stars),
              _buildWalletItem('VIP', 'Lv.$_vipLevel', Icons.workspace_premium),
              _buildWalletItem('المستوى', 'Lv.$_level', Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white12,
            shape: BoxShape.circle,
            border: Border.all(color: goldenColor.withValues(alpha: 0.3), width: 1),
          ),
          child: Icon(icon, color: goldenColor, size: 20),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildHorizontalSection(String title, IconData icon, List<Widget> items) {
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
              Icon(icon, color: goldenColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: goldenColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: items,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameItem(String url) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: goldenColor.withValues(alpha: 0.5), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(url, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const AppIcon('Icons.face', icon: Icons.face, color: goldenColor, size: 30),
        ),
      ),
    );
  }

  Widget _buildEmptyItem(String label) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(label, style: const TextStyle(color: textSecondary, fontSize: 10), textAlign: TextAlign.center),
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
              const AppIcon('Icons.card_giftcard', icon: Icons.card_giftcard, color: goldenColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'الهدايا المستلمة ($_receivedGiftsCount)',
                style: const TextStyle(color: goldenColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_receivedGifts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('لا توجد هدايا مستلمة', style: TextStyle(color: textSecondary)),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _receivedGifts.length.clamp(0, 12),
              itemBuilder: (context, index) {
                final gift = _receivedGifts[index];
                final count = gift['total_count'] as int;
                final imageUrl = gift['gift_image_url'] as String?;
                final name = gift['gift_name'] as String? ?? '';
                return Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.brown.withValues(alpha: 0.6), goldenColor.withValues(alpha: 0.4)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? Image.network(imageUrl, width: 32, height: 32,
                                      errorBuilder: (_, __, ___) => const AppIcon('Icons.card_giftcard', icon: Icons.card_giftcard, color: Colors.white70, size: 24))
                                  : const AppIcon('Icons.card_giftcard', icon: Icons.card_giftcard, color: Colors.white70, size: 24),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'x$count',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(color: textSecondary, fontSize: 8),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMomentsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon('Icons.camera_alt_outlined', icon: Icons.camera_alt_outlined, size: 64, color: textSecondary),
          SizedBox(height: 16),
          Text('لا توجد لحظات حتى الآن', style: TextStyle(color: textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}
