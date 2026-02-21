import 'package:flutter_test/flutter_test.dart';
import 'package:tradee/engines/margin_engine.dart';
import 'package:tradee/engines/pricing_engine.dart';

void main() {
  group('Margin Engine', () {
    test('long margin equals premium times quantity', () {
      final margin = MarginEngine.calculateLongMargin(5.0, 10.0);
      expect(margin, equals(50.0));
    });

    test('long margin is zero for zero quantity', () {
      final margin = MarginEngine.calculateLongMargin(5.0, 0.0);
      expect(margin, equals(0.0));
    });

    test('short margin uses stress test and exceeds long margin', () {
      final longMargin = MarginEngine.calculateLongMargin(5.0, 1.0);
      final shortMargin = MarginEngine.calculateShortMargin(
        S: 100, K: 100, T: 0.5, r: 0.05, v: 0.30,
        type: OptionType.call, quantity: 1.0,
      );
      expect(shortMargin, greaterThanOrEqualTo(longMargin));
    });

    test('short call margin increases when spot goes up', () {
      final marginBase = MarginEngine.calculateShortMargin(
        S: 100, K: 100, T: 0.5, r: 0.05, v: 0.30,
        type: OptionType.call, quantity: 1.0,
      );
      final marginHighSpot = MarginEngine.calculateShortMargin(
        S: 120, K: 100, T: 0.5, r: 0.05, v: 0.30,
        type: OptionType.call, quantity: 1.0,
      );
      expect(marginHighSpot, greaterThan(marginBase));
    });

    test('short put margin increases when spot goes down', () {
      final marginBase = MarginEngine.calculateShortMargin(
        S: 100, K: 100, T: 0.5, r: 0.05, v: 0.30,
        type: OptionType.put, quantity: 1.0,
      );
      final marginLowSpot = MarginEngine.calculateShortMargin(
        S: 80, K: 100, T: 0.5, r: 0.05, v: 0.30,
        type: OptionType.put, quantity: 1.0,
      );
      expect(marginLowSpot, greaterThan(marginBase));
    });

    test('short margin scales linearly with quantity', () {
      final margin1 = MarginEngine.calculateShortMargin(
        S: 100, K: 100, T: 0.5, r: 0.05, v: 0.30,
        type: OptionType.call, quantity: 1.0,
      );
      final margin5 = MarginEngine.calculateShortMargin(
        S: 100, K: 100, T: 0.5, r: 0.05, v: 0.30,
        type: OptionType.call, quantity: 5.0,
      );
      expect(margin5, closeTo(margin1 * 5, 0.01));
    });

    test('initial balance is 100000', () {
      expect(MarginEngine.initialBalance, equals(100000.0));
    });
  });
}
