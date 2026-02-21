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
  /// Expiry date for this position. Defaults to today's daily expiry.
  /// Stored for future multi-expiry support.
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
    expiry: map['expiry'] != null ? DateTime.parse(map['expiry']) : null,
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
    expiry: expiry,
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
    expiry: map['expiry'] != null ? DateTime.parse(map['expiry']) : null,
  );
}
