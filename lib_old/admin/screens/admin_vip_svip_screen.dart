import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/admin_auth_controller.dart';
import '../controllers/admin_rbac_controller.dart';
import '../../models/user_model.dart';

class AdminVipSvipScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  final int initialTab;
  
  const AdminVipSvipScreen({
    super.key,
    required this.adminAuthController,
    this.initialTab = 0,
  });

  @override
  State<AdminVipSvipScreen> createState() => _AdminVipSvipScreenState();
}

class _AdminVipSvipScreenState extends State<AdminVipSvipScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _rbacController = AdminRBACController();
  final _userIdController = TextEditingController();
  
  UserModel? _targetUser;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Badge management states
  List<Map<String, dynamic>> _vipTiers = [];
  bool _isLoadingTiers = false;

  @override
  void initState() {
    super.initState();
    _rbacController.loadAllAdmins();
    _loadVipTiers();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _loadVipTiers() async {
    setState(() {
      _isLoadingTiers = true;
    });

    try {
      final snapshot = await _firestore.collection('vip_tiers').orderBy('level').get();
      setState(() {
        _vipTiers = snapshot.docs.map((doc) => doc.data()).toList();
        _isLoadingTiers = false;
      });
    } catch (e) {
      debugPrint('Error loading VIP tiers: $e');
      setState(() {
        _isLoadingTiers = false;
      });
    }
  }

  Future<void> _updateVipTier(String tierId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('vip_tiers').doc(tierId).update(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('VIP tier updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadVipTiers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update VIP tier: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditBadgeDialog(Map<String, dynamic> tier) {
    final levelController = TextEditingController(text: tier['level']?.toString() ?? '');
    final nameController = TextEditingController(text: tier['name']?.toString() ?? '');
    final priceController = TextEditingController(text: tier['price']?.toString() ?? '');
    final iconPathController = TextEditingController(text: tier['badgeIcon']?.toString() ?? '');
    final diamondBonusController = TextEditingController(text: tier['diamondBonus']?.toString() ?? '');
    final privilegesController = TextEditingController(text: tier['privileges']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Badge: ${tier['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: levelController,
                decoration: InputDecoration(labelText: 'Level'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: iconPathController,
                decoration: InputDecoration(labelText: 'Badge Icon Path (URL/Asset)'),
              ),
              TextField(
                controller: diamondBonusController,
                decoration: InputDecoration(labelText: 'Diamond Bonus'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: privilegesController,
                decoration: InputDecoration(labelText: 'Privileges (comma-separated)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedData = {
                'level': int.tryParse(levelController.text) ?? tier['level'],
                'name': nameController.text,
                'price': int.tryParse(priceController.text) ?? tier['price'],
                'badgeIcon': iconPathController.text,
                'diamondBonus': int.tryParse(diamondBonusController.text) ?? tier['diamondBonus'],
                'privileges': privilegesController.text.split(',').map((p) => p.trim()).toList(),
                'updatedAt': FieldValue.serverTimestamp(),
              };
              _updateVipTier(tier['id'] ?? tier['level'].toString(), updatedData);
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddBadgeDialog() {
    final levelController = TextEditingController();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final iconPathController = TextEditingController();
    final diamondBonusController = TextEditingController();
    final privilegesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New VIP Tier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: levelController,
                decoration: InputDecoration(labelText: 'Level'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: iconPathController,
                decoration: InputDecoration(labelText: 'Badge Icon Path (URL/Asset)'),
              ),
              TextField(
                controller: diamondBonusController,
                decoration: InputDecoration(labelText: 'Diamond Bonus'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: privilegesController,
                decoration: InputDecoration(labelText: 'Privileges (comma-separated)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTierId = 'vip_${levelController.text}';
              final newTierData = {
                'id': newTierId,
                'level': int.tryParse(levelController.text) ?? 1,
                'name': nameController.text,
                'price': int.tryParse(priceController.text) ?? 0,
                'badgeIcon': iconPathController.text,
                'diamondBonus': int.tryParse(diamondBonusController.text) ?? 0,
                'privileges': privilegesController.text.split(',').map((p) => p.trim()).toList(),
                'isActive': true,
                'createdAt': FieldValue.serverTimestamp(),
              };
              try {
                await _firestore.collection('vip_tiers').doc(newTierId).set(newTierData);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('VIP tier added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                _loadVipTiers();
                Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add VIP tier: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
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
      final expiresAt = durationDays == 365 * 10 ? null : DateTime.now().add(Duration(days: durationDays));
      await _firestore.collection('users').doc(_targetUser!.id).update({
        'vipLevel': level,
        'svipExpiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('VIP $level granted for ${durationDays == 365 * 10 ? 'Permanent' : '$durationDays days'}'),
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
      final expiresAt = durationDays == 365 * 10 ? null : DateTime.now().add(Duration(days: durationDays));
      await _firestore.collection('users').doc(_targetUser!.id).update({
        'svipLevel': level,
        'svipExpiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SVIP $level granted for ${durationDays == 365 * 10 ? 'Permanent' : '$durationDays days'}'),
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
                items: [7, 30, 90, 365, 3650].map((days) {
                  return DropdownMenuItem(
                    value: days,
                    child: Text(days == 3650 ? 'Permanent' : '$days days'),
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
                items: [7, 30, 90, 365, 3650].map((days) {
                  return DropdownMenuItem(
                    value: days,
                    child: Text(days == 3650 ? 'Permanent' : '$days days'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('vip_svip_management'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: DefaultTabController(
          initialIndex: widget.initialTab,
          length: 2,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: Colors.blue.shade900,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue.shade900,
                  tabs: [
                    Tab(text: 'vip_svip_grant'.tr()),
                    Tab(text: 'badge_management'.tr()),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildGrantTab(),
                    _buildBadgeManagementTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrantTab() {
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
                    Text('VIP Level: ${_targetUser!.vipLevel}'),
                    Text('SVIP Level: ${_targetUser!.svipLevel}'),
                    if (_targetUser!.svipExpiresAt != null)
                      Text('Expires: ${_targetUser!.svipExpiresAt.toString().substring(0, 10)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showVIPDialog,
                    icon: const Icon(Icons.card_membership),
                    label: Text('grant_vip'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showSVIPDialog,
                    icon: const Icon(Icons.workspace_premium),
                    label: Text('grant_svip'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeManagementTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VIP/SVIP Badge Management',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddBadgeDialog,
                icon: const Icon(Icons.add),
                label: Text('Add New Tier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingTiers
              ? const Center(child: CircularProgressIndicator())
              : _vipTiers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No VIP tiers configured',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vipTiers.length,
                      itemBuilder: (context, index) {
                        final tier = _vipTiers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: tier['level']?.toString().contains('SVIP') == true 
                                  ? Colors.purple 
                                  : Colors.amber,
                              child: Text(
                                tier['level']?.toString() ?? '?',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(tier['name']?.toString() ?? 'Unknown'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Price: ${tier['price']?.toString() ?? '0'}'),
                                Text('Diamond Bonus: ${tier['diamondBonus']?.toString() ?? '0'}'),
                                if (tier['badgeIcon'] != null)
                                  Text('Icon: ${tier['badgeIcon']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showEditBadgeDialog(tier),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Delete Tier'),
                                        content: Text('Are you sure you want to delete ${tier['name']}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await _firestore.collection('vip_tiers').doc(tier['id'] ?? tier['level'].toString()).delete();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Tier deleted successfully'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                        _loadVipTiers();
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to delete tier: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
