import 'price_point.dart';

/// Abstract interface for market data sources.
/// Allows swapping between WebSocket (current), REST-only, or a future backend.
abstract class MarketDataSource {
  Stream<Map<String, double>> get priceStream;
  Stream<Map<String, List<PricePoint>>> get historyStream;
  Map<String, double> get latestPrices;

  void connect();
  void dispose();
}
