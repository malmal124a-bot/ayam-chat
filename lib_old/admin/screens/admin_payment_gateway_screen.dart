import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/admin_auth_controller.dart';
import '../controllers/admin_rbac_controller.dart';

class AdminPaymentGatewayScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  
  const AdminPaymentGatewayScreen({
    super.key,
    required this.adminAuthController,
  });

  @override
  State<AdminPaymentGatewayScreen> createState() => _AdminPaymentGatewayScreenState();
}

class _AdminPaymentGatewayScreenState extends State<AdminPaymentGatewayScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _rbacController = AdminRBACController();
  
  bool _autoRechargeEnabled = false;
  bool _inAppRechargeCardsEnabled = false;
  bool _isLoading = true;

  final _userIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPaymentConfig();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentConfig() async {
    try {
      final doc = await _firestore.collection('system_config').doc('payment_settings').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _autoRechargeEnabled = data['autoRechargeEnabled'] ?? false;
          _inAppRechargeCardsEnabled = data['inAppRechargeCardsEnabled'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _autoRechargeEnabled = false;
          _inAppRechargeCardsEnabled = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading payment config: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePaymentConfig() async {
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
      await _firestore.collection('system_config').doc('payment_settings').set({
        'autoRechargeEnabled': _autoRechargeEnabled,
        'inAppRechargeCardsEnabled': _inAppRechargeCardsEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': widget.adminAuthController.currentUserId,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('payment_config_saved'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('save_failed'.tr(namedArgs: {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _manualRecharge() async {
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

    final userId = _userIdController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final reason = _reasonController.text.trim();

    if (userId.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('invalid_input'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('user_not_found'.tr()),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final currentBalance = (userDoc.data()!['wallet'] as Map<String, dynamic>?)?['balance'] ?? 0.0;
      final newBalance = currentBalance + amount;

      await _firestore.collection('users').doc(userId).update({
        'wallet': {
          'balance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log transaction
      await _firestore.collection('users').doc(userId).collection('transactions').add({
        'amount': amount,
        'date': FieldValue.serverTimestamp(),
        'status': 'completed',
        'description': reason.isNotEmpty ? reason : 'Manual recharge by admin',
        'adminId': widget.adminAuthController.currentUserId,
        'adminName': widget.adminAuthController.currentUserName,
        'type': 'manual_recharge',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('recharge_success'.tr(namedArgs: {
            'amount': amount.toStringAsFixed(2),
            'userId': userId,
          })),
          backgroundColor: Colors.green,
        ),
      );
      _userIdController.clear();
      _amountController.clear();
      _reasonController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('transaction_failed'.tr(namedArgs: {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('payment_gateway'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Gateway Controls
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payment, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'payment_gateway_controls'.tr(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: Text('auto_recharge_enabled'.tr()),
                              subtitle: Text('auto_recharge_desc'.tr()),
                              value: _autoRechargeEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _autoRechargeEnabled = value;
                                });
                              },
                            ),
                            SwitchListTile(
                              title: Text('in_app_recharge_cards'.tr()),
                              subtitle: Text('in_app_recharge_cards_desc'.tr()),
                              value: _inAppRechargeCardsEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _inAppRechargeCardsEnabled = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _savePaymentConfig,
                              icon: const Icon(Icons.save),
                              label: Text('save_config'.tr()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Manual Recharge Panel
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_balance_wallet, color: Colors.green.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'manual_recharge'.tr(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _userIdController,
                              decoration: InputDecoration(
                                labelText: 'user_id'.tr(),
                                border: const OutlineInputBorder(),
                              ),
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
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _manualRecharge,
                              icon: const Icon(Icons.add_circle),
                              label: Text('recharge_now'.tr()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info Card
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'payment_gateway_info'.tr(),
                                style: TextStyle(color: Colors.orange.shade900),
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
}
