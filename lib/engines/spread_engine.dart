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

  static SpreadResult calculate({
    required double midPrice,
    double spreadPercent = 0.005,
  }) {
    final halfSpread = math.max(midPrice * spreadPercent / 2, _minimumTick);
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
    double spreadPercent = 0.005,
    double slippagePerUnit = 0.001,
  }) {
    final sr = calculate(midPrice: midPrice, spreadPercent: spreadPercent);

    final slippage = (quantity.abs() / 100.0) * slippagePerUnit * midPrice;
    if (quantity > 0) {
      return sr.ask + slippage;
    } else {
      return math.max(sr.bid - slippage, _minimumTick);
    }
  }
}
