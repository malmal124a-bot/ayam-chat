import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/app_icon.dart';

// Absolute imports to ensure perfect resolution
import 'package:ayam_chat/controllers/user_controller.dart';
import 'package:ayam_chat/controllers/auth_controller.dart';
import 'package:ayam_chat/screens/main_shell.dart';
import 'package:ayam_chat/services/supabase_service.dart';
import 'package:ayam_chat/services/cloudinary_service.dart';
import 'package:ayam_chat/utils/image_utils.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isInitialSetup;
  const EditProfileScreen({super.key, this.isInitialSetup = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserController userController = UserController();
  final AuthController authController = AuthController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late String _selectedGender;
  late String _selectedCountry;
  late DateTime _selectedDob;
  String? _base64Image;
  bool _isUploading = false;

  final List<String> _countries = [
    'العراق', 'السعودية', 'الإمارات', 'مصر', 'سوريا', 'الأردن',
    'لبنان', 'فلسطين', 'الكويت', 'قطر', 'البحرين', 'عمان',
    'اليمن', 'ليبيا', 'تونس', 'المغرب', 'الجزائر', 'السودان',
    'موريتانيا', 'الصومال', 'جيبوتي', 'إيران', 'تركيا', '其他国家',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: userController.name);
    _selectedGender = userController.gender.isNotEmpty ? userController.gender : 'Male';
    _selectedCountry = userController.country.isNotEmpty ? userController.country : '';
    _selectedDob = userController.dateOfBirth ?? DateTime(1995, 1, 1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // UPLOAD TO CLOUDINARY: Resize during picking, then upload
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 300,
        maxHeight: 300,
      );
      if (image != null) {
        final String url = await CloudinaryService.uploadImage(image, folder: 'avatars');
        if (mounted) {
          setState(() {
            _base64Image = url;
          });
        }
        if (mounted) Navigator.pop(context);
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

  void _showImageSourceSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: AppIcon('Icons.camera_alt_rounded', icon: Icons.camera_alt_rounded, color: theme.colorScheme.secondary),
              title: Text('الكاميرا', style: TextStyle(color: theme.colorScheme.onSurface)),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: AppIcon('Icons.photo_library_rounded', icon: Icons.photo_library_rounded, color: theme.colorScheme.secondary),
              title: Text('المعرض', style: TextStyle(color: theme.colorScheme.onSurface)),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: ColorScheme.dark(
              primary: theme.colorScheme.secondary,
              onPrimary: theme.colorScheme.onSecondary,
              surface: theme.cardColor,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    final theme = Theme.of(context);
    if (_formKey.currentState?.validate() ?? false) {
      try {
        setState(() => _isUploading = true);

        // Update local UserController
        userController.updateProfile(
          newName: _nameController.text.trim(),
          newGender: _selectedGender,
          newDob: _selectedDob,
          newPic: _base64Image ?? userController.profilePic,
          newCountry: _selectedCountry,
        );

        // Update Supabase profile row for real-time sync
        final userId = SupabaseService.currentUserId;
        if (userId != null) {
          await SupabaseService.client.from('users').update({
            'name': _nameController.text.trim(),
            'gender': _selectedGender,
            'country': _selectedCountry,
            'photo_url': _base64Image ?? userController.profilePic,
          }).eq('auth_uid', userId);
          debugPrint('Profile updated in Supabase for user: $userId');
        }

        if (widget.isInitialSetup) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 2)),
          );
        } else {
          Navigator.pop(context);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم تحديث بيانات الملف الشخصي بنجاح'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error saving profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildProfileImageWidget() {
    if (_base64Image != null && _base64Image!.isNotEmpty) {
       if (ImageUtils.isHttpUrl(_base64Image)) {
         return Image.network(
           _base64Image!,
           fit: BoxFit.cover,
           errorBuilder: (c, e, s) => const AppIcon('Icons.error', icon: Icons.error),
         );
       }
       final String pureBase64 = _base64Image!.split(',').last;
       return Image.memory(
         Uint8List.fromList(base64Decode(pureBase64)),
         fit: BoxFit.cover,
         errorBuilder: (c, e, s) => const AppIcon('Icons.error', icon: Icons.error),
       );
    }

    final String profilePic = userController.profilePic;

    if (profilePic.startsWith('assets/')) {
      return Image.asset(profilePic, fit: BoxFit.cover);
    }

    if (profilePic.startsWith('data:image')) {
       final String pureBase64 = profilePic.split(',').last;
       return Image.memory(
         Uint8List.fromList(base64Decode(pureBase64)),
         fit: BoxFit.cover,
          errorBuilder: (c, e, s) => const AppIcon('Icons.person', icon: Icons.person),
       );
    }

    if (kIsWeb || profilePic.startsWith('http') || profilePic.startsWith('blob:')) {
      return Image.network(
        profilePic,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const AppIcon('Icons.person', icon: Icons.person),
      );
    }
    
    return Image.file(File(profilePic), fit: BoxFit.cover, errorBuilder: (c, e, s) => const AppIcon('Icons.person', icon: Icons.person));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isInitialSetup ? 'إكمال الملف الشخصي' : 'تعديل الملف الشخصي',
          style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.cardColor,
                              border: Border.all(color: theme.colorScheme.secondary, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildProfileImageWidget(),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.cardColor, width: 2),
                              ),
                              child: AppIcon('Icons.camera_alt_rounded', icon: Icons.camera_alt_rounded, size: 20, color: theme.colorScheme.onSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text('الاسم المستعار', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: _inputDecoration('أدخل اسمك', theme),
                    validator: (value) => value == null || value.trim().isEmpty ? 'يرجى إدخال الاسم' : null,
                  ),
                  const SizedBox(height: 24),
                  Text('الجنس', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('ذكر', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14)),
                          value: 'Male',
                          groupValue: _selectedGender,
                          activeColor: theme.colorScheme.secondary,
                          onChanged: (value) => setState(() => _selectedGender = value ?? 'Male'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('أنثى', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14)),
                          value: 'Female',
                          groupValue: _selectedGender,
                          activeColor: theme.colorScheme.secondary,
                          onChanged: (value) => setState(() => _selectedGender = value ?? 'Female'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('تاريخ الميلاد', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${_selectedDob.toLocal()}".split(' ')[0],
                            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
                          ),
                          AppIcon('Icons.calendar_today_rounded', icon: Icons.calendar_today_rounded, color: theme.colorScheme.secondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('البلد', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCountry.isNotEmpty ? _selectedCountry : null,
                        hint: Text('اختر البلد', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.54))),
                        dropdownColor: theme.cardColor,
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
                        items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedCountry = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                      ),
                      child: Text(
                        widget.isInitialSetup ? 'إتمام التسجيل' : 'حفظ التغييرات',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.amber)),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, ThemeData theme) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.54)),
        filled: true,
        fillColor: theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
      );
}
