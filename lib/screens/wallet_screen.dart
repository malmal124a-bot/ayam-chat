import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/wallet_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletController>();

    return Scaffold(
      backgroundColor: AppTheme.nearBlackPurple,
      appBar: AppBar(
        title: Text('wallet'.tr(), style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AppIcon('Icons.arrow_back_ios', icon: Icons.arrow_back_ios, color: AppTheme.royalGold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Balance Header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.coffeeDark, AppTheme.nearBlackPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Diamonds Display
                Column(
                  children: [
                    Row(
                      children: [
                        const AppIcon('Icons.diamond', icon: Icons.diamond, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 8),
                        Text('diamonds'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${wallet.diamonds}',
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                // Divider
                Container(height: 40, width: 1, color: Colors.white.withValues(alpha: 0.1)),
                // Wallet Balance Display
                Column(
                  children: [
                    Row(
                      children: [
                        AppIcon('Icons.account_balance_wallet_rounded', icon: Icons.account_balance_wallet_rounded, color: AppTheme.royalGold, size: 20),
                        const SizedBox(width: 8),
                        Text('balance'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${wallet.balance.toStringAsFixed(2)}\$',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transactions Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                AppIcon('Icons.history', icon: Icons.history, color: AppTheme.royalGold, size: 20),
                const SizedBox(width: 8),
                Text('transaction_history'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: wallet.transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon('Icons.receipt_long_outlined', icon: Icons.receipt_long_outlined, size: 64, color: Colors.white.withValues(alpha: 0.15)),
                        const SizedBox(height: 16),
                        Text('no_transactions'.tr(), style: const TextStyle(color: Colors.white24)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: wallet.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = wallet.transactions[index];
                      final isIncome = tx.amount > 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.coffeeDark.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isIncome ? Icons.add_rounded : Icons.remove_rounded,
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tx.description ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text(tx.date.toString().substring(0, 16), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              '${isIncome ? "+" : ""}${tx.amount}',
                              style: TextStyle(
                                color: isIncome ? Colors.green : Colors.redAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}