import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/host_agency_controller.dart';
import 'agency_open_request_screen.dart';

class HostAgencyScreen extends StatefulWidget {
  const HostAgencyScreen({super.key});

  @override
  State<HostAgencyScreen> createState() => _HostAgencyScreenState();
}

class _HostAgencyScreenState extends State<HostAgencyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HostAgencyController _controller = HostAgencyController();
  final TextEditingController _transferTargetController = TextEditingController();
  final TextEditingController _transferAmountController = TextEditingController();

  bool get _isHosting => _controller.agencyType == 'hosting';

  List<Widget> get _tabs => _isHosting
      ? const [Tab(text: 'الأعضاء'), Tab(text: 'أرباحي'), Tab(text: 'الطلبات')]
      : [
          const Tab(text: 'الأعضاء'),
          const Tab(text: 'أرباحي'),
          Tab(text: 'الطلبات${_controller.joinRequests.isNotEmpty ? " (${_controller.joinRequests.length})" : ""}'),
          const Tab(text: 'السجلات'),
          const Tab(text: 'التحويلات'),
        ];

  List<Widget> get _tabViews => _isHosting
      ? [_buildMembersTab(_controller), _buildEarningsTab(_controller), _buildJoinRequestsTab(_controller)]
      : [
          _buildMembersTab(_controller),
          _buildEarningsTab(_controller),
          _buildJoinRequestsTab(_controller),
          _buildLogsTab(_controller),
          _buildTransferTab(_controller),
        ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _controller.addListener(_onControllerUpdate);
  }

  bool _lastWasHosting = false;

  void _onControllerUpdate() {
    if (!mounted) return;
    final nowHosting = _controller.agencyType == 'hosting';
    if (nowHosting != _lastWasHosting) {
      _lastWasHosting = nowHosting;
      final oldIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(
        length: nowHosting ? 3 : 5,
        vsync: this,
        initialIndex: nowHosting && oldIndex >= 2 ? 0 : oldIndex,
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _tabController.dispose();
    _transferTargetController.dispose();
    _transferAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<HostAgencyController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.agency == null && !controller.agencyDeleted) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (controller.agencyDeleted) {
            return _buildAgencyDeleted(theme, controller);
          }

          if (controller.agency == null) {
            return _buildNoAgency(theme, controller);
          }

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text(controller.agencyName, style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
                  onSelected: (v) => _handleMenuAction(v, controller),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'refresh', child: Text('تحديث')),
                    if (!controller.isOwner)
                      const PopupMenuItem(value: 'leave', child: Text('الانسحاب من الوكالة', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                _buildAgencyHeader(theme, controller),
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
                    tabs: _tabs,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _tabViews,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildIncomingInvites(
      ThemeData theme, HostAgencyController controller) {
    final invites = controller.incomingInvites;
    if (invites.isEmpty) return const [];

    return [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline, color: theme.colorScheme.secondary, size: 20),
                const SizedBox(width: 8),
                Text('لديك دعوات انضمام',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary)),
              ],
            ),
            const SizedBox(height: 12),
            ...invites.map((inv) {
              final requestId = (inv['id'] ?? '').toString();
              final agencyId = (inv['agency_id'] ?? '').toString();
              final name = (inv['agency_name'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.isEmpty ? 'دعوة انضمام إلى وكالة' : 'دعوة للانضمام إلى $name',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await controller.respondInvite(requestId, agencyId, false);
                      },
                      child: const Text('رفض'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary),
                      onPressed: () async {
                        await controller.respondInvite(requestId, agencyId, true);
                        await controller.refresh();
                      },
                      child: const Text('قبول',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ];
  }

  Widget _buildNoAgency(ThemeData theme, HostAgencyController controller) {
    final bool pending = controller.hasOpenRequest;
    final bool approved = controller.openRequestApproved;
    final bool rejected = controller.openRequestRejected;
    final String? rejectNote = controller.openRequest?['note']?.toString();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('agency'.tr(), style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ..._buildIncomingInvites(theme, controller),
              if (pending)
                _buildStatus(theme,
                    icon: Icons.hourglass_top,
                    color: Colors.amber,
                    title: 'انتظر، جاري الموافقة من قبل الإدارة',
                    subtitle: 'تم إرسال طلب فتح وكالتك، سيتم إشعارك فور الموافقة.')
              else if (approved)
                _buildStatus(theme,
                    icon: Icons.check_circle,
                    color: Colors.green,
                    title: 'تمت الموافقة على وكالتك 🎉',
                    subtitle: 'قم بتحديث الصفحة لفتح لوحة إدارة الوكالة.')
              else if (rejected)
                _buildStatus(theme,
                    icon: Icons.cancel,
                    color: Colors.red,
                    title: 'تم رفض طلب فتح الوكالة',
                    subtitle: rejectNote != null && rejectNote.isNotEmpty
                        ? rejectNote
                        : 'يمكنك التواصل مع الإدارة لمعرفة السبب.')
              else ...[
                Icon(Icons.business_outlined,
                    size: 80,
                    color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
                const SizedBox(height: 20),
                Text('لا توجد وكالة مسجلة لك',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 16)),
                const SizedBox(height: 8),
                Text('يمكنك الانضمام إلى وكالة أو فتح وكالة جديدة',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 12)),
              ],
              const SizedBox(height: 24),
              if (pending)
                ElevatedButton.icon(
                  onPressed: () => controller.refresh(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('تحديث حالة الطلب',
                      style: TextStyle(color: Colors.white)),
                )
              else if (approved)
                ElevatedButton.icon(
                  onPressed: () => controller.refresh(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('دخول لوحة الوكالة',
                      style: TextStyle(color: Colors.white)),
                )
              else if (!rejected) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    final created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (_) => const AgencyOpenRequestScreen()),
                    );
                    if (created == true) controller.refresh();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      minimumSize: const Size(double.infinity, 52)),
                  icon: Icon(Icons.add_business, color: theme.colorScheme.onSecondary),
                  label: Text('هل تريد فتح وكالة؟',
                      style: TextStyle(
                          color: theme.colorScheme.onSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 28),
                _buildOpenAgenciesList(theme, controller),
              ]
              else
                ElevatedButton.icon(
                  onPressed: () => controller.refresh(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('تحديث',
                      style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpenAgenciesList(ThemeData theme, HostAgencyController controller) {
    final agencies = controller.openAgencies;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.explore_outlined,
                size: 18, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text('الوكالات المفتوحة على النظام',
                style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.refresh, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              onPressed: () => controller.refreshOpenAgencies(),
              tooltip: 'تحديث',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (agencies.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('لا توجد وكالات مفتوحة حالياً',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 13)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: agencies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final a = agencies[index];
              final id = (a['id'] ?? '').toString();
              final name = (a['name'] ?? 'وكالة').toString();
              final desc = (a['description'] ?? '').toString();
              final photo = (a['photo_url'] ?? '').toString();
              final requested = controller.hasRequestedAgency(id);
              return Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.15)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo.isEmpty
                        ? Icon(Icons.business, color: theme.colorScheme.secondary)
                        : null,
                  ),
                  title: Text(name,
                      style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (desc.isNotEmpty)
                        Text(desc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                                fontSize: 12)),
                    ],
                  ),
                  trailing: requested
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('طلبك قيد المراجعة',
                              style: TextStyle(
                                  color: Colors.amber.shade800, fontSize: 11)),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            final err =
                                await controller.requestJoinAgency(id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err ?? 'تم إرسال طلب الانضمام بنجاح'),
                                backgroundColor:
                                    err == null ? Colors.green : Colors.red,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            minimumSize: const Size(72, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Text('انضمام',
                              style: TextStyle(
                                  color: theme.colorScheme.onSecondary,
                                  fontSize: 13)),
                        ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatus(ThemeData theme,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle}) {
    return Column(
      children: [
        Icon(icon, size: 72, color: color.withValues(alpha: 0.8)),
        const SizedBox(height: 20),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 13)),
      ],
    );
  }

  Widget _buildAgencyDeleted(ThemeData theme, HostAgencyController controller) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('agency'.tr(), style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block_outlined, size: 80, color: Colors.red.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            Text(controller.deletionMessage ?? 'تم إغلاق الوكالة', style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('يمكنك التواصل مع الإدارة لمعرفة التفاصيل', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary),
              child: const Text('العودة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencyHeader(ThemeData theme, HostAgencyController controller) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: theme.colorScheme.secondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.business, color: theme.colorScheme.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(controller.agencyName, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(_typeLabel(controller.agencyType), style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('رصيد الماس', '${controller.diamondsBalance}', Icons.diamond, theme),
              if (_hasRechargeFeatures(controller.agencyType)) ...[
                _buildMiniStat('شحن المستخدمين', '${controller.totalRecharged}', Icons.send, theme),
                _buildMiniStat('السحب', '${controller.totalWithdrawn}', Icons.download, theme),
              ],
              _buildMiniStat('الأعضاء', '${controller.members.length}', Icons.people, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.secondary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MEMBERS TAB
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMembersTab(HostAgencyController controller) {
    final theme = Theme.of(context);
    if (controller.members.isEmpty && !controller.isOwner) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('لا يوجد أعضاء', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (controller.isOwner) _buildInviteCard(theme, controller),
        if (controller.isOwner) const SizedBox(height: 12),
        if (controller.members.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 64, color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('لا يوجد أعضاء بعد', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          )
        else
          ...controller.members.map((m) => _buildMemberCard(m, theme, controller)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EARNINGS TAB (أرباحي) - member's own earnings / level / withdraw /
  // shipping-agent link / transfer / leave-request.
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEarningsTab(HostAgencyController controller) {
    final theme = Theme.of(context);
    final agentCtrl = TextEditingController();
    final transferCtrl = TextEditingController();

    final hasAgent = (controller.shippingAgentId ?? '').isNotEmpty;
    final agentName = controller.currentMember?['shipping_agent_name']?.toString() ?? '';

    return StatefulBuilder(
      builder: (context, setState) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('أرباحي الحالية', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('المستوى ${controller.myLevel}',
                          style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('${controller.myBalance}', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 34, fontWeight: FontWeight.bold)),
                  Text('ماس', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('التارجت: ${controller.myTarget}', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
                      Text('باقي ${controller.myRemaining}', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: controller.myProgress,
                      minHeight: 12,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${(controller.myProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (controller.myBalance <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد رصيد قابل للسحب'), backgroundColor: Colors.orange));
                          return;
                        }
                        final result = await controller.requestSalaryWithdrawal();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['ok'] ? Colors.green : Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('سحب أرباحي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Shipping agent linking + transfer ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('وكيل الشحن', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  if (hasAgent)
                    RichText(
                      text: TextSpan(
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                        children: [
                          const TextSpan(text: 'وكيلك: '),
                          TextSpan(text: agentName.isNotEmpty ? agentName : controller.shippingAgentId, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else ...[
                    TextField(
                      controller: agentCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'آيدي وكيل الشحن', filled: true, fillColor: theme.scaffoldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (agentCtrl.text.trim().isEmpty) return;
                          final r = await controller.setMyShippingAgent(agentCtrl.text.trim());
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message']), backgroundColor: r['ok'] ? Colors.green : Colors.red));
                            setState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary),
                        child: const Text('ربط وكيل الشحن', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                  if (hasAgent) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: transferCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'المبلغ (ماس)', filled: true, fillColor: theme.scaffoldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final amount = int.tryParse(transferCtrl.text.trim()) ?? 0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل مبلغاً صحيحاً'), backgroundColor: Colors.orange));
                            return;
                          }
                          final r = await controller.requestTransfer(amount);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message']), backgroundColor: r['ok'] ? Colors.green : Colors.red));
                            if (r['ok'] == true) transferCtrl.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary),
                        child: const Text('تحويل لوكيل الشحن', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Leave request ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withValues(alpha: 0.2))),
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('رابط يرغب بالانسحاب من الوكالة؟ أرسل طلباً للوكيل للموافقة.',
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('طلب الانسحاب'),
                      content: const Text('سيتم إرسال طلب انسحاب إلى الوكيل للموافقة. متابعة؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('إرسال')),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    final r = await controller.requestLeaveAgency();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message']), backgroundColor: r['ok'] ? Colors.green : Colors.red));
                  }
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.withValues(alpha: 0.5))),
                child: const Text('إرسال طلب الانسحاب من الوكالة'),
              ),
            ),
            const SizedBox(height: 12),
            Text('ملاحظة: تُصفَّر أرباحك مباشرة بعد سحب الراتب (بدون ترحيل). إذا كانت الفترة أسبوعية ولم تسحب تُرحَّل للفترة التالية.',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11)),
          ],
        );
      },
    );
  }

  // Invite a user (by numeric id) to join the agency as host/member
  Widget _buildInviteCard(ThemeData theme, HostAgencyController controller) {
    final inviteCtrl = TextEditingController();
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_add_alt_1, size: 18, color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text('دعوة عضو إلى الوكالة', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: inviteCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'اكتب آيدي المستخدم (مثال: 12345678)',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await controller.inviteMember(inviteCtrl.text);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] as String? ?? ''),
                        backgroundColor: result['ok'] == true ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary),
                  icon: const Icon(Icons.send, size: 16, color: Colors.white),
                  label: const Text('إرسال دعوة', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'سيصل للمستخدم إشعار بدعوة الانضمام، ويستطيع الموافقة أو الرفض',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member, ThemeData theme, HostAgencyController controller) {
    final roleColors = {
      'owner': Colors.amber,
      'supervisor': Colors.cyan,
      'host': theme.colorScheme.secondary,
    };
    final roleLabels = {'owner': 'مالك', 'supervisor': 'مشرف', 'host': 'مضيف'};

    return GestureDetector(
      onTap: () => _showMemberDetail(member, controller),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.surface,
              backgroundImage: (member['photo_url'] as String?)?.isNotEmpty == true
                  ? NetworkImage(member['photo_url'] as String)
                  : null,
              child: (member['photo_url'] as String?)?.isNotEmpty == true
                  ? null
                  : Icon(Icons.person, color: theme.colorScheme.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(member['name'] ?? 'عضو', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (roleColors[member['role']] ?? Colors.grey).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(roleLabels[member['role']] ?? member['role'], style: TextStyle(color: roleColors[member['role']] ?? Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('ID: ${member['numeric_id'] ?? ''}', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildMemberStat('💎', '${member['diamonds'] ?? 0}', theme),
                      const SizedBox(width: 12),
                      _buildMemberStat('📈', '${member['monthly_earnings'] ?? 0}/شهر', theme),
                      const SizedBox(width: 12),
                      _buildMemberStat('💰', '${member['balance'] ?? 0}', theme),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberStat(String emoji, String value, ThemeData theme) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(value, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MEMBER DETAIL SHEET
  // ═══════════════════════════════════════════════════════════════
  void _showMemberDetail(Map<String, dynamic> member, HostAgencyController controller) async {
    await controller.loadMemberDetail(member['auth_uid'] ?? member['id']);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: controller,
        child: Consumer<HostAgencyController>(
          builder: (ctx, ctrl, _) {
            final detail = ctrl.selectedMemberDetail;
            final info = detail?['info'] as Map<String, dynamic>?;
            final theme = Theme.of(ctx);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (ctx, scrollController) => Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 20),
                    // Member header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: (member['photo_url'] as String?)?.isNotEmpty == true
                              ? NetworkImage(member['photo_url'] as String)
                              : null,
                          child: (member['photo_url'] as String?)?.isNotEmpty == true
                              ? null
                              : Icon(Icons.person, color: theme.colorScheme.secondary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member['name'] ?? '', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
                              Text('ID: ${member['numeric_id'] ?? ''}', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Stats cards
                    if (detail != null) ...[
                      if (_hasRechargeFeatures(controller.agencyType))
                        _buildDetailStatsGrid(detail, theme),
                      if (!_hasRechargeFeatures(controller.agencyType))
                        _buildDetailStatsGridHostingOnly(detail, theme),
                      const SizedBox(height: 20),
                      // Gifts section
                      Text('سجل الهدايا', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      if ((detail['gifts'] as List?)?.isEmpty ?? true)
                        Text('لا توجد هدايا', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12))
                      else
                        ...((detail['gifts'] as List).take(20).map((g) => _buildGiftItem(g, theme))),
                      const SizedBox(height: 20),
                      // Recharge history (shipping/mixed only)
                      if (_hasRechargeFeatures(controller.agencyType)) ...[
                        Text('سجل الشحن من الوكالة', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        if ((detail['recharges'] as List?)?.isEmpty ?? true)
                          Text('لم يتم الشحن بعد', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12))
                        else
                          ...((detail['recharges'] as List).map((r) => _buildRechargeItem(r, theme))),
                        const SizedBox(height: 20),
                        // Withdrawal history
                        Text('سجل السحب من العضو', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        if ((detail['withdrawals'] as List?)?.isEmpty ?? true)
                          Text('لا يوجد سحوبات', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12))
                        else
                          ...((detail['withdrawals'] as List).map((w) => _buildWithdrawalItem(w, theme))),
                        const SizedBox(height: 20),
                      ],
                      // Actions
                      if (controller.isOwner) ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('إزالة العضو'),
                                content: Text('هل تريد إزالة ${member['name']} من الوكالة؟'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('إزالة', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final result = await controller.removeMember(member['auth_uid'] ?? member['id']);
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message']), backgroundColor: result['ok'] ? Colors.green : Colors.red),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.person_remove, color: Colors.white),
                          label: const Text('إزالة من الوكالة', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 48)),
                        ),
                      ],
                    ] else ...[
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ).then((_) => controller.clearMemberDetail());
  }

  Widget _buildDetailStatsGridHostingOnly(Map<String, dynamic> detail, ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2,
      children: [
        _buildDetailStatCard('هدايا مرسلة', '${detail['total_gifts_sent']}', Icons.card_giftcard, Colors.purple, theme),
        _buildDetailStatCard('هدايا مستلمة', '${detail['total_gifts_received']}', Icons.redeem, Colors.teal, theme),
      ],
    );
  }

  Widget _buildDetailStatsGrid(Map<String, dynamic> detail, ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2,
      children: [
        _buildDetailStatCard('هدايا مرسلة', '${detail['total_gifts_sent']}', Icons.card_giftcard, Colors.purple, theme),
        _buildDetailStatCard('هدايا مستلمة', '${detail['total_gifts_received']}', Icons.redeem, Colors.teal, theme),
        _buildDetailStatCard('شحن من الوكالة', '${detail['total_recharged']}', Icons.send, Colors.blue, theme),
        _buildDetailStatCard('سحب من العضو', '${detail['total_withdrawn']}', Icons.download, Colors.orange, theme),
      ],
    );
  }

  Widget _buildDetailStatCard(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildGiftItem(Map<String, dynamic> gift, ThemeData theme) {
    final isSender = gift['sender_id'] != null;
    final diamonds = (gift['diamonds'] as num?)?.toInt() ?? 0;
    final createdAt = gift['created_at'] != null ? gift['created_at'].toString().substring(0, 10) : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(isSender ? Icons.arrow_upward : Icons.arrow_downward, color: isSender ? Colors.red : Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isSender ? 'إرسال هدية' : 'استلام هدية', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(createdAt, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10)),
              ],
            ),
          ),
          Text('${isSender ? '-' : '+'}$diamonds 💎', style: TextStyle(color: isSender ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRechargeItem(Map<String, dynamic> r, ThemeData theme) {
    final diamonds = (r['diamonds'] as num?)?.toInt() ?? 0;
    final cost = (r['cost_diamonds'] as num?)?.toInt() ?? 0;
    final createdAt = r['created_at'] != null ? r['created_at'].toString().substring(0, 10) : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.send, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('شحن $diamonds ماس', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
                Text('التكلفة: $cost ماس | $createdAt', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalItem(Map<String, dynamic> w, ThemeData theme) {
    final diamonds = (w['diamonds'] as num?)?.toInt() ?? 0;
    final createdAt = w['created_at'] != null ? w['created_at'].toString().substring(0, 10) : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.download, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سحب $diamonds ماس', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(createdAt, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // JOIN REQUESTS TAB
  // ═══════════════════════════════════════════════════════════════
  Widget _buildJoinRequestsTab(HostAgencyController controller) {
    final theme = Theme.of(context);
    final isOwner = controller.isOwner;

    // Build the list of child widgets: owner approval sections first,
    // then join requests.
    final children = <Widget>[];

    // ── Owner: pending salary-withdrawal requests ──
    if (isOwner && controller.withdrawRequests.isNotEmpty) {
      children.add(Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('طلبات سحب الأرباح', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
      ));
      controller.withdrawRequests.toList().forEach((req) {
        children.add(Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: (req['member_photo_url'] as String?)?.isNotEmpty == true ? NetworkImage(req['member_photo_url'] as String) : null,
                    child: (req['member_photo_url'] as String?)?.isNotEmpty == true ? null : const Icon(Icons.person),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req['member_name'] ?? 'مستخدم', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        Text('المبلغ: ${req['amount']} ماس', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'موافقة',
                        onPressed: () async {
                          final r = await controller.approveWithdrawal(req['id']);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message']), backgroundColor: r['ok'] ? Colors.green : Colors.red));
                        },
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                      ),
                      IconButton(
                        tooltip: 'رفض',
                        onPressed: () async {
                          final r = await controller.rejectWithdrawal(req['id']);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message']), backgroundColor: r['ok'] ? Colors.green : Colors.red));
                        },
                        icon: const Icon(Icons.cancel, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ));
      });
    }

    // ── Owner: pending leave requests ──
    if (isOwner && controller.leaveRequests.isNotEmpty) {
      children.add(Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('طلبات الانسحاب من الوكالة', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
      ));
      controller.leaveRequests.toList().forEach((req) {
        children.add(Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(req['member_name'] ?? 'مستخدم', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                tooltip: 'قبول الانسحاب',
                onPressed: () async {
                  final r = await controller.respondLeave(req['id'], true);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message']), backgroundColor: r['ok'] ? Colors.green : Colors.red));
                },
                icon: const Icon(Icons.check_circle, color: Colors.green),
              ),
              IconButton(
                tooltip: 'رفض',
                onPressed: () async {
                  final r = await controller.respondLeave(req['id'], false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message']), backgroundColor: r['ok'] ? Colors.green : Colors.red));
                },
                icon: const Icon(Icons.cancel, color: Colors.red),
              ),
            ],
          ),
        ));
      });
    }

    // ── Join/invite requests ──
    if (controller.joinRequests.isEmpty) {
      children.add(Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            children: [
              Icon(Icons.person_add_outlined, size: 64, color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('لا توجد طلبات أو دعوات', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ));
    } else {
      controller.joinRequests.toList().forEach((req) {
        final status = req['status'] as String? ?? 'pending';
        final isInvited = status == 'invited';
        final borderColor = isInvited ? Colors.blue.withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.2);
        children.add(Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: (req['user_photo'] as String?)?.isNotEmpty == true ? NetworkImage(req['user_photo'] as String) : null,
                child: (req['user_photo'] as String?)?.isNotEmpty == true ? null : Icon(Icons.person, color: isInvited ? Colors.blue : Colors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(req['user_name'] ?? 'مستخدم', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isInvited ? Colors.blue.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(isInvited ? 'دعوة مرسلة' : 'طلب انضمام', style: TextStyle(color: isInvited ? Colors.blue : Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text('ID: ${req['user_numeric_id'] ?? ''}', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      final result = await controller.approveJoinRequest(req['id'], req['user_id']);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['ok'] ? Colors.green : Colors.red));
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  IconButton(
                    onPressed: () async {
                      final result = await controller.rejectJoinRequest(req['id']);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['ok'] ? Colors.green : Colors.red));
                    },
                    icon: const Icon(Icons.cancel, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ));
      });
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: children,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LOGS TAB
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLogsTab(HostAgencyController controller) {
    final theme = Theme.of(context);
    final hasRecharges = controller.rechargeLogs.isNotEmpty;
    final hasWithdrawals = controller.withdrawalLogs.isNotEmpty;

    if (!hasRecharges && !hasWithdrawals) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('لا توجد سجلات بعد', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (hasRecharges) ...[
          Text('شحن المستخدمين', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...controller.rechargeLogs.map((r) => _buildLogItem(r, 'recharge', theme)),
          const SizedBox(height: 16),
        ],
        if (hasWithdrawals) ...[
          Text('السحب من المستخدمين', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...controller.withdrawalLogs.map((w) => _buildLogItem(w, 'withdrawal', theme)),
        ],
      ],
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log, String type, ThemeData theme) {
    final diamonds = (log['diamonds'] as num?)?.toInt() ?? 0;
    final createdAt = log['created_at'] != null ? log['created_at'].toString().substring(0, 16) : '';
    final isRecharge = type == 'recharge';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isRecharge ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(isRecharge ? Icons.arrow_upward : Icons.arrow_downward, color: isRecharge ? Colors.blue : Colors.orange, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${isRecharge ? 'شحن' : 'سحب'} $diamonds ماس', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(createdAt, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10)),
              ],
            ),
          ),
          Text('${isRecharge ? '-' : '+'}$diamonds', style: TextStyle(color: isRecharge ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TRANSFER TAB
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTransferTab(HostAgencyController controller) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تحويل الأرباح لوكيل الشحن', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(' حوّل ماس الوكالة إلى مستخدم (وكيل شحن)', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.12))),
            child: Column(
              children: [
                _buildTransferField(_transferTargetController, 'المعرّف الرقمي للهدف', Icons.person, theme),
                const SizedBox(height: 12),
                _buildTransferField(_transferAmountController, 'عدد الماس', Icons.diamond, theme, isNumber: true),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final target = _transferTargetController.text.trim();
                      final amount = int.tryParse(_transferAmountController.text.trim()) ?? 0;
                      if (target.isEmpty || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء جميع الحقول بشكل صحيح'), backgroundColor: Colors.orange));
                        return;
                      }
                      final result = await controller.transferEarningsToAgent(amount, target);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message']), backgroundColor: result['ok'] ? Colors.green : Colors.red),
                        );
                        if (result['ok']) {
                          _transferTargetController.clear();
                          _transferAmountController.clear();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('تحويل الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferField(TextEditingController controller, String label, IconData icon, ThemeData theme, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.secondary),
        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.2))),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════
  bool _hasRechargeFeatures(String agencyType) {
    return agencyType != 'hosting';
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'shipping': return 'وكالة شحن ماس';
      case 'hosting': return 'وكالة استضافة';
      case 'mixed': return 'وكالة مختلطة';
      default: return type;
    }
  }

  void _handleMenuAction(String action, HostAgencyController controller) async {
    switch (action) {
      case 'refresh':
        await controller.refresh();
        break;
      case 'leave':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('الانسحاب من الوكالة'),
            content: const Text('هل أنت متأكد من الانسحاب؟ لن تتمكن من العودة إلا بموافقة المالك.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('انسحاب', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final result = await controller.leaveAgency();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['ok'] ? Colors.green : Colors.red));
            if (result['ok']) Navigator.pop(context);
          }
        }
        break;
    }
  }
}
