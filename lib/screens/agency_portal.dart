import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/agency_controller.dart';
import '../controllers/user_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class AgencyPortal extends StatelessWidget {
  const AgencyPortal({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white, // ضمان خلفية صلبة لمنع التداخل
        appBar: AppBar(
          backgroundColor: AppTheme.nearBlackPurple,
          elevation: 2,
          title: Text(
            'لوحة تحكم وكالة الموديفين',
            style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppTheme.royalGold,
            labelColor: AppTheme.royalGold,
            unselectedLabelColor: Colors.white54,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'إدارة التارجت'),
              Tab(text: 'قائمة الداعمين'),
            ],
          ),
        ),
        body: Material( // لف المحتوى بـ Material لضمان الرؤية
          color: Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints.expand(),
            child: Consumer<AgencyController>(
              builder: (context, controller, child) {
                return const TabBarView(
                  children: [
                    _TargetManagementTab(),
                    _SupportersTab(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetManagementTab extends StatelessWidget {
  const _TargetManagementTab();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AgencyController>(context);
    final user = Provider.of<UserController>(context);
    
    double progress = controller.hostCurrentProgress / controller.hostMonthlyTarget;
    if (progress > 1.0) progress = 1.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'تارجت المضيف الموديف (الشهر الحالي)',
            progress: progress,
            current: controller.hostCurrentProgress.toInt(),
            target: controller.hostMonthlyTarget.toInt(),
            unit: 'نقطة',
          ),
          const SizedBox(height: 20),
          if (user.isAgent) ...[
            _buildInfoCard(
              title: 'تارجت وكالة الموديفين الإجمالي',
              progress: controller.agencyCurrentProgress / controller.agencyMonthlyTarget,
              current: controller.agencyCurrentProgress.toInt(),
              target: controller.agencyMonthlyTarget.toInt(),
              unit: 'نقطة',
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'سحب الأرباح (الفك)',
            style: TextStyle(color: AppTheme.darkBrown, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppTheme.royalGold.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الرصيد القابل للسحب:', style: TextStyle(color: AppTheme.darkBrown)),
                    Text('${controller.hostCurrentProgress.toInt()} نقطة', 
                        style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
                const Divider(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.royalGold,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: () => _showWithdrawDialog(context, controller),
                  child: const Text('تحويل إلى رصيد المحفظة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AppIcon('Icons.info_outline', icon: Icons.info_outline, color: AppTheme.royalGold, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'يتم خصم 10% عمولة إدارية لوكالة الموديفين',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required double progress,
    required int current,
    required int target,
    required String unit,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (color ?? AppTheme.royalGold).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppTheme.darkBrown, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    height: 12,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color ?? AppTheme.royalGold, (color ?? AppTheme.royalGold).withOpacity(0.6)]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$current $unit', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
                  const Text('المحقق حالياً', style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$target $unit', style: TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.w900)),
                  const Text('الهدف الشهري', style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, AgencyController controller) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('سحب أرباح الموديفين', style: TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('رصيدك الحالي المتاح للفك:', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text('${controller.hostCurrentProgress.toInt()} نقطة', style: TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'كمية النقاط للتحويل',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold, foregroundColor: Colors.black),
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              final result = controller.withdrawEarnings(amount);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
            },
            child: const Text('تأكيد التحويل'),
          ),
        ],
      ),
    );
  }
}

class _SupportersTab extends StatelessWidget {
  const _SupportersTab();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AgencyController>(context);
    final user = Provider.of<UserController>(context);
    final supporters = controller.getSupporters(user.id);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              AppIcon('Icons.favorite', icon: Icons.favorite, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Text('أكثر الداعمين لك في وكالة الموديفين', style: TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: supporters.length,
            itemBuilder: (context, index) {
              final supporter = supporters[index];
              return Card(
                elevation: 0,
                color: AppTheme.card,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: index == 0 ? AppTheme.royalGold : Colors.grey[300],
                    child: Text('${index + 1}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(supporter.name, style: TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.bold)),
                  subtitle: Text('تاريخ الدعم: ${supporter.lastSupport.day}/${supporter.lastSupport.month}', style: const TextStyle(fontSize: 10)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${supporter.amount.toInt()}', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.w900, fontSize: 16)),
                      const Text('نقطة', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}