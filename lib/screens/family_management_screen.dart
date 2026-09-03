import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/family_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import 'family_requests_screen.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
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
    final family = context.watch<FamilyController>();
    
    return Scaffold(
      backgroundColor: AppTheme.nearBlackPurple,
      appBar: AppBar(
        title: Text('إدارة العائلة', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.royalGold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Settings Section
            _buildSectionHeader(Icons.settings_rounded, 'الإعدادات الأساسية'),
            const SizedBox(height: 20),
            _buildEditField(_nameController, 'اسم العائلة', (val) => family.updateFamilyDetails(name: val)),
            const SizedBox(height: 16),
            _buildEditField(_descController, 'الوصف', (val) => family.updateFamilyDetails(description: val), maxLines: 3),
            const SizedBox(height: 16),
            _buildEditField(_rulesController, 'القوانين والأنظمة', (val) => family.updateFamilyDetails(rules: val), maxLines: 3),
            
            const SizedBox(height: 40),
            
            // Actions Section
            _buildSectionHeader(Icons.admin_panel_settings_rounded, 'إجراءات الإدارة'),
            const SizedBox(height: 20),
            _buildManagementAction(
              context,
              icon: Icons.person_add_alt_1_rounded,
              title: 'طلبات الانضمام المعلقة',
              subtitle: '${family.pendingInvites.length} طلبات بانتظار الموافقة',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyRequestsScreen())),
            ),
            const SizedBox(height: 12),
            _buildManagementAction(
              context,
              icon: Icons.security_rounded,
              title: 'تعيين مشرفين',
              subtitle: 'إدارة صلاحيات الأعضاء',
              onTap: () {}, // Future implementation
            ),
            
            const SizedBox(height: 40),
            
            // Danger Zone
            const Text('منطقة الخطر', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              ),
              child: TextButton.icon(
                onPressed: () => _confirmDelete(context, family),
                icon: const AppIcon('Icons.delete_forever_rounded', icon: Icons.delete_forever_rounded, color: Colors.redAccent),
                label: const Text('حل العائلة نهائياً', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.royalGold, size: 20),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
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
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.royalGold)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildManagementAction(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.royalGold.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.royalGold.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppTheme.royalGold, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const AppIcon('Icons.arrow_forward_ios_rounded', icon: Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FamilyController family) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حل العائلة'),
        content: const Text('هل أنت متأكد من حل العائلة نهائياً؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              family.dissolveFamily();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('تأكيد الحل', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
