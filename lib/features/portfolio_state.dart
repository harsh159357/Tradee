import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import '../core/constants.dart';
import '../data/storage_service.dart';
import '../domain/position.dart';

export '../domain/position.dart';

class PortfolioNotifier extends StateNotifier<List<Position>> {
  PortfolioNotifier() : super([]) {
    loadPositions();
  }

  void loadPositions() {
    final box = StorageService.getBox(StorageService.boxPositions);
    state = box.values.map((m) => Position.fromMap(m)).toList();
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
    state = box.values.map((m) => TradeRecord.fromMap(m)).toList()
      ..sort((a, b) => b.closedAt.compareTo(a.closedAt));
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
