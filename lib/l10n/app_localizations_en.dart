// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tradee';

  @override
  String get marketsTitle => 'Markets';

  @override
  String get portfolioTitle => 'Portfolio';

  @override
  String get strategyBuilderTitle => 'Strategy Builder';

  @override
  String get riskTitle => 'Risk Management';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get tabPositions => 'Positions';

  @override
  String get tabHistory => 'History';

  @override
  String get loading => 'Loading...';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get noPositions => 'No active positions';

  @override
  String get noHistory => 'No trade history yet';

  @override
  String get buildStrategies => 'Build Multi-leg Strategies';

  @override
  String get buy => 'BUY';

  @override
  String get sell => 'SELL';

  @override
  String get buyLong => 'BUY / LONG';

  @override
  String get sellShort => 'SELL / SHORT';

  @override
  String get closePosition => 'CLOSE POSITION';

  @override
  String get cancelOrder => 'CANCEL ORDER';

  @override
  String get confirm => 'CONFIRM';

  @override
  String get cancel => 'CANCEL';

  @override
  String get marketOrder => 'Market';

  @override
  String get limitOrder => 'Limit';

  @override
  String get limitPrice => 'Limit Price';

  @override
  String get quantity => 'Quantity';

  @override
  String get contracts => 'Contracts';

  @override
  String get bid => 'Bid';

  @override
  String get ask => 'Ask';

  @override
  String get spread => 'Spread';

  @override
  String get iv => 'IV';

  @override
  String get estMargin => 'Est. Margin';

  @override
  String get equity => 'Equity';

  @override
  String get usedMargin => 'Used Margin';

  @override
  String get available => 'Available';

  @override
  String get unrealized => 'Unrealized';

  @override
  String get realized => 'Realized';

  @override
  String get netDelta => 'Net Delta (Δ)';

  @override
  String get netGamma => 'Net Gamma (Γ)';

  @override
  String get netVega => 'Net Vega (ν)';

  @override
  String get netTheta => 'Net Theta (Θ)';

  @override
  String get priceSensitivity => 'Price sensitivity per \$1 move';

  @override
  String get deltaChangeRate => 'Delta change rate';

  @override
  String get volSensitivity => 'Sensitivity to 1% vol change';

  @override
  String get timeDecay => 'Time decay per day';

  @override
  String get stressTest => 'Stress Test';

  @override
  String spotMove(String shift) {
    return 'Spot Move: $shift%';
  }

  @override
  String pnlLabel(String pnl) {
    return 'P&L: $pnl';
  }

  @override
  String get reset => 'Reset';

  @override
  String get marginUtilization => 'Margin Utilization';

  @override
  String get liquidationWarning =>
      'LIQUIDATION TRIGGERED: Positions force-closed at market';

  @override
  String get liquidationSnackbar =>
      'LIQUIDATION: All positions force-closed at market';

  @override
  String get expirySnackbar =>
      'EXPIRY: All positions settled at intrinsic value';

  @override
  String get resetAccount => 'Reset Demo Account';

  @override
  String get resetAccountDesc =>
      'Wipe all positions and reset balance to \$100,000';

  @override
  String get resetConfirmTitle => 'Reset Account?';

  @override
  String get resetConfirmBody =>
      'This will delete all positions, history, and reset balance.';

  @override
  String get resetSuccess => 'Account Reset Successful';

  @override
  String get volatility => 'VOLATILITY';

  @override
  String get rollingVolLabel => 'Rolling Realized Vol (1h window)';

  @override
  String get rollingVolDesc => 'Calculated from live price data';

  @override
  String get fixedVolLabel => 'Fixed 50% IV';

  @override
  String get fixedVolDesc => 'Constant implied volatility for all strikes';

  @override
  String get about => 'ABOUT';

  @override
  String get appName => 'Tradee';

  @override
  String get appSubtitle => 'Crypto Daily Options Simulator';

  @override
  String get pricingModel => 'Pricing Model';

  @override
  String get pricingModelValue => 'Black-Scholes (European)';

  @override
  String get expiry => 'Expiry';

  @override
  String get expiryValue => 'Daily 05:29:59 IST';

  @override
  String get addLeg => 'ADD LEG';

  @override
  String get totalCostCredit => 'Total Cost/Credit';

  @override
  String get maxProfit => 'Max Profit: ';

  @override
  String get maxLoss => 'Max Loss: ';

  @override
  String get calls => 'CALLS';

  @override
  String get puts => 'PUTS';

  @override
  String get strike => 'STRIKE';

  @override
  String get atm => 'ATM';

  @override
  String get pending => 'PENDING';

  @override
  String get longLabel => 'LONG';

  @override
  String get shortLabel => 'SHORT';

  @override
  String get failedToLoadChain => 'Failed to load chain';

  @override
  String get retry => 'Retry';
}
