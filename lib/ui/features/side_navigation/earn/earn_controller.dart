import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';

class EarnProduct {
  final int id;
  final String coin;
  final double apr;
  final int lockDays;
  final double minAmount;
  final double maxAmount;
  final String? coinIcon;

  EarnProduct({
    required this.id,
    required this.coin,
    required this.apr,
    required this.lockDays,
    required this.minAmount,
    required this.maxAmount,
    this.coinIcon,
  });

  factory EarnProduct.fromJson(Map<String, dynamic> json) {
    return EarnProduct(
      id: json['id'] ?? 0,
      coin: json['coin'] ?? '',
      apr: double.tryParse(json['apr'].toString()) ?? 0,
      lockDays: int.tryParse(json['lock_days'].toString()) ?? 0,
      minAmount: double.tryParse(json['min_amount'].toString()) ?? 0,
      maxAmount: double.tryParse(json['max_amount'].toString()) ?? 0,
      coinIcon: json['coin_icon'],
    );
  }
}

class EarnSubscription {
  final int id;
  final String coin;
  final double apr;
  final int lockDays;
  final double amount;
  final double accruedInterest;
  final String planType;
  final String? lockUntil;
  final bool isRedeemable;
  final int daysLeft;
  final int autoReinvest;
  final int reinvestCount;

  EarnSubscription({
    required this.id,
    required this.coin,
    required this.apr,
    required this.lockDays,
    required this.amount,
    required this.accruedInterest,
    required this.planType,
    this.lockUntil,
    required this.isRedeemable,
    required this.daysLeft,
    required this.autoReinvest,
    required this.reinvestCount,
  });

  factory EarnSubscription.fromJson(Map<String, dynamic> json) {
    return EarnSubscription(
      id: json['id'] ?? 0,
      coin: json['coin'] ?? '',
      apr: double.tryParse(json['apr'].toString()) ?? 0,
      lockDays: int.tryParse(json['lock_days'].toString()) ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      accruedInterest: double.tryParse(json['accrued_interest'].toString()) ?? 0,
      planType: json['plan_type'] ?? 'flexible',
      lockUntil: json['lock_until'],
      isRedeemable: json['is_redeemable'] == true || json['is_redeemable'] == 1,
      daysLeft: int.tryParse(json['days_left'].toString()) ?? 0,
      autoReinvest: int.tryParse(json['auto_reinvest'].toString()) ?? 0,
      reinvestCount: int.tryParse(json['reinvest_count'].toString()) ?? 0,
    );
  }
}

class EarnTransaction {
  final int id;
  final String type;
  final String coin;
  final double amount;
  final String createdAt;

  EarnTransaction({
    required this.id,
    required this.type,
    required this.coin,
    required this.amount,
    required this.createdAt,
  });

  factory EarnTransaction.fromJson(Map<String, dynamic> json) {
    return EarnTransaction(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      coin: json['coin'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class EarnController extends GetxController {
  static const String _baseUrl = 'https://api.trapix.com';

  final RxList<EarnProduct> products = <EarnProduct>[].obs;
  final RxList<EarnSubscription> positions = <EarnSubscription>[].obs;
  final RxList<EarnTransaction> history = <EarnTransaction>[].obs;
  final RxMap<String, double> balances = <String, double>{}.obs;
  final RxBool isLoadingProducts = false.obs;
  final RxBool isLoadingPositions = false.obs;
  final RxBool isLoadingHistory = false.obs;

  String get _userId => gUserRx.value.id > 0 ? gUserRx.value.id.toString() : '';

  Future<void> fetchProducts() async {
    isLoadingProducts.value = true;
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/tf/products'));
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        final list = (json['data'] as List).map((e) => EarnProduct.fromJson(e)).toList();
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
      final res = await http.get(Uri.parse('$_baseUrl/api/tf/earn/balances?user_id=$_userId'));
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        final map = <String, double>{};
        for (final item in (json['data'] as List)) {
          map[item['coin']] = double.tryParse(item['balance'].toString()) ?? 0;
        }
        balances.assignAll(map);
      }
    } catch (e) {
      showToast(e.toString());
    }
  }

  Future<void> fetchPositions() async {
    if (_userId.isEmpty) return;
    isLoadingPositions.value = true;
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/tf/earn/positions?user_id=$_userId'));
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        final list = (json['data'] as List).map((e) => EarnSubscription.fromJson(e)).toList();
        positions.assignAll(list);
      }
    } catch (e) {
      showToast(e.toString());
    } finally {
      isLoadingPositions.value = false;
    }
  }

  Future<void> fetchHistory() async {
    if (_userId.isEmpty) return;
    isLoadingHistory.value = true;
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/tf/earn/history?user_id=$_userId'));
      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        final data = json['data']['data'] as List? ?? [];
        final list = data.map((e) => EarnTransaction.fromJson(e)).toList();
        history.assignAll(list);
      }
    } catch (e) {
      showToast(e.toString());
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<bool> subscribe({
    required int productId,
    required double amount,
    required bool autoReinvest,
  }) async {
    if (_userId.isEmpty) {
      showToast('Please login first');
      return false;
    }
    showLoadingDialog();
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/tf/earn/subscribe?user_id=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'product_id': productId,
          'amount': amount,
          'auto_reinvest': autoReinvest,
        }),
      );
      hideLoadingDialog();
      final json = jsonDecode(res.body);
      final success = json['success'] == true;
      showToast(json['message'] ?? (success ? 'Subscribed!' : 'Failed'), isError: !success);
      if (success) {
        await fetchPositions();
        await fetchBalances();
      }
      return success;
    } catch (e) {
      hideLoadingDialog();
      showToast(e.toString());
      return false;
    }
  }

  Future<void> redeem(int subscriptionId) async {
    if (_userId.isEmpty) return;
    showLoadingDialog();
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/tf/earn/redeem?user_id=$_userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'subscription_id': subscriptionId}),
      );
      hideLoadingDialog();
      final json = jsonDecode(res.body);
      final success = json['success'] == true;
      showToast(json['message'] ?? (success ? 'Redeemed!' : 'Failed'), isError: !success);
      if (success) {
        await fetchPositions();
        await fetchBalances();
      }
    } catch (e) {
      hideLoadingDialog();
      showToast(e.toString());
    }
  }
}