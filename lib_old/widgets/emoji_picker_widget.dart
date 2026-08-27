import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmojiPickerWidget extends StatelessWidget {
  final Function(String assetPath) onEmojiSelected;

  const EmojiPickerWidget({super.key, required this.onEmojiSelected});

  /// Loads all GIF emoji assets from the 'assets/emojis/' directory dynamically.
  Future<List<String>> _loadGifEmojis() async {
    try {
      final String manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Filter for GIFs located under 'assets/emojis/'.
      final List<String> emojis = manifestMap.keys
          .where((String key) => 
            key.startsWith('assets/emojis/') && 
            key.toLowerCase().endsWith('.gif'))
          .toList();
          
      return emojis;
    } catch (e) {
      debugPrint('Error loading GIF emojis: $e');
      // Fallback list using actual existing files found in assets/emojis/
      return [
        'assets/emojis/[crown-angry]@2x.gif',
        'assets/emojis/[crown-cool]@2x.gif',
        'assets/emojis/[crown-cry]@2x.gif',
        'assets/emojis/[crown-dese]@2x.gif',
        'assets/emojis/[crown-drink]@2x.gif',
        'assets/emojis/[crown-fugui]@2x.gif',
        'assets/emojis/[crown-happy]@2x.gif',
        'assets/emojis/[crown-helpless]@2x.gif',
        'assets/emojis/[crown-jqyk]@2x.gif',
        'assets/emojis/[crown-kiss]@2x.gif',
        'assets/emojis/[crown-kissmua]@2x.gif',
        'assets/emojis/[crown-kuxiao]@2x.gif',
        'assets/emojis/[crown-shuiyan]@2x.gif',
        'assets/emojis/[crown-smile]@2x.gif',
        'assets/emojis/[crown-smoke]@2x.gif',
        'assets/emojis/[crown-weiqu]@2x.gif',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "تفاعلات المايك المتحركة",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _loadGifEmojis(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.amber));
                }
                
                final emojis = snapshot.data ?? [];
                
                if (emojis.isEmpty) {
                  return const Center(
                    child: Text(
                      "لا توجد تفاعلات متاحة حالياً",
                      style: TextStyle(color: Colors.white54, fontFamily: 'Cairo'),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: emojis.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    final String assetPath = emojis[index];
                    return InkWell(
                      onTap: () {
                        onEmojiSelected(assetPath);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.face_retouching_natural, color: Colors.white24),
                        ),
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
