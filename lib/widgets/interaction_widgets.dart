import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showGiftSheet(BuildContext context, void Function(String giftName) onGiftSelected) {
  final theme = Theme.of(context);
  final gifts = ['وردة ملكية', 'تاج ذهبي', 'قلب مضيء', 'سيارة فاخرة', 'قلعة'];
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
              onTap: () {
                Navigator.pop(context);
                onGiftSelected(gifts[i]);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.background.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.18)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.card_giftcard, color: theme.colorScheme.secondary, size: 28),
                    const SizedBox(height: 8),
                    Text(gifts[i], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11)),
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
                          color: Colors.white.withOpacity(0.05),
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
