import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/relationship_controller.dart';
import '../models/relationship.dart';
import 'app_icon.dart';

class FriendRequestsNotification extends StatelessWidget {
  const FriendRequestsNotification({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: RelationshipController(),
      child: Consumer<RelationshipController>(
        builder: (context, controller, child) {
          final pendingRequests = controller.getPendingRequestsForUser(
            controller.currentUserId ?? 'user1',
          );

          if (pendingRequests.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.withValues(alpha: 0.1),
                  Colors.purple.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.pink.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppIcon('Icons.person_add', icon: Icons.person_add, color: Colors.pink, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'طلبات الصداقة (${pendingRequests.length})',
                      style: const TextStyle(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...pendingRequests.take(3).map((request) => _buildRequestItem(
                  context,
                  request,
                  controller,
                )),
                if (pendingRequests.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+${pendingRequests.length - 3} طلبات أخرى',
                      style: TextStyle(
                        color: Colors.pink.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestItem(
    BuildContext context,
    FriendRequest request,
    RelationshipController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.pink.withValues(alpha: 0.2),
            child: Text(
              request.fromUserName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.pink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.fromUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'يريد الارتباط بك',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  final success = await controller.acceptFriendRequest(request.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'تم قبول طلب الصداقة! 🎉'
                              : 'فشل قبول الطلب',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                icon: const AppIcon('Icons.check', icon: Icons.check, color: Colors.green, size: 20),
              ),
              IconButton(
                onPressed: () async {
                  final success = await controller.rejectFriendRequest(request.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'تم رفض طلب الصداقة'
                              : 'فشل رفض الطلب',
                        ),
                        backgroundColor: success ? Colors.orange : Colors.red,
                      ),
                    );
                  }
                },
                icon: const AppIcon('Icons.close', icon: Icons.close, color: Colors.red, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
