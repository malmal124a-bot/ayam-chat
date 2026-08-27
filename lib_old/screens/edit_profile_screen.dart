import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Absolute imports to ensure perfect resolution
import 'package:ayam_chat/controllers/user_controller.dart';
import 'package:ayam_chat/screens/main_shell.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isInitialSetup;
  const EditProfileScreen({super.key, this.isInitialSetup = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserController userController = UserController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late String _selectedGender;
  late DateTime _selectedDob;
  String? _localImagePath;
  Uint8List? _webImageBytes;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    _nameController = TextEditingController(text: userController.name);
    _selectedGender = userController.gender.isNotEmpty ? userController.gender : 'Male';
    _selectedDob = userController.dateOfBirth ?? DateTime(1995, 1, 1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 512,
      );
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _localImagePath = image.path;
          });
        } else {
          setState(() {
            _localImagePath = image.path;
          });
        }
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.amber),
                title: const Text('الكاميرا', style: TextStyle(color: Colors.white)),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.amber),
                title: const Text('المعرض', style: TextStyle(color: Colors.white)),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Convert image to Base64 for Firestore storage
      String? imageBase64;
      if (_webImageBytes != null) {
        imageBase64 = 'data:image/jpeg;base64,${base64Encode(_webImageBytes!)}';
      } else if (_localImagePath != null && !_localImagePath!.startsWith('http') && !_localImagePath!.startsWith('assets/')) {
        try {
          final bytes = await File(_localImagePath!).readAsBytes();
          imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        } catch (e) {
          debugPrint('Error reading image file: $e');
        }
      }

      // Update Firestore with profile image
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('users').doc(userController.id).update({
          'name': _nameController.text.trim(),
          'gender': _selectedGender,
          'profilePic': imageBase64 ?? _localImagePath ?? userController.profilePic,
          'photoUrl': imageBase64 ?? _localImagePath ?? userController.profilePic, // Unified field
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update local controller state
        userController.updateProfile(
          newName: _nameController.text.trim(),
          newGender: _selectedGender,
          newDob: _selectedDob,
          newPic: imageBase64 ?? _localImagePath,
        );

        // Force UI refresh
        setState(() {});

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
            const SnackBar(
              content: Text('تم تحديث بيانات الملف الشخصي بنجاح'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.amber,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error updating profile in Firestore: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل تحديث الملف الشخصي: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildProfileImageWidget() {
    if (kIsWeb && _webImageBytes != null) {
      return Image.memory(_webImageBytes!, fit: BoxFit.cover);
    }

    final localPath = _localImagePath;
    if (localPath != null) {
      if (kIsWeb || localPath.startsWith('http') || localPath.startsWith('blob:')) {
        return Image.network(
          localPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
        );
      }
      return Image.file(File(localPath), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.error));
    }

    final String profilePic = userController.profilePic;

    if (profilePic.startsWith('assets/')) {
      return Image.asset(profilePic, fit: BoxFit.cover);
    }

    if (kIsWeb || profilePic.startsWith('http') || profilePic.startsWith('blob:')) {
      return Image.network(
        profilePic,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
      );
    }
    
    return Image.file(File(profilePic), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
              const Color(0xFF1A1A2E),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    if (!widget.isInitialSetup)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                      ),
                    Expanded(
                      child: Text(
                        widget.isInitialSetup ? 'إكمال الملف الشخصي' : 'تعديل الملف الشخصي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: widget.isInitialSetup ? TextAlign.center : TextAlign.left,
                      ),
                    ),
                    if (!widget.isInitialSetup)
                      const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Image Section
                            Center(
                              child: GestureDetector(
                                onTap: _showImageSourceSheet,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 130,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.amber.withValues(alpha: 0.3),
                                            Colors.orange.withValues(alpha: 0.2),
                                            Colors.deepOrange.withValues(alpha: 0.1),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: Colors.amber.withValues(alpha: 0.6),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.amber.withValues(alpha: 0.3),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: _buildProfileImageWidget(),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.amber,
                                              Colors.orange,
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.amber.withValues(alpha: 0.4),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Name Field
                            _buildSectionTitle('الاسم المستعار'),
                            const SizedBox(height: 12),
                            _buildModernTextField(
                              controller: _nameController,
                              hint: 'أدخل اسمك',
                              validator: (value) => value == null || value.trim().isEmpty ? 'يرجى إدخال الاسم' : null,
                            ),
                            const SizedBox(height: 28),
                            // Gender Selection
                            _buildSectionTitle('الجنس'),
                            const SizedBox(height: 12),
                            _buildGenderSelector(),
                            const SizedBox(height: 28),
                            // Date of Birth Field
                            _buildSectionTitle('تاريخ الميلاد'),
                            const SizedBox(height: 12),
                            _buildDateSelector(),
                            const SizedBox(height: 40),
                            // Action Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 8,
                                  shadowColor: Colors.amber.withValues(alpha: 0.4),
                                ),
                                child: Text(
                                  widget.isInitialSetup ? 'إتمام التسجيل' : 'حفظ التغييرات',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.amber, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedGender = 'Male'),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: _selectedGender == 'Male' 
                      ? Colors.amber.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  border: _selectedGender == 'Male'
                      ? const Border(left: BorderSide(color: Colors.amber, width: 3))
                      : null,
                ),
                child: Center(
                  child: Text(
                    'ذكر',
                    style: TextStyle(
                      color: _selectedGender == 'Male' ? Colors.amber : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedGender = 'Female'),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: _selectedGender == 'Female'
                      ? Colors.amber.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: _selectedGender == 'Female'
                      ? const Border(right: BorderSide(color: Colors.amber, width: 3))
                      : null,
                ),
                child: Center(
                  child: Text(
                    'أنثى',
                    style: TextStyle(
                      color: _selectedGender == 'Female' ? Colors.amber : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${_selectedDob.toLocal()}".split(' ')[0],
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Icon(Icons.calendar_today_rounded, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amber,
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
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
}
