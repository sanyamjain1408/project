import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/remote/future_socket.dart';
import 'future_models.dart';

class NewFutureController extends GetxController {
  final pairs = <FuturePair>[].obs;
  final currentPair = Rxn<FuturePair>();
  final positions = <FuturePosition>[].obs;
  final orders = <FutureOrder>[].obs;
  final balance = 0.0.obs;
  final isLoggedIn = false.obs;
  final orderLoading = false.obs;
  final priceGoingUp = true.obs;

  // Live order book from WebSocket
  final orderBookBids = <List<String>>[].obs;
  final orderBookAsks = <List<String>>[].obs;

  final _ws = FutureWebSocket();
  Timer? _fallbackTimer;
  String lastError = '';

  static const _base = 'https://api.trapix.com/api/v1/future';

  @override
  void onInit() {
    super.onInit();
    _checkLogin();
    fetchPairs();
  }

  @override
  void onClose() {
    _ws.dispose();
    _fallbackTimer?.cancel();
    super.onClose();
  }

  void _checkLogin() {
    final token = getFutureToken();
    isLoggedIn.value = token.isNotEmpty;
    if (isLoggedIn.value) {
      fetchBalance();
      fetchPositions();
      fetchOrders();
    }
  }

  Future<void> fetchPairs() async {
    try {
      final res = await http.get(Uri.parse('$_base/pairs'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          final list = (data['data'] as List).map((e) => FuturePair.fromJson(e)).toList();
          pairs.value = list;
          if (currentPair.value == null && list.isNotEmpty) {
            selectPair(list.firstWhere((p) => p.symbol == 'BTCUSDT', orElse: () => list.first));
          }
        }
      }
    } catch (_) {}
  }

  void selectPair(FuturePair pair) {
    currentPair.value = pair;
    orderBookBids.clear();
    orderBookAsks.clear();
    _fallbackTimer?.cancel();

    if (_ws.isAlive) {
      _ws.changeSymbol(pair.symbol);
    } else {
      _ws.connect(pair.symbol, _onWsMessage);
    }
    // Fallback HTTP poll in case WS drops — every 5s
    _fallbackTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_ws.isAlive) _fetchTickerAndBook(pair.symbol);
    });
  }

  void _onWsMessage(Map<String, dynamic> msg) {
    // Update ticker
    final ticker = msg['ticker'] as Map<String, dynamic>?;
    if (ticker != null && currentPair.value != null) {
      final prev = currentPair.value!;
      final newPrice = double.tryParse(ticker['price']?.toString() ?? '') ?? prev.currentPrice;
      priceGoingUp.value = newPrice >= prev.currentPrice;
      currentPair.value = FuturePair(
        id: prev.id,
        symbol: prev.symbol,
        baseCurrency: prev.baseCurrency,
        quoteCurrency: prev.quoteCurrency,
        currentPrice: newPrice,
        markPrice: double.tryParse(ticker['mark_price']?.toString() ?? '') ?? prev.markPrice,
        indexPrice: double.tryParse(ticker['index_price']?.toString() ?? '') ?? prev.indexPrice,
        priceChange24h: double.tryParse(ticker['change_24h']?.toString() ?? '') ?? prev.priceChange24h,
        high24h: double.tryParse(ticker['high_24h']?.toString() ?? '') ?? prev.high24h,
        low24h: double.tryParse(ticker['low_24h']?.toString() ?? '') ?? prev.low24h,
        volume24h: double.tryParse(ticker['volume_24h']?.toString() ?? '') ?? prev.volume24h,
        pricePrecision: prev.pricePrecision,
        quantityPrecision: prev.quantityPrecision,
        fundingRate: double.tryParse(ticker['funding_rate']?.toString() ?? '') ?? prev.fundingRate,
        makerFee: prev.makerFee,
        takerFee: prev.takerFee,
        leverageMin: prev.leverageMin,
        leverageMax: prev.leverageMax,
        leverageStep: prev.leverageStep,
      );
      // Also update in pairs list
      final idx = pairs.indexWhere((p) => p.symbol == prev.symbol);
      if (idx >= 0) pairs[idx] = currentPair.value!;
    }

    // Update order book
    final ob = msg['orderbook'] as Map<String, dynamic>?;
    if (ob != null) {
      final bids = ob['bids'] as List?;
      final asks = ob['asks'] as List?;
      if (bids != null) {
        orderBookBids.value = bids
            .map((e) => [(e[0] as Object).toString(), (e[1] as Object).toString()])
            .toList();
      }
      if (asks != null) {
        orderBookAsks.value = asks
            .map((e) => [(e[0] as Object).toString(), (e[1] as Object).toString()])
            .toList();
      }
    }
  }

  Future<void> _fetchTickerAndBook(String symbol) async {
    await Future.wait([_fetchTicker(symbol), _fetchOrderBook(symbol)]);
  }

  Future<void> _fetchTicker(String symbol) async {
    try {
      final res = await http.get(Uri.parse('$_base/ticker/$symbol'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          final updated = FuturePair.fromJson(data['data']);
          final prevPrice = currentPair.value?.currentPrice ?? updated.currentPrice;
          priceGoingUp.value = updated.currentPrice >= prevPrice;
          currentPair.value = updated;
          final idx = pairs.indexWhere((p) => p.symbol == symbol);
          if (idx >= 0) pairs[idx] = updated;
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchOrderBook(String symbol) async {
    try {
      final res = await http.get(Uri.parse('$_base/orderbook/$symbol'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          final d = data['data'] as Map<String, dynamic>;
          orderBookBids.value = (d['bids'] as List? ?? [])
              .map((e) => [(e[0] as Object).toString(), (e[1] as Object).toString()])
              .toList();
          orderBookAsks.value = (d['asks'] as List? ?? [])
              .map((e) => [(e[0] as Object).toString(), (e[1] as Object).toString()])
              .toList();
        }
      }
    } catch (_) {}
  }

  Future<void> fetchBalance() async {
    try {
      final token = getFutureToken();
      if (token.isEmpty) return;
      final res = await http.get(
        Uri.parse('$_base/balance'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          balance.value = double.tryParse(data['data']?['balance']?.toString() ?? '0') ?? 0;
        }
      }
    } catch (_) {}
  }

  Future<void> fetchPositions() async {
    try {
      final token = getFutureToken();
      if (token.isEmpty) return;
      final res = await http.get(
        Uri.parse('$_base/positions'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          positions.value = (data['data'] as List).map((e) => FuturePosition.fromJson(e)).toList();
        }
      }
    } catch (_) {}
  }

  Future<void> fetchOrders() async {
    try {
      final token = getFutureToken();
      if (token.isEmpty) return;
      final res = await http.get(
        Uri.parse('$_base/orders'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          orders.value = (data['data'] as List).map((e) => FutureOrder.fromJson(e)).toList();
        }
      }
    } catch (_) {}
  }

  Future<bool> placeOrder({
    required String symbol,
    required String side,
    required int leverage,
    required double margin,
    required double quantity,
    required String orderType,
    required double price,
    required String marginMode,
    double? takeProfit,
    double? stopLoss,
    double? stopPrice,
  }) async {
    try {
      orderLoading.value = true;
      lastError = '';
      final token = getFutureToken();
      if (token.isEmpty) {
        lastError = 'Please login first';
        return false;
      }
      final body = {
        'symbol': symbol,
        'side': side,
        'leverage': leverage,
        'margin': margin,
        'quantity': quantity,
        'order_type': orderType,
        'price': price,
        'margin_mode': marginMode,
        if (takeProfit != null && takeProfit > 0) 'take_profit': takeProfit,
        if (stopLoss != null && stopLoss > 0) 'stop_loss': stopLoss,
        if (stopPrice != null && stopPrice > 0) 'stop_price': stopPrice,
      };
      final res = await http.post(
        Uri.parse('$_base/order'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          fetchPositions();
          fetchOrders();
          fetchBalance();
          return true;
        }
        lastError = data['message']?.toString() ?? 'Order failed';
      } else {
        try {
          final data = jsonDecode(res.body);
          lastError = data['message']?.toString() ?? 'HTTP ${res.statusCode}';
        } catch (_) {
          lastError = 'HTTP ${res.statusCode}';
        }
      }
      return false;
    } catch (e) {
      lastError = e.toString();
      return false;
    } finally {
      orderLoading.value = false;
    }
  }

  Future<void> closePosition(int positionId) async {
    try {
      final token = getFutureToken();
      if (token.isEmpty) return;
      final res = await http.post(
        Uri.parse('$_base/close/$positionId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          fetchPositions();
          fetchBalance();
        }
      }
    } catch (_) {}
  }

  Future<void> cancelOrder(int orderId) async {
    try {
      final token = getFutureToken();
      if (token.isEmpty) return;
      final res = await http.delete(
        Uri.parse('$_base/order/$orderId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) fetchOrders();
      }
    } catch (_) {}
  }

  Future<void> updateTpSl(int positionId, double tp, double sl) async {
    try {
      final token = getFutureToken();
      if (token.isEmpty) return;
      final res = await http.patch(
        Uri.parse('$_base/positions/$positionId/tpsl'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'take_profit': tp, 'stop_loss': sl}),
      );
      if (res.statusCode == 200) {
        fetchPositions();
      }
    } catch (_) {}
  }
}
