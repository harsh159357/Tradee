import 'dart:math' as math;

class VolatilityEngine {
  final double baseVolatility;
  
  VolatilityEngine({this.baseVolatility = 0.50}); // Default 50% IV

  /// Calculate skew-adjusted volatility
  /// S = Spot Price
  /// K = Strike Price
  /// T = Time to expiry
  double calculateIV({
    required double S,
    required double K,
    required double T,
  }) {
    // Basic skew logic:
    // OTM Puts (K < S) -> Higher IV
    // OTM Calls (K > S) -> Lower IV
    
    final moneyness = K / S;
    double skew = 0.0;
    
    if (moneyness < 1.0) {
      // OTM Put / ITM Call
      // Increase IV as strike moves lower
      skew = (1.0 - moneyness) * 0.5; // Up to 50% boost for deep OTM puts
    } else {
      // OTM Call / ITM Put
      // Slightly lower IV or flat
      skew = (1.0 - moneyness) * 0.1; // Slight decrease
    }

    // Time factor: Volatility often increases as T approaches zero (near-term uncertainty)
    final timeFactor = T < 0.01 ? 1.2 : 1.0; 

    return (baseVolatility + skew) * timeFactor;
  }

  /// Placeholder for rolling realized volatility logic
  /// In a real app, this would intake a list of historical prices
  static double calculateRealized(List<double> prices) {
    if (prices.length < 2) return 0.50;
    
    // Simplified log returns standard deviation
    final returns = <double>[];
    for (var i = 1; i < prices.length; i++) {
      returns.add(math.log(prices[i] / prices[i - 1]));
    }
    
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / (returns.length - 1);
    final stdDev = math.sqrt(variance);
    
    // Annualize (assuming 1-second intervals and 24/7 market)
    return stdDev * math.sqrt(365 * 24 * 60 * 60);
  }
}
