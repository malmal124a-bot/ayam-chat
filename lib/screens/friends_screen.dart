import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('الأصدقاء', style: TextStyle(color: theme.colorScheme.secondary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'قائمة الأصدقاء ستظهر هنا',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 16),
        ),
      ),
    );
  }
}
