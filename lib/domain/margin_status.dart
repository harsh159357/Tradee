class MarginStatus {
  final double equity;
  final double maintenanceMargin;
  final double unrealizedPnL;
  final bool isLiquidated;

  MarginStatus({
    required this.equity,
    required this.maintenanceMargin,
    required this.unrealizedPnL,
    required this.isLiquidated,
  });
}
