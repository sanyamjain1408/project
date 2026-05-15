import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/data/models/market_date.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

class MarketOpportunityController extends GetxController {
  RxBool isLoading = true.obs;
  RxBool isFgLoading = true.obs;

  RxList<MarketCoin> allCoins = <MarketCoin>[].obs;

  RxInt fgValue = 50.obs;
  RxInt fgYesterday = 50.obs;
  RxInt fgLastWeek = 50.obs;
  RxInt fgLastMonth = 50.obs;
  RxBool fgLoaded = false.obs;

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

  int get upCount => allCoins.where((c) => (c.change ?? 0) > 0).length;
  int get downCount => allCoins.where((c) => (c.change ?? 0) <= 0).length;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([loadCoins(), loadFearGreed()]);
  }

  @override
  Future<void> refresh() async {
    isLoading.value = true;
    isFgLoading.value = true;
    await Future.wait([loadCoins(), loadFearGreed()]);
  }

  Future<void> loadCoins() async {
    isLoading.value = true;
    try {
      final resp = await APIRepository()
          .getMarketOverviewTopCoinList(1, DefaultValue.currency, 1);
      if (resp.success) {
        final listResp = ListResponse.fromJson(resp.data);
        allCoins.value = List<MarketCoin>.from(
          listResp.data.map((x) => MarketCoin.fromJson(x)),
        );
      } else {
        showToast(resp.message);
      }
    } catch (_) {}
    isLoading.value = false;
  }

  Future<void> loadFearGreed() async {
    isFgLoading.value = true;
    try {
      final resp = await http
          .get(Uri.parse('https://api.alternative.me/fng/?limit=31'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body)['data'] as List;
        fgValue.value = int.parse(data[0]['value'].toString());
        if (data.length > 1) {
          fgYesterday.value = int.parse(data[1]['value'].toString());
        }
        if (data.length > 6) {
          fgLastWeek.value = int.parse(data[6]['value'].toString());
        }
        if (data.length > 30) {
          fgLastMonth.value = int.parse(data[30]['value'].toString());
        }
        fgLoaded.value = true;
      }
    } catch (_) {}
    isFgLoading.value = false;
  }
}
