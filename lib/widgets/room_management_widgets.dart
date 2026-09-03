import 'package:flutter/material.dart';
import 'package:ayam_chat/models/mic_seat.dart';
import 'app_icon.dart';

Future<void> showUserProfilePopup(BuildContext context, MicSeat seat) {
  final theme = Theme.of(context);
  final userName = seat.userName ?? 'ضيف الغرفة';
  final flag = seat.index.isEven ? '🇪🇬' : '🇸🇦';
  
  // Updated VIP logic to support 10 levels in the room UI
  final int vipLevel = (seat.index % 11); 
  final String vipLabel = vipLevel > 0 ? 'VIP $vipLevel' : 'عضو';

  return showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [theme.colorScheme.tertiary, theme.colorScheme.secondary]),
                border: Border.all(color: theme.colorScheme.secondary, width: 2),
              ),
              child: const AppIcon('Icons.person', icon: Icons.person, color: Colors.black, size: 44),
            ),
            const SizedBox(height: 12),
            Text('$userName $flag', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Lv.20', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vipLevel >= 1 && vipLevel <= 3)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Image.asset(
                        'assets/vip/vip$vipLevel.png',
                        height: 16,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  Text(
                    vipLabel,
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('ID: ${102488 + seat.index}', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.secondary, foregroundColor: Colors.black),
                child: const Text('أرسل هدية'),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionChip(icon: Icons.mic_off, label: 'كتم', theme: theme),
                _ActionChip(icon: Icons.lock_outline, label: 'قفل', theme: theme),
                _ActionChip(icon: Icons.vertical_align_bottom, label: 'تنزيل', theme: theme),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showMicBottomMenu(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['أخذ المايك', 'كتم المايك', 'مقفل المايك', 'دعوة إلى مايك', 'إلغاء'].map((e) => ListTile(
          title: Center(child: Text(e, style: TextStyle(fontWeight: e == 'إلغاء' ? FontWeight.bold : FontWeight.w500))),
          onTap: () => Navigator.pop(context),
        )).toList(),
      ),
    ),
  );
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;
  const _ActionChip({required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 18),
          const SizedBox(height: 4),
          // Fix: Removed 'const' because 'label' is a dynamic variable.
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
