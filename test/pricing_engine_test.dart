import 'package:flutter_test/flutter_test.dart';
import 'package:tradee/engines/pricing_engine.dart';

void main() {
  group('Black-Scholes Pricing Engine', () {
    test('ATM call premium is approximately correct', () {
      final res = BlackScholesEngine.calculate(
        S: 100, K: 100, T: 1.0, r: 0.05, v: 0.20, type: OptionType.call,
      );
      expect(res.premium, closeTo(10.45, 0.1));
      expect(res.delta, closeTo(0.63, 0.05));
    });

    test('ATM put premium satisfies put-call parity', () {
      final call = BlackScholesEngine.calculate(
        S: 100, K: 100, T: 1.0, r: 0.05, v: 0.20, type: OptionType.call,
      );
      final put = BlackScholesEngine.calculate(
        S: 100, K: 100, T: 1.0, r: 0.05, v: 0.20, type: OptionType.put,
      );
      // Put-call parity: C - P = S - K*e^(-rT)
      final parity = call.premium - put.premium;
      final expected = 100 - 100 * 0.951229; // e^(-0.05) ≈ 0.951229
      expect(parity, closeTo(expected, 0.1));
    });

    test('intrinsic value at expiry for ITM call', () {
      final res = BlackScholesEngine.calculate(
        S: 110, K: 100, T: 0.0, r: 0.05, v: 0.20, type: OptionType.call,
      );
      expect(res.premium, equals(10.0));
      expect(res.delta, equals(1.0));
      expect(res.gamma, equals(0.0));
    });

    test('intrinsic value at expiry for OTM call', () {
      final res = BlackScholesEngine.calculate(
        S: 90, K: 100, T: 0.0, r: 0.05, v: 0.20, type: OptionType.call,
      );
      expect(res.premium, equals(0.0));
      expect(res.delta, equals(0.0));
    });

    test('intrinsic value at expiry for ITM put', () {
      final res = BlackScholesEngine.calculate(
        S: 90, K: 100, T: 0.0, r: 0.05, v: 0.20, type: OptionType.put,
      );
      expect(res.premium, equals(10.0));
      expect(res.delta, equals(-1.0));
    });

    test('deep ITM call has delta near 1', () {
      final res = BlackScholesEngine.calculate(
        S: 200, K: 100, T: 0.5, r: 0.05, v: 0.20, type: OptionType.call,
      );
      expect(res.delta, closeTo(1.0, 0.01));
    });

    test('deep OTM call has delta near 0', () {
      final res = BlackScholesEngine.calculate(
        S: 50, K: 100, T: 0.5, r: 0.05, v: 0.20, type: OptionType.call,
      );
      expect(res.delta, closeTo(0.0, 0.01));
    });

    test('gamma is positive for all options', () {
      final call = BlackScholesEngine.calculate(
        S: 100, K: 100, T: 0.25, r: 0.05, v: 0.30, type: OptionType.call,
      );
      final put = BlackScholesEngine.calculate(
        S: 100, K: 100, T: 0.25, r: 0.05, v: 0.30, type: OptionType.put,
      );
      expect(call.gamma, greaterThan(0));
      expect(put.gamma, greaterThan(0));
      expect(call.gamma, closeTo(put.gamma, 0.0001));
    });

    test('theta is negative for long options', () {
      final res = BlackScholesEngine.calculate(
        S: 100, K: 100, T: 0.25, r: 0.05, v: 0.30, type: OptionType.call,
      );
      expect(res.theta, lessThan(0));
    });

    test('vega is positive for all options', () {
      final res = BlackScholesEngine.calculate(
        S: 100, K: 100, T: 0.25, r: 0.05, v: 0.30, type: OptionType.call,
      );
      expect(res.vega, greaterThan(0));
    });

    test('higher volatility increases premium', () {
      final low = BlackScholesEngine.calculate(
        S: 100, K: 100, T: 0.5, r: 0.05, v: 0.20, type: OptionType.call,
      );
      final high = BlackScholesEngine.calculate(
        S: 100, K: 100, T: 0.5, r: 0.05, v: 0.40, type: OptionType.call,
      );
      expect(high.premium, greaterThan(low.premium));
    });
  });
}
