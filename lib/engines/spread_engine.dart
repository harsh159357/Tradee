import 'dart:math' as math;
import '../core/constants.dart';

class SpreadResult {
  final double mid;
  final double bid;
  final double ask;
  final double spread;

  const SpreadResult({
    required this.mid,
    required this.bid,
    required this.ask,
    required this.spread,
  });
}

class SpreadEngine {
  static SpreadResult calculate({
    required double midPrice,
    double spreadPercent = AppConstants.baseSpreadPercent,
    double realizedVol = AppConstants.defaultBaseVolatility,
  }) {
    final volRatio = realizedVol / AppConstants.defaultBaseVolatility;
    final volMultiplier = volRatio > 2.0 ? 1.0 + (volRatio - 2.0) * 0.5 : 1.0;
    final adjustedSpread = spreadPercent * volMultiplier;

    final halfSpread = math.max(midPrice * adjustedSpread / 2, AppConstants.minimumTick);
    final bid = math.max(midPrice - halfSpread, AppConstants.minimumTick);
    final ask = midPrice + halfSpread;

    return SpreadResult(
      mid: midPrice,
      bid: bid,
      ask: ask,
      spread: ask - bid,
    );
  }

  static double fillPrice({
    required double midPrice,
    required double quantity,
    double spreadPercent = AppConstants.baseSpreadPercent,
    double slippagePerUnit = AppConstants.slippagePerUnit,
    double realizedVol = AppConstants.defaultBaseVolatility,
  }) {
    final sr = calculate(
      midPrice: midPrice,
      spreadPercent: spreadPercent,
      realizedVol: realizedVol,
    );

    final slippage = (quantity.abs() / 100.0) * slippagePerUnit * midPrice;
    if (quantity > 0) {
      return sr.ask + slippage;
    } else {
      return math.max(sr.bid - slippage, AppConstants.minimumTick);
    }
  }
}
