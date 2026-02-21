class PricePoint {
  final double price;
  final DateTime timestamp;

  const PricePoint({required this.price, required this.timestamp});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PricePoint &&
          price == other.price &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(price, timestamp);
}
