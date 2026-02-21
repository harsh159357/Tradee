import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../domain/margin_status.dart';
import '../domain/position.dart';
import 'market_state.dart';
import 'portfolio_state.dart';
import '../engines/pricing_engine.dart';
import '../engines/margin_engine.dart';
import '../engines/volatility_engine.dart';

export '../domain/margin_status.dart';

final marginStatusProvider = Provider<MarginStatus>((ref) {
  final balance = ref.watch(balanceProvider);
  final positions = ref.watch(portfolioProvider);
  final prices = ref.watch(pricesProvider).value ?? {};
  final t = ref.watch(tValueProvider).value ?? 0.0;
  final rollingVols = ref.watch(rollingVolatilityProvider);

  double totalUnrealizedPnL = 0;
  double totalMarginRequired = 0;

  for (final pos in positions) {
    if (!pos.isFilled) continue;

    final spot = prices[pos.symbol] ?? 0.0;
    if (spot == 0) continue;

    final baseVol = rollingVols[pos.symbol] ?? AppConstants.defaultBaseVolatility;
    final iv = VolatilityEngine(baseVolatility: baseVol).calculateIV(
      S: spot, K: pos.strike, T: t,
    );

    final currentRes = BlackScholesEngine.calculate(
      S: spot, K: pos.strike, T: t, r: AppConstants.riskFreeRate, v: iv,
      type: pos.type == 'call' ? OptionType.call : OptionType.put,
    );

    totalUnrealizedPnL += (currentRes.premium - pos.entryPrice) * pos.quantity;

    if (pos.quantity > 0) {
      totalMarginRequired += currentRes.premium * pos.quantity;
    } else {
      totalMarginRequired += MarginEngine.calculateShortMargin(
        S: spot, K: pos.strike, T: t, r: AppConstants.riskFreeRate, v: iv,
        type: pos.type == 'call' ? OptionType.call : OptionType.put,
        quantity: pos.quantity.abs(),
      );
    }
  }

  final equity = balance + totalUnrealizedPnL;
  final hasFilledPositions = positions.any((p) => p.isFilled);
  final isLiquidated = equity < totalMarginRequired && hasFilledPositions;

  return MarginStatus(
    equity: equity,
    maintenanceMargin: totalMarginRequired,
    unrealizedPnL: totalUnrealizedPnL,
    isLiquidated: isLiquidated,
  );
});

Map<String, double> calculateExitPrices(
  List<Position> positions,
  Map<String, double> prices,
  double t,
  Map<String, double> rollingVols,
) {
  final exitPrices = <String, double>{};
  for (final pos in positions) {
    if (!pos.isFilled) continue;
    final spot = prices[pos.symbol] ?? 0.0;
    if (spot == 0) continue;

    final baseVol = rollingVols[pos.symbol] ?? AppConstants.defaultBaseVolatility;
    final iv = VolatilityEngine(baseVolatility: baseVol).calculateIV(
      S: spot, K: pos.strike, T: t,
    );
    final res = BlackScholesEngine.calculate(
      S: spot, K: pos.strike, T: t, r: AppConstants.riskFreeRate, v: iv,
      type: pos.type == 'call' ? OptionType.call : OptionType.put,
    );
    exitPrices[pos.id] = res.premium;
  }
  return exitPrices;
}
