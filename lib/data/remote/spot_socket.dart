import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:tradexpro_flutter/utils/common_utils.dart';

typedef SpotWsCallback = void Function(Map<String, dynamic> msg);

/// Connects to wss://api.trapix.com/ws/spot
/// Send:    {"type":"subscribe","symbol":"BTCUSDT"}
/// Receive: {"type":"update","symbol":"BTCUSDT","ticker":{...},"orderbook":{...},"trades":[...]}
class SpotWebSocket {
  static const _wsUrl = 'wss://trapix.com/ws/spot';
  static const _reconnectDelay = Duration(seconds: 3);

  WebSocket? _ws;
  Timer? _reconnTimer;
  String _currentSymbol = '';
  SpotWsCallback? _onMessage;
  bool _disposed = false;

  bool get isAlive =>
      _ws != null && _ws!.readyState == WebSocket.open;

  Future<void> connect(String symbol, SpotWsCallback callback) async {
    _disposed = false;
    _currentSymbol = symbol;
    _onMessage = callback;
    await _connect();
  }

  void changeSymbol(String symbol) {
    _currentSymbol = symbol;
    if (isAlive) {
      _send({'type': 'subscribe', 'symbol': symbol});
    } else {
      _reconnTimer?.cancel();
      _connect();
    }
  }

  Future<void> _connect() async {
    if (_disposed) return;
    try {
      _ws = await WebSocket.connect(_wsUrl);
      printFunction('SpotWS', 'connected → $_currentSymbol');
      _send({'type': 'subscribe', 'symbol': _currentSymbol});
      _ws!.listen(
        _onData,
        onDone: _onDisconnect,
        onError: (_) => _onDisconnect(),
        cancelOnError: true,
      );
    } catch (e) {
      printFunction('SpotWS connect error', e);
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    try {
      final msg = json.decode(raw as String) as Map<String, dynamic>;
      if (msg['type'] == 'update' && msg['symbol'] == _currentSymbol) {
        _onMessage?.call(msg);
      }
    } catch (_) {}
  }

  void _onDisconnect() {
    printFunction('SpotWS', 'disconnected');
    _scheduleReconnect();
  }

  void _send(Map<String, dynamic> msg) {
    try { _ws?.add(json.encode(msg)); } catch (_) {}
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnTimer?.cancel();
    _reconnTimer = Timer(_reconnectDelay, _connect);
  }

  void dispose() {
    _disposed = true;
    _reconnTimer?.cancel();
    _reconnTimer = null;
    try { _ws?.close(); } catch (_) {}
    _ws = null;
  }
}
