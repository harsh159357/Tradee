import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import '../data/storage_service.dart';

class Position {
  final String symbol;
  final double strike;
  final String type; // 'call' or 'put'
  final double quantity; // Positive for long, negative for short
  final double entryPrice;

  Position({
    required this.symbol,
    required this.strike,
    required this.type,
    required this.quantity,
    required this.entryPrice,
  });

  Map<String, dynamic> toMap() => {
    'symbol': symbol,
    'strike': strike,
    'type': type,
    'quantity': quantity,
    'entryPrice': entryPrice,
  };

  factory Position.fromMap(Map<dynamic, dynamic> map) => Position(
    symbol: map['symbol'],
    strike: map['strike'],
    type: map['type'],
    quantity: map['quantity'],
    entryPrice: map['entryPrice'],
  );
}

class PortfolioNotifier extends StateNotifier<List<Position>> {
  PortfolioNotifier() : super([]) {
    _loadPositions();
  }

  void _loadPositions() {
    final box = StorageService.getBox(StorageService.boxPositions);
    state = box.values.map((m) => Position.fromMap(m)).toList();
  }

  Future<void> addPosition(Position pos) async {
    final box = StorageService.getBox(StorageService.boxPositions);
    await box.add(pos.toMap());
    state = [...state, pos];
  }

  Future<void> closePosition(int index) async {
    final box = StorageService.getBox(StorageService.boxPositions);
    await box.deleteAt(index);
    _loadPositions();
  }
}

final portfolioProvider = StateNotifierProvider<PortfolioNotifier, List<Position>>((ref) {
  return PortfolioNotifier();
});

final balanceProvider = StateProvider<double>((ref) {
  final box = StorageService.getBox(StorageService.boxAccount);
  return box.get('balance', defaultValue: 100000.0);
});
