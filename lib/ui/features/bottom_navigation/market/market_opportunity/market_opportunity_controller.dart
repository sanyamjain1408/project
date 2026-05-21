import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/models/market_date.dart';
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

  Timer? _coinsTimer;

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
    // Pehli baar loadCoins() se poori list load hogi
    // Uske baad har 5 sec mein sirf price+change silently update
    _coinsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshPrices();
    });
  }

  @override
  void onClose() {
    _coinsTimer?.cancel();
    super.onClose();
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
  // LOAD COINS — pehli baar, loading dikhata hai
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadCoins() async {
    isLoading.value = true;
    try {
      final resp = await http
          .get(Uri.parse('https://api.trapix.com/api/v1/spot/pairs'))
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        final List<dynamic> list = body['data'] ?? [];

        allCoins.value = list.map((item) {
          return MarketCoin(
            coinType: item['base_currency']?.toString(),
            coinIcon: item['icon']?.toString(),
            price:    (item['current_price'] as num?)?.toDouble(),
            change:   (item['price_change_24h'] as num?)?.toDouble(),
            volume:   (item['volume_24h'] as num?)?.toDouble(),
          );
        }).toList();
      } else {
        showToast('Failed to load coins');
      }
    } catch (e) {
      // handle error
    }
    isLoading.value = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SILENT PRICE REFRESH — har 5 sec, no loading, no flicker
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _refreshPrices() async {
    try {
      final resp = await http
          .get(Uri.parse('https://api.trapix.com/api/v1/spot/pairs'))
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        final List<dynamic> list = body['data'] ?? [];

        // symbol → new data ka map
        final Map<String, dynamic> newData = {
          for (final item in list)
            (item['base_currency']?.toString() ?? ''): item,
        };

        // Sirf price + change update karo index se
        for (int i = 0; i < allCoins.length; i++) {
          final symbol = allCoins[i].coinType ?? '';
          final updated = newData[symbol];
          if (updated != null) {
            allCoins[i] = MarketCoin(
              coinType: allCoins[i].coinType,
              coinIcon: allCoins[i].coinIcon,
              volume:   allCoins[i].volume,
              price:    (updated['current_price'] as num?)?.toDouble(),
              change:   (updated['price_change_24h'] as num?)?.toDouble(),
            );
          }
        }
      }
    } catch (e) {
      // silent fail — purani values rehti hain
    }
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

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body)['data'] as List;
        fgValue.value = int.parse(data[0]['value'].toString());
        if (data.length > 1)  fgYesterday.value = int.parse(data[1]['value'].toString());
        if (data.length > 6)  fgLastWeek.value  = int.parse(data[6]['value'].toString());
        if (data.length > 30) fgLastMonth.value = int.parse(data[30]['value'].toString());
        fgLoaded.value = true;
      }
    } catch (e) {
      // handle error
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

      if (responses[0].statusCode == 200) {
        final d = json.decode(responses[0].body)['data'];
        totalMarketCap.value  = ((d['total_market_cap']?['usd']  ?? 0) as num).toDouble();
        totalVolume24h.value  = ((d['total_volume']?['usd']      ?? 0) as num).toDouble();
        btcDominance.value    = ((d['market_cap_percentage']?['btc'] ?? 0) as num).toDouble();
        ethDominance.value    = ((d['market_cap_percentage']?['eth'] ?? 0) as num).toDouble();
        marketCapChange.value = ((d['market_cap_change_percentage_24h_usd'] ?? 0) as num).toDouble();
        globalLoaded.value    = true;
      }

      if (responses[1].statusCode == 200) {
        final btcData = json.decode(responses[1].body);
        btcChange24h.value = ((btcData['quotes']?['USD']?['percent_change_24h'] ?? 0) as num).toDouble();
      }

      if (responses[2].statusCode == 200) {
        final ethData = json.decode(responses[2].body);
        ethChange24h.value = ((ethData['quotes']?['USD']?['percent_change_24h'] ?? 0) as num).toDouble();
      }
    } catch (e) {
      // handle error
    }
    isGlobalLoading.value = false;
  }
}