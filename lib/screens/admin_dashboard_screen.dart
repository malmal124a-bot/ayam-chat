import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../controllers/agency_controller.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard (Agency Requests)'),
        centerTitle: true,
      ),
      body: Consumer<AgencyController>(
        builder: (context, controller, child) {
          final requests = controller.pendingRequests;

          if (requests.isEmpty) {
            return const Center(
              child: Text('No pending requests'),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Agency: ${request.agencyName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text('Owner: ${request.personalName}'),
                      Text('ID: ${request.nationalId}'),
                      Text('Phone: ${request.phoneNumber}'),
                      Text('WhatsApp: ${request.whatsappLink}'),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => controller.rejectRequest(request),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: Text(tr('reject')),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              await controller.approveRequest(request);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Approved ${request.agencyName}')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, 
                              foregroundColor: Colors.white
                            ),
                            child: Text(tr('approve')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
