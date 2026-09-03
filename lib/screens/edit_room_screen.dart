import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../services/cloudinary_service.dart';
import '../controllers/room_ui_controller.dart';
import '../widgets/app_icon.dart';

class EditRoomScreen extends StatefulWidget {
  final String roomName;
  final int currentMicCount;
  final RoomUiController? controller;

  const EditRoomScreen({
    super.key,
    required this.roomName,
    this.currentMicCount = 20,
    this.controller,
  });

  @override
  State<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends State<EditRoomScreen> {
  late TextEditingController roomNameController;
  late TextEditingController announcementController;
  int selectedMicsCount = 20;
  String selectedBadge = 'دردشة';
  String selectedBackground = 'assets/Asad/room_item_bg.png';
  String? _base64Image;
  bool _isSaving = false;

  final List<Map<String, String>> categories = [
    {'name': 'دردشة', 'icon': '💬'},
    {'name': 'كرة قدم', 'icon': '⚽'},
    {'name': 'ألعاب', 'icon': '🎮'},
    {'name': 'غناء', 'icon': '🎤'},
  ];

  @override
  void initState() {
    super.initState();
    roomNameController = TextEditingController(text: widget.roomName);
    announcementController = TextEditingController(text: widget.controller?.roomAnnouncement ?? 'أهلاً بالجميع');
    selectedMicsCount = widget.currentMicCount;
    if (widget.controller != null) {
      selectedBadge = widget.controller!.roomCategory;
      selectedBackground = widget.controller!.backgroundPath;
      // We don't load the existing Base64 here for performance, only if updated
    }
  }

  @override
  void dispose() {
    roomNameController.dispose();
    announcementController.dispose();
    super.dispose();
  }

  ImageProvider _getSafeImage(String path) {
    if (path.isEmpty) return const AssetImage('assets/Asad/room.jpg');
    if (path.startsWith('assets/')) return AssetImage(path);
    if (path.startsWith('http')) return NetworkImage(path);
    if (path.startsWith('data:image')) {
      final String pureBase64 = path.split(',').last;
      return MemoryImage(Uint8List.fromList(base64Decode(pureBase64)));
    }
    return FileImage(File(path));
  }

  Future<void> _pickRoomImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 300,
      maxHeight: 300,
    );
    if (image != null) {
      try {
        final String url = await CloudinaryService.uploadImage(image, folder: 'room_covers');
        if (mounted) {
          setState(() {
            _base64Image = url;
          });
        }
      } catch (e) {
        debugPrint('Error uploading image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل رفع الصورة، حاول مرة أخرى')),
          );
        }
      }
    }
  }

  Future<void> _saveChanges() async {
    if (widget.controller == null) return;

    setState(() => _isSaving = true);

    try {
      final String name = roomNameController.text.trim();
      final String announcement = announcementController.text.trim();

      // 1. Update local controller
      widget.controller!.updateRoomDetails(
        name: name,
        announcement: announcement,
        micCount: selectedMicsCount,
        category: selectedBadge,
        background: selectedBackground,
        coverPath: _base64Image ?? widget.controller!.roomCoverPath,
      );

      // 2. Sync to Supabase
      await SupabaseService.client.from('rooms').update({
        'room_name': name,
        'description': announcement,
        'active_mic_count': selectedMicsCount,
        'category': selectedBadge,
        'background_path': selectedBackground,
        if (_base64Image != null) 'room_cover': _base64Image,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('room_id', widget.controller!.roomId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving room changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحفظ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000B18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0033),
        title: const Text('تعديل الغرفة', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSettingRow(
                  title: 'صورة الغرفة',
                  value: 'تغيير صورة الغلاف',
                  onTap: _pickRoomImage,
                  trailing: Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white10,
                        backgroundImage: _getSafeImage(_base64Image ?? widget.controller?.roomCoverPath ?? ''),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                          child: const AppIcon('Icons.camera_alt', icon: Icons.camera_alt, size: 12, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: roomNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'اسم الغرفة',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: announcementController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'شعار الغرفة (Motto)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                  ),
                ),
                const SizedBox(height: 30),
                _buildSettingRow(
                  title: 'سعة الغرفة (المايكات)',
                  value: 'عدد مقاعد المايكات ($selectedMicsCount)',
                  onTap: _showMicCountPicker,
                  icon: Icons.mic,
                ),
                _buildSettingRow(
                  title: 'خلفية الغرفة',
                  value: 'تغيير الخلفية الحالية',
                  onTap: _showBackgroundPicker,
                  icon: Icons.image,
                ),
                _buildSettingRow(
                  title: 'تصنيف الغرفة (Badge)',
                  value: 'التصنيف المختار: $selectedBadge',
                  onTap: _showBadgePicker,
                  icon: Icons.badge,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_isSaving ? 'جاري الحفظ...' : 'الاحتفاظ', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.amber)),
            ),
        ],
      ),
    );
  }

  void _showMicCountPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1931),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 400,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              const Text(
                'تغيير عدد مقاعد المايك',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: 20,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final count = index + 1;
                    final isSelected = selectedMicsCount == count;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedMicsCount = count;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.amber : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.amber : Colors.white12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBackgroundPicker() {
    final backgrounds = [
      'assets/Asad/room_item_bg.png',
      'assets/Asad/room.jpg',
      'assets/Asad/bg_header.png',
      'assets/Asad/bg_room.png',
      'assets/Asad/bg_vip_content.png',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1931),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'اختر خلفية الغرفة',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: backgrounds.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    final bg = backgrounds[index];
                    final isSelected = selectedBackground == bg;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedBackground = bg);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.amber : Colors.transparent,
                            width: 3,
                          ),
                          image: DecorationImage(
                            image: _getSafeImage(bg),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: isSelected ? const Center(child: AppIcon('Icons.check_circle', icon: Icons.check_circle, color: Colors.amber, size: 40)) : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBadgePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1931),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر شعار الغرفة',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: categories.map((cat) {
                  final isSelected = selectedBadge == cat['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBadge = cat['name']!;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.amber : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: isSelected ? Colors.amber : Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat['icon']!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            cat['name']!,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingRow({
    required String title,
    required String value,
    required VoidCallback onTap,
    IconData? icon,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.amber, size: 24),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            trailing ?? const AppIcon('Icons.arrow_forward_ios', icon: Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }
}
