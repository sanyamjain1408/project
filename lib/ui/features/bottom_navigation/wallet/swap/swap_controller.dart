import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/data/models/market_date.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

import '../wallet_controller.dart';
import '../../market/market_spot/market_spot_controller.dart';

const String _kBase = 'https://api.trapix.com';

class SwapCoin {
  final int id;
  final String name;
  final String symbol;
  final double feePercentage;
  String? iconUrl;
  double availableBalance;
  double usdPrice; // price of 1 coin in USD

  SwapCoin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.feePercentage,
    this.iconUrl,
    this.availableBalance = 0,
    this.usdPrice = 0,
  });

  factory SwapCoin.fromJson(Map<String, dynamic> j) => SwapCoin(
        id: j['id'] as int,
        name: j['name'] as String,
        symbol: j['symbol'] as String,
        feePercentage: makeDouble(j['fee_percentage']),
      );
}

class SwapController extends GetxController {
  RxList<SwapCoin> coinList = <SwapCoin>[].obs;
  Rx<SwapCoin?> selectedFromCoin = Rx<SwapCoin?>(null);
  Rx<SwapCoin?> selectedToCoin = Rx<SwapCoin?>(null);

  final toEditController = TextEditingController();
  final fromEditController = TextEditingController();

  final RxBool isLoading = true.obs;
  final RxBool isRateLoading = false.obs;
  final RxString fromAmountRx = "1".obs;

  // USD values for display
  final RxDouble fromUsdValue = 0.0.obs;
  final RxDouble toUsdValue = 0.0.obs;

  Timer? _rateDebounce;
  bool _fetchingCoins = false;

  final RxDouble rate = 0.0.obs;
  final RxDouble convertRate = 0.0.obs;
  final RxDouble feeAmount = 0.0.obs;
  final RxDouble feePercentage = 0.0.obs;
  final RxDouble grossReceive = 0.0.obs;

  // Market data cache: symbol -> MarketCoin (for icon + price)
  final Map<String, MarketCoin> _marketCache = {};

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

  Map<String, String> _authHeaders() {
    final token = GetStorage().read(PreferenceKey.accessToken) ?? '';
    final type = GetStorage().read(PreferenceKey.accessType) ?? 'Bearer';
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': '$type $token',
    };
  }

  /// Fetch all pages of market data into [_marketCache] keyed by coinType (symbol).
  Future<void> _fetchMarketData() async {
    try {
      int page = 1;
      bool hasMore = true;
      while (hasMore) {
        final uri = Uri.parse('$_kBase/api/market-overview-top-coin-list').replace(
          queryParameters: {
            'page': '$page',
            'limit': '100',
            'currency_type': DefaultValue.currency,
            'type': '1',
            'search': '',
          },
        );
        print('[SWAP] _fetchMarketData: GET $uri');
        final resp = await http
            .get(uri, headers: _authHeaders())
            .timeout(const Duration(seconds: 15));
        print('[SWAP] _fetchMarketData: status=${resp.statusCode} bodyLen=${resp.body.length}');
        final body = jsonDecode(resp.body);
        print('[SWAP] _fetchMarketData: success=${body['success']}');
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'];
          final rawList = (data['data'] ?? data['list'] ?? []) as List;
          print('[SWAP] _fetchMarketData: page=$page coins=${rawList.length}');
          final coins = rawList.map((x) => MarketCoin.fromJson(x)).toList();
          for (final c in coins) {
            final sym = (c.coinType ?? '').toUpperCase();
            if (sym.isNotEmpty) {
              final existing = _marketCache[sym];
              if (existing == null ||
                  (c.usdtPrice ?? 0) > (existing.usdtPrice ?? 0)) {
                _marketCache[sym] = c;
              }
            }
          }
          hasMore = data['next_page_url'] != null;
          page++;
        } else {
          print('[SWAP] _fetchMarketData: failed or no data. body=${resp.body.substring(0, resp.body.length.clamp(0, 300))}');
          break;
        }
      }
      print('[SWAP] _fetchMarketData: done. cached symbols=${_marketCache.keys.toList()}');
    } catch (e) {
      print('[SWAP] _fetchMarketData ERROR: $e');
    }
  }

  void _enrichFromMarket(List<SwapCoin> coins) {
    // First try MarketSpotController if already loaded
    if (Get.isRegistered<MarketSpotController>()) {
      print('[SWAP] _enrichFromMarket: MarketSpotController found, fullList=${Get.find<MarketSpotController>().marketFullList.length}');
      final marketCtrl = Get.find<MarketSpotController>();
      for (final coin in coins) {
        final m = marketCtrl.marketFullList.firstWhereOrNull(
            (e) => (e.coinType ?? '').toUpperCase() == coin.symbol.toUpperCase());
        if (m == null) continue;
        if (coin.iconUrl == null || coin.iconUrl!.isEmpty) {
          coin.iconUrl = m.coinIcon;
        }
        if (coin.usdPrice == 0 && (m.usdtPrice ?? 0) > 0) {
          coin.usdPrice = m.usdtPrice!;
        }
      }
    } else {
      print('[SWAP] _enrichFromMarket: MarketSpotController NOT registered');
    }
    // Then apply fetched market cache
    for (final coin in coins) {
      final m = _marketCache[coin.symbol.toUpperCase()];
      if (m == null) continue;
      if (coin.iconUrl == null || coin.iconUrl!.isEmpty) {
        coin.iconUrl = m.coinIcon;
      }
      if (coin.usdPrice == 0 && (m.usdtPrice ?? 0) > 0) {
        coin.usdPrice = m.usdtPrice!;
      }
    }
    print('[SWAP] _enrichFromMarket result:');
    for (final c in coins) {
      print('  ${c.symbol}: iconUrl=${c.iconUrl} usdPrice=${c.usdPrice}');
    }
  }

  Future<void> getCoinSwapApp({Wallet? preWallet, CoinPair? pair}) async {
    if (_fetchingCoins) return;
    _fetchingCoins = true;
    isLoading.value = true;
    try {
      // 1. Fetch market data for icons + prices (in parallel with swap coins)
      final marketFuture = _fetchMarketData();

      // 2. Get enabled swap coins (public)
      final coinsResp = await http
          .get(Uri.parse('$_kBase/api/v1/swap/coins'),
              headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      final coinsBody = jsonDecode(coinsResp.body);
      if (coinsBody['success'] != true) {
        showToast('Failed to load swap coins');
        return;
      }
      final rawCoins = coinsBody['data'] as List;
      final coins = rawCoins.map((e) => SwapCoin.fromJson(e)).toList();

      // Wait for market data before enriching
      await marketFuture;

      // 3. Enrich from market data (icons + USD price)
      _enrichFromMarket(coins);

      // 4. Try wallet API for balance + fallback icons
      try {
        final walletResp = await http
            .get(Uri.parse('$_kBase/api/coin-swap-app'), headers: _authHeaders())
            .timeout(const Duration(seconds: 10));
        final walletBody = jsonDecode(walletResp.body);
        if (walletBody is Map && walletBody['data'] is Map) {
          final wallets = walletBody['data']['wallets'] as List? ?? [];
          for (final coin in coins) {
            final match = wallets.firstWhere(
              (w) =>
                  (w['coin_type'] ?? '').toString().toUpperCase() ==
                  coin.symbol.toUpperCase(),
              orElse: () => null,
            );
            if (match != null) {
              if (coin.iconUrl == null || coin.iconUrl!.isEmpty) {
                coin.iconUrl = match['coin_icon'] as String?;
              }
              coin.availableBalance =
                  makeDouble(match['balance'] ?? match['available_balance']);
              // Only override usdPrice if market didn't supply one
              if (coin.usdPrice == 0) {
                final usd = makeDouble(match['available_balance_usd'] ?? 0);
                final bal = coin.availableBalance;
                if (bal > 0) coin.usdPrice = usd / bal;
              }
            }
          }
        }
      } catch (_) {
        _enrichFromWalletController(coins);
      }

      // 5. Final fallback from WalletController cache
      _enrichFromWalletController(coins);

      coinList.value = coins;

      // 6. Set initial selections
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
      showToast('Please check your internet connection'.tr);
    } finally {
      isLoading.value = false;
      _fetchingCoins = false;
    }
  }

  void _enrichFromWalletController(List<SwapCoin> coins) {
    if (!Get.isRegistered<WalletController>()) return;
    final walletCtrl = Get.find<WalletController>();
    for (final coin in coins) {
      final w = walletCtrl.walletList.firstWhereOrNull(
          (w) => (w.coinType ?? '').toUpperCase() == coin.symbol.toUpperCase());
      if (w != null) {
        if (coin.iconUrl == null || coin.iconUrl!.isEmpty) {
          coin.iconUrl = w.coinIcon;
        }
        if (coin.availableBalance == 0) {
          coin.availableBalance = makeDouble(w.balance ?? w.availableBalance);
        }
        if (coin.usdPrice == 0) {
          final usd = makeDouble(w.availableBalanceUsd ?? 0);
          final bal = coin.availableBalance;
          if (bal > 0) coin.usdPrice = usd / bal;
        }
      }
    }
  }

  void onFromAmountChanged(String v) {
    fromAmountRx.value = v.isEmpty ? "0" : v;
    _updateFromUsd();
    _rateDebounce?.cancel();
    _rateDebounce = Timer(const Duration(milliseconds: 700), getAndSetCoinRate);
  }

  void _updateFromUsd() {
    final amount = makeDouble(fromAmountRx.value);
    final price = selectedFromCoin.value?.usdPrice ?? 0;
    fromUsdValue.value = amount * price;
  }

  void getAndSetCoinRate() {
    final amount = fromAmountRx.value.trim();
    if (amount.isEmpty || makeDouble(amount) == 0) {
      rate.value = 0;
      convertRate.value = 0;
      feeAmount.value = 0;
      feePercentage.value = 0;
      grossReceive.value = 0;
      toUsdValue.value = 0;
      toEditController.text = "";
      return;
    }
    final from = selectedFromCoin.value;
    final to = selectedToCoin.value;
    if (from != null && to != null) {
      _fetchCoinRate(amount, from.id, to.id);
    }
  }

  Future<void> _fetchCoinRate(String amount, int fromId, int toId) async {
    if (isRateLoading.value) return;
    isRateLoading.value = true;
    try {
      final resp = await http
          .post(
            Uri.parse('$_kBase/api/v1/swap/calculate'),
            headers: _authHeaders(),
            body: jsonEncode({
              'from_coin_id': fromId,
              'to_coin_id': toId,
              'amount': makeDouble(amount),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(resp.body);
      if (body['success'] == true) {
        final data = body['data'];
        rate.value = makeDouble(data['exchange_rate']);
        final grossAmt =
            makeDouble(data['from_amount']) * makeDouble(data['exchange_rate']);
        grossReceive.value = grossAmt;
        const double kFeePercent = 0.03;
        feePercentage.value = kFeePercent;
        final fee = grossAmt * kFeePercent / 100;
        feeAmount.value = fee;
        final toAmount = grossAmt - fee;
        convertRate.value = toAmount;
        toEditController.text = toAmount.toStringAsFixed(8);
        final toPrice = selectedToCoin.value?.usdPrice ?? 0;
        toUsdValue.value = toAmount * toPrice;
      } else {
        showToast(body['message'] ?? 'Rate error');
      }
    } catch (_) {
      // silently fail
    } finally {
      isRateLoading.value = false;
    }
  }

  void swapSelectedCoins() {
    final tmp = selectedFromCoin.value;
    selectedFromCoin.value = selectedToCoin.value;
    selectedToCoin.value = tmp;
    _updateFromUsd();
    getAndSetCoinRate();
  }

  Future<void> swapCoinProcess(
      int fromCoinId, int toCoinId, double amount) async {
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
      final body = jsonDecode(resp.body);
      final success = body['success'] as bool? ?? false;
      final message = body['message'] as String? ?? '';
      showToast(message, isError: !success);
      if (success) {
        Get.back();
        if (Get.isRegistered<WalletController>()) {
          Future.delayed(
              const Duration(seconds: 2),
              () => Get.find<WalletController>()
                  .getWalletList(WalletViewType.spot, () {}));
        }
      }
    } catch (e) {
      hideLoadingDialog();
      showToast('Swap failed. Please try again.'.tr);
    }
  }
}
