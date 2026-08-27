import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ayam_chat/controllers/family_controller.dart';
import 'package:ayam_chat/controllers/user_controller.dart';
import 'package:ayam_chat/services/cloudinary_service.dart';
import 'package:ayam_chat/screens/family_members_screen.dart';
import 'package:ayam_chat/screens/family_management_screen.dart';

class FamilyDetailsScreen extends StatefulWidget {
  const FamilyDetailsScreen({super.key});

  @override
  State<FamilyDetailsScreen> createState() => _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState extends State<FamilyDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyController>().loadMyFamily();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyController>(
      builder: (context, family, _) {
        if (!family.isInFamily) {
          return _buildNoFamilyView(context, family);
        }
        return _buildFamilyView(context, family);
      },
    );
  }

  Widget _buildNoFamilyView(BuildContext context, FamilyController family) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('العائلات', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.family_restroom_rounded, size: 80, color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
              const SizedBox(height: 24),
              Text('انضم لعالم العائلات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
              const SizedBox(height: 12),
              Text('أنشئ عائلتك أو انضم لعائلة موجودة', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateFamilyDialog(context),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text('إنشاء عائلة (${FamilyController.createCost} ماسة)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
              const SizedBox(height: 16),
              Text('المستوى المطلوب: ${FamilyController.minLevelToCreate}+  |  الرصيد: ${UserController().diamonds} ماسة', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyView(BuildContext context, FamilyController family) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(family.familyName ?? 'عائلتي', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (family.isOwner)
            IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyManagementScreen())), icon: const Icon(Icons.settings)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildFamilyHeader(context, family, theme),
            const SizedBox(height: 20),
            _buildQuickActions(context, family, theme),
            const SizedBox(height: 20),
            _buildFamilyInfo(context, family, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyHeader(BuildContext context, FamilyController family, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: family.isOwner ? () => _pickFamilyImage(context) : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white24,
                  backgroundImage: family.imageUrl != null && family.imageUrl!.isNotEmpty ? NetworkImage(family.imageUrl!) : null,
                  child: family.imageUrl == null || family.imageUrl!.isEmpty ? const Icon(Icons.family_restroom, color: Colors.white, size: 40) : null,
                ),
                if (family.isOwner)
                  Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Icon(Icons.camera_alt, size: 16, color: theme.colorScheme.primary))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(family.familyName ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('كود: ${family.familyCode ?? ''}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('المستوى', '${family.familyLevel}', Icons.star, Colors.amber),
              _buildStat('الأعضاء', '${family.memberCount}', Icons.people, Colors.greenAccent),
              _buildStat('الماس', '${family.familyDiamonds}', Icons.diamond, Colors.blueAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, FamilyController family, ThemeData theme) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12,
      children: [
        _buildActionCard('الأعضاء', Icons.people, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyMembersScreen())), theme),
        if (family.isAdmin)
          _buildActionCard('الدعوة', Icons.person_add, () => _showInviteDialog(context), theme),
        if (family.isOwner)
          _buildActionCard('الإدارة', Icons.admin_panel_settings, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyManagementScreen())), theme),
        _buildActionCard('المتجر', Icons.store, () {}, theme),
        _buildActionCard('المهام', Icons.task_alt, () {}, theme),
        _buildActionCard('المغادرة', Icons.exit_to_app, () => _confirmLeave(context), theme),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, VoidCallback onTap, ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.15))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildFamilyInfo(BuildContext context, FamilyController family, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('معلومات العائلة', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInfoRow('المالك', family.ownerName, theme),
          _buildInfoRow('الكود', family.familyCode ?? '-', theme),
          _buildInfoRow('الوصف', family.description?.isNotEmpty == true ? family.description! : 'لم يُحدد بعد', theme),
          const SizedBox(height: 16),
          if (family.isOwner)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmDissolve(context),
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('حل العائلة نهائياً', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label: ', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: TextStyle(color: theme.colorScheme.onSurface))),
      ]),
    );
  }

  void _showCreateFamilyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('إنشاء عائلة جديدة', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('سيتم خصم ${FamilyController.createCost} ماسة من رصيدك', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'اسم العائلة',
                filled: true, fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final success = await context.read<FamilyController>().createFamily(nameController.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'تم إنشاء العائلة بنجاح!' : 'فشل الإنشاء (تأكد من المستوى والرصيد)')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, foregroundColor: Colors.white),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final uidController = TextEditingController();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('دعوة عضو', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: uidController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'أدخل الرقم التعريفي (6 أرقام)',
            filled: true, fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final targetId = uidController.text.trim();
              if (targetId.length != 6) return;
              Navigator.pop(ctx);
              final success = await context.read<FamilyController>().inviteUser(targetId, targetId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'تم إرسال الدعوة!' : 'فشل إرسال الدعوة')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, foregroundColor: Colors.white),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _pickFamilyImage(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 300, maxHeight: 300);
    if (image != null) {
      final url = await CloudinaryService.uploadImage(image, folder: 'families');
      if (context.mounted) {
        await context.read<FamilyController>().updateFamilyDetails(imageUrl: url);
      }
    }
  }

  void _confirmLeave(BuildContext context) {
    final family = context.read<FamilyController>();
    if (family.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المالك لا يمكنه المغادرة، قم بحل العائلة')));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مغادرة العائلة'),
        content: const Text('هل أنت متأكد من مغادرة العائلة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); family.leaveFamily(); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );
  }

  void _confirmDissolve(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حل العائلة', style: TextStyle(color: Colors.red)),
        content: const Text('سيتم حذف العائلة وجميع بياناتها نهائياً. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); context.read<FamilyController>().dissolveFamily(); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('حل نهائياً'),
          ),
        ],
      ),
    );
  }
}
