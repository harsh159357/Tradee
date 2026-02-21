import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../domain/margin_status.dart';
import '../domain/position.dart';
import 'market_state.dart';
import 'portfolio_state.dart';
import '../engines/pricing_engine.dart';
import '../engines/margin_engine.dart';
import '../engines/spread_engine.dart';
import '../engines/volatility_engine.dart';

export '../domain/margin_status.dart';

class NetGreeks {
  final double delta;
  final double gamma;
  final double vega;
  final double theta;

  const NetGreeks({this.delta = 0, this.gamma = 0, this.vega = 0, this.theta = 0});
}

class PositionMark {
  final double premium;
  final double iv;
  final double pnl;

  const PositionMark({required this.premium, required this.iv, required this.pnl});
}

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
  final availableMargin = equity - totalMarginRequired;
  final hasFilledPositions = positions.any((p) => p.isFilled);
  final isLiquidated = equity < totalMarginRequired && hasFilledPositions;

  return MarginStatus(
    equity: equity,
    maintenanceMargin: totalMarginRequired,
    availableMargin: availableMargin,
    unrealizedPnL: totalUnrealizedPnL,
    isLiquidated: isLiquidated,
  );
});

final netGreeksProvider = Provider<NetGreeks>((ref) {
  final positions = ref.watch(portfolioProvider);
  final prices = ref.watch(pricesProvider).value ?? {};
  final t = ref.watch(tValueProvider).value ?? 0.0;
  final rollingVols = ref.watch(rollingVolatilityProvider);

  double nd = 0, ng = 0, nv = 0, nt = 0;

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

    nd += res.delta * pos.quantity;
    ng += res.gamma * pos.quantity;
    nv += res.vega * pos.quantity;
    nt += res.theta * pos.quantity;
  }

  return NetGreeks(delta: nd, gamma: ng, vega: nv, theta: nt);
});

final stressedPnLProvider = Provider.family<double, double>((ref, stressShift) {
  if (stressShift == 0) return 0.0;

  final positions = ref.watch(portfolioProvider);
  final prices = ref.watch(pricesProvider).value ?? {};
  final t = ref.watch(tValueProvider).value ?? 0.0;
  final rollingVols = ref.watch(rollingVolatilityProvider);

  double pnl = 0;
  for (final pos in positions) {
    if (!pos.isFilled) continue;
    final spot = prices[pos.symbol] ?? 0.0;
    if (spot == 0) continue;

    final baseVol = rollingVols[pos.symbol] ?? AppConstants.defaultBaseVolatility;
    final iv = VolatilityEngine(baseVolatility: baseVol).calculateIV(
      S: spot, K: pos.strike, T: t,
    );
    final stressedSpot = spot * (1 + stressShift / 100);
    final stressedRes = BlackScholesEngine.calculate(
      S: stressedSpot, K: pos.strike, T: t, r: AppConstants.riskFreeRate, v: iv,
      type: pos.type == 'call' ? OptionType.call : OptionType.put,
    );
    pnl += (stressedRes.premium - pos.entryPrice) * pos.quantity;
  }

  return pnl;
});

final positionMarksProvider = Provider<Map<String, PositionMark>>((ref) {
  final positions = ref.watch(portfolioProvider);
  final prices = ref.watch(pricesProvider).value ?? {};
  final t = ref.watch(tValueProvider).value ?? 0.0;
  final rollingVols = ref.watch(rollingVolatilityProvider);

  final marks = <String, PositionMark>{};
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
    marks[pos.id] = PositionMark(
      premium: res.premium,
      iv: iv,
      pnl: (res.premium - pos.entryPrice) * pos.quantity,
    );
  }
  return marks;
});

/// Force-close exit prices use worst bid/ask per the spec:
/// Long positions exit at bid (worst for seller), short at ask (worst for buyer).
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
    final spread = SpreadEngine.calculate(
      midPrice: res.premium,
      realizedVol: baseVol,
    );

    // Long positions close at bid (worst for seller)
    // Short positions close at ask (worst for buyer-back)
    exitPrices[pos.id] = pos.quantity > 0 ? spread.bid : spread.ask;
  }
  return exitPrices;
}
