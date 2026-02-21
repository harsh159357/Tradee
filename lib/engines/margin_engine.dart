import 'dart:math' as math;
import '../core/constants.dart';
import 'pricing_engine.dart';

class MarginEngine {
  static double calculateLongMargin(double premium, double quantity) {
    return premium * quantity;
  }

  /// Stress test: calculate worst-case loss across spot +/-5% scenarios
  static double calculateShortMargin({
    required double S,
    required double K,
    required double T,
    required double r,
    required double v,
    required OptionType type,
    required double quantity,
  }) {
    final sUp = S * 1.05;
    final sDown = S * 0.95;

    final resCurrent = BlackScholesEngine.calculate(S: S, K: K, T: T, r: r, v: v, type: type);
    final resUp = BlackScholesEngine.calculate(S: sUp, K: K, T: T, r: r, v: v, type: type);
    final resDown = BlackScholesEngine.calculate(S: sDown, K: K, T: T, r: r, v: v, type: type);

    final maxPremium = [resCurrent.premium, resUp.premium, resDown.premium].reduce(math.max);
    return maxPremium * quantity;
  }

  static double get initialBalance => AppConstants.initialBalance;
}
