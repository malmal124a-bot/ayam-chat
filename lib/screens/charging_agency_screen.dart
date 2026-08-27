import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/shipping_agency_controller.dart';
import '../controllers/user_controller.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateBasedOnAgentStatus();
    });
  }

  void _navigateBasedOnAgentStatus() {
    final userController = context.read<UserController>();
    
    if (userController.isAgent) {
      // User is already an agent, go to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AgencyDashboardScreen()),
      );
    } else {
      // User is not an agent, start onboarding flow
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

    return Scaffold(
      backgroundColor: AppTheme.warmSandBackground,
      appBar: AppBar(
        title: Text(
          'وكالة الشحن',
          style: TextStyle(
            color: AppTheme.darkBrown,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const SizedBox(height: 10),
              // Top Card (Agency Balance)
              _buildAgencyBalanceCard(agency),
              const SizedBox(height: 30),
              
              Text(
                'وسائل الدفع',
                style: TextStyle(
                  color: AppTheme.darkBrown,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              
              // Payment Methods Grid
              _buildPaymentGrid(),
              const SizedBox(height: 35),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سجل العمليات',
                    style: TextStyle(
                      color: AppTheme.darkBrown,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'عرض الكل',
                    style: TextStyle(
                      color: AppTheme.darkBrown.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // Transaction History List
              _buildTransactionHistory(controller),
              const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencyBalanceCard(Agency? agency) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    String balanceString = agency != null ? currencyFormat.format(agency.totalEarnings) : '\$0';
    String idString = agency != null ? 'ID #${agency.id}' : 'لم يتم التفعيل';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkBrown,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رصيد الوكالة',
                    style: TextStyle(color: Colors.white70, fontSize: 17),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    balanceString,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet_rounded, color: AppTheme.royalGold, size: 36),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Divider(color: Colors.white.withValues(alpha: 0.15), thickness: 1.2),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                idString,
                style: TextStyle(
                  color: AppTheme.royalGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: (agency?.isActivated ?? false) ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (agency?.isActivated ?? false) ? 'وكالة نشطة' : 'وكالة غير نشطة',
                  style: TextStyle(
                    color: (agency?.isActivated ?? false) ? Colors.greenAccent : Colors.redAccent, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 13
                  ),
                ),
              ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.darkBrown,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(ShippingAgencyController controller) {
    final logs = controller.getChargingLogs();
    
    if (logs.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const Text('لا توجد عمليات شحن حالياً', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final txn = logs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warmSandBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_rounded, color: AppTheme.darkBrown, size: 24),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مستخدم #${txn.targetId}',
                      style: TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy-MM-dd').format(txn.date),
                      style: TextStyle(color: AppTheme.darkBrown.withValues(alpha: 0.4), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${txn.amount.toInt()} ماسة',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ناجح',
                      style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}