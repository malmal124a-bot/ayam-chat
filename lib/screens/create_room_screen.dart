import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../services/cloudinary_service.dart';
import '../widgets/royal_button.dart';
import '../widgets/app_icon.dart';
import 'voice_room_screen.dart';
import '../controllers/user_controller.dart';
import '../utils/image_utils.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  String? _base64Image;
  String selectedCategory = 'دردشة';
  bool _isLoading = false;
  
  final List<String> categories = ['دردشة', 'ألعاب', 'موسيقى', 'حفلات', 'ثقافة'];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      // UPLOAD TO CLOUDINARY: Resize during picking, then upload
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 300,
        maxHeight: 300,
      );
      
      if (image != null) {
        final String url = await CloudinaryService.uploadImage(image, folder: 'room_covers');
        if (mounted) {
          setState(() {
            _base64Image = url;
          });
        }
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

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الغرفة')),
      );
      return;
    }

    if (_base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار صورة للغرفة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userController = UserController();
      final String roomId = userController.numericId; // User's 6-digit Profile ID
      
      // FALLBACK: Use Supabase user ID if auth is unavailable
      final String uid = SupabaseService.currentUserId ?? userController.numericId;

      if (uid.isEmpty) {
        debugPrint('No user ID available for room creation');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل: لا يوجد معرف مستخدم')),
          );
        }
        return;
      }

      // STRICT 1 USER = 1 ROOM = 1 ID PRINCIPLE
      // Check if room already exists
      final existingRoom = await SupabaseService.client
          .from('rooms')
          .select()
          .eq('room_id', roomId)
          .maybeSingle();

      if (existingRoom != null) {
        // If room exists, immediately route them into their existing room
        debugPrint('Room already exists for ID: $roomId. Entering existing room.');
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoiceRoomScreen(
              roomName: existingRoom['room_name'] ?? name,
              roomId: roomId,
              roomCover: existingRoom['room_cover'],
              isOwner: true,
            ),
          ),
        );
        return;
      }

      // Create new room row in Supabase using 6-digit ID as room_id
      final roomData = {
        'room_id': roomId,
        'room_name': name,
        'description': _descController.text.trim(),
        'category': selectedCategory,
        'owner_id': userController.numericId,
        'owner_uid': uid,
        'owner_name': userController.name,
        'room_cover': _base64Image, // CLOUDINARY URL
        'participant_count': 1,
        'status': 'active', // STEP 5: GLOBAL HOME SCREEN STREAMING
        'is_active': true,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'last_active': DateTime.now().toUtc().toIso8601String(),
      };

      await SupabaseService.client.from('rooms').insert(roomData);

      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VoiceRoomScreen(
            roomName: name,
            roomId: roomId,
            roomCover: _base64Image,
            isOwner: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error creating room: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء الغرفة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          icon: const AppIcon('Icons.arrow_back_ios_new_rounded', icon: Icons.arrow_back_ios_new_rounded, color: Colors.amber),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'إنشاء غرفة ملكية',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Material(
            color: const Color(0xFF0D0B08),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'أدخل تفاصيل غرفتك للبدء بالبث الصوتي المباشر والتميز بمكانتك الملكية',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  
                  const Text('صورة الغرفة', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 12),
                  
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        image: _buildDecorationImage(),
                        border: Border.all(
                          color: (_base64Image == null)
                            ? Colors.amber.withOpacity(0.3)
                            : Colors.amber,
                          width: 1.5,
                        ),
                      ),
                      child: (_base64Image == null)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const AppIcon('Icons.add_photo_alternate_rounded', icon: Icons.add_photo_alternate_rounded, color: Colors.amber, size: 32),
                                ),
                                const SizedBox(height: 12),
                                const Text('اضغط لاختيار صورة من الاستوديو', 
                                  style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            )
                          : Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: const AppIcon('Icons.edit', icon: Icons.edit, color: Colors.black, size: 18),
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  _field('اسم الغرفة (مثال: سهرة الملوك والأساطير)', _nameController, Icons.title_rounded),
                  const SizedBox(height: 16),
                  _field('وصف الغرفة (أخبر العالم عن تميز غرفتك)', _descController, Icons.description_rounded),
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
                          labelStyle: TextStyle(
                            color: selectedCategory == cat ? Colors.black : Colors.white60,
                            fontWeight: selectedCategory == cat ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: Colors.white.withOpacity(0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                        ),
                      )).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  RoyalButton(
                    label: _isLoading ? 'جاري الإنشاء...' : 'إنشاء ودخول الآن', 
                    icon: Icons.rocket_launch_rounded, 
                    onTap: _isLoading ? () {} : _handleCreate,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.amber)),
            ),
        ],
      ),
    );
  }

  DecorationImage? _buildDecorationImage() {
    if (_base64Image != null && _base64Image!.isNotEmpty) {
       if (ImageUtils.isHttpUrl(_base64Image)) {
         return DecorationImage(
           image: NetworkImage(_base64Image!),
           fit: BoxFit.cover,
           onError: (exception, stackTrace) {},
         );
       }
       final String pureBase64 = _base64Image!.split(',').last;
       return DecorationImage(
         image: MemoryImage(Uint8List.fromList(base64Decode(pureBase64))),
         fit: BoxFit.cover,
       );
    }
    return null;
  }

  Widget _field(String hint, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: Colors.amber.withOpacity(0.5), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.amber.withOpacity(0.5))),
      ),
    );
  }
}
