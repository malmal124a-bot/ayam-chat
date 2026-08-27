class WalletLogic {
  final int diamonds;

  WalletLogic({
    this.diamonds = 0,
  });

  WalletLogic copyWith({
    int? diamonds,
  }) {
    return WalletLogic(
      diamonds: diamonds ?? this.diamonds,
    );
  }

  /// Calculates how many bonus diamonds are earned from a recharge.
  /// Example: 10% bonus diamonds on recharge.
  int calculateBonusDiamonds(int rechargeAmount) {
    return (rechargeAmount * 0.1).floor();
  }
}
