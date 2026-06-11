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

  // Session-level cache so reopening swap is instant
  static List<SwapCoin>? _cachedCoins;

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

    try {
      List<SwapCoin> coins;

      if (_cachedCoins != null && _cachedCoins!.isNotEmpty) {
        // Instant load from cache — show UI immediately
        coins = _cachedCoins!;
        coinList.value = coins;
        isLoading.value = false;
        _setSelections(coins, preWallet, pair);
        getAndSetCoinRate();
        // Refresh balances in background silently
        _enrichBalances(coins).then((_) {
          coinList.refresh();
          final from = selectedFromCoin.value;
          final to = selectedToCoin.value;
          if (from != null) selectedFromCoin.value = coins.firstWhereOrNull((c) => c.id == from.id);
          if (to != null) selectedToCoin.value = coins.firstWhereOrNull((c) => c.id == to.id);
        });
        return;
      }

      isLoading.value = true;

      // Fetch coins list + balances in parallel
      final results = await Future.wait([
        http.get(Uri.parse('$_kBase/api/v1/swap/coins'), headers: _publicHeaders()).timeout(const Duration(seconds: 15)),
        _fetchBalanceMap(),
      ]);

      final coinsResp = results[0] as http.Response;
      final balanceMap = results[1] as Map<String, Map<String, dynamic>>;

      final coinsBody = jsonDecode(coinsResp.body) as Map<String, dynamic>;
      if (coinsBody['success'] != true) {
        showToast(coinsBody['message'] ?? 'Failed to load swap coins');
        return;
      }

      coins = (coinsBody['data'] as List).map((e) => SwapCoin.fromJson(e)).toList();

      // Apply balances from parallel fetch
      for (final coin in coins) {
        final data = balanceMap[coin.symbol.toUpperCase()];
        if (data != null) {
          if (coin.iconUrl == null || coin.iconUrl!.isEmpty) coin.iconUrl = data['icon'] as String?;
          coin.availableBalance = makeDouble(data['balance']);
          if (coin.usdPrice == 0) coin.usdPrice = makeDouble(data['price']);
        }
      }

      _cachedCoins = coins;
      coinList.value = coins;
      _setSelections(coins, preWallet, pair);
      getAndSetCoinRate();
    } catch (e) {
      showToast('Please check your internet connection'.tr);
    } finally {
      isLoading.value = false;
      _fetchingCoins = false;
    }
  }

  void _setSelections(List<SwapCoin> coins, Wallet? preWallet, CoinPair? pair) {
    if (preWallet != null) {
      final match = coins.firstWhereOrNull((c) => c.symbol.toUpperCase() == preWallet.coinType?.toUpperCase());
      selectedFromCoin.value = match ?? (coins.isNotEmpty ? coins.first : null);
    } else if (pair != null) {
      selectedFromCoin.value = coins.firstWhereOrNull((c) => c.symbol.toUpperCase() == pair.parentCoinName?.toUpperCase());
      selectedToCoin.value = coins.firstWhereOrNull((c) => c.symbol.toUpperCase() == pair.childCoinName?.toUpperCase());
    }
    if (selectedFromCoin.value == null && coins.isNotEmpty) selectedFromCoin.value = coins.first;
    if (selectedToCoin.value == null && coins.length > 1) selectedToCoin.value = coins[1];
  }

  // Fetch balance/price/icon map keyed by symbol
  // Runs wallet API + spot pairs price API in parallel for max speed
  Future<Map<String, Map<String, dynamic>>> _fetchBalanceMap() async {
    // Fast path: WalletController already in memory
    if (Get.isRegistered<WalletController>()) {
      final wc = Get.find<WalletController>();
      if (wc.walletList.isNotEmpty) {
        final map = <String, Map<String, dynamic>>{};
        for (final w in wc.walletList) {
          final sym = (w.coinType ?? '').toUpperCase();
          final bal = makeDouble(w.balance ?? w.availableBalance);
          final usd = makeDouble(w.availableBalanceUsd ?? 0);
          map[sym] = {'balance': bal, 'price': bal > 0 ? usd / bal : 0.0, 'icon': w.coinIcon};
        }
        return map;
      }
    }

    // Fetch wallet balances + spot prices in parallel
    final results = await Future.wait([
      _fetchWalletBalances(),
      _fetchSpotPrices(),
    ]);

    final map = results[0] as Map<String, Map<String, dynamic>>;
    final prices = results[1] as Map<String, double>;

    // Merge prices into map (overwrite with accurate spot price)
    for (final sym in prices.keys) {
      if (map.containsKey(sym)) {
        map[sym]!['price'] = prices[sym]!;
      } else {
        map[sym] = {'balance': 0.0, 'price': prices[sym]!, 'icon': null};
      }
    }

    return map;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchWalletBalances() async {
    // Try coin-swap-app first
    try {
      final r = await http.get(Uri.parse('$_kBase/api/coin-swap-app'), headers: _authHeaders()).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final wallets = (body['data'] is Map ? body['data']['wallets'] : null) as List? ?? [];
        if (wallets.isNotEmpty) {
          final map = <String, Map<String, dynamic>>{};
          for (final w in wallets) {
            final sym = (w['coin_type'] ?? '').toString().toUpperCase();
            final bal = makeDouble(w['balance'] ?? w['available_balance']);
            final usd = makeDouble(w['available_balance_usd'] ?? 0);
            map[sym] = {'balance': bal, 'price': bal > 0 ? usd / bal : 0.0, 'icon': w['coin_icon']};
          }
          return map;
        }
      }
    } catch (_) {}

    // Fallback: wallet-list
    try {
      final r = await http.get(Uri.parse('$_kBase/api/wallet-list?page=1&per_page=200'), headers: _authHeaders()).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final wallets = (body['data']?['wallets']?['data'] ?? body['data']?['data'] ?? body['data'] ?? []) as List;
        final map = <String, Map<String, dynamic>>{};
        for (final w in wallets) {
          final sym = (w['coin_type'] ?? '').toString().toUpperCase();
          final bal = makeDouble(w['balance'] ?? w['available_balance']);
          final usd = makeDouble(w['available_balance_usd'] ?? 0);
          map[sym] = {'balance': bal, 'price': bal > 0 ? usd / bal : 0.0, 'icon': w['coin_icon']};
        }
        return map;
      }
    } catch (_) {}

    return {};
  }

  // Fetch USD prices from our own spot pairs API
  Future<Map<String, double>> _fetchSpotPrices() async {
    try {
      final r = await http.get(Uri.parse('$_kBase/api/v1/spot/pairs'), headers: _publicHeaders()).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return {};
      final body = jsonDecode(r.body);
      final pairs = (body['data'] ?? body['pairs'] ?? []) as List;
      final prices = <String, double>{};
      for (final p in pairs) {
        // e.g. BTC/USDT → base_currency price in USD
        final base = (p['base_currency'] ?? p['parent_coin'] ?? '').toString().toUpperCase();
        final price = makeDouble(p['current_price'] ?? p['last_price'] ?? p['price'] ?? 0);
        if (base.isNotEmpty && price > 0) prices[base] = price;
      }
      return prices;
    } catch (_) {
      return {};
    }
  }

  // ── Enrich balances — tries coin-swap-app first, then wallet-list ─
  Future<void> _enrichBalances(List<SwapCoin> coins) async {
    final map = await _fetchBalanceMap();
    for (final coin in coins) {
      final data = map[coin.symbol.toUpperCase()];
      if (data == null) continue;
      if (coin.iconUrl == null || coin.iconUrl!.isEmpty) coin.iconUrl = data['icon'] as String?;
      coin.availableBalance = makeDouble(data['balance']);
      if (coin.usdPrice == 0) coin.usdPrice = makeDouble(data['price']);
    }
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