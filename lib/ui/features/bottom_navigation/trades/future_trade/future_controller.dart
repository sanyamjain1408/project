import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'future_models.dart';

class NewFutureController extends GetxController {
  final pairs = <FuturePair>[].obs;
  final currentPair = Rxn<FuturePair>();
  final positions = <FuturePosition>[].obs;
  final orders = <FutureOrder>[].obs;
  final balance = 0.0.obs;
  final isLoggedIn = false.obs;
  final orderLoading = false.obs;
  final seed = 0.obs;
  final priceGoingUp = true.obs;
  Timer? _seedTimer;
  Timer? _priceTimer;

  @override
  void onInit() {
    super.onInit();
    _seedTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      seed.value = math.Random().nextInt(100000);
    });
    _checkLogin();
    fetchPairs();
  }

  @override
  void onClose() {
    _seedTimer?.cancel();
    _priceTimer?.cancel();
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
      final res = await http.get(Uri.parse('https://api.trapix.com/api/v1/future/pairs'));
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
    _priceTimer?.cancel();
    _startPricePoll(pair.symbol);
  }

  void _startPricePoll(String symbol) {
    _priceTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final res = await http.get(Uri.parse('https://api.trapix.com/api/v1/future/ticker/$symbol'));
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
    });
  }

  Future<void> fetchBalance() async {
    try {
      final token = getFutureToken();
      if (token.isEmpty) return;
      final res = await http.get(
        Uri.parse('https://api.trapix.com/api/v1/future/balance'),
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
        Uri.parse('https://api.trapix.com/api/v1/future/positions'),
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
        Uri.parse('https://api.trapix.com/api/v1/future/orders'),
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
    required String orderType,
    required double price,
    required String marginMode,
    double? takeProfit,
    double? stopLoss,
    double? stopPrice,
  }) async {
    try {
      orderLoading.value = true;
      final token = getFutureToken();
      if (token.isEmpty) return false;
      final body = {
        'symbol': symbol,
        'side': side,
        'leverage': leverage,
        'margin': margin,
        'order_type': orderType,
        'price': price,
        'margin_mode': marginMode,
        if (takeProfit != null && takeProfit > 0) 'take_profit': takeProfit,
        if (stopLoss != null && stopLoss > 0) 'stop_loss': stopLoss,
        if (stopPrice != null && stopPrice > 0) 'stop_price': stopPrice,
      };
      final res = await http.post(
        Uri.parse('https://api.trapix.com/api/v1/future/order'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          fetchPositions();
          fetchBalance();
          return true;
        }
      }
      return false;
    } catch (_) {
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
        Uri.parse('https://api.trapix.com/api/v1/future/close/$positionId'),
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

  Future<void> updateTpSl(int positionId, double tp, double sl) async {
    try {
      final token = getFutureToken();
      if (token.isEmpty) return;
      final res = await http.patch(
        Uri.parse('https://api.trapix.com/api/v1/future/positions/$positionId/tpsl'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'take_profit': tp, 'stop_loss': sl}),
      );
      if (res.statusCode == 200) {
        fetchPositions();
      }
    } catch (_) {}
  }
}
