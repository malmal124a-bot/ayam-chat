import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../controllers/agency_controller.dart';
import '../models/agency_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import 'agency_portal.dart';

class AgencyManagementScreen extends StatefulWidget {
  const AgencyManagementScreen({super.key});

  @override
  State<AgencyManagementScreen> createState() => _AgencyManagementScreenState();
}

class _AgencyManagementScreenState extends State<AgencyManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // خلفية بيضاء صلبة لضمان الرؤية
      appBar: AppBar(
        title: Text('agency_dashboard'.tr(), style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.royalPurpleDark,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.royalGold,
          labelColor: AppTheme.royalGold,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: 'overview'.tr()),
            Tab(text: 'members'.tr()),
            Tab(text: 'join_requests'.tr()),
            Tab(text: 'sent_invites'.tr()),
          ],
        ),
      ),
      body: Material(
        color: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: Consumer<AgencyController>(
            builder: (context, controller, child) {
              final myAgency = controller.myAgency;

              if (myAgency == null) {
                return Center(
                  child: Text(
                    'no_agency_found'.tr(), 
                    style: const TextStyle(color: Colors.grey, fontSize: 16)
                  )
                );
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(myAgency),
                  _buildMembersTab(myAgency, controller),
                  _buildRequestsTab(myAgency, controller),
                  _buildInvitationsTab(myAgency, controller),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'invite',
              backgroundColor: AppTheme.royalGold,
              onPressed: _showInviteDialog,
              icon: const AppIcon('Icons.person_add_alt_1_rounded', icon: Icons.person_add_alt_1_rounded, color: Colors.black),
              label: Text('invite_modife'.tr(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            FloatingActionButton(
              heroTag: 'portal',
              backgroundColor: Colors.blueAccent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AgencyPortal()),
                );
              },
              child: const AppIcon('Icons.dashboard_rounded', icon: Icons.dashboard_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Agency agency) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAgencyHeader(agency),
          const SizedBox(height: 32),
          Text(
            'statistics'.tr(),
            style: TextStyle(color: AppTheme.darkBrown, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard('total_members'.tr(), '${agency.members.length}', Icons.group, Colors.blue),
              _buildStatCard('total_earnings'.tr(), '\$${agency.totalEarnings.toStringAsFixed(2)}', Icons.diamond_rounded, Colors.green),
              _buildStatCard('active_now'.tr(), '${agency.members.where((m) => m.isOnline).length}', Icons.bolt, Colors.orange),
              _buildStatCard('rating'.tr(), '${agency.rating}', Icons.star, Colors.amber),
            ],
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildMembersTab(Agency agency, AgencyController controller) {
    if (agency.members.isEmpty) {
      return Center(child: Text('no_members_yet'.tr(), style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agency.members.length,
      itemBuilder: (context, index) {
        final member = agency.members[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Text(member.name[0], style: TextStyle(color: AppTheme.darkBrown)),
            ),
            title: Text(member.name, style: TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.bold)),
            subtitle: Text('joined'.tr(args: [member.joinDate]), style: const TextStyle(fontSize: 12)),
            trailing: Text('\$${member.earnings.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab(Agency agency, AgencyController controller) {
    final requests = controller.getPendingJoinRequestsForAgency(agency.id);

    if (requests.isEmpty) {
      return Center(child: Text('no_pending_requests'.tr(), style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            title: Text(request.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ID: ${request.userId}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const AppIcon('Icons.check_circle', icon: Icons.check_circle, color: Colors.green),
                  onPressed: () => controller.respondToJoinRequest(request, true),
                ),
                IconButton(
                  icon: const AppIcon('Icons.cancel', icon: Icons.cancel, color: Colors.red),
                  onPressed: () => controller.respondToJoinRequest(request, false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvitationsTab(Agency agency, AgencyController controller) {
    final agencyInvites = controller.invitations.where((i) => i.agencyId == agency.id).toList();

    if (agencyInvites.isEmpty) {
      return Center(child: Text('no_pending_invites'.tr(), style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agencyInvites.length,
      itemBuilder: (context, index) {
        final invite = agencyInvites[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            title: Text('modife_id'.tr(args: [invite.modifeId])),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(invite.timestamp)),
            trailing: Chip(
              label: Text('pending'.tr(), style: const TextStyle(fontSize: 10, color: Colors.white)),
              backgroundColor: Colors.orange,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgencyHeader(Agency agency) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.royalGold.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppTheme.royalGold,
            child: Text(agency.name[0], style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agency.name, style: TextStyle(color: AppTheme.darkBrown, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('ID: ${agency.id}', style: TextStyle(color: AppTheme.royalGold, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(agency.description, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: AppTheme.darkBrown, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showInviteDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('invite_member'.tr(), style: TextStyle(color: AppTheme.darkBrown)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'enter_user_id'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<AgencyController>().sendInvite(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('invite_sent_success'.tr())),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold, foregroundColor: Colors.black),
            child: Text('send'.tr()),
          ),
        ],
      ),
    );
  }
}
