import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import 'user_controller.dart';

class RoomController extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;

  String? roomPassword;
  List<Color> get vipColors => [const Color(0xFFFFD700), const Color(0xFFFFA500)];

  Future<void> createRoom({
    required String name,
    required String description,
    required String category,
    required String coverUrl,
  }) async {
    final userController = UserController();
    final String roomId = userController.numericId; // BIND ROOM ID DIRECTLY TO USER'S 6-DIGIT PROFILE ID

    // PREVENT DUPLICATE ROOM CREATION: Check if room already exists
    final existingRoom = await _client
        .from('rooms')
        .select('room_id')
        .eq('room_id', roomId)
        .maybeSingle();
    if (existingRoom != null) {
      debugPrint('Room already exists with ID: $roomId - Skipping creation');
      return;
    }

    final roomData = {
      'room_id': roomId,
      'room_name': name,
      'description': description,
      'category': category,
      'owner_id': userController.numericId,
      'owner_uid': SupabaseService.currentUserId ?? userController.numericId,
      'owner_name': userController.name,
      'room_cover': coverUrl,
      'participant_count': 1,
      'status': 'active', // GLOBAL HOME SCREEN STREAMING - PERSISTENT ROOM
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'last_active': DateTime.now().toUtc().toIso8601String(),
    };

    // Use this 6-digit User ID as the room_id in Supabase: rooms/{user_numeric_id}
    // Room persistence: Row is never auto-deleted, remains listed on Home Screen permanently
    await _client.from('rooms').insert(roomData);
    debugPrint('Room created with ID: $roomId - Status: active (persistent)');
  }

  void addActiviteCount() {
    // Logic to increment activity count if needed
  }

  void onLockRoomWithPassword(String password) {
    roomPassword = password;
    notifyListeners();
  }

  void onUnLockRoomWithPassword() {
    roomPassword = null;
    notifyListeners();
  }

  void banUserFromSeat(dynamic seatIndex) {
    // Logic to ban user from seat
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
    // toggle mic state
    notifyListeners();
  }

  void toggleSpeaker() {
    // toggle speaker state
    notifyListeners();
  }

  void useProfileAvatar() {
    // set profile avatar logic
  }
}
