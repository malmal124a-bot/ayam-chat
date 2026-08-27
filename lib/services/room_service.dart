import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../controllers/user_controller.dart';

class RoomService {
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  final SupabaseClient _client = SupabaseService.client;

  Future<void> createRoom({
    required String name,
    required String description,
    required String category,
    required String coverUrl,
  }) async {
    final userController = UserController();
    final String roomId = userController.numericId; // BIND ROOM ID DIRECTLY TO USER'S 6-DIGIT PROFILE ID
    final String? uid = SupabaseService.currentUserId;

    if (uid == null) throw Exception('User not logged in');

    final roomData = {
      'room_id': roomId,
      'room_name': name,
      'description': description,
      'category': category,
      'owner_id': userController.numericId,
      'owner_uid': uid,
      'owner_name': userController.name,
      'room_cover': coverUrl,
      'participant_count': 1,
      'status': 'active', // STEP 5: GLOBAL STATUS FOR HOME SCREEN STREAMING
      'is_active': true,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'last_active': DateTime.now().toUtc().toIso8601String(),
    };

    // Use this 6-digit User ID as the room_id in Supabase: rooms/{user_numeric_id}
    await _client.from('rooms').upsert(roomData, onConflict: 'room_id');
  }

  Future<void> deleteRoom(String roomId) async {
    await _client.from('rooms').delete().eq('room_id', roomId);
  }

  Future<void> updateRoomStatus(String roomId, String status) async {
    await _client.from('rooms').update({'status': status}).eq('room_id', roomId);
  }

  Future<Map<String, dynamic>?> getRoom(String roomId) async {
    return await _client
        .from('rooms')
        .select()
        .eq('room_id', roomId)
        .maybeSingle();
  }
}
