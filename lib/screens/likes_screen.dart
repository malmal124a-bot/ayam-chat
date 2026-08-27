import 'package:flutter/material.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('الإعجابات', style: TextStyle(color: theme.colorScheme.secondary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'قائمة المعجبين ستظهر هنا',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 16),
        ),
      ),
    );
  }
}
