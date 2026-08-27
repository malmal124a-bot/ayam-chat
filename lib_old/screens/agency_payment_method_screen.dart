import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/agency_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/wallet_controller.dart';
import '../theme/app_theme.dart';
import 'agency_dashboard_screen.dart';

class AgencyPaymentMethodScreen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  const AgencyPaymentMethodScreen({super.key, required this.onboardingData});

  @override
  State<AgencyPaymentMethodScreen> createState() => _AgencyPaymentMethodScreenState();
}

class _AgencyPaymentMethodScreenState extends State<AgencyPaymentMethodScreen> {
  String? _selectedMethod;
  final List<Map<String, dynamic>> _methods = [
    {'id': 'usdt', 'name': 'USDT (TRC20)', 'icon': Icons.currency_bitcoin},
    {'id': 'vodafone', 'name': 'Vodafone Cash', 'icon': Icons.phone_android},
    {'id': 'bank', 'name': 'Bank Transfer', 'icon': Icons.account_balance},
  ];

  void _finish() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار وسيلة دفع')),
      );
      return;
    }

    final controller = context.read<AgencyController>();
    final userController = context.read<UserController>();
    final walletController = context.read<WalletController>();

    final double amount = (widget.onboardingData['selectedTier'] as int).toDouble();

    // Simulate Payment: Add the balance to the wallet first so it can be used for activation/liquidity
    walletController.addBalance(amount * 2, description: 'شحن رصيد تفعيل الوكالة');

    // Finalize Onboarding
    await controller.submitAgencyRequest(
      agencyName: 'وكالة ${widget.onboardingData['name']}',
      personalName: widget.onboardingData['name'],
      nationalId: 'VERIFIED_ID',
      phoneNumber: widget.onboardingData['phone'],
      whatsappLink: widget.onboardingData['phone'],
      idCardFrontUrl: widget.onboardingData['frontId'],
      idCardBackUrl: widget.onboardingData['backId'],
    );

    // Activate Agency
    userController.toggleAgentStatus(true);
    await controller.activateAgency(amount.toInt());

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.card,
          title: Text(tr('success'), style: const TextStyle(color: Colors.green)),
          content: const Text('تم تفعيل الوكالة بنجاح! يمكنك الآن استخدام لوحة التحكم.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AgencyDashboardScreen()),
                  (route) => route.isFirst,
                );
              },
              child: Text(tr('ok'), style: const TextStyle(color: AppTheme.royalGold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.royalPurpleDark,
      appBar: AppBar(
        title: const Text('تأكيد الدفع'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'الخطوة الأخيرة: الدفع',
                style: TextStyle(color: AppTheme.royalGold, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'المبلغ المطلوب لتفعيل باقة الوكالة: \$${widget.onboardingData['selectedTier']}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ..._methods.map((method) => _buildMethodCard(method)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _finish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.royalGold,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('إتمام التفعيل', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard(Map<String, dynamic> method) {
    bool isSelected = _selectedMethod == method['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.green : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(method['icon'], color: isSelected ? Colors.green : Colors.white54),
            const SizedBox(width: 15),
            Text(method['name'], style: TextStyle(color: isSelected ? Colors.green : Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }
}
