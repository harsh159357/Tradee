import '../core/constants.dart';
import '../domain/price_point.dart';
import 'dart:math' as math;

class VolatilityEngine {
  final double baseVolatility;
  
  VolatilityEngine({this.baseVolatility = AppConstants.defaultBaseVolatility});

  double calculateIV({
    required double S,
    required double K,
    required double T,
  }) {
    final moneyness = K / S;
    double skew = 0.0;
    
    if (moneyness < 1.0) {
      skew = (1.0 - moneyness) * 0.5;
    } else {
      skew = (1.0 - moneyness) * 0.1;
    }

    final timeFactor = T < 0.01 ? 1.2 : 1.0; 

    return (baseVolatility + skew) * timeFactor;
  }

  static double calculateRealized(List<PricePoint> points) {
    if (points.length < 5) return AppConstants.defaultBaseVolatility;
    
    final returns = <double>[];
    for (var i = 1; i < points.length; i++) {
      if (points[i].price > 0 && points[i-1].price > 0) {
        returns.add(math.log(points[i].price / points[i - 1].price));
      }
    }
    
    if (returns.isEmpty) return AppConstants.defaultBaseVolatility;

    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / (returns.length - 1);
    final stdDev = math.sqrt(variance);
    
    final totalSecs = points.last.timestamp.difference(points.first.timestamp).inSeconds;
    if (totalSecs == 0) return AppConstants.defaultBaseVolatility;
    
    final intervalsPerYear = (365 * 24 * 60 * 60) / (totalSecs / (points.length - 1));
    return stdDev * math.sqrt(intervalsPerYear);
  }
}
