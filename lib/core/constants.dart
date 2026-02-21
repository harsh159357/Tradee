class AppConstants {
  AppConstants._();

  static const double riskFreeRate = 0.05;
  static const double initialBalance = 100000.0;
  static const double defaultBaseVolatility = 0.50;
  static const double minimumTick = 0.01;
  static const double baseSpreadPercent = 0.005;
  static const double slippagePerUnit = 0.001;

  static const List<String> supportedAssets = [
    'BTCUSDT',
    'ETHUSDT',
    'SOLUSDT',
  ];

  static const List<double> strikeOffsets = [
    0.95, 0.97, 0.98, 0.99, 1.0, 1.01, 1.02, 1.03, 1.05,
  ];
}
