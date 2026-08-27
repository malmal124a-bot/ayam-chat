import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/user_controller.dart';

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserController _userController = UserController();
  List<Map<String, dynamic>> _followers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoading = true);
    
    try {
      // Query followers subcollection from Firestore
      final followersSnapshot = await _firestore
          .collection('users')
          .doc(_userController.id)
          .collection('followers')
          .orderBy('followedAt', descending: true)
          .limit(50)
          .get();
      
      List<Map<String, dynamic>> followersList = [];
      
      for (var doc in followersSnapshot.docs) {
        final followerData = doc.data();
        // Get follower user details
        final followerUserDoc = await _firestore.collection('users').doc(doc.id).get();
        if (followerUserDoc.exists) {
          final userData = followerUserDoc.data() as Map<String, dynamic>;
          final followedAt = followerData['followedAt'] as Timestamp?;
          final timeAgo = _formatTimeAgo(followedAt);
          
          followersList.add({
            'name': userData['name'] ?? 'Unknown',
            'id': userData['id'] ?? doc.id,
            'followedAt': timeAgo,
            'profilePic': userData['profilePic'],
          });
        }
      }
      
      setState(() {
        _followers = followersList;
      });
    } catch (e) {
      debugPrint('Error loading followers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'الآن';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());
    
    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} دقيقة';
    if (difference.inHours < 24) return 'منذ ${difference.inHours} ساعة';
    if (difference.inDays < 7) return 'منذ ${difference.inDays} يوم';
    return 'منذ ${difference.inDays ~/ 7} أسبوع';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B08),
      appBar: AppBar(
        title: Text('المتابعين', style: TextStyle(color: theme.colorScheme.secondary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : _followers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('لا يوجد متابعين بعد', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _followers.length,
                  itemBuilder: (context, index) {
                    final follower = _followers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F180B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                              ),
                            ),
                            child: const Icon(Icons.person, color: Colors.black),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(follower['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('ID: ${follower['id']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(follower['followedAt'], style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
