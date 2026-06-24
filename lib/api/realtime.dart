import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'client.dart';
import 'endpoints.dart';
import 'models.dart';

class WatchlistTick {
  final String stockCode;
  final double price;
  final double change;
  final double changeRate;
  final int? volume;
  final double? tradeValue;

  const WatchlistTick({
    required this.stockCode,
    required this.price,
    required this.change,
    required this.changeRate,
    this.volume,
    this.tradeValue,
  });

  factory WatchlistTick.fromJson(Map<String, Object?> json) => WatchlistTick(
        stockCode: json['stock_code'] as String,
        price: (json['price'] as num).toDouble(),
        change: (json['change'] as num).toDouble(),
        changeRate: (json['change_rate'] as num).toDouble(),
        volume: (json['volume'] as num?)?.toInt(),
        tradeValue: (json['trade_value'] as num?)?.toDouble(),
      );
}

sealed class WatchlistRealtimeEvent {
  const WatchlistRealtimeEvent();
}

class WatchlistConnected extends WatchlistRealtimeEvent {
  const WatchlistConnected();
}

class WatchlistDisconnected extends WatchlistRealtimeEvent {
  final bool canReconnect;

  const WatchlistDisconnected({required this.canReconnect});
}

class WatchlistTickEvent extends WatchlistRealtimeEvent {
  final WatchlistTick tick;

  const WatchlistTickEvent(this.tick);
}

class WatchlistSnapshotEvent extends WatchlistRealtimeEvent {
  final List<WatchlistItem> items;

  const WatchlistSnapshotEvent(this.items);
}

class WatchlistTickerChannel {
  final List<String> codes;
  final Duration fallbackInterval;
  final _controller = StreamController<WatchlistRealtimeEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pollTimer;
  bool _opened = false;
  bool _disposed = false;

  WatchlistTickerChannel({
    required this.codes,
    this.fallbackInterval = const Duration(seconds: 10),
  });

  Stream<WatchlistRealtimeEvent> get stream => _controller.stream;

  void start() {
    if (_disposed || codes.isEmpty) return;
    final uri = Uri.parse(api.wsUrl('/ws/watchlist?codes=${codes.join(',')}'));
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleMessage,
        onDone: _handleDone,
        onError: (_) => _handleDone(),
        cancelOnError: false,
      );
      _opened = true;
      _controller.add(const WatchlistConnected());
    } catch (_) {
      _startPollingFallback();
    }
  }

  Future<void> reconnect() async {
    await _closeSocket();
    _stopPollingFallback();
    _opened = false;
    start();
  }

  Future<void> dispose() async {
    _disposed = true;
    _stopPollingFallback();
    await _closeSocket();
    await _controller.close();
  }

  void _handleMessage(dynamic message) {
    if (_disposed) return;
    try {
      final decoded = jsonDecode(message as String);
      if (decoded is! Map<String, Object?>) return;
      _controller.add(WatchlistTickEvent(WatchlistTick.fromJson(decoded)));
    } catch (_) {
      // malformed realtime messages are ignored, matching the web implementation
    }
  }

  void _handleDone() {
    if (_disposed) return;
    _controller.add(WatchlistDisconnected(canReconnect: _opened));
    if (!_opened) _startPollingFallback();
  }

  void _startPollingFallback() {
    if (_disposed || _pollTimer != null || codes.isEmpty) return;
    _pollTimer = Timer.periodic(fallbackInterval, (_) async {
      try {
        final items = await fetchWatchlistItems(codes);
        if (!_disposed) _controller.add(WatchlistSnapshotEvent(items));
      } catch (_) {
        // keep polling, same as web fallback
      }
    });
  }

  void _stopPollingFallback() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _closeSocket() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }
}
