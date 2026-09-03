import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/agency_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class JoinAgencyScreen extends StatefulWidget {
  const JoinAgencyScreen({super.key});

  @override
  State<JoinAgencyScreen> createState() => _JoinAgencyScreenState();
}

class _JoinAgencyScreenState extends State<JoinAgencyScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final code = _codeController.text.trim();
    if (code.length == 4) {
      context.read<AgencyController>().searchAgencyByCode(code);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال كود مكون من 4 أرقام')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final agencyController = context.watch<AgencyController>();
    final searchedAgency = agencyController.searchedAgency;

    return Scaffold(
      backgroundColor: Colors.white, // خلفية بيضاء لضمان الرؤية
      appBar: AppBar(
        title: Text('الانضمام لوكالة موديفين', style: TextStyle(color: AppTheme.darkBrown, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.darkBrown),
      ),
      body: Material(
        color: Colors.white,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ابحث عن وكيلك',
                style: TextStyle(color: AppTheme.darkBrown, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'أدخل كود الوكالة المكون من 4 أرقام للانضمام إلى فريق العمل',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: TextStyle(color: AppTheme.darkBrown, fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0000',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.3)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: agencyController.isLoading ? null : _onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.royalGold,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: agencyController.isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('بحث عن الوكالة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
              if (searchedAgency != null) ...[
                _buildAgencyResultCard(searchedAgency, agencyController),
              ] else if (_codeController.text.isNotEmpty && !agencyController.isLoading) ...[
                const Center(
                  child: Text('لم يتم العثور على وكالة بهذا الكود', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ],
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgencyResultCard(dynamic searchedAgency, AgencyController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.royalGold.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.royalGold,
            child: AppIcon('Icons.business_rounded', icon: Icons.business_rounded, size: 40, color: Colors.black),
          ),
          const SizedBox(height: 15),
          Text(
            searchedAgency.name,
            style: TextStyle(color: AppTheme.darkBrown, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'ID: ${searchedAgency.id}',
            style: TextStyle(color: AppTheme.royalGold, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            searchedAgency.description,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () async {
              await controller.requestToJoinAgency(searchedAgency.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال طلب الانضمام بنجاح')),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('إرسال طلب انضمام', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}