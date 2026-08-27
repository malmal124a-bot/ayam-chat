import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/admin_auth_controller.dart';
import '../controllers/admin_rbac_controller.dart';
import '../../models/user_model.dart';

class AdminInstantActionsScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  
  const AdminInstantActionsScreen({
    super.key,
    required this.adminAuthController,
  });

  @override
  State<AdminInstantActionsScreen> createState() => _AdminInstantActionsScreenState();
}

class _AdminInstantActionsScreenState extends State<AdminInstantActionsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _rbacController = AdminRBACController();
  final _userIdController = TextEditingController();
  final _customIdController = TextEditingController();
  final _reasonController = TextEditingController();
  
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
    _customIdController.dispose();
    _reasonController.dispose();
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
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading user: $e';
        _targetUser = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _grantVIP(int level, int durationDays) async {
    if (_targetUser == null) return;
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.modifyFinancials,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('financial_access_denied'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final expiresAt = DateTime.now().add(Duration(days: durationDays));
      await _firestore.collection('users').doc(_targetUser!.id).update({
        'vipLevel': level,
        'svipExpiresAt': Timestamp.fromDate(expiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('VIP $level granted for $durationDays days'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to grant VIP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _grantSVIP(int level, int durationDays) async {
    if (_targetUser == null) return;
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.modifyFinancials,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('financial_access_denied'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final expiresAt = DateTime.now().add(Duration(days: durationDays));
      await _firestore.collection('users').doc(_targetUser!.id).update({
        'svipLevel': level,
        'svipExpiresAt': Timestamp.fromDate(expiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SVIP $level granted for $durationDays days'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to grant SVIP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _assignCustomId() async {
    if (_targetUser == null) return;
    final customId = _customIdController.text.trim();
    if (customId.isEmpty) return;

    try {
      // Check if custom ID already exists
      final existing = await _firestore
          .collection('users')
          .where('customNumericId', isEqualTo: customId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Custom ID already in use'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _firestore.collection('users').doc(_targetUser!.id).update({
        'customNumericId': customId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Custom ID $customId assigned'),
          backgroundColor: Colors.green,
        ),
      );
      _customIdController.clear();
      _loadUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign custom ID: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _grantRechargeAgency() async {
    if (_targetUser == null) return;
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.modifyFinancials,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('financial_access_denied'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('users').doc(_targetUser!.id).update({
        'isRechargeAgency': true,
        'agencyType': 'recharge',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recharge Agency granted to ${_targetUser!.name}'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to grant Recharge Agency: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _revokeRechargeAgency() async {
    if (_targetUser == null) return;
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.modifyFinancials,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('financial_access_denied'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('users').doc(_targetUser!.id).update({
        'isRechargeAgency': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recharge Agency revoked from ${_targetUser!.name}'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to revoke Recharge Agency: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _grantModeratorAgency() async {
    if (_targetUser == null) return;
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.manageModerators,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('moderator_access_denied'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('users').doc(_targetUser!.id).update({
        'isModeratorAgency': true,
        'agencyType': 'moderator',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moderator Agency granted to ${_targetUser!.name}'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to grant Moderator Agency: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _revokeModeratorAgency() async {
    if (_targetUser == null) return;
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.manageModerators,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('moderator_access_denied'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('users').doc(_targetUser!.id).update({
        'isModeratorAgency': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moderator Agency revoked from ${_targetUser!.name}'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to revoke Moderator Agency: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _grantTimedItem(String itemId, int durationDays) async {
    if (_targetUser == null) return;

    try {
      final expiresAt = DateTime.now().add(Duration(days: durationDays));
      final currentItems = _targetUser!.timedStoreItems ?? {};
      currentItems[itemId] = expiresAt;

      await _firestore.collection('users').doc(_targetUser!.id).update({
        'timedStoreItems': currentItems.map(
          (k, v) => MapEntry(k, Timestamp.fromDate(v)),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item $itemId granted for $durationDays days'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to grant item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _hardcoreBan({
    required bool permanent,
    int? durationDays,
    bool banDevice = false,
    bool banIP = false,
    bool globalMute = false,
    bool forceKick = false,
  }) async {
    if (_targetUser == null) return;
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ban_reason'.tr())),
      );
      return;
    }

    try {
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(_targetUser!.id);

      DateTime? expiresAt;
      if (!permanent && durationDays != null) {
        expiresAt = DateTime.now().add(Duration(days: durationDays));
      }

      batch.update(userRef, {
        'isBanned': true,
        'banReason': _reasonController.text,
        'banExpiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'bannedBy': widget.adminAuthController.currentUserId,
        'bannedAt': FieldValue.serverTimestamp(),
      });

      // Device ban
      if (banDevice && _targetUser!.deviceId != null) {
        batch.set(
          _firestore.collection('banned_devices').doc(_targetUser!.deviceId),
          {
            'deviceId': _targetUser!.deviceId,
            'userId': _targetUser!.id,
            'bannedAt': FieldValue.serverTimestamp(),
            'bannedBy': widget.adminAuthController.currentUserId,
          },
          SetOptions(merge: true),
        );
      }

      // IP ban
      if (banIP && _targetUser!.ipAddress != null) {
        batch.set(
          _firestore.collection('banned_ips').doc(_targetUser!.ipAddress),
          {
            'ipAddress': _targetUser!.ipAddress,
            'userId': _targetUser!.id,
            'bannedAt': FieldValue.serverTimestamp(),
            'bannedBy': widget.adminAuthController.currentUserId,
          },
          SetOptions(merge: true),
        );
      }

      // Global mute
      if (globalMute) {
        batch.update(userRef, {
          'isGloballyMuted': true,
          'globalMuteReason': _reasonController.text,
        });
      }

      // Force kick from room
      if (forceKick && _targetUser!.currentRoomId != null) {
        batch.update(
          _firestore.collection('rooms').doc(_targetUser!.currentRoomId),
          {
            'participantCount': FieldValue.increment(-1),
          },
        );
        batch.update(userRef, {
          'currentRoomId': null,
          'currentRoomName': null,
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User banned successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _reasonController.clear();
      _loadUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ban user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showVIPDialog() {
    int selectedLevel = 1;
    int selectedDays = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('grant_vip'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('vip_level'.tr()),
              Slider(
                value: selectedLevel.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: 'VIP $selectedLevel',
                onChanged: (value) {
                  setDialogState(() => selectedLevel = value.toInt());
                },
              ),
              Text('VIP $selectedLevel'),
              const SizedBox(height: 16),
              Text('duration_days'.tr()),
              DropdownButton<int>(
                value: selectedDays,
                items: [7, 30, 90, 365].map((days) {
                  return DropdownMenuItem(
                    value: days,
                    child: Text('$days days'),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedDays = value!);
                },
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
                _grantVIP(selectedLevel, selectedDays);
                Navigator.pop(context);
              },
              child: Text('grant_vip'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _showSVIPDialog() {
    int selectedLevel = 1;
    int selectedDays = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('grant_svip'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('svip_level'.tr()),
              Slider(
                value: selectedLevel.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: 'SVIP $selectedLevel',
                onChanged: (value) {
                  setDialogState(() => selectedLevel = value.toInt());
                },
              ),
              Text('SVIP $selectedLevel'),
              const SizedBox(height: 16),
              Text('duration_days'.tr()),
              DropdownButton<int>(
                value: selectedDays,
                items: [7, 30, 90, 365].map((days) {
                  return DropdownMenuItem(
                    value: days,
                    child: Text('$days days'),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedDays = value!);
                },
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
                _grantSVIP(selectedLevel, selectedDays);
                Navigator.pop(context);
              },
              child: Text('grant_svip'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomIdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('assign_custom_id'.tr()),
        content: TextField(
          controller: _customIdController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'numeric_id'.tr(),
            hintText: 'e.g., 7777, 1000',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              _assignCustomId();
              Navigator.pop(context);
            },
            child: Text('assign_custom_id'.tr()),
          ),
        ],
      ),
    );
  }

  void _showTimedItemDialog() {
    final itemIdController = TextEditingController();
    int selectedDays = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('grant_item'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemIdController,
                decoration: InputDecoration(
                  labelText: 'item_id'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('duration_days'.tr()),
              DropdownButton<int>(
                value: selectedDays,
                items: [7, 30, 90, 365].map((days) {
                  return DropdownMenuItem(
                    value: days,
                    child: Text('$days days'),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedDays = value!);
                },
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
                _grantTimedItem(itemIdController.text, selectedDays);
                Navigator.pop(context);
              },
              child: Text('grant_item'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _showHardcoreBanDialog() {
    bool permanent = false;
    int? durationDays = 7;
    bool banDevice = false;
    bool banIP = false;
    bool globalMute = false;
    bool forceKick = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('hardcore_ban'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'ban_reason'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('permanent_ban'.tr()),
                  value: permanent,
                  onChanged: (value) {
                    setDialogState(() => permanent = value);
                  },
                ),
                if (!permanent)
                  DropdownButton<int>(
                    value: durationDays,
                    items: [1, 7, 30, 90, 365].map((days) {
                      return DropdownMenuItem(
                        value: days,
                        child: Text('$days days'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => durationDays = value);
                    },
                  ),
                SwitchListTile(
                  title: Text('device_ban'.tr()),
                  subtitle: Text('device_fingerprint'.tr()),
                  value: banDevice,
                  onChanged: (value) {
                    setDialogState(() => banDevice = value);
                  },
                ),
                SwitchListTile(
                  title: Text('ip_ban'.tr()),
                  value: banIP,
                  onChanged: (value) {
                    setDialogState(() => banIP = value);
                  },
                ),
                SwitchListTile(
                  title: Text('global_mute'.tr()),
                  value: globalMute,
                  onChanged: (value) {
                    setDialogState(() => globalMute = value);
                  },
                ),
                SwitchListTile(
                  title: Text('force_kick'.tr()),
                  value: forceKick,
                  onChanged: (value) {
                    setDialogState(() => forceKick = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                _hardcoreBan(
                  permanent: permanent,
                  durationDays: durationDays,
                  banDevice: banDevice,
                  banIP: banIP,
                  globalMute: globalMute,
                  forceKick: forceKick,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('ban'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('instant_actions'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Search
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
                // User Info Card
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
                        Text('Custom ID: ${_targetUser!.customNumericId ?? "None"}'),
                        Text('VIP Level: ${_targetUser!.vipLevel}'),
                        Text('SVIP Level: ${_targetUser!.svipLevel}'),
                        if (_targetUser!.svipExpiresAt != null)
                          Text('SVIP Expires: ${_targetUser!.svipExpiresAt.toString().substring(0, 10)}'),
                        Text('Role: ${_targetUser!.role.name}'),
                        if (_targetUser!.adminAccessExpiresAt != null)
                          Text('Admin Access Expires: ${_targetUser!.adminAccessExpiresAt.toString().substring(0, 10)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2,
                  children: [
                    _buildActionButton(
                      icon: Icons.card_membership,
                      label: 'vip_svip_grant'.tr(),
                      color: Colors.amber,
                      onTap: _showVIPDialog,
                    ),
                    _buildActionButton(
                      icon: Icons.workspace_premium,
                      label: 'grant_svip'.tr(),
                      color: Colors.purple,
                      onTap: _showSVIPDialog,
                    ),
                    _buildActionButton(
                      icon: Icons.tag,
                      label: 'custom_id'.tr(),
                      color: Colors.blue,
                      onTap: _showCustomIdDialog,
                    ),
                    _buildActionButton(
                      icon: Icons.inventory_2,
                      label: 'timed_items'.tr(),
                      color: Colors.green,
                      onTap: _showTimedItemDialog,
                    ),
                    _buildActionButton(
                      icon: Icons.account_balance_wallet,
                      label: 'Recharge Agency',
                      color: Colors.teal,
                      onTap: _targetUser?.isRechargeAgency == true ? _revokeRechargeAgency : _grantRechargeAgency,
                    ),
                    _buildActionButton(
                      icon: Icons.admin_panel_settings,
                      label: 'Moderator Agency',
                      color: Colors.indigo,
                      onTap: _targetUser?.isModeratorAgency == true ? _revokeModeratorAgency : _grantModeratorAgency,
                    ),
                    _buildActionButton(
                      icon: Icons.block,
                      label: 'hardcore_ban'.tr(),
                      color: Colors.red,
                      onTap: _showHardcoreBanDialog,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
