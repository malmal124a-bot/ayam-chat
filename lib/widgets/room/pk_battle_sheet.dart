import 'package:flutter/material.dart';
import '../app_icon.dart';

class PKBattleSheet extends StatefulWidget {
  final Function(String mode, int durationMinutes)? onStartPK;

  const PKBattleSheet({super.key, this.onStartPK});

  @override
  State<PKBattleSheet> createState() => _PKBattleSheetState();
}

class _PKBattleSheetState extends State<PKBattleSheet> {
  String selectedMode = '2v2';
  int selectedDuration = 5; // in minutes

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1B2230),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title with PK Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/icon_pk.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (context, error, stackTrace) => const AppIcon(
                      'Icons.sports_esports', icon: Icons.sports_esports,
                      color: Colors.amber,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'تحدي PK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Select Mode Section
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اختر وضع المعركة',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildModeCard('2v2', 'ضد 2 2')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildModeCard('4v4', 'ضد 4 4')),
                ],
              ),
              const SizedBox(height: 20),

              // Select Duration Section
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اختر مدة المعركة',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDurationChip(3, '3 دقائق'),
                  _buildDurationChip(5, '5 دقائق'),
                  _buildDurationChip(10, '10 دقائق'),
                ],
              ),
              const SizedBox(height: 24),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB703),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    if (widget.onStartPK != null) {
                      widget.onStartPK!(selectedMode, selectedDuration);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'بدء التحدي',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(String mode, String subtext) {
    final isSelected = selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A3447) : const Color(0xFF141923),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFB703) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              mode,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFB703) : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtext,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(int minutes, String label) {
    final isSelected = selectedDuration == minutes;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFFFB703),
      backgroundColor: const Color(0xFF141923),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) => setState(() => selectedDuration = minutes),
    );
  }
}
