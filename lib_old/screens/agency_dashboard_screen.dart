import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../controllers/wallet_controller.dart';
import '../controllers/agency_controller.dart';
import '../theme/app_theme.dart';

class AgencyDashboardScreen extends StatefulWidget {
  const AgencyDashboardScreen({super.key});

  @override
  State<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends State<AgencyDashboardScreen> {
  final _targetIdController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isProcessing = false;

  final List<int> _quickRechargeTiers = [500, 1000, 2000, 5000, 10000];

  @override
  void dispose() {
    _targetIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _processCharge() async {
    final targetId = _targetIdController.text.trim();
    final amountStr = _amountController.text.trim();

    if (targetId.isEmpty || amountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال معرف المستخدم والمبلغ')),
      );
      return;
    }

    final amount = int.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ غير صالح')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final wallet = context.read<WalletController>();
      final agency = context.read<AgencyController>();
      
      double costUsd = amount / 12000;

      if (wallet.agencyBalance.value < costUsd) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سيولة وكالة غير كافية')),
        );
      } else {
        await agency.processChargingTransaction(targetId, amount);
        wallet.addDiamondsToUser(targetId, amount, costUsd);

        _targetIdController.clear();
        _amountController.clear();

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
              content: Text('تم شحن $amount ماسة للمستخدم $targetId بنجاح.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.darkBrown)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً', style: TextStyle(color: AppTheme.royalGold)),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _handleQuickRecharge(int amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppTheme.royalGold),
            SizedBox(width: 10),
            Text('شحن سيولة وكالة', style: TextStyle(color: AppTheme.darkBrown, fontSize: 18)),
          ],
        ),
        content: Text('تأكيد شراء سيولة إضافية بمبلغ \$$amount؟\nسيتم إضافة الرصيد فوراً إلى لوحة التحكم.', 
          style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<WalletController>().addAgencyBalance(amount.toDouble());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text('تمت إضافة \$$amount إلى رصيد الوكالة بنجاح.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('تأكيد الدفع', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletController>();
    final agencyCtrl = context.watch<AgencyController>();
    final logs = agencyCtrl.getChargingLogs();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('لوحة تحكم الوكالة', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.royalPurpleDark,
        elevation: 0,
      ),
      body: Material(
        color: Colors.white,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBalanceCard(wallet.agencyBalance.value.toDouble()),
                const SizedBox(height: 30),
                const Text('إعادة شحن سيولة سريعة', style: TextStyle(color: AppTheme.darkBrown, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: _quickRechargeTiers.length,
                  itemBuilder: (context, index) => _buildQuickRechargeButton(_quickRechargeTiers[index]),
                ),
                const SizedBox(height: 40),
                const Text('شحن رصيد لعميل', style: TextStyle(color: AppTheme.darkBrown, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildTextField(_targetIdController, 'معرف المستخدم (Target User ID)', Icons.perm_identity),
                const SizedBox(height: 15),
                _buildTextField(_amountController, 'المبلغ (Amount)', Icons.diamond_rounded, keyboardType: TextInputType.number),
                const SizedBox(height: 25),
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processCharge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.royalGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('تنفيذ الشحن الآن', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 40),
                _buildLogsHeader(),
                const SizedBox(height: 10),
                _buildLogsList(logs),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.royalGold, Color(0xFFB8860B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text('سيولة الوكالة الحالية', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.black, fontSize: 38, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.black12, thickness: 1),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.black45, size: 16),
              SizedBox(width: 5),
              Text('وكيل معتمد - خصم 20%', style: TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRechargeButton(int amount) {
    return InkWell(
      onTap: () => _handleQuickRecharge(amount),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('\$$amount', style: const TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 2),
            const Text('شحن سريع', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('سجل معاملات الوكالة', style: TextStyle(color: AppTheme.darkBrown, fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: () {},
          child: const Text('عرض الكل', style: TextStyle(color: AppTheme.royalGold)),
        ),
      ],
    );
  }

  Widget _buildLogsList(List<dynamic> logs) {
    if (logs.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(30.0),
        child: Text('لا توجد عمليات شحن سابقة', style: TextStyle(color: Colors.grey)),
      ));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              radius: 18,
              child: Icon(Icons.arrow_upward, color: Colors.white, size: 18),
            ),
            title: Text('شحن لـ ID: ${log.targetId}', style: const TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(log.date), style: const TextStyle(fontSize: 11)),
            trailing: Text(
              '+${log.amount.toInt()} ماسة',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.royalGold, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppTheme.royalGold)),
      ),
    );
  }
}
