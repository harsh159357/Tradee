import 'package:flutter_test/flutter_test.dart';
import 'package:tradee/engines/volatility_engine.dart';
import 'package:tradee/domain/price_point.dart';

void main() {
  group('Volatility Engine - Skew', () {
    late VolatilityEngine engine;

    setUp(() {
      engine = VolatilityEngine(baseVolatility: 0.50);
    });

    test('ATM strike returns base volatility', () {
      final iv = engine.calculateIV(S: 100, K: 100, T: 0.5);
      expect(iv, closeTo(0.50, 0.01));
    });

    test('OTM put has higher IV than ATM', () {
      final atm = engine.calculateIV(S: 100, K: 100, T: 0.5);
      final otmPut = engine.calculateIV(S: 100, K: 95, T: 0.5);
      expect(otmPut, greaterThan(atm));
    });

    test('OTM call has slightly lower IV than ATM', () {
      final atm = engine.calculateIV(S: 100, K: 100, T: 0.5);
      final otmCall = engine.calculateIV(S: 100, K: 105, T: 0.5);
      expect(otmCall, lessThan(atm));
    });

    test('deeper OTM put has even higher IV', () {
      final otm5 = engine.calculateIV(S: 100, K: 95, T: 0.5);
      final otm10 = engine.calculateIV(S: 100, K: 90, T: 0.5);
      expect(otm10, greaterThan(otm5));
    });

    test('near-expiry time factor boosts IV by 20%', () {
      final normal = engine.calculateIV(S: 100, K: 100, T: 0.5);
      final nearExpiry = engine.calculateIV(S: 100, K: 100, T: 0.005);
      expect(nearExpiry, closeTo(normal * 1.2, 0.01));
    });

    test('custom base volatility is respected', () {
      final custom = VolatilityEngine(baseVolatility: 0.80);
      final iv = custom.calculateIV(S: 100, K: 100, T: 0.5);
      expect(iv, closeTo(0.80, 0.01));
    });
  });

  group('Volatility Engine - Realized', () {
    test('returns default when insufficient data', () {
      final result = VolatilityEngine.calculateRealized([]);
      expect(result, equals(0.50));
    });

    test('returns default with fewer than 5 points', () {
      final points = [
        PricePoint(price: 100, timestamp: DateTime(2024, 1, 1, 0, 0, 0)),
        PricePoint(price: 101, timestamp: DateTime(2024, 1, 1, 0, 0, 1)),
      ];
      expect(VolatilityEngine.calculateRealized(points), equals(0.50));
    });

    test('constant prices produce near-zero realized vol', () {
      final points = List.generate(
        20,
        (i) => PricePoint(
          price: 100.0,
          timestamp: DateTime(2024, 1, 1, 0, 0, i),
        ),
      );
      final vol = VolatilityEngine.calculateRealized(points);
      expect(vol, closeTo(0.0, 0.01));
    });

    test('volatile prices produce higher realized vol', () {
      final prices = [100.0, 105.0, 95.0, 110.0, 90.0, 108.0, 92.0, 105.0];
      final points = List.generate(
        prices.length,
        (i) => PricePoint(
          price: prices[i],
          timestamp: DateTime(2024, 1, 1, 0, 0, i * 10),
        ),
      );
      final vol = VolatilityEngine.calculateRealized(points);
      expect(vol, greaterThan(0.5));
    });

    test('handles zero prices gracefully', () {
      final points = [
        PricePoint(price: 0, timestamp: DateTime(2024, 1, 1, 0, 0, 0)),
        PricePoint(price: 0, timestamp: DateTime(2024, 1, 1, 0, 0, 1)),
        PricePoint(price: 0, timestamp: DateTime(2024, 1, 1, 0, 0, 2)),
        PricePoint(price: 0, timestamp: DateTime(2024, 1, 1, 0, 0, 3)),
        PricePoint(price: 0, timestamp: DateTime(2024, 1, 1, 0, 0, 4)),
      ];
      expect(VolatilityEngine.calculateRealized(points), equals(0.50));
    });
  });
}
