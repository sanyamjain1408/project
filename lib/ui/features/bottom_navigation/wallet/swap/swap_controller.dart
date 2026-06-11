import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

import '../wallet_controller.dart';

const String _kBase = 'https://api.trapix.com';


// ── SwapCoin model ────────────────────────────────────────────────
class SwapCoin {
  final int id;
  final String name;
  final String symbol;
  final double feePercentage;
  String? iconUrl;
  double availableBalance;
  double usdPrice;

  SwapCoin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.feePercentage,
    this.iconUrl,
    this.availableBalance = 0,
    this.usdPrice = 0,
  });

  factory SwapCoin.fromJson(Map<String, dynamic> j) {
    return SwapCoin(
      id: j['id'] as int,
      name: (j['name'] as String? ?? ''),
      symbol: (j['symbol'] as String? ?? ''),
      feePercentage: makeDouble(j['fee_percentage']),
      iconUrl: j['coin_icon'] as String? ??
          j['icon'] as String? ??
          j['icon_url'] as String? ??
          j['image'] as String?,
    );
  }
}

// ── Controller ────────────────────────────────────────────────────
class SwapController extends GetxController {
  RxList<SwapCoin> coinList = <SwapCoin>[].obs;
  Rx<SwapCoin?> selectedFromCoin = Rx<SwapCoin?>(null);
  Rx<SwapCoin?> selectedToCoin = Rx<SwapCoin?>(null);

  final toEditController = TextEditingController();
  final fromEditController = TextEditingController();

  final RxBool isLoading = true.obs;
  final RxBool isRateLoading = false.obs;
  final RxString fromAmountRx = "1".obs;

  Timer? _rateDebounce;
  bool _fetchingCoins = false;

  final RxDouble rate = 0.0.obs;
  final RxDouble convertRate = 0.0.obs;
  final RxDouble feeAmount = 0.0.obs;
  final RxDouble feePercentage = 0.0.obs;
  final RxDouble grossReceive = 0.0.obs;

  @override
  void onClose() {
    _rateDebounce?.cancel();
    fromEditController.dispose();
    toEditController.dispose();
    super.onClose();
  }

  bool get canSwap =>
      coinList.isNotEmpty &&
      selectedFromCoin.value != null &&
      selectedToCoin.value != null &&
      makeDouble(fromAmountRx.value) > 0;

  // ── Auth headers ─────────────────────────────────────────────────
  Map<String, String> _authHeaders() {
    final token = GetStorage().read(PreferenceKey.accessToken) ?? '';
    final type = GetStorage().read(PreferenceKey.accessType) ?? 'Bearer';
    final secret = dotenv.env[EnvKeyValue.kApiSecret] ?? '';
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': '$type $token',
      'userapisecret': secret,
    };
  }

  Map<String, String> _publicHeaders() => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  // ── Load coins ───────────────────────────────────────────────────
  Future<void> getCoinSwapApp({Wallet? preWallet, CoinPair? pair}) async {
    if (_fetchingCoins) return;
    _fetchingCoins = true;
    isLoading.value = true;

    try {
      // 1. Fetch swap coins list
      // print("[SWAP] Fetching swap coins...");
      final coinsResp = await http
          .get(Uri.parse('$_kBase/api/v1/swap/coins'), headers: _publicHeaders())
          .timeout(const Duration(seconds: 15));

      // print("[SWAP] Coins status: ${coinsResp.statusCode}");
      // print("[SWAP] Coins body: ${coinsResp.body}");

      final coinsBody = jsonDecode(coinsResp.body) as Map<String, dynamic>;
      if (coinsBody['success'] != true) {
        showToast(coinsBody['message'] ?? 'Failed to load swap coins');
        return;
      }

      final rawCoins = coinsBody['data'] as List;
      final coins = rawCoins.map((e) => SwapCoin.fromJson(e)).toList();

      // 2. Fetch balances + icons + prices from our own API
      await _enrichBalances(coins);

      coinList.value = coins;

      // print("[SWAP] ── FINAL COIN SUMMARY ──");
      // for (var c in coins) {
      //   print("${c.symbol} | Bal: ${c.availableBalance} | USD: ${c.usdPrice} | Icon: ${c.iconUrl}");
      // }

      // 5. Set initial selections
      if (preWallet != null) {
        final match = coins.firstWhereOrNull(
            (c) => c.symbol.toUpperCase() == preWallet.coinType?.toUpperCase());
        selectedFromCoin.value = match ?? (coins.isNotEmpty ? coins.first : null);
      } else if (pair != null) {
        selectedFromCoin.value = coins.firstWhereOrNull(
            (c) => c.symbol.toUpperCase() == pair.parentCoinName?.toUpperCase());
        selectedToCoin.value = coins.firstWhereOrNull(
            (c) => c.symbol.toUpperCase() == pair.childCoinName?.toUpperCase());
      }

      if (selectedFromCoin.value == null && coins.isNotEmpty) {
        selectedFromCoin.value = coins.first;
      }
      if (selectedToCoin.value == null && coins.length > 1) {
        selectedToCoin.value = coins[1];
      }

      getAndSetCoinRate();
    } catch (e) {
      // print("[SWAP] Exception in getCoinSwapApp: $e");
      showToast('Please check your internet connection'.tr);
    } finally {
      isLoading.value = false;
      _fetchingCoins = false;
    }
  }

  // ── Enrich balances — tries coin-swap-app first, then wallet-list ─
  Future<void> _enrichBalances(List<SwapCoin> coins) async {
    // Fast path: WalletController already loaded in memory
    if (Get.isRegistered<WalletController>()) {
      final wc = Get.find<WalletController>();
      if (wc.walletList.isNotEmpty) {
        for (final coin in coins) {
          final w = wc.walletList.firstWhereOrNull(
              (w) => (w.coinType ?? '').toUpperCase() == coin.symbol.toUpperCase());
          if (w != null) {
            if (coin.iconUrl == null || coin.iconUrl!.isEmpty) coin.iconUrl = w.coinIcon;
            coin.availableBalance = makeDouble(w.balance ?? w.availableBalance);
            if (coin.usdPrice == 0) {
              final usd = makeDouble(w.availableBalanceUsd ?? 0);
              if (coin.availableBalance > 0) coin.usdPrice = usd / coin.availableBalance;
            }
          }
        }
        return;
      }
    }

    // API path: fetch directly (works even when Wallet tab never opened)
    // Try /api/coin-swap-app first, fallback to /api/wallet-list
    bool filled = false;
    try {
      final r = await http
          .get(Uri.parse('$_kBase/api/coin-swap-app'), headers: _authHeaders())
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final wallets = (body['data'] is Map ? body['data']['wallets'] : null) as List? ?? [];
        if (wallets.isNotEmpty) {
          for (final coin in coins) {
            final match = wallets.firstWhereOrNull(
              (w) => (w['coin_type'] ?? '').toString().toUpperCase() == coin.symbol.toUpperCase());
            if (match == null) continue;
            if (coin.iconUrl == null || coin.iconUrl!.isEmpty) coin.iconUrl = match['coin_icon'] as String?;
            coin.availableBalance = makeDouble(match['balance'] ?? match['available_balance']);
            if (coin.usdPrice == 0) {
              final usd = makeDouble(match['available_balance_usd'] ?? 0);
              if (coin.availableBalance > 0) coin.usdPrice = usd / coin.availableBalance;
            }
          }
          filled = true;
        }
      }
    } catch (_) {}

    if (filled) return;

    // Final fallback: wallet-list endpoint
    try {
      final r = await http
          .get(Uri.parse('$_kBase/api/wallet-list?page=1&per_page=200'), headers: _authHeaders())
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return;
      final body = jsonDecode(r.body);
      final wallets = (body['data']?['wallets']?['data'] ?? body['data']?['data'] ?? body['data'] ?? []) as List;
      for (final coin in coins) {
        final match = wallets.firstWhereOrNull(
          (w) => (w['coin_type'] ?? '').toString().toUpperCase() == coin.symbol.toUpperCase());
        if (match == null) continue;
        if (coin.iconUrl == null || coin.iconUrl!.isEmpty) coin.iconUrl = match['coin_icon'] as String?;
        coin.availableBalance = makeDouble(match['balance'] ?? match['available_balance']);
        if (coin.usdPrice == 0) {
          final usd = makeDouble(match['available_balance_usd'] ?? 0);
          if (coin.availableBalance > 0) coin.usdPrice = usd / coin.availableBalance;
        }
      }
    } catch (_) {}
  }

  // ── Amount changed ───────────────────────────────────────────────
  void onFromAmountChanged(String v) {
    fromAmountRx.value = v.isEmpty ? "0" : v;
    _rateDebounce?.cancel();
    _rateDebounce = Timer(const Duration(milliseconds: 700), getAndSetCoinRate);
  }

  // ── Calculate rate ───────────────────────────────────────────────
  void getAndSetCoinRate() {
    final amount = fromAmountRx.value.trim();
    if (amount.isEmpty || makeDouble(amount) == 0) {
      rate.value = 0;
      convertRate.value = 0;
      feeAmount.value = 0;
      feePercentage.value = 0;
      grossReceive.value = 0;
      toEditController.text = "";
      return;
    }
    final from = selectedFromCoin.value;
    final to = selectedToCoin.value;
    if (from != null && to != null && from.id != to.id) {
      _fetchCoinRate(amount, from.id, to.id);
    }
  }

  Future<void> _fetchCoinRate(String amount, int fromCoinId, int toCoinId) async {
    if (isRateLoading.value) return;
    isRateLoading.value = true;
    try {
      // print("[SWAP][Rate] Requesting rate for $amount ($fromCoinId -> $toCoinId)");
      final resp = await http
          .post(
            Uri.parse('$_kBase/api/v1/swap/calculate'),
            headers: _authHeaders(),
            body: jsonEncode({
              'from_coin_id': fromCoinId,
              'to_coin_id': toCoinId,
              'amount': makeDouble(amount),
            }),
          )
          .timeout(const Duration(seconds: 15));

      // print("[SWAP][Rate] Response: ${resp.body}");
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        rate.value = makeDouble(data['exchange_rate']);
        grossReceive.value = makeDouble(data['from_amount']) * rate.value;
        feePercentage.value = makeDouble(data['fee_percentage']);
        feeAmount.value = makeDouble(data['fee_amount']);
        final toAmt = makeDouble(data['to_amount'] ??
            data['amount_after_fee'] ??
            (grossReceive.value - feeAmount.value));
        convertRate.value = toAmt;
        toEditController.text = toAmt.toStringAsFixed(8);
        // print("[SWAP][Rate] Success. Rate: ${rate.value}");
      } else {
        showToast(body['message']?.toString() ?? 'Rate error');
      }
    } catch (e) {
      // print("[SWAP][Rate] Exception: $e");
    } finally {
      isRateLoading.value = false;
    }
  }

  // ── Refresh balances after swap ──────────────────────────────────
  Future<void> _refreshBalances() async {
    final coins = coinList.toList();
    await _enrichBalances(coins);
    coinList.value = coins;
    // Update selected coin references so the UI rebuilds
    final from = selectedFromCoin.value;
    final to = selectedToCoin.value;
    if (from != null) {
      selectedFromCoin.value = coins.firstWhereOrNull((c) => c.id == from.id);
    }
    if (to != null) {
      selectedToCoin.value = coins.firstWhereOrNull((c) => c.id == to.id);
    }
  }

  // ── Swap selected coins ──────────────────────────────────────────
  void swapSelectedCoins() {
    final tmp = selectedFromCoin.value;
    selectedFromCoin.value = selectedToCoin.value;
    selectedToCoin.value = tmp;
    getAndSetCoinRate();
  }

  // ── Execute swap ─────────────────────────────────────────────────
  Future<void> swapCoinProcess(int fromCoinId, int toCoinId, double amount) async {
    showLoadingDialog();
    try {
      final resp = await http
          .post(
            Uri.parse('$_kBase/api/v1/swap/execute'),
            headers: _authHeaders(),
            body: jsonEncode({
              'from_coin_id': fromCoinId,
              'to_coin_id': toCoinId,
              'amount': amount,
            }),
          )
          .timeout(const Duration(seconds: 30));

      hideLoadingDialog();
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      final message = body['message'] as String? ?? '';
      showToast(message, isError: !success);
      if (success) {
        Get.back();
        // Refresh balances in swap cards immediately
        _refreshBalances();
        // Also refresh WalletController cache if loaded
        if (Get.isRegistered<WalletController>()) {
          Future.delayed(
            const Duration(seconds: 2),
            () => Get.find<WalletController>()
                .getWalletList(WalletViewType.spot, () {}),
          );
        }
      }
    } catch (e) {
      hideLoadingDialog();
      showToast('Swap failed. Please try again.'.tr);
    }
  }
}