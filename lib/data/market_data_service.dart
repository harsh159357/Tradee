import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../domain/market_data_source.dart';
import '../domain/price_point.dart';

export '../domain/price_point.dart';

enum WsConnectionState { connected, reconnecting, disconnected }

class MarketDataService implements MarketDataSource {
  WebSocketChannel? _channel;
  static const _wsBaseUrl = 'wss://stream.binance.com:9443/ws';
  static const _restBaseUrl = 'https://api.binance.com/api/v3';

  final _priceController = StreamController<Map<String, double>>.broadcast();
  @override
  Stream<Map<String, double>> get priceStream => _priceController.stream;

  final _historyController = StreamController<Map<String, List<PricePoint>>>.broadcast();
  @override
  Stream<Map<String, List<PricePoint>>> get historyStream => _historyController.stream;

  final _connectionStateController = StreamController<WsConnectionState>.broadcast();
  Stream<WsConnectionState> get connectionStateStream => _connectionStateController.stream;
  WsConnectionState _connectionState = WsConnectionState.disconnected;

  final Map<String, double> _latestPrices = {
    for (final s in AppConstants.supportedAssets) s: 0.0,
  };

  final Map<String, List<PricePoint>> _priceHistory = {
    for (final s in AppConstants.supportedAssets) s: [],
  };

  Timer? _heartbeatTimer;
  Timer? _restFallbackTimer;
  Timer? _debounceTimer;
  Timer? _reconnectTimer;
  DateTime _lastMessageTime = DateTime.now();
  bool _wsConnected = false;
  bool _isDisposed = false;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  Map<String, double>? _pendingUpdate;

  @override
  void connect() {
    _connectWebSocket();
    _startRestFallback();
  }

  void _connectWebSocket() {
    if (_isDisposed) return;
    _channel?.sink.close();
    _wsConnected = false;

    try {
      final streams = AppConstants.supportedAssets
          .map((s) => '${s.toLowerCase()}@ticker')
          .join('/');
      _channel = WebSocketChannel.connect(Uri.parse('$_wsBaseUrl/$streams'));

      _channel!.stream.listen(
        (message) {
          _lastMessageTime = DateTime.now();
          _wsConnected = true;
          _reconnectAttempts = 0;
          _setConnectionState(WsConnectionState.connected);

          try {
            final data = jsonDecode(message);
            final symbol = data['s'] as String;
            final price = double.parse(data['c']);

            _latestPrices[symbol] = price;
            _recordHistory(symbol, price);
            _debouncedEmit();
          } on FormatException catch (e) {
            developer.log('Malformed WS message: $e', name: 'MarketData');
          }
        },
        onError: (e) {
          developer.log('WebSocket error: $e', name: 'MarketData');
          _reconnect();
        },
        onDone: () {
          developer.log('WebSocket closed', name: 'MarketData');
          _reconnect();
        },
      );

      _startHeartbeat();
      developer.log('WebSocket connected', name: 'MarketData');
    } catch (e) {
      developer.log('WebSocket connect failed: $e', name: 'MarketData');
      _reconnect();
    }
  }

  void _debouncedEmit() {
    if (_isDisposed) return;
    _pendingUpdate = Map.from(_latestPrices);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppConstants.debounceInterval, () {
      if (_pendingUpdate != null && !_isDisposed) {
        _priceController.add(_pendingUpdate!);
        _pendingUpdate = null;
      }
    });
  }

  void _recordHistory(String symbol, double price) {
    if (_isDisposed) return;
    final now = DateTime.now();
    _priceHistory[symbol]!.add(PricePoint(price: price, timestamp: now));
    _priceHistory[symbol]!.removeWhere(
      (p) => now.difference(p.timestamp).inMinutes >= 60,
    );
    _historyController.add(Map.from(_priceHistory));
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(AppConstants.heartbeatInterval, (_) {
      final silenceDuration = DateTime.now().difference(_lastMessageTime);
      if (silenceDuration > AppConstants.heartbeatTimeout) {
        developer.log('Heartbeat timeout, reconnecting', name: 'MarketData');
        _reconnect();
      }
    });
  }

  void _startRestFallback() {
    _restFallbackTimer?.cancel();
    _restFallbackTimer = Timer.periodic(AppConstants.restFallbackInterval, (_) {
      if (!_wsConnected ||
          DateTime.now().difference(_lastMessageTime) > AppConstants.heartbeatInterval) {
        _fetchRestPrices();
      }
    });
  }

  Future<void> _fetchRestPrices() async {
    if (_isDisposed) return;
    try {
      final symbolsParam =
          AppConstants.supportedAssets.map((s) => '"$s"').join(',');
      final uri = Uri.parse(
        '$_restBaseUrl/ticker/price?symbols=[$symbolsParam]',
      );
      final response = await http.get(uri).timeout(AppConstants.restTimeout);

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        for (final item in data) {
          final symbol = item['symbol'] as String;
          final price = double.parse(item['price']);
          _latestPrices[symbol] = price;
          _recordHistory(symbol, price);
        }
        if (!_isDisposed) {
          _priceController.add(Map.from(_latestPrices));
        }
      }
    } catch (e) {
      developer.log('REST fallback failed: $e', name: 'MarketData');
    }
  }

  void _reconnect() {
    if (_isDisposed || _isReconnecting) return;
    _isReconnecting = true;
    _setConnectionState(WsConnectionState.reconnecting);

    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _wsConnected = false;

    final delay = _backoffDelay();
    developer.log('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)',
        name: 'MarketData');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _isReconnecting = false;
      _reconnectAttempts++;
      _connectWebSocket();
    });
  }

  Duration _backoffDelay() {
    final seconds = math.min(5 * math.pow(2, _reconnectAttempts).toInt(), 60);
    return Duration(seconds: seconds);
  }

  @override
  Map<String, double> get latestPrices => Map.unmodifiable(_latestPrices);

  Future<Map<String, double>> fetch24hChange() async {
    final result = <String, double>{};
    try {
      final symbolsParam =
          AppConstants.supportedAssets.map((s) => '"$s"').join(',');
      final uri = Uri.parse(
        '$_restBaseUrl/ticker/24hr?symbols=[$symbolsParam]',
      );
      final response = await http.get(uri).timeout(AppConstants.restTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        for (final item in data) {
          final symbol = item['symbol'] as String;
          final pctChange = double.tryParse(item['priceChangePercent'] ?? '0') ?? 0.0;
          result[symbol] = pctChange;
        }
      }
    } catch (e) {
      developer.log('24h change fetch failed: $e', name: 'MarketData');
    }
    return result;
  }

  void _setConnectionState(WsConnectionState state) {
    if (_isDisposed || _connectionState == state) return;
    _connectionState = state;
    _connectionStateController.add(state);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _setConnectionState(WsConnectionState.disconnected);
    _heartbeatTimer?.cancel();
    _restFallbackTimer?.cancel();
    _debounceTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _priceController.close();
    _historyController.close();
    _connectionStateController.close();
  }
}
