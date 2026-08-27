import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/family_controller.dart';
import '../theme/app_theme.dart';
import '../helpers/image_helper.dart';

class FamilyStoreScreen extends StatelessWidget {
  const FamilyStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final family = context.watch<FamilyController>();

    return Scaffold(
      backgroundColor: AppTheme.nearBlackPurple,
      appBar: AppBar(
        title: const Text('متجر العائلة', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.royalGold),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.diamond_rounded, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 4),
                Text('${family.familyDiamonds}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: family.storeItems.length,
        itemBuilder: (context, index) {
          final item = family.storeItems[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ImageHelper.buildSafeImage(
                      imagePath: item.image,
                      fit: BoxFit.contain,
                      errorWidget: Container(
                        color: Colors.white.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.store,
                          color: AppTheme.royalGold,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showPurchaseConfirm(context, item);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.royalGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text('${item.price} ماسة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPurchaseConfirm(BuildContext context, FamilyStoreItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.nearBlackPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.royalGold, width: 0.5)),
        title: const Text('تأكيد الشراء', style: TextStyle(color: AppTheme.royalGold)),
        content: Text('هل ترغب في شراء ${item.name} مقابل ${item.price} ماسة عائلية؟', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم شراء ${item.name} بنجاح!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('شراء', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
