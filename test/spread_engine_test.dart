import 'package:flutter_test/flutter_test.dart';
import 'package:tradee/engines/spread_engine.dart';

void main() {
  group('Spread Engine', () {
    test('bid is below mid and ask is above mid', () {
      final sr = SpreadEngine.calculate(midPrice: 10.0);
      expect(sr.bid, lessThan(sr.mid));
      expect(sr.ask, greaterThan(sr.mid));
    });

    test('spread equals ask minus bid', () {
      final sr = SpreadEngine.calculate(midPrice: 10.0);
      expect(sr.spread, closeTo(sr.ask - sr.bid, 0.0001));
    });

    test('spread is at least 0.5% of mid price', () {
      final sr = SpreadEngine.calculate(midPrice: 10.0);
      expect(sr.spread, greaterThanOrEqualTo(10.0 * 0.005));
    });

    test('spread enforces minimum tick for very small premiums', () {
      final sr = SpreadEngine.calculate(midPrice: 0.001);
      expect(sr.bid, greaterThanOrEqualTo(0.01));
      expect(sr.ask, greaterThan(sr.bid));
    });

    test('custom spread percent is applied', () {
      final sr = SpreadEngine.calculate(
          midPrice: 100.0, spreadPercent: 0.01);
      expect(sr.spread, closeTo(1.0, 0.01));
    });

    test('buy fill price is above ask', () {
      final fill =
          SpreadEngine.fillPrice(midPrice: 10.0, quantity: 1.0);
      final sr = SpreadEngine.calculate(midPrice: 10.0);
      expect(fill, greaterThanOrEqualTo(sr.ask));
    });

    test('sell fill price is below bid', () {
      final fill =
          SpreadEngine.fillPrice(midPrice: 10.0, quantity: -1.0);
      final sr = SpreadEngine.calculate(midPrice: 10.0);
      expect(fill, lessThanOrEqualTo(sr.bid));
    });

    test('larger orders have worse fill prices', () {
      final fillSmall =
          SpreadEngine.fillPrice(midPrice: 10.0, quantity: 1.0);
      final fillLarge =
          SpreadEngine.fillPrice(midPrice: 10.0, quantity: 100.0);
      expect(fillLarge, greaterThan(fillSmall));
    });
  });
}
