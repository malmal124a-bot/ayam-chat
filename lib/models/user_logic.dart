import 'dart:math';

enum BadgeType { recharge, gifting, level }

class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int threshold;
  final BadgeType type;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.threshold,
    required this.type,
  });
}

class UserLogic {
  final int totalDiamondsRecharged;
  final int totalGiftsSent;

  UserLogic({
    this.totalDiamondsRecharged = 0,
    this.totalGiftsSent = 0,
  });

  /// Total XP is the sum of diamonds recharged and gifts sent.
  int get totalXP => totalDiamondsRecharged + totalGiftsSent;

  /// Calculates the current level based on total XP.
  /// Formula: XP required for Level L = 50 * L * (L - 1)
  /// This results in a progressive difficulty curve.
  int get currentLevel {
    if (totalXP <= 0) return 1;
    // Solving 50 * L^2 - 50 * L - XP = 0 using quadratic formula
    // L = (50 + sqrt(2500 + 200 * XP)) / 100
    double level = (50 + sqrt(2500 + 200 * totalXP)) / 100;
    return level.floor();
  }

  /// Progress to the next level (0.0 to 1.0)
  double get levelProgress {
    int currentLvl = currentLevel;
    int xpCurrentLevel = 50 * currentLvl * (currentLvl - 1);
    int xpNextLevel = 50 * (currentLvl + 1) * currentLvl;
    
    int xpRequiredForThisLevel = xpNextLevel - xpCurrentLevel;
    int xpGainedInThisLevel = totalXP - xpCurrentLevel;
    
    return (xpGainedInThisLevel / xpRequiredForThisLevel).clamp(0.0, 1.0);
  }

  /// Returns all badges earned by the user.
  List<Badge> get unlockedBadges {
    return allBadges.where((badge) {
      switch (badge.type) {
        case BadgeType.recharge:
          return totalDiamondsRecharged >= badge.threshold;
        case BadgeType.gifting:
          return totalGiftsSent >= badge.threshold;
        case BadgeType.level:
          return currentLevel >= badge.threshold;
      }
    }).toList();
  }

  /// Returns the most prestigious badge currently earned (highest threshold).
  Badge? get currentBadge {
    final unlocked = unlockedBadges;
    if (unlocked.isEmpty) return null;
    return unlocked.reduce((a, b) => a.threshold > b.threshold ? a : b);
  }

  /// Static list of available badges and milestones.
  static const List<Badge> allBadges = [
    // Recharge Milestones
    Badge(
      id: 'recharge_1',
      name: 'Bronze Recharger',
      description: 'Recharged 10k Diamonds',
      iconPath: 'assets/vip/vip1.png',
      threshold: 10000,
      type: BadgeType.recharge,
    ),
    Badge(
      id: 'recharge_2',
      name: 'Silver Recharger',
      description: 'Recharged 100k Diamonds',
      iconPath: 'assets/vip/vip2.png',
      threshold: 100000,
      type: BadgeType.recharge,
    ),
    Badge(
      id: 'recharge_3',
      name: 'Recharge King',
      description: 'Recharged 1M Diamonds',
      iconPath: 'assets/vip/vip3.png',
      threshold: 1000000,
      type: BadgeType.recharge,
    ),

    // Gifting Milestones
    Badge(
      id: 'gift_1',
      name: 'Generous Heart',
      description: 'Sent 50k in Gifts',
      iconPath: 'assets/vip/1.png',
      threshold: 50000,
      type: BadgeType.gifting,
    ),
    Badge(
      id: 'gift_2',
      name: 'Philanthropist',
      description: 'Sent 500k in Gifts',
      iconPath: 'assets/vip/2.png',
      threshold: 500000,
      type: BadgeType.gifting,
    ),
    Badge(
      id: 'gift_3',
      name: 'Super Gifter',
      description: 'Sent 10M in Gifts',
      iconPath: 'assets/vip/3.png',
      threshold: 10000000,
      type: BadgeType.gifting,
    ),

    // Level Milestones
    Badge(
      id: 'level_50',
      name: 'Elite Member',
      description: 'Reached Level 50',
      iconPath: 'assets/vip/12.png',
      threshold: 50,
      type: BadgeType.level,
    ),
    Badge(
      id: 'level_100',
      name: 'Legendary',
      description: 'Reached Level 100',
      iconPath: 'assets/vip/29.png',
      threshold: 100,
      type: BadgeType.level,
    ),
  ];

  UserLogic copyWith({
    int? totalDiamondsRecharged,
    int? totalGiftsSent,
  }) {
    return UserLogic(
      totalDiamondsRecharged: totalDiamondsRecharged ?? this.totalDiamondsRecharged,
      totalGiftsSent: totalGiftsSent ?? this.totalGiftsSent,
    );
  }
}
