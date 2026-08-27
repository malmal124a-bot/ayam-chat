import 'package:flutter/material.dart';
import '../services/screen_visual_service.dart';
import '../services/theme_service.dart';

/// Wraps any screen's body with background image/color from the admin dashboard.
///
/// Usage:
/// ```dart
/// ScreenVisualWrapper(
///   screenKey: 'store',
///   child: YourScreenContent(),
/// )
/// ```
class ScreenVisualWrapper extends StatelessWidget {
  final String screenKey;
  final Widget child;

  const ScreenVisualWrapper({
    super.key,
    required this.screenKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ScreenVisualService.instance,
      builder: (context, _) {
        final visual = ScreenVisualService.instance.getScreen(screenKey);
        return Container(
          decoration: BoxDecoration(
            color: visual.backgroundImage.isEmpty
                ? visual.headerBgColor
                : null,
            image: visual.backgroundImage.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(visual.backgroundImage),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  )
                : null,
          ),
          child: child,
        );
      },
    );
  }
}

/// A themed header/app bar that reads from ScreenVisualService.
class ScreenVisualAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String screenKey;
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const ScreenVisualAppBar({
    super.key,
    required this.screenKey,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ScreenVisualService.instance,
      builder: (context, _) {
        final visual = ScreenVisualService.instance.getScreen(screenKey);
        return AppBar(
          title: Text(
            ThemeService.instance.getScreenTitle(screenKey, title),
            style: TextStyle(color: visual.headerTextColor),
          ),
          backgroundColor: visual.headerBgColor,
          foregroundColor: visual.headerTextColor,
          elevation: 0,
          centerTitle: true,
          leading: leading,
          actions: actions,
        );
      },
    );
  }
}

/// Helper to get current screen visual colors without building a widget.
/// Useful for inline code in screen state.
class ScreenColors {
  /// Get a visual for a screen key (convenience shortcut).
  static ScreenVisual of(String screenKey) =>
      ScreenVisualService.instance.getScreen(screenKey);
}
