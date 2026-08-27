import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'voice_room_screen.dart';
import 'create_room_screen.dart';
import 'family_management_screen.dart';
import 'cp_screen.dart';
import 'leaderboard_screen.dart';
import 'daily_checkin_screen.dart';
import 'profile_details_screen.dart';
import '../controllers/user_controller.dart';
import '../controllers/daily_checkin_controller.dart';
import '../services/supabase_service.dart';

class RoomsHomeScreen extends StatefulWidget {
  const RoomsHomeScreen({super.key});

  @override
  State<RoomsHomeScreen> createState() => _RoomsHomeScreenState();
}

class _RoomsHomeScreenState extends State<RoomsHomeScreen> {
  String _activeTab = 'hot'; // Default to GLOBAL 'hot' tab
  String? _selectedCategory; // STEP 5: Category Filtering
  final TextEditingController _searchController = TextEditingController();
  final DailyCheckinController checkinController = Get.find<DailyCheckinController>();
  
  final List<String> _categories = ['الكل', 'دردشة', 'ألعاب', 'موسيقى', 'حفلات', 'ثقافة'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (checkinController.canClaimToday.value && !checkinController.hasClaimedOnce.value) {
        Get.to(() => const DailyCheckinScreen());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1F180B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'بحث (مستخدم أو غرفة)',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'أدخل المعرف (6 أرقام)',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: const Color(0xFF2A1F0D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFD700)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFD700)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                  ),
                ),
              ),
	      const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _searchController.clear();
                    },
                    child: const Text('إلغاء', style: TextStyle(color: Colors.white38)),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleSearch(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 5,
                    ),
                    child: const Text('بحث', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSearch() async {
    final id = _searchController.text.trim();
    if (id.isEmpty) return;

    final roomRow = await SupabaseService.client
        .from('rooms')
        .select()
        .eq('room_id', id)
        .maybeSingle();
    if (roomRow != null) {
      if (!mounted) return;
      Navigator.pop(context);
      _searchController.clear();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VoiceRoomScreen(
            roomId: id,
            roomName: roomRow['room_name'],
            roomCover: roomRow['room_cover'],
            isOwner: roomRow['owner_id'] == UserController().numericId,
          ),
        ),
      );
      return;
    }

    final userRows = await SupabaseService.client
        .from('users')
        .select()
        .eq('numeric_id', id)
        .limit(1);
    if (userRows.isNotEmpty) {
      if (!mounted) return;
      Navigator.pop(context);
      _searchController.clear();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileDetailsScreen(userId: userRows.first['numeric_id']),
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لم يتم العثور على نتائج')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B08),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildRoyalHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          _buildLiveBannerSlider(), // STEP 5: Live Banner Stream
                          const SizedBox(height: 6),
                          _buildDualSecondaryBanners(),
                          const SizedBox(height: 6),
                          _buildCategoryFilterBar(), // STEP 5: Category Filters
                          const SizedBox(height: 6),
                          _buildTabDescription(),
                          const SizedBox(height: 6),
                          _buildRoyalRoomsGrid(),
                          const SizedBox(height: 6),
                          _buildBottomDualWideBanners(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 100,
            child: _buildFloatingCheckinButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBannerSlider() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.client
          .from('banners')
          .stream(primaryKey: ['id'])
          .order('order'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Fallback to default header if no banners in DB
          return Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/images/bg_header.png', fit: BoxFit.cover),
            ),
          );
        }

        final banners = snapshot.data!;
        return SizedBox(
          height: 140,
          child: PageView.builder(
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final data = banners[index];
              final imageUrl = data['image_url'] ?? '';
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageUrl.startsWith('http') 
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Image.asset('assets/images/bg_header.png', fit: BoxFit.cover),
                ),
              );
            },
          ),
        );
      }
    );
  }

  Widget _buildCategoryFilterBar() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = (_selectedCategory == cat) || (_selectedCategory == null && cat == 'الكل');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  _selectedCategory = (cat == 'الكل') ? null : cat;
                });
              },
              selectedColor: Colors.amber,
              backgroundColor: Colors.white.withOpacity(0.05),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabDescription() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F180B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x55FFD700), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            _activeTab == 'mine' ? Icons.bookmark : Icons.local_fire_department,
            color: const Color(0xFFFFD700),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _activeTab == 'mine' 
                ? 'غرفتك الخاصة وغرفك المفضلة' 
                : 'الغرفة الرائجة حالياً (بث عالمي لجميع المستخدمين)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoyalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A1F0D), Color(0xFF0D0B08)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _activeTab = 'hot';
                  });
                },
                child: _buildHeaderTextTab("الرائج", _activeTab == 'hot'),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _activeTab = 'mine';
                  });
                },
                child: _buildHeaderTextTab("غرفي", _activeTab == 'mine'),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showSearchDialog(),
                child: _buildHeaderIconButton(Icons.search_rounded, 'assets/images/icon_search.png', 24),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  final userController = UserController();
                  final String roomId = userController.numericId;
                  if (roomId.isEmpty) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomScreen()));
                    return;
                  }
                  try {
                    final existingRoom = await SupabaseService.client
                        .from('rooms')
                        .select()
                        .eq('room_id', roomId)
                        .maybeSingle();
                    if (existingRoom != null && mounted) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => VoiceRoomScreen(
                          roomName: existingRoom['room_name'] ?? 'غرفتي',
                          roomId: roomId,
                          roomCover: existingRoom['room_cover'],
                          isOwner: true,
                        ),
                      ));
                    } else if (mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomScreen()));
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomScreen()));
                    }
                  }
                },
                child: _buildHeaderIconButton(Icons.castle_rounded, 'assets/images/icon_my_room_entry.png', 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTextTab(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.transparent : const Color(0xFFD4AF37),
          width: 1.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.black : const Color(0xFFFFD700),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFloatingCheckinButton() {
    return Obx(() => Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: !checkinController.canClaimToday.value
            ? [const Color(0xFFFFD700).withOpacity(0.5), const Color(0xFFB8860B).withOpacity(0.5)]
            : [const Color(0xFFFFD700), const Color(0xFFB8860B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => const DailyCheckinScreen()),
          borderRadius: BorderRadius.circular(32.5),
          child: ClipOval(
            child: Image.asset(
              'assets/images/icon_user_task_new.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.today,
                color: Colors.black,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildDualSecondaryBanners() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildGoldenHeartCard(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStackedEventBadges(),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldenHeartCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CpScreen(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD700), width: 2),
          gradient: const LinearGradient(
            colors: [Color(0xFF3D2B00), Color(0xFF191100)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/cp_entry.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Color(0xFFFFD700), size: 35),
                  SizedBox(height: 8),
                  Text(
                    "القلب الملكي",
                    style: TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStackedEventBadges() {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FamilyManagementScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3D2B00), Color(0xFF191100)],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/+½+¦+ê+¬ +¦+ê+à.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.family_restroom, color: Color(0xFFFFD700), size: 40),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LeaderboardScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3D2B00), Color(0xFF191100)],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/ranking_entry.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 40),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoyalRoomsGrid() {
    final userController = UserController();
    final base = SupabaseService.client.from('rooms').stream(primaryKey: ['room_id']);

    // GLOBAL HOME SCREEN STREAMING: Use 'status' == 'active' for real-time feed
    Stream<List<Map<String, dynamic>>> query;
    if (_activeTab == 'mine') {
      query = base.eq('owner_id', userController.numericId);
    } else if (_selectedCategory != null) {
      query = base
          .eq('status', 'active')
          .eq('category', _selectedCategory!)
          .order('participant_count', ascending: false);
    } else {
      query = base
          .eq('status', 'active')
          .order('participant_count', ascending: false);
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: query,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }
        
        final roomsDocs = snapshot.data ?? [];
        
        if (_activeTab == 'mine' && roomsDocs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.bookmark_border, color: const Color(0xFFFFD700).withOpacity(0.5), size: 64),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد غرف خاصة بك',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'قم بإنشاء غرفتك الملكية الآن',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          );
        }

        if (roomsDocs.isEmpty) {
           return Container(
            padding: const EdgeInsets.all(32),
            child: const Text('لا توجد غرف حالياً تطابق هذا التصنيف', style: TextStyle(color: Colors.white54)),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: roomsDocs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final roomData = roomsDocs[index];
            final roomId = roomData['room_id'] ?? '';
            final roomName = roomData['room_name'] ?? 'غرفة ملكية';
            final roomCover = roomData['room_cover'] ?? '';
            final participants = roomData['participant_count'] ?? 0;
            final category = roomData['category'] ?? 'عام';
            final ownerId = roomData['owner_id'] ?? '';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoiceRoomScreen(
                      roomId: roomId,
                      roomName: roomName,
                      roomCover: roomCover,
                      isOwner: ownerId == userController.numericId,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x33FFD700), blurRadius: 6)],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          index % 2 == 0 ? 'assets/images/room_top1.png' : 'assets/images/room_top2.png',
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFFD700), width: 2),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2E2000), Color(0xFF0F0B00)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 22.0, 8.0, 10.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: const Color(0xFF4A3400),
                                image: roomCover.isNotEmpty 
                                  ? _buildRoomImageProvider(roomCover)
                                  : null,
                              ),
                              child: roomCover.isEmpty ? const Center(
                                child: Icon(
                                  Icons.castle_rounded,
                                  color: Color(0xFFFFD700),
                                  size: 32,
                                ),
                              ) : null,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            roomName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                category,
                                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 7),
                              ),
                              const Text(' • ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 7)),
                              Text(
                                participants.toString(),
                                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 7),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: $roomId',
                            style: const TextStyle(color: Colors.white70, fontSize: 7),
                          ),
                        ],
                      ),
                    ),
                    if (roomData['status'] == 'active')
                      Positioned(
                        top: 16,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text("LIVE +", style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  DecorationImage _buildRoomImageProvider(String cover) {
    if (cover.startsWith('data:image')) {
      final String pureBase64 = cover.split(',').last;
      return DecorationImage(
        image: MemoryImage(Uint8List.fromList(base64Decode(pureBase64))),
        fit: BoxFit.cover,
      );
    }
    return DecorationImage(
      image: cover.startsWith('http') 
        ? NetworkImage(cover) as ImageProvider
        : FileImage(File(cover)),
      fit: BoxFit.cover
    );
  }

  Widget _buildBottomDualWideBanners() {
    return Column(
      children: [
        _buildWideGoldBanner("العرض المميز", Icons.local_offer, 'assets/images/banner_rssasa_main.jpeg', _showFeaturedOfferDialog),
        const SizedBox(height: 6),
        _buildWideGoldBanner("الفعالية القادمة", Icons.event, 'assets/images/banner_rssasa_secondary.jpeg', _showUpcomingEventDialog),
      ],
    );
  }

  Widget _buildWideGoldBanner(String title, IconData icon, String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
          gradient: const LinearGradient(
            colors: [Color(0xFF3D2B00), Color(0xFF191100)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                    ),
                  ),
                  child: Icon(icon, color: Colors.black, size: 30),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_back_ios, color: Color(0xFFFFD700)),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(IconData fallbackIcon, String assetPath, [double size = 24]) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F180B),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x55FFD700)),
      ),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) => Icon(
          fallbackIcon,
          color: Colors.amber,
          size: size * 0.8,
        ),
      ),
    );
  }

  void _showFeaturedOfferDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1F180B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)]),
                ),
                child: const Icon(Icons.local_offer_rounded, color: Colors.black, size: 50),
              ),
              const SizedBox(height: 20),
              const Text(
                'العرض المميز',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'احصل على خصم 50% على جميع مشتريات المتجر لفترة محدودة!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'الكود: ROYAL50',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: const Text('حسناً', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpcomingEventDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1F180B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)]),
                ),
                child: const Icon(Icons.event_rounded, color: Colors.black, size: 50),
              ),
              const SizedBox(height: 20),
              const Text(
                'الفعالية القادمة',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'مسابقة الملوك السنوية',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'التاريخ: 15 أغسطس 2026',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'الجائزة: 10,000 عملة ذهبية + لقب ملكي خاص',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: const Text('سجل الآن', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق', style: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
