import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_room_screen.dart';
import 'family_management_screen.dart';
import 'cp_screen.dart';
import 'leaderboard_screen.dart';
import 'voice_room_screen.dart';
import '../controllers/user_controller.dart';
import '../controllers/room_controller.dart';

class RoomsHomeScreen extends StatefulWidget {
  const RoomsHomeScreen({super.key});

  @override
  State<RoomsHomeScreen> createState() => _RoomsHomeScreenState();
}

class _RoomsHomeScreenState extends State<RoomsHomeScreen> {
  String _activeTab = 'mine'; // 'mine' or 'hot'
  final TextEditingController _userIdSearchController = TextEditingController();
  final RoomController _roomController = RoomController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Room loading state
  bool _isLoadingRooms = false;
  List<Map<String, dynamic>> _rooms = [];
  
  @override
  void initState() {
    super.initState();
    _loadRooms();
  }
  
  void _loadRooms() {
    // Rooms are loaded via StreamBuilder in _buildRoyalRoomsGrid
    // This method is called on tab change to trigger rebuild
    setState(() {});
  }

  @override
  void dispose() {
    _userIdSearchController.dispose();
    super.dispose();
  }

  void _showUserIdSearchDialog() {
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'البحث عن المستخدم',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _userIdSearchController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'أدخل رقم المستخدم',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
                      _userIdSearchController.clear();
                    },
                    child: const Text('إلغاء', style: TextStyle(color: Colors.white38)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final query = _userIdSearchController.text.trim();
                      if (query.isNotEmpty) {
                        if (!mounted) return;
                        Navigator.pop(context);
                        _userIdSearchController.clear();
                        
                        // Search for room by roomId OR ownerId
                        try {
                          Map<String, dynamic>? searchedRoom;
                          
                          // First try by exact roomId
                          searchedRoom = await _roomController.getRoom(query);
                          
                          // If not found, try by ownerId
                          if (searchedRoom == null) {
                            final ownerQuery = await _firestore
                                .collection('rooms')
                                .where('ownerId', isEqualTo: query)
                                .limit(1)
                                .get();
                            
                            if (ownerQuery.docs.isNotEmpty) {
                              searchedRoom = ownerQuery.docs.first.data();
                            }
                          }
                          
                          if (!mounted) return;
                          
                          if (searchedRoom != null) {
                            // Navigate to the searched room
                            if (!context.mounted) return;
                            Navigator.pushNamed(
                              context,
                              '/room_screen',
                              arguments: {
                                'roomId': searchedRoom['roomId'],
                                'roomName': searchedRoom['roomName'],
                                'roomCover': searchedRoom['roomImage'] ?? searchedRoom['roomCover'],
                                'isOwner': searchedRoom['ownerId'] == UserController().id,
                              },
                            );
                          } else {
                            // Room not found
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('الغرفة غير موجودة'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('Error searching for room: $e');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ في البحث: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
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
                          _buildMainHeroBanner(),
                          const SizedBox(height: 6),
                          _buildDualSecondaryBanners(),
                          const SizedBox(height: 6),
                          // Tab description
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
          // Daily Rewards Button - Bottom-Right Position
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: _showDailyRewardsDialog,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/icon_calendar.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
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
                ? 'غرفك المحفوظة والتي انضممت إليها' 
                : 'الغرفة الرائجة حسب التصنيفات والهاشتاغات',
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
          // Top-left text tabs: Mine and Hot
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _activeTab = 'mine';
                  });
                  _loadRooms();
                },
                child: _buildHeaderTextTab("غرفي", _activeTab == 'mine'),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _activeTab = 'hot';
                  });
                  _loadRooms();
                },
                child: _buildHeaderTextTab("الرائج", _activeTab == 'hot'),
              ),
            ],
          ),
          // Top-right action icons
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  _showUserIdSearchDialog();
                },
                child: _buildHeaderIconButton(Icons.search_rounded, 'assets/images/icon_search.png', 24),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _showDailyRewardsDialog,
                child: _buildHeaderIconButton(Icons.calendar_today_rounded, 'assets/images/icon_calendar.png', 24),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateRoomScreen(),
                    ),
                  );
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

  Widget _buildMainHeroBanner() {
    return Container(
      width: double.infinity,
      height: 140,
      constraints: const BoxConstraints(
        minHeight: 120,
        maxHeight: 160,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/bg_header.png',
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[800],
            child: const Center(
              child: Icon(Icons.image_not_supported, color: Colors.white54, size: 40),
            ),
          ),
        ),
      ),
    );
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
        // Top Sub-Card: Family banner
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
        // Bottom Sub-Card: Trophy / Rank card
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
    if (_isLoadingRooms) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
    }
    
    // Show empty state for mine tab if no rooms
    if (_activeTab == 'mine' && _rooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.bookmark_border, color: const Color(0xFFFFD700).withValues(alpha: 0.5), size: 64),
            const SizedBox(height: 16),
            const Text(
              'لا توجد غرفة خاصة بك',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'أنشئ غرفتك الخاصة الآن',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
              child: const Text('إنشاء غرفة'),
            ),
          ],
        ),
      );
    }
    
    if (_rooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.local_fire_department, color: const Color(0xFFFFD700).withValues(alpha: 0.5), size: 64),
            const SizedBox(height: 16),
            const Text(
              'لا توجد غرف رائجة حالياً',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'كن أول من ينشئ غرفة',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
          ],
        ),
      );
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: _activeTab == 'mine'
          ? _firestore.collection('rooms').where('ownerId', isEqualTo: UserController().id).snapshots()
          : _firestore.collection('rooms').orderBy('participantCount', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        }
        
        final rooms = snapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];
        
        if (rooms.isEmpty) {
          return Center(
            child: Text(
              _activeTab == 'mine' ? 'لا توجد غرفة خاصة بك' : 'لا توجد غرف متاحة',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rooms.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final room = rooms[index];
            final userController = UserController();
            final isOwner = room['ownerId'] == userController.id;
            
            return GestureDetector(
              onTap: () async {
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VoiceRoomScreen(
                        roomId: room['roomId'],
                        roomName: room['roomName'],
                        roomCover: room['roomImage'] ?? room['roomCover'], // Use roomImage for parity
                        isOwner: isOwner,
                      ),
                    ),
                  );
                } catch (e) {
                  debugPrint('Error navigating to room: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ في فتح الغرفة: $e')),
                    );
                  }
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x33FFD700), blurRadius: 6)],
                ),
                child: Stack(
                  children: [
                    // Outer decorative frame layer - full card frame
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
                // Inner content layer
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 22.0, 8.0, 10.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: const Color(0xFF4A3400),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _buildRoomImage(
                              room['roomImageBase64'] as String? ?? 
                              room['roomImage'] as String? ?? 
                              room['roomCover'] as String?
                            ), // Use roomImageBase64 first, then roomImage, then roomCover
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        room['roomName'] as String? ?? 'غرفة',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            room['category'] as String? ?? 'عام',
                            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 7),
                          ),
                          if (isOwner) ...[
                            const Text(' • ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 7)),
                            const Text(
                              'غرفتي',
                              style: TextStyle(color: Color(0xFFFFD700), fontSize: 7, fontWeight: FontWeight.bold),
                            ),
                          ],
                          const Text(' • ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 7)),
                          Text(
                            '${(room['participantCount'] as int?) ?? 0} متواجد',
                            style: const TextStyle(color: Colors.white70, fontSize: 7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // LIVE badge - only show for hot rooms
                if (_activeTab == 'hot')
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
      },
    );
  }

  Widget _buildBottomDualWideBanners() {
    return Column(
      children: [
        _buildWideGoldBanner("العرض المميز", Icons.local_offer, 'assets/images/banner_promo.png', _showFeaturedOfferDialog),
        const SizedBox(height: 6),
        _buildWideGoldBanner("الفعالية القادمة", Icons.event, 'assets/images/banner_event.png', _showUpcomingEventDialog),
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)
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
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)
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

  Widget _buildRoomImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const Center(
        child: Icon(Icons.home, color: Color(0xFFFFD700), size: 32),
      );
    }

    // Check if it's a Base64 image (with or without data URI prefix)
    if (imagePath.startsWith('data:image/') && imagePath.contains(';base64,')) {
      try {
        final base64String = imagePath.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.home, color: Color(0xFFFFD700), size: 32),
            );
          },
        );
      } catch (e) {
        debugPrint('Error loading Base64 image: $e');
        return const Center(
          child: Icon(Icons.home, color: Color(0xFFFFD700), size: 32),
        );
      }
    }

    // Check if it's a raw Base64 string (without data URI prefix)
    if (!imagePath.startsWith('http') && !imagePath.startsWith('assets/') && !imagePath.startsWith('/')) {
      try {
        final bytes = base64Decode(imagePath);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.home, color: Color(0xFFFFD700), size: 32),
            );
          },
        );
      } catch (e) {
        debugPrint('Error loading raw Base64 image: $e');
        // Fall through to asset/image handling
      }
    }

    // Handle asset images
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.home, color: Color(0xFFFFD700), size: 32),
          );
        },
      );
    }

    // Handle network images
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.home, color: Color(0xFFFFD700), size: 32),
          );
        },
      );
    }

    // Handle file images (mobile only)
    try {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.home, color: Color(0xFFFFD700), size: 32),
          );
        },
      );
    } catch (e) {
      return const Center(
        child: Icon(Icons.home, color: Color(0xFFFFD700), size: 32),
      );
    }
  }

  void _showDailyRewardsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AlertDialog(
        title: Text('المكافأة اليومية'),
        content: Text('تم استلام مكافأتك اليومية!'),
      ),
    );
  }
}
