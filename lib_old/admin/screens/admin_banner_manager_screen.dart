import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/web_file_picker.dart';
import '../controllers/admin_auth_controller.dart';
import '../controllers/admin_rbac_controller.dart';

class AdminBannerManagerScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  
  const AdminBannerManagerScreen({
    super.key,
    required this.adminAuthController,
  });

  @override
  State<AdminBannerManagerScreen> createState() => _AdminBannerManagerScreenState();
}

class _AdminBannerManagerScreenState extends State<AdminBannerManagerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _rbacController = AdminRBACController();
  
  List<Map<String, dynamic>> _banners = [];
  Map<String, dynamic>? _announcementConfig;
  
  bool _isLoading = true;
  bool _isSaving = false;

  // Banner form controllers
  final _imageUrlController = TextEditingController();
  final _targetUrlController = TextEditingController();
  final _scrollDurationController = TextEditingController(text: '5');
  
  // Announcement form controllers
  final _announcementTextController = TextEditingController();
  final _announcementDurationController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _loadBanners();
    _loadAnnouncementConfig();
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    _targetUrlController.dispose();
    _scrollDurationController.dispose();
    _announcementTextController.dispose();
    _announcementDurationController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestore
          .collection('banners')
          .orderBy('order')
          .get();

      setState(() {
        _banners = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading banners: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAnnouncementConfig() async {
    try {
      final doc = await _firestore
          .collection('system_config')
          .doc('global_announcement')
          .get();

      if (doc.exists) {
        setState(() {
          _announcementConfig = doc.data();
          _announcementTextController.text = _announcementConfig?['text'] ?? '';
          _announcementDurationController.text = (_announcementConfig?['scrollDuration'] ?? 10).toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading announcement config: $e');
    }
  }

  Future<void> _addBanner(String imageUrl, String targetUrl) async {
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.manageBanners,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient permissions to manage banners'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image URL is required')),
      );
      return;
    }

    try {
      final newOrder = _banners.length;
      await _firestore.collection('banners').add({
        'imageUrl': imageUrl,
        'targetUrl': targetUrl,
        'order': newOrder,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': widget.adminAuthController.currentUserId,
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Banner added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBanners();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add banner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBanner(String bannerId) async {
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.manageBanners,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient permissions to manage banners'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('banners').doc(bannerId).delete();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Banner deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBanners();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete banner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleBannerActive(String bannerId, bool isActive) async {
    try {
      await _firestore.collection('banners').doc(bannerId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _loadBanners();
    } catch (e) {
      debugPrint('Failed to toggle banner: $e');
    }
  }

  Future<void> _saveAnnouncementConfig() async {
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.manageBanners,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient permissions to manage announcements'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final duration = int.tryParse(_announcementDurationController.text) ?? 10;
      await _firestore
          .collection('system_config')
          .doc('global_announcement')
          .set({
        'text': _announcementTextController.text,
        'scrollDuration': duration,
        'autoScroll': _announcementTextController.text.isNotEmpty,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': widget.adminAuthController.currentUserId,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Announcement config saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save announcement config: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showAddBannerDialog() {
    final imageUrlController = TextEditingController();
    final targetUrlController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('add_banner'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'image_url'.tr(),
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
                              imageUrlController.text = base64;
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
                            allowedExtensions: ['png', 'jpg', 'jpeg', 'gif'],
                            withData: true,
                          );
                          if (result != null && result.files.single.bytes != null) {
                            final file = result.files.single;
                            // Encode to Base64 and save directly to Firestore
                            final base64Data = 'data:image/${file.extension ?? 'png'};base64,${base64Encode(file.bytes!)}';
                            setDialogState(() {
                              imageUrlController.text = base64Data;
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
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (imageUrlController.text.isNotEmpty) {
                        setDialogState(() {
                          isSaving = true;
                        });
                        await _addBanner(
                          imageUrlController.text,
                          targetUrlController.text,
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
                  : Text('add_banner'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Base64 image
      try {
        final base64Data = imageUrl.split(',')[1];
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.broken_image),
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.grey.shade300,
          child: const Center(
            child: Icon(Icons.broken_image),
          ),
        );
      }
    } else if (imageUrl.startsWith('http')) {
      // Network image
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Center(
              child: Icon(Icons.broken_image),
            ),
          );
        },
      );
    } else if (imageUrl.startsWith('assets/')) {
      // Asset image
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Center(
              child: Icon(Icons.broken_image),
            ),
          );
        },
      );
    } else {
      // Fallback
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.broken_image),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('banner_manager'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBanners,
            tooltip: 'refresh'.tr(),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              // Tabs
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: Colors.blue.shade900,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue.shade900,
                  tabs: [
                    Tab(text: 'banners'.tr()),
                    Tab(text: 'global_announcement'.tr()),
                  ],
                ),
              ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildBannersTab(),
                    _buildAnnouncementTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Add Banner Button
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: ElevatedButton.icon(
            onPressed: _showAddBannerDialog,
            icon: const Icon(Icons.add),
            label: Text('add_banner'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        
        // Banners Grid
        Expanded(
          child: _banners.isEmpty
              ? Center(child: Text('no_banners'.tr()))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2,
                  ),
                  itemCount: _banners.length,
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    final isActive = banner['isActive'] as bool? ?? true;
                    
                    return Card(
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildBannerImage(banner['imageUrl'] ?? ''),
                                if (!isActive)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    child: const Center(
                                      child: Text(
                                        'INACTIVE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Order: ${banner['order'] ?? 0}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Switch(
                                  value: isActive,
                                  onChanged: (value) {
                                    _toggleBannerActive(banner['id'], value);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => _deleteBanner(banner['id']),
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

  Widget _buildAnnouncementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'global_announcement'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _announcementTextController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'announcement_text'.tr(),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _announcementDurationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'scroll_duration'.tr(),
                  suffixText: 'seconds',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('auto_scroll'.tr()),
                subtitle: Text('Enable auto-scrolling announcement bar'),
                value: _announcementTextController.text.isNotEmpty,
                onChanged: null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAnnouncementConfig,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text('save'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Preview
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Preview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.campaign, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _announcementTextController.text.isEmpty
                            ? 'No announcement set'
                            : _announcementTextController.text,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
