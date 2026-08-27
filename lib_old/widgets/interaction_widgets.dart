import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/gift_controller.dart';
import '../controllers/wallet_controller.dart';

Future<void> showGiftSheet(BuildContext context, void Function(String giftName) onGiftSelected) async {
  final theme = Theme.of(context);
  final giftController = context.read<GiftController>();
  final walletController = context.read<WalletController>();

  // Load gifts from Firestore via GiftController
  final gifts = await giftController.getAvailableGifts();

  if (!context.mounted) return;

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('إرسال هدية', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gifts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () async {
                final gift = gifts[i];
                final giftName = gift['name'] as String;
                final giftPrice = gift['price'] as int? ?? 0;
                
                // Check if user has enough diamonds
                if (walletController.diamonds.value >= giftPrice) {
                  // Deduct diamonds from wallet
                  await walletController.deductDiamonds(giftPrice);

                  if (context.mounted) {
                    Navigator.pop(context);
                    onGiftSelected(giftName);
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ليس لديك الماس الكافي')),
                    );
                  }
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.18)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.card_giftcard, color: theme.colorScheme.secondary, size: 28),
                    const SizedBox(height: 8),
                    Text(gifts[i]['name'] as String? ?? 'هدية', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('${gifts[i]['price'] ?? 0} 💎', style: const TextStyle(color: Colors.amber, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class QuickEmojiBar extends StatelessWidget {
  final void Function(String emoji) onTapEmoji;
  const QuickEmojiBar({super.key, required this.onTapEmoji});

  Future<List<String>> _loadEmojiGifs() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      return manifestMap.keys
          .where((String key) => key.startsWith('assets/emojis/') && key.endsWith('.gif'))
          .toList();
    } catch (e) {
      debugPrint('Error loading emoji gifs: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const Text(
            'تفاعلات المايك (GIF)',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _loadEmojiGifs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.amber));
                }
                
                final emojis = snapshot.data ?? [];
                
                if (emojis.isEmpty) {
                  return const Center(
                    child: Text('لا توجد إيموجي متحركة حالياً', style: TextStyle(color: Colors.white54)),
                  );
                }

                return GridView.builder(
                  itemCount: emojis.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    final assetPath = emojis[index];
                    return InkWell(
                      onTap: () => onTapEmoji(assetPath),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Image.asset(assetPath, fit: BoxFit.contain),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
