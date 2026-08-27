import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/agency_controller.dart';
import '../controllers/user_controller.dart';
import '../theme/app_theme.dart';

class ApplyAgencyScreen extends StatefulWidget {
  const ApplyAgencyScreen({super.key});

  @override
  State<ApplyAgencyScreen> createState() => _ApplyAgencyScreenState();
}

class _ApplyAgencyScreenState extends State<ApplyAgencyScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  // Step 1 Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _frontImageUrl;
  String? _backImageUrl;
  bool _isUploadingFront = false;
  bool _isUploadingBack = false;

  // Step 2 Selection
  int? _selectedTier;
  final List<int> _tiers = [500, 1000, 2000, 5000, 10000];

  // Step 3 Payment
  String? _selectedPaymentMethod;
  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'usdt', 'name': 'USDT (TRC20)', 'icon': Icons.currency_bitcoin},
    {'id': 'vodafone', 'name': 'Vodafone Cash', 'icon': Icons.phone_android},
    {'id': 'bank', 'name': 'Bank Transfer', 'icon': Icons.account_balance},
  ];

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
        url = image.path;
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
          SnackBar(content: Text('error_uploading'.tr())),
        );
      }
    } finally {
      setState(() {
        if (isFront) {
          _isUploadingFront = false;
        } else {
          _isUploadingBack = false;
        }
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate() && _frontImageUrl != null && _backImageUrl != null) {
        setState(() => _currentStep++);
      } else if (_frontImageUrl == null || _backImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload ID card photos')),
        );
      }
    } else if (_currentStep == 1) {
      if (_selectedTier != null) {
        setState(() => _currentStep++);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a package')),
        );
      }
    }
  }

  void _finishOnboarding() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    // Process activation
    final controller = context.read<AgencyController>();
    final userController = context.read<UserController>();

    // Submit request data
    await controller.submitAgencyRequest(
      agencyName: 'وكالة ${_nameController.text}',
      personalName: _nameController.text,
      nationalId: 'ID_REF_PENDING',
      phoneNumber: _phoneController.text,
      whatsappLink: _phoneController.text,
      idCardFrontUrl: _frontImageUrl!,
      idCardBackUrl: _backImageUrl!,
    );

    // For demo purposes/logic: Mark user as agent immediately after payment selection
    userController.toggleAgentStatus(true);
    await controller.activateAgency(_selectedTier!);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.card,
          title: Text(tr('success'), style: const TextStyle(color: Colors.green)),
          content: const Text('لقد تم تفعيل الوكالة بنجاح! يمكنك الآن الوصول للوحة التحكم.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to profile
              },
              child: Text(tr('ok'), style: const TextStyle(color: AppTheme.royalGold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.royalPurpleDark,
      appBar: AppBar(
        title: Text('agency_onboarding'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStepContent(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: List.generate(3, (index) {
          bool isActive = index <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.royalGold : Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.white24,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: index < _currentStep ? AppTheme.royalGold : Colors.white10,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('بيانات الهوية والاتصال', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTextField(_nameController, 'الاسم الكامل', Icons.person),
          const SizedBox(height: 15),
          _buildTextField(_phoneController, 'رقم الهاتف', Icons.phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 15),
          _buildTextField(_emailController, 'البريد الإلكتروني', Icons.email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 25),
          const Text('صور البطاقة الشخصية', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 15),
          Row(
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
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اختيار فئة الوكالة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('اختر الباقة المناسبة لبدء العمل كوكيل معتمد', style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 25),
        ..._tiers.map((tier) => _buildTierCard(tier)),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('تأكيد الدفع', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('المبلغ المطلوب: \$$_selectedTier', style: const TextStyle(color: AppTheme.royalGold, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 25),
        const Text('اختر وسيلة الدفع:', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 15),
        ..._paymentMethods.map((method) => _buildPaymentCard(method)),
      ],
    );
  }

  Widget _buildTierCard(int amount) {
    bool isSelected = _selectedTier == amount;
    return GestureDetector(
      onTap: () => setState(() => _selectedTier = amount),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.royalGold.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? AppTheme.royalGold : Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('باقة $amount\$', style: TextStyle(color: isSelected ? AppTheme.royalGold : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('رصيد سيولة متاح للشحن', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.royalGold, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> method) {
    bool isSelected = _selectedPaymentMethod == method['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.green : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(method['icon'], color: isSelected ? Colors.green : Colors.white54, size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                method['name'], 
                style: TextStyle(color: isSelected ? Colors.green : Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.green, size: 18),
          ],
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
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildImagePickerBox({required String label, required String? imageUrl, required bool isUploading, required VoidCallback onTap}) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      child: Column(
        children: [
          Container(
            height: 100,
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
                  ? const Icon(Icons.add_a_photo_outlined, color: AppTheme.royalGold) 
                  : (kIsWeb || imageUrl.startsWith('http') || imageUrl.startsWith('blob:')
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Image.file(File(imageUrl), fit: BoxFit.cover)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    bool isLastStep = _currentStep == 2;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('السابق', style: TextStyle(color: Colors.white54)),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLastStep ? _finishOnboarding : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.royalGold,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isLastStep ? 'تأكيد وتفعيل' : 'التالي',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
