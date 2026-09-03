import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../controllers/wallet_controller.dart';
import '../controllers/agency_controller.dart';
import '../controllers/user_controller.dart';
import '../services/agency_api_service.dart';
import '../models/transaction_model.dart' as tx_model;
import '../widgets/app_icon.dart';

class AgencyScreen extends StatefulWidget {
  const AgencyScreen({super.key});

  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen> {
  final TextEditingController _targetIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _targetIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallet = context.watch<WalletController>();
    final agencyController = context.watch<AgencyController>();

    // Task 2: Filter logs to show only agency transfers (Wholesale transfers)
    final agencyLogs = wallet.transactions
        .where((t) => t.description != null && (t.description!.contains('شحن وكالة') || t.description!.contains('Diamond')))
        .cast<tx_model.Transaction>()
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('agency_dashboard'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Agency Liquidity Overview
            _buildBalanceCard(theme, wallet),
            const SizedBox(height: 20),

            // Target Management Section (New Logic)
            _buildTargetManagement(theme, agencyController),
            const SizedBox(height: 30),

            // 2. Recharge Form
            Text(
              'recharge_customer'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 15),
            _buildRechargeForm(theme, wallet),
            const SizedBox(height: 30),

            // 3. Agency Transfer History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'agency_logs'.tr(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                AppIcon('Icons.history', icon: Icons.history, color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 15),
            _buildLogsList(theme, agencyLogs),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetManagement(ThemeData theme, AgencyController agency) {
    double progress = agency.hostCurrentProgress;
    double target = agency.hostMonthlyTarget;
    bool canWithdraw = progress >= target;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon('Icons.stars', icon: Icons.stars, color: Colors.amber),
              const SizedBox(width: 10),
              Text('تارجت الهوست', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const Spacer(),
              Text('${progress.toInt()} / ${target.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: (progress / target).clamp(0.0, 1.0),
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(canWithdraw ? Colors.green : theme.colorScheme.primary),
            borderRadius: BorderRadius.circular(10),
            minHeight: 10,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isProcessing || !canWithdraw) ? null : () => _handleWithdrawTarget(agency),
                  icon: const AppIcon('Icons.lock_open_rounded', icon: Icons.lock_open_rounded, size: 18),
                  label: const Text('فك التارجت'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isProcessing || progress <= 0) ? null : () => _handleSellTarget(agency),
                  icon: const AppIcon('Icons.sell_rounded', icon: Icons.sell_rounded, size: 18),
                  label: const Text('بيع للوكيل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleWithdrawTarget(AgencyController agency) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الفك'),
        content: const Text('هل أنت متأكد من فك التارجت؟ سيتم تحويل النقاط إلى رصيد محفظة بعد خصم 10% عمولة.'),
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
      final result = await agency.withdrawTarget();
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: result['ok'] ? Colors.green : Colors.red,
        ));
      }
    }
  }

  void _handleSellTarget(AgencyController agency) async {
    final double amount = agency.hostCurrentProgress;
    final theme = Theme.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد البيع'),
        content: Text('هل أنت متأكد من بيع ${amount.toInt()} نقطة لوكيل الشحن؟ سيتم تسجيل العملية في سجلات الشحن.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, foregroundColor: Colors.white),
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      final result = await agency.sellTargetToAgent(amount);
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: result['ok'] ? Colors.green : Colors.red,
        ));
      }
    }
  }

  Widget _buildBalanceCard(ThemeData theme, WalletController wallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.secondary, theme.colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('available_liquidity'.tr(), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
              const AppIcon('Icons.account_balance_wallet', icon: Icons.account_balance_wallet, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '\$${wallet.balance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            '${'rate'.tr()}: 1\$ = 12,000 Diamonds',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeForm(ThemeData theme, WalletController wallet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _targetIdController,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'target_user_id'.tr(),
              hintText: 'Enter ID...',
              prefixIcon: const AppIcon('Icons.person_pin_rounded', icon: Icons.person_pin_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'diamonds_amount'.tr(),
              hintText: 'e.g. 12000',
              prefixIcon: const AppIcon('Icons.diamond_rounded', icon: Icons.diamond_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _handleRecharge(wallet),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('execute_recharge_now'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRecharge(WalletController wallet) async {
    final String targetId = _targetIdController.text.trim();
    final int? diamondAmount = int.tryParse(_amountController.text);

    if (targetId.isEmpty || diamondAmount == null || diamondAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('invalid_input'.tr())));
      return;
    }

    double costUsd = diamondAmount / 12000.0;

    if (wallet.balance < costUsd) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('insufficient_liquidity'.tr())));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Try backend API first (atomic server-side operation)
      final agencyId = UserController().numericId.isNotEmpty ? UserController().numericId : UserController().id;
      final result = await AgencyApiService().recharge(
        agencyId: agencyId,
        targetUserId: targetId,
        targetNumericId: targetId,
        diamonds: diamondAmount,
        costDiamonds: diamondAmount,
      );

      if (result['ok'] == true) {
        if (mounted) {
          setState(() => _isProcessing = false);
          _targetIdController.clear();
          _amountController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('recharge_done_msg'.tr(args: [diamondAmount.toString(), targetId])),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['error'] ?? 'فشلت العملية');
      }
    } catch (e) {
      debugPrint('Agency recharge API failed, falling back to local: $e');
      // Fallback: local-only if backend is unavailable
      Future.delayed(const Duration(seconds: 1), () {
        wallet.addDiamondsToUser(targetId, diamondAmount, costUsd);
        if (mounted) {
          setState(() => _isProcessing = false);
          _targetIdController.clear();
          _amountController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('recharge_done_msg'.tr(args: [diamondAmount.toString(), targetId])),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    }
  }

  Widget _buildLogsList(ThemeData theme, List<tx_model.Transaction> logs) {
    if (logs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            AppIcon('Icons.notes_rounded', icon: Icons.notes_rounded, size: 40, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 10),
            Text('no_transactions_yet'.tr(), style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: AppIcon('Icons.outbound_rounded', icon: Icons.outbound_rounded, color: theme.colorScheme.secondary, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To ID: ${log.targetId}',
                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(log.date),
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-\$${log.amount.abs().toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    log.status.name.toUpperCase(),
                    style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
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
