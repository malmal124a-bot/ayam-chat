import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/host_agency_controller.dart';

class HostAgencyScreen extends StatefulWidget {
  const HostAgencyScreen({super.key});

  @override
  State<HostAgencyScreen> createState() => _HostAgencyScreenState();
}

class _HostAgencyScreenState extends State<HostAgencyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HostAgencyController _controller = HostAgencyController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('وكالة المضيفين', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stats Overview
          _buildStatsOverview(theme),
          const SizedBox(height: 20),
          
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.secondary,
              labelColor: theme.colorScheme.secondary,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'المضيفين'),
                Tab(text: 'الإحصائيات'),
                Tab(text: 'المدفوعات'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHostsTab(theme),
                _buildStatsTab(theme),
                _buildPayoutsTab(theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHostDialog,
        backgroundColor: theme.colorScheme.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildApplicationStatusBar(theme),
    );
  }

  Widget _buildStatsOverview(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary.withValues(alpha: 0.2),
            theme.colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('المضيفين', '24', Icons.people_outline, theme),
              _buildStatItem('الهدف الشهري', '85%', Icons.trending_up, theme),
              _buildStatItem('الأرباح', '50K', Icons.diamond, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.secondary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHostsTab(ThemeData theme) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<HostAgencyController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.hosts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (controller.hosts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد مضيفين بعد',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط على + لإضافة مضيف جديد',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 12),
                  ),
                ],
              ),
            );
          }
          
          final hosts = controller.hosts;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hosts.length,
            itemBuilder: (context, index) {
              final host = hosts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.12)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.colorScheme.surface,
                          child: Icon(Icons.person, color: theme.colorScheme.secondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                host['name'] as String,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${host['id']}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${host['earnings']} 💎',
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                              onSelected: (value) {
                                if (value == 'remove') {
                                  _showRemoveHostDialog(host['id'] as String);
                                } else if (value == 'details') {
                                  _showHostDetailsDialog(host);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'details', child: Text('التفاصيل')),
                                const PopupMenuItem(value: 'remove', child: Text('إزالة', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ساعات العمل: ${host['hours']}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: host['progress'] as double,
                                  backgroundColor: theme.colorScheme.surface,
                                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'الهدف: ${host['target']}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard('إجمالي الأرباح', '150,000 💎', Icons.diamond, theme),
          const SizedBox(height: 12),
          _buildStatCard('المضيفين النشطين', '24', Icons.people, theme),
          const SizedBox(height: 12),
          _buildStatCard('ساعات العمل الإجمالية', '1,200h', Icons.access_time, theme),
          const SizedBox(height: 12),
          _buildStatCard('نسبة الإنجاز', '78%', Icons.check_circle, theme),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.secondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutsTab(ThemeData theme) {
    final payouts = List.generate(5, (i) => {
      'date': '2024-${(i + 1).toString().padLeft(2, '0')}-15',
      'amount': '${(i + 1) * 10000}',
      'status': i == 0 ? 'completed' : 'pending',
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: payouts.length,
      itemBuilder: (context, index) {
        final payout = payouts[index];
        final isCompleted = payout['status'] == 'completed';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.pending,
                  color: isCompleted ? Colors.green : Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payout['date'] as String,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted ? 'تم الدفع' : 'قيد المعالجة',
                      style: TextStyle(
                        color: isCompleted ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${payout['amount']} 💎',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddHostDialog() {
    final TextEditingController idController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('إضافة مضيف جديد', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'ID المضيف',
                hintText: 'أدخل ID المضيف',
                labelStyle: TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'اسم المضيف',
                hintText: 'أدخل اسم المضيف',
                labelStyle: TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (idController.text.isEmpty || nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى ملء جميع الحقول')),
                );
                return;
              }
              
              final success = await _controller.addHost(
                id: idController.text,
                name: nameController.text,
              );
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'تم إضافة المضيف: ${nameController.text}' : 'فشل إضافة المضيف'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showRemoveHostDialog(String hostId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('إزالة المضيف', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من إزالة المضيف $hostId؟', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _controller.removeHost(hostId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'تم إزالة المضيف' : 'فشل إزالة المضيف'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
  }

  void _showHostDetailsDialog(Map<String, dynamic> host) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(host['name'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('ID:', host['id'] as String),
            const SizedBox(height: 8),
            _detailRow('ساعات العمل:', '${host['hours']}'),
            const SizedBox(height: 8),
            _detailRow('الهدف:', '${host['target']}'),
            const SizedBox(height: 8),
            _detailRow('الأرباح:', '${host['earnings']} 💎'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationStatusBar(ThemeData theme) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<HostAgencyController>(
        builder: (context, controller, child) {
          final status = controller.applicationStatus;
          if (status == null) {
            return Container(
              padding: const EdgeInsets.all(16),
              color: theme.cardColor,
              child: ElevatedButton(
                onPressed: _showApplicationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('التقدم بطلب للانضمام كوكالة مضيفين', style: TextStyle(color: Colors.white)),
              ),
            );
          }
          
          Color statusColor;
          String statusText;
          switch (status['status']) {
            case 'approved':
              statusColor = Colors.green;
              statusText = 'تم القبول';
              break;
            case 'rejected':
              statusColor = Colors.red;
              statusText = 'تم الرفض';
              break;
            default:
              statusColor = Colors.orange;
              statusText = 'قيد المراجعة';
          }
          
          return Container(
            padding: const EdgeInsets.all(16),
            color: theme.cardColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'حالة الطلب: $statusText',
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${status["id"]} | الاسم: ${status["name"]}',
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showApplicationDialog() {
    final TextEditingController idController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController proofController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('طلب الانضمام كوكالة مضيفين', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'ID الوكالة',
                  hintText: 'أدخل ID الوكالة',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'اسم الوكالة',
                  hintText: 'أدخل اسم الوكالة',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: proofController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'إثبات/معلومات إضافية',
                  hintText: 'أدخل معلومات الإثبات',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (idController.text.isEmpty || nameController.text.isEmpty || proofController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى ملء جميع الحقول')),
                );
                return;
              }
              
              final success = await _controller.submitApplication(
                id: idController.text,
                name: nameController.text,
                proof: proofController.text,
              );
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'تم إرسال الطلب بنجاح' : 'فشل إرسال الطلب'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
            child: const Text('إرسال الطلب'),
          ),
        ],
      ),
    );
  }
}