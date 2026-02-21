class AppConstants {
  AppConstants._();

  // Pricing
  static const double riskFreeRate = 0.05;
  static const double initialBalance = 100000.0;
  static const double defaultBaseVolatility = 0.50;
  static const double minimumTick = 0.01;
  static const double baseSpreadPercent = 0.005;
  static const double slippagePerUnit = 0.001;

  // ATM detection threshold (fraction of spot)
  static const double atmThreshold = 0.015;

  // Strategy chart price range factor
  static const double chartRangeMin = 0.80;
  static const double chartRangeMax = 1.20;
  static const double chartPayoffRangeMin = 0.90;
  static const double chartPayoffRangeMax = 1.10;

  // WebSocket / Network
  static const Duration reconnectBaseDelay = Duration(seconds: 5);
  static const Duration reconnectMaxDelay = Duration(seconds: 60);
  static const Duration heartbeatInterval = Duration(seconds: 15);
  static const Duration heartbeatTimeout = Duration(seconds: 30);
  static const Duration restFallbackInterval = Duration(seconds: 10);
  static const Duration restTimeout = Duration(seconds: 5);
  static const Duration debounceInterval = Duration(milliseconds: 250);

  // Assets
  static const List<String> supportedAssets = [
    'BTCUSDT',
    'ETHUSDT',
    'SOLUSDT',
  ];

  // Strike chain
  static const List<double> strikeOffsets = [
    0.95, 0.97, 0.98, 0.99, 1.0, 1.01, 1.02, 1.03, 1.05,
  ];
}
