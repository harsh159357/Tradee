import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import '../data/storage_service.dart';

class Position {
  final String id;
  final String symbol;
  final double strike;
  final String type; // 'call' or 'put'
  final double quantity;
  final double entryPrice;
  final String orderType; // 'market' or 'limit'
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
    strike: map['strike'],
    type: map['type'],
    quantity: map['quantity'],
    entryPrice: map['entryPrice'],
    orderType: map['orderType'] ?? 'market',
    isFilled: map['isFilled'] ?? true,
    timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
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

  Future<void> closePosition(String id) async {
    final box = StorageService.getBox(StorageService.boxPositions);
    await box.delete(id);
    loadPositions();
  }
}

final portfolioProvider = StateNotifierProvider<PortfolioNotifier, List<Position>>((ref) {
  return PortfolioNotifier();
});

final balanceProvider = StateNotifierProvider<BalanceNotifier, double>((ref) {
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
