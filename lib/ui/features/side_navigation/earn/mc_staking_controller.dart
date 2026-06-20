import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'mc_staking_models.dart';

// ─── Shared constants (used by all MC staking screens) ─────────────────────
const kMcBase = 'https://api.trapix.com';
const kMcStorage = 'https://api.trapix.com/storage/';

/// Build the full image URL from a logo path returned by the backend.
String mcLogoUrl(String? logo, {String? symbol}) {
  if (logo != null && logo.isNotEmpty) {
    if (logo.startsWith('http')) return logo;
    return '$kMcStorage$logo';
  }
  // fallback: CoinGecko public icon by symbol
  if (symbol != null && symbol.isNotEmpty) {
    return _coinIconBySymbol(symbol.toUpperCase());
  }
  return '';
}

String _coinIconBySymbol(String symbol) {
  const map = {
    'BTC': 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png',
    'ETH': 'https://assets.coingecko.com/coins/images/279/large/ethereum.png',
    'USDT': 'https://assets.coingecko.com/coins/images/325/large/Tether.png',
    'BNB':
        'https://assets.coingecko.com/coins/images/825/large/bnb-icon2_2x.png',
    'SOL': 'https://assets.coingecko.com/coins/images/4128/large/solana.png',
    'XRP':
        'https://assets.coingecko.com/coins/images/44/large/xrp-symbol-white-128.png',
    'ADA': 'https://assets.coingecko.com/coins/images/975/large/cardano.png',
    'DOGE': 'https://assets.coingecko.com/coins/images/5/large/dogecoin.png',
    'TRX': 'https://assets.coingecko.com/coins/images/1094/large/tron-logo.png',
    'LTC': 'https://assets.coingecko.com/coins/images/2/large/litecoin.png',
    'MATIC':
        'https://assets.coingecko.com/coins/images/4713/large/matic-token-icon.png',
    'DOT': 'https://assets.coingecko.com/coins/images/12171/large/polkadot.png',
    'AVAX':
        'https://assets.coingecko.com/coins/images/12559/large/Avalanche_Circle_RedWhite_Trans.png',
    'LINK':
        'https://assets.coingecko.com/coins/images/877/large/chainlink-new-logo.png',
    'USDC': 'https://assets.coingecko.com/coins/images/6319/large/usdc.png',
  };
  return map[symbol] ?? '';
}

class McStakingController extends GetxController {
  @override
  void onClose() {
    stopTrpxTickerPolling();
    super.onClose();
  }

  // ── Auth header — same as rest of app (includes userapisecret + Bearer) ──
  Map<String, String> get _headers {
    final h = APIRepository().authHeader();
    h['Content-Type'] = 'application/json';
    return h;
  }

  // ── Observable state ─────────────────────────────────────────────────────
  final coins = <McStakingCoin>[].obs;
  final plans = <McStakingPlan>[].obs;
  final stakes = <McStake>[].obs;
  final rewards = <McStakingReward>[].obs;
  final referralRewards = <McReferralReward>[].obs;
  final withdrawHistory = <McWithdrawRecord>[].obs;

  final Rx<McPortfolioData?> portfolio = Rx(null);
  final Rx<McStatistics?> statistics = Rx(null);
  final Rx<McCalcResult?> calcResult = Rx(null);
  final liveEarningUsdt = 0.0.obs;

  final isLoadingCoins = false.obs;
  final isLoadingPlans = false.obs;
  final coinDurations = <int, String>{}.obs;
  final coinPlansMap = <int, List<McStakingPlan>>{}.obs;
  final isLoadingStakes = false.obs;
  final isLoadingPortfolio = false.obs;
  final isLoadingRewards = false.obs;
  final isLoadingReferral = false.obs;
  final isLoadingWithdraw = false.obs;
  final isStaking = false.obs;
  final isCancelling = ''.obs;
  final isWithdrawing = ''.obs;

  final stakesMeta = Rx<Map<String, dynamic>?>(null);
  final rewardsMeta = Rx<Map<String, dynamic>?>(null);
  final referralMeta = Rx<Map<String, dynamic>?>(null);
  final withdrawMeta = Rx<Map<String, dynamic>?>(null);

  // ── Helper ───────────────────────────────────────────────────────────────
  Future<http.Response> _get(String path) => http
      .get(Uri.parse('$kMcBase$path'), headers: _headers)
      .timeout(const Duration(seconds: 15));

  Future<http.Response> _post(String path, Map<String, dynamic> body) => http
      .post(
        Uri.parse('$kMcBase$path'),
        headers: _headers,
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 15));

  Map<String, dynamic> _decode(http.Response res) {
    if (res.statusCode == 401)
      return {'success': false, 'message': 'Unauthorized. Please login again.'};
    if (res.statusCode != 200)
      return {'success': false, 'message': 'Server error (${res.statusCode})'};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Coins ─────────────────────────────────────────────────────────────────
  Future<void> fetchCoins() async {
    isLoadingCoins.value = true;
    try {
      final j = _decode(await _get('/api/mc-staking/coins'));
      if (j['success'] == true) {
        coins.assignAll(
          (j['data'] as List).map((e) => McStakingCoin.fromJson(e)),
        );
        _prefetchDurations();
      }
    } catch (e) {
      showToast('Error loading coins');
    } finally {
      isLoadingCoins.value = false;
    }
  }

  Future<void> _prefetchDurations() async {
    for (final coin in coins) {
      try {
        final j = _decode(
          await _get('/api/mc-staking/plans?coin_id=${coin.id}'),
        );
        if (j['success'] == true) {
          final coinPlans = (j['data'] as List)
              .map((e) => McStakingPlan.fromJson(e))
              .toList();
          if (coinPlans.isNotEmpty) {
            coinPlansMap[coin.id] = coinPlans;
            // Collect all daily rates from all rate rules across all plans
            final rates = <double>[];
            for (final p in coinPlans) {
              if (p.rateRules.isNotEmpty) {
                rates.addAll(p.rateRules.map((r) => r.dailyRate));
              }
            }
            String text;
            if (rates.isNotEmpty) {
              rates.sort();
              final minRate = rates.first;
              final maxRate = rates.last;
              if (minRate == maxRate) {
                text = '${minRate.toStringAsFixed(2)}%';
              } else {
                text =
                    '${minRate.toStringAsFixed(2)}% – ${maxRate.toStringAsFixed(2)}%';
              }
            } else {
              text = '';
            }
            coinDurations[coin.id] = text;
          }
        }
      } catch (_) {}
    }
  }

  // ── Plans ─────────────────────────────────────────────────────────────────
  Future<void> fetchPlans(int coinId) async {
    isLoadingPlans.value = true;
    plans.clear();
    calcResult.value = null;
    try {
      final j = _decode(await _get('/api/mc-staking/plans?coin_id=$coinId'));
      if (j['success'] == true) {
        plans.assignAll(
          (j['data'] as List).map((e) => McStakingPlan.fromJson(e)),
        );
      }
    } catch (e) {
      showToast('Error loading plans');
    } finally {
      isLoadingPlans.value = false;
    }
  }

  // ── Calculate reward ──────────────────────────────────────────────────────
  Future<void> calculateReward(int planId, double amount) async {
    if (amount <= 0) {
      calcResult.value = null;
      return;
    }
    try {
      final j = _decode(
        await _post('/api/mc-staking/calculate-reward', {
          'plan_id': planId,
          'amount': amount,
        }),
      );
      calcResult.value = j['success'] == true ? McCalcResult.fromJson(j) : null;
    } catch (_) {
      calcResult.value = null;
    }
  }

  // ── Submit stake ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> submitStake(int planId, double amount) async {
    isStaking.value = true;
    try {
      final j = _decode(
        await _post('/api/mc-staking/submit-stake', {
          'plan_id': planId,
          'amount': amount,
        }),
      );
      final ok = j['success'] == true;
      showToast(
        j['message'] ?? (ok ? 'Staking started!' : 'Failed'),
        isError: !ok,
      );
      if (ok) return j['stake'] as Map<String, dynamic>?;
      return null;
    } catch (e) {
      showToast('Network error. Please try again.');
      return null;
    } finally {
      isStaking.value = false;
    }
  }

  // ── My Stakes ─────────────────────────────────────────────────────────────
  Future<void> fetchMyStakes({int page = 1, String status = ''}) async {
    isLoadingStakes.value = true;
    try {
      var path = '/api/mc-staking/my-stakes?per_page=10&page=$page';
      if (status.isNotEmpty) path += '&status=$status';
      final res = await _get(path);
      final j = _decode(res);
      if (j['success'] == true) {
        final data = j['data'] as Map<String, dynamic>;
        final list = data['data'] as List;
        stakes.assignAll(list.map((e) => McStake.fromJson(e)));
        stakesMeta.value = data;
      }
    } catch (e) {
      showToast('Error loading stakes');
    } finally {
      isLoadingStakes.value = false;
    }
  }

  // ── Cancel stake ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> cancelStake(String uid) async {
    isCancelling.value = uid;
    try {
      final j = _decode(
        await _post('/api/mc-staking/cancel-stake', {'uid': uid}),
      );
      final ok = j['success'] == true;
      if (!ok) {
        showToast(j['message'] ?? 'Cannot cancel', isError: true);
        return null;
      }
      return j;
    } catch (e) {
      showToast('Network error. Please try again.');
      return null;
    } finally {
      isCancelling.value = '';
    }
  }

  // ── TRPX Ticker (price + % change for sparkline card) ───────────────────
  final trpxPrice = 0.0.obs;
  final trpxChange = 0.0.obs; // percent change e.g. 4.15
  final trpxVolume = 0.0.obs;
  final trpxGoingUp = true.obs;
  double _previousTrpxChange = 0.0; // 24h volume in USDT

  /// Live price history for the animated sparkline — max 40 points
  final trpxPriceHistory = <double>[].obs;
  Timer? _trpxTickerTimer;

  Future<void> fetchTrpxTicker() async {
    try {
      final res = await _get('/api/v1/spot/ticker/TRPXUSDT');
      final j = _decode(res);
      // Handle both success wrapper and direct object
      final data = j['data'] ?? j;
      final price =
          double.tryParse(
            data['current_price']?.toString() ??
                data['last_price']?.toString() ??
                data['price']?.toString() ??
                '0',
          ) ??
          0;
      trpxPrice.value = price;

      final newChange =
          double.tryParse(
            data['price_change_24h']?.toString() ??
                data['price_change_percent']?.toString() ??
                data['change']?.toString() ??
                '0',
          ) ??
          0;

      if (newChange > _previousTrpxChange) {
        trpxGoingUp.value = true;
      } else if (newChange < _previousTrpxChange) {
        trpxGoingUp.value = false;
      }

      _previousTrpxChange = newChange;
      trpxChange.value = newChange;

      trpxVolume.value =
          double.tryParse(
            data['volume_24h']?.toString() ??
                data['quote_volume']?.toString() ??
                data['volume']?.toString() ??
                '0',
          ) ??
          0;

      // Accumulate price points for animated sparkline
      if (price > 0) {
        final history = trpxPriceHistory.toList();
        history.add(price);
        if (history.length > 40) history.removeAt(0);
        trpxPriceHistory.value = history;
      }
    } catch (_) {}
  }

  /// Start polling ticker every 3 s so sparkline animates with live prices
  void startTrpxTickerPolling() {
    _trpxTickerTimer?.cancel();
    // Reset history so screen always starts fresh — no catch-up animation
    trpxPriceHistory.value = [];
    fetchTrpxTicker();
    _trpxTickerTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => fetchTrpxTicker(),
    );
  }

  void stopTrpxTickerPolling() {
    _trpxTickerTimer?.cancel();
    _trpxTickerTimer = null;
  }

  // ── Multi-coin ticker (for carousel cards) ───────────────────────────────
  // symbol → price history (max 40 pts)
  final coinHistories = <String, List<double>>{}.obs;
  // symbol → {price, change, volume, goingUp}
  final coinTickers = <String, Map<String, dynamic>>{}.obs;
  Timer? _coinCarouselTimer;

  Future<void> fetchCoinTicker(String symbol) async {
    try {
      final res = await _get('/api/v1/spot/ticker/${symbol}USDT');
      final j = _decode(res);
      final data = j['data'] ?? j;
      final price = double.tryParse(
            data['current_price']?.toString() ??
                data['last_price']?.toString() ??
                data['price']?.toString() ??
                '0',
          ) ?? 0;
      if (price <= 0) return;
      final change = double.tryParse(
            data['price_change_24h']?.toString() ??
                data['price_change_percent']?.toString() ??
                data['change']?.toString() ??
                '0',
          ) ?? 0;
      final volume = double.tryParse(
            data['volume_24h']?.toString() ??
                data['quote_volume']?.toString() ??
                data['volume']?.toString() ??
                '0',
          ) ?? 0;
      final prev = coinTickers[symbol]?['change'] as double? ?? change;
      final goingUp = change >= prev;

      // Update histories
      final hist = List<double>.from(coinHistories[symbol] ?? []);
      hist.add(price);
      if (hist.length > 40) hist.removeAt(0);
      coinHistories[symbol] = hist;

      coinTickers[symbol] = {
        'price': price,
        'change': change,
        'volume': volume,
        'goingUp': goingUp,
      };
      // trigger Obx
      coinHistories.refresh();
      coinTickers.refresh();
    } catch (_) {}
  }

  void startCoinCarouselPolling(List<String> symbols) {
    _coinCarouselTimer?.cancel();
    // Reset all histories so screen starts fresh — no catch-up animation
    coinHistories.clear();
    coinTickers.removeWhere((k, _) => !symbols.contains(k));
    for (final s in symbols) fetchCoinTicker(s);
    _coinCarouselTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) { for (final s in symbols) fetchCoinTicker(s); },
    );
  }

  void stopCoinCarouselPolling() {
    _coinCarouselTimer?.cancel();
    _coinCarouselTimer = null;
  }

  // ── Coin Dashboard (live data per coin) ──────────────────────────────────
  final coinDashboard = Rx<Map<String, dynamic>?>(null);
  final isLoadingCoinDashboard = false.obs;

  Future<void> fetchCoinDashboard(int coinId) async {
    isLoadingCoinDashboard.value = true;
    try {
      final j = _decode(
        await _get('/api/mc-staking/coin-dashboard?coin_id=$coinId'),
      );
      if (j['success'] == true) {
        coinDashboard.value = j['data'] as Map<String, dynamic>;
      }
    } catch (_) {
    } finally {
      isLoadingCoinDashboard.value = false;
    }
  }

  // ── Portfolio + Statistics ─────────────────────────────────────────────────
  Future<void> fetchPortfolio() async {
    isLoadingPortfolio.value = true;
    try {
      final [pRes, sRes] = await Future.wait([
        _get('/api/mc-staking/portfolio'),
        _get('/api/mc-staking/statistics'),
      ]);
      final pj = _decode(pRes);
      final sj = _decode(sRes);
      if (pj['success'] == true) {
        portfolio.value = McPortfolioData.fromJson(pj['data']);
      }
      if (sj['success'] == true)
        statistics.value = McStatistics.fromJson(sj['data']);
    } catch (e) {
      showToast('Error loading portfolio');
    } finally {
      isLoadingPortfolio.value = false;
    }
  }

  // ── Withdraw reward ───────────────────────────────────────────────────────
  Future<bool> withdrawReward(String uid, double liveAmount) async {
    isWithdrawing.value = uid;
    try {
      final j = _decode(
        await _post('/api/mc-staking/withdraw-reward', {
          'uid': uid,
          'live_amount': liveAmount,
        }),
      );
      final ok = j['success'] == true;
      showToast(
        j['message'] ?? (ok ? 'Withdrawal successful!' : 'Failed'),
        isError: !ok,
      );
      return ok;
    } catch (e) {
      showToast('Network error. Please try again.');
      return false;
    } finally {
      isWithdrawing.value = '';
    }
  }

  // ── Rewards history ───────────────────────────────────────────────────────
  Future<void> fetchRewards({int page = 1}) async {
    isLoadingRewards.value = true;
    try {
      final res = await _get(
        '/api/mc-staking/my-rewards?per_page=15&page=$page',
      );
      final j = _decode(res);
      if (j['success'] == true) {
        rewards.assignAll(
          (j['data']['data'] as List).map((e) => McStakingReward.fromJson(e)),
        );
        rewardsMeta.value = j['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      showToast('Error loading rewards');
    } finally {
      isLoadingRewards.value = false;
    }
  }

  // ── Referral rewards ──────────────────────────────────────────────────────
  Future<void> fetchReferralRewards({int page = 1}) async {
    isLoadingReferral.value = true;
    try {
      final j = _decode(
        await _get(
          '/api/mc-staking/my-referral-rewards?per_page=15&page=$page',
        ),
      );
      if (j['success'] == true) {
        referralRewards.assignAll(
          (j['data']['data'] as List).map((e) => McReferralReward.fromJson(e)),
        );
        referralMeta.value = j['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      showToast('Error loading referral rewards');
    } finally {
      isLoadingReferral.value = false;
    }
  }

  // ── Withdraw history ──────────────────────────────────────────────────────
  Future<void> fetchWithdrawHistory({int page = 1}) async {
    isLoadingWithdraw.value = true;
    try {
      final j = _decode(
        await _get('/api/mc-staking/withdraw-history?per_page=20&page=$page'),
      );
      if (j['success'] == true) {
        withdrawHistory.assignAll(
          (j['data']['data'] as List).map((e) => McWithdrawRecord.fromJson(e)),
        );
        withdrawMeta.value = j['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      showToast('Error loading withdraw history');
    } finally {
      isLoadingWithdraw.value = false;
    }
  }
}

  // ── Stake reward history (for schedule tick marks) ─────────────────────────
  Future<List<Map<String, dynamic>>> fetchStakeRewards(String uid) async {
    try {
      final j = _decode(await _get('/api/mc-staking/stake-rewards?uid=$uid'));
      if (j['success'] == true) {
        return List<Map<String, dynamic>>.from(j['data'] ?? []);
      }
    } catch (_) {}
    return [];
  }
}
