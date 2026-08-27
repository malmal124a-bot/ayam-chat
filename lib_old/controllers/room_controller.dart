import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomController {
  static final RoomController _instance = RoomController._internal();
  factory RoomController() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RoomController._internal() {
    debugPrint('Initializing: RoomController');
  }

  /// Generate a unique 6-digit room ID
  Future<String> generateUniqueRoomId() async {
    final random = Random();
    int maxAttempts = 100;
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      int generated = 100000 + random.nextInt(900000); // 6-digit: 100000-999999
      String candidateId = generated.toString();
      
      // Check Firestore for uniqueness
      final snapshot = await _firestore.collection('rooms').doc(candidateId).get();
      if (!snapshot.exists) {
        debugPrint('RoomController: Generated unique room ID: $candidateId (attempt ${attempts + 1})');
        return candidateId;
      }
      
      attempts++;
    }
    
    // Fallback if all attempts fail (should be extremely rare)
    final timestampId = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    debugPrint('RoomController: Using timestamp-based fallback room ID: $timestampId');
    return timestampId;
  }

  /// Create or update a room for a user (one room per user)
  Future<bool> createOrUpdateRoom({
    required String roomId,
    required String ownerId,
    required String roomName,
    required String roomCover,
    required String category,
    String? description,
    String? ownerName,
    bool isLocked = false,
    List<Map<String, dynamic>>? micSeats,
    String? roomImageBase64,
  }) async {
    try {
      final roomRef = _firestore.collection('rooms').doc(roomId);
      
      final roomData = {
        'roomId': roomId,
        'ownerId': ownerId,
        'ownerName': ownerName ?? 'Unknown',
        'roomName': roomName,
        'roomCover': roomCover,
        'roomImageBase64': roomImageBase64, // Store Base64 only if provided and within size limits
        'category': category,
        'description': description ?? '',
        'isLocked': isLocked,
        'micSeats': micSeats ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'participantCount': 0,
      };

      await roomRef.set(roomData, SetOptions(merge: true));
      debugPrint('Room created/updated successfully with Base64 support: $roomId');
      return true;
    } catch (e) {
      debugPrint('Error creating/updating room: $e');
      return false;
    }
  }

  /// Get room data by room ID
  Future<Map<String, dynamic>?> getRoom(String roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting room: $e');
      return null;
    }
  }

  /// Get room data stream for real-time updates
  Stream<Map<String, dynamic>?> getRoomStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  /// Get room by owner ID (since one room per user)
  Future<Map<String, dynamic>?> getRoomByOwner(String ownerId) async {
    try {
      final query = await _firestore
          .collection('rooms')
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting room by owner: $e');
      return null;
    }
  }

  /// Get ALL public rooms for global discovery
  Future<List<Map<String, dynamic>>> getAllRooms() async {
    try {
      final query = await _firestore
          .collection('rooms')
          .orderBy('participantCount', descending: true)
          .limit(50)
          .get();

      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting all rooms: $e');
      return [];
    }
  }

  /// Delete a room
  Future<bool> deleteRoom(String roomId) async {
    try {
      await _firestore.collection('rooms').doc(roomId).delete();
      debugPrint('Room deleted successfully: $roomId');
      return true;
    } catch (e) {
      debugPrint('Error deleting room: $e');
      return false;
    }
  }

  /// Add participant to room
  Future<void> addParticipant(String roomId, String userId) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('participants')
          .doc(userId)
          .set({
            'userId': userId,
            'joinedAt': FieldValue.serverTimestamp(),
          });

      // Increment participant count
      await _firestore.collection('rooms').doc(roomId).update({
        'participantCount': FieldValue.increment(1),
      });

      debugPrint('Participant added to room: $userId');
    } catch (e) {
      debugPrint('Error adding participant: $e');
    }
  }

  /// Remove participant from room
  Future<void> removeParticipant(String roomId, String userId) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('participants')
          .doc(userId)
          .delete();

      // Decrement participant count
      await _firestore.collection('rooms').doc(roomId).update({
        'participantCount': FieldValue.increment(-1),
      });

      debugPrint('Participant removed from room: $userId');
    } catch (e) {
      debugPrint('Error removing participant: $e');
    }
  }

  /// Update room lock status
  Future<void> updateRoomLock(String roomId, bool isLocked) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'isLocked': isLocked,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Room lock status updated: $isLocked');
    } catch (e) {
      debugPrint('Error updating room lock: $e');
    }
  }

  /// Update mic seats state in room
  Future<void> updateMicSeats(String roomId, List<Map<String, dynamic>> micSeats) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'micSeats': micSeats,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Mic seats updated for room: $roomId');
    } catch (e) {
      debugPrint('Error updating mic seats: $e');
    }
  }

  /// Update single mic seat state (real-time sync for multi-user)
  Future<void> updateMicSeat(String roomId, int seatIndex, Map<String, dynamic> seatData) async {
    try {
      final roomRef = _firestore.collection('rooms').doc(roomId);
      final roomDoc = await roomRef.get();
      
      if (roomDoc.exists) {
        final roomData = roomDoc.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> micSeats = 
            (roomData['micSeats'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        
        // Ensure micSeats has enough elements
        while (micSeats.length <= seatIndex) {
          micSeats.add({});
        }
        
        // Update the specific seat
        micSeats[seatIndex] = seatData;
        
        await roomRef.update({
          'micSeats': micSeats,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('Mic seat $seatIndex updated for room: $roomId');
      }
    } catch (e) {
      debugPrint('Error updating mic seat: $e');
    }
  }

  /// Get rooms by category
  Future<List<Map<String, dynamic>>> getRoomsByCategory(String category) async {
    try {
      final query = await _firestore
          .collection('rooms')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting rooms by category: $e');
      return [];
    }
  }
}
