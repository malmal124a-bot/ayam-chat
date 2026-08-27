import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/user_controller.dart';

class VisitorsScreen extends StatefulWidget {
  const VisitorsScreen({super.key});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserController _userController = UserController();
  List<Map<String, dynamic>> _visitors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    setState(() => _isLoading = true);
    
    try {
      // Query visitors subcollection from Firestore
      final visitorsSnapshot = await _firestore
          .collection('users')
          .doc(_userController.id)
          .collection('visitors')
          .orderBy('visitedAt', descending: true)
          .limit(50)
          .get();
      
      List<Map<String, dynamic>> visitorsList = [];
      
      for (var doc in visitorsSnapshot.docs) {
        final visitorData = doc.data();
        // Get visitor user details
        final visitorUserDoc = await _firestore.collection('users').doc(doc.id).get();
        if (visitorUserDoc.exists) {
          final userData = visitorUserDoc.data() as Map<String, dynamic>;
          final visitedAt = visitorData['visitedAt'] as Timestamp?;
          final timeAgo = _formatTimeAgo(visitedAt);
          
          visitorsList.add({
            'name': userData['name'] ?? 'Unknown',
            'id': userData['id'] ?? doc.id,
            'time': timeAgo,
            'profilePic': userData['profilePic'],
          });
        }
      }
      
      setState(() {
        _visitors = visitorsList;
      });
    } catch (e) {
      debugPrint('Error loading visitors: $e');
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B08),
      appBar: AppBar(
        title: const Text('الزوار', style: TextStyle(color: Color(0xFFFFD700))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : _visitors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('لا يوجد زوار بعد', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _visitors.length,
                  itemBuilder: (context, index) {
                    final visitor = _visitors[index];
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
                                Text(visitor['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('ID: ${visitor['id']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(visitor['time'], style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
