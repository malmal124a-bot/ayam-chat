import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/royal_button.dart';
import '../controllers/user_controller.dart';
import '../controllers/room_controller.dart';
import 'voice_room_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  String? _selectedImagePath;
  Uint8List? _webImageBytes;
  String? _selectedImageBase64;
  String selectedCategory = 'دردشة';
  
  final List<String> categories = ['دردشة', 'ألعاب', 'موسيقى', 'حفلات', 'ثقافة'];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      // COMPRESS IMAGE: Reduced quality and size for Firestore Base64 storage
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 20, // More aggressive compression
        maxWidth: 300,    // Even smaller dimensions for Base64
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        
        // Check if Base64 string exceeds safe size (Firestore 1MB limit, aim for <100KB)
        if (base64String.length > 150000) {
          debugPrint('Image too large for Firestore (${base64String.length} chars), using default');
          setState(() {
            _webImageBytes = bytes;
            _selectedImagePath = image.path;
            _selectedImageBase64 = null; // Reject oversized images
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('الصورة كبيرة جداً، سيتم استخدام الصورة الافتراضية')),
            );
          }
        } else {
          setState(() {
            _webImageBytes = bytes;
            _selectedImagePath = image.path;
            _selectedImageBase64 = base64String;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking/compressing image: $e');
    }
  }

  Future<void> _handleCreate() async {
    if (_nameController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الغرفة')),
      );
      return;
    }

    final userController = UserController();
    final roomController = RoomController();
    
    final existingRoom = await roomController.getRoomByOwner(userController.id);
    
    if (existingRoom != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لديك بالفعل غرفة، يتم توجيهك إليها')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VoiceRoomScreen(
              roomId: existingRoom['roomId'],
              roomName: existingRoom['roomName'],
              roomCover: existingRoom['roomImageBase64'] ?? existingRoom['roomImage'] ?? existingRoom['roomCover'],
              isOwner: true,
            ),
          ),
        );
      }
      return;
    }
    
    final roomId = userController.displayId;
    
    // PERSIST ROOM WITH BASE64: Use encoded string for direct Firestore storage
    final roomCover = _selectedImageBase64 ?? 'assets/Asad/bg_vip_content.png';
    
    final success = await roomController.createOrUpdateRoom(
      roomId: roomId,
      ownerId: userController.id,
      ownerName: userController.name,
      roomName: _nameController.text.trim(),
      roomCover: roomCover,
      category: selectedCategory,
      description: _descController.text.trim(),
      roomImageBase64: _selectedImageBase64,
    );
    
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VoiceRoomScreen(
            roomId: roomId,
            roomName: _nameController.text.trim(),
            roomCover: roomCover,
            isOwner: true,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل إنشاء الغرفة، يرجى المحاولة مرة أخرى')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B08),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.amber),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('إنشاء غرفة ملكية', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Material(
        color: const Color(0xFF0D0B08),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('أدخل تفاصيل غرفتك للبدء بالبث الصوتي المباشر والتميز بمكانتك الملكية', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 32),
              const Text('صورة الغرفة (اختياري)', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    image: _buildDecorationImage(),
                    border: Border.all(color: (_selectedImagePath == null && _webImageBytes == null) ? Colors.amber.withValues(alpha: 0.3) : Colors.amber, width: 1.5),
                  ),
                  child: (_selectedImagePath == null && _webImageBytes == null)
                      ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_rounded, color: Colors.amber, size: 32), SizedBox(height: 12), Text('اضغط لاختيار صورة (اختياري)', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500))])
                      : Align(alignment: Alignment.bottomRight, child: Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.black, size: 18))),
                ),
              ),
              const SizedBox(height: 24),
              _field('اسم الغرفة', _nameController, Icons.title_rounded),
              const SizedBox(height: 16),
              _field('وصف الغرفة', _descController, Icons.description_rounded),
              const SizedBox(height: 24),
              const Text('تصنيف الغرفة', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: selectedCategory == cat,
                      onSelected: (val) => setState(() => selectedCategory = cat),
                      selectedColor: Colors.amber,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 40),
              RoyalButton(label: 'إنشاء ودخول الآن', icon: Icons.rocket_launch_rounded, onTap: _handleCreate),
            ],
          ),
        ),
      ),
    );
  }

  DecorationImage? _buildDecorationImage() {
    if (kIsWeb && _webImageBytes != null) return DecorationImage(image: MemoryImage(_webImageBytes!), fit: BoxFit.cover);
    if (!kIsWeb && _selectedImagePath != null) return DecorationImage(image: FileImage(File(_selectedImagePath!)), fit: BoxFit.cover);
    return null;
  }

  Widget _field(String hint, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        prefixIcon: Icon(icon, color: Colors.amber.withValues(alpha: 0.5), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }
}
