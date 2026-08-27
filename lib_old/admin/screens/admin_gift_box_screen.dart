import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/web_file_picker.dart';
import '../controllers/admin_auth_controller.dart';

class AdminGiftBoxScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  
  const AdminGiftBoxScreen({
    super.key,
    required this.adminAuthController,
  });

  @override
  State<AdminGiftBoxScreen> createState() => _AdminGiftBoxScreenState();
}

class _AdminGiftBoxScreenState extends State<AdminGiftBoxScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<QueryDocumentSnapshot> _gifts = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadGiftsRealTime();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadGiftsRealTime() {
    _firestore.collection('gifts').orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
      try {
        setState(() {
          _gifts = snapshot.docs;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error loading gifts: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }, onError: (error) {
      debugPrint('Gifts stream error: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _addGift({
    required String name,
    required int price,
    required String category,
    required String format,
    required String animationPath,
    required String imagePath,
    required bool isLuckGift,
    required double winProbability,
    required int expirationDays,
  }) async {
    try {
      final giftData = {
        'name': name,
        'price': price,
        'category': category,
        'format': format,
        'animationPath': animationPath,
        'imagePath': imagePath,
        'isLuckGift': isLuckGift,
        'winProbability': isLuckGift ? winProbability : null,
        'expirationDays': category == 'celebrity' ? 30 : expirationDays,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };
      
      await _firestore.collection('gifts').add(giftData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('gift_added'.tr()),
          backgroundColor: Colors.green,
        ),
      );
      // Real-time stream will auto-update
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('add_failed'.tr(namedArgs: {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteGift(String giftId) async {
    try {
      await _firestore.collection('gifts').doc(giftId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('gift_deleted'.tr()),
          backgroundColor: Colors.green,
        ),
      );
      // Real-time stream will auto-update
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('delete_failed'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddGiftDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String category = 'fixed';
    final formatController = TextEditingController();
    final animationPathController = TextEditingController();
    final imagePathController = TextEditingController();
    bool isLuckGift = false;
    double winProbability = 80.0;
    int expirationDays = 30;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('add_gift'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'gift_name'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'price'.tr(),
                    prefixText: '\$ ',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('category'.tr()),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'fixed', label: Text('Fixed')),
                    ButtonSegment(value: 'luck', label: Text('Luck')),
                    ButtonSegment(value: 'celebrity', label: Text('Celebrity')),
                    ButtonSegment(value: 'vip', label: Text('VIP')),
                    ButtonSegment(value: 'popular', label: Text('Popular')),
                  ],
                  selected: {category},
                  onSelectionChanged: (Set<String> newSelection) {
                    setDialogState(() {
                      category = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: formatController,
                  decoration: InputDecoration(
                    labelText: 'format'.tr(),
                    hintText: 'svga, mp4, json',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: animationPathController,
                        decoration: InputDecoration(
                          labelText: 'animation_path'.tr(),
                          hintText: 'assets/...',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (kIsWeb) {
                          WebFilePicker.pickFile(
                            accept: '.svga,.mp4,.json',
                            onPicked: (base64, fileName) {
                              setDialogState(() {
                                animationPathController.text = base64;
                              });
                            },
                            onError: (error) {
                              debugPrint('File picker error: $error');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('file_picker_error'.tr(namedArgs: {'error': error})),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          );
                        } else {
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['svga', 'mp4', 'json'],
                              withData: true,
                            );
                            if (result != null && result.files.single.bytes != null) {
                              final file = result.files.single;
                              // Encode to Base64 and save directly to Firestore
                              final base64Data = 'data:${file.extension ?? 'application/octet-stream'};base64,${base64Encode(file.bytes!)}';
                              setDialogState(() {
                                animationPathController.text = base64Data;
                              });
                            }
                          } catch (e) {
                            debugPrint('File picker error: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('file_picker_error'.tr(namedArgs: {'error': e.toString()})),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.folder_open),
                      label: Text('browse'.tr()),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imagePathController,
                        decoration: InputDecoration(
                          labelText: 'image_path'.tr(),
                          hintText: 'assets/...',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (kIsWeb) {
                          WebFilePicker.pickFile(
                            accept: 'image/*',
                            onPicked: (base64, fileName) {
                              setDialogState(() {
                                imagePathController.text = base64;
                              });
                            },
                            onError: (error) {
                              debugPrint('File picker error: $error');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('file_picker_error'.tr(namedArgs: {'error': error})),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          );
                        } else {
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['png', 'jpg', 'jpeg'],
                              withData: true,
                            );
                            if (result != null && result.files.single.bytes != null) {
                              final file = result.files.single;
                              // Encode to Base64 and save directly to Firestore
                              final base64Data = 'data:image/${file.extension ?? 'png'};base64,${base64Encode(file.bytes!)}';
                              setDialogState(() {
                                imagePathController.text = base64Data;
                              });
                            }
                          } catch (e) {
                            debugPrint('File picker error: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('file_picker_error'.tr(namedArgs: {'error': e.toString()})),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.folder_open),
                      label: Text('browse'.tr()),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (category == 'luck') ...[
                  Text('win_probability'.tr()),
                  Slider(
                    value: winProbability,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${winProbability.toStringAsFixed(0)}%',
                    onChanged: (value) {
                      setDialogState(() {
                        winProbability = value;
                      });
                    },
                  ),
                  Text('${winProbability.toStringAsFixed(0)}%'),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: TextEditingController(text: expirationDays.toString()),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'expiration_days'.tr(),
                    suffixText: 'days',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    expirationDays = int.tryParse(value) ?? 30;
                  },
                ),
                if (category == 'celebrity') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'celebrity_gift_auto_expire'.tr(),
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.isNotEmpty &&
                          priceController.text.isNotEmpty &&
                          formatController.text.isNotEmpty &&
                          animationPathController.text.isNotEmpty &&
                          imagePathController.text.isNotEmpty) {
                        setDialogState(() {
                          isSaving = true;
                        });
                        await _addGift(
                          name: nameController.text,
                          price: int.tryParse(priceController.text) ?? 0,
                          category: category,
                          format: formatController.text,
                          animationPath: animationPathController.text,
                          imagePath: imagePathController.text,
                          isLuckGift: isLuckGift,
                          winProbability: winProbability,
                          expirationDays: expirationDays,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('add'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('gift_box_management'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue.shade900,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue.shade900,
                isScrollable: true,
                tabs: [
                  Tab(text: 'fixed_gifts'.tr()),
                  Tab(text: 'luck_gifts'.tr()),
                  Tab(text: 'celebrity_gifts'.tr()),
                  Tab(text: 'vip_gifts'.tr()),
                  Tab(text: 'popular_gifts'.tr()),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGiftsTab('fixed'),
                  _buildGiftsTab('luck'),
                  _buildGiftsTab('celebrity'),
                  _buildGiftsTab('vip'),
                  _buildGiftsTab('popular'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGiftDialog,
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGiftsTab(String categoryFilter) {
    final filteredGifts = _gifts.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category'] as String? ?? '';
      return category == categoryFilter;
    }).toList();

    // Hardcoded fallback data
    final fallbackGifts = _getHardcodedGifts(categoryFilter);
    final displayGifts = filteredGifts.isEmpty ? fallbackGifts : filteredGifts;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getCategoryTitle(categoryFilter),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayGifts.length,
                  itemBuilder: (context, index) {
                    final isFallback = filteredGifts.isEmpty;
                    final data = isFallback 
                        ? displayGifts[index] as Map<String, dynamic>
                        : (displayGifts[index] as QueryDocumentSnapshot).data() as Map<String, dynamic>;
                    final docId = isFallback ? 'fallback_$index' : (displayGifts[index] as QueryDocumentSnapshot).id;
                    
                    final name = data['name'] as String? ?? 'Unknown';
                    final price = (data['price'] as num?)?.toInt() ?? 0;
                    final category = data['category'] as String? ?? categoryFilter;
                    final format = data['format'] as String? ?? '';
                    final imagePath = data['imagePath'] as String? ?? data['image_path'] as String? ?? '';
                    final isLuckGift = data['isLuckGift'] as bool? ?? data['isLuck'] as bool? ?? false;
                    final winProbability = (data['winProbability'] as num?)?.toDouble() ?? (data['winRate'] as num?)?.toDouble() ?? 0.0;
                    final expirationDays = data['expirationDays'] as int? ?? 30;
                    final isActive = data['isActive'] as bool? ?? true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Thumbnail (40x40px)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: imagePath.startsWith('assets/')
                                    ? Image.asset(
                                        imagePath,
                                        fit: BoxFit.cover,
                                        width: 40,
                                        height: 40,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Icon(
                                              _getGiftFallbackIconData(category),
                                              size: 20,
                                              color: Colors.grey.shade400,
                                            ),
                                          );
                                        },
                                      )
                                    : imagePath.startsWith('http')
                                        ? Image.network(
                                            imagePath,
                                            fit: BoxFit.cover,
                                            width: 40,
                                            height: 40,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Icon(
                                                  _getGiftFallbackIconData(category),
                                                  size: 20,
                                                  color: Colors.grey.shade400,
                                                ),
                                              );
                                            },
                                          )
                                        : imagePath.startsWith('data:image')
                                            ? Image.memory(
                                                base64Decode(imagePath.split(',')[1]),
                                                fit: BoxFit.cover,
                                                width: 40,
                                                height: 40,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Center(
                                                    child: Icon(
                                                      _getGiftFallbackIconData(category),
                                                      size: 20,
                                                      color: Colors.grey.shade400,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Center(
                                                child: Icon(
                                                  _getGiftFallbackIconData(category),
                                                  size: 20,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Item Name
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getGiftCategoryColor(category),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getGiftCategoryLabel(category),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Duration Tag
                            SizedBox(
                              width: 80,
                              child: Text(
                                category == 'celebrity' 
                                    ? '30 يوم' 
                                    : expirationDays == 0 
                                        ? 'دائم' 
                                        : '${expirationDays} يوم',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Price
                            SizedBox(
                              width: 60,
                              child: Text(
                                '\$$price',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Specific Attributes
                            SizedBox(
                              width: 80,
                              child: isLuckGift
                                  ? Text(
                                      '${winProbability.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : Text(
                                      format.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            // Active Status Toggle
                            SizedBox(
                              width: 60,
                              child: Switch(
                                value: isActive ?? true,
                                onChanged: (value) async {
                                  await _firestore.collection('gifts').doc(docId).update({
                                    'isActive': value,
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Actions
                            if (!isFallback) ...[
                              ElevatedButton.icon(
                                onPressed: () => _showEditGiftDialog(docId, data),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('تعديل'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _deleteGift(docId),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('مسح'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _getGiftFallbackIconData(String category) {
    switch (category) {
      case 'luck':
        return Icons.casino;
      case 'celebrity':
        return Icons.star;
      case 'vip':
      case 'svip':
        return Icons.workspace_premium;
      case 'popular':
        return Icons.favorite;
      default:
        return Icons.card_giftcard;
    }
  }

  Widget _buildGiftFallbackIcon(String category) {
    return Center(
      child: Icon(_getGiftFallbackIconData(category), size: 48, color: Colors.grey.shade400),
    );
  }

  Color _getGiftCategoryColor(String category) {
    switch (category) {
      case 'luck':
        return Colors.orange;
      case 'celebrity':
        return Colors.purple;
      case 'vip':
      case 'svip':
        return Colors.amber;
      case 'popular':
        return Colors.pink;
      default:
        return Colors.blue;
    }
  }

  String _getGiftCategoryLabel(String category) {
    switch (category) {
      case 'luck':
        return 'حظ';
      case 'celebrity':
        return 'مشاهير';
      case 'vip':
        return 'VIP';
      case 'svip':
        return 'SVIP';
      case 'popular':
        return 'شائع';
      case 'fixed':
        return 'ثابت';
      default:
        return category.toUpperCase();
    }
  }

  String _getCategoryTitle(String categoryFilter) {
    switch (categoryFilter) {
      case 'fixed':
        return 'هدايا ثابتة';
      case 'luck':
        return 'هدايا الحظ';
      case 'celebrity':
        return 'هدايا المشاهير';
      case 'vip':
        return 'هدايا VIP';
      case 'popular':
        return 'الهدايا الشائعة';
      default:
        return categoryFilter.toUpperCase();
    }
  }

  List<Map<String, dynamic>> _getHardcodedGifts(String categoryFilter) {
    switch (categoryFilter) {
      case 'fixed':
      case 'popular':
        return [
          {
            'name': 'وردة حمراء',
            'price': 10,
            'category': categoryFilter,
            'format': 'png',
            'imagePath': 'assets/gifts/rose.png',
            'isLuck': false,
            'winProbability': 0,
            'expirationDays': 0,
            'isActive': true,
          },
          {
            'name': 'قلوب',
            'price': 50,
            'category': categoryFilter,
            'format': 'svga',
            'imagePath': 'assets/gifts/hearts.svga',
            'isLuck': false,
            'winProbability': 0,
            'expirationDays': 0,
            'isActive': true,
          },
        ];
      case 'luck':
        return [
          {
            'name': 'صندوق الحظ الذهبي',
            'price': 100,
            'category': 'luck',
            'format': 'json',
            'imagePath': 'assets/gifts/luck_box.png',
            'isLuck': true,
            'winProbability': 80,
            'expirationDays': 0,
            'isActive': true,
          },
          {
            'name': 'صندوق الحظ الفضي',
            'price': 50,
            'category': 'luck',
            'format': 'json',
            'imagePath': 'assets/gifts/luck_box_silver.png',
            'isLuck': true,
            'winProbability': 60,
            'expirationDays': 0,
            'isActive': true,
          },
        ];
      case 'celebrity':
        return [
          {
            'name': 'تاج المشاهير',
            'price': 2500,
            'category': 'celebrity',
            'format': 'mp4',
            'imagePath': 'assets/gifts/celeb_star.png',
            'isLuck': false,
            'winProbability': 0,
            'expirationDays': 30,
            'isActive': true,
          },
        ];
      case 'vip':
      case 'svip':
        return [
          {
            'name': 'سيارة فيراري VIP',
            'price': 5000,
            'category': categoryFilter,
            'format': 'svga',
            'imagePath': 'assets/gifts/car.png',
            'isLuck': false,
            'winProbability': 0,
            'expirationDays': 0,
            'isActive': true,
          },
          {
            'name': 'يخت VIP',
            'price': 10000,
            'category': categoryFilter,
            'format': 'svga',
            'imagePath': 'assets/gifts/yacht.svga',
            'isLuck': false,
            'winProbability': 0,
            'expirationDays': 0,
            'isActive': true,
          },
        ];
      default:
        return [];
    }
  }

  void _showEditPriceDialog(String giftId, double currentPrice) {
    final priceController = TextEditingController(text: currentPrice.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('edit_price'.tr()),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'price'.tr(),
            prefixText: '\$ ',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(priceController.text) ?? currentPrice;
              _editGiftPrice(giftId, newPrice.toInt());
              Navigator.pop(context);
            },
            child: Text('update'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _editGiftPrice(String giftId, int newPrice) async {
    try {
      await _firestore.collection('gifts').doc(giftId).update({
        'price': newPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('price_updated'.tr()),
          backgroundColor: Colors.green,
        ),
      );
      // Real-time stream will auto-update
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('update_failed'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditGiftDialog(String giftId, Map<String, dynamic> currentData) {
    final nameController = TextEditingController(text: currentData['name']?.toString() ?? '');
    final priceController = TextEditingController(text: currentData['price']?.toString() ?? '');
    String category = currentData['category']?.toString() ?? 'fixed';
    final formatController = TextEditingController(text: currentData['format']?.toString() ?? '');
    final animationPathController = TextEditingController(text: currentData['animationPath']?.toString() ?? '');
    final imagePathController = TextEditingController(text: currentData['imagePath']?.toString() ?? '');
    bool isLuckGift = currentData['isLuckGift'] == true;
    double winProbability = (currentData['winProbability'] as num?)?.toDouble() ?? 80.0;
    int expirationDays = (currentData['expirationDays'] as num?)?.toInt() ?? 30;
    bool isActive = currentData['isActive'] == true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('edit_gift'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'gift_name'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'price'.tr(),
                    prefixText: '\$ ',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('category'.tr()),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'fixed', label: Text('Fixed')),
                    ButtonSegment(value: 'luck', label: Text('Luck')),
                    ButtonSegment(value: 'celebrity', label: Text('Celebrity')),
                    ButtonSegment(value: 'vip', label: Text('VIP')),
                    ButtonSegment(value: 'popular', label: Text('Popular')),
                  ],
                  selected: {category},
                  onSelectionChanged: (Set<String> newSelection) {
                    setDialogState(() {
                      category = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: formatController,
                  decoration: InputDecoration(
                    labelText: 'format'.tr(),
                    hintText: 'svga, mp4, json',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: animationPathController,
                        decoration: InputDecoration(
                          labelText: 'animation_path'.tr(),
                          hintText: 'assets/...',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (kIsWeb) {
                          WebFilePicker.pickFile(
                            accept: '.svga,.mp4,.json',
                            onPicked: (base64, fileName) {
                              setDialogState(() {
                                animationPathController.text = base64;
                              });
                            },
                            onError: (error) {
                              debugPrint('File picker error: $error');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('file_picker_error'.tr(namedArgs: {'error': error})),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          );
                        } else {
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['svga', 'mp4', 'json'],
                              withData: true,
                            );
                            if (result != null && result.files.single.bytes != null) {
                              final base64 = base64Encode(result.files.single.bytes!);
                              setDialogState(() {
                                animationPathController.text = base64;
                              });
                            }
                          } catch (e) {
                            debugPrint('File picker error: $e');
                          }
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imagePathController,
                        decoration: InputDecoration(
                          labelText: 'image_path'.tr(),
                          hintText: 'assets/...',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (kIsWeb) {
                          WebFilePicker.pickFile(
                            accept: 'image/*',
                            onPicked: (base64, fileName) {
                              setDialogState(() {
                                imagePathController.text = base64;
                              });
                            },
                            onError: (error) {
                              debugPrint('File picker error: $error');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('file_picker_error'.tr(namedArgs: {'error': error})),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          );
                        } else {
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              withData: true,
                            );
                            if (result != null && result.files.single.bytes != null) {
                              final base64 = base64Encode(result.files.single.bytes!);
                              setDialogState(() {
                                imagePathController.text = base64;
                              });
                            }
                          } catch (e) {
                            debugPrint('File picker error: $e');
                          }
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('is_luck_gift'.tr()),
                  value: isLuckGift,
                  onChanged: (value) {
                    setDialogState(() {
                      isLuckGift = value;
                    });
                  },
                ),
                if (isLuckGift) ...[
                  const SizedBox(height: 16),
                  Text('win_probability'.tr()),
                  Slider(
                    value: winProbability,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${winProbability.toStringAsFixed(0)}%',
                    onChanged: (value) {
                      setDialogState(() {
                        winProbability = value;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'expiration_days'.tr(),
                    suffixText: 'days',
                    border: const OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: expirationDays.toString()),
                  onChanged: (value) {
                    expirationDays = int.tryParse(value) ?? 30;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('is_active'.tr()),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() {
                      isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() {
                        isSaving = true;
                      });

                      try {
                        final giftData = {
                          'name': nameController.text,
                          'price': int.tryParse(priceController.text) ?? 0,
                          'category': category,
                          'format': formatController.text,
                          'animationPath': animationPathController.text,
                          'imagePath': imagePathController.text,
                          'isLuckGift': isLuckGift,
                          'winProbability': isLuckGift ? winProbability : null,
                          'expirationDays': category == 'celebrity' ? 30 : expirationDays,
                          'isActive': isActive,
                          'updatedAt': FieldValue.serverTimestamp(),
                        };

                        await _firestore.collection('gifts').doc(giftId).update(giftData);
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('gift_updated'.tr()),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Real-time stream will auto-update
                      } catch (e) {
                        setDialogState(() {
                          isSaving = false;
                        });
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('update_failed'.tr(namedArgs: {'error': e.toString()})),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('update'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
