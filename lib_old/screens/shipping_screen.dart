import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class ShippingScreen extends StatefulWidget {
  const ShippingScreen({super.key});

  @override
  State<ShippingScreen> createState() => _ShippingScreenState();
}

class _ShippingScreenState extends State<ShippingScreen> {
  String? selectedGateway;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> gateways = [
    {'id': 'vodafone', 'name': 'Vodafone Cash (فودافون كاش)', 'icon': Icons.phone_android, 'color': Colors.red},
    {'id': 'usdt', 'name': 'USDT Crypto (TRC20 / BEP20)', 'icon': Icons.currency_bitcoin, 'color': Colors.teal},
  ];

  final List<Map<String, dynamic>> packages = [
    {'usd': 1.0, 'coins': 1000000},
    {'usd': 5.0, 'coins': 5000000},
    {'usd': 10.0, 'coins': 10000000},
    {'usd': 50.0, 'coins': 50000000},
    {'usd': 100.0, 'coins': 100000000},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmSandBackground,
      appBar: AppBar(
        title: Text('shipping'.tr(), style: const TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildSectionTitle('payment_method'.tr()),
                _buildGatewayList(),
                const SizedBox(height: 20),
                _buildSectionTitle('select_package'.tr()),
                _buildPackageGrid(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBrown),
      ),
    );
  }

  Widget _buildGatewayList() {
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
                color: isSelected ? (gw['color'] as Color) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.white : AppTheme.darkBrown.withValues(alpha: 0.1),
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
                      color: isSelected ? Colors.white : AppTheme.darkBrown,
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

  Widget _buildPackageGrid() {
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
          onTap: () => _initiateDirectPayment(pkg['usd'], pkg['coins']),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.diamond, color: Colors.blueAccent, size: 28),
                const SizedBox(height: 5),
                Text(
                  pkg['coins'].toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBrown),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.royalGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '\$${pkg['usd']}',
                    style: const TextStyle(
                      color: AppTheme.royalGold,
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

  void _initiateDirectPayment(double usd, int coins) async {
    if (selectedGateway == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text('Confirm recharge of \$$usd for $coins coins?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Confirm'),
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
            'coins': FieldValue.increment(coins),
            'diamonds': FieldValue.increment(coins),
          });
          
          if (mounted) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(backgroundColor: Colors.green, content: Text('Recharge successful!')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error processing payment: $e');
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.red, content: Text('Payment failed')),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 25),
              const Text('Processing...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
