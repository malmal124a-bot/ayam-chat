import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/admin_auth_controller.dart';
import '../controllers/admin_rbac_controller.dart';
import '../../models/user_model.dart';

class AdminCredentialsScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  
  const AdminCredentialsScreen({
    super.key,
    required this.adminAuthController,
  });

  @override
  State<AdminCredentialsScreen> createState() => _AdminCredentialsScreenState();
}

class _AdminCredentialsScreenState extends State<AdminCredentialsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _rbacController = AdminRBACController();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  List<UserModel> _allAdmins = [];
  bool _isLoading = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', whereIn: [
            'owner',
            'regional_manager',
            'app_manager',
            'super_admin',
            'agency_admin',
            'banner_admin',
            'moderator',
          ])
          .get();

      setState(() {
        _allAdmins = snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc.id, doc.data()))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading admins: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createAdminAccount({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    List<String>? permissions,
    int? durationDays,
  }) async {
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.grantRoles,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient permissions to create admin accounts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Owner role cannot be granted by non-owners
    if (role == UserRole.owner && widget.adminAuthController.currentUserRole != UserRole.owner) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only Owner can grant Owner role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Calculate expiration if duration is set
      DateTime? expiresAt;
      if (durationDays != null && durationDays > 0) {
        expiresAt = DateTime.now().add(Duration(days: durationDays));
      }

      // Create Firestore user document
      await _firestore.collection('users').doc(userId).set({
        'id': userId,
        'name': name,
        'email': email,
        'profilePic': '',
        'gender': 'other',
        'level': 1,
        'currentXP': 0,
        'vipLevel': 0,
        'svipLevel': 0,
        'wealthLevel': 1,
        'magicLevel': 1,
        'nobleLevel': 1,
        'wealthXP': 0,
        'magicXP': 0,
        'nobleXP': 0,
        'globalScore': 0,
        'followersCount': 0,
        'visitorsCount': 0,
        'friendsCount': 0,
        'likesCount': 0,
        'role': role.name,
        'permissions': permissions ?? [],
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
        'adminAccessExpiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'isBanned': false,
        'wallet': {
          'balance': 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': widget.adminAuthController.currentUserId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin account created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      
      await _loadAdmins();
      if (!mounted) return;
      setState(() {
        _isCreating = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getAuthErrorMessage(e.code)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create admin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetPassword(String userId, String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send password reset: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _revokeAccess(String userId) async {
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.revokeRoles,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient permissions to revoke access'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'role': UserRole.user.name,
        'adminAccessExpiresAt': null,
        'revokedAt': FieldValue.serverTimestamp(),
        'revokedBy': widget.adminAuthController.currentUserId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin access revoked'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadAdmins();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to revoke access: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _extendDuration(String userId, int extraDays) async {
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.grantTimedAccess,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient permissions to extend duration'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final data = userDoc.data();
      final currentExpiresAt = data?['adminAccessExpiresAt'] is Timestamp
          ? (data!['adminAccessExpiresAt'] as Timestamp).toDate()
          : DateTime.now();

      final newExpiresAt = currentExpiresAt.add(Duration(days: extraDays));

      await _firestore.collection('users').doc(userId).update({
        'adminAccessExpiresAt': Timestamp.fromDate(newExpiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access extended by $extraDays days'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAdmins();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to extend duration: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateAdminDialog() {
    UserRole selectedRole = UserRole.moderator;
    int? durationDays;
    final permissionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('create_admin_account'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'email'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'password'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'name'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButton<UserRole>(
                  value: selectedRole,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: UserRole.regionalManager, child: Text('regional_manager_role'.tr())),
                    DropdownMenuItem(value: UserRole.appManager, child: Text('app_manager_role'.tr())),
                    DropdownMenuItem(value: UserRole.superAdmin, child: Text('super_admin_role'.tr())),
                    DropdownMenuItem(value: UserRole.agencyAdmin, child: Text('agency_admin_role'.tr())),
                    DropdownMenuItem(value: UserRole.bannerAdmin, child: Text('banner_admin_role'.tr())),
                    DropdownMenuItem(value: UserRole.moderator, child: Text('moderator_role'.tr())),
                    if (widget.adminAuthController.currentUserRole == UserRole.owner)
                      DropdownMenuItem(value: UserRole.owner, child: Text('owner_role'.tr())),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedRole = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: permissionsController,
                  decoration: InputDecoration(
                    labelText: 'permissions'.tr(),
                    hintText: 'comma separated',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButton<int?>(
                  value: durationDays,
                  isExpanded: true,
                  hint: Text('access_duration'.tr()),
                  items: [
                    DropdownMenuItem(value: null, child: Text('permanent'.tr())),
                    DropdownMenuItem(value: 7, child: Text('7 days')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                    DropdownMenuItem(value: 90, child: Text('90 days')),
                    DropdownMenuItem(value: 365, child: Text('365 days')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => durationDays = value);
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
              onPressed: _isCreating
                  ? null
                  : () {
                      final permissions = permissionsController.text
                          .split(',')
                          .map((p) => p.trim())
                          .where((p) => p.isNotEmpty)
                          .toList();
                      
                      _createAdminAccount(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                        name: _nameController.text.trim(),
                        role: selectedRole,
                        permissions: permissions.isEmpty ? null : permissions,
                        durationDays: durationDays,
                      );
                      Navigator.pop(context);
                    },
              child: _isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('create'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _showExtendDialog(String userId) {
    int selectedDays = 30;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('extend_duration'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int>(
              value: selectedDays,
              items: [
                DropdownMenuItem(value: 7, child: Text('7 days')),
                DropdownMenuItem(value: 30, child: Text('30 days')),
                DropdownMenuItem(value: 90, child: Text('90 days')),
                DropdownMenuItem(value: 365, child: Text('365 days')),
              ],
              onChanged: (value) {
                setState(() => selectedDays = value!);
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
              _extendDuration(userId, selectedDays);
              Navigator.pop(context);
            },
            child: Text('extend'.tr()),
          ),
        ],
      ),
    );
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Email/password accounts not enabled';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Authentication failed: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('admin_credentials_management'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdmins,
            tooltip: 'refresh'.tr(),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            // Create Admin Button
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: ElevatedButton.icon(
                onPressed: _showCreateAdminDialog,
                icon: const Icon(Icons.person_add),
                label: Text('create_admin_account'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            // Admins Table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
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
                            child: const Row(
                              children: [
                                Expanded(flex: 2, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Created', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Expires', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 3, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          
                          // Table Body
                          Expanded(
                            child: _allAdmins.isEmpty
                                ? Center(child: Text('no_admins_found'.tr()))
                                : ListView.builder(
                                    itemCount: _allAdmins.length,
                                    itemBuilder: (context, index) {
                                      final admin = _allAdmins[index];
                                      final isExpired = admin.adminAccessExpiresAt != null &&
                                          admin.adminAccessExpiresAt!.isBefore(DateTime.now());
                                      final isOwner = admin.role == UserRole.owner;
                                      
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
                                            Expanded(flex: 2, child: Text(admin.name)),
                                            Expanded(flex: 2, child: Text('${admin.id.substring(0, 8)}...')),
                                            Expanded(
                                              flex: 2,
                                              child: _buildRoleChip(admin.role),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text('Recently'),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: admin.adminAccessExpiresAt != null
                                                  ? Text(
                                                      admin.adminAccessExpiresAt.toString().substring(0, 10),
                                                      style: TextStyle(
                                                        color: isExpired ? Colors.red : Colors.green,
                                                      ),
                                                    )
                                                  : const Text('Permanent'),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: _buildStatusChip(isExpired, isOwner),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.lock_reset),
                                                    onPressed: () => _resetPassword(admin.id, admin.id),
                                                    tooltip: 'reset_password'.tr(),
                                                    color: Colors.blue,
                                                  ),
                                                  if (!isOwner)
                                                    IconButton(
                                                      icon: const Icon(Icons.block),
                                                      onPressed: () => _revokeAccess(admin.id),
                                                      tooltip: 'revoke_access'.tr(),
                                                      color: Colors.orange,
                                                    ),
                                                  if (admin.adminAccessExpiresAt != null && !isOwner)
                                                    IconButton(
                                                      icon: const Icon(Icons.access_time),
                                                      onPressed: () => _showExtendDialog(admin.id),
                                                      tooltip: 'extend_duration'.tr(),
                                                      color: Colors.green,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(UserRole role) {
    Color color;
    switch (role) {
      case UserRole.owner:
        color = Colors.purple;
        break;
      case UserRole.regionalManager:
        color = Colors.blue;
        break;
      case UserRole.appManager:
        color = Colors.teal;
        break;
      case UserRole.superAdmin:
        color = Colors.orange;
        break;
      case UserRole.agencyAdmin:
        color = Colors.green;
        break;
      case UserRole.bannerAdmin:
        color = Colors.pink;
        break;
      case UserRole.moderator:
        color = Colors.amber;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isExpired, bool isOwner) {
    if (isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple),
        ),
        child: Text(
          'OWNER',
          style: TextStyle(
            color: Colors.purple,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    if (isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red),
        ),
        child: Text(
          'EXPIRED',
          style: TextStyle(
            color: Colors.red,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Text(
        'ACTIVE',
        style: TextStyle(
          color: Colors.green,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
