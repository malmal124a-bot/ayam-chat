import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/host_agency_controller.dart';
import '../services/cloudinary_service.dart';

/// "فتح وكالة" form — a user submits their own hosting-agency open request.
/// Fields: agency photo, agency name, agency ID (numeric), WhatsApp number,
/// ID card upload. On submit the request goes to the admin for approval.
/// Submits directly to Supabase (bypasses backend API auth issues).
class AgencyOpenRequestScreen extends StatefulWidget {
  const AgencyOpenRequestScreen({super.key});

  @override
  State<AgencyOpenRequestScreen> createState() =>
      _AgencyOpenRequestScreenState();
}

class _AgencyOpenRequestScreenState extends State<AgencyOpenRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _agencyIdController = TextEditingController();

  XFile? _photoFile;
  XFile? _idCardFile;
  bool _submitting = false;
  bool _uploadingPhoto = false;
  bool _uploadingIdCard = false;
  String _agencyType = 'shipping'; // shipping | hosting | mixed

  final ImagePicker _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _agencyIdController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _photoFile = image);
  }

  Future<void> _pickIdCard() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _idCardFile = image);
  }

  Future<String?> _uploadImage(XFile file, String tag) async {
    try {
      if (kIsWeb) return file.path;
      final bytes = await file.readAsBytes();
      return await CloudinaryService.uploadImageBytes(bytes,
          fileName: '$tag.png', folder: 'agency_open');
    } catch (e) {
      debugPrint('AgencyOpenRequest: upload $tag failed: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    // Check if user is logged in
    final session = _supabase.auth.currentSession;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى تسجيل الدخول أولاً'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Validate form fields
    if (!_formKey.currentState!.validate()) return;

    // Validate images
    if (_photoFile == null || _idCardFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى رفع صورة الوكالة وصورة الهوية'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final agencyId = _agencyIdController.text.trim();
      if (agencyId.isEmpty) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('يرجى إدخال آيدي الوكالة (الرقم)'),
              backgroundColor: Colors.orange),
        );
        return;
      }

      // Upload images
      setState(() {
        _uploadingPhoto = true;
        _uploadingIdCard = true;
      });

      final photoUrl = await _uploadImage(_photoFile!, 'agency_photo');
      if (mounted) setState(() => _uploadingPhoto = false);

      final idCardUrl = await _uploadImage(_idCardFile!, 'id_card');
      if (mounted) setState(() => _uploadingIdCard = false);

      if (!mounted) return;

      // Submit directly to Supabase (bypasses backend API)
      final uid = session.user.id;
      try {
        final data = await _supabase
            .from('agency_open_requests')
            .insert({
              'requested_by': uid,
              'agency_name': _nameController.text.trim(),
              'agency_id': agencyId,
              'phone': _phoneController.text.trim(),
              'photo_url': photoUrl ?? '',
              'id_card_url': idCardUrl ?? '',
              'agency_type': _agencyType,
              'status': 'pending',
            })
            .select()
            .single();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم إرسال طلبك بنجاح، جاري مراجعة الإدارة'),
              backgroundColor: Colors.green),
        );

        // Refresh the controller so the pending status shows
        try {
          if (mounted) context.read<HostAgencyController>().refresh();
        } catch (_) {}

        if (mounted) Navigator.of(context).pop(true);
      } catch (dbError) {
        if (!mounted) return;
        final errMsg = dbError.toString().replaceAll(RegExp(r'Exception: |PostgrestException: '), '');
        debugPrint('AgencyOpenRequest: Supabase insert error: $dbError');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('AgencyOpenRequest: submit error: $e');
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('فتح وكالة',
            style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'بيانات الوكالة',
                  style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'املأ البيانات وارفع صورة الوكالة والهوية، ثم سيتم إرسال طلبك لمراجعة الإدارة.',
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12),
                ),
                const SizedBox(height: 20),
                _buildPhotoPicker(theme),
                const SizedBox(height: 20),
                _buildTypeSelector(theme),
                const SizedBox(height: 16),
                _buildTextField(_nameController, 'اسم الوكالة', Icons.business),
                const SizedBox(height: 12),
                _buildTextField(_phoneController, 'رقم الواتساب', Icons.message,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildTextField(_agencyIdController, 'آيدي الوكالة (الرقم)',
                    Icons.tag,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 24),
                const Text('صورة الهوية',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _buildIdCardPicker(theme),
                const SizedBox(height: 30),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: _submitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('إرسال الطلب',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'بعد الإرسال ستظهر لك رسالة "انتظر جاري الموافقة من قبل الإدارة".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    const options = [
      ('shipping', '🚚 وكالة شحن ماس', 'ترسل الشحنات والرواتب للمستخدمين'),
      ('hosting', '🏠 وكالة استضافة', 'تستضيف الأعضاء وكسب الأرباح معهم'),
      ('mixed', '🔀 مختلطة', 'شحن + استضافة معاً'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('نوع الوكالة',
            style: TextStyle(
                color: theme.colorScheme.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...options.map((o) {
          final selected = _agencyType == o.$1;
          return GestureDetector(
            onTap: () => setState(() => _agencyType = o.$1),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.secondary.withValues(alpha: 0.12)
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.secondary.withValues(alpha: 0.18),
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(o.$1 == 'shipping' ? Icons.local_shipping_outlined
                      : o.$1 == 'hosting' ? Icons.house_outlined : Icons.sync_alt,
                      color: selected
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.$2,
                            style: TextStyle(
                                color: selected
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(o.$3,
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.45),
                                fontSize: 10)),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle,
                        color: theme.colorScheme.secondary, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPhotoPicker(ThemeData theme) {
    return InkWell(
      onTap: _uploadingPhoto ? null : _pickPhoto,
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _uploadingPhoto
                ? Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary))
                : _photoFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 40,
                              color: theme.colorScheme.secondary
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text('اضغط لرفع صورة الوكالة',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4))),
                        ],
                      )
                    : kIsWeb
                        ? Image.network(_photoFile!.path, fit: BoxFit.cover)
                        : Image.file(File(_photoFile!.path), fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  Widget _buildIdCardPicker(ThemeData theme) {
    return InkWell(
      onTap: _uploadingIdCard ? null : _pickIdCard,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: theme.colorScheme.secondary.withValues(alpha: 0.15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: _uploadingIdCard
            ? Center(child: CircularProgressIndicator(color: theme.colorScheme.secondary))
            : _idCardFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined,
                          size: 34,
                          color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text('اضغط لرفع صورة الهوية',
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4))),
                    ],
                  )
                : kIsWeb
                    ? Image.network(_idCardFile!.path, fit: BoxFit.cover)
                    : Image.file(File(_idCardFile!.path), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon,
      {TextInputType? keyboardType}) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: theme.colorScheme.secondary),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.2))),
      ),
      validator: (val) =>
          (val == null || val.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
    );
  }
}
