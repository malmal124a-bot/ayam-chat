import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/broadcast_controller.dart';
import 'app_icon.dart';

class BroadcastTicker extends StatelessWidget {
  const BroadcastTicker({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: BroadcastController(),
      child: Consumer<BroadcastController>(
        builder: (context, controller, child) {
          final currentBroadcast = controller.currentBroadcast;
          
          if (currentBroadcast == null) {
            return const SizedBox.shrink();
          }

          return Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.8),
                  Colors.pink.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const AppIcon(
                  'Icons.campaign', icon: Icons.campaign,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      currentBroadcast.message,
                      key: ValueKey(currentBroadcast.id),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}
