class MarginStatus {
  final double equity;
  final double maintenanceMargin;
  final double availableMargin;
  final double unrealizedPnL;
  final bool isLiquidated;

  const MarginStatus({
    required this.equity,
    required this.maintenanceMargin,
    required this.availableMargin,
    required this.unrealizedPnL,
    required this.isLiquidated,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarginStatus &&
          equity == other.equity &&
          maintenanceMargin == other.maintenanceMargin &&
          availableMargin == other.availableMargin &&
          unrealizedPnL == other.unrealizedPnL &&
          isLiquidated == other.isLiquidated;

  @override
  int get hashCode => Object.hash(
      equity, maintenanceMargin, availableMargin, unrealizedPnL, isLiquidated);
}
