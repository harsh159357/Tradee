import 'dart:math' as math;
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/market_data_service.dart';
import '../engines/pricing_engine.dart';
import '../engines/time_engine.dart';
import '../engines/volatility_engine.dart';

// Service Provider
final marketDataProvider = Provider((ref) {
  final service = MarketDataService();
  service.connect();
  ref.onDispose(() => service.dispose());
  return service;
});

// Price Stream Provider
final pricesProvider = StreamProvider<Map<String, double>>((ref) {
  return ref.watch(marketDataProvider).priceStream;
});

// Time Engine Provider
final timeProvider = Provider((ref) => TimeEngine());

// T (Time to Expiry) Stream Provider
final tValueProvider = StreamProvider<double>((ref) {
  return ref.watch(timeProvider).tStream();
});

// Selected Asset Provider
final selectedAssetProvider = StateProvider<String>((ref) => 'BTCUSDT');

// Option Chain Model
class OptionContract {
  final double strike;
  final OptionType type;
  final BlackScholesResult greeks;
  final double iv;

  OptionContract({
    required this.strike,
    required this.type,
    required this.greeks,
    required this.iv,
  });
}

// Options Chain Provider
final optionsChainProvider = Provider<List<OptionContract>>((ref) {
  final prices = ref.watch(pricesProvider).value;
  final symbol = ref.watch(selectedAssetProvider);
  final t = ref.watch(tValueProvider).value ?? 0.0;
  
  if (prices == null || prices[symbol] == null || prices[symbol] == 0.0) return [];

  final spot = prices[symbol]!;
  final volEngine = VolatilityEngine();
  
  // Generate strikes: S ±1%, ±2%, ±3%, ±5%
  final strikeOffsets = [0.95, 0.97, 0.98, 0.99, 1.0, 1.01, 1.02, 1.03, 1.05];
  final List<OptionContract> chain = [];

  for (final offset in strikeOffsets) {
    // Round strike to meaningful numbers based on asset
    double strike;
    if (symbol.contains('BTC')) {
      strike = (spot * offset / 100).round() * 100.0;
    } else if (symbol.contains('ETH')) {
      strike = (spot * offset / 10).round() * 10.0;
    } else {
      strike = (spot * offset).roundToDouble();
    }

    // Call & Put
    for (final type in OptionType.values) {
      final iv = volEngine.calculateIV(S: spot, K: strike, T: t);
      final greeks = BlackScholesEngine.calculate(
        S: spot,
        K: strike,
        T: t,
        r: 0.05, // 5% risk-free rate
        v: iv,
        type: type,
      );
      
      chain.add(OptionContract(
        strike: strike,
        type: type,
        greeks: greeks,
        iv: iv,
      ));
    }
  }

  return chain;
});
