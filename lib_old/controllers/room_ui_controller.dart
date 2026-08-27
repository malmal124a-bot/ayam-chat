import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mic_seat.dart';
import 'user_controller.dart';

enum RoomMessageType { text, system, gift, image }

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

class RoomUiController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Room Details
  String roomId = '1205838';
  String roomName = 'غرفة الدردشة';
  String roomAnnouncement = 'أهلاً بالجميع في غرفتنا المتواضعة';
  String roomCoverPath = 'assets/Asad/room.jpg';
  int activeMicCount = 12; 
  String backgroundPath = 'assets/Asad/bg_room.png';
  String ownerId = ''; // Owner ID - should match user profile ID for independent rooms
  bool isOwner = false; // Owner permission flag
  
  // Properties / Getters
  String roomCategory = 'عام';
  List<String> moderators = [];
  String roomPassword = '';
  bool roomLocked = false;

  // Room State (Interactive Options - Offline Handlers)
  bool isChatEnabled = true;
  bool allMicsMuted = false; 
  bool isUserMicEnabled = true; 
  bool isUserMuted = false; 
  bool isRoomAudioEnabled = true; 
  bool noiseIsolation = false;
  String audioQuality = 'ممتازة';

  // Volume Controls
  double voiceVolume = 0.8;
  double musicVolume = 0.5;

  // Effects selection state
  String selectedEntryEffect = 'None';
  String selectedGiftEffect = 'None';
  String selectedEntranceEffect = 'None';

  bool _isDisposed = false;

  // Local state for full execution
  final List<String> _followingIds = [];
  final List<String> _bannedUserIds = [];
  
  // Firestore participant count for real-time sync
  int _firestoreParticipantCount = 0;

  // task 4: User Decorations Store
  final Map<String, String> _userAvatarFrames = {
    'host_id': 'assets/vip/vip1.png',
    'user_0': 'assets/vip/vip1.png',
    'u1': 'assets/vip/vip1.png',
  };

  final List<RoomMessage> _messages = [];
  List<RoomMessage> get messages => List.unmodifiable(_messages);

  final List<MicSeat> _allSeats = List.generate(
    20,
    (i) => MicSeat(
      index: i + 1,
      userName: null, // Empty seat
      userId: null, // Empty seat
      userProfilePic: null,
      avatarFrame: null,
      userLevel: 1,
      isVip: false,
      isLocked: i >= 12,
      isMuted: false,
      isSpeaking: false,
    ),
  );

  List<MicSeat> get visibleSeats => _allSeats.take(activeMicCount).toList();
  List<MicSeat> get allSeats => _allSeats;

  RoomUiController() {
    _listenToFirestore();
  }

  void _listenToFirestore() {
    // Listen to room messages
    _firestore.collection('rooms').doc(roomId).collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
      _messages.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _messages.add(RoomMessage(
          id: doc.id,
          senderName: data['senderName'] ?? '',
          text: data['text'] ?? '',
          type: _parseMessageType(data['type']),
          targetName: data['targetName'],
          giftName: data['giftName'],
          giftCount: data['giftCount'] as int?,
          senderLevel: (data['senderLevel'] as num?)?.toInt() ?? 1,
          imageUrl: data['imageUrl'],
        ));
      }
      safeNotify();
    });

    // Listen to room state (mic seats, mute status, etc.)
    _firestore.collection('rooms').doc(roomId).snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          roomName = data['roomName'] ?? roomName;
          roomAnnouncement = data['announcement'] ?? roomAnnouncement;
          allMicsMuted = data['allMicsMuted'] as bool? ?? false;
          roomLocked = data['roomLocked'] as bool? ?? false;
          activeMicCount = (data['activeMicCount'] as num?)?.toInt() ?? activeMicCount;
          
          // Update mic seats from Firestore
          // FIX: Safely convert Firestore map data to List
          final seatsDataRaw = data['micSeats'];
          final List<dynamic> seatsData = seatsDataRaw is List 
              ? (seatsDataRaw as List<dynamic>)
              : ((seatsDataRaw as Map?)?.values.toList() ?? []);
          
          if (seatsData.isNotEmpty) {
            for (var seatData in seatsData) {
              final index = (seatData['index'] as num?)?.toInt() ?? 0;
              if (index > 0 && index <= _allSeats.length) {
                _allSeats[index - 1] = MicSeat(
                  index: index,
                  userName: seatData['userName'],
                  userId: seatData['userId'],
                  userProfilePic: seatData['userProfilePic'],
                  avatarFrame: seatData['avatarFrame'],
                  userLevel: (seatData['userLevel'] as num?)?.toInt() ?? 1,
                  isVip: seatData['isVip'] as bool? ?? false,
                  isLocked: seatData['isLocked'] as bool? ?? false,
                  isMuted: seatData['isMuted'] as bool? ?? false,
                  isSpeaking: seatData['isSpeaking'] as bool? ?? false,
                );
              }
            }
          }
          safeNotify();
        }
      }
    });
  }

  RoomMessageType _parseMessageType(String? type) {
    switch (type) {
      case 'system': return RoomMessageType.system;
      case 'gift': return RoomMessageType.gift;
      case 'image': return RoomMessageType.image;
      default: return RoomMessageType.text;
    }
  }

  Future<void> sendMessage(String text, {String? targetName, String? giftName, int? giftCount}) async {
    try {
      final user = UserController();
      await _firestore.collection('rooms').doc(roomId).collection('messages')
          .add({
        'senderName': user.name,
        'senderId': user.id,
        'senderLevel': user.currentLevel,
        'text': text,
        'type': 'text',
        'targetName': targetName,
        'giftName': giftName,
        'giftCount': giftCount,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> updateMicSeat(MicSeat seat) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'micSeats': FieldValue.arrayUnion([
          {
            'index': seat.index,
            'userName': seat.userName,
            'userId': seat.userId,
            'userProfilePic': seat.userProfilePic,
            'avatarFrame': seat.avatarFrame,
            'userLevel': seat.userLevel,
            'isVip': seat.isVip,
            'isLocked': seat.isLocked,
            'isMuted': seat.isMuted,
            'isSpeaking': seat.isSpeaking,
          }
        ]),
      });
    } catch (e) {
      debugPrint('Error updating mic seat: $e');
    }
  }

  Future<void> toggleRoomMute(bool muted) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'allMicsMuted': muted,
      });
    } catch (e) {
      debugPrint('Error toggling room mute: $e');
    }
  }

  // Available Backgrounds
  final List<String> availableBackgrounds = [
    'assets/Asad/bg_room.png',
    'assets/Asad/room.jpg',
    'assets/Asad/room_item_bg.png',
  ];

  // Online audience members - empty for clean room
  List<Map<String, String>> roomAudience = [];
  
  // Room members for multi-user presence
  List<Map<String, dynamic>> roomMembers = [];

  int get onlineUsersCount => _firestoreParticipantCount > 0 
      ? _firestoreParticipantCount 
      : roomAudience.length + _allSeats.where((s) => s.userName != null).length;

  // MULTI-USER ROOM PRESENCE: Update room members from Firestore
  void updateRoomMembers(List<Map<String, dynamic>> members) {
    roomMembers = members;
    update();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void update() {
    if (_isDisposed) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) {
          notifyListeners();
        }
      });
    } else {
      notifyListeners();
    }
  }

  void safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // Follow Logic
  bool isFollowing(String userId) => _followingIds.contains(userId);
  Future<void> toggleFollow(String userId) async {
    final currentUserId = UserController().id;
    if (_followingIds.contains(userId)) {
      _followingIds.remove(userId);
      // Remove from Firestore
      try {
        await _firestore.collection('users').doc(currentUserId).update({
          'following': FieldValue.arrayRemove([userId])
        });
      } catch (e) {
        debugPrint('Error unfollowing user: $e');
      }
    } else {
      _followingIds.add(userId);
      // Add to Firestore
      try {
        await _firestore.collection('users').doc(currentUserId).update({
          'following': FieldValue.arrayUnion([userId])
        });
      } catch (e) {
        debugPrint('Error following user: $e');
      }
    }
    update();
  }

  // Ban Logic
  bool isUserBanned(String userId) => _bannedUserIds.contains(userId);
  Future<void> toggleUserBan(String userId) async {
    if (_bannedUserIds.contains(userId)) {
      _bannedUserIds.remove(userId);
      // Remove from Firestore
      try {
        await _firestore.collection('rooms').doc(roomId).update({
          'bannedUsers': FieldValue.arrayRemove([userId])
        });
      } catch (e) {
        debugPrint('Error unbanning user: $e');
      }
    } else {
      _bannedUserIds.add(userId);
      // Add to Firestore
      try {
        await _firestore.collection('rooms').doc(roomId).update({
          'bannedUsers': FieldValue.arrayUnion([userId])
        });
      } catch (e) {
        debugPrint('Error banning user: $e');
      }
    }
    update();
  }

  // Room Management
  Future<void> setRoomCategory(String category) async {
    roomCategory = category;
    
    // Sync to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'category': category,
      });
    } catch (e) {
      debugPrint('Error setting room category: $e');
    }
    update();
  }

  Future<void> setActiveMicCount(int count) async {
    activeMicCount = count.clamp(1, 20);
    for (int i = 0; i < _allSeats.length; i++) {
      if (i >= activeMicCount && _allSeats[i].userName == null) {
        _allSeats[i] = _allSeats[i].copyWith(isLocked: true);
      } else if (i < activeMicCount && _allSeats[i].isLocked) {
        _allSeats[i] = _allSeats[i].copyWith(isLocked: false);
      }
    }
    
    // Sync to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'activeMicCount': activeMicCount,
        'micSeats': _allSeats.map((s) => s.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('Error setting active mic count: $e');
    }
    update();
  }

  Future<void> removeModerator(String id) async {
    moderators.remove(id);
    
    // Sync to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'moderators': FieldValue.arrayRemove([id])
      });
    } catch (e) {
      debugPrint('Error removing moderator: $e');
    }
    update();
  }

  Future<void> lockRoomWithPassword(String pwd) async {
    roomPassword = pwd;
    roomLocked = pwd.isNotEmpty;
    
    // Sync to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'password': pwd,
        'isLocked': roomLocked,
      });
    } catch (e) {
      debugPrint('Error locking room: $e');
    }
    update();
  }

  Future<void> updateRoomDetails({
    String? id, 
    String? name, 
    String? announcement, 
    String? coverPath, 
    int? micCount, 
    String? background,
    String? category,
    String? ownerId,
  }) async {
    if (id != null) roomId = id;
    if (name != null) roomName = name;
    if (announcement != null) roomAnnouncement = announcement;
    if (coverPath != null) roomCoverPath = coverPath;
    if (micCount != null) setActiveMicCount(micCount);
    if (background != null) backgroundPath = background;
    if (category != null) roomCategory = category;
    if (ownerId != null) this.ownerId = ownerId;
    
    // Sync to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'name': roomName,
        'announcement': roomAnnouncement,
        'coverPath': roomCoverPath,
        'activeMicCount': activeMicCount,
        'backgroundPath': backgroundPath,
        'category': roomCategory,
        'ownerId': ownerId,
      });
    } catch (e) {
      debugPrint('Error updating room details: $e');
    }
    update();
  }

  void addMessage(RoomMessage message) {
    if (!isChatEnabled && message.type == RoomMessageType.text) return;
    _messages.add(message);
    if (_messages.length > 200) _messages.removeAt(0);
    update();
  }

  void clearMessages() {
    _messages.clear();
    update();
  }

  Future<void> toggleChat() async {
    isChatEnabled = !isChatEnabled;
    
    // Sync to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'isChatEnabled': isChatEnabled,
      });
    } catch (e) {
      debugPrint('Error toggling chat: $e');
    }
    update();
  }

  Future<void> toggleAllMicsMute() async {
    allMicsMuted = !allMicsMuted;
    for (int i = 0; i < _allSeats.length; i++) {
      _allSeats[i] = _allSeats[i].copyWith(isMuted: allMicsMuted);
    }
    
    // Sync to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'allMicsMuted': allMicsMuted,
        'micSeats': _allSeats.map((s) => s.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('Error toggling all mics mute: $e');
    }
    update();
  }

  Future<void> toggleUserMic() async {
    isUserMicEnabled = !isUserMicEnabled;
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'userMicStates': FieldValue.arrayUnion([
          {'userId': UserController().id, 'isMicEnabled': isUserMicEnabled}
        ]),
      });
    } catch (e) {
      debugPrint('Error toggling user mic: $e');
    }
    update();
  }

  Future<void> toggleUserMute() async {
    isUserMuted = !isUserMuted;
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'userMuteStates': FieldValue.arrayUnion([
          {'userId': UserController().id, 'isMuted': isUserMuted}
        ]),
      });
    } catch (e) {
      debugPrint('Error toggling user mute: $e');
    }
    update();
  }

  // REAL-TIME MIC SEAT SYNC: Update mic seats from Firestore
  void updateMicSeatsFromFirestore(List<Map<String, dynamic>> micSeatsData) {
    for (int i = 0; i < micSeatsData.length && i < _allSeats.length; i++) {
      final seatData = micSeatsData[i];
      _allSeats[i] = _allSeats[i].copyWith(
        userName: seatData['userName'] as String?,
        userId: seatData['userId'] as String?,
        userProfilePic: seatData['userProfilePic'] as String?,
        avatarFrame: seatData['avatarFrame'] as String?,
        userLevel: (seatData['userLevel'] as num?)?.toInt() ?? 1,
        isVip: seatData['isVip'] as bool? ?? false,
        isLocked: seatData['isLocked'] as bool? ?? false,
        isMuted: seatData['isMuted'] as bool? ?? false,
        isSpeaking: seatData['isSpeaking'] as bool? ?? false,
        userRole: seatData['userRole'] as String?,
        isSvip: seatData['isSvip'] as bool? ?? false,
      );
    }
    update();
  }

  // REAL-TIME PARTICIPANT COUNT: Update participant count from Firestore
  void updateParticipantCount(int count) {
    _firestoreParticipantCount = count;
    update();
  }

  Future<void> toggleRoomAudio() async {
    isRoomAudioEnabled = !isRoomAudioEnabled;
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'roomAudioEnabled': isRoomAudioEnabled,
      });
    } catch (e) {
      debugPrint('Error toggling room audio: $e');
    }
    update();
  }

  Future<void> setAudioQuality(String quality) async {
    audioQuality = quality;
    
    // Sync to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'audioQuality': quality,
      });
    } catch (e) {
      debugPrint('Error setting audio quality: $e');
    }
    update();
  }

  Future<void> setBackground(String path) async {
    backgroundPath = path;
    
    // Sync to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'backgroundPath': path,
      });
    } catch (e) {
      debugPrint('Error setting background: $e');
    }
    update();
  }

  void sendTextMessage(String sender, String text) {
    addMessage(RoomMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: sender,
      text: text,
      type: RoomMessageType.text,
    ));
  }

  Future<void> joinSeat(int seatIndex, {required String userName, required String userId, required String userProfilePic}) async {
    // FIX: Prevent duplicate seat occupancy - clear user from existing seat first
    int? existingSeatIndex;
    for (int i = 0; i < _allSeats.length; i++) {
      if (_allSeats[i].userId == userId) {
        existingSeatIndex = i;
        // Clear the existing seat
        _allSeats[i] = MicSeat(index: i + 1, isLocked: i >= activeMicCount);
        // Sync the clearing to Firestore
        try {
          await _firestore.collection('rooms').doc(roomId).update({
            'micSeats.$i': _allSeats[i].toJson(),
          });
        } catch (e) {
          debugPrint('Error clearing existing seat: $e');
        }
      }
    }

    final idx = seatIndex - 1;
    if (idx < 0 || idx >= _allSeats.length) return;
    
    // Fetch user's current avatar frame from Firestore for real-time sync
    String? userAvatarFrame = getUserFrame(userId);
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        userAvatarFrame = userData['activeFrame'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching user frame: $e');
    }
    
    _allSeats[idx] = _allSeats[idx].copyWith(
      userName: userName, 
      userId: userId, 
      userProfilePic: userProfilePic,
      avatarFrame: userAvatarFrame,
      isLocked: false, 
      isMuted: false, 
      isVip: userId == 'host_id' || userId == 'u1' || userId.startsWith('user_0'),
    );
    
    // Sync to Firestore for real-time multi-user visibility
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'micSeats.$idx': _allSeats[idx].toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Only increment participant count if user wasn't already seated
        ...(existingSeatIndex == null ? {'participantCount': FieldValue.increment(1)} : {}),
      });
      debugPrint('User $userId joined seat $seatIndex, synced to Firestore');
    } catch (e) {
      debugPrint('Error joining seat: $e');
    }
    update();
  }

  Future<void> kickUserFromSeat(int seatIndex) async {
    final idx = seatIndex - 1;
    if (idx < 0 || idx >= _allSeats.length) return;
    _allSeats[idx] = MicSeat(index: seatIndex, isLocked: idx >= activeMicCount);
    
    // Sync to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'micSeats.$idx': _allSeats[idx].toJson(),
      });
    } catch (e) {
      debugPrint('Error kicking user from seat: $e');
    }
    update();
  }

  Future<void> kickUserToAudience(int seatIndex) async {
    final idx = seatIndex - 1;
    if (idx < 0 || idx >= _allSeats.length) return;
    final seat = _allSeats[idx];
    if (seat.userName != null) {
      roomAudience.add({
        'id': seat.userId!,
        'name': seat.userName!,
        'avatar': seat.userProfilePic ?? '',
      });
      await kickUserFromSeat(seatIndex);
      
      // Sync audience to Firestore
      try {
        await _firestore.collection('rooms').doc(roomId).update({
          'audience': FieldValue.arrayUnion([{
            'id': seat.userId!,
            'name': seat.userName!,
            'avatar': seat.userProfilePic ?? '',
          }])
        });
      } catch (e) {
        debugPrint('Error adding user to audience: $e');
      }
    }
  }

  Future<void> kickUserFromRoom(String userId) async {
    // Remove from mic
    final seatIdx = _allSeats.indexWhere((s) => s.userId == userId);
    if (seatIdx != -1) {
      await kickUserFromSeat(seatIdx + 1);
    }
    // Remove from audience
    roomAudience.removeWhere((u) => u['id'] == userId);
    
    // Sync to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'audience': FieldValue.arrayRemove([{'id': userId}])
      });
    } catch (e) {
      debugPrint('Error removing user from room: $e');
    }
    update();
  }

  Future<void> banUserFromRoom(String userId) async {
    toggleUserBan(userId);
    await kickUserFromRoom(userId);
    
    // Sync banned users to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'bannedUsers': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      debugPrint('Error banning user from room: $e');
    }
  }

  Future<void> banUserFromSeat(int seatIndex) async {
    final idx = seatIndex - 1;
    if (idx < 0 || idx >= _allSeats.length) return;
    final userId = _allSeats[idx].userId;
    if (userId != null) {
      await banUserFromRoom(userId);
    } else {
      await kickUserFromSeat(seatIndex);
    }
  }

  Future<void> toggleSeatMute(int seatIndex) async {
    final idx = seatIndex - 1;
    if (idx < 0 || idx >= _allSeats.length) return;
    _allSeats[idx] = _allSeats[idx].copyWith(isMuted: !_allSeats[idx].isMuted);
    
    // Sync to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'micSeats.$idx.isMuted': _allSeats[idx].isMuted,
      });
    } catch (e) {
      debugPrint('Error toggling seat mute: $e');
    }
    update();
  }

  Future<void> toggleSeatLock(int seatIndex) async {
    final idx = seatIndex - 1;
    if (idx < 0 || idx >= _allSeats.length) return;
    _allSeats[idx] = _allSeats[idx].copyWith(isLocked: !_allSeats[idx].isLocked);
    
    // Sync to Firestore
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'micSeats.$idx.isLocked': _allSeats[idx].isLocked,
      });
    } catch (e) {
      debugPrint('Error toggling seat lock: $e');
    }
    update();
  }

  Future<void> occupySeat(int seatIndex) async {
    final userController = UserController();
    await joinSeat(seatIndex, 
      userName: userController.name, 
      userId: userController.id, 
      userProfilePic: userController.profilePic
    );
  }

  void inviteToSeat(int seatIndex) {
    addMessage(RoomMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: 'System',
      text: 'طلب دعوة صعود للمقعد $seatIndex',
      type: RoomMessageType.system,
    ));
    // Note: This is a UI-only notification. Actual seat assignment is handled via joinSeat() which syncs to Firestore.
  }

  void advanceRocketProgress(double value) => update();

  String? getUserFrame(String? userId) => _userAvatarFrames[userId];

  static ImageProvider getSafeImageProvider(String? path, {String fallback = 'assets/Asad/room.jpg'}) {
    if (path == null || path.isEmpty) return AssetImage(fallback);
    if (path.startsWith('http://') || path.startsWith('https://')) return NetworkImage(path);
    if (path.startsWith('assets/')) return AssetImage(path);
    return AssetImage(fallback);
  }
}
