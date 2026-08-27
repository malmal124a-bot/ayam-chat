import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/admin_auth_controller.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart' as tx;

class AdminUsersScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  
  const AdminUsersScreen({
    super.key,
    required this.adminAuthController,
  });

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  List<tx.Transaction> _userTransactions = [];
  bool _isLoading = true;
  bool _isTransactionsLoading = false;
  String _selectedUserId = '';
  bool _isRechargeMode = true;
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  String _sortField = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadUsersRealTime();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _loadUsersRealTime() {
    _firestore.collection('users').orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
      try {
        setState(() {
          _allUsers = snapshot.docs.map((doc) {
            try {
              return UserModel.fromFirestore(doc.id, doc.data());
            } catch (e) {
              debugPrint('Error parsing user ${doc.id}: $e');
              return UserModel(
                id: doc.id,
                name: doc.data()['name'] as String? ?? 'Unknown',
                profilePic: doc.data()['profilePic'] as String? ?? '',
                gender: doc.data()['gender'] as String? ?? 'other',
                level: (doc.data()['level'] as num?)?.toInt() ?? 1,
                vipLevel: (doc.data()['vipLevel'] as num?)?.toInt() ?? 0,
              );
            }
          }).toList();
          _filteredUsers = List.from(_allUsers);
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error loading users: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }, onError: (error) {
      debugPrint('Stream error: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _loadUsers() async {
    // Fallback method for initial load
    try {
      final snapshot = await _firestore.collection('users').get();
      setState(() {
        _allUsers = snapshot.docs.map((doc) => UserModel.fromFirestore(doc.id, doc.data())).toList();
        _filteredUsers = List.from(_allUsers);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserTransactions(String userId) async {
    setState(() {
      _isTransactionsLoading = true;
    });
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(50)
          .get();
      setState(() {
        _userTransactions = snapshot.docs
            .map((doc) => tx.Transaction.fromFirestore(doc.data()))
            .toList();
        _isTransactionsLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      setState(() {
        _isTransactionsLoading = false;
      });
    }
  }

  Future<void> _deepSearchUser(String query) async {
    if (query.isEmpty) {
      _loadUsers();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Search by user ID
      final idSnapshot = await _firestore.collection('users').doc(query).get();
      
      // Search by phone number (assuming phone is stored in user document)
      final phoneSnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: query)
          .limit(1)
          .get();

      List<UserModel> results = [];
      
      if (idSnapshot.exists) {
        results.add(UserModel.fromFirestore(idSnapshot.id, idSnapshot.data()!));
      }
      
      for (var doc in phoneSnapshot.docs) {
        results.add(UserModel.fromFirestore(doc.id, doc.data()));
      }

      setState(() {
        _allUsers = results;
        _filteredUsers = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error in deep search: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers = _allUsers.where((user) {
          return user.name.toLowerCase().contains(query) ||
                 user.id.toLowerCase().contains(query) ||
                 user.profilePic.toLowerCase().contains(query);
        }).toList();
      }
      _currentPage = 1;
    });
  }

  void _sortUsers(String field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }

      _filteredUsers.sort((a, b) {
        dynamic valueA;
        dynamic valueB;

        switch (field) {
          case 'name':
            valueA = a.name.toLowerCase();
            valueB = b.name.toLowerCase();
            break;
          case 'level':
            valueA = a.level;
            valueB = b.level;
            break;
          case 'vipLevel':
            valueA = a.vipLevel;
            valueB = b.vipLevel;
            break;
          case 'balance':
            valueA = 0; // Will be fetched from wallet
            valueB = 0;
            break;
          default:
            valueA = a.name;
            valueB = b.name;
        }

        if (_sortAscending) {
          return valueA.compareTo(valueB);
        } else {
          return valueB.compareTo(valueA);
        }
      });
    });
  }

  Future<double> _getUserBalance(String userId) async {
    try {
      final walletDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('current')
          .get();
      if (walletDoc.exists) {
        return (walletDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      debugPrint('Error fetching user balance: $e');
      return 0.0;
    }
  }

  Future<int> _getUserDiamonds(String userId) async {
    try {
      final walletDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallet')
          .doc('current')
          .get();
      if (walletDoc.exists) {
        return (walletDoc.data()?['diamonds'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching user diamonds: $e');
      return 0;
    }
  }

  Future<void> _handleWalletTransaction() async {
    if (_selectedUserId.isEmpty) return;
    if (_amountController.text.isEmpty) return;
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('reason_required'.tr())),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('invalid_amount'.tr())),
      );
      return;
    }

    try {
      final userRef = _firestore.collection('users').doc(_selectedUserId);
      final walletRef = userRef.collection('wallet').doc('current');
      final walletDoc = await walletRef.get();
      
      if (!walletDoc.exists) {
        // Initialize wallet if it doesn't exist
        await walletRef.set({
          'balance': 0.0,
          'agencyBalance': 0.0,
          'diamonds': 0,
          'totalRecharged': 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final currentBalance = (walletDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      final currentDiamonds = (walletDoc.data()?['diamonds'] as int?) ?? 0;
      
      final newBalance = _isRechargeMode 
          ? currentBalance + amount 
          : currentBalance - amount;

      if (newBalance < 0) {
        throw Exception('Insufficient balance for deduction');
      }

      // Calculate diamonds based on current exchange rate (default 1:100)
      final rate = 100;
      final diamondsChange = _isRechargeMode 
          ? (amount * rate).toInt() 
          : -((amount * rate).toInt());
      final newDiamonds = currentDiamonds + diamondsChange;

      // Create transaction record
      final transactionRef = userRef.collection('transactions').doc();
      await transactionRef.set({
        'id': transactionRef.id,
        'amount': _isRechargeMode ? amount : -amount,
        'date': DateTime.now().toIso8601String(),
        'status': 'completed',
        'description': _reasonController.text,
        'adminId': widget.adminAuthController.currentUserId,
        'adminName': widget.adminAuthController.currentUserName,
        'type': _isRechargeMode ? 'admin_recharge' : 'admin_deduction',
        'targetId': _selectedUserId,
      });

      // Update wallet balance and diamonds
      await walletRef.update({
        'balance': newBalance,
        'diamonds': newDiamonds,
        'totalRecharged': _isRechargeMode 
            ? FieldValue.increment(amount) 
            : FieldValue.increment(0),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _amountController.clear();
      _reasonController.clear();
      _selectedUserId = '';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRechargeMode ? 'recharge_success'.tr() : 'deduction_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        // Users will auto-update via real-time listener
      }
    } catch (e) {
      debugPrint('Wallet transaction error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('transaction_failed'.tr(namedArgs: {'error': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _banUser(String userId, String userName) async {
    final reasonController = TextEditingController();
    String selectedDuration = '1d';

    final confirmed = await showDialog<bool>(
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
                    selectedDuration = '1h';
                  },
                ),
                ChoiceChip(
                  label: const Text('1 Day'),
                  selected: selectedDuration == '1d',
                  onSelected: (selected) {
                    selectedDuration = '1d';
                  },
                ),
                ChoiceChip(
                  label: const Text('1 Week'),
                  selected: selectedDuration == '1w',
                  onSelected: (selected) {
                    selectedDuration = '1w';
                  },
                ),
                ChoiceChip(
                  label: const Text('Permanent'),
                  selected: selectedDuration == 'perm',
                  onSelected: (selected) {
                    selectedDuration = 'perm';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('ban'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      try {
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

        final banExpiry = DateTime.now().add(duration);
        await _firestore.collection('users').doc(userId).update({
          'isBanned': true,
          'banReason': reasonController.text,
          'banExpiresAt': Timestamp.fromDate(banExpiry),
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
        // Users will auto-update via real-time listener
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
  }

  void _showWalletDialog(String userId, String userName) {
    setState(() {
      _selectedUserId = userId;
      _isRechargeMode = true;
    });
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('wallet_transaction'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${'user'.tr()}: $userName'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      // ignore: deprecated_member_use
                      groupValue: _isRechargeMode,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setDialogState(() {
                          _isRechargeMode = value ?? true;
                        });
                      },
                    ),
                    Text('recharge'.tr()),
                    const SizedBox(width: 16),
                    Radio<bool>(
                      value: false,
                      // ignore: deprecated_member_use
                      groupValue: _isRechargeMode,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setDialogState(() {
                          _isRechargeMode = value ?? false;
                        });
                      },
                    ),
                    Text('deduct'.tr()),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'amount'.tr(),
                    prefixText: '\$ ',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'reason'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: _handleWalletTransaction,
                child: Text('confirm'.tr()),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUserProfileDialog(UserModel user) async {
    setState(() {
      _selectedUserId = user.id;
    });
    
    await _loadUserTransactions(user.id);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'user_profile'.tr(),
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
              
              // User Info
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(text: 'profile_info'.tr()),
                          Tab(text: 'transaction_history'.tr()),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildProfileInfo(user),
                            _buildTransactionHistory(),
                          ],
                        ),
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

  Widget _buildProfileInfo(UserModel user) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        _getUserBalance(user.id),
        _getUserDiamonds(user.id),
      ]).then((results) => {
        'balance': results[0],
        'diamonds': results[1],
      }),
      builder: (context, snapshot) {
        final balance = snapshot.data?['balance'] ?? 0.0;
        final diamonds = snapshot.data?['diamonds'] ?? 0;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('user_id'.tr(), user.id),
              _buildInfoRow('name'.tr(), user.name),
              _buildInfoRow('gems_balance'.tr(), '\$${balance.toStringAsFixed(2)}'),
              _buildInfoRow('coins_balance'.tr(), diamonds.toString()),
              _buildInfoRow('level'.tr(), user.level.toString()),
              _buildInfoRow('vip_level'.tr(), user.vipLevel.toString()),
              _buildInfoRow('svip_level'.tr(), user.svipLevel.toString()),
              _buildInfoRow('wealth_level'.tr(), user.wealthLevel.toString()),
              _buildInfoRow('magic_level'.tr(), user.magicLevel.toString()),
              _buildInfoRow('noble_level'.tr(), user.nobleLevel.toString()),
              _buildInfoRow('followers'.tr(), user.followersCount.toString()),
              _buildInfoRow('friends'.tr(), user.friendsCount.toString()),
              _buildInfoRow('is_online'.tr(), user.isOnline.toString()),
              _buildInfoRow('current_room'.tr(), user.currentRoomName ?? 'None'),
              _buildInfoRow('role'.tr(), user.role.name),
              _buildInfoRow('status'.tr(), user.isBanned ? 'Banned' : 'Active'),
              if (user.isBanned) _buildInfoRow('ban_reason'.tr(), user.banReason ?? 'Unknown'),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showWalletDialog(user.id, user.name);
                    },
                    icon: const Icon(Icons.account_balance_wallet),
                    label: Text('wallet_transaction'.tr()),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showGrantItemDialog(user.id, user.name);
                    },
                    icon: const Icon(Icons.card_giftcard),
                    label: Text('grant_item'.tr()),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _banUser(user.id, user.name);
                    },
                    icon: const Icon(Icons.block),
                    label: Text('ban_user'.tr()),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showGrantItemDialog(String userId, String userName) async {
    final itemIdController = TextEditingController();
    String itemType = 'frame';
    String duration = '30d';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('grant_item'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${'user'.tr()}: $userName'),
                const SizedBox(height: 16),
                Text('item_type'.tr()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Frame / إطار'),
                      selected: itemType == 'frame',
                      onSelected: (selected) {
                        setDialogState(() => itemType = 'frame');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Entrance / دخولية'),
                      selected: itemType == 'entrance',
                      onSelected: (selected) {
                        setDialogState(() => itemType = 'entrance');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Tag / شارة'),
                      selected: itemType == 'tag',
                      onSelected: (selected) {
                        setDialogState(() => itemType = 'tag');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: itemIdController,
                  decoration: InputDecoration(
                    labelText: 'item_id'.tr(),
                    hintText: 'e.g., frame_vip1, entrance_159',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('duration'.tr()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('7 Days'),
                      selected: duration == '7d',
                      onSelected: (selected) {
                        setDialogState(() => duration = '7d');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('30 Days'),
                      selected: duration == '30d',
                      onSelected: (selected) {
                        setDialogState(() => duration = '30d');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Permanent'),
                      selected: duration == 'perm',
                      onSelected: (selected) {
                        setDialogState(() => duration = 'perm');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: Text('grant'.tr()),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && itemIdController.text.isNotEmpty) {
      try {
        final itemId = itemIdController.text.trim();
        final expirationDays = duration == 'perm' ? 0 : int.parse(duration.replaceAll('d', ''));
        
        // Add item to user's inventory
        await _firestore.collection('users').doc(userId).update({
          'activeItems': FieldValue.arrayUnion([
            {
              'itemId': itemId,
              'type': itemType,
              'grantedAt': FieldValue.serverTimestamp(),
              'expirationDays': expirationDays,
            }
          ]),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('item_granted_success'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Grant item error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('grant_failed'.tr(namedArgs: {'error': e.toString()})),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildTransactionHistory() {
    if (_isTransactionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userTransactions.isEmpty) {
      return Center(child: Text('no_transactions'.tr()));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _userTransactions[index];
        final date = transaction.date;
        final isPositive = transaction.amount >= 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPositive ? Colors.green : Colors.red,
            ),
            title: Text(transaction.description ?? 'Transaction'),
            subtitle: Text(date.toString().substring(0, 19)),
            trailing: Text(
              '\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  List<UserModel> _getPaginatedUsers() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    if (startIndex >= _filteredUsers.length) {
      return [];
    }
    
    return _filteredUsers.sublist(
      startIndex,
      endIndex > _filteredUsers.length ? _filteredUsers.length : endIndex,
    );
  }

  int get _totalPages => (_filteredUsers.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('users_management'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'refresh'.tr(),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'search_users_id_phone'.tr(),
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _deepSearchUser(_searchController.text),
                    icon: const Icon(Icons.search),
                    label: Text('deep_search'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Users Data Table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? Center(child: Text('no_users_found'.tr()))
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
                                child: Row(
                                  children: [
                                    _buildTableHeader('user_id'.tr(), 120, 'id'),
                                    _buildTableHeader('name'.tr(), 150, 'name'),
                                    _buildTableHeader('level'.tr(), 80, 'level'),
                                    _buildTableHeader('vip_tier'.tr(), 80, 'vipLevel'),
                                    _buildTableHeader('gems'.tr(), 80, 'balance'),
                                    _buildTableHeader('coins'.tr(), 80, 'diamonds'),
                                    _buildTableHeader('status'.tr(), 80, 'status'),
                                    const Spacer(),
                                    _buildTableHeader('actions'.tr(), 150, ''),
                                  ],
                                ),
                              ),
                              
                              // Table Body
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _getPaginatedUsers().length,
                                  itemBuilder: (context, index) {
                                    final user = _getPaginatedUsers()[index];
                                    return FutureBuilder<Map<String, dynamic>>(
                                      future: Future.wait([
                                        _getUserBalance(user.id),
                                        _getUserDiamonds(user.id),
                                      ]).then((results) => {
                                        'balance': results[0],
                                        'diamonds': results[1],
                                      }),
                                      builder: (context, snapshot) {
                                        final balance = snapshot.data?['balance'] ?? 0.0;
                                        final diamonds = snapshot.data?['diamonds'] ?? 0;
                                        final status = user.isBanned ? 'Banned' : 'Active';
                                        final statusColor = user.isBanned ? Colors.red : Colors.green;
                                        
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
                                              _buildTableCell(user.id, 120),
                                              _buildTableCell(user.name, 150),
                                              _buildTableCell(user.level.toString(), 80),
                                              _buildTableCell('VIP ${user.vipLevel}', 80),
                                              _buildTableCell('\$${balance.toStringAsFixed(2)}', 80),
                                              _buildTableCell(diamonds.toString(), 80),
                                              _buildTableCell(
                                                status,
                                                80,
                                                textColor: statusColor,
                                              ),
                                              const Spacer(),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.visibility),
                                                    onPressed: () => _showUserProfileDialog(user),
                                                    tooltip: 'view_profile'.tr(),
                                                    color: Colors.blue,
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.account_balance_wallet),
                                                    onPressed: () => _showWalletDialog(user.id, user.name),
                                                    tooltip: 'wallet'.tr(),
                                                    color: Colors.green,
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.block),
                                                    onPressed: () => _banUser(user.id, user.name),
                                                    tooltip: 'ban'.tr(),
                                                    color: Colors.red,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              
                              // Pagination
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: const Border(top: BorderSide(color: Colors.grey)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${'showing'.tr()} ${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage).clamp(0, _filteredUsers.length)} of ${_filteredUsers.length}'),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          onPressed: _currentPage > 1
                                              ? () => setState(() => _currentPage--)
                                              : null,
                                        ),
                                        Text('$_currentPage / $_totalPages'),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          onPressed: _currentPage < _totalPages
                                              ? () => setState(() => _currentPage++)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ],
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

  Widget _buildTableHeader(String text, double width, String sortField) {
    return InkWell(
      onTap: () => _sortUsers(sortField),
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

  Widget _buildTableCell(String text, double width, {Color? textColor}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: textColor != null ? TextStyle(color: textColor, fontWeight: FontWeight.bold) : null,
      ),
    );
  }
}
