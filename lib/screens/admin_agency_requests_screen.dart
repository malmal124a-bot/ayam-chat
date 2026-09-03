import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/agency_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';

class AdminAgencyRequestsScreen extends StatelessWidget {
  const AdminAgencyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AgencyController>();

    return Scaffold(
      backgroundColor: AppTheme.royalPurpleDark,
      appBar: AppBar(
        title: Text('agency_requests'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          if (controller.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.royalGold),
            );
          }

          final requests = controller.pendingRequests;

          if (requests.isEmpty) {
            return Center(
              child: Text(
                'no_pending_requests'.tr(),
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.agencyName,
                      style: TextStyle(color: AppTheme.royalGold, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Owner: ${request.personalName}', style: const TextStyle(color: Colors.white)),
                    Text('ID Number: ${request.nationalId}', style: const TextStyle(color: Colors.white70)),
                    Text('Phone: ${request.phoneNumber}', style: const TextStyle(color: Colors.white70)),
                    Text('WhatsApp: ${request.whatsappLink}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Text(tr('id_card_photos'), style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImagePreview(context, tr('id_front'), request.idCardFrontUrl),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildImagePreview(context, tr('id_back'), request.idCardBackUrl),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => controller.denyRequest(request),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: Text('reject'.tr()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => controller.approveRequest(request),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('approve'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, String label, String? url) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (url != null) {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  child: (kIsWeb || url.startsWith('http'))
                      ? Image.network(url, errorBuilder: (c, e, s) => const AppIcon('Icons.error', icon: Icons.error))
                      : Image.file(File(url), errorBuilder: (c, e, s) => const AppIcon('Icons.error', icon: Icons.error)),
                ),
              );
            }
          },
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: url == null
                ? const Center(child: AppIcon('Icons.image_not_supported', icon: Icons.image_not_supported, color: Colors.white24))
                : (kIsWeb || url.startsWith('http'))
                    ? Image.network(url, fit: BoxFit.cover, errorBuilder: (c, e, s) => const AppIcon('Icons.error', icon: Icons.error))
                    : Image.file(File(url), fit: BoxFit.cover, errorBuilder: (c, e, s) => const AppIcon('Icons.error', icon: Icons.error)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}