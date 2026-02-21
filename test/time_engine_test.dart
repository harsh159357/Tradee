import 'package:flutter_test/flutter_test.dart';
import 'package:tradee/engines/time_engine.dart';

void main() {
  group('Time Engine', () {
    late TimeEngine engine;

    setUp(() {
      engine = TimeEngine();
    });

    test('T is always non-negative', () {
      final t = engine.calculateT();
      expect(t, greaterThanOrEqualTo(0.0));
    });

    test('T is less than 1 day in years', () {
      final t = engine.calculateT();
      final oneDayInYears = 1.0 / 365.0;
      expect(t, lessThanOrEqualTo(oneDayInYears + 0.0001));
    });

    test('expiry is today at 23:59:59 UTC', () {
      final expiry = engine.expiry;
      final now = DateTime.now().toUtc();
      expect(expiry.year, equals(now.year));
      expect(expiry.month, equals(now.month));
      expect(expiry.day, equals(now.day));
      expect(expiry.hour, equals(23));
      expect(expiry.minute, equals(59));
      expect(expiry.second, equals(59));
    });

    test('countdown format is HH:mm:ss', () {
      final countdown = engine.getCountdown();
      expect(countdown, matches(RegExp(r'^\d{2}:\d{2}:\d{2}$')));
    });

    test('tStream emits values', () async {
      final stream = engine.tStream();
      final first = await stream.first;
      expect(first, isA<double>());
      expect(first, greaterThanOrEqualTo(0.0));
    });
  });
}
