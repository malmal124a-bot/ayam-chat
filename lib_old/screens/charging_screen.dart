import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/wallet_controller.dart';
import '../controllers/auth_controller.dart';

class ChargingScreen extends StatefulWidget {
  const ChargingScreen({super.key});

  @override
  State<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends State<ChargingScreen> {
  String? selectedGateway;
  bool _isProcessing = false;
  bool _isRechargeEnabled = false;

  @override
  void initState() {
    super.initState();
    // Always enable recharge for in-app purchases
    setState(() {
      _isRechargeEnabled = true;
    });
  }

  final List<Map<String, dynamic>> gateways = [
    {'id': 'vodafone', 'name': 'Vodafone Cash (فودافون كاش)', 'icon': Icons.phone_android, 'color': Colors.red},
    {'id': 'usdt', 'name': 'USDT Crypto (TRC20 / BEP20)', 'icon': Icons.currency_bitcoin, 'color': Colors.teal},
  ];

  final List<Map<String, dynamic>> packages = [
    {'usd': 1.0, 'diamonds': 1000000},
    {'usd': 5.0, 'diamonds': 5000000},
    {'usd': 10.0, 'diamonds': 10000000},
    {'usd': 50.0, 'diamonds': 50000000},
    {'usd': 100.0, 'diamonds': 100000000},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallet = context.watch<WalletController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('shipping'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (!_isRechargeEnabled)
            _buildDisabledMessage()
          else
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceHeader(theme, wallet),
                  const SizedBox(height: 20),
                  _buildSectionTitle('payment_method'.tr()),
                  _buildGatewayList(theme),
                  const SizedBox(height: 20),
                  _buildSectionTitle('select_package'.tr()),
                  _buildPackageGrid(theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildDisabledMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'خدمة الشحن غير متاحة حالياً',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى المحاولة مرة أخرى لاحقاً',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBalanceHeader(ThemeData theme, WalletController wallet) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text('your_balance'.tr(), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          const SizedBox(height: 10),
          Text(
            NumberFormat.decimalPattern().format(wallet.diamonds),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          Text(
            '${wallet.balance.value.toStringAsFixed(2)} USD',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayList(ThemeData theme) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: gateways.length,
        itemBuilder: (context, index) {
          final gw = gateways[index];
          final bool isSelected = selectedGateway == gw['id'];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedGateway = gw['id'];
              });
            },
            child: Container(
              width: 110,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? (gw['color'] as Color) : theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(gw['icon'] as IconData, color: isSelected ? Colors.white : (gw['color'] as Color), size: 28),
                  const SizedBox(height: 8),
                  Text(
                    gw['name'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackageGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        return InkWell(
          onTap: () => _initiateDirectPayment(pkg['usd'], pkg['diamonds']),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.diamond, color: Colors.blueAccent, size: 28),
                const SizedBox(height: 5),
                Text(
                  NumberFormat.compact().format(pkg['diamonds']),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '\$${pkg['usd']}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _initiateDirectPayment(double usd, int diamonds) async {
    if (selectedGateway == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_select_payment_method'.tr())),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm'.tr()),
        content: Text('Confirm recharge of \$$usd for $diamonds diamonds?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        setState(() => _isProcessing = true);
      }
      
      try {
        final authController = context.read<AuthController>();
        final userId = authController.currentUser?.uid;
        
        if (userId != null) {
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'diamonds': FieldValue.increment(diamonds),
            'coins': FieldValue.increment(diamonds),
          });
          
          if (mounted) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(backgroundColor: Colors.green, content: Text('success'.tr())),
            );
          }
        }
      } catch (e) {
        debugPrint('Error processing payment: $e');
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text('error_occurred'.tr())),
          );
        }
      }
    }
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(35),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 25),
              const Text('جاري المعالجة...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
