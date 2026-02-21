import 'dart:developer' as developer;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import '../core/constants.dart';
import '../data/storage_service.dart';
import '../domain/position.dart';
import '../engines/spread_engine.dart';

export '../domain/position.dart';

class PortfolioNotifier extends StateNotifier<List<Position>> {
  PortfolioNotifier() : super([]) {
    loadPositions();
  }

  void loadPositions() {
    final box = StorageService.getBox(StorageService.boxPositions);
    final positions = <Position>[];
    for (final entry in box.toMap().entries) {
      try {
        positions.add(Position.fromMap(entry.value));
      } catch (e) {
        developer.log('Corrupt position ${entry.key}, removing: $e',
            name: 'PortfolioNotifier');
        box.delete(entry.key);
      }
    }
    state = positions;
  }

  Future<void> addOrder(Position pos) async {
    final box = StorageService.getBox(StorageService.boxPositions);
    await box.put(pos.id, pos.toMap());
    state = [...state, pos];
  }

  Future<void> updatePosition(Position pos) async {
    final box = StorageService.getBox(StorageService.boxPositions);
    await box.put(pos.id, pos.toMap());
    loadPositions();
  }

  Future<void> closePosition(String id, {double exitPrice = 0.0}) async {
    final box = StorageService.getBox(StorageService.boxPositions);
    final historyBox = StorageService.getBox(StorageService.boxHistory);

    final posMap = box.get(id);
    if (posMap != null) {
      final pos = Position.fromMap(posMap);
      if (pos.isFilled) {
        final pnl = (exitPrice - pos.entryPrice) * pos.quantity;
        final record = TradeRecord(
          id: pos.id,
          symbol: pos.symbol,
          strike: pos.strike,
          type: pos.type,
          quantity: pos.quantity,
          entryPrice: pos.entryPrice,
          exitPrice: exitPrice,
          realizedPnL: pnl,
          openedAt: pos.timestamp,
          closedAt: DateTime.now(),
        );
        await historyBox.put(record.id, record.toMap());
      }
    }

    await box.delete(id);
    loadPositions();
  }

  /// Atomic order placement: creates position, computes fill, deducts balance.
  /// Returns the created Position and the fill message.
  Future<({Position position, String message})> placeOrder({
    required String symbol,
    required double strike,
    required String type,
    required double quantity,
    required double qtyFactor,
    required String orderType,
    required double midPrice,
    required double limitPrice,
    required double currentVol,
    required BalanceNotifier balanceNotifier,
    required double currentBalance,
  }) async {
    double entryPrice;
    if (orderType == 'market') {
      entryPrice = SpreadEngine.fillPrice(
        midPrice: midPrice,
        quantity: quantity * qtyFactor,
        realizedVol: currentVol,
      );
    } else {
      entryPrice = limitPrice;
    }

    final pos = Position(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: symbol,
      strike: strike,
      type: type,
      quantity: quantity * qtyFactor,
      entryPrice: entryPrice,
      orderType: orderType,
      isFilled: orderType == 'market',
      timestamp: DateTime.now(),
    );

    await addOrder(pos);

    if (orderType == 'market') {
      final cost = entryPrice * quantity * qtyFactor;
      await balanceNotifier.updateBalance(currentBalance - cost);
    } else {
      final marginHold = entryPrice * quantity;
      await balanceNotifier.updateBalance(currentBalance - marginHold);
    }

    final message = orderType == 'market'
        ? 'Filled @ \$${entryPrice.toStringAsFixed(2)}'
        : 'Limit Order Placed @ \$${limitPrice.toStringAsFixed(2)}';

    return (position: pos, message: message);
  }

  /// Atomic close: settles PnL, updates balance, records history in one call.
  Future<void> closePositionWithSettlement({
    required String id,
    required double exitPrice,
    required bool isFilled,
    required double pnl,
    required BalanceNotifier balanceNotifier,
    required double currentBalance,
    required double entryPrice,
    required double quantity,
    required TradeHistoryNotifier historyNotifier,
  }) async {
    await closePosition(id, exitPrice: exitPrice);

    if (isFilled) {
      await balanceNotifier.updateBalance(currentBalance + pnl);
    } else {
      final refund = entryPrice * quantity.abs();
      await balanceNotifier.updateBalance(currentBalance + refund);
    }

    historyNotifier.refresh();
  }

  Future<void> closeAllPositions(Map<String, double> exitPrices) async {
    final box = StorageService.getBox(StorageService.boxPositions);
    final historyBox = StorageService.getBox(StorageService.boxHistory);

    for (final key in box.keys.toList()) {
      final posMap = box.get(key);
      if (posMap != null) {
        final pos = Position.fromMap(posMap);
        if (pos.isFilled) {
          final ep = exitPrices[pos.id] ?? pos.entryPrice;
          final pnl = (ep - pos.entryPrice) * pos.quantity;
          final record = TradeRecord(
            id: pos.id,
            symbol: pos.symbol,
            strike: pos.strike,
            type: pos.type,
            quantity: pos.quantity,
            entryPrice: pos.entryPrice,
            exitPrice: ep,
            realizedPnL: pnl,
            openedAt: pos.timestamp,
            closedAt: DateTime.now(),
          );
          await historyBox.put(record.id, record.toMap());
        }
      }
    }
    await box.clear();
    loadPositions();
  }
}

class TradeHistoryNotifier extends StateNotifier<List<TradeRecord>> {
  TradeHistoryNotifier() : super([]) {
    _load();
  }

  void _load() {
    final box = StorageService.getBox(StorageService.boxHistory);
    final records = <TradeRecord>[];
    for (final entry in box.toMap().entries) {
      try {
        records.add(TradeRecord.fromMap(entry.value));
      } catch (e) {
        developer.log('Corrupt trade record ${entry.key}, removing: $e',
            name: 'TradeHistoryNotifier');
        box.delete(entry.key);
      }
    }
    records.sort((a, b) => b.closedAt.compareTo(a.closedAt));
    state = records;
  }

  void refresh() => _load();
}

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, List<Position>>((ref) {
  return PortfolioNotifier();
});

final tradeHistoryProvider =
    StateNotifierProvider<TradeHistoryNotifier, List<TradeRecord>>((ref) {
  return TradeHistoryNotifier();
});

final balanceProvider =
    StateNotifierProvider<BalanceNotifier, double>((ref) {
  return BalanceNotifier();
});

class BalanceNotifier extends StateNotifier<double> {
  BalanceNotifier() : super(AppConstants.initialBalance) {
    _load();
  }

  void _load() {
    final box = StorageService.getBox(StorageService.boxAccount);
    state = box.get('balance', defaultValue: AppConstants.initialBalance);
  }

  Future<void> updateBalance(double newBalance) async {
    final box = StorageService.getBox(StorageService.boxAccount);
    await box.put('balance', newBalance);
    state = newBalance;
  }
}

final realizedPnLProvider = Provider<double>((ref) {
  final history = ref.watch(tradeHistoryProvider);
  if (history.isEmpty) return 0.0;
  return history.fold(0.0, (sum, t) => sum + t.realizedPnL);
});
