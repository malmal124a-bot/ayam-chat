import 'package:flutter/material.dart';

class EffectsTabWidget extends StatelessWidget {
  final Function(String type) onShowEffectPicker;

  const EffectsTabWidget({
    super.key,
    required this.onShowEffectPicker,
  });

  @override
  Widget build(BuildContext context) {
    return GridView(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      children: [
        _gridItem(Icons.login, 'تأثيرات الدخول', () => onShowEffectPicker('entry')),
        _gridItem(Icons.card_giftcard, 'تأثيرات الهدايا', () => onShowEffectPicker('gift')),
        _gridItem(Icons.door_front_door, 'تأثيرات الدخوليه', () => onShowEffectPicker('entrance')),
      ],
    );
  }

  Widget _gridItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: Colors.amber),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
