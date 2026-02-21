import 'dart:math' as math;

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
  static const double _minimumTick = 0.01;
  static const double _baseSpreadPercent = 0.005;
  static const double _defaultBaseVol = 0.50;

  static SpreadResult calculate({
    required double midPrice,
    double spreadPercent = _baseSpreadPercent,
    double realizedVol = _defaultBaseVol,
  }) {
    // Widen spreads under extreme volatility (>2x baseline)
    final volRatio = realizedVol / _defaultBaseVol;
    final volMultiplier = volRatio > 2.0 ? 1.0 + (volRatio - 2.0) * 0.5 : 1.0;
    final adjustedSpread = spreadPercent * volMultiplier;

    final halfSpread = math.max(midPrice * adjustedSpread / 2, _minimumTick);
    final bid = math.max(midPrice - halfSpread, _minimumTick);
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
    double spreadPercent = _baseSpreadPercent,
    double slippagePerUnit = 0.001,
    double realizedVol = _defaultBaseVol,
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
      return math.max(sr.bid - slippage, _minimumTick);
    }
  }
}
