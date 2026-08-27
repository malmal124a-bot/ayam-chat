import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/admin_auth_controller.dart';
import '../../services/database_seeder.dart';
import 'admin_users_screen.dart';
import 'admin_agencies_screen.dart';
import 'admin_store_screen.dart';
import 'admin_moderation_screen.dart';
import 'admin_instant_actions_screen.dart';
import 'admin_financial_logs_screen.dart';
import 'admin_ai_config_screen.dart';
import 'admin_banner_manager_screen.dart';
import 'admin_luck_ratios_screen.dart';
import 'admin_credentials_screen.dart';
import 'admin_gift_box_screen.dart';
import 'admin_vip_svip_screen.dart';
import 'admin_payment_gateway_screen.dart';
import 'admin_badges_notifications_screen.dart';
import 'admin_theme_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  
  const AdminDashboardScreen({
    super.key,
    required this.adminAuthController,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _totalUsers = 0;
  int _activeRooms = 0;
  double _totalSystemBalance = 0.0;
  int _totalTransactions = 0;
  bool _isLoading = true;
  bool _isSeeding = false;
  
  // Dropdown expansion states
  bool _storeExpanded = false;
  bool _vipSvipExpanded = false;
  bool _aiSecurityExpanded = false;
  
  // Quick Top-Up states
  final _targetUserIdController = TextEditingController();
  final _gemsAmountController = TextEditingController();
  String _currencyType = 'gems'; // 'gems' or 'coins'
  bool _isTopUpLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardMetrics();
  }

  @override
  void dispose() {
    _targetUserIdController.dispose();
    _gemsAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardMetrics() async {
    try {
      // Get total users
      final usersSnapshot = await _firestore.collection('users').get();
      _totalUsers = usersSnapshot.size;

      // Get active rooms (rooms with participants)
      final roomsSnapshot = await _firestore.collection('rooms').get();
      _activeRooms = roomsSnapshot.docs.where((doc) {
        final data = doc.data();
        final participantCount = (data['participantCount'] as num?)?.toInt() ?? 0;
        return participantCount > 0;
      }).length;

      // Calculate total system balance (sum of all user balances)
      double totalBalance = 0.0;
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final wallet = data['wallet'] as Map<String, dynamic>?;
        if (wallet != null) {
          final balance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;
          totalBalance += balance;
        }
      }
      _totalSystemBalance = totalBalance;

      // Get total transactions count
      final transactionsCount = await _firestore
          .collectionGroup('transactions')
          .count()
          .get();
      _totalTransactions = transactionsCount.count ?? 0;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard metrics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forceSeedDatabase() async {
    setState(() {
      _isSeeding = true;
    });
    
    try {
      await DatabaseSeeder.seedAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data Seeded Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seeding Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
        });
      }
    }
  }

  Future<void> _quickTopUp() async {
    final targetUserId = _targetUserIdController.text.trim();
    final gemsAmountText = _gemsAmountController.text.trim();
    
    if (targetUserId.isEmpty || gemsAmountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final gemsAmount = int.tryParse(gemsAmountText);
    if (gemsAmount == null || gemsAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isTopUpLoading = true;
    });

    try {
      // Query user by userId OR equippedVanityId OR uid field
      DocumentSnapshot? userDoc;
      
      // First try by exact userId (document ID)
      userDoc = await _firestore.collection('users').doc(targetUserId).get();
      
      // If not found, try by equippedVanityId
      if (!userDoc.exists) {
        final vanityQuery = await _firestore
            .collection('users')
            .where('equippedVanityId', isEqualTo: targetUserId)
            .limit(1)
            .get();
        
        if (vanityQuery.docs.isNotEmpty) {
          userDoc = vanityQuery.docs.first;
        }
      }
      
      // If still not found, try by uid field
      if (userDoc == null || !userDoc.exists) {
        final uidQuery = await _firestore
            .collection('users')
            .where('uid', isEqualTo: targetUserId)
            .limit(1)
            .get();
        
        if (uidQuery.docs.isNotEmpty) {
          userDoc = uidQuery.docs.first;
        }
      }
      
      if (userDoc == null || !userDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User not found'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isTopUpLoading = false;
          });
        }
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? 'Unknown User';
      final actualUserId = userDoc.id;

      // Atomic update of user balance using FieldValue.increment
      final fieldPath = _currencyType == 'gems' ? 'wallet.gems' : 'wallet.coins';
      await _firestore.collection('users').doc(actualUserId).update({
        fieldPath: FieldValue.increment(gemsAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log transaction
      await _firestore.collection('financial_records').add({
        'userId': actualUserId,
        'userName': userName,
        'type': 'admin_topup',
        'currencyType': _currencyType,
        'amount': gemsAmount,
        'adminId': widget.adminAuthController.currentUserId,
        'adminName': widget.adminAuthController.currentUserName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Get updated balance
      final updatedDoc = await _firestore.collection('users').doc(actualUserId).get();
      final updatedData = updatedDoc.data() as Map<String, dynamic>;
      final wallet = updatedData['wallet'] as Map<String, dynamic>?;
      final newBalance = wallet != null 
          ? (_currencyType == 'gems' 
              ? (wallet['gems'] as num?)?.toInt() ?? 0 
              : (wallet['coins'] as num?)?.toInt() ?? 0)
          : 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم الشحن بنجاح! المستخدم: $userName - الرصيد الجديد: $newBalance ${_currencyType == 'gems' ? 'ماسات' : 'ذهبيات'}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
        _targetUserIdController.clear();
        _gemsAmountController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top-up failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTopUpLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(context),
          // Main Content
          Expanded(
            child: _buildMainContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.blue.shade900,
      child: Column(
        children: [
          // Logo/Title & Language Switcher
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'Admin Portal',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Language Switcher
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Locale>(
                      value: context.locale,
                      dropdownColor: Colors.blue.shade900,
                      iconEnabledColor: Colors.white,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: const [
                        DropdownMenuItem(value: Locale('en'), child: Text('English')),
                        DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
                        DropdownMenuItem(value: Locale('es'), child: Text('Español')),
                        DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
                        DropdownMenuItem(value: Locale('de'), child: Text('Deutsch')),
                        DropdownMenuItem(value: Locale('tr'), child: Text('Türkçe')),
                        DropdownMenuItem(value: Locale('hi'), child: Text('हिन्दी')),
                        DropdownMenuItem(value: Locale('pt'), child: Text('Português')),
                        DropdownMenuItem(value: Locale('ru'), child: Text('Русский')),
                        DropdownMenuItem(value: Locale('zh'), child: Text('中文')),
                      ],
                      onChanged: (locale) {
                        if (locale != null) {
                          context.setLocale(locale);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          
          // Navigation Items with Dropdowns
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  icon: Icons.dashboard,
                  title: 'dashboard'.tr(),
                  onTap: () {},
                  isSelected: true,
                ),
                _buildNavItem(
                  icon: Icons.people,
                  title: 'users'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminUsersScreen(
                          adminAuthController: widget.adminAuthController,
                        ),
                      ),
                    );
                  },
                ),
                _buildNavItem(
                  icon: Icons.business,
                  title: 'agencies'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminAgenciesScreen(
                          adminAuthController: widget.adminAuthController,
                        ),
                      ),
                    );
                  },
                ),
                
                // Store Module Dropdown
                _buildDropdownNavItem(
                  icon: Icons.store,
                  title: 'store'.tr(),
                  isExpanded: _storeExpanded,
                  onTap: () {
                    setState(() {
                      _storeExpanded = !_storeExpanded;
                    });
                  },
                  subItems: [
                    _buildSubNavItem(
                      title: 'avatar_frames'.tr(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminStoreScreen(
                              adminAuthController: widget.adminAuthController,
                              initialTab: 0,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildSubNavItem(
                      title: 'entrance_effects'.tr(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminStoreScreen(
                              adminAuthController: widget.adminAuthController,
                              initialTab: 1,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildSubNavItem(
                      title: 'vanity_ids'.tr(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminStoreScreen(
                              adminAuthController: widget.adminAuthController,
                              initialTab: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                // VIP & SVIP Management Dropdown
                _buildDropdownNavItem(
                  icon: Icons.workspace_premium,
                  title: 'vip_svip_management'.tr(),
                  isExpanded: _vipSvipExpanded,
                  onTap: () {
                    setState(() {
                      _vipSvipExpanded = !_vipSvipExpanded;
                    });
                  },
                  subItems: [
                    _buildSubNavItem(
                      title: 'vip_svip_grant'.tr(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminVipSvipScreen(
                              adminAuthController: widget.adminAuthController,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildSubNavItem(
                      title: 'badge_management'.tr(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminVipSvipScreen(
                              adminAuthController: widget.adminAuthController,
                              initialTab: 1,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                // Gift Box Management
                _buildNavItem(
                  icon: Icons.card_giftcard,
                  title: 'gift_box'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminGiftBoxScreen(
                          adminAuthController: widget.adminAuthController,
                        ),
                      ),
                    );
                  },
                ),
                
                // AI Support & Security Policy Center Dropdown
                _buildDropdownNavItem(
                  icon: Icons.psychology,
                  title: 'ai_security_center'.tr(),
                  isExpanded: _aiSecurityExpanded,
                  onTap: () {
                    setState(() {
                      _aiSecurityExpanded = !_aiSecurityExpanded;
                    });
                  },
                  subItems: [
                    _buildSubNavItem(
                      title: 'ai_config'.tr(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminAIConfigScreen(
                              adminAuthController: widget.adminAuthController,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildSubNavItem(
                      title: 'security_policy'.tr(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminAIConfigScreen(
                              adminAuthController: widget.adminAuthController,
                              initialTab: 1,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                // Payment Gateway Controls
                _buildNavItem(
                  icon: Icons.payment,
                  title: 'payment_gateway'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminPaymentGatewayScreen(
                          adminAuthController: widget.adminAuthController,
                        ),
                      ),
                    );
                  },
                ),
                
                // Badges & Notifications
                _buildNavItem(
                  icon: Icons.emoji_events,
                  title: 'badges_notifications'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminBadgesNotificationsScreen(
                          adminAuthController: widget.adminAuthController,
                        ),
                      ),
                    );
                  },
                ),
                
                // App Design & Theme
                _buildNavItem(
                  icon: Icons.palette,
                  title: 'app_design_theme'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminThemeScreen(
                          adminAuthController: widget.adminAuthController,
                        ),
                      ),
                    );
                  },
                ),
                
                const Divider(color: Colors.white24),
                
                _buildNavItem(
                  icon: Icons.gavel,
                  title: 'moderation'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminModerationScreen(
                          adminAuthController: widget.adminAuthController,
                        ),
                      ),
                    );
                  },
                ),
                _buildNavItem(
                  icon: Icons.flash_on,
                  title: 'instant_actions'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminInstantActionsScreen(
                          adminAuthController: widget.adminAuthController,
                        ),
                      ),
                    );
                  },
                ),
                _buildNavItem(
                  icon: Icons.account_balance,
                  title: 'financial_logs'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminFinancialLogsScreen(
                          adminAuthController: widget.adminAuthController,
                        ),
                      ),
                    );
                  },
                ),
                _buildNavItem(
                  icon: Icons.image,
                  title: 'banner_manager'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminBannerManagerScreen(
                          adminAuthController: widget.adminAuthController,
                        ),
                      ),
                    );
                  },
                ),
                _buildNavItem(
                  icon: Icons.casino,
                  title: 'luck_ratios'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminLuckRatiosScreen(
                          adminAuthController: widget.adminAuthController,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.white24),
                _buildNavItem(
                  icon: Icons.admin_panel_settings,
                  title: 'admin_credentials_management'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminCredentialsScreen(
                          adminAuthController: widget.adminAuthController,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // User Info & Logout
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade600,
                      child: Text(
                        widget.adminAuthController.currentUserName?.substring(0, 1).toUpperCase() ?? 'A',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.adminAuthController.currentUserName ?? 'Admin',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.adminAuthController.currentUserRole?.name.toUpperCase() ?? 'USER',
                            style: TextStyle(
                              color: Colors.blue.shade200,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: widget.adminAuthController.logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text('logout'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.blue.shade200),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.blue.shade200,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.shade800,
      onTap: onTap,
    );
  }

  Widget _buildDropdownNavItem({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> subItems,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.blue.shade200),
          title: Text(
            title,
            style: TextStyle(
              color: Colors.blue.shade200,
              fontWeight: FontWeight.normal,
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.blue.shade200,
          ),
          onTap: onTap,
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: subItems,
            ),
          ),
      ],
    );
  }

  Widget _buildSubNavItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: const SizedBox(width: 24),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.blue.shade300,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'dashboard'.tr(),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'welcome_admin'.tr(namedArgs: {
                        'name': widget.adminAuthController.currentUserName ?? 'Admin',
                      }),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSeeding ? null : _forceSeedDatabase,
                      icon: _isSeeding 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.flash_on),
                      label: Text('⚡ FORCE SEED ALL STORE & GIFT DATA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadDashboardMetrics,
                      tooltip: 'refresh'.tr(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Metrics Cards
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.people,
                      title: 'total_users'.tr(),
                      value: _totalUsers.toString(),
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminUsersScreen(
                              adminAuthController: widget.adminAuthController,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.meeting_room,
                      title: 'active_rooms'.tr(),
                      value: _activeRooms.toString(),
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminModerationScreen(
                              adminAuthController: widget.adminAuthController,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.account_balance_wallet,
                      title: 'system_balance'.tr(),
                      value: '\$${_totalSystemBalance.toStringAsFixed(2)}',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminPaymentGatewayScreen(
                              adminAuthController: widget.adminAuthController,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.receipt_long,
                      title: 'total_transactions'.tr(),
                      value: _totalTransactions.toString(),
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminFinancialLogsScreen(
                              adminAuthController: widget.adminAuthController,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            
            // Quick Top-Up Widget
            Card(
              elevation: 6,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Text(
                            'Quick Top-Up (شحن فوري)',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _targetUserIdController,
                              decoration: InputDecoration(
                                labelText: 'أدخل رقم الـ ID للمستخدم',
                                labelStyle: TextStyle(color: Colors.blue.shade100),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(Icons.person, color: Colors.blue.shade900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _gemsAmountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'عدد الماسات / الجواهر',
                                labelStyle: TextStyle(color: Colors.blue.shade100),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(Icons.diamond, color: Colors.blue.shade900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _currencyType,
                                dropdownColor: Colors.white,
                                style: TextStyle(color: Colors.blue.shade900),
                                items: const [
                                  DropdownMenuItem(value: 'gems', child: Text('ماسات / Gems')),
                                  DropdownMenuItem(value: 'coins', child: Text('ذهبيات / Coins')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _currencyType = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isTopUpLoading ? null : _quickTopUp,
                            icon: _isTopUpLoading 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send, size: 20),
                            label: Text('شحن فوراً إلى الحساب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Recent Activity Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'recent_activity'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecentActivityList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collectionGroup('transactions')
          .orderBy('date', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('no_recent_activity'.tr());
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final description = data['description'] as String? ?? 'Transaction';
            final date = data['date'] is Timestamp 
                ? (data['date'] as Timestamp).toDate()
                : DateTime.now();

            return ListTile(
              leading: const Icon(Icons.receipt, color: Colors.blue),
              title: Text(description),
              subtitle: Text(
                date.toString().substring(0, 19),
                style: TextStyle(color: Colors.grey.shade600),
              ),
              trailing: Text(
                '\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: amount >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
