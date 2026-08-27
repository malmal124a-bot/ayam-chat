import 'package:flutter/material.dart';

class RoomControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  const RoomControlButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 58,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: highlighted ? theme.colorScheme.secondary.withValues(alpha: 0.16) : theme.cardColor.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: highlighted ? theme.colorScheme.secondary : theme.colorScheme.secondary.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: highlighted ? theme.colorScheme.secondary : theme.colorScheme.onSurface, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: highlighted ? theme.colorScheme.secondary : theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
