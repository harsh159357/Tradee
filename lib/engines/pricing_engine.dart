import 'dart:math' as math;

enum OptionType { call, put }

class BlackScholesResult {
  final double premium;
  final double delta;
  final double gamma;
  final double vega;
  final double theta;

  BlackScholesResult({
    required this.premium,
    required this.delta,
    required this.gamma,
    required this.vega,
    required this.theta,
  });
}

class BlackScholesEngine {
  /// S = Spot Price
  /// K = Strike Price
  /// T = Time to expiry (in years)
  /// r = Risk-free rate (e.g., 0.05 for 5%)
  /// v = Volatility (e.g., 0.50 for 50%)
  static BlackScholesResult calculate({
    required double S,
    required double K,
    required double T,
    required double r,
    required double v,
    required OptionType type,
  }) {
    // Edge case: Expiry reached
    if (T <= 0) {
      final intrinsic = type == OptionType.call 
          ? math.max(0.0, S - K) 
          : math.max(0.0, K - S);
      return BlackScholesResult(
        premium: intrinsic,
        delta: type == OptionType.call ? (S > K ? 1.0 : 0.0) : (S < K ? -1.0 : 0.0),
        gamma: 0.0,
        vega: 0.0,
        theta: 0.0,
      );
    }

    final d1 = (math.log(S / K) + (r + (v * v) / 2) * T) / (v * math.sqrt(T));
    final d2 = d1 - v * math.sqrt(T);

    final nd1 = _cnd(d1);
    final nd2 = _cnd(d2);
    final nMinusD1 = _cnd(-d1);
    final nMinusD2 = _cnd(-d2);

    final expRT = math.exp(-r * T);
    
    double premium;
    double delta;
    
    if (type == OptionType.call) {
      premium = S * nd1 - K * expRT * nd2;
      delta = nd1;
    } else {
      premium = K * expRT * nMinusD2 - S * nMinusD1;
      delta = nd1 - 1;
    }

    final pdfD1 = _pdf(d1);
    final gamma = pdfD1 / (S * v * math.sqrt(T));
    final vega = S * pdfD1 * math.sqrt(T) / 100; // Divided by 100 to get per 1% vol change
    
    double theta;
    if (type == OptionType.call) {
      theta = (-(S * pdfD1 * v) / (2 * math.sqrt(T)) - r * K * expRT * nd2) / 365;
    } else {
      theta = (-(S * pdfD1 * v) / (2 * math.sqrt(T)) + r * K * expRT * nMinusD2) / 365;
    }

    return BlackScholesResult(
      premium: premium,
      delta: delta,
      gamma: gamma,
      vega: vega,
      theta: theta,
    );
  }

  /// Cumulative Normal Distribution (Approximation)
  static double _cnd(double x) {
    const a1 = 0.31938153;
    const a2 = -0.356563782;
    const a3 = 1.781477937;
    const a4 = -1.821255978;
    const a5 = 1.330274429;
    
    final L = x.abs();
    final K = 1.0 / (1.0 + 0.2316419 * L);
    var d = 1.0 - 1.0 / math.sqrt(2 * math.pi) * math.exp(-L * L / 2) * (a1 * K + a2 * K * K + a3 * math.pow(K, 3) + a4 * math.pow(K, 4) + a5 * math.pow(K, 5));
    
    if (x < 0) d = 1.0 - d;
    return d;
  }

  /// Normal Probability Density Function
  static double _pdf(double x) {
    return (1.0 / math.sqrt(2 * math.pi)) * math.exp(-0.5 * x * x);
  }
}
