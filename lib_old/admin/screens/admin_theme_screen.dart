import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/admin_auth_controller.dart';

class AdminThemeScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  
  const AdminThemeScreen({
    super.key,
    required this.adminAuthController,
  });

  @override
  State<AdminThemeScreen> createState() => _AdminThemeScreenState();
}

class _AdminThemeScreenState extends State<AdminThemeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Theme Configuration
  String _primaryColor = '#2196F3';
  String _secondaryColor = '#FF9800';
  String _backgroundColor = '#FFFFFF';
  String _textColor = '#000000';
  String _bannerImageUrl = '';
  String _promoCardTitle = '';
  String _promoCardSubtitle = '';
  String _promoCardImageUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemeConfig();
  }

  Future<void> _loadThemeConfig() async {
    try {
      final doc = await _firestore.collection('app_config').doc('theme').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _primaryColor = data['primaryColor'] as String? ?? '#2196F3';
          _secondaryColor = data['secondaryColor'] as String? ?? '#FF9800';
          _backgroundColor = data['backgroundColor'] as String? ?? '#FFFFFF';
          _textColor = data['textColor'] as String? ?? '#000000';
          _bannerImageUrl = data['bannerImageUrl'] as String? ?? '';
          _promoCardTitle = data['promoCardTitle'] as String? ?? '';
          _promoCardSubtitle = data['promoCardSubtitle'] as String? ?? '';
          _promoCardImageUrl = data['promoCardImageUrl'] as String? ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading theme config: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveThemeConfig() async {
    try {
      await _firestore.collection('app_config').doc('theme').set({
        'primaryColor': _primaryColor,
        'secondaryColor': _secondaryColor,
        'backgroundColor': _backgroundColor,
        'textColor': _textColor,
        'bannerImageUrl': _bannerImageUrl,
        'promoCardTitle': _promoCardTitle,
        'promoCardSubtitle': _promoCardSubtitle,
        'promoCardImageUrl': _promoCardImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('theme_saved'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving theme config: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('save_failed'.tr(namedArgs: {'error': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_design_theme'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'color_scheme'.tr(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          _buildColorField('primary_color'.tr(), _primaryColor, (value) {
                            setState(() => _primaryColor = value);
                          }),
                          const SizedBox(height: 16),
                          _buildColorField('secondary_color'.tr(), _secondaryColor, (value) {
                            setState(() => _secondaryColor = value);
                          }),
                          const SizedBox(height: 16),
                          _buildColorField('background_color'.tr(), _backgroundColor, (value) {
                            setState(() => _backgroundColor = value);
                          }),
                          const SizedBox(height: 16),
                          _buildColorField('text_color'.tr(), _textColor, (value) {
                            setState(() => _textColor = value);
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'banner_config'.tr(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'banner_image_url'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() => _bannerImageUrl = value);
                            },
                            controller: TextEditingController(text: _bannerImageUrl),
                          ),
                          if (_bannerImageUrl.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _bannerImageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150,
                                    color: Colors.grey.shade200,
                                    child: const Center(child: Text('Image Error')),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'promo_card_config'.tr(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'promo_card_title'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() => _promoCardTitle = value);
                            },
                            controller: TextEditingController(text: _promoCardTitle),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'promo_card_subtitle'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() => _promoCardSubtitle = value);
                            },
                            controller: TextEditingController(text: _promoCardSubtitle),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'promo_card_image_url'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() => _promoCardImageUrl = value);
                            },
                            controller: TextEditingController(text: _promoCardImageUrl),
                          ),
                          if (_promoCardImageUrl.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _promoCardImageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150,
                                    color: Colors.grey.shade200,
                                    child: const Center(child: Text('Image Error')),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveThemeConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('save_changes'.tr()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildColorField(String label, String value, Function(String) onChanged) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              hintText: '#FFFFFF',
            ),
            onChanged: onChanged,
            controller: TextEditingController(text: value),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _parseColor(value),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }
}
