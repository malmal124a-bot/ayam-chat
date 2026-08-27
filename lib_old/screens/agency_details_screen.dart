import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../controllers/agency_controller.dart';
import '../models/agency_model.dart';
import '../theme/app_theme.dart';

class AgencyDetailsScreen extends StatelessWidget {
  final String agencyId;

  const AgencyDetailsScreen({super.key, required this.agencyId});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AgencyController>();
    final agency = controller.findAgencyById(agencyId);

    if (agency == null) {
      return Scaffold(
        backgroundColor: AppTheme.royalPurpleDark,
        appBar: AppBar(title: Text(tr('error')), backgroundColor: Colors.transparent),
        body: Center(child: Text(tr('no_data'), style: const TextStyle(color: Colors.white24))),
      );
    }

    final bool isOwner = controller.myAgency?.id == agency.id;
    final bool isMember = agency.members.any((m) => m.userId == "user_id");

    return Scaffold(
      backgroundColor: AppTheme.royalPurpleDark,
      appBar: AppBar(
        title: Text(agency.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.5), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.card,
                      child: Text(
                        agency.name[0],
                        style: const TextStyle(fontSize: 40, color: AppTheme.royalGold, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    agency.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.royalGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'ID: ${agency.id} • ${agency.members.length} ${tr('member')}',
                      style: const TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildSectionTitle(tr('description')),
            const SizedBox(height: 12),
            Text(
              agency.description,
              style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(tr('agency_type')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    agency.agencyType == AgencyType.charging ? Icons.bolt_rounded : Icons.people_outline,
                    color: AppTheme.royalGold,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    agency.agencyType == AgencyType.charging ? tr('charging_agency') : tr('host_agency'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            if (!isOwner && !isMember)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.requestToJoinAgency(agency.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('join_request_sent'))),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.royalGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    tr('request_to_join'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              )
            else if (isMember)
              const Center(
                child: Text('Already a member', style: TextStyle(color: Colors.white38)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.royalGold),
    );
  }
}
