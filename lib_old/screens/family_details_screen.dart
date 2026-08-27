import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/family_controller.dart';
import '../theme/app_theme.dart';
import 'family_members_screen.dart';
import 'family_tasks_screen.dart';
import 'family_store_screen.dart';
import 'family_requests_screen.dart';

class FamilyDetailsScreen extends StatefulWidget {
  const FamilyDetailsScreen({super.key});

  @override
  State<FamilyDetailsScreen> createState() => _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState extends State<FamilyDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _rulesController;

  @override
  void initState() {
    super.initState();
    final family = context.read<FamilyController>();
    _nameController = TextEditingController(text: family.familyName);
    _descController = TextEditingController(text: family.description);
    _rulesController = TextEditingController(text: family.rules);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearBlackPurple,
      appBar: AppBar(
        title: const Text('نظام العائلة', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.royalGold),
        centerTitle: true,
      ),
      body: Consumer<FamilyController>(
        builder: (context, family, child) {
          if (!family.isInFamily) {
            return _buildNoFamilyView(family);
          }

          final bool isOwner = family.role == 'Owner';
          final bool isAdmin = family.role == 'Admin' || isOwner;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFamilyHeader(family),
                const SizedBox(height: 24),
                _buildQuickAccessGrid(context, isAdmin),
                const SizedBox(height: 24),
                _buildInfoSection(family, isOwner),
                const SizedBox(height: 30),
                _buildActionButtons(family),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFamilyHeader(FamilyController family) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.nearBlackPurple, AppTheme.coffeeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: AppTheme.royalGold, shape: BoxShape.circle),
            child: const CircleAvatar(
              radius: 35,
              backgroundImage: AssetImage('assets/Asad/bg_vip_content.png'),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  family.familyName ?? 'عائلة الملوك',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppTheme.royalGold, size: 16),
                    const SizedBox(width: 5),
                    Text('مستوى ${family.familyLevel}', style: const TextStyle(color: AppTheme.royalGoldSoft, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.royalGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.5)),
            ),
            child: Text(
              family.role ?? 'عضو',
              style: const TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, bool isAdmin) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1,
      children: [
        _buildGridItem(context, Icons.people_rounded, 'الأعضاء', const FamilyMembersScreen()),
        _buildGridItem(context, Icons.task_alt_rounded, 'المهام', const FamilyTasksScreen()),
        _buildGridItem(context, Icons.storefront_rounded, 'المتجر', const FamilyStoreScreen()),
        if (isAdmin)
          _buildGridItem(context, Icons.admin_panel_settings_rounded, 'طلبات الانضمام', const FamilyRequestsScreen()),
      ],
    );
  }

  Widget _buildGridItem(BuildContext context, IconData icon, String label, Widget screen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.royalGold, size: 30),
            const SizedBox(height: 10),
            Text(
              label, 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFamilyView(FamilyController family) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: AppTheme.royalGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.group_add_rounded, size: 80, color: AppTheme.royalGold),
              ),
              const SizedBox(height: 24),
              const Text(
                'انضم لعالم العائلات',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'عزز تجربتك في الدردشة من خلال الانضمام لعائلة أو إنشاء مملكتك الخاصة',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.royalGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => family.createFamily('عائلة الملوك'),
                  child: const Text('إنشاء عائلة جديدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.royalGold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => family.joinFamily('نادي الأصدقاء'),
                  child: const Text('استكشاف العائلات', style: TextStyle(color: AppTheme.royalGold, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(FamilyController family, bool isOwner) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_rounded, color: AppTheme.royalGold, size: 20),
              const SizedBox(width: 10),
              Text(isOwner ? 'إدارة العائلة' : 'معلومات العائلة', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.royalGold)),
            ],
          ),
          const SizedBox(height: 20),
          if (isOwner) ...[
            _buildEditField(_nameController, 'اسم العائلة', (val) => family.updateFamilyDetails(name: val)),
            const SizedBox(height: 16),
            _buildEditField(_descController, 'الوصف', (val) => family.updateFamilyDetails(description: val), maxLines: 2),
            const SizedBox(height: 16),
            _buildEditField(_rulesController, 'القوانين', (val) => family.updateFamilyDetails(rules: val), maxLines: 2),
          ] else ...[
            _buildInfoRow('الوصف', family.description ?? 'لا يوجد وصف'),
            const Divider(height: 30, color: Colors.white10),
            _buildInfoRow('القوانين', family.rules ?? 'لا توجد قوانين'),
          ],
        ],
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String label, Function(String) onChanged, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.royalGold)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildActionButtons(FamilyController family) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: () {
          _confirmLeave(context, family);
        },
        icon: const Icon(Icons.exit_to_app_rounded),
        label: Text(family.role == 'Owner' ? 'حل العائلة نهائياً' : 'مغادرة العائلة', 
          style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _confirmLeave(BuildContext context, FamilyController family) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(family.role == 'Owner' ? 'حل العائلة' : 'مغادرة العائلة'),
        content: Text(family.role == 'Owner' 
          ? 'سيتم حذف العائلة نهائياً وإزالة جميع الأعضاء. هل أنت متأكد؟' 
          : 'هل تريد حقاً مغادرة هذه العائلة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('تراجع')),
          TextButton(
            onPressed: () {
              family.leaveFamily();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('تأكيد', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
