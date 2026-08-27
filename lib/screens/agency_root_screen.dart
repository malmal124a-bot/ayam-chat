import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';
import '../controllers/agency_controller.dart';
import 'agency_management_screen.dart';
import 'join_agency_screen.dart';

class AgencyRootScreen extends StatelessWidget {
  const AgencyRootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserController>(
      builder: (context, userController, child) {
        return Consumer<AgencyController>(
          builder: (context, agencyController, child) {
            // Check if user is already a member of an agency
            if (agencyController.myAgency != null) {
              // User is already a member, go to management screen
              return const AgencyManagementScreen();
            } else if (userController.isAgent) {
              // User is an agent but no agency assigned, go to join screen
              return const JoinAgencyScreen();
            } else {
              // User is not an agent, go to join screen to find an agency
              return const JoinAgencyScreen();
            }
          },
        );
      },
    );
  }
}
