import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../controllers/wallet_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_icon.dart';

class ChargingScreen extends StatefulWidget {
  const ChargingScreen({super.key});

  @override
  State<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends State<ChargingScreen> {
  String? selectedGateway;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> gateways = [
    {'id': 'vodafone', 'name': 'Vodafone Cash', 'icon': Icons.phone_android, 'color': Colors.red},
    {'id': 'usdt', 'name': 'USDT (TRC20)', 'icon': Icons.currency_bitcoin, 'color': Colors.teal},
    {'id': 'syriatel', 'name': 'Syriatel Cash', 'icon': Icons.account_balance_wallet, 'color': Colors.orange},
    {'id': 'google', 'name': 'Google Play', 'icon': Icons.play_arrow, 'color': Colors.blue},
  ];

  final List<Map<String, dynamic>> packages = [
    {'usd': 1.0, 'diamonds': 10000},
    {'usd': 5.0, 'diamonds': 50000},
    {'usd': 10.0, 'diamonds': 100000},
    {'usd': 20.0, 'diamonds': 200000},
    {'usd': 30.0, 'diamonds': 300000},
    {'usd': 50.0, 'diamonds': 500000},
    {'usd': 100.0, 'diamonds': 1000000},
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceHeader(theme, wallet),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  AppIcon('Icons.lock_outline_rounded', icon: Icons.lock_outline_rounded, color: theme.colorScheme.secondary.withValues(alpha: 0.6), size: 48),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'الشحن غير متاح حالياً',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'سيتم تفعيل الشحن عبر Google Play قريباً\nيمكنك استخدام رصيدك الحالي لشراء الهدايا',
                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon('Icons.diamond', icon: Icons.diamond, color: Colors.blueAccent, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          '${NumberFormat.decimalPattern().format(wallet.diamonds)} ماسة',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
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
            '${wallet.balance.toStringAsFixed(2)} USD',
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
                const AppIcon('Icons.diamond', icon: Icons.diamond, color: Colors.blueAccent, size: 28),
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
        content: Text('Confirm recharge of \$${usd} for ${NumberFormat.decimalPattern().format(diamonds)} diamonds?'),
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
      setState(() => _isProcessing = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        final gatewayName = gateways.firstWhere((g) => g['id'] == selectedGateway)['name'];
        context.read<AuthController>().updateBalance(
          usd, 
          description: 'شحن مباشر',
          method: gatewayName,
        );
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.green, content: Text('success'.tr())),
        );
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
