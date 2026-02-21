import 'dart:developer' as developer;

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
  final DateTime? expiry;

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
    this.expiry,
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
    if (expiry != null) 'expiry': expiry!.toIso8601String(),
  };

  factory Position.fromMap(Map<dynamic, dynamic> map) {
    final id = map['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final symbol = map['symbol']?.toString() ?? '';
    final type = map['type']?.toString() ?? 'call';
    final orderType = map['orderType']?.toString() ?? 'market';

    if (symbol.isEmpty) {
      throw FormatException('Position $id has no symbol');
    }

    return Position(
      id: id,
      symbol: symbol,
      strike: _parseDouble(map['strike'], 'strike'),
      type: type,
      quantity: _parseDouble(map['quantity'], 'quantity'),
      entryPrice: _parseDouble(map['entryPrice'], 'entryPrice'),
      orderType: orderType,
      isFilled: map['isFilled'] as bool? ?? true,
      timestamp: _parseDateTime(map['timestamp']) ?? DateTime.now(),
      expiry: _parseDateTime(map['expiry']),
    );
  }

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
    expiry: expiry,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          symbol == other.symbol &&
          strike == other.strike &&
          type == other.type &&
          quantity == other.quantity &&
          entryPrice == other.entryPrice &&
          orderType == other.orderType &&
          isFilled == other.isFilled;

  @override
  int get hashCode => Object.hash(
      id, symbol, strike, type, quantity, entryPrice, orderType, isFilled);

  @override
  String toString() =>
      'Position($symbol $strike $type qty=$quantity filled=$isFilled)';
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
  final DateTime? expiry;

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
    this.expiry,
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
    if (expiry != null) 'expiry': expiry!.toIso8601String(),
  };

  factory TradeRecord.fromMap(Map<dynamic, dynamic> map) {
    return TradeRecord(
      id: map['id']?.toString() ?? '',
      symbol: map['symbol']?.toString() ?? '',
      strike: _parseDouble(map['strike'], 'strike'),
      type: map['type']?.toString() ?? 'call',
      quantity: _parseDouble(map['quantity'], 'quantity'),
      entryPrice: _parseDouble(map['entryPrice'], 'entryPrice'),
      exitPrice: _parseDouble(map['exitPrice'], 'exitPrice'),
      realizedPnL: _parseDouble(map['realizedPnL'], 'realizedPnL'),
      openedAt: _parseDateTime(map['openedAt']) ?? DateTime.now(),
      closedAt: _parseDateTime(map['closedAt']) ?? DateTime.now(),
      expiry: _parseDateTime(map['expiry']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeRecord && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

double _parseDouble(dynamic value, String field) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  developer.log('Unexpected type for $field: ${value.runtimeType}',
      name: 'Position');
  return 0.0;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
