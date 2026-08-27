import 'package:flutter/material.dart';
import 'app_theme.dart';

class VIPStyle {
  final Color primaryColor;
  final LinearGradient gradient;
  final Color textColor;
  final bool hasGlow;

  VIPStyle({
    required this.primaryColor,
    required this.gradient,
    required this.textColor,
    this.hasGlow = false,
  });
}

class VIPStyleManager {
  static VIPStyle getStyle(int vipLevel) {
    if (vipLevel <= 0) {
      return VIPStyle(
        primaryColor: AppTheme.vipGrey,
        gradient: const LinearGradient(colors: [AppTheme.vipGrey, Colors.blueGrey]),
        textColor: Colors.white,
      );
    } else if (vipLevel < 5) {
      // VIP 1-4: Bronze/Blue theme
      return VIPStyle(
        primaryColor: AppTheme.vipBlue,
        gradient: const LinearGradient(colors: [AppTheme.vipBlue, AppTheme.vipLightBlue]),
        textColor: Colors.blue.shade900,
      );
    } else if (vipLevel < 10) {
      // VIP 5-9: Purple/Silver theme
      return VIPStyle(
        primaryColor: AppTheme.vipPurple,
        gradient: const LinearGradient(colors: [AppTheme.vipPurple, AppTheme.vipDeepPurple]),
        textColor: Colors.purple.shade900,
        hasGlow: true,
      );
    } else if (vipLevel < 20) {
      // VIP 10-19: Gold theme
      return VIPStyle(
        primaryColor: AppTheme.vipAmber,
        gradient: const LinearGradient(colors: [AppTheme.vipAmber, AppTheme.vipOrange]),
        textColor: Colors.orange.shade900,
        hasGlow: true,
      );
    } else {
      // VIP 20+: Red/Legendary theme
      return VIPStyle(
        primaryColor: AppTheme.vipRed,
        gradient: const LinearGradient(colors: [AppTheme.vipRed, AppTheme.vipDeepOrange]),
        textColor: Colors.white,
        hasGlow: true,
      );
    }
  }

  static List<BoxShadow> getGlow(int vipLevel) {
    final style = getStyle(vipLevel);
    if (!style.hasGlow) return [];
    return [
      BoxShadow(
        color: style.primaryColor.withValues(alpha: 0.5),
        blurRadius: 10,
        spreadRadius: 2,
      )
    ];
  }
}
