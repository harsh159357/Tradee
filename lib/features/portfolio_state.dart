import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import '../data/storage_service.dart';

class Position {
  final String id;
  final String symbol;
  final double strike;
  final String type;
  final double quantity;
  final double entryPrice;
  final String orderType;
  final bool isFilled;
  final DateTime timestamp;

  Position({
    required this.id,
    required this.symbol,
    required this.strike,
    required this.type,
    required this.quantity,
    required this.entryPrice,
    required this.orderType,
    required this.isFilled,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'symbol': symbol,
    'strike': strike,
    'type': type,
    'quantity': quantity,
    'entryPrice': entryPrice,
    'orderType': orderType,
    'isFilled': isFilled,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Position.fromMap(Map<dynamic, dynamic> map) => Position(
    id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    symbol: map['symbol'],
    strike: (map['strike'] as num).toDouble(),
    type: map['type'],
    quantity: (map['quantity'] as num).toDouble(),
    entryPrice: (map['entryPrice'] as num).toDouble(),
    orderType: map['orderType'] ?? 'market',
    isFilled: map['isFilled'] ?? true,
    timestamp: map['timestamp'] != null
        ? DateTime.parse(map['timestamp'])
        : DateTime.now(),
  );

  Position copyWith({bool? isFilled, double? entryPrice}) => Position(
    id: id,
    symbol: symbol,
    strike: strike,
    type: type,
    quantity: quantity,
    entryPrice: entryPrice ?? this.entryPrice,
    orderType: orderType,
    isFilled: isFilled ?? this.isFilled,
    timestamp: timestamp,
  );
}

class TradeRecord {
  final String id;
  final String symbol;
  final double strike;
  final String type;
  final double quantity;
  final double entryPrice;
  final double exitPrice;
  final double realizedPnL;
  final DateTime openedAt;
  final DateTime closedAt;

  TradeRecord({
    required this.id,
    required this.symbol,
    required this.strike,
    required this.type,
    required this.quantity,
    required this.entryPrice,
    required this.exitPrice,
    required this.realizedPnL,
    required this.openedAt,
    required this.closedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'symbol': symbol,
    'strike': strike,
    'type': type,
    'quantity': quantity,
    'entryPrice': entryPrice,
    'exitPrice': exitPrice,
    'realizedPnL': realizedPnL,
    'openedAt': openedAt.toIso8601String(),
    'closedAt': closedAt.toIso8601String(),
  };

  factory TradeRecord.fromMap(Map<dynamic, dynamic> map) => TradeRecord(
    id: map['id'],
    symbol: map['symbol'],
    strike: (map['strike'] as num).toDouble(),
    type: map['type'],
    quantity: (map['quantity'] as num).toDouble(),
    entryPrice: (map['entryPrice'] as num).toDouble(),
    exitPrice: (map['exitPrice'] as num).toDouble(),
    realizedPnL: (map['realizedPnL'] as num).toDouble(),
    openedAt: DateTime.parse(map['openedAt']),
    closedAt: DateTime.parse(map['closedAt']),
  );
}

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
  BalanceNotifier() : super(100000.0) {
    _load();
  }

  void _load() {
    final box = StorageService.getBox(StorageService.boxAccount);
    state = box.get('balance', defaultValue: 100000.0);
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
