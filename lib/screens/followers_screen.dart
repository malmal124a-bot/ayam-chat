import 'package:flutter/material.dart';

class FollowersScreen extends StatelessWidget {
  const FollowersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('المتابعين', style: TextStyle(color: theme.colorScheme.secondary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'قائمة المتابعين ستظهر هنا',
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16),
        ),
      ),
    );
  }
}
