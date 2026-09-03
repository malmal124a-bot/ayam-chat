import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'agency_payment_method_screen.dart';
import '../widgets/app_icon.dart';

class AgencyTierSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> verificationData;
  const AgencyTierSelectionScreen({super.key, required this.verificationData});

  @override
  State<AgencyTierSelectionScreen> createState() => _AgencyTierSelectionScreenState();
}

class _AgencyTierSelectionScreenState extends State<AgencyTierSelectionScreen> {
  int? _selectedTier;
  final List<int> _tiers = [500, 1000, 2000, 5000, 10000];

  void _next() {
    if (_selectedTier != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AgencyPaymentMethodScreen(
            onboardingData: {
              ...widget.verificationData,
              'selectedTier': _selectedTier,
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار فئة الوكالة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.royalPurpleDark,
      appBar: AppBar(
        title: const Text('اختيار الفئة'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'الخطوة 2: فئة الوكالة',
                style: TextStyle(color: AppTheme.royalGold, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'اختر مبلغ السيولة الذي ترغب في البدء به للعمل كوكيل شحن معتمد.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 30),
              ..._tiers.map((tier) => _buildTierCard(tier)).toList(),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.royalGold,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('التالي', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard(int amount) {
    bool isSelected = _selectedTier == amount;
    return GestureDetector(
      onTap: () => setState(() => _selectedTier = amount),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.royalGold.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? AppTheme.royalGold : Colors.white10, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'باقة $amount\$',
                    style: TextStyle(
                      color: isSelected ? AppTheme.royalGold : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'رصيد سيولة متاح للشحن الفوري', 
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected) 
              AppIcon('Icons.check_circle', icon: Icons.check_circle, color: AppTheme.royalGold, size: 28),
          ],
        ),
      ),
    );
  }
}