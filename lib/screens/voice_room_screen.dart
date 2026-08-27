import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/room_ui_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/gift_controller.dart';
import '../controllers/gift_manager.dart';
import '../controllers/leaderboard_controller.dart';
import '../controllers/rocket_controller.dart';
import '../controllers/store_controller.dart';
import '../controllers/inventory_controller.dart';
import '../services/agora_service.dart';
import '../services/cloudinary_service.dart';
import '../services/supabase_service.dart';
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
import '../widgets/lucky_gift_banner.dart';
import '../widgets/room/pk_hud_overlay.dart';
import '../widgets/room/pk_battle_sheet.dart';
import '../widgets/rocket_reward_box.dart';
import '../widgets/rocket_global_banner_overlay.dart';
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

  late RoomUiController controller;
  late UserController userController;
  late GiftController giftController;
  late GiftManager giftManager;
  late AgoraService agoraService;
  final ScrollController _chatScrollController = ScrollController();
  final Map<int, String> _seatReactions = {};

  bool micEnabled = false;
  bool isMuted = false;
  bool roomAudioEnabled = true;

  StoreItem? _entranceToPlay;
  String _entrancePlayerName = '';
  final Set<String> _playedEntryEffectIds = {};
  bool _entryEffectsPrimed = false;
  bool _isRoomLocked = false;
  bool _passwordChecked = false;

  bool isPkBattleActive = false;
  String pkMode = '2v2';
  int pkDurationMinutes = 5;
  int redTeamScore = 0;
  int blueTeamScore = 0;

  @override
  void initState() {
    super.initState();
    _removeMiniPlayerOverlay();

    userController = UserController();
    final String currentId = widget.roomId ?? userController.numericId;
    bool isResuming = false;

    if (_minimizedController != null && _minimizedRoomId == currentId) {
      controller = _minimizedController!;
      isResuming = true;
    } else {
      controller = RoomUiController();
    }

    giftController = GiftController();
    giftManager = GiftManager();
    agoraService = AgoraService();

    giftController.preCacheGifts();

    controller.addListener(_refreshUi);
    giftController.addListener(_refreshUi);

    if (!isResuming) {
      controller.init(currentId);
      controller.updateRoomDetails(
        name: widget.roomName ?? controller.roomName,
        id: currentId,
        coverPath: widget.roomCover ?? controller.roomCoverPath,
        ownerId: widget.isOwner ? userController.numericId : null,
      );
    }

    // Initialize Agora audio engine on room join
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await agoraService.initEngine();
      await agoraService.joinRoom(currentId);
      _checkAndPlayEntrance();
    });
  }

  void _checkAndPlayEntrance() {
    final inventory = InventoryController();
    final effectId = inventory.activeEntryEffectId;
    if (effectId != null) {
      final store = StoreController();
      final item = store.items.firstWhere((element) => element.id == effectId, orElse: () => StoreItem(id: '', name: '', imagePath: '', price: 0, type: StoreItemType.entryEffect));
      if (item.id.isNotEmpty) {
        setState(() {
          _entranceToPlay = item;
          _entrancePlayerName = userController.name;
        });
      }
    }
  }

  void _refreshUi() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
    _checkIncomingEntryEffects();
    _checkIncomingGiftAnimations();
    _checkRoomPassword();
  }

  void _checkRoomPassword() {
    if (_passwordChecked || !mounted) return;
    if (!controller.canManageRoom && controller.roomPassword != null && controller.roomPassword!.isNotEmpty) {
      _passwordChecked = true;
      final TextEditingController passCtrl = TextEditingController();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: const Text('الغرفة مقفلة', style: TextStyle(color: Colors.amber, fontFamily: 'Cairo'), textAlign: TextAlign.center),
          content: TextField(
            controller: passCtrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'أدخل كلمة المرور للدخول',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                if (passCtrl.text.trim() == controller.roomPassword) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم الدخول بنجاح')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('كلمة المرور خاطئة')),
                  );
                }
              },
              child: const Text('دخول', style: TextStyle(color: Colors.amber)),
            ),
          ],
        ),
      );
    }
  }

  void _checkIncomingEntryEffects() {
    if (!mounted) return;
    StoreItem? incoming;
    String? incomingName;
    for (final msg in controller.messages) {
      if (msg.type != RoomMessageType.entryEffect) continue;
      if (_playedEntryEffectIds.contains(msg.id)) continue;
      if (msg.senderName == userController.name) continue;
      _playedEntryEffectIds.add(msg.id);
      if (!_entryEffectsPrimed) continue;
      incoming = StoreItem(
        id: 'incoming_${msg.id}',
        name: msg.giftName ?? 'تأثير',
        imagePath: msg.imageUrl ?? '',
        price: 0,
        type: StoreItemType.entryEffect,
      );
      incomingName = msg.senderName;
    }
    _entryEffectsPrimed = true;
    if (incoming != null && incomingName != null) {
      setState(() {
        _entranceToPlay = incoming;
        _entrancePlayerName = incomingName ?? '';
      });
    }
  }

  void _checkIncomingGiftAnimations() {
    if (!mounted) return;
    final pending = controller.pendingGiftAnimations;
    if (pending.isEmpty) return;

    final msg = pending.first;
    controller.consumePendingGiftAnimation();

    GiftItem? matchedGift;
    for (var gift in giftController.gifts) {
      if (gift.name == msg.giftName) {
        matchedGift = gift;
        break;
      }
    }
    if (matchedGift != null && matchedGift.animated) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          giftManager.triggerAnimation(context, matchedGift!, senderName: msg.senderName);
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    if (_minimizedController != controller) {
      controller.removeListener(_refreshUi);
    }
    giftController.removeListener(_refreshUi);
    _chatScrollController.dispose();
    AgoraService().leaveRoom();
    super.dispose();
  }

  ImageProvider _getSafeImage(String path) {
    if (path.isEmpty) return const AssetImage('assets/Asad/room.jpg');
    if (path.startsWith('assets/')) return AssetImage(path);
    if (path.startsWith('http')) return NetworkImage(path);
    if (path.startsWith('data:image')) {
      final String pureBase64 = path.split(',').last;
      return MemoryImage(Uint8List.fromList(base64Decode(pureBase64)));
    }
    return FileImage(File(path));
  }

  void _showChatInput() {
    final TextEditingController textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Color(0xFF16213E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.image, color: Colors.white70, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: textController,
                      autofocus: true,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          controller.sendTextMessage(userController.name, val.trim());
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      final val = textController.text;
                      if (val.trim().isNotEmpty) {
                        controller.sendTextMessage(userController.name, val.trim());
                      }
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 300, maxHeight: 300);
    if (image != null && mounted) {
      try {
        final String url = await CloudinaryService.uploadImage(image, folder: 'chat_images');
        await controller.addMessage('[صورة]', imageUrl: url);
      } catch (e) {
        debugPrint('Error uploading chat image: $e');
        await controller.sendTextMessage(userController.name, '[صورة]');
      }
      if (mounted) Navigator.pop(context);
    }
  }

  void _triggerMicReaction(String emoji) {
    final mySeatIndex = controller.allSeats.indexWhere((s) => s.userId == userController.numericId);
    if (mySeatIndex != -1) {
      final seatIndex = controller.allSeats[mySeatIndex].index;
      setState(() => _seatReactions[seatIndex] = "$emoji|${DateTime.now().millisecondsSinceEpoch}");
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _seatReactions.remove(seatIndex));
      });
    }
  }

  void _showRoomSettings() {
    if (!controller.canManageRoom) return;
    showToolBoxSheet();
  }

  void showToolBoxSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.3),
                    Colors.orange.withOpacity(0.2),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: const Column(
                children: [
                  SizedBox(height: 8),
                  Text(
                    'أدوات الغرفة',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildHexagonalIcon('assets/images/more_music.png', 'الموسيقى', () {
                    Navigator.pop(context);
                    _showMusicPlayer();
                  }),
                  if (controller.isRoomOwner)
                    _buildHexagonalIcon('assets/images/more_lock.png', 'قفل الغرفة', () {
                      Navigator.pop(context);
                      _toggleRoomLock();
                    }),
                  if (controller.isRoomOwner)
                    _buildHexagonalIcon('assets/images/more_msg_clear.png', 'مسح الدردشة', () {
                      controller.clearMessages();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم مسح الدردشة')));
                    }),
                  if (controller.isRoomOwner)
                    _buildHexagonalIcon('assets/images/more_setting.png', 'الإعدادات', () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EditRoomScreen(roomName: controller.roomName, controller: controller)));
                    }),
                  if (controller.isRoomOwner)
                    _buildHexagonalIcon('assets/images/more_theme.png', 'الخلفية', () {
                      Navigator.pop(context);
                      _showBackgroundPicker();
                    }),
                  _buildHexagonalIcon('assets/images/more_effective.png', 'التأثيرات', () {
                    Navigator.pop(context);
                    _showEffectsSheet();
                  }),
                  _buildHexagonalIcon('assets/images/more_shop.png', 'الحقيبة', () {
                    Navigator.pop(context);
                    _showInventorySheet();
                  }),
                  _buildHexagonalIcon('assets/images/more_red.png', 'الحظر والطرود', () {
                    Navigator.pop(context);
                    _showModerationList();
                  }),
                  _buildHexagonalIcon('assets/images/icon_fun_game.png', 'تحدي PK', () {
                    Navigator.pop(context);
                    _showPkBattleSetup();
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHexagonalIcon(String assetPath, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white12,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
            ),
            child: ClipOval(
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.settings, color: Colors.amber, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void showExactFiveMicOptions([MicSeat? seat]) {
    final MicSeat targetSeat = seat ?? controller.allSeats.firstWhere(
      (s) => s.userId == userController.numericId,
      orElse: () => controller.allSeats.firstWhere(
        (s) => s.userName == null || s.userName!.isEmpty,
        orElse: () => controller.allSeats.first,
      ),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MicControlsSheet(
        seat: targetSeat,
        isMe: targetSeat.userId == userController.numericId,
        canManage: controller.canManageRoom,
        isTargetMod: controller.isModerator(targetSeat.userId ?? ''),
        onJoin: (idx) => controller.joinSeat(idx, userName: userController.name, userId: userController.numericId, userProfilePic: userController.profilePic),
        onLeave: (idx) => controller.kickUserFromSeat(idx),
        onToggleMute: (idx) => controller.toggleSeatMute(idx),
        onToggleLock: (idx) => controller.toggleSeatLock(idx),
        onKickToAudience: (idx) => controller.kickUserToAudience(idx),
        onInvite: (idx) => controller.inviteToSeat(idx, userName: userController.name, userId: userController.numericId, userProfilePic: userController.profilePic, uid: SupabaseService.currentUserId ?? ''),
        onBan: (idx) {
          final seat = controller.allSeats[idx - 1];
          if (seat.userId != null) {
            controller.banUser(seat.userId!, seat.userName ?? 'مستخدم');
            controller.kickUserToAudience(idx);
          }
        },
      ),
    );
  }

  void showGamesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const GamesSheetWidget(),
    );
  }

  // MUSIC PLAYER STATE
  final List<Map<String, String>> _musicPlaylist = [];
  int _currentMusicIndex = -1;
  bool _isMusicPlaying = false;

  void _showMusicPlayer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Color(0xFF16213E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 45, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              const Text('مشغل الموسيقى', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Now Playing
              if (_currentMusicIndex >= 0 && _currentMusicIndex < _musicPlaylist.length)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_isMusicPlaying ? Icons.music_note : Icons.music_off, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_musicPlaylist[_currentMusicIndex]['name'] ?? 'موسيقى',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('جاري التشغيل...', style: TextStyle(color: Colors.amber.withValues(alpha: 0.7), fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isMusicPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.amber, size: 36),
                        onPressed: () {
                          setSheetState(() => _isMusicPlaying = !_isMusicPlaying);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Pick from device button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final file = await FilePicker.platform.pickFiles(type: FileType.audio);
                        if (file != null && file.files.isNotEmpty) {
                          final name = file.files.first.name;
                          final path = file.files.first.path ?? '';
                          setSheetState(() {
                            _musicPlaylist.add({'name': name, 'path': path});
                          });
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت إضافة: $name')));
                        }
                      } catch (e) {
                        debugPrint('Error picking audio: $e');
                      }
                    },
                    icon: const Icon(Icons.folder_open, color: Colors.black),
                    label: const Text('اختيار من الجهاز', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Playlist
              Expanded(
                child: _musicPlaylist.isEmpty
                    ? const Center(child: Text('لا توجد موسيقى بعد\nاضغط "اختيار من الجهاز" لإضافة', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontFamily: 'Cairo')))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _musicPlaylist.length,
                        itemBuilder: (context, index) {
                          final item = _musicPlaylist[index];
                          final isPlaying = index == _currentMusicIndex;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isPlaying ? Colors.amber.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: isPlaying ? Border.all(color: Colors.amber.withValues(alpha: 0.3)) : null,
                            ),
                            child: ListTile(
                              leading: Icon(isPlaying ? Icons.music_note : Icons.audiotrack, color: isPlaying ? Colors.amber : Colors.white54),
                              title: Text(item['name'] ?? '', style: TextStyle(color: isPlaying ? Colors.amber : Colors.white, fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(isPlaying && _isMusicPlaying ? Icons.pause : Icons.play_arrow, color: Colors.amber),
                                    onPressed: () {
                                      setSheetState(() {
                                        _currentMusicIndex = index;
                                        _isMusicPlaying = true;
                                      });
                                      setState(() {});
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setSheetState(() {
                                        if (index == _currentMusicIndex) {
                                          _currentMusicIndex = -1;
                                          _isMusicPlaying = false;
                                        } else if (index < _currentMusicIndex) {
                                          _currentMusicIndex--;
                                        }
                                        _musicPlaylist.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleRoomLock() {
    final TextEditingController passController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          controller.roomPassword != null && controller.roomPassword!.isNotEmpty
              ? 'فتح الغرفة'
              : 'قفل الغرفة بكلمة مرور',
          style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
          textAlign: TextAlign.center,
        ),
        content: controller.roomPassword != null && controller.roomPassword!.isNotEmpty
            ? const Text('هل تريد فتح الغرفة وإزالة كلمة المرور؟',
                style: TextStyle(color: Colors.white70, fontFamily: 'Cairo'))
            : TextField(
                controller: passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'أدخل كلمة المرور',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (controller.roomPassword != null && controller.roomPassword!.isNotEmpty) {
                await controller.onUnLockRoomWithPassword();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم فتح الغرفة')),
                  );
                }
              } else if (passController.text.trim().isNotEmpty) {
                await controller.onLockRoomWithPassword(passController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم قفل الغرفة بكلمة المرور')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('أدخل كلمة مرور')),
                  );
                }
              }
            },
            child: const Text('تأكيد', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _showBackgroundPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('اختر الخلفية', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: List.generate(6, (index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير الخلفية')));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Icon(Icons.image, color: Colors.white70)),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEffectsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('التأثيرات', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _effectItem('تأثير الدخول VIP', Icons.stars),
                  _effectItem('تأثير الغرفة', Icons.home),
                  _effectItem('تأثير الميكروفون', Icons.mic),
                  _effectItem('تأثير السحب', Icons.card_giftcard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _effectItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تفعيل $title')));
      },
    );
  }

  void _showInventorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 500,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('الحقيبة', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: List.generate(9, (index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.backpack, color: Colors.amber, size: 40),
                        const SizedBox(height: 8),
                        Text('عنصر ${index + 1}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('x${(index + 1) * 5}', style: const TextStyle(color: Colors.amber, fontSize: 10)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModerationList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('قائمة الحظر', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: controller.bannedUsers.isEmpty
                  ? const Center(child: Text('لا يوجد مستخدمين محظورين', style: TextStyle(color: Colors.white38, fontFamily: 'Cairo')))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.bannedUsers.length,
                      itemBuilder: (context, index) {
                        final banned = controller.bannedUsers[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Icon(Icons.person_off, color: Colors.white),
                          ),
                          title: Text(banned['user_name'] ?? 'مستخدم', style: const TextStyle(color: Colors.white)),
                          subtitle: const Text('محظور', style: TextStyle(color: Colors.red)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await controller.unbanUser(banned['user_id'] ?? '');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم إلغاء الحظر')),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPkBattleSetup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PKBattleSheet(
        onStartPK: (mode, duration) {
          setState(() {
            isPkBattleActive = true;
            pkMode = mode;
            pkDurationMinutes = duration;
            redTeamScore = 0;
            blueTeamScore = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('بدأت معركة $mode لمدة $duration دقائق')),
          );
        },
      ),
    );
  }

  Widget _buildPKBattleLayout() {
    final seatsPerTeam = pkMode == '2v2' ? 2 : 4;
    final allSeats = controller.visibleSeats;
    
    final redTeamSeats = allSeats.take(seatsPerTeam).toList();
    final blueTeamSeats = allSeats.skip(seatsPerTeam).take(seatsPerTeam).toList();
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    isPkBattleActive = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إيقاف التحدي')),
                  );
                },
                child: const Text(
                  'إيقاف التحدي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        'الفريق الأحمر',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(seatsPerTeam, (index) {
                    if (index < redTeamSeats.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: _buildPKSeat(redTeamSeats[index], Colors.red),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: _buildEmptyPKSeat(Colors.red),
                    );
                  }),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/icon_pk.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        'الفريق الأزرق',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(seatsPerTeam, (index) {
                    if (index < blueTeamSeats.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: _buildPKSeat(blueTeamSeats[index], Colors.blue),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: _buildEmptyPKSeat(Colors.blue),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
      ),
    );
  }

  Widget _buildPKSeat(MicSeat seat, Color teamColor) {
    return GestureDetector(
      onTap: () {
        if (seat.userId != null && seat.userId!.isNotEmpty) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) => UserProfileSheet(
                userId: seat.userId ?? '',
                nickname: seat.userName ?? 'مستخدم',
                avatarUrl: seat.userProfilePic,
                age: 25,
                gender: 'male',
                vipLevel: userController.vipLevel,
                isHost: widget.isOwner,
                followers: 100,
                following: 50,
                receivedItems: 20,
                sentItems: 15,
                bio: 'هذا هو النص التعريفي للمستخدم',
                vipDays: 30,
                authUid: seat.uid,
              ),
            ),
          );
        }
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: teamColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: teamColor, width: 1.5),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundImage: _getSafeImage(seat.userProfilePic ?? ''),
              backgroundColor: Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seat.userName ?? 'مقعد فارغ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (seat.isMuted)
                    const Icon(
                      Icons.mic_off,
                      color: Colors.red,
                      size: 16,
                    ),
                ],
              ),
            ),
            if (seat.userId != null && seat.userId!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  seat.isMuted ? Icons.mic_off : Icons.mic,
                  color: seat.isMuted ? Colors.red : teamColor,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPKSeat(Color teamColor) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teamColor.withOpacity(0.3), width: 1),
      ),
      child: const Center(
        child: Text(
          'مقعد فارغ',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF16213E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('مشاركة الغرفة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareItem('فيسبوك', Icons.facebook, Colors.blue),
                _shareItem('واتساب', Icons.chat, Colors.green),
                _shareItem('تليجرام', Icons.send, Colors.lightBlue),
                _shareItem('تويتر', Icons.close, Colors.black),
                _shareItem('رابط', Icons.link, Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _shareItem(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مشاركة عبر $label')));
        Navigator.pop(context);
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  void _showAudienceList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF16213E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("المتواجدون في الغرفة", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: controller.participants.length,
                itemBuilder: (context, index) {
                  final p = controller.participants[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: _getSafeImage(p.profilePic),
                    ),
                    title: Text(p.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('ID: ${p.userId}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                      child: Text('Lv.${p.level}', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showProfileSheet(authUid: p.uid, userId: p.userId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet({required String authUid, String userId = ''}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => UserProfileSheet(
          userId: userId,
          nickname: '',
          age: 0,
          gender: 'male',
          vipLevel: 0,
          followers: 0,
          following: 0,
          receivedItems: 0,
          sentItems: 0,
          vipDays: 0,
          authUid: authUid,
        ),
      ),
    );
  }

  void _showRoomInfo() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => RoomInfoSheet(
          roomName: controller.roomName,
          announcement: controller.roomAnnouncement,
          roomId: controller.roomId,
          roomCover: controller.roomCoverPath,
          controller: controller,
        )
    );
  }

  void _minimizeRoom() {
    Navigator.pop(context);
    _minimizedController = controller;
    _minimizedRoomId = widget.roomId ?? userController.numericId;
    _showMiniPlayerOverlay();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _exitRoom() {
    giftManager.clearAnimation();
    setState(() {
      _entranceToPlay = null;
    });
    AgoraService().leaveRoom();
    controller.leaveRoom();
    Navigator.pop(context);
    _minimizedController = null;
    _minimizedRoomId = null;
    _removeMiniPlayerOverlay();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showMiniPlayerOverlay() {
    _removeMiniPlayerOverlay();
    final OverlayState? overlayState = Overlay.of(context, rootOverlay: true);
    if (overlayState == null) return;

    _miniPlayerOverlay = OverlayEntry(
      builder: (context) => _MiniPlayerWidget(
        roomName: controller.roomName,
        roomImage: controller.roomCoverPath,
        onTap: () {
          _removeMiniPlayerOverlay();
          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
              builder: (_) => VoiceRoomScreen(
                  roomName: controller.roomName,
                  roomId: controller.roomId,
                  roomCover: controller.roomCoverPath,
                  isOwner: widget.isOwner
              )
          ));
        },
        onClose: () {
          _removeMiniPlayerOverlay();
          _minimizedController = null;
        },
      ),
    );
    overlayState.insert(_miniPlayerOverlay!);
  }

  void _removeMiniPlayerOverlay() {
    _miniPlayerOverlay?.remove();
    _miniPlayerOverlay = null;
  }

  void _handleExit() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF16213E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('خروج من الغرفة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _minimizeRoom,
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Image.asset(
                          'assets/Asad/room_mini.png',
                          width: 35,
                          height: 35,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.minimize_rounded, color: Colors.blue, size: 35),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('احتفاظ وخروج', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _exitRoom,
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Image.asset(
                          'assets/Asad/room_exit.png',
                          width: 35,
                          height: 35,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.logout_rounded, color: Colors.red, size: 35),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('خروج نهائي', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: controller),
        ChangeNotifierProvider.value(value: giftManager),
        ChangeNotifierProvider.value(value: giftController),
      ],
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image(image: _getSafeImage(controller.backgroundPath), fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(0.4)),

            const LuckyGiftBanner(),
            const RocketGlobalBannerOverlay(),

            if (isPkBattleActive)
              PkHudOverlay(
                redScore: redTeamScore,
                blueScore: blueTeamScore,
                durationMinutes: pkDurationMinutes,
                onEndBattle: () {
                  setState(() {
                    isPkBattleActive = false;
                  });
                },
              ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 6),

                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) => RoomLeaderboardSheet(roomId: controller.roomId)
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withOpacity(0.4), width: 0.8),
                            ),
                            child: Consumer<LeaderboardController>(
                              builder: (context, lb, _) {
                                final rankings = lb.getRoomUserRankings(controller.roomId);
                                int totalPoints = rankings.fold(0, (sum, item) => sum + item.giftScore);
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(totalPoints > 0 ? totalPoints.toString() : '105880', style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                    const SizedBox(width: 6),
                                    Image.asset('assets/Asad/icon_room_rank.png', width: 18, height: 18, fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18)),
                                  ],
                                );
                              }
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10.0),

                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.60,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: isPkBattleActive
                                  ? _buildPKBattleLayout()
                                  : RoomMicGridWidget(
                                      seats: controller.visibleSeats,
                                      seatReactions: _seatReactions,
                                      isCurrentUserOwner: widget.isOwner,
                                      isCurrentUserAdmin: controller.canManageRoom,
                                      onSeatTap: (s) {
                                        final bool isOwnSeat = s.userId == userController.numericId;
                                        final bool canManage = controller.canManageRoom;
                                        final bool isSeatLocked = s.isLocked;

                                        if (isSeatLocked && !canManage) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('المقعد مغلق', textAlign: TextAlign.center),
                                              backgroundColor: Colors.redAccent,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          return;
                                        }

                                        if (s.userId != null && s.userId!.isNotEmpty && !isOwnSeat && !canManage) {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => DraggableScrollableSheet(
                                              initialChildSize: 0.9,
                                              minChildSize: 0.5,
                                              maxChildSize: 0.95,
                                              builder: (context, scrollController) => UserProfileSheet(
                                                userId: s.userId ?? '',
                                                nickname: s.userName ?? 'مستخدم',
                                                avatarUrl: s.userProfilePic,
                                                authUid: s.uid,
                                                age: 25,
                                                gender: 'male',
                                                vipLevel: userController.vipLevel,
                                                isHost: widget.isOwner,
                                                followers: 100,
                                                following: 50,
                                                receivedItems: 20,
                                                sentItems: 15,
                                                bio: 'هذا هو النص التعريفي للمستخدم',
                                                vipDays: 30,
                                              ),
                                            ),
                                          );
                                        } else if (s.userId != null && s.userId!.isNotEmpty && !isOwnSeat && canManage) {
                                          showExactFiveMicOptions(s);
                                        } else {
                                          showExactFiveMicOptions(s);
                                        }
                                      },
                                      onSeatLongPress: (s) {},
                                      onJoinMic: (i) => controller.joinSeat(i, userName: userController.name, userId: userController.numericId, userProfilePic: userController.profilePic),
                                      onLeaveMic: (i) => controller.kickUserFromSeat(i),
                                      onToggleMute: (i) => controller.toggleSeatMute(i),
                                      onLockSeat: (i) => controller.toggleSeatLock(i),
                                    ),
                            ),
                          ),

                          Flexible(
                            flex: 2,
                            child: RoomChatStreamWidget(
                              messages: controller.messages,
                              scrollController: _chatScrollController,
                              onJoinMic: () {},
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RoomBottomDockWidget(
                micEnabled: micEnabled,
                isMuted: isMuted,
                roomAudioEnabled: roomAudioEnabled,
                isUserOnMic: controller.allSeats.any((s) => s.userId == userController.numericId),
                canManageRoom: controller.canManageRoom,
                onMicToggle: () => showExactFiveMicOptions(),
                onMuteToggle: () {
                  setState(() => isMuted = !isMuted);
                  controller.toggleUserMute();
                },
                onAudioToggle: () {
                  setState(() => roomAudioEnabled = !roomAudioEnabled);
                  controller.toggleRoomAudio();
                },
                onChatTap: _showChatInput,
                onSettingsTap: _showRoomSettings,
                onGiftTap: () => showComprehensiveGiftSheet(
                  context, 
                  giftController, 
                  (msg, target, combo) {
                    controller.addMessage(
                      'أرسل $msg x$combo',
                      giftName: msg,
                      giftCount: combo,
                      targetName: target > 0 ? 'المقعد $target' : 'الجميع',
                    );
                  }, 
                  roomId: controller.roomId,
                  roomController: controller,
                ),
                onMessagesTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
                },
                onEmotionsTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => EmojiPickerWidget(onEmojiSelected: _triggerMicReaction)
                ),
              ),
            ),

            Positioned(
                left: 16,
                bottom: 70,
                child: RoomSideActionsWidget(
                  onRocketTap: () {
                    final rocketController = context.read<RocketController>();
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierColor: Colors.transparent,
                      useSafeArea: false,
                      builder: (dialogContext) => ChangeNotifierProvider.value(
                        value: rocketController,
                        child: const SuperPrizeScreen(),
                      ),
                    );
                  },
                  onGamesTap: () => showGamesModal(context),
                )
            ),

            if (_entranceToPlay != null)
              Positioned.fill(
                child: EntryEffectPlayer(
                  item: _entranceToPlay!,
                  userName: _entrancePlayerName,
                  onFinished: () {
                    if (mounted) setState(() => _entranceToPlay = null);
                  },
                ),
              ),

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

            Consumer<GiftController>(
              builder: (context, gCtrl, _) {
                if (gCtrl.comboCount == 0 || gCtrl.lastTappedGift == null) return const SizedBox.shrink();
                return Positioned(
                  right: 16,
                  bottom: 120,
                  child: GestureDetector(
                    onTap: () async {
                      final item = gCtrl.lastTappedGift!;
                      gCtrl.tapCombo(item);
                      String? receiverId;
                      String? receiverName;
                      if (gCtrl.targetSeats.isNotEmpty) {
                        final targetIdx = gCtrl.targetSeats.first;
                        final seat = controller.allSeats.where((s) => s.index == targetIdx).toList();
                        if (seat.isNotEmpty && seat.first.uid != null) {
                          receiverId = seat.first.uid;
                          receiverName = seat.first.userName;
                        }
                      }
                      final res = await gCtrl.sendGift(item, roomId: controller.roomId, roomName: controller.roomName, roomPhoto: controller.roomCoverPath, receiverId: receiverId, receiverName: receiverName);
                      if (res['ok']) {
                        final target = gCtrl.targetSeats.length == 1 ? gCtrl.targetSeats.first : 0;
                        controller.addMessage(
                          'أرسل ${item.name} x${gCtrl.comboCount}',
                          giftName: item.name,
                          giftCount: gCtrl.comboCount,
                          targetName: target > 0 ? 'المقعد $target' : 'الجميع',
                        );
                        giftManager.triggerAnimation(context, item, comboCount: gCtrl.comboCount);
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 70, height: 70,
                          child: CircularProgressIndicator(
                            value: gCtrl.comboProgress,
                            strokeWidth: 4,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                          ),
                        ),
                        Container(
                          width: 60, height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [Colors.orange, Colors.amber]),
                            boxShadow: [BoxShadow(color: Colors.amberAccent, blurRadius: 10)],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Combo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                              Text('x${gCtrl.comboCount}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 16, top: 10, bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _handleExit,
                      child: Image.asset('assets/Asad/room_exit.png', width: 24, height: 24, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 24))
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showShareOptions,
                    child: Image.asset('assets/Asad/room_share.png', width: 20, height: 20, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.ios_share_rounded, color: Colors.white, size: 20)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _showAudienceList,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                          '${controller.onlineUsersCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showRoomInfo,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.3)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withOpacity(0.4), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('31.6K', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                const SizedBox(width: 4),
                                Image.asset('assets/Asad/vip_coin.png', width: 12, height: 12, fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.workspace_premium, color: Colors.amber, size: 10)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                                controller.roomName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo')
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('ID:${controller.roomId}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Cairo')),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                      image: _getSafeImage(controller.roomCoverPath),
                      width: 40, height: 40, fit: BoxFit.cover
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPlayerWidget extends StatelessWidget {
  final String roomName;
  final String roomImage;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _MiniPlayerWidget({
    required this.roomName,
    required this.roomImage,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: GestureDetector(
        onTap: onTap,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(30),
          color: Colors.black87,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 18, backgroundImage: RoomUiController.getSafeImageProvider(roomImage)),
                const SizedBox(width: 10),
                Text(roomName, style: const TextStyle(color: Colors.white, fontSize: 12)),
                const SizedBox(width: 8),
                GestureDetector(onTap: onClose, child: const Icon(Icons.close, color: Colors.white54, size: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void audienceMemberSheet(
    BuildContext context, {
      required Map<String, dynamic> user,
      required List<MicSeat> emptySeats,
      required void Function(String, int) onPullToSeat,
      required void Function(String) onInvite,
    }) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: RoomUiController.getSafeImageProvider(user['avatar']),
          ),
          const SizedBox(height: 16),
          Text(
            user['name'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  onInvite(user['id'] ?? '');
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.mic, size: 20),
                label: const Text('دعوة للمايك'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              if (emptySeats.isNotEmpty)
                PopupMenuButton<int>(
                  onSelected: (seatIndex) {
                    onPullToSeat(user['id'] ?? '', seatIndex);
                    Navigator.pop(context);
                  },
                  itemBuilder: (context) => emptySeats
                      .map((seat) => PopupMenuItem<int>(
                    value: seat.index,
                    child: Text('مقعد ${seat.index}', style: const TextStyle(color: Colors.white)),
                  ))
                      .toList(),
                  color: const Color(0xFF1A1A2E),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.airline_seat_recline_extra, size: 20, color: Colors.black),
                        SizedBox(width: 8),
                        Text('سحب للمقعد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
