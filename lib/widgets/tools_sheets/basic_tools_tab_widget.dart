import 'package:flutter/material.dart';

class BasicToolsTabWidget extends StatelessWidget {
  final VoidCallback onShowTransfer;
  final VoidCallback onShowEventSheet;

  const BasicToolsTabWidget({
    super.key,
    required this.onShowTransfer,
    required this.onShowEventSheet,
  });

  @override
  Widget build(BuildContext context) {
    return GridView(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      children: [
        _gridItem(Icons.swap_horiz, 'تحويل', onShowTransfer),
        _gridItem(Icons.event, 'إنشاء الحدث', onShowEventSheet),
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
