import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/admin_auth_controller.dart';

class AdminAgenciesScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  
  const AdminAgenciesScreen({
    super.key,
    required this.adminAuthController,
  });

  @override
  State<AdminAgenciesScreen> createState() => _AdminAgenciesScreenState();
}

class _AdminAgenciesScreenState extends State<AdminAgenciesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> _rechargeAgencies = [];
  List<QueryDocumentSnapshot> _hostAgencies = [];
  List<QueryDocumentSnapshot> _pendingRechargeRequests = [];
  List<QueryDocumentSnapshot> _pendingHostRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgenciesRealTime();
    _loadPendingRequestsRealTime();
  }

  void _loadAgenciesRealTime() {
    _firestore
        .collection('agencies')
        .where('agencyType', isEqualTo: 'recharge')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _rechargeAgencies = snapshot.docs;
        _isLoading = false;
      });
    }, onError: (error) {
      debugPrint('Error loading recharge agencies: $error');
      setState(() {
        _isLoading = false;
      });
    });

    _firestore
        .collection('agencies')
        .where('agencyType', isEqualTo: 'host')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _hostAgencies = snapshot.docs;
        _isLoading = false;
      });
    }, onError: (error) {
      debugPrint('Error loading host agencies: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _loadPendingRequestsRealTime() {
    _firestore
        .collection('agency_requests')
        .where('status', isEqualTo: 'pending')
        .where('agencyType', isEqualTo: 'recharge')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _pendingRechargeRequests = snapshot.docs;
      });
    }, onError: (error) {
      debugPrint('Error loading pending recharge requests: $error');
    });

    _firestore
        .collection('agency_requests')
        .where('status', isEqualTo: 'pending')
        .where('agencyType', isEqualTo: 'host')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _pendingHostRequests = snapshot.docs;
      });
    }, onError: (error) {
      debugPrint('Error loading pending host requests: $error');
    });
  }

  Future<void> _approveAgency(String requestId, String userId, String agencyName) async {
    try {
      await _firestore.collection('agency_requests').doc(requestId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': widget.adminAuthController.currentUserId,
      });

      // Update user's agency status
      await _firestore.collection('users').doc(userId).update({
        'isAgent': true,
        'agencyName': agencyName,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('agency_approved'.tr()),
          backgroundColor: Colors.green,
        ),
      );
      // Real-time streams will auto-update
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('approval_failed'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectAgency(String requestId, String reason) async {
    try {
      await _firestore.collection('agency_requests').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': widget.adminAuthController.currentUserId,
        'rejectionReason': reason,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('agency_rejected'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      // Real-time stream handles updates automatically
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('rejection_failed'.tr(namedArgs: {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRejectDialog(String requestId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('reject_agency'.tr()),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: 'rejection_reason'.tr(),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                _rejectAgency(requestId, reasonController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('reject'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('agencies_management'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              // Tabs
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: Colors.blue.shade900,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue.shade900,
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'وكالات الشحن (Pending)'),
                    Tab(text: 'وكالات المضيفين (Pending)'),
                    Tab(text: 'وكالات الشحن (Active)'),
                    Tab(text: 'وكالات المضيفين (Active)'),
                  ],
                ),
              ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPendingRechargeTab(),
                    _buildPendingHostTab(),
                    _buildActiveRechargeTab(),
                    _buildActiveHostTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRechargeTab() {
    if (_pendingRechargeRequests.isEmpty) {
      return Center(child: Text('لا توجد طلبات وكالات شحن معلقة'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRechargeRequests.length,
      itemBuilder: (context, index) {
        final doc = _pendingRechargeRequests[index];
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String? ?? '';
        final userName = data['userName'] as String? ?? 'Unknown';
        final agencyName = data['agencyName'] as String? ?? 'Unknown';
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
                  agencyName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('المستخدم: $userName'),
                Text('معرف المستخدم: $userId'),
                Text('تاريخ التقديم: ${timestamp.toString().substring(0, 19)}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveAgency(doc.id, userId, agencyName),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text('موافقة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRejectDialog(doc.id),
                        icon: const Icon(Icons.close, size: 18),
                        label: Text('رفض'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
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

  Widget _buildPendingHostTab() {
    if (_pendingHostRequests.isEmpty) {
      return Center(child: Text('لا توجد طلبات وكالات مضيفين معلقة'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingHostRequests.length,
      itemBuilder: (context, index) {
        final doc = _pendingHostRequests[index];
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String? ?? '';
        final userName = data['userName'] as String? ?? 'Unknown';
        final agencyName = data['agencyName'] as String? ?? 'Unknown';
        final hostCommission = (data['hostCommission'] as num?)?.toDouble() ?? 0.0;
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
                  agencyName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('المستخدم: $userName'),
                Text('معرف المستخدم: $userId'),
                Text('عمولة المضيف: $hostCommission%'),
                Text('تاريخ التقديم: ${timestamp.toString().substring(0, 19)}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveAgency(doc.id, userId, agencyName),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text('موافقة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRejectDialog(doc.id),
                        icon: const Icon(Icons.close, size: 18),
                        label: Text('رفض'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
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

  Widget _buildActiveRechargeTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showCreateRechargeAgencyDialog(),
                icon: const Icon(Icons.add),
                label: Text('إنشاء وكالة شحن'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Table
        Expanded(
          child: _rechargeAgencies.isEmpty
              ? Center(child: Text('لا توجد وكالات شحن نشطة'))
              : SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('معرف الوكالة')),
                      DataColumn(label: Text('الاسم')),
                      DataColumn(label: Text('معرف المالك')),
                      DataColumn(label: Text('الرصيد')),
                      DataColumn(label: Text('إجمالي الشحن')),
                      DataColumn(label: Text('تاريخ الإنشاء')),
                      DataColumn(label: Text('الإجراءات')),
                    ],
                    rows: _rechargeAgencies.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final id = doc.id;
                      final name = data['name'] as String? ?? 'Unknown';
                      final ownerId = data['ownerId'] as String? ?? '';
                      final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
                      final totalRecharges = (data['totalRecharges'] as num?)?.toInt() ?? 0;
                      final createdAt = data['createdAt'] is Timestamp 
                          ? (data['createdAt'] as Timestamp).toDate()
                          : DateTime.now();
                      final isActivated = data['isActivated'] as bool? ?? false;

                      return DataRow(
                        cells: [
                          DataCell(Text(id.substring(0, 8))),
                          DataCell(Text(name)),
                          DataCell(Text(ownerId.substring(0, 8))),
                          DataCell(Text('\$${balance.toStringAsFixed(2)}')),
                          DataCell(Text('$totalRecharges')),
                          DataCell(Text(createdAt.toString().substring(0, 10))),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                                  onPressed: () => _showTopUpDialog(id, name, balance),
                                  tooltip: 'شحن الرصيد',
                                ),
                                IconButton(
                                  icon: Icon(isActivated ? Icons.lock_open : Icons.lock, color: Colors.orange),
                                  onPressed: () {
                                    _firestore.collection('agencies').doc(id).update({'isActivated': !isActivated});
                                    // Real-time stream handles updates automatically
                                  },
                                  tooltip: isActivated ? 'تجميد' : 'تفعيل',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  void _showCreateRechargeAgencyDialog() {
    final nameController = TextEditingController();
    final ownerIdController = TextEditingController();
    final phoneController = TextEditingController();
    final balanceController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إنشاء وكالة شحن جديدة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'اسم الوكالة',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ownerIdController,
                decoration: InputDecoration(
                  labelText: 'معرف المستخدم المالك',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف / البريد الإلكتروني',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الرصيد الافتتاحي',
                  prefixText: '\$ ',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && ownerIdController.text.isNotEmpty) {
                await _firestore.collection('agencies').add({
                  'name': nameController.text,
                  'ownerId': ownerIdController.text,
                  'phone': phoneController.text,
                  'balance': double.tryParse(balanceController.text) ?? 0.0,
                  'totalRecharges': 0,
                  'agencyType': 'recharge',
                  'isActivated': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                // Real-time stream handles updates automatically
              }
            },
            child: Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  void _showTopUpDialog(String agencyId, String agencyName, double currentBalance) {
    final amountController = TextEditingController();
    bool isAdd = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('شحن رصيد وكالة: $agencyName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الرصيد الحالي: \$${currentBalance.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('إضافة')),
                  ButtonSegment(value: false, label: Text('خصم')),
                ],
                selected: {isAdd},
                onSelectionChanged: (Set<bool> newSelection) {
                  setDialogState(() {
                    isAdd = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  prefixText: '\$ ',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount != null) {
                  final newBalance = isAdd ? currentBalance + amount : currentBalance - amount;
                  await _firestore.collection('agencies').doc(agencyId).update({
                    'balance': newBalance,
                    'totalRecharges': isAdd ? FieldValue.increment(1) : FieldValue.increment(0),
                  });
                  Navigator.pop(context);
                  // Real-time stream handles updates automatically
                }
              },
              child: Text(isAdd ? 'إضافة' : 'خصم'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveHostTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showCreateHostAgencyDialog(),
                icon: const Icon(Icons.add),
                label: Text('إنشاء وكالة مضيفين'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Table
        Expanded(
          child: _hostAgencies.isEmpty
              ? Center(child: Text('لا توجد وكالات مضيفين نشطة'))
              : SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('معرف الوكالة')),
                      DataColumn(label: Text('الاسم')),
                      DataColumn(label: Text('معرف الوكيل')),
                      DataColumn(label: Text('عمولة المضيف %')),
                      DataColumn(label: Text('إجمالي المضيفين')),
                      DataColumn(label: Text('الهدف/الأرباح')),
                      DataColumn(label: Text('الإجراءات')),
                    ],
                    rows: _hostAgencies.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final id = doc.id;
                      final name = data['name'] as String? ?? 'Unknown';
                      final agentId = data['agentId'] as String? ?? data['ownerId'] as String? ?? '';
                      final commission = (data['hostCommission'] as num?)?.toDouble() ?? 0.0;
                      final totalHosts = (data['totalHosts'] as num?)?.toInt() ?? 0;
                      final totalEarnings = (data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
                      final isActivated = data['isActivated'] as bool? ?? false;

                      return DataRow(
                        cells: [
                          DataCell(Text(id.substring(0, 8))),
                          DataCell(Text(name)),
                          DataCell(Text(agentId.substring(0, 8))),
                          DataCell(Text('${commission.toStringAsFixed(1)}%')),
                          DataCell(Text('$totalHosts')),
                          DataCell(Text('\$${totalEarnings.toStringAsFixed(2)}')),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditCommissionDialog(id, name, commission),
                                  tooltip: 'تعديل العمولة',
                                ),
                                IconButton(
                                  icon: Icon(isActivated ? Icons.lock_open : Icons.lock, color: Colors.orange),
                                  onPressed: () {
                                    _firestore.collection('agencies').doc(id).update({'isActivated': !isActivated});
                                    // Real-time stream handles updates automatically
                                  },
                                  tooltip: isActivated ? 'تجميد' : 'تفعيل',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  void _showCreateHostAgencyDialog() {
    final nameController = TextEditingController();
    final agentIdController = TextEditingController();
    final commissionController = TextEditingController(text: '10.0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إنشاء وكالة مضيفين جديدة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'اسم الوكالة',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: agentIdController,
                decoration: InputDecoration(
                  labelText: 'معرف المستخدم الوكيل',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commissionController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'نسبة عمولة المضيف %',
                  suffixText: '%',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && agentIdController.text.isNotEmpty) {
                await _firestore.collection('agencies').add({
                  'name': nameController.text,
                  'agentId': agentIdController.text,
                  'hostCommission': double.tryParse(commissionController.text) ?? 10.0,
                  'totalHosts': 0,
                  'totalEarnings': 0.0,
                  'agencyType': 'host',
                  'isActivated': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                // Real-time stream handles updates automatically
              }
            },
            child: Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  void _showEditCommissionDialog(String agencyId, String agencyName, double currentCommission) {
    final commissionController = TextEditingController(text: currentCommission.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل عمولة وكالة: $agencyName'),
        content: TextField(
          controller: commissionController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'نسبة العمولة الجديدة %',
            suffixText: '%',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCommission = double.tryParse(commissionController.text);
              if (newCommission != null) {
                await _firestore.collection('agencies').doc(agencyId).update({
                  'hostCommission': newCommission,
                });
                Navigator.pop(context);
                // Real-time stream handles updates automatically
              }
            },
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
