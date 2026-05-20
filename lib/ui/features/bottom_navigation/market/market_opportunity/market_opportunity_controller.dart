import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/data/models/market_date.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

class MarketOpportunityController extends GetxController {
  RxBool isLoading       = true.obs;
  RxBool isFgLoading     = true.obs;
  RxBool isGlobalLoading = true.obs;

  RxList<MarketCoin> allCoins = <MarketCoin>[].obs;

  // Fear & Greed
  RxInt  fgValue     = 50.obs;
  RxInt  fgYesterday = 50.obs;
  RxInt  fgLastWeek  = 50.obs;
  RxInt  fgLastMonth = 50.obs;
  RxBool fgLoaded    = false.obs;

  // Global stats
  RxDouble totalMarketCap  = 0.0.obs;
  RxDouble totalVolume24h  = 0.0.obs;
  RxDouble btcDominance    = 0.0.obs;
  RxDouble ethDominance    = 0.0.obs;
  RxDouble marketCapChange = 0.0.obs;
  RxDouble btcChange24h    = 0.0.obs;
  RxDouble ethChange24h    = 0.0.obs;
  RxBool   globalLoaded    = false.obs;

  // Heatmap filter (-3,-2,-1,0,1,2,3)
  RxList<int> heatmapFilter = <int>[].obs;

  List<MarketCoin> get gainers {
    final list = allCoins.where((c) => (c.change ?? 0) > 0).toList();
    list.sort((a, b) => (b.change ?? 0).compareTo(a.change ?? 0));
    return list.take(10).toList();
  }

  List<MarketCoin> get losers {
    final list = allCoins.where((c) => (c.change ?? 0) <= 0).toList();
    list.sort((a, b) => (a.change ?? 0).compareTo(b.change ?? 0));
    return list.take(10).toList();
  }

  List<MarketCoin> get heatmapCoins {
    final sorted = List<MarketCoin>.from(allCoins);
    sorted.sort((a, b) => (b.volume ?? 0).compareTo(a.volume ?? 0));
    return sorted.take(20).toList();
  }

  List<MarketCoin> get filteredHeatmapCoins {
    if (heatmapFilter.isEmpty) return heatmapCoins;
    return heatmapCoins.where((coin) {
      final p = coin.change ?? 0;
      return heatmapFilter.any((f) {
        if (f == 0) return p >= -1 && p < 1;
        if (f > 0)  return p >= f && p < f + 1;
        return p >= f && p < f + 1;
      });
    }).toList();
  }

  void toggleHeatmapFilter(int pct) {
    if (heatmapFilter.contains(pct)) {
      heatmapFilter.remove(pct);
    } else {
      heatmapFilter.add(pct);
    }
  }

  int get upCount   => allCoins.where((c) => (c.change ?? 0) > 0).length;
  int get downCount => allCoins.where((c) => (c.change ?? 0) <= 0).length;

  double get othersDominance =>
      (100 - btcDominance.value - ethDominance.value).clamp(0.0, 100.0);

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([loadCoins(), loadFearGreed(), loadGlobalStats()]);
  }

  @override
  Future<void> refresh() async {
    isLoading.value       = true;
    isFgLoading.value     = true;
    isGlobalLoading.value = true;
    await Future.wait([loadCoins(), loadFearGreed(), loadGlobalStats()]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD COINS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadCoins() async {
    isLoading.value = true;
    try {
      final resp = await APIRepository()
          .getMarketOverviewTopCoinList(1, DefaultValue.currency, 1);

      // ── RAW RESPONSE ──────────────────────────────────────────────────
      // debugPrint('');
      // debugPrint('╔══════════════════════════════════════════════════════╗');
      // debugPrint('║              COINS — RAW RESPONSE                    ║');
      // debugPrint('╚══════════════════════════════════════════════════════╝');
      // debugPrint('  success : ${resp.success}');
      // debugPrint('  message : ${resp.message}');
      // debugPrint('  data    : ${resp.data}');
      // debugPrint('');

      if (resp.success) {
        final listResp = ListResponse.fromJson(resp.data);
        allCoins.value = List<MarketCoin>.from(
          listResp.data.map((x) => MarketCoin.fromJson(x)),
        );

        // ── PARSED COINS ───────────────────────────────────────────────
        // debugPrint('╔══════════════════════════════════════════════════════╗');
        // debugPrint('║          COINS — PARSED (${allCoins.length} coins)');
        // debugPrint('╚══════════════════════════════════════════════════════╝');
        // for (int i = 0; i < allCoins.length; i++) {
        //   final c = allCoins[i];
        //   debugPrint(
        //     '  [${(i + 1).toString().padLeft(3)}] '
        //     'symbol: ${(c.coinType ?? '').padRight(8)} | '
        //     'price: ${c.price} | '
        //     'change: ${c.change} | '
        //     'volume: ${c.volume} | '
        //     'coinIcon: ${c.coinIcon}',
        //   );
        // }

        // ── GAINERS / LOSERS SUMMARY ───────────────────────────────────
        // debugPrint('');
        // debugPrint('── GAINERS TOP-10 ──────────────────────────────────────');
        // for (int i = 0; i < gainers.length; i++) {
        //   final c = gainers[i];
        //   debugPrint(
        //     '  [${i + 1}] ${(c.coinType ?? '').padRight(8)} | '
        //     'price: ${c.price} | change: +${c.change}%',
        //   );
        // }
        // debugPrint('');
        // debugPrint('── LOSERS TOP-10 ───────────────────────────────────────');
        // for (int i = 0; i < losers.length; i++) {
        //   final c = losers[i];
        //   debugPrint(
        //     '  [${i + 1}] ${(c.coinType ?? '').padRight(8)} | '
        //     'price: ${c.price} | change: ${c.change}%',
        //   );
        // }
        // debugPrint('');
        // debugPrint('── HEATMAP TOP-20 (by volume) ──────────────────────────');
        // for (int i = 0; i < heatmapCoins.length; i++) {
        //   final c = heatmapCoins[i];
        //   debugPrint(
        //     '  [${i + 1}] ${(c.coinType ?? '').padRight(8)} | '
        //     'volume: ${c.volume} | change: ${c.change}%',
        //   );
        // }
        // debugPrint('');

      } else {
        showToast(resp.message);
      }
    } catch (e, st) {
      // debugPrint('');
      // debugPrint('╔══════════════════════════════════════════════════════╗');
      // debugPrint('║              COINS — ERROR                           ║');
      // debugPrint('╚══════════════════════════════════════════════════════╝');
      // debugPrint('  error: $e');
      // debugPrint('  stack: $st');
      // debugPrint('');
    }
    isLoading.value = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD FEAR & GREED
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadFearGreed() async {
    isFgLoading.value = true;
    try {
      final resp = await http
          .get(Uri.parse('https://api.alternative.me/fng/?limit=31'))
          .timeout(const Duration(seconds: 10));

      // ── RAW RESPONSE ──────────────────────────────────────────────────
      // debugPrint('');
      // debugPrint('╔══════════════════════════════════════════════════════╗');
      // debugPrint('║           FEAR & GREED — RAW RESPONSE                ║');
      // debugPrint('╚══════════════════════════════════════════════════════╝');
      // debugPrint('  statusCode : ${resp.statusCode}');
      // debugPrint('  body       : ${resp.body}');
      // debugPrint('');

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body)['data'] as List;
        fgValue.value = int.parse(data[0]['value'].toString());
        if (data.length > 1)  fgYesterday.value = int.parse(data[1]['value'].toString());
        if (data.length > 6)  fgLastWeek.value  = int.parse(data[6]['value'].toString());
        if (data.length > 30) fgLastMonth.value = int.parse(data[30]['value'].toString());
        fgLoaded.value = true;

        // ── PARSED ────────────────────────────────────────────────────
        // debugPrint('╔══════════════════════════════════════════════════════╗');
        // debugPrint('║           FEAR & GREED — PARSED                      ║');
        // debugPrint('╚══════════════════════════════════════════════════════╝');
        // debugPrint('  today     : ${fgValue.value}');
        // debugPrint('  yesterday : ${fgYesterday.value}');
        // debugPrint('  last week : ${fgLastWeek.value}');
        // debugPrint('  last month: ${fgLastMonth.value}');
        // debugPrint('');
        // debugPrint('  All 31 entries:');
        // for (int i = 0; i < data.length; i++) {
        //   debugPrint(
        //     '    [day-$i] value: ${data[i]['value']} | '
        //     'classification: ${data[i]['value_classification']} | '
        //     'timestamp: ${data[i]['timestamp']}',
        //   );
        // }
        // debugPrint('');
      }
    } catch (e, st) {
      // debugPrint('');
      // debugPrint('╔══════════════════════════════════════════════════════╗');
      // debugPrint('║           FEAR & GREED — ERROR                       ║');
      // debugPrint('╚══════════════════════════════════════════════════════╝');
      // debugPrint('  error: $e');
      // debugPrint('  stack: $st');
      // debugPrint('');
    }
    isFgLoading.value = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD GLOBAL STATS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadGlobalStats() async {
    isGlobalLoading.value = true;
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('https://api.coingecko.com/api/v3/global'))
            .timeout(const Duration(seconds: 12)),
        http.get(Uri.parse('https://api.coinpaprika.com/v1/tickers/btc-bitcoin'))
            .timeout(const Duration(seconds: 12)),
        http.get(Uri.parse('https://api.coinpaprika.com/v1/tickers/eth-ethereum'))
            .timeout(const Duration(seconds: 12)),
      ]);

      // ── RAW RESPONSES ─────────────────────────────────────────────────
      // debugPrint('');
      // debugPrint('╔══════════════════════════════════════════════════════╗');
      // debugPrint('║           GLOBAL STATS — RAW RESPONSES               ║');
      // debugPrint('╚══════════════════════════════════════════════════════╝');
      // debugPrint('');
      // debugPrint('  ── [0] CoinGecko /global ───────────────────────────');
      // debugPrint('     statusCode : ${responses[0].statusCode}');
      // debugPrint('     body       : ${responses[0].body}');
      // debugPrint('');
      // debugPrint('  ── [1] CoinPaprika BTC ─────────────────────────────');
      // debugPrint('     statusCode : ${responses[1].statusCode}');
      // debugPrint('     body       : ${responses[1].body}');
      // debugPrint('');
      // debugPrint('  ── [2] CoinPaprika ETH ─────────────────────────────');
      // debugPrint('     statusCode : ${responses[2].statusCode}');
      // debugPrint('     body       : ${responses[2].body}');
      // debugPrint('');

      if (responses[0].statusCode == 200) {
        final d = json.decode(responses[0].body)['data'];
        totalMarketCap.value  = ((d['total_market_cap']?['usd']  ?? 0) as num).toDouble();
        totalVolume24h.value  = ((d['total_volume']?['usd']      ?? 0) as num).toDouble();
        btcDominance.value    = ((d['market_cap_percentage']?['btc'] ?? 0) as num).toDouble();
        ethDominance.value    = ((d['market_cap_percentage']?['eth'] ?? 0) as num).toDouble();
        marketCapChange.value = ((d['market_cap_change_percentage_24h_usd'] ?? 0) as num).toDouble();
        globalLoaded.value    = true;

        // ── PARSED ──────────────────────────────────────────────────
        // debugPrint('╔══════════════════════════════════════════════════════╗');
        // debugPrint('║           GLOBAL STATS — PARSED (CoinGecko)          ║');
        // debugPrint('╚══════════════════════════════════════════════════════╝');
        // debugPrint('  totalMarketCap        : ${totalMarketCap.value}');
        // debugPrint('  totalVolume24h        : ${totalVolume24h.value}');
        // debugPrint('  btcDominance          : ${btcDominance.value}%');
        // debugPrint('  ethDominance          : ${ethDominance.value}%');
        // debugPrint('  othersDominance       : ${othersDominance}%');
        // debugPrint('  marketCapChange (24h) : ${marketCapChange.value}%');
        // debugPrint('');

        // Full market_cap_percentage map log karo
        // final mcPct = d['market_cap_percentage'] as Map<String, dynamic>?;
        // if (mcPct != null) {
        //   debugPrint('  market_cap_percentage (all coins):');
        //   mcPct.forEach((k, v) {
        //     debugPrint('    $k : $v%');
        //   });
        //   debugPrint('');
        // }
      }

      if (responses[1].statusCode == 200) {
        final btcData = json.decode(responses[1].body);
        btcChange24h.value = ((btcData['quotes']?['USD']?['percent_change_24h'] ?? 0) as num).toDouble();

        // debugPrint('╔══════════════════════════════════════════════════════╗');
        // debugPrint('║           GLOBAL STATS — PARSED (BTC CoinPaprika)    ║');
        // debugPrint('╚══════════════════════════════════════════════════════╝');
        // debugPrint('  btcChange24h : ${btcChange24h.value}%');
        // final btcQuotes = btcData['quotes']?['USD'] as Map<String, dynamic>?;
        // if (btcQuotes != null) {
        //   debugPrint('  BTC quotes/USD:');
        //   btcQuotes.forEach((k, v) => debugPrint('    $k : $v'));
        // }
        // debugPrint('');
      }

      if (responses[2].statusCode == 200) {
        final ethData = json.decode(responses[2].body);
        ethChange24h.value = ((ethData['quotes']?['USD']?['percent_change_24h'] ?? 0) as num).toDouble();

        // debugPrint('╔══════════════════════════════════════════════════════╗');
        // debugPrint('║           GLOBAL STATS — PARSED (ETH CoinPaprika)    ║');
        // debugPrint('╚══════════════════════════════════════════════════════╝');
        // debugPrint('  ethChange24h : ${ethChange24h.value}%');
        // final ethQuotes = ethData['quotes']?['USD'] as Map<String, dynamic>?;
        // if (ethQuotes != null) {
        //   debugPrint('  ETH quotes/USD:');
        //   ethQuotes.forEach((k, v) => debugPrint('    $k : $v'));
        // }
        // debugPrint('');
      }

    } catch (e, st) {
      // debugPrint('');
      // debugPrint('╔══════════════════════════════════════════════════════╗');
      // debugPrint('║           GLOBAL STATS — ERROR                       ║');
      // debugPrint('╚══════════════════════════════════════════════════════╝');
      // debugPrint('  error: $e');
      // debugPrint('  stack: $st');
      // debugPrint('');
    }
    isGlobalLoading.value = false;
  }
}