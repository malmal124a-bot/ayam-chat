import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/host_agency_controller.dart';
import '../controllers/user_controller.dart';

/// "فتح وكالة" form — a user submits their own hosting-agency open request.
/// Fields: agency photo, phone, agency ID, ID card upload. On submit the
/// request goes to the admin for approval/rejection.
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
  String? _photoUrl;
  String? _idCardUrl;
  bool _submitting = false;

  final ImagePicker _picker = ImagePicker();

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

  Future<String> _upload(
      XFile file, HostAgencyController controller, String tag) async {
    if (kIsWeb) return file.path;
    final bytes = await file.readAsBytes();
    return controller.uploadImageBytes(bytes, '$tag.png',
        folder: 'agency_open');
  }

  Future<void> _submit(HostAgencyController controller) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'أكمل جميع الحقول: اسم الوكالة، رقم الهاتف، وآيدي الوكالة'),
            backgroundColor: Colors.orange),
      );
      return;
    }
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
      // Resolve the user's numeric id if the agency id field is left empty.
      var agencyId = _agencyIdController.text.trim();
      if (agencyId.isEmpty) {
        final user = UserController();
        agencyId = user.numericId.trim();
      }
      if (agencyId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('يرجى إدخال آيدي الوكالة (الرقم)'),
              backgroundColor: Colors.orange),
        );
        setState(() => _submitting = false);
        return;
      }

      final photoUrl = await _upload(_photoFile!, controller, 'photo');
      final idCardUrl = await _upload(_idCardFile!, controller, 'idcard');
      if (!mounted) return;

      final result = await controller.submitOpenRequest(
        agencyName: _nameController.text.trim(),
        agencyId: agencyId,
        phone: _phoneController.text.trim(),
        photoUrl: photoUrl,
        idCardUrl: idCardUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result['message']),
            backgroundColor: result['ok'] ? Colors.green : Colors.red),
      );
      if (result['ok'] == true) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الرفع: $e')),
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
        title: Text('فتح وكالة مضيفين',
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
                _buildTextField(_nameController, 'اسم الوكالة', Icons.business),
                const SizedBox(height: 12),
                _buildTextField(_phoneController, 'رقم الهاتف', Icons.phone,
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
                    onPressed: _submitting
                        ? null
                        : () => _submit(context.read<HostAgencyController>()),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: _submitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('التالي',
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

  Widget _buildPhotoPicker(ThemeData theme) {
    return InkWell(
      onTap: _pickPhoto,
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
            child: _photoFile == null
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
      onTap: _pickIdCard,
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
        child: _idCardFile == null
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
