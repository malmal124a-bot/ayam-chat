import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_icon.dart';
import '../controllers/user_controller.dart';
import '../controllers/gift_controller.dart';
import '../services/supabase_service.dart';
import '../widgets/gift_sheet_widget.dart';
import 'dm_chat_screen.dart';
import 'edit_profile_screen.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final String? userId;
  final String? userName;

  const ProfileDetailsScreen({
    super.key,
    this.userId,
    this.userName,
  });

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  bool _isLoading = true;
  String _name = '';
  String _photoUrl = '';
  String _gender = '';
  int _age = 0;
  int _vipLevel = 0;
  int _level = 1;
  int _globalScore = 0;
  String _bio = '';
  String? _equippedFrameUrl;
  String? _authUid;
  String _country = '';
  int _receivedGiftsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchTargetUser();
  }

  Future<void> _fetchTargetUser() async {
    try {
      final userId = widget.userId;
      if (userId == null || userId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      var query = SupabaseService.client.from('users').select();
      query = query.eq('numeric_id', userId);
      final rows = await query.limit(1);

      if (rows.isEmpty || !mounted) {
        setState(() => _isLoading = false);
        return;
      }

      final data = rows.first;
      setState(() {
        _name = data['name']?.toString() ?? widget.userName ?? 'مستخدم';
        _photoUrl = data['photo_url']?.toString() ?? '';
        _gender = (data['gender']?.toString() ?? '').toLowerCase();
        _vipLevel = (data['vip_level'] as num?)?.toInt() ?? 0;
        _level = (data['level'] as num?)?.toInt() ?? 1;
        _globalScore = (data['global_score'] as num?)?.toInt() ?? 0;
        _bio = data['bio']?.toString() ?? '';
        _equippedFrameUrl = data['equipped_frame_url']?.toString();
        _authUid = data['auth_uid']?.toString();
        _country = data['country']?.toString() ?? '';
        final dob = data['date_of_birth'];
        if (dob != null) {
          final parsed = DateTime.tryParse(dob.toString());
          if (parsed != null) _age = DateTime.now().year - parsed.year;
        }
        _isLoading = false;
      });

      _fetchGiftCount();
    } catch (e) {
      debugPrint('ProfileDetailsScreen: error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchGiftCount() async {
    try {
      if (_authUid == null) return;
      final rows = await SupabaseService.client
          .from('sent_gifts')
          .select('id')
          .eq('receiver_id', _authUid!);
      if (mounted) {
        setState(() => _receivedGiftsCount = rows.length);
      }
    } catch (e) {
      debugPrint('ProfileDetailsScreen: error fetching gifts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = context.watch<UserController>();
    final bool isOwnProfile = currentUser.numericId == widget.userId;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

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
                        _buildAvatar(theme),
                        const SizedBox(height: 14),
                        Text(_name, style: TextStyle(color: _vipLevel > 0 ? Colors.amber : theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 22)),
                        const SizedBox(height: 6),
                        Text('ID: ${widget.userId}', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14)),
                        const SizedBox(height: 12),
                        _buildBadges(theme),
                        const SizedBox(height: 24),
                        _info('المستوى', '$_level'),
                        _info('النقاط', '$_globalScore'),
                        _info('VIP', '$_vipLevel'),
                        if (_country.isNotEmpty) _info('البلد', _country),
                        if (_bio.isNotEmpty) _info('السيرة الذاتية', _bio),
                        const SizedBox(height: 24),
                        if (!isOwnProfile)
                          _buildActionButtons(context)
                        else
                          _buildOwnProfileActions(context),
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

  Widget _buildAvatar(ThemeData theme) {
    final bool isVip = _vipLevel > 0;
    final Color vipColor = isVip ? Colors.amber : theme.colorScheme.secondary;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: isVip ? vipColor : theme.colorScheme.secondary, width: 3),
            image: _photoUrl.isNotEmpty
                ? DecorationImage(
                    image: (_photoUrl.startsWith('http') ? NetworkImage(_photoUrl) : AssetImage(_photoUrl)) as ImageProvider,
                    fit: BoxFit.cover,
                  )
                : null,
            color: _photoUrl.isEmpty ? Colors.grey : null,
          ),
          child: _photoUrl.isEmpty
              ? const AppIcon('Icons.person', icon: Icons.person, size: 50, color: Colors.white)
              : null,
        ),
        if (_equippedFrameUrl != null && _equippedFrameUrl!.isNotEmpty)
          Positioned(
            top: -18, left: -18, right: -18, bottom: -18,
            child: ClipOval(
              child: Image.network(_equippedFrameUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadges(ThemeData theme) {
    final Color vipColor = _vipLevel > 0 ? Colors.amber : theme.colorScheme.secondary;
    return Wrap(
      spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
      children: [
        if (_vipLevel > 0) _badge('VIP $_vipLevel', vipColor, Icons.star_rounded),
        _badge('Lv.$_level', theme.colorScheme.tertiary, Icons.military_tech),
        if (_globalScore > 0) _badge('$_globalScore نقطة', Colors.cyan, Icons.stars),
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

  Widget _info(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
          Flexible(child: Text(v, style: TextStyle(color: Colors.grey.shade700, fontSize: 14), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _actionBtn(context, Icons.message_rounded, 'رسالة', Colors.teal, () {
              if (_authUid != null) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DmChatScreen(
                    otherUserId: widget.userId ?? '',
                    otherName: _name,
                    otherPic: _photoUrl,
                  ),
                ));
              }
            })),
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
              }, roomId: widget.userId, profileUserId: _authUid, profileUserName: _name, profileUserPhoto: _photoUrl);
            })),
          ],
        ),
      ],
    );
  }

  Widget _buildOwnProfileActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionBtn(context, Icons.edit_rounded, 'تعديل الملف الشخصي', Colors.amber, () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => Consumer<UserController>(
                builder: (_, __, ___) => const EditProfileScreen(),
              ),
            ));
          }),
        ),
      ],
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
