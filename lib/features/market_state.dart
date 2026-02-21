import 'dart:async';
import 'dart:isolate';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../data/market_data_service.dart';
import '../domain/option_contract.dart';
import '../domain/price_point.dart';
import '../engines/pricing_engine.dart';
import '../engines/spread_engine.dart';
import '../engines/time_engine.dart';
import '../engines/volatility_engine.dart';
import 'portfolio_state.dart';

export '../domain/option_contract.dart';
export '../domain/price_point.dart';

Completer<List<OptionContract>>? _activeChainComputation;

final marketDataProvider = Provider((ref) {
  final service = MarketDataService();
  service.connect();
  ref.onDispose(() => service.dispose());
  return service;
});

final pricesProvider = StreamProvider<Map<String, double>>((ref) {
  return ref.watch(marketDataProvider).priceStream;
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

final rollingVolatilityProvider = Provider<Map<String, double>>((ref) {
  final history = ref.watch(priceHistoryProvider).value ?? {};
  final result = <String, double>{};

  for (final symbol in history.keys) {
    result[symbol] = VolatilityEngine.calculateRealized(history[symbol]!);
  }
  return result;
});

final optionsChainProvider = FutureProvider<List<OptionContract>>((ref) async {
  final prices = ref.watch(pricesProvider).value;
  final symbol = ref.watch(selectedAssetProvider);
  final t = ref.watch(tValueProvider).value ?? 0.0;
  final rollingVols = ref.watch(rollingVolatilityProvider);
  final baseVol = rollingVols[symbol] ?? AppConstants.defaultBaseVolatility;

  if (prices == null || prices[symbol] == null || prices[symbol] == 0.0) {
    return [];
  }

  final spot = prices[symbol]!;

  _checkLimitOrderFills(ref, spot, t, baseVol);

  // If an isolate computation is already running, wait for it and reuse the result
  // rather than spawning a second concurrent isolate.
  if (_activeChainComputation != null && !_activeChainComputation!.isCompleted) {
    return _activeChainComputation!.future;
  }

  final completer = Completer<List<OptionContract>>();
  _activeChainComputation = completer;

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
