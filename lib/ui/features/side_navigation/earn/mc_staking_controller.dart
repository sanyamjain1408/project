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
    'BTC':  'https://assets.coingecko.com/coins/images/1/large/bitcoin.png',
    'ETH':  'https://assets.coingecko.com/coins/images/279/large/ethereum.png',
    'USDT': 'https://assets.coingecko.com/coins/images/325/large/Tether.png',
    'BNB':  'https://assets.coingecko.com/coins/images/825/large/bnb-icon2_2x.png',
    'SOL':  'https://assets.coingecko.com/coins/images/4128/large/solana.png',
    'XRP':  'https://assets.coingecko.com/coins/images/44/large/xrp-symbol-white-128.png',
    'ADA':  'https://assets.coingecko.com/coins/images/975/large/cardano.png',
    'DOGE': 'https://assets.coingecko.com/coins/images/5/large/dogecoin.png',
    'TRX':  'https://assets.coingecko.com/coins/images/1094/large/tron-logo.png',
    'LTC':  'https://assets.coingecko.com/coins/images/2/large/litecoin.png',
    'MATIC':'https://assets.coingecko.com/coins/images/4713/large/matic-token-icon.png',
    'DOT':  'https://assets.coingecko.com/coins/images/12171/large/polkadot.png',
    'AVAX': 'https://assets.coingecko.com/coins/images/12559/large/Avalanche_Circle_RedWhite_Trans.png',
    'LINK': 'https://assets.coingecko.com/coins/images/877/large/chainlink-new-logo.png',
    'USDC': 'https://assets.coingecko.com/coins/images/6319/large/usdc.png',
  };
  return map[symbol] ?? '';
}

class McStakingController extends GetxController {
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

  final isLoadingCoins = false.obs;
  final isLoadingPlans = false.obs;
  final coinDurations = <int, String>{}.obs;
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
  Future<http.Response> _get(String path) =>
      http.get(Uri.parse('$kMcBase$path'), headers: _headers)
          .timeout(const Duration(seconds: 15));

  Future<http.Response> _post(String path, Map<String, dynamic> body) =>
      http.post(Uri.parse('$kMcBase$path'), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

  Map<String, dynamic> _decode(http.Response res) {
    if (res.statusCode == 401) return {'success': false, 'message': 'Unauthorized. Please login again.'};
    if (res.statusCode != 200) return {'success': false, 'message': 'Server error (${res.statusCode})'};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Coins ─────────────────────────────────────────────────────────────────
  Future<void> fetchCoins() async {
    isLoadingCoins.value = true;
    try {
      final j = _decode(await _get('/api/mc-staking/coins'));
      if (j['success'] == true) {
        coins.assignAll((j['data'] as List).map((e) => McStakingCoin.fromJson(e)));
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
        final j = _decode(await _get('/api/mc-staking/plans?coin_id=${coin.id}'));
        if (j['success'] == true) {
          final coinPlans = (j['data'] as List).map((e) => McStakingPlan.fromJson(e)).toList();
          if (coinPlans.isNotEmpty) {
            final days = coinPlans.map((p) => p.durationDays).toSet().toList()..sort();
            String text;
            if (days.length == 1) {
              text = days.first == 0 ? 'Flexible' : '${days.first} Days';
            } else {
              final min = days.first == 0 ? 'Flexible' : '${days.first}D';
              text = '$min – ${days.last}D';
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
        plans.assignAll((j['data'] as List).map((e) => McStakingPlan.fromJson(e)));
      }
    } catch (e) {
      showToast('Error loading plans');
    } finally {
      isLoadingPlans.value = false;
    }
  }

  // ── Calculate reward ──────────────────────────────────────────────────────
  Future<void> calculateReward(int planId, double amount) async {
    if (amount <= 0) { calcResult.value = null; return; }
    try {
      final j = _decode(await _post('/api/mc-staking/calculate-reward', {'plan_id': planId, 'amount': amount}));
calcResult.value = j['success'] == true ? McCalcResult.fromJson(j) : null;
    } catch (_) {
      calcResult.value = null;
    }
  }

  // ── Submit stake ──────────────────────────────────────────────────────────
  Future<bool> submitStake(int planId, double amount) async {
    isStaking.value = true;
    try {
      final j = _decode(await _post('/api/mc-staking/submit-stake', {'plan_id': planId, 'amount': amount}));
      final ok = j['success'] == true;
      showToast(j['message'] ?? (ok ? 'Staking started!' : 'Failed'), isError: !ok);
      return ok;
    } catch (e) {
      showToast('Network error. Please try again.');
      return false;
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
      final j = _decode(await _get(path));
      if (j['success'] == true) {
        final data = j['data'] as Map<String, dynamic>;
        stakes.assignAll((data['data'] as List).map((e) => McStake.fromJson(e)));
        stakesMeta.value = data;
      }
    } catch (e) {
      showToast('Error loading stakes');
    } finally {
      isLoadingStakes.value = false;
    }
  }

  // ── Cancel stake ──────────────────────────────────────────────────────────
  Future<bool> cancelStake(String uid) async {
    isCancelling.value = uid;
    try {
      final j = _decode(await _post('/api/mc-staking/cancel-stake', {'uid': uid}));
      final ok = j['success'] == true;
      showToast(j['message'] ?? (ok ? 'Cancelled!' : 'Cannot cancel'), isError: !ok);
      return ok;
    } catch (e) {
      showToast('Network error. Please try again.');
      return false;
    } finally {
      isCancelling.value = '';
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
      if (pj['success'] == true) portfolio.value = McPortfolioData.fromJson(pj['data']);
      if (sj['success'] == true) statistics.value = McStatistics.fromJson(sj['data']);
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
      final j = _decode(await _post('/api/mc-staking/withdraw-reward', {'uid': uid, 'live_amount': liveAmount}));
      final ok = j['success'] == true;
      showToast(j['message'] ?? (ok ? 'Withdrawal successful!' : 'Failed'), isError: !ok);
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
      final j = _decode(await _get('/api/mc-staking/my-rewards?per_page=15&page=$page'));
      if (j['success'] == true) {
        rewards.assignAll((j['data']['data'] as List).map((e) => McStakingReward.fromJson(e)));
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
      final j = _decode(await _get('/api/mc-staking/my-referral-rewards?per_page=15&page=$page'));
      if (j['success'] == true) {
        referralRewards.assignAll((j['data']['data'] as List).map((e) => McReferralReward.fromJson(e)));
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
      final j = _decode(await _get('/api/mc-staking/withdraw-history?per_page=20&page=$page'));
      if (j['success'] == true) {
        withdrawHistory.assignAll((j['data']['data'] as List).map((e) => McWithdrawRecord.fromJson(e)));
        withdrawMeta.value = j['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      showToast('Error loading withdraw history');
    } finally {
      isLoadingWithdraw.value = false;
    }
  }
}
