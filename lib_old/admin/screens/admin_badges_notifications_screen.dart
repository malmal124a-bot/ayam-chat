import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/admin_auth_controller.dart';
import '../controllers/admin_rbac_controller.dart';
import '../../models/user_model.dart';

class AdminBadgesNotificationsScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  
  const AdminBadgesNotificationsScreen({
    super.key,
    required this.adminAuthController,
  });

  @override
  State<AdminBadgesNotificationsScreen> createState() => _AdminBadgesNotificationsScreenState();
}

class _AdminBadgesNotificationsScreenState extends State<AdminBadgesNotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _rbacController = AdminRBACController();
  
  final _userIdController = TextEditingController();
  final _badgeNameController = TextEditingController();
  final _notificationTitleController = TextEditingController();
  final _notificationBodyController = TextEditingController();

  UserModel? _targetUser;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rbacController.loadAllAdmins();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _badgeNameController.dispose();
    _notificationTitleController.dispose();
    _notificationBodyController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        setState(() {
          _targetUser = UserModel.fromFirestore(doc.id, doc.data()!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'User not found';
          _targetUser = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user: $e';
        _targetUser = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _assignBadge() async {
    if (_targetUser == null) return;
    final badgeName = _badgeNameController.text.trim();
    if (badgeName.isEmpty) return;

    try {
      final currentBadges = _targetUser!.badges ?? [];
      if (!currentBadges.contains(badgeName)) {
        currentBadges.add(badgeName);
      }

      await _firestore.collection('users').doc(_targetUser!.id).update({
        'badges': currentBadges,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('badge_assigned'.tr(namedArgs: {'badge': badgeName})),
          backgroundColor: Colors.green,
        ),
      );
      _loadUser();
      _badgeNameController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('assign_failed'.tr(namedArgs: {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _modifyUserLevel() async {
    if (_targetUser == null) return;

    int newLevel = 0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('modify_level'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${'current_level'.tr()}: ${_targetUser!.level}'),
              const SizedBox(height: 16),
              Text('new_level'.tr()),
              Slider(
                value: newLevel.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                label: 'Level $newLevel',
                onChanged: (value) {
                  setDialogState(() => newLevel = value.toInt());
                },
              ),
              Text('Level $newLevel'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                await _firestore.collection('users').doc(_targetUser!.id).update({
                  'level': newLevel,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (!mounted) return;
                navigator.pop();
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('level_updated'.tr()),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadUser();
              },
              child: Text('update'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendSystemNotification() async {
    final title = _notificationTitleController.text.trim();
    final body = _notificationBodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('invalid_input'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('system_notifications').add({
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': widget.adminAuthController.currentUserId,
        'isActive': true,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('notification_sent'.tr()),
          backgroundColor: Colors.green,
        ),
      );
      _notificationTitleController.clear();
      _notificationBodyController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('send_failed'.tr(namedArgs: {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('badges_notifications'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: Colors.blue.shade900,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue.shade900,
                  tabs: [
                    Tab(text: 'badges'.tr()),
                    Tab(text: 'user_level'.tr()),
                    Tab(text: 'notifications'.tr()),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildBadgesTab(),
                    _buildUserLevelTab(),
                    _buildNotificationsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userIdController,
                      decoration: InputDecoration(
                        labelText: 'user_id'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadUser,
                    icon: const Icon(Icons.search),
                    label: Text('search'.tr()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!)),
                  ],
                ),
              ),
            ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_targetUser != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _targetUser!.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('ID: ${_targetUser!.id}'),
                    Text('Level: ${_targetUser!.level}'),
                    Text('Badges: ${(_targetUser!.badges ?? []).join(", ")}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'assign_badge'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _badgeNameController,
                      decoration: InputDecoration(
                        labelText: 'badge_name'.tr(),
                        hintText: 'e.g., VIP, Moderator, Top Supporter',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _assignBadge,
                      icon: const Icon(Icons.add),
                      label: Text('assign_badge'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserLevelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userIdController,
                      decoration: InputDecoration(
                        labelText: 'user_id'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadUser,
                    icon: const Icon(Icons.search),
                    label: Text('search'.tr()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_targetUser != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _targetUser!.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('ID: ${_targetUser!.id}'),
                    Text('Current Level: ${_targetUser!.level}'),
                    Text('XP: ${_targetUser!.currentXP}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _modifyUserLevel,
              icon: const Icon(Icons.edit),
              label: Text('modify_level'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'send_system_notification'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notificationTitleController,
                decoration: InputDecoration(
                  labelText: 'notification_title'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notificationBodyController,
                decoration: InputDecoration(
                  labelText: 'notification_body'.tr(),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _sendSystemNotification,
                icon: const Icon(Icons.send),
                label: Text('send_notification'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
