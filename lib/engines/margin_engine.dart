import 'dart:math' as math;
import 'pricing_engine.dart';

class MarginEngine {
  /// Initial Balance
  static const double initialBalance = 100000.0;

  /// Long Options: Margin = Premium Paid
  static double calculateLongMargin(double premium, double quantity) {
    return premium * quantity;
  }

  /// Short Options: Margin = worst-case loss using stress test (+/- 5%)
  static double calculateShortMargin({
    required double S,
    required double K,
    required double T,
    required double r,
    required double v,
    required OptionType type,
    required double quantity,
  }) {
    // Stress scenarios
    final sUp = S * 1.05;
    final sDown = S * 0.95;

    final resCurrent = BlackScholesEngine.calculate(S: S, K: K, T: T, r: r, v: v, type: type);
    final resUp = BlackScholesEngine.calculate(S: sUp, K: K, T: T, r: r, v: v, type: type);
    final resDown = BlackScholesEngine.calculate(S: sDown, K: K, T: T, r: r, v: v, type: type);

    // Worst case premium
    final maxPremium = [resCurrent.premium, resUp.premium, resDown.premium].reduce(math.max);
    
    // Minimum margin requirement (e.g., 10% of spot for naked shorts, but we follow spec-like stress test)
    // To be safe, we use the max stressed premium as the margin requirement.
    return maxPremium * quantity;
  }
}
