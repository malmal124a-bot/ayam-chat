import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/user_controller.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserController _userController = UserController();
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    
    try {
      // Query friends subcollection from Firestore
      final friendsSnapshot = await _firestore
          .collection('users')
          .doc(_userController.id)
          .collection('friends')
          .get();
      
      List<Map<String, dynamic>> friendsList = [];
      
      for (var doc in friendsSnapshot.docs) {
        // Get friend user details
        final friendUserDoc = await _firestore.collection('users').doc(doc.id).get();
        if (friendUserDoc.exists) {
          final userData = friendUserDoc.data() as Map<String, dynamic>;
          friendsList.add({
            'name': userData['name'] ?? 'Unknown',
            'id': userData['id'] ?? doc.id,
            'status': userData['isOnline'] == true ? 'متصل' : 'غير متصل',
            'profilePic': userData['profilePic'],
          });
        }
      }
      
      setState(() {
        _friends = friendsList;
      });
    } catch (e) {
      debugPrint('Error loading friends: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B08),
      appBar: AppBar(
        title: Text('الأصدقاء', style: TextStyle(color: theme.colorScheme.secondary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : _friends.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('لا يوجد أصدقاء بعد', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
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
                                Text(friend['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('ID: ${friend['id']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: friend['status'] == 'متصل' ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              friend['status'],
                              style: TextStyle(
                                color: friend['status'] == 'متصل' ? Colors.green : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
