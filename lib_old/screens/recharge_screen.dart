import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/wallet_controller.dart';
import '../controllers/user_controller.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final WalletController walletController = WalletController();
  final UserController userController = UserController();
  double? selectedAmount;

  final List<double> rechargeAmounts = [5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0, 1000.0];

  void _handleRecharge() {
    final theme = Theme.of(context);
    final amount = selectedAmount;
    if (amount == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('تأكيد الشحن', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text('هل تريد شحن \$${amount.toStringAsFixed(2)}؟', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.54)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
            ),
            onPressed: () async {
              // PERSIST TO FIRESTORE: Execute real-time Firestore increment
              final userId = userController.id;
              try {
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'balance': FieldValue.increment(amount),
                  'coins': FieldValue.increment((amount * 12000).toInt()),
                });
                walletController.addBalance(amount);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم شحن \$${amount.toStringAsFixed(2)} بنجاح!')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('فشل الشحن: $e')),
                );
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('شحن الرصيد', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اختر المبلغ المراد شحنه', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: rechargeAmounts.length,
              itemBuilder: (context, index) {
                final amount = rechargeAmounts[index];
                final isSelected = selectedAmount == amount;
                return GestureDetector(
                  onTap: () => setState(() => selectedAmount = amount),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.secondary : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isSelected ? theme.colorScheme.onSecondary : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedAmount != null ? _handleRecharge : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                ),
                child: const Text('اشحن الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
