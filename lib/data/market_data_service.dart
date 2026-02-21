import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class MarketDataService {
  WebSocketChannel? _channel;
  final String _baseUrl = "wss://stream.binance.com:9443/ws";
  
  final _priceController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get priceStream => _priceController.stream;

  final Map<String, double> _latestPrices = {
    'BTCUSDT': 0.0,
    'ETHUSDT': 0.0,
    'SOLUSDT': 0.0,
  };

  void connect() {
    final streams = ['btcusdt@ticker', 'ethusdt@ticker', 'solusdt@ticker'].join('/');
    final url = "$_baseUrl/$streams";
    
    _channel = WebSocketChannel.connect(Uri.parse(url));
    
    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        final symbol = data['s'] as String;
        final price = double.parse(data['c']);
        
        _latestPrices[symbol] = price;
        _priceController.add(Map.from(_latestPrices));
      },
      onError: (e) {
        print("WebSocket Error: $e");
        reconnect();
      },
      onDone: () {
        print("WebSocket Closed");
        reconnect();
      },
    );
  }

  void reconnect() {
    _channel?.sink.close();
    Future.delayed(const Duration(seconds: 5), () => connect());
  }

  void dispose() {
    _channel?.sink.close();
    _priceController.close();
  }

  double? getLatestPrice(String symbol) => _latestPrices[symbol];
}
