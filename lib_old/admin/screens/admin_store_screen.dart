import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/web_file_picker.dart';
import '../controllers/admin_auth_controller.dart';

class AdminStoreScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  final int initialTab;
  
  const AdminStoreScreen({
    super.key,
    required this.adminAuthController,
    this.initialTab = 0,
  });

  @override
  State<AdminStoreScreen> createState() => _AdminStoreScreenState();
}

class _AdminStoreScreenState extends State<AdminStoreScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<QueryDocumentSnapshot> _storeItems = [];
  List<QueryDocumentSnapshot> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreItemsRealTime();
    _loadBannersRealTime();
  }

  void _loadStoreItemsRealTime() {
    _firestore.collection('store_items').orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
      try {
        setState(() {
          _storeItems = snapshot.docs;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error loading store items: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }, onError: (error) {
      debugPrint('Stream error: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _loadBannersRealTime() {
    _firestore.collection('banners').orderBy('order').snapshots().listen((snapshot) {
      try {
        setState(() {
          _banners = snapshot.docs;
        });
      } catch (e) {
        debugPrint('Error loading banners: $e');
      }
    }, onError: (error) {
      debugPrint('Banners stream error: $error');
    });
  }

  Future<void> _addStoreItem({
    required String name,
    required String type,
    required double price,
    required String imagePath,
    required int expirationDays,
  }) async {
    try {
      final itemData = {
        'name': name,
        'type': type,
        'price': price,
        'imagePath': imagePath,
        'expirationDays': expirationDays,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };
      
      await _firestore.collection('store_items').add(itemData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('item_added'.tr()),
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

  Future<void> _deleteStoreItem(String itemId) async {
    try {
      await _firestore.collection('store_items').doc(itemId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('item_deleted'.tr()),
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

  Future<void> _editItemPrice(String itemId, double newPrice) async {
    try {
      await _firestore.collection('store_items').doc(itemId).update({
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

  Future<void> _addBanner(String imageUrl, String targetUrl) async {
    try {
      await _firestore.collection('banners').add({
        'imageUrl': imageUrl,
        'targetUrl': targetUrl,
        'isActive': true,
        'order': _banners.length,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('banner_added'.tr()),
          backgroundColor: Colors.green,
        ),
      );
      // Real-time stream will auto-update
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('add_banner_failed'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBanner(String bannerId) async {
    try {
      await _firestore.collection('banners').doc(bannerId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('banner_deleted'.tr()),
          backgroundColor: Colors.green,
        ),
      );
      // Real-time stream will auto-update
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('delete_banner_failed'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddItemDialog(String itemType) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final imageController = TextEditingController();
    final expirationDaysController = TextEditingController(text: '30');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('add_item'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'item_name'.tr(),
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
                TextField(
                  controller: expirationDaysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'expiration_duration'.tr(),
                    suffixText: 'days',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imageController,
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
                            accept: 'image/*,.svga,.json,.gif',
                            onPicked: (base64, fileName) {
                              setDialogState(() {
                                imageController.text = base64;
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
                              allowedExtensions: ['svga', 'mp4', 'svg', 'png', 'jpg', 'jpeg'],
                              withData: true,
                            );
                            if (result != null && result.files.single.bytes != null) {
                              final file = result.files.single;
                              // Encode to Base64 and save directly to Firestore
                              final base64Data = 'data:image/${file.extension ?? 'png'};base64,${base64Encode(file.bytes!)}';
                              setDialogState(() {
                                imageController.text = base64Data;
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
                          imageController.text.isNotEmpty) {
                        setDialogState(() {
                          isSaving = true;
                        });
                        await _addStoreItem(
                          name: nameController.text,
                          type: itemType,
                          price: double.tryParse(priceController.text) ?? 0.0,
                          imagePath: imageController.text,
                          expirationDays: int.tryParse(expirationDaysController.text) ?? 30,
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

  void _showAddBannerDialog() {
    final imageUrlController = TextEditingController();
    final targetUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('add_banner'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: imageUrlController,
              decoration: InputDecoration(
                labelText: 'image_url'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetUrlController,
              decoration: InputDecoration(
                labelText: 'target_url'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (imageUrlController.text.isNotEmpty) {
                _addBanner(
                  imageUrlController.text,
                  targetUrlController.text,
                );
                Navigator.pop(context);
              }
            },
            child: Text('add'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('store_management'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: DefaultTabController(
          initialIndex: widget.initialTab,
          length: 4,
          child: Column(
            children: [
              // Tabs
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: Colors.blue.shade900,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue.shade900,
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'avatar_frames'.tr()),
                    Tab(text: 'entrance_effects'.tr()),
                    Tab(text: 'vanity_ids'.tr()),
                    Tab(text: 'banners'.tr()),
                  ],
                ),
              ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildStoreItemsTab('frame'),
                    _buildStoreItemsTab('entryEffect'),
                    _buildStoreItemsTab('fancyId'),
                    _buildBannersTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreItemsTab(String filterType) {
    final filteredItems = _storeItems.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';
      return type == filterType;
    }).toList();

    // Hardcoded fallback data
    final fallbackItems = _getHardcodedStoreItems(filterType);
    final displayItems = filteredItems.isEmpty ? fallbackItems : filteredItems;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                filterType == 'frame' ? 'إطارات الصورة الرمزية' :
                filterType == 'entryEffect' ? 'تأثيرات الدخول' :
                filterType == 'fancyId' ? 'معرفات مميزة' : filterType.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddItemDialog(filterType),
                icon: const Icon(Icons.add),
                label: Text('إضافة عنصر'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayItems.length,
                  itemBuilder: (context, index) {
                    final isFallback = filteredItems.isEmpty;
                    final data = isFallback 
                        ? displayItems[index] as Map<String, dynamic>
                        : (displayItems[index] as QueryDocumentSnapshot).data() as Map<String, dynamic>;
                    final docId = isFallback ? 'fallback_$index' : (displayItems[index] as QueryDocumentSnapshot).id;
                    
                    final name = data['name'] as String? ?? 'Unknown';
                    final type = data['type'] as String? ?? filterType;
                    final category = data['category'] as String? ?? type;
                    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
                    final imagePath = data['imagePath'] as String? ?? data['assetPath'] as String? ?? '';
                    final durationDays = data['durationDays'] as int? ?? data['expirationDays'] as int? ?? 30;
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imagePath.startsWith('assets/')
                                    ? Image.asset(
                                        imagePath,
                                        fit: BoxFit.cover,
                                        width: 40,
                                        height: 40,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Icon(
                                              _getFallbackIconData(category),
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
                                                  _getFallbackIconData(category),
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
                                                      _getFallbackIconData(category),
                                                      size: 20,
                                                      color: Colors.grey.shade400,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Center(
                                                child: Icon(
                                                  _getFallbackIconData(category),
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
                                      color: _getCategoryColor(category),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getCategoryLabel(category),
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
                                durationDays == 0 ? 'دائم' : '${durationDays} يوم',
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
                                '\$${price.toStringAsFixed(0)}',
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
                              child: Text(
                                type.toUpperCase(),
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
                                  await _firestore.collection('store_items').doc(docId).update({
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
                                onPressed: () => _showEditStoreItemDialog(docId, data),
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
                                onPressed: () => _deleteStoreItem(docId),
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

  IconData _getFallbackIconData(String category) {
    switch (category) {
      case 'frame':
        return Icons.crop_square;
      case 'entrance_effect':
      case 'entryEffect':
        return Icons.animation;
      case 'fancyId':
      case 'vanity_id':
        return Icons.tag;
      default:
        return Icons.image;
    }
  }

  Widget _buildFallbackIcon(String category) {
    return Center(
      child: Icon(_getFallbackIconData(category), size: 48, color: Colors.grey.shade400),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'frame':
        return Colors.purple;
      case 'entrance_effect':
      case 'entryEffect':
        return Colors.orange;
      case 'fancyId':
      case 'vanity_id':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'frame':
        return 'إطار';
      case 'entrance_effect':
      case 'entryEffect':
        return 'دخولية';
      case 'fancyId':
      case 'vanity_id':
        return 'معرف';
      default:
        return category.toUpperCase();
    }
  }

  List<Map<String, dynamic>> _getHardcodedStoreItems(String filterType) {
    switch (filterType) {
      case 'frame':
        return [
          {
            'name': 'إطار التاج الذهبي',
            'type': 'frame',
            'category': 'frame',
            'price': 1500,
            'imagePath': 'assets/store/frames/gold_crown.png',
            'durationDays': 30,
            'isActive': true,
          },
          {
            'name': 'إطار الماس',
            'type': 'frame',
            'category': 'frame',
            'price': 3000,
            'imagePath': 'assets/store/frames/diamond.png',
            'durationDays': 90,
            'isActive': true,
          },
        ];
      case 'entryEffect':
        return [
          {
            'name': 'دخولية التنين الملكي',
            'type': 'entryEffect',
            'category': 'entrance_effect',
            'price': 3000,
            'imagePath': 'assets/store/entrances/dragon.svga',
            'durationDays': 30,
            'isActive': true,
          },
          {
            'name': 'دخولية قوس قزح',
            'type': 'entryEffect',
            'category': 'entrance_effect',
            'price': 1500,
            'imagePath': 'assets/store/entrances/rainbow.svga',
            'durationDays': 7,
            'isActive': true,
          },
        ];
      case 'fancyId':
        return [
          {
            'name': 'معرف مميز 777',
            'type': 'fancyId',
            'category': 'vanity_id',
            'price': 10000,
            'imagePath': '',
            'durationDays': 30,
            'isActive': true,
          },
          {
            'name': 'معرف مميز 888',
            'type': 'fancyId',
            'category': 'vanity_id',
            'price': 8000,
            'imagePath': '',
            'durationDays': 30,
            'isActive': true,
          },
        ];
      default:
        return [];
    }
  }

  void _showEditPriceDialog(String itemId, double currentPrice) {
    final priceController = TextEditingController(text: currentPrice.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل السعر'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'السعر الجديد',
            prefixText: '\$ ',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(priceController.text);
              if (newPrice != null) {
                _editItemPrice(itemId, newPrice);
                Navigator.pop(context);
              }
            },
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showEditStoreItemDialog(String itemId, Map<String, dynamic> currentData) {
    final nameController = TextEditingController(text: currentData['name']?.toString() ?? '');
    final priceController = TextEditingController(text: currentData['price']?.toString() ?? '');
    String type = currentData['type']?.toString() ?? 'frame';
    final imageController = TextEditingController(text: currentData['imagePath']?.toString() ?? '');
    final expirationDaysController = TextEditingController(text: currentData['expirationDays']?.toString() ?? '30');
    bool isActive = currentData['isActive'] == true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('edit_item'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'item_name'.tr(),
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
                Text('item_type'.tr()),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'frame', label: Text('Frame')),
                    ButtonSegment(value: 'entrance', label: Text('Entrance')),
                    ButtonSegment(value: 'entryEffect', label: Text('Entry Effect')),
                    ButtonSegment(value: 'fancyId', label: Text('Fancy ID')),
                  ],
                  selected: {type},
                  onSelectionChanged: (Set<String> newSelection) {
                    setDialogState(() {
                      type = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: expirationDaysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'expiration_duration'.tr(),
                    suffixText: 'days',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imageController,
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
                            accept: 'image/*,.svga,.json,.gif',
                            onPicked: (base64, fileName) {
                              setDialogState(() {
                                imageController.text = base64;
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
                              allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'svga', 'json'],
                              withData: true,
                            );
                            if (result != null && result.files.single.bytes != null) {
                              final base64 = base64Encode(result.files.single.bytes!);
                              setDialogState(() {
                                imageController.text = base64;
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
                        final itemData = {
                          'name': nameController.text,
                          'type': type,
                          'price': double.tryParse(priceController.text) ?? 0.0,
                          'imagePath': imageController.text,
                          'expirationDays': int.tryParse(expirationDaysController.text) ?? 30,
                          'isActive': isActive,
                          'updatedAt': FieldValue.serverTimestamp(),
                        };

                        await _firestore.collection('store_items').doc(itemId).update(itemData);
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('item_updated'.tr()),
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

  Widget _buildBannersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'banners'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: _showAddBannerDialog,
                icon: const Icon(Icons.add),
                label: Text('add_banner'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _banners.isEmpty
              ? Center(child: Text('no_banners'.tr()))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _banners.length,
                  itemBuilder: (context, index) {
                    final doc = _banners[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final imageUrl = data['imageUrl'] as String? ?? '';
                    final targetUrl = data['targetUrl'] as String? ?? '';
                    final isActive = data['isActive'] as bool? ?? true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.image, size: 48),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Icon(Icons.image, size: 48),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${'target_url'.tr()}: $targetUrl',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Switch(
                                      value: isActive,
                                      onChanged: (value) async {
                                        await _firestore
                                            .collection('banners')
                                            .doc(doc.id)
                                            .update({'isActive': value});
                                        // Real-time stream will auto-update
                                      },
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      onPressed: () => _deleteBanner(doc.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
