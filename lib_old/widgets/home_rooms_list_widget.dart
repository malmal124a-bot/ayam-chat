import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../controllers/user_controller.dart';
import '../screens/voice_room_screen.dart';

class HomeRoomsListWidget extends StatelessWidget {
  const HomeRoomsListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // PERSIST PUBLIC ROOMS: Listen directly to real-time stream of ALL rooms
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .orderBy('participantCount', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.meeting_room_outlined, size: 64, color: Colors.amber.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text('لا توجد غرف نشطة حالياً', style: TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          );
        }

        final rooms = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final roomData = rooms[index].data() as Map<String, dynamic>;
            final roomId = roomData['roomId'] ?? rooms[index].id;
            final roomName = roomData['roomName'] ?? 'غرفة جديدة';
            final roomImageBase64 = roomData['roomImageBase64'] ?? roomData['roomImage'] ?? roomData['roomCover'] ?? '';
            final participantCount = roomData['participantCount'] ?? 0;
            final ownerId = roomData['ownerId'] ?? '';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoiceRoomScreen(
                      roomId: roomId,
                      roomName: roomName,
                      roomCover: roomImageBase64,
                      isOwner: ownerId == UserController().id,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.1), width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // ROOM IMAGE: Render using BoxFit.cover
                    Positioned.fill(
                      child: _buildRoomImage(roomImageBase64),
                    ),
                    
                    // Gradient Overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Occupant Count Badge
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '$participantCount',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Room Info
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roomName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: $roomId',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
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

  Widget _buildRoomImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Image.asset('assets/Asad/room.jpg', fit: BoxFit.cover);
    }
    
    // RENDER BASE64 IMAGE: Render room cover using Image.memory with BoxFit.cover
    if (imagePath.startsWith('data:image/') && imagePath.contains(';base64,')) {
      try {
        final base64String = imagePath.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      } catch (e) {
        return Image.asset('assets/Asad/room.jpg', fit: BoxFit.cover);
      }
    }

    if (!imagePath.startsWith('http') && !imagePath.startsWith('assets/') && !imagePath.startsWith('/')) {
      try {
        return Image.memory(base64Decode(imagePath), fit: BoxFit.cover);
      } catch (e) {
        // Not base64
      }
    }
    
    if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, fit: BoxFit.cover);
    }
    
    if (imagePath.startsWith('http')) {
      return Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/Asad/room.jpg', fit: BoxFit.cover));
    }
    
    return Image.file(File(imagePath), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/Asad/room.jpg', fit: BoxFit.cover));
  }
}
