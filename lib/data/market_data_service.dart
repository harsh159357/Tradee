import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class PricePoint {
  final double price;
  final DateTime timestamp;

  PricePoint({required this.price, required this.timestamp});
}

class MarketDataService {
  WebSocketChannel? _channel;
  static const _wsBaseUrl = "wss://stream.binance.com:9443/ws";
  static const _restBaseUrl = "https://api.binance.com/api/v3";
  static const _symbols = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT'];

  final _priceController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get priceStream => _priceController.stream;

  final _historyController = StreamController<Map<String, List<PricePoint>>>.broadcast();
  Stream<Map<String, List<PricePoint>>> get historyStream => _historyController.stream;

  final Map<String, double> _latestPrices = {
    'BTCUSDT': 0.0,
    'ETHUSDT': 0.0,
    'SOLUSDT': 0.0,
  };

  final Map<String, List<PricePoint>> _priceHistory = {
    'BTCUSDT': [],
    'ETHUSDT': [],
    'SOLUSDT': [],
  };

  Timer? _heartbeatTimer;
  Timer? _restFallbackTimer;
  Timer? _debounceTimer;
  DateTime _lastMessageTime = DateTime.now();
  bool _wsConnected = false;
  Map<String, double>? _pendingUpdate;

  void connect() {
    _connectWebSocket();
    _startRestFallback();
  }

  void _connectWebSocket() {
    _channel?.sink.close();
    _wsConnected = false;

    try {
      final streams = _symbols.map((s) => '${s.toLowerCase()}@ticker').join('/');
      _channel = WebSocketChannel.connect(Uri.parse("$_wsBaseUrl/$streams"));

      _channel!.stream.listen(
        (message) {
          _lastMessageTime = DateTime.now();
          _wsConnected = true;

          final data = jsonDecode(message);
          final symbol = data['s'] as String;
          final price = double.parse(data['c']);

          _latestPrices[symbol] = price;
          _recordHistory(symbol, price);
          _debouncedEmit();
        },
        onError: (e) => _reconnect(),
        onDone: () => _reconnect(),
      );

      _startHeartbeat();
    } catch (_) {
      _reconnect();
    }
  }

  void _debouncedEmit() {
    _pendingUpdate = Map.from(_latestPrices);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (_pendingUpdate != null) {
        _priceController.add(_pendingUpdate!);
        _pendingUpdate = null;
      }
    });
  }

  void _recordHistory(String symbol, double price) {
    final now = DateTime.now();
    _priceHistory[symbol]!.add(PricePoint(price: price, timestamp: now));
    _priceHistory[symbol]!.removeWhere(
      (p) => now.difference(p.timestamp).inMinutes >= 60,
    );
    _historyController.add(Map.from(_priceHistory));
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final silenceDuration = DateTime.now().difference(_lastMessageTime);
      if (silenceDuration.inSeconds > 30) {
        _reconnect();
      }
    });
  }

  void _startRestFallback() {
    _restFallbackTimer?.cancel();
    _restFallbackTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_wsConnected ||
          DateTime.now().difference(_lastMessageTime).inSeconds > 15) {
        _fetchRestPrices();
      }
    });
  }

  Future<void> _fetchRestPrices() async {
    try {
      final symbolsParam = _symbols.map((s) => '"$s"').join(',');
      final uri = Uri.parse(
        '$_restBaseUrl/ticker/price?symbols=[$symbolsParam]',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        for (final item in data) {
          final symbol = item['symbol'] as String;
          final price = double.parse(item['price']);
          _latestPrices[symbol] = price;
          _recordHistory(symbol, price);
        }
        _priceController.add(Map.from(_latestPrices));
      }
    } catch (_) {
      // REST fallback failed silently; WebSocket reconnect will handle recovery
    }
  }

  void _reconnect() {
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _wsConnected = false;
    Future.delayed(const Duration(seconds: 5), _connectWebSocket);
  }

  Map<String, double> get latestPrices => Map.unmodifiable(_latestPrices);

  void dispose() {
    _heartbeatTimer?.cancel();
    _restFallbackTimer?.cancel();
    _debounceTimer?.cancel();
    _channel?.sink.close();
    _priceController.close();
    _historyController.close();
  }
}
