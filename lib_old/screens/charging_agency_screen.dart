import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../controllers/shipping_agency_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/wallet_controller.dart';
import '../models/agency_model.dart';
import 'package:intl/intl.dart';
import 'agency_id_verification_screen.dart';
import 'agency_dashboard_screen.dart';

class ChargingAgencyScreen extends StatefulWidget {
  const ChargingAgencyScreen({super.key});

  @override
  State<ChargingAgencyScreen> createState() => _ChargingAgencyScreenState();
}

class _ChargingAgencyScreenState extends State<ChargingAgencyScreen> {
  // PERMANENTLY ENABLED: Set to true by default
  bool _isRechargeEnabled = true;

  @override
  void initState() {
    super.initState();
    // PERMANENTLY ENABLED: No longer checking system_config
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateBasedOnAgentStatus();
    });
  }

  void _navigateBasedOnAgentStatus() {
    final userController = context.read<UserController>();
    
    if (userController.isAgent) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AgencyDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AgencyIdVerificationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ShippingAgencyController>();
    final agency = controller.myShippingAgency;
    final wallet = context.watch<WalletController>();

    return Scaffold(
      backgroundColor: AppTheme.warmSandBackground,
      appBar: AppBar(
        title: const Text('وكالة الشحن', style: TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const SizedBox(height: 10),
              // LINKED TO FIRESTORE: Display agencyBalance from WalletController
              _buildAgencyBalanceCard(wallet.agencyBalance.value.toDouble()),
              const SizedBox(height: 30),
              
              const Text('وسائل الدفع', style: TextStyle(color: AppTheme.darkBrown, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              _buildPaymentGrid(),
              const SizedBox(height: 35),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('سجل العمليات', style: TextStyle(color: AppTheme.darkBrown, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('عرض الكل', style: TextStyle(color: AppTheme.darkBrown.withValues(alpha: 0.5), fontSize: 14)),
                ],
              ),
              const SizedBox(height: 15),
              _buildTransactionHistory(controller),
              const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencyBalanceCard(double balance) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkBrown,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('رصيد الوكالة', style: TextStyle(color: Colors.white70, fontSize: 17)),
                  const SizedBox(height: 8),
                  Text(currencyFormat.format(balance), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.royalGold, size: 36),
            ],
          ),
          const SizedBox(height: 25),
          Divider(color: Colors.white12, thickness: 1.2),
          const SizedBox(height: 15),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('وكالة نشطة', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 20)),
              Icon(Icons.verified, color: Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 18,
      crossAxisSpacing: 18,
      childAspectRatio: 1.45,
      children: [
        _buildPaymentMethodCard('Syriatel Cash', Icons.phone_iphone_rounded, Colors.red),
        _buildPaymentMethodCard('Vodafone Cash', Icons.vibration_rounded, Colors.redAccent),
        _buildPaymentMethodCard('USDT (TRC20)', Icons.currency_bitcoin_rounded, Colors.green),
        _buildPaymentMethodCard('Abaya Bank', Icons.account_balance_rounded, Colors.blue),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _showRechargeDialog(title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showRechargeDialog(String method) {
    final userIdController = TextEditingController();
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('شحن عبر $method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: userIdController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رقم المستخدم'), maxLength: 6),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final targetId = userIdController.text.trim();
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              if (targetId.isNotEmpty && amount > 0) {
                Navigator.pop(context);
                // PERSIST TO FIRESTORE: Execute real-time Firestore increment for agency transfer
                try {
                  await FirebaseFirestore.instance.collection('users').doc(targetId).update({
                    'gems': FieldValue.increment((amount * 12000).toInt()),
                    'diamonds': FieldValue.increment((amount * 12000).toInt()),
                    'coins': FieldValue.increment((amount * 12000).toInt()),
                  });
                  context.read<WalletController>().addDiamondsToUser(targetId, (amount * 12000).toInt(), amount);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم الشحن بنجاح!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل الشحن: $e')),
                  );
                }
              }
            },
            child: const Text('شحن'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(ShippingAgencyController controller) {
    final logs = controller.getChargingLogs();
    if (logs.isEmpty) return const Center(child: Text('لا توجد عمليات حالياً'));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final txn = logs[index];
        return ListTile(
          title: Text('مستخدم #${txn.targetId}'),
          subtitle: Text(DateFormat('yyyy-MM-dd').format(txn.date)),
          trailing: Text('${txn.amount.toInt()} ماسة', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
