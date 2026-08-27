import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/room_ui_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/gift_controller.dart';
import '../controllers/gift_manager.dart';
import '../controllers/leaderboard_controller.dart';
import '../controllers/rocket_controller.dart';
import '../controllers/store_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/agora_controller.dart';
import '../models/mic_seat.dart';
import '../models/store_item.dart';
import '../widgets/room/room_mic_grid_widget.dart';
import '../widgets/room/room_chat_stream_widget.dart';
import '../widgets/room/room_bottom_dock_widget.dart';
import '../widgets/room/room_side_actions_widget.dart';
import '../widgets/room/room_leaderboard_sheet.dart';
import '../widgets/room/room_info_sheet.dart';
import '../widgets/emoji_picker_widget.dart';
import '../widgets/gift_sheet_widget.dart';
import '../widgets/games_sheet_widget.dart';
import '../widgets/room/pk_hud_overlay.dart';
import '../widgets/rocket_reward_box.dart';
import '../widgets/rocket_global_banner_overlay.dart';
import '../helpers/mic_settings_helper.dart';
import '../widgets/mic_controls_sheet.dart';
import '../widgets/entry_effect_player.dart';
import 'messages_screen.dart';
import 'edit_room_screen.dart';
import 'super_prize_screen.dart';
import 'user_profile_sheet.dart';

class VoiceRoomScreen extends StatefulWidget {
  final String? roomId;
  final String? roomName;
  final String? roomCover;
  final bool isOwner;

  const VoiceRoomScreen({
    super.key,
    this.roomId,
    this.roomName,
    this.roomCover,
    this.isOwner = false,
  });

  @override
  State<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends State<VoiceRoomScreen> with TickerProviderStateMixin {
  static RoomUiController? _minimizedController;
  static String? _minimizedRoomId;
  static OverlayEntry? _miniPlayerOverlay;

  RoomUiController controller = RoomUiController();
  UserController userController = UserController();
  GiftController giftController = GiftController();
  GiftManager giftManager = GiftManager();
  
  // FIX: Access AgoraController via Get.find with safe fallback
  AgoraController get agoraController {
    if (!Get.isRegistered<AgoraController>()) {
      Get.put<AgoraController>(AgoraController(), permanent: true);
    }
    return Get.find<AgoraController>();
  }

  final ScrollController _chatScrollController = ScrollController();
  final Map<int, String> _seatReactions = {};

  bool micEnabled = false;
  bool isMuted = false;
  bool roomAudioEnabled = true;
  double volumeLevel = 0.8;

  StoreItem? _entranceToPlay;
  bool _isRoomLocked = false;
  bool isPkBattleActive = false;
  String pkMode = '2v2';
  int pkDurationMinutes = 5;
  int redTeamScore = 0;
  int blueTeamScore = 0;
  bool isOwner = false;
  bool _hasRenderedFallback = false;

  @override
  void initState() {
    super.initState();
    _removeMiniPlayerOverlay();

    // FIX 1: FIX AGORA GETX INJECTION - Always register before rendering UI
    if (!Get.isRegistered<AgoraController>()) {
      Get.put<AgoraController>(AgoraController(), permanent: true);
    }

    try {
      String currentId = widget.roomId ?? userController.id;
      if (currentId == '00000000' || currentId.isEmpty) {
        currentId = userController.id;
      }
      
      bool isResuming = false;
      isOwner = currentId == userController.id;
      controller.isOwner = isOwner;

      if (_minimizedController != null && _minimizedRoomId == currentId) {
        controller = _minimizedController!;
        isResuming = true;
      }

      giftController.preCacheGifts();
      controller.addListener(_refreshUi);
      giftController.addListener(_refreshUi);

      _listenToRoomFirestore(currentId);
      _listenToRoomMembers(currentId);

      if (!isResuming) {
        controller.updateRoomDetails(
          name: widget.roomName ?? controller.roomName,
          id: currentId,
          coverPath: widget.roomCover ?? controller.roomCoverPath,
          ownerId: isOwner ? userController.id : null,
        );
      }

      _initAgora(currentId);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !_hasRenderedFallback) {
          setState(() { _hasRenderedFallback = true; });
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndPlayEntrance();
      });
    } catch (e) {
      debugPrint('Error initializing VoiceRoomScreen: $e');
    }
  }

  Future<void> _initAgora(String roomId) async {
    try {
      final uidString = userController.displayId.length >= 8 
          ? userController.displayId.substring(0, 8) 
          : userController.displayId;
      final parsedUid = int.tryParse(uidString);
      final agoraUid = parsedUid ?? DateTime.now().millisecondsSinceEpoch % 1000000;
      
      await agoraController.initEngine();
      await agoraController.joinRoom(roomId, uid: agoraUid);
    } catch (e) {
      debugPrint('Error initializing Agora: $e');
    }
  }

  void _checkAndPlayEntrance() {
    try {
      final inventory = InventoryController();
      final effectId = inventory.activeEntryEffectId;
      if (effectId != null) {
        final store = StoreController();
        final item = store.items.firstWhere((element) => element.id == effectId, orElse: () => StoreItem(id: '', name: '', imagePath: '', price: 0, type: StoreItemType.entryEffect));
        if (item.id.isNotEmpty && mounted) {
          setState(() { _entranceToPlay = item; });
        }
      }
    } catch (e) {}
  }

  void _listenToRoomFirestore(String roomId) {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final roomData = snapshot.data() as Map<String, dynamic>;
        
        if (roomData.containsKey('micSeats')) {
          final micSeatsData = roomData['micSeats'];
          List<Map<String, dynamic>> seatsList = [];
          if (micSeatsData is List) {
            seatsList = micSeatsData.cast<Map<String, dynamic>>();
          } else if (micSeatsData is Map) {
            seatsList = micSeatsData.values.cast<Map<String, dynamic>>().toList();
          }
          if (seatsList.isNotEmpty) {
            controller.updateMicSeatsFromFirestore(seatsList);
          }
        }
        
        if (roomData.containsKey('participantCount')) {
          controller.updateParticipantCount(roomData['participantCount'] as int);
        }

        // Support Base64 Image or Path
        final roomCover = roomData['roomImageBase64'] ?? roomData['roomImage'] ?? roomData['roomCover'];
        if (roomCover != null && roomCover.isNotEmpty) {
          controller.updateRoomDetails(
            name: controller.roomName,
            id: controller.roomId,
            coverPath: roomCover,
            ownerId: controller.ownerId,
          );
        }

        if (mounted && !_hasRenderedFallback) setState(() { _hasRenderedFallback = true; });
      }
    }, onError: (error) {
      if (mounted && !_hasRenderedFallback) setState(() { _hasRenderedFallback = true; });
    });
  }

  void _listenToRoomMembers(String roomId) {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final members = snapshot.docs.map((doc) => doc.data()).toList();
        controller.updateRoomMembers(members);
      }
    });
    _addCurrentUserToRoom(roomId);
  }

  Future<void> _addCurrentUserToRoom(String roomId) async {
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .doc(userController.id)
          .set({
            'userId': userController.id,
            'userName': userController.name,
            'userProfilePic': userController.profilePic,
            'joinedAt': FieldValue.serverTimestamp(),
            'isOnline': true,
          });
    } catch (e) {}
  }

  void _refreshUi() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(_chatScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    if (_minimizedController != controller) controller.removeListener(_refreshUi);
    giftController.removeListener(_refreshUi);
    _chatScrollController.dispose();
    try { agoraController.leaveRoom(); } catch (e) {}
    _removeCurrentUserFromRoom(widget.roomId ?? userController.displayId);
    super.dispose();
  }

  Future<void> _removeCurrentUserFromRoom(String roomId) async {
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .doc(userController.id)
          .delete();
    } catch (e) {}
  }

  void _toggleMic() async {
    if (mounted) setState(() { micEnabled = !micEnabled; });
    await MicSettingsHelper.updateMicStateInFirestore(roomId: widget.roomId ?? userController.id, userId: userController.id, isMicOn: micEnabled, volumeLevel: volumeLevel);
    await agoraController.setMute(!micEnabled);
  }

  ImageProvider _getSafeImage(String path) {
    if (path.isEmpty) return const AssetImage('assets/Asad/room.jpg');
    // FIX 2: Render room cover using Base64 decode
    if (path.startsWith('data:image/') && path.contains(';base64,')) {
      try {
        final bytes = base64Decode(path.split(',').last);
        return MemoryImage(bytes);
      } catch (e) { return const AssetImage('assets/Asad/room.jpg'); }
    }
    if (!path.startsWith('http') && !path.startsWith('assets/') && !path.startsWith('/')) {
      try { return MemoryImage(base64Decode(path)); } catch (e) {}
    }
    if (path.startsWith('assets/')) return AssetImage(path);
    if (path.startsWith('http')) return NetworkImage(path);
    try { return FileImage(File(path)); } catch (e) { return const AssetImage('assets/Asad/room.jpg'); }
  }

  void _showChatInput() {
    final TextEditingController textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(color: Color(0xFF16213E), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(onTap: _pickImage, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.image, color: Colors.white70, size: 20))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: textController, autofocus: true, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'اكتب رسالة...', hintStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)), onSubmitted: (val) { if (val.trim().isNotEmpty) { controller.sendTextMessage(userController.name, val.trim()); Navigator.pop(context); } })),
              const SizedBox(width: 12),
              GestureDetector(onTap: () { if (textController.text.trim().isNotEmpty) controller.sendTextMessage(userController.name, textController.text.trim()); Navigator.pop(context); }, child: Container(width: 40, height: 40, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.amber, Colors.orange]), shape: BoxShape.circle), child: const Icon(Icons.send, color: Colors.white, size: 20))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null && mounted) {
      controller.addMessage(RoomMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), senderName: userController.name, text: '[صورة]', type: RoomMessageType.image, imageUrl: image.path, senderLevel: userController.currentLevel));
      Navigator.pop(context);
    }
  }

  void _triggerMicReaction(String emoji) {
    final mySeatIndex = controller.allSeats.indexWhere((s) => s.userId == userController.id);
    if (mySeatIndex != -1 && mounted) {
      final seatIndex = controller.allSeats[mySeatIndex].index;
      setState(() => _seatReactions[seatIndex] = "$emoji|${DateTime.now().millisecondsSinceEpoch}");
      Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _seatReactions.remove(seatIndex)); });
    }
  }

  void showToolBoxSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.85), borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 2)),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.amber.withValues(alpha: 0.3), Colors.orange.withValues(alpha: 0.2)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(28))), child: const Column(children: [SizedBox(height: 8), Text('أدوات الغرفة', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)), SizedBox(height: 8)])),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3, padding: const EdgeInsets.all(16), mainAxisSpacing: 16, crossAxisSpacing: 16,
                children: [
                  if (isOwner) ...[
                    _buildHexagonalIcon('assets/images/more_music.png', 'الموسيقى', () { Navigator.pop(context); _showMusicPlayer(); }),
                    _buildHexagonalIcon('assets/images/more_lock.png', 'قفل الغرفة', () { Navigator.pop(context); _toggleRoomLock(); }),
                    _buildHexagonalIcon('assets/images/more_msg_clear.png', 'مسح الدردشة', () { controller.clearMessages(); Navigator.pop(context); }),
                    _buildHexagonalIcon('assets/images/more_setting.png', 'الإعدادات', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => EditRoomScreen(roomName: controller.roomName, controller: controller))); }),
                    _buildHexagonalIcon('assets/images/more_theme.png', 'الخلفية', () { Navigator.pop(context); _showBackgroundPicker(); }),
                    _buildHexagonalIcon('assets/images/more_effective.png', 'التأثيرات', () { Navigator.pop(context); _showEffectsSheet(); }),
                    _buildHexagonalIcon('assets/images/more_red.png', 'الحظر والطرود', () { Navigator.pop(context); _showModerationList(); }),
                    _buildHexagonalIcon('assets/images/icon_game_controller.png', 'الألعاب', () { Navigator.pop(context); _showGamesSheet(); }),
                  ],
                  _buildHexagonalIcon('assets/images/more_shop.png', 'الحقيبة', () { Navigator.pop(context); _showInventorySheet(); }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHexagonalIcon(String assetPath, String label, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(children: [Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white12, shape: BoxShape.circle, border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1)), child: ClipOval(child: Image.asset(assetPath, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.settings, color: Colors.amber, size: 30)))), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center)]));
  }

  void showExactFiveMicOptions([MicSeat? seat]) {
    final MicSeat targetSeat = seat ?? controller.allSeats.firstWhere((s) => s.userId == userController.id, orElse: () => controller.allSeats.firstWhere((s) => s.userName == null || s.userName!.isEmpty, orElse: () => controller.allSeats.first));
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => MicControlsSheet(seat: targetSeat, isMe: targetSeat.userId == userController.id, canManage: isOwner || controller.moderators.contains(userController.id), onJoin: (idx) => controller.joinSeat(idx, userName: userController.name, userId: userController.id, userProfilePic: userController.profilePic), onLeave: (idx) => controller.kickUserFromSeat(idx), onToggleMute: (idx) => controller.toggleSeatMute(idx), onToggleLock: (idx) => controller.toggleSeatLock(idx), onKickToAudience: (idx) => controller.kickUserToAudience(idx), onInvite: (idx) => controller.inviteToSeat(idx)));
  }

  void _showMusicPlayer() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(height: 300, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.9), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))), child: Column(children: [const SizedBox(height: 20), const Text('مشغل الموسيقى', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 20), const Icon(Icons.music_note, color: Colors.white70, size: 60), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: () {}), IconButton(icon: const Icon(Icons.play_arrow, color: Colors.amber, size: 40), onPressed: () {}), IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: () {})])])));
  }

  void _toggleRoomLock() { if (mounted) setState(() { _isRoomLocked = !_isRoomLocked; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isRoomLocked ? 'تم قفل الغرفة' : 'تم فتح الغرفة'))); }

  void _showBackgroundPicker() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(height: 400, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.9), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))), child: Column(children: [const SizedBox(height: 20), const Text('اختر الخلفية', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)), Expanded(child: GridView.count(crossAxisCount: 3, padding: const EdgeInsets.all(16), children: List.generate(6, (index) => GestureDetector(onTap: () => Navigator.pop(context), child: Container(margin: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.primaries[index % Colors.primaries.length].withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)), child: const Center(child: Icon(Icons.image, color: Colors.white70)))))))])));
  }

  void _showEffectsSheet() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(height: 350, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.9), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))), child: Column(children: [const SizedBox(height: 20), const Text('التأثيرات', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)), Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [_effectItem('تأثير الدخول VIP', Icons.stars), _effectItem('تأثير الغرفة', Icons.home), _effectItem('تأثير الميكروفون', Icons.mic)]))])));
  }

  Widget _effectItem(String title, IconData icon) { return ListTile(leading: Icon(icon, color: Colors.amber), title: Text(title, style: const TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)); }

  void _showInventorySheet() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(height: 500, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.9), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))), child: Column(children: [const SizedBox(height: 20), const Text('الحقيبة', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)), Expanded(child: GridView.count(crossAxisCount: 3, padding: const EdgeInsets.all(16), children: List.generate(9, (index) => Container(margin: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.backpack, color: Colors.amber, size: 40), Text('عنصر', style: TextStyle(color: Colors.white70, fontSize: 12))])))))])));
  }

  void _showModerationList() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(height: 400, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.9), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))), child: Column(children: [const SizedBox(height: 20), const Text('قائمة الحظر والطرد', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)), Expanded(child: ListView.builder(itemCount: 3, itemBuilder: (context, index) => ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text('مستخدم $index', style: const TextStyle(color: Colors.white)), trailing: const Icon(Icons.delete, color: Colors.red))))])));
  }

  Widget _buildPKBattleLayout() {
    final seatsPerTeam = pkMode == '2v2' ? 2 : 4;
    final allSeats = controller.visibleSeats;
    final redTeamSeats = allSeats.take(seatsPerTeam).toList();
    final blueTeamSeats = allSeats.skip(seatsPerTeam).take(seatsPerTeam).toList();
    return SingleChildScrollView(child: Column(children: [SizedBox(width: double.infinity, height: 40, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))), onPressed: () => mounted ? setState(() => isPkBattleActive = false) : null, child: const Text('إيقاف التحدي', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)))), const SizedBox(height: 8), Row(children: [Expanded(child: Column(children: [Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red, width: 2)), child: const Center(child: Text('الفريق الأحمر', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))), const SizedBox(height: 8), ...List.generate(seatsPerTeam, (index) => index < redTeamSeats.length ? _buildPKSeat(redTeamSeats[index], Colors.red) : _buildEmptyPKSeat(Colors.red))])), const SizedBox(width: 12), const Center(child: Text('VS', style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold))), const SizedBox(width: 12), Expanded(child: Column(children: [Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue, width: 2)), child: const Center(child: Text('الفريق الأزرق', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)))), const SizedBox(height: 8), ...List.generate(seatsPerTeam, (index) => index < blueTeamSeats.length ? _buildPKSeat(blueTeamSeats[index], Colors.blue) : _buildEmptyPKSeat(Colors.blue))]))])]));
  }

  Widget _buildPKSeat(MicSeat seat, Color teamColor) {
    return GestureDetector(
      onTap: () { if (seat.userId != null) showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => UserProfileSheet(userId: seat.userId!, nickname: seat.userName ?? '', avatarUrl: seat.userProfilePic, age: 25, gender: 'male', vipLevel: 0, isHost: isOwner, followers: 0, following: 0, receivedItems: 0, sentItems: 0, bio: '', vipDays: 0)); },
      child: Container(margin: const EdgeInsets.symmetric(vertical: 2), height: 50, decoration: BoxDecoration(color: teamColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: teamColor, width: 1.5)), child: Row(children: [const SizedBox(width: 12), CircleAvatar(radius: 15, backgroundImage: _getSafeImage(seat.userProfilePic ?? '')), const SizedBox(width: 8), Expanded(child: Text(seat.userName ?? 'مقعد فارغ', style: const TextStyle(color: Colors.white, fontSize: 12))), if (seat.userId != null) Icon(seat.isMuted ? Icons.mic_off : Icons.mic, color: seat.isMuted ? Colors.red : teamColor, size: 16), const SizedBox(width: 8)])),
    );
  }

  Widget _buildEmptyPKSeat(Color teamColor) { return Container(margin: const EdgeInsets.symmetric(vertical: 2), height: 50, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: teamColor.withValues(alpha: 0.3), width: 1)), child: const Center(child: Text('مقعد فارغ', style: TextStyle(color: Colors.white54, fontSize: 10)))); }

  void _showRoomInfo() { showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => RoomInfoSheet(roomName: controller.roomName, announcement: controller.roomAnnouncement, roomId: controller.roomId, roomCover: controller.roomCoverPath, controller: controller)); }

  void _showGamesSheet() { showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => const GamesSheetWidget()); }

  void _minimizeRoom() { 
    _minimizedController = controller; 
    _minimizedRoomId = controller.roomId; 
    _showMiniPlayerOverlay(); 
    Navigator.of(context).popUntil((route) => route.isFirst); 
  }

  void _showMiniPlayerOverlay() {
    _removeMiniPlayerOverlay();
    _miniPlayerOverlay = OverlayEntry(builder: (context) => Positioned(bottom: 100, right: 16, child: GestureDetector(onTap: () { _removeMiniPlayerOverlay(); Navigator.push(context, MaterialPageRoute(builder: (_) => VoiceRoomScreen(roomId: controller.roomId, roomName: controller.roomName, roomCover: controller.roomCoverPath, isOwner: isOwner))); }, child: _MiniPlayerWidget(roomName: controller.roomName, roomImage: controller.roomCoverPath, onTap: () { _removeMiniPlayerOverlay(); Navigator.push(context, MaterialPageRoute(builder: (_) => VoiceRoomScreen(roomId: controller.roomId, roomName: controller.roomName, roomCover: controller.roomCoverPath, isOwner: isOwner))); }, onClose: () { _removeMiniPlayerOverlay(); _minimizedController = null; }))));
    Overlay.of(context).insert(_miniPlayerOverlay!);
  }

  void _removeMiniPlayerOverlay() { _miniPlayerOverlay?.remove(); _miniPlayerOverlay = null; }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: controller), ChangeNotifierProvider.value(value: giftManager), ChangeNotifierProvider.value(value: giftController)],
      child: Scaffold(
        backgroundColor: Colors.black, resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image(image: _getSafeImage(controller.backgroundPath), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[900])),
            Container(color: Colors.black.withValues(alpha: 0.4)),
            const RocketGlobalBannerOverlay(),
            if (isPkBattleActive) PkHudOverlay(redScore: redTeamScore, blueScore: blueTeamScore, durationMinutes: pkDurationMinutes, onEndBattle: () => mounted ? setState(() => isPkBattleActive = false) : null),
            SafeArea(child: Column(children: [
              _buildHeader(),
              Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(right: 16), child: GestureDetector(onTap: () => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => RoomLeaderboardSheet(roomId: controller.roomId)), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)), child: Consumer<LeaderboardController>(builder: (context, lb, _) { final rank = lb.getRoomUserRankings(controller.roomId); int score = rank.fold(0, (s, i) => s + i.giftScore); return Row(mainAxisSize: MainAxisSize.min, children: [Text('$score', style: const TextStyle(color: Colors.amber, fontSize: 12)), const SizedBox(width: 4), const Icon(Icons.emoji_events, color: Colors.amber, size: 16)]); }))))),
              Expanded(child: Column(children: [
                Container(constraints: const BoxConstraints(maxHeight: 400), child: isPkBattleActive ? _buildPKBattleLayout() : RoomMicGridWidget(seats: controller.visibleSeats, seatReactions: _seatReactions, isCurrentUserOwner: isOwner, onSeatTap: (s) { if (s.userId != null) { showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => UserProfileSheet(userId: s.userId!, nickname: s.userName ?? '', avatarUrl: s.userProfilePic, age: 25, gender: 'male', vipLevel: 0, isHost: isOwner, followers: 0, following: 0, receivedItems: 0, sentItems: 0, bio: '', vipDays: 0)); } else { showExactFiveMicOptions(s); } }, onSeatLongPress: (s) {}, onJoinMic: (i) => controller.joinSeat(i, userName: userController.name, userId: userController.id, userProfilePic: userController.profilePic), onLeaveMic: (i) => controller.kickUserFromSeat(i), onToggleMute: (i) => controller.toggleSeatMute(i), onLockSeat: (i) => controller.toggleSeatLock(i))),
                Expanded(child: RoomChatStreamWidget(messages: controller.messages, scrollController: _chatScrollController, onJoinMic: () {})),
              ])),
              RoomBottomDockWidget(micEnabled: micEnabled, isMuted: isMuted, roomAudioEnabled: roomAudioEnabled, isUserOnMic: controller.allSeats.any((s) => s.userId == userController.id), onMicToggle: _toggleMic, onMuteToggle: () { if (mounted) setState(() => isMuted = !isMuted); controller.toggleUserMute(); }, onAudioToggle: () { if (mounted) setState(() => roomAudioEnabled = !roomAudioEnabled); controller.toggleRoomAudio(); }, onChatTap: _showChatInput, onSettingsTap: showToolBoxSheet, onGiftTap: () => showComprehensiveGiftSheet(context, giftController, (m, t, c) => controller.addMessage(RoomMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), senderName: userController.name, text: "أرسل $m x$c", type: RoomMessageType.gift, senderLevel: userController.currentLevel)), roomId: controller.roomId, roomController: controller), onMessagesTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())), onEmotionsTap: () => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => EmojiPickerWidget(onEmojiSelected: _triggerMicReaction))),
            ])),
            Positioned(left: 16, bottom: 70, child: RoomSideActionsWidget(onRocketTap: () { final rocket = context.read<RocketController>(); showDialog(context: context, builder: (d) => ChangeNotifierProvider.value(value: rocket, child: const SuperPrizeScreen())); })),
            if (_entranceToPlay != null) EntryEffectPlayer(item: _entranceToPlay!, userName: userController.name, onFinished: () => mounted ? setState(() => _entranceToPlay = null) : null),
            Consumer<RocketController>(
              builder: (context, rocketCtrl, _) {
                if (rocketCtrl.isRewardBoxVisible && rocketCtrl.activeRoomId == controller.roomId) {
                  return Positioned(
                    top: 250,
                    right: 20,
                    child: RocketRewardBox(onClaimed: () {}),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      // Left side: Exit, Minimize, Copy Room ID buttons
      Row(children: [
        IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.white, size: 24), onPressed: () => Get.back()),
        IconButton(icon: const Icon(Icons.expand_more, color: Colors.white, size: 24), onPressed: _minimizeRoom),
        IconButton(icon: const Icon(Icons.copy, color: Colors.white, size: 20), onPressed: () {
          Clipboard.setData(ClipboardData(text: controller.roomId));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ معرف الغرفة')));
        }),
      ]),
      const Spacer(),
      // Right side: Room info
      Flexible(
        child: GestureDetector(
          onTap: _showRoomInfo,
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Flexible(child: Text(controller.roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 1)),
              Text('ID:${controller.roomId}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ]),
            const SizedBox(width: 8),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image(image: _getSafeImage(controller.roomCoverPath), width: 35, height: 35, fit: BoxFit.cover)),
          ]),
        ),
      ),
    ]));
  }
}

class _MiniPlayerWidget extends StatelessWidget {
  final String roomName; final String roomImage; final VoidCallback onTap; final VoidCallback onClose;
  const _MiniPlayerWidget({required this.roomName, required this.roomImage, required this.onTap, required this.onClose});
  
  ImageProvider _getSafeImage(String path) {
    if (path.isEmpty) return const AssetImage('assets/Asad/room.jpg');
    if (path.startsWith('data:image/') && path.contains(';base64,')) {
      try {
        final bytes = base64Decode(path.split(',').last);
        return MemoryImage(bytes);
      } catch (e) { return const AssetImage('assets/Asad/room.jpg'); }
    }
    if (path.startsWith('assets/')) return AssetImage(path);
    if (path.startsWith('http')) return NetworkImage(path);
    return const AssetImage('assets/Asad/room.jpg');
  }

  @override
  Widget build(BuildContext context) { return Positioned(bottom: 100, right: 16, child: GestureDetector(onTap: onTap, child: Material(elevation: 8, borderRadius: BorderRadius.circular(30), color: Colors.black87, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(radius: 15, backgroundImage: _getSafeImage(roomImage)), const SizedBox(width: 8), Text(roomName, style: const TextStyle(color: Colors.white, fontSize: 10)), const SizedBox(width: 8), GestureDetector(onTap: onClose, child: const Icon(Icons.close, color: Colors.white54, size: 14))]))))); }
}
