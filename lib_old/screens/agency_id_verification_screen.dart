import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/agency_controller.dart';
import '../theme/app_theme.dart';
import 'agency_tier_selection_screen.dart';

class AgencyIdVerificationScreen extends StatefulWidget {
  const AgencyIdVerificationScreen({super.key});

  @override
  State<AgencyIdVerificationScreen> createState() => _AgencyIdVerificationScreenState();
}

class _AgencyIdVerificationScreenState extends State<AgencyIdVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  String? _frontImageUrl;
  String? _backImageUrl;
  bool _isUploadingFront = false;
  bool _isUploadingBack = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      if (isFront) {
        _isUploadingFront = true;
      } else {
        _isUploadingBack = true;
      }
    });

    try {
      String? url;
      if (kIsWeb) {
        url = image.path; // Blob URL on web
      } else {
        if (!mounted) return;
        url = await context.read<AgencyController>().uploadCardImage(File(image.path), isFront);
      }

      if (mounted) {
        setState(() {
          if (isFront) {
            _frontImageUrl = url;
          } else {
            _backImageUrl = url;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error uploading image')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isFront) {
            _isUploadingFront = false;
          } else {
            _isUploadingBack = false;
          }
        });
      }
    }
  }

  void _next() {
    if (_formKey.currentState!.validate() && _frontImageUrl != null && _backImageUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AgencyTierSelectionScreen(
            verificationData: {
              'name': _nameController.text,
              'phone': _phoneController.text,
              'email': _emailController.text,
              'frontId': _frontImageUrl,
              'backId': _backImageUrl,
            },
          ),
        ),
      );
    } else if (_frontImageUrl == null || _backImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء رفع صور البطاقة (وجه وضهر)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.royalPurpleDark,
      appBar: AppBar(
        title: const Text('طلب توثيق الوكالة'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'الخطوة 1: البيانات الشخصية',
                  style: TextStyle(color: AppTheme.royalGold, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildTextField(_nameController, 'الاسم الكامل', Icons.person),
                const SizedBox(height: 15),
                _buildTextField(_phoneController, 'رقم الهاتف', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 15),
                _buildTextField(_emailController, 'البريد الإلكتروني', Icons.email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 30),
                const Text('صور البطاقة الشخصية', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildImagePickerBox(
                        label: 'وجه البطاقة',
                        imageUrl: _frontImageUrl,
                        isUploading: _isUploadingFront,
                        onTap: () => _pickImage(true),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildImagePickerBox(
                        label: 'ظهر البطاقة',
                        imageUrl: _backImageUrl,
                        isUploading: _isUploadingBack,
                        onTap: () => _pickImage(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.royalGold,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('التالي', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: AppTheme.royalGold, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.royalGold)),
      ),
      validator: (val) => val == null || val.isEmpty ? 'هذا الحقل مطلوب' : null,
    );
  }

  Widget _buildImagePickerBox({required String label, required String? imageUrl, required bool isUploading, required VoidCallback onTap}) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            clipBehavior: Clip.antiAlias,
            child: isUploading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.royalGold))
                : imageUrl == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: AppTheme.royalGold, size: 30),
                        SizedBox(height: 8),
                        Text('اضغط للرفع', style: TextStyle(color: Colors.white24, fontSize: 12)),
                      ],
                    ) 
                  : (kIsWeb || imageUrl.startsWith('http') || imageUrl.startsWith('blob:')
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Image.file(File(imageUrl), fit: BoxFit.cover)),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: const TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
