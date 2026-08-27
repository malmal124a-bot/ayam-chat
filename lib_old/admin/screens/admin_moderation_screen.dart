import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/admin_auth_controller.dart';

class AdminModerationScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  
  const AdminModerationScreen({
    super.key,
    required this.adminAuthController,
  });

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> _activeRooms = [];
  List<QueryDocumentSnapshot> _reportedUsers = [];
  bool _isLoading = true;
  String _sortField = 'participantCount';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadActiveRooms();
    _loadReportedUsers();
  }

  Future<void> _loadActiveRooms() async {
    try {
      final snapshot = await _firestore.collection('rooms').get();
      setState(() {
        _activeRooms = snapshot.docs
            .where((doc) {
              final data = doc.data();
              final participantCount = (data['participantCount'] as num?)?.toInt() ?? 0;
              return participantCount > 0;
            })
            .toList();
        _sortRooms();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading active rooms: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReportedUsers() async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .get();
      setState(() {
        _reportedUsers = snapshot.docs;
      });
    } catch (e) {
      debugPrint('Error loading reported users: $e');
    }
  }

  void _sortRooms() {
    setState(() {
      _activeRooms.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        
        dynamic valueA;
        dynamic valueB;

        switch (_sortField) {
          case 'roomName':
            valueA = (dataA['roomName'] as String? ?? '').toLowerCase();
            valueB = (dataB['roomName'] as String? ?? '').toLowerCase();
            break;
          case 'ownerId':
            valueA = (dataA['ownerId'] as String? ?? '').toLowerCase();
            valueB = (dataB['ownerId'] as String? ?? '').toLowerCase();
            break;
          case 'participantCount':
            valueA = (dataA['participantCount'] as num?)?.toInt() ?? 0;
            valueB = (dataB['participantCount'] as num?)?.toInt() ?? 0;
            break;
          case 'micCount':
            valueA = _getActiveMicCount(dataA);
            valueB = _getActiveMicCount(dataB);
            break;
          default:
            valueA = 0;
            valueB = 0;
        }

        if (_sortAscending) {
          return valueA.compareTo(valueB);
        } else {
          return valueB.compareTo(valueA);
        }
      });
    });
  }

  int _getActiveMicCount(Map<String, dynamic> roomData) {
    final micSeats = roomData['micSeats'] as List?;
    if (micSeats == null) return 0;
    return micSeats.where((seat) {
      final seatData = seat as Map<String, dynamic>;
      return (seatData['userId'] as String?) != null;
    }).length;
  }

  Future<void> _muteUser(String userId, String roomId, int seatIndex) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'micSeats.$seatIndex.isMuted': true,
        'micSeats.$seatIndex.updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('user_muted'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('mute_failed'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _muteHost(String roomId) async {
    try {
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      final roomData = roomDoc.data();
      if (roomData == null) return;

      final micSeats = roomData['micSeats'] as List?;
      if (micSeats == null || micSeats.isEmpty) return;

      // Mute the first mic seat (host seat)
      final hostSeat = micSeats[0] as Map<String, dynamic>;
      final seatIndex = hostSeat['index'] as int? ?? 0;

      await _firestore.collection('rooms').doc(roomId).update({
        'micSeats.$seatIndex.isMuted': true,
        'micSeats.$seatIndex.updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('host_muted'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('mute_host_failed'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _kickUser(String userId, String roomId) async {
    try {
      // Remove user from room participants
      await _firestore.collection('rooms').doc(roomId).update({
        'participantCount': FieldValue.increment(-1),
      });
      
      // Update user's current room
      await _firestore.collection('users').doc(userId).update({
        'currentRoomId': null,
        'currentRoomName': null,
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('user_kicked'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      _loadActiveRooms();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('kick_failed'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _closeRoom(String roomId) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'participantCount': 0,
        'isActive': false,
        'closedAt': FieldValue.serverTimestamp(),
        'closedBy': widget.adminAuthController.currentUserId,
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('room_closed'.tr()),
          backgroundColor: Colors.green,
        ),
      );
      _loadActiveRooms();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('close_room_failed'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _banUser(String userId, String reason, Duration duration) async {
    try {
      final banExpiry = DateTime.now().add(duration);
      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'banReason': reason,
        'banExpiry': banExpiry.toIso8601String(),
        'bannedBy': widget.adminAuthController.currentUserId,
        'bannedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('user_banned'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ban_failed'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBanDialog(String userId, String userName) {
    final reasonController = TextEditingController();
    String selectedDuration = '1d';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ban_user'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'user'.tr()}: $userName'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'ban_reason'.tr(),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text('duration'.tr()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('1 Hour'),
                  selected: selectedDuration == '1h',
                  onSelected: (selected) {
                    setState(() => selectedDuration = '1h');
                  },
                ),
                ChoiceChip(
                  label: const Text('1 Day'),
                  selected: selectedDuration == '1d',
                  onSelected: (selected) {
                    setState(() => selectedDuration = '1d');
                  },
                ),
                ChoiceChip(
                  label: const Text('1 Week'),
                  selected: selectedDuration == '1w',
                  onSelected: (selected) {
                    setState(() => selectedDuration = '1w');
                  },
                ),
                ChoiceChip(
                  label: const Text('Permanent'),
                  selected: selectedDuration == 'perm',
                  onSelected: (selected) {
                    setState(() => selectedDuration = 'perm');
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Duration duration;
                switch (selectedDuration) {
                  case '1h':
                    duration = const Duration(hours: 1);
                    break;
                  case '1d':
                    duration = const Duration(days: 1);
                    break;
                  case '1w':
                    duration = const Duration(days: 7);
                    break;
                  case 'perm':
                    duration = const Duration(days: 365 * 100);
                    break;
                  default:
                    duration = const Duration(days: 1);
                }
                _banUser(userId, reasonController.text, duration);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('ban'.tr()),
          ),
        ],
      ),
    );
  }

  void _showRoomDetails(String roomId, Map<String, dynamic> roomData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'room_details'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('room_name'.tr(), roomData['roomName'] ?? 'Unknown'),
                      _buildInfoRow('room_id'.tr(), roomId),
                      _buildInfoRow('owner_id'.tr(), roomData['ownerId'] ?? 'Unknown'),
                      _buildInfoRow('participants'.tr(), (roomData['participantCount'] ?? 0).toString()),
                      _buildInfoRow('category'.tr(), roomData['category'] ?? 'General'),
                      const SizedBox(height: 16),
                      const Text('Mic Seats:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (roomData['micSeats'] != null)
                        ...List<Widget>.from(
                          (roomData['micSeats'] as List).map((seat) {
                            final seatData = seat as Map<String, dynamic>;
                            final userName = seatData['userName'] ?? 'Empty';
                            final isMuted = seatData['isMuted'] ?? false;
                            final userId = seatData['userId'];
                            
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isMuted ? Icons.mic_off : Icons.mic,
                                color: isMuted ? Colors.red : Colors.green,
                              ),
                              title: Text(userName),
                              trailing: userId != null
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.volume_off),
                                          onPressed: () => _muteUser(userId, roomId, seatData['index']),
                                          tooltip: 'mute'.tr(),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle),
                                          onPressed: () => _kickUser(userId, roomId),
                                          tooltip: 'kick'.tr(),
                                        ),
                                      ],
                                    )
                                  : null,
                            );
                          }),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('moderation_tools'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveRooms,
            tooltip: 'refresh'.tr(),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              // Tabs
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: Colors.blue.shade900,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue.shade900,
                  tabs: [
                    Tab(text: 'active_rooms'.tr()),
                    Tab(text: 'reports'.tr()),
                  ],
                ),
              ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildActiveRoomsTab(),
                    _buildReportsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRoomsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeRooms.isEmpty) {
      return Center(child: Text('no_active_rooms'.tr()));
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: const Border(
                bottom: BorderSide(color: Colors.grey),
              ),
            ),
            child: Row(
              children: [
                _buildTableHeader('room_name'.tr(), 200, 'roomName'),
                _buildTableHeader('owner_id'.tr(), 150, 'ownerId'),
                _buildTableHeader('mic_count'.tr(), 100, 'micCount'),
                _buildTableHeader('online_members'.tr(), 100, 'participantCount'),
                _buildTableHeader('category'.tr(), 120, 'category'),
                const Spacer(),
                _buildTableHeader('actions'.tr(), 200, ''),
              ],
            ),
          ),
          
          // Table Body
          Expanded(
            child: ListView.builder(
              itemCount: _activeRooms.length,
              itemBuilder: (context, index) {
                final doc = _activeRooms[index];
                final data = doc.data() as Map<String, dynamic>;
                final roomName = data['roomName'] as String? ?? 'Unknown';
                final ownerId = data['ownerId'] as String? ?? '';
                final participantCount = (data['participantCount'] as num?)?.toInt() ?? 0;
                final category = data['category'] as String? ?? 'General';
                final micCount = _getActiveMicCount(data);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                    border: const Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildTableCell(roomName, 200),
                      _buildTableCell(ownerId, 150),
                      _buildTableCell(micCount.toString(), 100),
                      _buildTableCell(participantCount.toString(), 100),
                      _buildTableCell(category, 120),
                      const Spacer(),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => _showRoomDetails(doc.id, data),
                            tooltip: 'view_details'.tr(),
                            color: Colors.blue,
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_off),
                            onPressed: () => _muteHost(doc.id),
                            tooltip: 'mute_host'.tr(),
                            color: Colors.orange,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            color: Colors.red,
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('close_room'.tr()),
                                  content: Text('close_room_confirm'.tr()),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('cancel'.tr()),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: Text('close'.tr()),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                _closeRoom(doc.id);
                              }
                            },
                            tooltip: 'close_room'.tr(),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    if (_reportedUsers.isEmpty) {
      return Center(child: Text('no_reports'.tr()));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reportedUsers.length,
      itemBuilder: (context, index) {
        final doc = _reportedUsers[index];
        final data = doc.data() as Map<String, dynamic>;
        final reportedUserId = data['reportedUserId'] as String? ?? '';
        final reporterId = data['reporterId'] as String? ?? '';
        final reason = data['reason'] as String? ?? 'Unknown';
        final timestamp = data['timestamp'] is Timestamp 
            ? (data['timestamp'] as Timestamp).toDate()
            : DateTime.now();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'report_reason'.tr()}: $reason',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('${'reported_user_id'.tr()}: $reportedUserId'),
                Text('${'reporter_id'.tr()}: $reporterId'),
                Text('${'timestamp'.tr()}: ${timestamp.toString().substring(0, 19)}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showBanDialog(reportedUserId, 'Reported User'),
                        icon: const Icon(Icons.block, size: 18),
                        label: Text('ban_user'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _firestore.collection('reports').doc(doc.id).update({
                            'status': 'resolved',
                            'resolvedBy': widget.adminAuthController.currentUserId,
                            'resolvedAt': FieldValue.serverTimestamp(),
                          });
                          _loadReportedUsers();
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: Text('resolve'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(String text, double width, String sortField) {
    return InkWell(
      onTap: () {
        setState(() {
          if (_sortField == sortField) {
            _sortAscending = !_sortAscending;
          } else {
            _sortField = sortField;
            _sortAscending = true;
          }
          _sortRooms();
        });
      },
      child: SizedBox(
        width: width,
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (_sortField == sortField)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
