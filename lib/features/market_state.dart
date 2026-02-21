import 'dart:async';
import 'dart:isolate';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../data/market_data_service.dart';
import '../data/storage_service.dart';
import '../domain/option_contract.dart';
import '../engines/pricing_engine.dart';
import '../engines/spread_engine.dart';
import '../engines/time_engine.dart';
import '../engines/volatility_engine.dart';
import 'portfolio_state.dart';

export '../domain/option_contract.dart';
export '../domain/price_point.dart';

Completer<List<OptionContract>>? _activeChainComputation;
String? _activeChainKey;

final marketDataProvider = Provider((ref) {
  final service = MarketDataService();
  service.connect();
  ref.onDispose(() => service.dispose());
  return service;
});

final pricesProvider = StreamProvider<Map<String, double>>((ref) {
  return ref.watch(marketDataProvider).priceStream;
});

final connectionStateProvider = StreamProvider<WsConnectionState>((ref) {
  return ref.watch(marketDataProvider).connectionStateStream;
});

final timeProvider = Provider((ref) => TimeEngine());

final tValueProvider = StreamProvider<double>((ref) {
  return ref.watch(timeProvider).tStream();
});

final selectedAssetProvider = StateProvider<String>((ref) => 'BTCUSDT');

/// Fetches true 24h price change % from Binance REST API.
final change24hProvider = FutureProvider<Map<String, double>>((ref) async {
  final service = ref.watch(marketDataProvider);
  return service.fetch24hChange();
});

final priceHistoryProvider = StreamProvider<Map<String, List<PricePoint>>>((ref) {
  final service = ref.watch(marketDataProvider);
  return service.historyStream;
});

final volatilityModeProvider = StateProvider<String>((ref) {
  final box = StorageService.getBox(StorageService.boxSettings);
  return box.get('volatility_mode', defaultValue: 'rolling') as String;
});

final rollingVolatilityProvider = Provider<Map<String, double>>((ref) {
  final mode = ref.watch(volatilityModeProvider);

  if (mode == 'fixed') {
    return {
      for (final symbol in AppConstants.supportedAssets)
        symbol: AppConstants.defaultBaseVolatility,
    };
  }

  final history = ref.watch(priceHistoryProvider).value ?? {};
  final result = <String, double>{};
  for (final symbol in history.keys) {
    result[symbol] = VolatilityEngine.calculateRealized(history[symbol]!);
  }
  return result;
});

/// Quantized spot price: only changes when the raw price moves by > 0.1%.
/// Prevents the chain from recomputing on every tiny WebSocket tick.
final _lastQuantizedSpot = <String, double>{};

final quantizedSpotProvider = Provider<double>((ref) {
  final symbol = ref.watch(selectedAssetProvider);
  final prices = ref.watch(pricesProvider).value ?? {};
  final rawSpot = prices[symbol] ?? 0.0;
  final lastSpot = _lastQuantizedSpot[symbol] ?? 0.0;

  if (lastSpot == 0 || rawSpot == 0) {
    _lastQuantizedSpot[symbol] = rawSpot;
    return rawSpot;
  }

  final pctChange = (rawSpot - lastSpot).abs() / lastSpot;
  if (pctChange > 0.001) {
    _lastQuantizedSpot[symbol] = rawSpot;
    return rawSpot;
  }
  return lastSpot;
});

final optionsChainProvider = FutureProvider<List<OptionContract>>((ref) async {
  final symbol = ref.watch(selectedAssetProvider);
  final spot = ref.watch(quantizedSpotProvider);
  final t = ref.watch(tValueProvider).value ?? 0.0;
  final rollingVols = ref.watch(rollingVolatilityProvider);
  final baseVol = rollingVols[symbol] ?? AppConstants.defaultBaseVolatility;

  if (spot == 0.0) return [];

  // Check limit fills using live (unquantized) spot
  final livePrices = ref.read(pricesProvider).value ?? {};
  final liveSpot = livePrices[symbol] ?? spot;
  _checkLimitOrderFills(ref, liveSpot, t, baseVol);

  final chainKey = '$symbol:${spot.toStringAsFixed(2)}';

  if (_activeChainComputation != null &&
      !_activeChainComputation!.isCompleted &&
      _activeChainKey == chainKey) {
    return _activeChainComputation!.future;
  }

  final completer = Completer<List<OptionContract>>();
  _activeChainComputation = completer;
  _activeChainKey = chainKey;

  try {
    final chain = await Isolate.run(() => _computeChain(spot, symbol, t, baseVol));
    completer.complete(chain);
    return chain;
  } catch (e) {
    completer.completeError(e);
    rethrow;
  }
});

List<OptionContract> _computeChain(
  double spot,
  String symbol,
  double t,
  double baseVol,
) {
  final volEngine = VolatilityEngine(baseVolatility: baseVol);
  final List<OptionContract> chain = [];

  for (final offset in AppConstants.strikeOffsets) {
    double strike;
    if (symbol.contains('BTC')) {
      strike = (spot * offset / 100).round() * 100.0;
    } else if (symbol.contains('ETH')) {
      strike = (spot * offset / 10).round() * 10.0;
    } else {
      strike = (spot * offset).roundToDouble();
    }

    for (final type in OptionType.values) {
      final iv = volEngine.calculateIV(S: spot, K: strike, T: t);
      final greeks = BlackScholesEngine.calculate(
        S: spot, K: strike, T: t, r: AppConstants.riskFreeRate, v: iv, type: type,
      );
      final spread = SpreadEngine.calculate(
        midPrice: greeks.premium,
        realizedVol: baseVol,
      );

      chain.add(OptionContract(
        strike: strike,
        type: type,
        greeks: greeks,
        iv: iv,
        spread: spread,
      ));
    }
  }

  return chain;
}

void _checkLimitOrderFills(Ref ref, double spot, double t, double baseVol) {
  final portfolio = ref.read(portfolioProvider);
  for (final pos in portfolio) {
    if (!pos.isFilled && pos.orderType == 'limit') {
      final iv = VolatilityEngine(baseVolatility: baseVol).calculateIV(
        S: spot, K: pos.strike, T: t,
      );
      final res = BlackScholesEngine.calculate(
        S: spot, K: pos.strike, T: t, r: AppConstants.riskFreeRate, v: iv,
        type: pos.type == 'call' ? OptionType.call : OptionType.put,
      );

      if (pos.quantity > 0 && res.premium <= pos.entryPrice) {
        ref.read(portfolioProvider.notifier).updatePosition(
          pos.copyWith(isFilled: true),
        );
      } else if (pos.quantity < 0 && res.premium >= pos.entryPrice) {
        ref.read(portfolioProvider.notifier).updatePosition(
          pos.copyWith(isFilled: true),
        );
      }
    }
  }
}
