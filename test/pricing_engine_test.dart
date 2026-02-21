import 'package:flutter_test/flutter_test.dart';
import 'package:tradee/engines/pricing_engine.dart';

void main() {
  group('Black-Scholes Pricing Engine Tests', () {
    test('Call Option at the money', () {
      final res = BlackScholesEngine.calculate(
        S: 100,
        K: 100,
        T: 1.0, 
        r: 0.05,
        v: 0.20,
        type: OptionType.call,
      );
      
      // Expected premium approx 10.45
      expect(res.premium, closeTo(10.45, 0.1));
      expect(res.delta, closeTo(0.63, 0.05));
    });

    test('Put Option at the money', () {
      final res = BlackScholesEngine.calculate(
        S: 100,
        K: 100,
        T: 1.0,
        r: 0.05,
        v: 0.20,
        type: OptionType.put,
      );
      
      expect(res.premium, closeTo(5.57, 0.1));
      expect(res.delta, closeTo(-0.36, 0.05));
    });

    test('Intrinsic value at expiry', () {
      final res = BlackScholesEngine.calculate(
        S: 110,
        K: 100,
        T: 0.0,
        r: 0.05,
        v: 0.20,
        type: OptionType.call,
      );
      
      expect(res.premium, equals(10.0));
    });
  });
}
