import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/admin_auth_controller.dart';
import '../controllers/admin_rbac_controller.dart';

class AdminLuckRatiosScreen extends StatefulWidget {
  final AdminAuthController adminAuthController;
  
  const AdminLuckRatiosScreen({
    super.key,
    required this.adminAuthController,
  });

  @override
  State<AdminLuckRatiosScreen> createState() => _AdminLuckRatiosScreenState();
}

class _AdminLuckRatiosScreenState extends State<AdminLuckRatiosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _rbacController = AdminRBACController();
  
  double _luckGiftsRTP = 95.0;
  double _cpGiftsRTP = 90.0;
  double _miniGamesRTP = 92.0;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRatios();
  }

  Future<void> _loadRatios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await _firestore
          .collection('system_config')
          .doc('game_ratios')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _luckGiftsRTP = (data['luckGiftsRTP'] as num?)?.toDouble() ?? 95.0;
          _cpGiftsRTP = (data['cpGiftsRTP'] as num?)?.toDouble() ?? 90.0;
          _miniGamesRTP = (data['miniGamesRTP'] as num?)?.toDouble() ?? 92.0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading ratios: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRatios() async {
    if (!_rbacController.hasPermission(
      widget.adminAuthController.currentUserRole!,
      RBACAction.adjustRTP,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient permissions to adjust RTP ratios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore
          .collection('system_config')
          .doc('game_ratios')
          .set({
        'luckGiftsRTP': _luckGiftsRTP,
        'cpGiftsRTP': _cpGiftsRTP,
        'miniGamesRTP': _miniGamesRTP,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': widget.adminAuthController.currentUserId,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('RTP ratios saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save RTP ratios: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('luck_ratios'.tr()),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveRatios,
              tooltip: 'Save Ratios',
            ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'RTP (Return to Player) ratios control the win-rate return percentages for games and gifts. Lower values favor the system, higher values favor players.',
                                style: TextStyle(color: Colors.blue.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Luck Gifts RTP
                    _buildRatioCard(
                      title: 'luck_gifts_rtp'.tr(),
                      value: _luckGiftsRTP,
                      icon: Icons.card_giftcard,
                      color: Colors.purple,
                      onChanged: (value) {
                        setState(() => _luckGiftsRTP = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // CP Gifts RTP
                    _buildRatioCard(
                      title: 'cp_gifts_rtp'.tr(),
                      value: _cpGiftsRTP,
                      icon: Icons.emoji_events,
                      color: Colors.amber,
                      onChanged: (value) {
                        setState(() => _cpGiftsRTP = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Mini Games RTP
                    _buildRatioCard(
                      title: 'mini_games_rtp'.tr(),
                      value: _miniGamesRTP,
                      icon: Icons.casino,
                      color: Colors.green,
                      onChanged: (value) {
                        setState(() => _miniGamesRTP = value);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Quick Presets
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Presets',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildPresetChip('Conservative (80%)', 80.0),
                                _buildPresetChip('Balanced (90%)', 90.0),
                                _buildPresetChip('Generous (95%)', 95.0),
                                _buildPresetChip('High (98%)', 98.0),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveRatios,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: Text('save'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRatioCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Slider(
              value: value,
              min: 50.0,
              max: 100.0,
              divisions: 50,
              label: '${value.toStringAsFixed(1)}%',
              activeColor: color,
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '50%',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    '${value.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  '100%',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double value) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _luckGiftsRTP = value;
          _cpGiftsRTP = value;
          _miniGamesRTP = value;
        });
      },
    );
  }
}
