import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/app_icon_service.dart';

/// A configurable icon that can be replaced at runtime from the admin dashboard.
///
/// When an override image URL exists in the dashboard for [iconKey] (via
/// `app_config.iconOverrides`), this widget shows that image as-is; otherwise
/// it falls back to the default Material [icon].
///
/// This widget is [const]-friendly: it reads the current override directly in
/// [build] and relies on the app-wide rebuild (in `main.dart`, which listens
/// to `AppIconService` + `ThemeService` + `ScreenVisualService`) to refresh
/// instantly whenever the admin changes an icon — so the user never has to
/// restart or even notice the update.
class AppIcon extends StatelessWidget {
  /// Registry key matching the admin dashboard icon list (e.g. `Icons.home`).
  final String iconKey;

  /// Default Material icon shown when there is no override.
  final IconData icon;

  final double size;
  final Color? color;
  final BoxFit fit;
  final double? imageWidth;
  final double? imageHeight;

  const AppIcon(
    this.iconKey, {
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.fit = BoxFit.contain,
    this.imageWidth,
    this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    final url = AppIconService.instance.overrideFor(iconKey);
    if (url == null) {
      return Icon(icon, size: size, color: color);
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: imageWidth ?? size,
      height: imageHeight ?? size,
      fit: fit,
      errorWidget: (_, __, ___) => Icon(icon, size: size, color: color),
      placeholder: (_, __) => Icon(icon, size: size, color: color),
    );
  }
}
