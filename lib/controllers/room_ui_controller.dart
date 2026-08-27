import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mic_seat.dart';
import '../services/supabase_service.dart';
import 'user_controller.dart';
import '../services/agora_service.dart';
import 'inventory_controller.dart';
import 'store_controller.dart';

enum RoomMessageType { text, system, gift, image, entryEffect }

class RoomMessage {
  final String id;
  final String senderName;
  final String text;
  final RoomMessageType type;
  final String? targetName;
  final String? giftName;
  final int? giftCount;
  final int senderLevel;
  final String? imageUrl;

  RoomMessage({
    required this.id,
    required this.senderName,
    required this.text,
    this.type = RoomMessageType.text,
    this.targetName,
    this.giftName,
    this.giftCount,
    this.senderLevel = 1,
    this.imageUrl,
  });
}

class ParticipantInfo {
  final String uid;
  final String userId;
  final String name;
  final String profilePic;
  final int level;

  ParticipantInfo({
    required this.uid,
    required this.userId,
    required this.name,
    required this.profilePic,
    required this.level,
  });

  factory ParticipantInfo.fromRow(Map<String, dynamic> row) {
    return ParticipantInfo(
      uid: (row['uid'] ?? '').toString(),
      userId: (row['user_id'] ?? '').toString(),
      name: (row['name'] ?? '').toString(),
      profilePic: (row['profile_pic'] ?? '').toString(),
      level: (row['level'] ?? 1) as int,
    );
  }
}

class RoomUiController extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;
  final AgoraService _agoraService = AgoraService();
  StreamSubscription? _roomSubscription;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _participantsSubscription;
  RealtimeChannel? _presenceChannel;

  // Room Details
  String roomId = '';
  String roomName = 'غرفة الدردشة';
  String roomAnnouncement = 'أهلاً بالجميع في غرفتنا المتواضعة';
  String roomCoverPath = 'assets/Asad/room.jpg';
  int activeMicCount = 20; 
  String backgroundPath = 'assets/Asad/bg_room.png';
  String ownerId = ''; 
  String? roomPassword;
  
  String roomCategory = 'عام';
  List<String> _moderators = [];
  List<String> get moderators => List.unmodifiable(_moderators);
  bool roomLocked = false;
  String status = 'active';

  bool isChatEnabled = true;
  bool allMicsMuted = false; 
  bool isUserMicEnabled = true; 
  bool isUserMuted = false; 
  bool isRoomAudioEnabled = true; 

  bool _isDisposed = false;

  // OWNER VS VISITOR ROLE DETECTION: Check if current user is room owner
  bool get isRoomOwner {
    final userController = UserController();
    return userController.numericId == roomId;
  }

  bool isModerator(String userId) => _moderators.contains(userId);

  bool get canManageRoom {
    final currentUserId = UserController().numericId;
    return isRoomOwner || isModerator(currentUserId);
  }

  /// Check if a target user can be managed (kicked/muted) by the current user.
  /// Owner is immune from everyone. Mods are immune from other mods.
  bool canManageTarget(String targetUserId) {
    if (isRoomOwner) return true;
    if (isModerator(UserController().numericId)) {
      return !isModerator(targetUserId);
    }
    return false;
  }

  final List<RoomMessage> _messages = [];
  List<RoomMessage> get messages => List.unmodifiable(_messages);

  final List<RoomMessage> _pendingGiftAnimations = [];
  List<RoomMessage> get pendingGiftAnimations => List.unmodifiable(_pendingGiftAnimations);
  void consumePendingGiftAnimation() {
    if (_pendingGiftAnimations.isNotEmpty) {
      _pendingGiftAnimations.removeAt(0);
    }
  }

  final List<ParticipantInfo> _participants = [];
  List<ParticipantInfo> get participants => List.unmodifiable(_participants);

  final Map<String, String> _userAvatarFrames = {};
  Map<String, String> get userAvatarFrames => Map.unmodifiable(_userAvatarFrames);

  final List<MicSeat> _allSeats = List.generate(
    20,
    (i) => MicSeat(
      index: i + 1,
    ),
  );
  List<MicSeat> get allSeats => _allSeats;

  int _visibleSeatsCount = 20;
  int get visibleSeatsCount => _visibleSeatsCount;
  set visibleSeatsCount(int value) {
    _visibleSeatsCount = value;
    safeNotify();
  }

  List<MicSeat> get visibleSeats => _allSeats.take(activeMicCount).toList();

  int onlineUsersCount = 0;

  List<Color> get vipColors => [const Color(0xFFFFD700), const Color(0xFFFFA500)];

  RoomUiController() {
    debugPrint('Initializing: RoomUiController');
  }

  void init(String id) {
    if (id.isEmpty) return;
    roomId = id;
    _listenToRoom();
    _listenToMessages();
    _listenToParticipants();
    _listenToBans();
    _joinParticipantsCollection();
    _setupPresence();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _roomSubscription?.cancel();
    _messageSubscription?.cancel();
    _participantsSubscription?.cancel();
    _bansSubscription?.cancel();
    _presenceChannel?.unsubscribe();
    super.dispose();
  }

  void _listenToRoom() async {
    _roomSubscription?.cancel();
    await SupabaseService.ensureValidSession();
    _roomSubscription = _client
        .from('rooms')
        .stream(primaryKey: ['room_id'])
        .eq('room_id', roomId)
        .listen((rows) {
      if (rows.isNotEmpty) {
        final data = rows.first;
        roomName = data['room_name'] ?? roomName;
        roomAnnouncement = data['description'] ?? roomAnnouncement;
        roomCoverPath = data['room_cover'] ?? roomCoverPath;
        ownerId = data['owner_id'] ?? ownerId;
        activeMicCount = (data['active_mic_count'] as num?)?.toInt() ?? activeMicCount;
        roomCategory = data['category'] ?? roomCategory;
        status = data['status'] ?? 'active';
        roomPassword = data['room_password'];

        final modsRaw = data['moderators'];
        if (modsRaw is List) {
          _moderators = modsRaw.map((e) => e.toString()).toList();
        }

         if (data['mic_seats'] != null) {
          final Map<String, dynamic> seatsData = Map<String, dynamic>.from(data['mic_seats'] as Map);
          for (int i = 0; i < 20; i++) {
             final seatValue = seatsData[i.toString()];
             if (seatValue != null) {
               final seatAgoraUid = (seatValue['agoraUid'] as num?)?.toInt();
               final seatSupabaseUid = (seatValue['uid'] ?? '').toString();
               if (seatAgoraUid != null && seatSupabaseUid.isNotEmpty) {
                 _agoraService.registerUserMapping(seatAgoraUid, seatSupabaseUid);
               }
               final bool hasUser = seatSupabaseUid.isNotEmpty;
               final bool dbLocked = seatValue['isLocked'] ?? false;
               _allSeats[i] = MicSeat(
                 index: i + 1,
                 userName: seatValue['userName'],
                 userId: seatValue['userId'],
                 uid: seatValue['uid'],
                 userProfilePic: seatValue['userProfilePic'],
                 avatarFrame: seatValue['avatarFrame'],
                 userLevel: (seatValue['userLevel'] as num?)?.toInt() ?? 1,
                 isMuted: seatValue['isMuted'] ?? false,
                 isLocked: hasUser ? dbLocked : (i >= activeMicCount),
               );
             } else {
               _allSeats[i] = MicSeat(
                 index: i + 1,
                 isLocked: i >= activeMicCount,
               );
             }
          }
          _syncAgoraMute(seatsData);
        }
        safeNotify();
      }
    });
  }

  bool _messagesInitialized = false;

  void _listenToMessages() {
    _messageSubscription?.cancel();
    final knownIds = <String>{};
    _messagesInitialized = false;
    _messageSubscription = _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .limit(50)
        .listen((rows) {
      _messages.clear();
      for (var row in rows) {
        final msg = RoomMessage(
          id: row['id'].toString(),
          senderName: (row['sender_name'] ?? '').toString(),
          text: (row['text'] ?? '').toString(),
          type: RoomMessageType.values.firstWhere((e) => e.name == (row['type'] ?? 'text'), orElse: () => RoomMessageType.text),
          senderLevel: (row['sender_level'] as num?)?.toInt() ?? 1,
          imageUrl: row['image_url'],
          giftName: row['gift_name']?.toString(),
        );
        _messages.add(msg);
        if (!_messagesInitialized) {
          knownIds.add(msg.id);
        } else if (msg.type == RoomMessageType.gift && !knownIds.contains(msg.id) && msg.senderName != UserController().name) {
          _pendingGiftAnimations.add(msg);
        }
      }
      _messagesInitialized = true;
      knownIds.addAll(rows.map((r) => r['id'].toString()));
      safeNotify();
    });
  }

  void _listenToParticipants() {
    _participantsSubscription?.cancel();
    _participantsSubscription = _client
        .from('participants')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .listen((rows) {
      _participants.clear();
      for (var row in rows) {
        _participants.add(ParticipantInfo.fromRow(row));
      }
      onlineUsersCount = _participants.length;
      
      // REAL-TIME PRESENCE: Keep room participant count synced
      _client.from('rooms').update({
        'participant_count': onlineUsersCount
      }).eq('room_id', roomId).then((_) {}).catchError((_) {});
      
      safeNotify();
    });
  }

  Future<void> _joinParticipantsCollection() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    final userController = UserController();

    // BAN CHECK: Don't let banned users rejoin
    if (isUserBanned(userController.numericId)) {
      await sendSystemMessage('تم حظر هذا المستخدم من الغرفة');
      return;
    }

    // REAL-TIME PRESENCE: Add user info to room participants table
    await _client.from('participants').upsert({
      'room_id': roomId,
      'uid': uid,
      'user_id': userController.numericId,
      'name': userController.name,
      'profile_pic': userController.profilePic,
      'level': userController.currentLevel,
      'joined_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'room_id,uid');

    await sendSystemMessage('${userController.name} انضم إلى الغرفة');

    // ENTRY EFFECT BROADCAST: Everyone in the room sees the effect + name
    final effectId = InventoryController().activeEntryEffectId;
    if (effectId != null && effectId.isNotEmpty) {
      final effects = StoreController()
          .items
          .where((e) => e.id == effectId)
          .toList();
      if (effects.isNotEmpty) {
        await _client.from('messages').insert({
          'room_id': roomId,
          'sender_name': userController.name,
          'text': '${userController.name} دخل الغرفة',
          'type': RoomMessageType.entryEffect.name,
          'sender_level': userController.currentLevel,
          'gift_name': effects.first.name,
          'image_url': effects.first.imagePath,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    }
  }

  // --- REAL-TIME PRESENCE ---
  // Tracks every connected client in the room. When a client leaves the app
  // (logout, kill, network loss) or the room, its presence disappears, which
  // lets the remaining clients remove it from the participant list, free its
  // mic seat, and show a "خرج من الغرفة" notification.
  Future<void> _setupPresence() async {
    final currentUid = SupabaseService.currentUserId;
    if (currentUid == null || roomId.isEmpty) return;

    await SupabaseService.ensureValidSession();
    _presenceChannel?.unsubscribe();
    _presenceChannel = _client.channel('presence:room_$roomId');

    _presenceChannel
        ?.onPresenceLeave((payload) {
          for (final presence in payload.leftPresences) {
            final data = presence.payload;
            final leavingUid = (data['uid'] ?? '').toString();
            if (leavingUid.isEmpty || leavingUid == currentUid) continue;

            // Multi-device guard: keep the user if another presence remains.
            final stillPresent = _presenceChannel?.presenceState().any(
                  (state) => state.presences.any(
                    (p) => (p.payload['uid'] ?? '').toString() == leavingUid,
                  ),
                ) ??
                false;
            if (stillPresent) continue;

            _cleanupLeftUser(leavingUid, (data['name'] ?? '').toString());
          }
        })
        .onPresenceSync((_) {
          final presentUids = _presenceChannel?.presenceState().expand(
                (state) => state.presences,
              ).map((p) => (p.payload['uid'] ?? '').toString()).toSet() ??
              <String>{};
          presentUids.add(currentUid);
          _cleanupAbsentUsers(presentUids);
        });

    _presenceChannel?.subscribe();
    await _presenceChannel?.track({
      'uid': currentUid,
      'userId': UserController().numericId,
      'name': UserController().name,
      'profilePic': UserController().profilePic,
      'level': UserController().currentLevel,
    });
  }

  /// Called when a connected client disconnects: removes them from the
  /// participant list, frees their mic seat, and broadcasts the exit message.
  Future<void> _cleanupLeftUser(String leavingUid, String leavingName) async {
    try {
      await _client
          .from('participants')
          .delete()
          .eq('room_id', roomId)
          .eq('uid', leavingUid);
    } catch (_) {}

    try {
      final seats = await _getMicSeats();
      final keysToRemove = seats.keys.where((k) {
        final v = seats[k];
        return v is Map && (v['uid'] ?? '').toString() == leavingUid;
      }).toList();
      if (keysToRemove.isNotEmpty) {
        for (final key in keysToRemove) {
          seats.remove(key);
        }
        await _saveMicSeats(seats);
      }
    } catch (_) {}

    if (leavingName.isNotEmpty) {
      await sendSystemMessage('$leavingName خرج من الغرفة');
    }
  }

  /// Removes participants / mic seats whose uid has no live presence.
  /// This clears stale accounts that were left behind by old sessions.
  Future<void> _cleanupAbsentUsers(Set<String> presentUids) async {
    try {
      final rows = await _client
          .from('participants')
          .select('id,uid')
          .eq('room_id', roomId);
      for (final row in rows) {
        if (!presentUids.contains((row['uid'] ?? '').toString())) {
          await _client.from('participants').delete().eq('id', row['id']);
        }
      }
    } catch (_) {}

    try {
      final seats = await _getMicSeats();
      final keysToRemove = seats.keys.where((k) {
        final v = seats[k];
        return v is Map && !presentUids.contains((v['uid'] ?? '').toString());
      }).toList();
      if (keysToRemove.isNotEmpty) {
        for (final key in keysToRemove) {
          seats.remove(key);
        }
        await _saveMicSeats(seats);
      }
    } catch (_) {}
  }

  void safeNotify() {
    if (_isDisposed) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _getMicSeats() async {
    final row = await _client
        .from('rooms')
        .select('mic_seats')
        .eq('room_id', roomId)
        .maybeSingle();
    final raw = row?['mic_seats'];
    if (raw == null) return {};
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<void> _saveMicSeats(Map<String, dynamic> seats) async {
    await _client
        .from('rooms')
        .update({'mic_seats': seats})
        .eq('room_id', roomId);
  }

  // AGORA SAFETY: Whenever the seat list changes (including updates pushed by
  // other clients, e.g. an admin kicking this user off the mic or muting them),
  // make sure the microphone is muted when the current user is no longer seated
  // or is muted on their seat.
  Future<void> _syncAgoraMute(Map<String, dynamic> seatsData) async {
    final currentUid = SupabaseService.currentUserId;
    if (currentUid == null) return;

    String? mySeatKey;
    bool iAmMuted = false;

    for (final entry in seatsData.entries) {
      final v = entry.value;
      if (v is Map && (v['uid'] ?? '').toString() == currentUid) {
        mySeatKey = entry.key;
        iAmMuted = v['isMuted'] == true;
        break;
      }
    }

    if (mySeatKey == null) {
      await _agoraService.setMute(true);
    } else if (iAmMuted) {
      await _agoraService.setMute(true);
    } else {
      await _agoraService.setMute(false);
    }

    // Mute/unmute remote users whose seats are muted/locked
    for (final entry in seatsData.entries) {
      final v = entry.value;
      if (v is Map) {
        final seatUid = (v['uid'] ?? '').toString();
        final seatMuted = v['isMuted'] == true;
        final seatLocked = v['isLocked'] == true;
        if (seatUid.isNotEmpty && seatUid != currentUid && (seatMuted || seatLocked)) {
          final agoraUid = _agoraService.getAgoraUidByUserId(seatUid);
          if (agoraUid != null) {
            await _agoraService.muteRemoteUser(agoraUid, true);
          }
        } else if (seatUid.isNotEmpty && seatUid != currentUid && !seatMuted && !seatLocked) {
          final agoraUid = _agoraService.getAgoraUidByUserId(seatUid);
          if (agoraUid != null) {
            await _agoraService.muteRemoteUser(agoraUid, false);
          }
        }
      }
    }
  }

  // 1. أخذ المايك (Take Mic / Move Seat)
  Future<void> joinSeat(int seatIndex, {required String userName, required String userId, required String userProfilePic}) async {
    final String? currentUid = SupabaseService.currentUserId;
    if (currentUid == null) return;

    // BAN CHECK: Banned users cannot join seats
    if (isUserBanned(userId)) return;

    final idx = seatIndex - 1;
    if (idx < 0 || idx >= _allSeats.length) return;

    final seats = await _getMicSeats();

    // ANTI-CLONE + SEAT MOVE: If the user is already seated, remove them
    // from the old seat first so they can switch directly to a new one.
    final keysToRemove = seats.keys.where((k) {
      final v = seats[k];
      return v is Map && v['uid'] == currentUid;
    }).toList();
    for (final key in keysToRemove) {
      seats.remove(key);
    }

    // Don't overwrite a seat locked or occupied by another user
    final existing = seats['$idx'];
    if (existing is Map) {
      if (existing['isLocked'] == true) return;
      if (existing['uid'] != null && existing['uid'] != currentUid) return;
    }

    final seatData = {
      'userName': userName,
      'userId': userId,
      'uid': currentUid,
      'agoraUid': _agoraService.localAgoraUid,
      'userProfilePic': userProfilePic,
      'userLevel': UserController().currentLevel,
      'isMuted': false,
      'isLocked': false,
      'takenAt': DateTime.now().toUtc().toIso8601String(),
    };

    seats['$idx'] = seatData;
    await _saveMicSeats(seats);

    // AGORA: Unmute local audio stream when taking mic
    await _agoraService.setMute(false);
  }

  // 2. إقفال / فتح المايك (Lock/Unlock Mic)
  Future<void> toggleSeatLock(int seatIndex) async {
    final idx = seatIndex - 1;
    if (idx < 0 || idx >= _allSeats.length) return;

    // PERMISSION CHECK: Only owner/mod can lock/unlock seats
    if (!canManageRoom) return;

    final seats = await _getMicSeats();
    final seatData = seats['$idx'];
    if (seatData is Map) {
      seatData['isLocked'] = !(seatData['isLocked'] ?? false);
      seats['$idx'] = seatData;
    } else {
      // Empty seat - create a locked placeholder
      seats['$idx'] = {'isLocked': true};
    }
    await _saveMicSeats(seats);
  }

  // 3. النزول من على المايك (Leave Mic)
  Future<void> kickUserFromSeat(int seatIndex) async {
    final idx = seatIndex - 1;
    final seats = await _getMicSeats();
    final seatData = seats['$idx'];
    final bool wasLocked = seatData is Map && seatData['isLocked'] == true;

    if (wasLocked) {
      seats['$idx'] = {'isLocked': true};
    } else {
      seats.remove('$idx');
    }
    await _saveMicSeats(seats);

    // AGORA: Mute local audio stream when leaving mic
    await _agoraService.setMute(true);
  }

  // 4. أنزل أي حد من على المايك (Kick User from Mic)
  Future<void> kickUserToAudience(int seatIndex) async {
    final idx = seatIndex - 1;
    if (idx < 0 || idx >= _allSeats.length) return;

    final targetUserId = _allSeats[idx].userId;

    // PERMISSION CHECK: Only owner/mod can kick others
    if (!canManageTarget(targetUserId ?? '')) return;

    final seats = await _getMicSeats();
    final seatData = seats['$idx'];
    final bool wasLocked = seatData is Map && seatData['isLocked'] == true;

    if (wasLocked) {
      seats['$idx'] = {'isLocked': true};
    } else {
      seats.remove('$idx');
    }
    await _saveMicSeats(seats);
  }

  // 5. عمل ميوت لأي حد على المايك (Mute User)
  Future<void> toggleSeatMute(int seatIndex, {bool forceMute = false}) async {
    final idx = seatIndex - 1;
    if (idx < 0 || idx >= _allSeats.length) return;

    final currentMuteState = _allSeats[idx].isMuted;
    final targetUid = _allSeats[idx].uid;
    final targetUserId = _allSeats[idx].userId;

    // PERMISSION CHECK: Only owner/mod can mute others
    if (targetUserId != UserController().numericId && !canManageTarget(targetUserId ?? '')) return;

    // ENFORCE MUTED STATE: If seat is muted, only owner/mod can unmute
    if (currentMuteState && !forceMute) {
      if (!canManageRoom) return;
    }

    final seats = await _getMicSeats();
    final seatData = seats['$idx'];
    if (seatData is Map) {
      seatData['isMuted'] = !currentMuteState;
      seats['$idx'] = seatData;
      await _saveMicSeats(seats);
    }

    // AGORA: Toggle local audio mute state for current user
    final currentUid = SupabaseService.currentUserId;
    if (currentUid != null && targetUid == currentUid) {
      if (!currentMuteState) {
        // Being muted by mod/owner - mute Agora
        await _agoraService.setMute(true);
      } else {
        // Being unmuted - only unmute if not force-muted by mod
        await _agoraService.setMute(false);
      }
    }
  }

  Future<void> leaveRoom() async {
    final currentUid = SupabaseService.currentUserId;
    if (currentUid == null) return;

    // SAFE EXIT: Clear seat status
    for (int i = 0; i < _allSeats.length; i++) {
      if (_allSeats[i].uid == currentUid) {
        await kickUserFromSeat(i + 1);
        break;
      }
    }
    
    // SAFE EXIT: Remove from participants table
    await _client
        .from('participants')
        .delete()
        .eq('room_id', roomId)
        .eq('uid', currentUid);

    // SAFE EXIT: Drop presence so other clients remove the user from the
    // room, free the mic seat, and broadcast "خرج من الغرفة".
    try {
      await _presenceChannel?.untrack();
    } catch (_) {}
  }

  void updateRoomDetails({String? id, String? name, String? announcement, String? coverPath, int? micCount, String? background, String? category, String? ownerId}) {
    if (id != null) roomId = id;
    if (name != null) roomName = name;
    if (announcement != null) roomAnnouncement = announcement;
    if (coverPath != null) roomCoverPath = coverPath;
    if (micCount != null) activeMicCount = micCount;
    if (background != null) backgroundPath = background;
    if (category != null) roomCategory = category;
    if (ownerId != null) this.ownerId = ownerId;
    safeNotify();
  }

  Future<void> sendTextMessage(String sender, String text) async {
    if (roomId.isEmpty) return;
    await _client.from('messages').insert({
      'room_id': roomId,
      'sender_name': sender,
      'text': text,
      'type': RoomMessageType.text.name,
      'sender_level': UserController().currentLevel,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> sendSystemMessage(String text) async {
    if (roomId.isEmpty) return;
    await _client.from('messages').insert({
      'room_id': roomId,
      'sender_name': 'النظام',
      'text': text,
      'type': RoomMessageType.system.name,
      'sender_level': 0,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  void toggleUserMute() {
    isUserMuted = !isUserMuted;
    safeNotify();
  }

  void toggleRoomAudio() {
    isRoomAudioEnabled = !isRoomAudioEnabled;
    safeNotify();
  }

  /// Invite a user to a specific seat. The invited user joins MUTED.
  Future<void> inviteToSeat(int seatIndex, {required String userName, required String userId, required String userProfilePic, required String uid}) async {
    final idx = seatIndex - 1;
    if (idx < 0 || idx >= _allSeats.length) return;

    // PERMISSION CHECK: Only owner/mod can invite
    if (!canManageRoom) return;

    final seats = await _getMicSeats();

    // Don't overwrite occupied seat (except by same user)
    final existing = seats['$idx'];
    if (existing is Map && existing['uid'] != null && existing['uid'] != uid) return;

    final seatData = {
      'userName': userName,
      'userId': userId,
      'uid': uid,
      'userProfilePic': userProfilePic,
      'userLevel': UserController().currentLevel,
      'isMuted': true, // INVITED USERS JOIN MUTED
      'isLocked': false,
      'isInvited': true,
      'takenAt': DateTime.now().toUtc().toIso8601String(),
    };

    seats['$idx'] = seatData;
    await _saveMicSeats(seats);

    await sendSystemMessage('تمت دعوة $userName إلى المقعد ${seatIndex}');
  }

  /// Remove a user from their seat (moderator/owner action).
  Future<void> removeFromSeat(String targetUid) async {
    final seats = await _getMicSeats();
    final keysToRemove = seats.keys.where((k) {
      final v = seats[k];
      return v is Map && (v['uid'] ?? '').toString() == targetUid;
    }).toList();

    if (keysToRemove.isEmpty) return;

    final targetUserId = seats[keysToRemove.first]?['userId']?.toString() ?? '';
    if (!canManageTarget(targetUserId)) return;

    for (final key in keysToRemove) {
      final seatData = seats[key];
      final bool wasLocked = seatData is Map && seatData['isLocked'] == true;
      if (wasLocked) {
        seats[key] = {'isLocked': true};
      } else {
        seats.remove(key);
      }
    }
    await _saveMicSeats(seats);
  }

  /// Assign a user as moderator (owner only).
  Future<void> assignModerator(String userNumericId) async {
    if (!isRoomOwner) return;
    if (_moderators.contains(userNumericId)) return;
    _moderators.add(userNumericId);
    await _client.from('rooms').update({'moderators': _moderators}).eq('room_id', roomId);
    safeNotify();
  }

  /// Remove a moderator (owner only).
  Future<void> removeModerator(String userNumericId) async {
    if (!isRoomOwner) return;
    _moderators.remove(userNumericId);
    await _client.from('rooms').update({'moderators': _moderators}).eq('room_id', roomId);
    safeNotify();
  }

  // BAN SYSTEM
  final List<Map<String, dynamic>> _bannedUsers = [];
  List<Map<String, dynamic>> get bannedUsers => List.unmodifiable(_bannedUsers);
  StreamSubscription? _bansSubscription;

  void _listenToBans() {
    _bansSubscription?.cancel();
    try {
      _bansSubscription = _client
          .from('room_bans')
          .stream(primaryKey: ['id'])
          .eq('room_id', roomId)
          .listen((rows) {
        _bannedUsers.clear();
        for (final row in rows) {
          _bannedUsers.add({
            'user_id': row['user_id']?.toString() ?? '',
            'user_name': row['user_name']?.toString() ?? 'مستخدم',
            'banned_at': row['banned_at'] ?? '',
          });
        }
        safeNotify();
      }, onError: (_) {});
    } catch (_) {}
  }

  /// Ban a user from the room (owner/mod only).
  Future<void> banUser(String targetUserId, String targetUserName) async {
    if (!canManageTarget(targetUserId)) return;
    if (isModerator(targetUserId)) return; // Can't ban other mods

    await _client.from('room_bans').upsert({
      'room_id': roomId,
      'user_id': targetUserId,
      'user_name': targetUserName,
      'banned_by': UserController().numericId,
    }, onConflict: 'room_id,user_id');

    // Also kick them from seat if seated
    final seats = await _getMicSeats();
    final keysToRemove = seats.keys.where((k) {
      final v = seats[k];
      return v is Map && (v['userId'] ?? '').toString() == targetUserId;
    }).toList();
    for (final key in keysToRemove) {
      seats.remove(key);
    }
    if (keysToRemove.isNotEmpty) await _saveMicSeats(seats);

    await sendSystemMessage('تم حظر $targetUserName من الغرفة');
  }

  /// Unban a user from the room (owner/mod only).
  Future<void> unbanUser(String targetUserId) async {
    if (!canManageRoom) return;
    await _client.from('room_bans').delete()
        .eq('room_id', roomId)
        .eq('user_id', targetUserId);
  }

  /// Check if a user is banned from this room.
  bool isUserBanned(String userId) {
    return _bannedUsers.any((b) => b['user_id'] == userId);
  }

  void clearMessages() {
    _messages.clear();
    safeNotify();
  }

  // PORTED MISSING METHODS
  void addActiviteCount() {
    // increment activity logic
  }

  Future<void> onLockRoomWithPassword(String password) async {
    roomPassword = password;
    await _client.from('rooms').update({'room_password': password}).eq('room_id', roomId);
    safeNotify();
  }

  Future<void> onUnLockRoomWithPassword() async {
    roomPassword = null;
    await _client.from('rooms').update({'room_password': null}).eq('room_id', roomId);
    safeNotify();
  }

  void banUserFromSeat(dynamic seatIndex) {
    // seat ban logic
    if (seatIndex is int) {
      kickUserFromSeat(seatIndex);
    }
  }

  void vibrate() {
    HapticFeedback.vibrate();
  }

  void hideMessage(dynamic msgId) {
    // hide chat message logic
  }

  void toggleFollow(String userId) {
    // toggle follow user logic
  }

  void toggleMic() {
    isUserMicEnabled = !isUserMicEnabled;
    notifyListeners();
  }

  void toggleSpeaker() {
    isRoomAudioEnabled = !isRoomAudioEnabled;
    notifyListeners();
  }

  void useProfileAvatar() {
    // set profile avatar logic
  }

  // Admin and Lifecycle methods
  Future<void> setActiveMicCount(int count) async {
    if (roomId.isEmpty) return;
    await _client.from('rooms').update({'active_mic_count': count}).eq('room_id', roomId);
    safeNotify();
  }

  Future<void> lockRoomWithPassword(String password) async {
    if (roomId.isEmpty) return;
    await _client.from('rooms').update({'room_password': password}).eq('room_id', roomId);
    roomPassword = password;
    safeNotify();
  }

  Future<void> addMessage(String text, {String? targetName, String? giftName, int? giftCount, String? imageUrl}) async {
    if (roomId.isEmpty) return;
    final userController = UserController();
    final bool isGift = giftName != null;
    await _client.from('messages').insert({
      'room_id': roomId,
      'sender_name': userController.name,
      'text': text,
      'type': isGift ? RoomMessageType.gift.name : RoomMessageType.text.name,
      'sender_level': userController.currentLevel,
      'target_name': targetName,
      'gift_name': giftName,
      'gift_count': giftCount,
      'image_url': imageUrl,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  bool isFollowing(String userId) {
    // Follow logic placeholder
    return false;
  }

  Future<void> toggleUserMic(String userId) async {
    // Toggle specific user mic logic
    safeNotify();
  }

  Future<void> toggleChat() async {
    isChatEnabled = !isChatEnabled;
    safeNotify();
  }

  Future<void> toggleAllMicsMute() async {
    allMicsMuted = !allMicsMuted;
    safeNotify();
  }

  Future<void> destroyRoom({String? requesterId, bool isAdmin = false}) async {
    if (roomId.isEmpty) return;
    await _client.from('rooms').delete().eq('room_id', roomId);
  }

  Future<void> closeRoom({String? requesterId, bool isAdmin = false}) async {
    if (roomId.isEmpty) return;
    await _client.from('rooms').update({'status': 'inactive'}).eq('room_id', roomId);
  }

  Future<void> reopenRoom({String? requesterId, bool isAdmin = false}) async {
    if (roomId.isEmpty) return;
    await _client.from('rooms').update({'status': 'active'}).eq('room_id', roomId);
  }

  static ImageProvider getSafeImageProvider(String? path) {
    if (path == null || path.isEmpty) return const AssetImage('assets/Asad/room.jpg');
    if (path.startsWith('assets/')) return AssetImage(path);
    if (path.startsWith('http')) return NetworkImage(path);
    if (path.startsWith('data:image')) {
      final String pureBase64 = path.split(',').last;
      return MemoryImage(Uint8List.fromList(base64Decode(pureBase64)));
    }
    return FileImage(File(path));
  }
}
