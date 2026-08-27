import 'package:flutter/material.dart';
import '../controllers/admin_controller.dart';
import '../controllers/wallet_controller.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AdminController adminController = AdminController();
  final WalletController walletController = WalletController();

  final TextEditingController _balanceController = TextEditingController();
  
  final TextEditingController _entryNameController = TextEditingController();
  final TextEditingController _entryPathController = TextEditingController();
  final TextEditingController _entryPriceController = TextEditingController();

  final TextEditingController _idValueController = TextEditingController();
  final TextEditingController _idPriceController = TextEditingController();

  @override
  void dispose() {
    _balanceController.dispose();
    _entryNameController.dispose();
    _entryPathController.dispose();
    _entryPriceController.dispose();
    _idValueController.dispose();
    _idPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('لوحة الإدارة (Admin)', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
        backgroundColor: theme.cardColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('إدارة المحفظة (شحن ماسات)', theme),
            _buildCard([
              _buildTextField(_balanceController, 'المبلغ (USD)', theme, TextInputType.number),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(_balanceController.text);
                  if (amount != null) {
                    adminController.adjustBalance(amount);
                    _balanceController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إضافة \$ $amount بنجاح')));
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary),
                child: Text('شحن الرصيد', style: TextStyle(color: theme.colorScheme.onSecondary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Center(child: Text('الرصيد الحالي: ${walletController.diamonds} ماسة', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)))),
            ], theme),
            
            const SizedBox(height: 32),
            _buildSectionTitle('إضافة دخوليات جديدة (Entry Effects)', theme),
            _buildCard([
              _buildTextField(_entryNameController, 'اسم الدخولية', theme),
              const SizedBox(height: 12),
              _buildTextField(_entryPathController, 'مسار الملف (asset path)', theme),
              const SizedBox(height: 12),
              _buildTextField(_entryPriceController, 'السعر (ماسات)', theme, TextInputType.number),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final name = _entryNameController.text;
                  final path = _entryPathController.text;
                  final price = double.tryParse(_entryPriceController.text);
                  if (name.isNotEmpty && path.isNotEmpty && price != null) {
                    adminController.addEntryEffect(name: name, assetPath: path, price: price);
                    _entryNameController.clear();
                    _entryPathController.clear();
                    _entryPriceController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الدخولية للمتجر')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.tertiaryContainer),
                child: Text('إضافة للمتجر', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
              ),
            ], theme),

            const SizedBox(height: 32),
            _buildSectionTitle('إضافة آي دي مميز (Premium IDs)', theme),
            _buildCard([
              _buildTextField(_idValueController, 'الآي دي (مثلاً: 5555)', theme),
              const SizedBox(height: 12),
              _buildTextField(_idPriceController, 'السعر (ماسات)', theme, TextInputType.number),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final fancyId = _idValueController.text;
                  final price = double.tryParse(_idPriceController.text);
                  if (fancyId.isNotEmpty && price != null) {
                    adminController.addPremiumId(fancyId: fancyId, price: price);
                    _idValueController.clear();
                    _idPriceController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الآي دي للمتجر')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primaryContainer),
                child: Text('إضافة للمتجر', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
              ),
            ], theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(title, style: TextStyle(color: theme.colorScheme.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCard(List<Widget> children, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, ThemeData theme, [TextInputType type = TextInputType.text]) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
        filled: true,
        fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
