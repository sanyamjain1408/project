import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

class DualPair {
  final String baseCoin;
  final String quoteCoin;
  DualPair({required this.baseCoin, required this.quoteCoin});
  factory DualPair.fromJson(Map<String, dynamic> json) => DualPair(
    baseCoin:  json['base_coin']  ?? '',
    quoteCoin: json['quote_coin'] ?? '',
  );
}

class DualProduct {
  final int    id;
  final String baseCoin;
  final String quoteCoin;
  final String depositCoin;
  final double targetPrice;
  final double apr;
  final int    termDays;
  final String expiryDate;
  final String strategy;
  final double minAmount;
  final double maxAmount;

  DualProduct({
    required this.id,
    required this.baseCoin,
    required this.quoteCoin,
    required this.depositCoin,
    required this.targetPrice,
    required this.apr,
    required this.termDays,
    required this.expiryDate,
    required this.strategy,
    required this.minAmount,
    required this.maxAmount,
  });

  factory DualProduct.fromJson(Map<String, dynamic> json) => DualProduct(
    id:          json['id'] ?? 0,
    baseCoin:    json['base_coin']    ?? '',
    quoteCoin:   json['quote_coin']   ?? '',
    depositCoin: json['deposit_coin'] ?? '',
    targetPrice: double.tryParse(json['target_price'].toString()) ?? 0,
    apr:         double.tryParse(json['apr'].toString()) ?? 0,
    termDays:    int.tryParse(json['term_days'].toString()) ?? 0,
    expiryDate:  json['expiry_date']  ?? '',
    strategy:    json['strategy']     ?? 'sell_high',
    minAmount:   double.tryParse(json['min_amount'].toString()) ?? 0,
    maxAmount:   double.tryParse(json['max_amount'].toString()) ?? 0,
  );
}

class DualSubscription {
  final int    id;
  final String baseCoin;
  final String quoteCoin;
  final String depositCoin;
  final double amount;
  final double targetPrice;
  final double apr;
  final double yieldRate;
  final String strategy;
  final String status;
  final String expiryDate;
  final String? payoutCoin;
  final double? payoutAmount;

  DualSubscription({
    required this.id,
    required this.baseCoin,
    required this.quoteCoin,
    required this.depositCoin,
    required this.amount,
    required this.targetPrice,
    required this.apr,
    required this.yieldRate,
    required this.strategy,
    required this.status,
    required this.expiryDate,
    this.payoutCoin,
    this.payoutAmount,
  });

  factory DualSubscription.fromJson(Map<String, dynamic> json) => DualSubscription(
    id:           json['id'] ?? 0,
    baseCoin:     json['base_coin']    ?? '',
    quoteCoin:    json['quote_coin']   ?? '',
    depositCoin:  json['deposit_coin'] ?? '',
    amount:       double.tryParse(json['amount'].toString()) ?? 0,
    targetPrice:  double.tryParse(json['target_price'].toString()) ?? 0,
    apr:          double.tryParse(json['apr'].toString()) ?? 0,
    yieldRate:    double.tryParse(json['yield_rate'].toString()) ?? 0,
    strategy:     json['strategy']    ?? '',
    status:       json['status']      ?? '',
    expiryDate:   json['expiry_date'] ?? '',
    payoutCoin:   json['payout_coin'],
    payoutAmount: json['payout_amount'] != null ? double.tryParse(json['payout_amount'].toString()) : null,
  );
}

class DualInvestmentController extends GetxController {
  static const String _baseUrl = 'https://api.trapix.com';

  final RxList<DualPair>         pairs         = <DualPair>[].obs;
  final RxList<DualProduct>      products      = <DualProduct>[].obs;
  final RxList<DualSubscription> subscriptions = <DualSubscription>[].obs;
  final RxMap<String, double>    balances      = <String, double>{}.obs;
  final Rx<DualPair?>            selectedPair  = Rx<DualPair?>(null);
  final RxString                 strategy      = 'sell_high'.obs;
  final RxnInt                   termFilter    = RxnInt();
  final RxBool                   isLoadingProducts = false.obs;
  final RxBool                   isLoadingSubs     = false.obs;

  String get _userId => gUserRx.value.id > 0 ? gUserRx.value.id.toString() : '';

  @override
  void onInit() {
    super.onInit();
    fetchPairs();
    if (_userId.isNotEmpty) fetchBalances();
  }

  Future<void> fetchPairs() async {
    try {
      final res  = await http.get(Uri.parse('$_baseUrl/api/dual/pairs'));
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        final list = (json['data'] as List).map((e) => DualPair.fromJson(e)).toList();
        pairs.assignAll(list);
        if (list.isNotEmpty) {
          selectedPair.value = list.first;
          fetchProducts();
        }
      }
    } catch (e) {
      showToast(e.toString());
    }
  }

  Future<void> fetchProducts() async {
    final pair = selectedPair.value;
    if (pair == null) return;
    isLoadingProducts.value = true;
    try {
      String url = '$_baseUrl/api/dual/products?base_coin=${pair.baseCoin}&strategy=${strategy.value}';
      if (termFilter.value != null) url += '&term_days=${termFilter.value}';
      final res  = await http.get(Uri.parse(url));
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        final list = (json['data'] as List).map((e) => DualProduct.fromJson(e)).toList();
        products.assignAll(list);
      }
    } catch (e) {
      showToast(e.toString());
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> fetchBalances() async {
    if (_userId.isEmpty) return;
    try {
      final res  = await http.get(Uri.parse('$_baseUrl/api/dual/balances?user_id=$_userId'));
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        final map = <String, double>{};
        (json['data'] as Map).forEach((k, v) => map[k] = double.tryParse(v.toString()) ?? 0);
        balances.assignAll(map);
      }
    } catch (_) {}
  }

  Future<void> fetchSubscriptions() async {
    if (_userId.isEmpty) return;
    isLoadingSubs.value = true;
    try {
      final res  = await http.get(Uri.parse('$_baseUrl/api/dual/subscriptions?user_id=$_userId&status=all'));
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        final list = (json['data'] as List).map((e) => DualSubscription.fromJson(e)).toList();
        subscriptions.assignAll(list);
      }
    } catch (_) {}
    finally { isLoadingSubs.value = false; }
  }

  Future<bool> subscribe(int productId, double amount) async {
    if (_userId.isEmpty) { showToast('Please login first'); return false; }
    showLoadingDialog();
    try {
      final res  = await http.post(
        Uri.parse('$_baseUrl/api/dual/subscribe?user_id=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'product_id': productId, 'amount': amount}),
      );
      hideLoadingDialog();
      final json    = jsonDecode(res.body);
      final success = json['success'] == true;
      showToast(json['message'] ?? (success ? 'Subscribed!' : 'Failed'), isError: !success);
      if (success) { await fetchBalances(); await fetchSubscriptions(); }
      return success;
    } catch (e) {
      hideLoadingDialog();
      showToast(e.toString());
      return false;
    }
  }

  void setStrategy(String s) {
    strategy.value = s;
    fetchProducts();
  }

  void setTermFilter(int? t) {
    termFilter.value = t;
    fetchProducts();
  }

  void setSelectedPair(DualPair p) {
    selectedPair.value = p;
    fetchProducts();
  }
}