import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/data/models/market_date.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/data/remote/socket_provider.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

import 'market_spot_widgets.dart' as spot;

class MarketSpotController extends GetxController implements SocketListener {
  RxBool isLoading = true.obs;
  RxInt selectedTab = 0.obs;
  RxInt selectedFilterIndex = 0.obs;

  RxList<MarketCoin> marketList = <MarketCoin>[].obs;
  List<MarketCoin> marketFullList = [];
  Rx<spot.MarketSort> marketSort = spot.MarketSort().obs;
  final searchController = TextEditingController();
  int loadedPage = 0;
  bool hasMoreData = false;
  Timer? _searchTimer;
  Timer? _autoRefreshTimer; // ← Auto refresh timer

  List<String> getFilterList() {
    return ["ALL", "USDT", "USDC", "BTC"];
  }

  Map<int, String> getTypeMap() {
    var map = {1: "All Crypto".tr, 2: "Spot Markets".tr, 3: "New Listing".tr};
    return map;
  }

  void changeTab(int key) {
    selectedTab.value = key;
    getMarketOverviewTopCoinList(false);
  }

  void onFilterChanged(int index) {
    selectedFilterIndex.value = index;
    applyFiltersAndSort();
  }

  void onTextChanged(String text) {
    if (_searchTimer?.isActive ?? false) _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(seconds: 1),
      () => applyFiltersAndSort(),
    );
  }

  void onSortChanged(spot.MarketSort sort) {
    marketSort.value = sort;
    marketSort.refresh();
    applyFiltersAndSort();
  }

  // ── Auto refresh start karo ──
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30), // har 30 sec mein update
      (_) => _refreshDataSilently(), // loading spinner nahi dikhega
    );
  }

  // ── Auto refresh band karo ──
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  // ── Silent refresh — loading show nahi hoga, sirf data update hoga ──
  void _refreshDataSilently() {
    APIRepository().getSpotMarketPairs().then((resp) {
      if (resp.success) {
        List rawPairs = [];
        if (resp.data is List) {
          rawPairs = resp.data as List;
        } else if (resp.data is Map) {
          rawPairs = (resp.data['data'] as List?) ??
              (resp.data['pairs'] as List?) ??
              (resp.data['result'] as List?) ??
              (resp.data['markets'] as List?) ??
              [];
        }

        if (rawPairs.isEmpty) return;

        final newList = rawPairs.map<MarketCoin>((p) {
          final coin = MarketCoin();
          coin.coinType = p['base_currency'] ?? p['base'] ?? p['base_asset'] ?? '';
          coin.baseCoinType = p['quote_currency'] ?? p['quote'] ?? p['quote_asset'] ?? '';
          coin.price = double.tryParse(
                p['last_price']?.toString() ??
                p['current_price']?.toString() ??
                p['price']?.toString() ??
                '0') ?? 0;
          coin.change = double.tryParse(
                p['price_change_percent']?.toString() ??
                p['change_24h']?.toString() ??
                p['price_change_24h']?.toString() ??
                p['change']?.toString() ??
                '0') ?? 0;
          coin.volume = double.tryParse(
                p['volume_24h']?.toString() ??
                p['volume']?.toString() ??
                p['base_volume']?.toString() ??
                '0') ?? 0;
          coin.coinIcon = p['icon'] ?? p['logo'] ?? p['image'] ?? p['icon_url'] ?? '';
          return coin;
        }).toList();

        // Sirf changed data update karo — poori list replace nahi
        bool hasChanges = false;
        for (final newCoin in newList) {
          final index = marketFullList.indexWhere(
            (c) => c.coinType == newCoin.coinType && c.baseCoinType == newCoin.baseCoinType,
          );
          if (index != -1) {
            final old = marketFullList[index];
            if (old.price != newCoin.price ||
                old.change != newCoin.change ||
                old.volume != newCoin.volume) {
              marketFullList[index] = newCoin;
              hasChanges = true;
            }
          } else {
            // Naya coin aaya toh add karo
            marketFullList.add(newCoin);
            hasChanges = true;
          }
        }

        if (hasChanges) {
          applyFiltersAndSort();
          //print("=== AUTO REFRESH: Data updated ===");
        }
      }
    }, onError: (err) {
      // print("=== AUTO REFRESH ERROR: $err ===");
      // Silent fail — user ko toast nahi dikhayenge
    });
  }

  Future<void> getMarketOverviewTopCoinList(bool isLoadMore) async {
    if (!isLoadMore) {
      loadedPage = 0;
      hasMoreData = false;
      marketFullList.clear();
      marketList.clear();
    }
    isLoading.value = true;

    APIRepository().getSpotMarketPairs().then((resp) {
      isLoading.value = false;

      // print("=== TRAPIX DEBUG ===");
      // print("Success: ${resp.success}");
      // print("Message: ${resp.message}");
      // print("Data: ${resp.data}");
      // print("===================");

      if (resp.success) {
        List rawPairs = [];
        if (resp.data is List) {
          rawPairs = resp.data as List;
        } else if (resp.data is Map) {
          rawPairs = (resp.data['data'] as List?) ??
              (resp.data['pairs'] as List?) ??
              (resp.data['result'] as List?) ??
              (resp.data['markets'] as List?) ??
              [];
        }

        final list = rawPairs.map<MarketCoin>((p) {
          final coin = MarketCoin();
          coin.coinType = p['base_currency'] ?? p['base'] ?? p['base_asset'] ?? '';
          coin.baseCoinType = p['quote_currency'] ?? p['quote'] ?? p['quote_asset'] ?? '';
          coin.price = double.tryParse(
                p['last_price']?.toString() ??
                p['current_price']?.toString() ??
                p['price']?.toString() ??
                '0') ?? 0;
          coin.change = double.tryParse(
                p['price_change_percent']?.toString() ??
                p['change_24h']?.toString() ??
                p['price_change_24h']?.toString() ??
                p['change']?.toString() ??
                '0') ?? 0;
          coin.volume = double.tryParse(
                p['volume_24h']?.toString() ??
                p['volume']?.toString() ??
                p['base_volume']?.toString() ??
                '0') ?? 0;
          coin.coinIcon = p['icon'] ?? p['logo'] ?? p['image'] ?? p['icon_url'] ?? '';
          return coin;
        }).toList();

        marketFullList..clear()..addAll(list);
        applyFiltersAndSort();

        // ── Pehli load ke baad auto refresh shuru karo ──
        startAutoRefresh();

      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  void applyFiltersAndSort() {
    List<MarketCoin> currentList = List.from(marketFullList);

    if (selectedFilterIndex.value > 0) {
      String selectedFilter = getFilterList()[selectedFilterIndex.value];
      currentList = currentList
          .where((coin) => coin.baseCoinType == selectedFilter)
          .toList();
    }

    String query = searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      currentList = currentList
          .where((coin) =>
              (coin.coinType?.toLowerCase().contains(query) ?? false) ||
              (coin.baseCoinType?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    if (marketSort.value.pair != null) {
      if (marketSort.value.pair == true) {
        currentList.sort((a, b) => (a.coinType ?? '').compareTo(b.coinType ?? ''));
      } else {
        currentList.sort((a, b) => (b.coinType ?? '').compareTo(a.coinType ?? ''));
      }
    } else if (marketSort.value.volume != null) {
      if (marketSort.value.volume == true) {
        currentList.sort((a, b) => (a.volume ?? 0).compareTo(b.volume ?? 0));
      } else {
        currentList.sort((a, b) => (b.volume ?? 0).compareTo(a.volume ?? 0));
      }
    } else if (marketSort.value.price != null) {
      if (marketSort.value.price == true) {
        currentList.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
      } else {
        currentList.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
      }
    } else if (marketSort.value.capital != null) {
      if (marketSort.value.capital == true) {
        currentList.sort((a, b) => (a.totalBalance ?? 0).compareTo(b.totalBalance ?? 0));
      } else {
        currentList.sort((a, b) => (b.totalBalance ?? 0).compareTo(a.totalBalance ?? 0));
      }
    } else if (marketSort.value.change != null) {
      if (marketSort.value.change == true) {
        currentList.sort((a, b) => (a.change ?? 0).compareTo(b.change ?? 0));
      } else {
        currentList.sort((a, b) => (b.change ?? 0).compareTo(a.change ?? 0));
      }
    } else {
      // Default: price high to low
      currentList.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
    }

    marketList.value = currentList;
  }

  @override
  void onClose() {
    // Controller destroy hone par timer band karo — memory leak nahi hoga
    stopAutoRefresh();
    _searchTimer?.cancel();
    searchController.dispose();
    super.onClose();
  }

  @override
  void onDataGet(channel, event, data) {
    if (channel == SocketConstants.channelMarketOverviewTopCoinListData &&
        event == SocketConstants.eventMarketOverviewTopCoinList) {
      if (data is Map<String, dynamic>) {
        final details = data[APIKeyConstants.coinPairDetails];
        if (details is Map<String, dynamic>) {
          final coin = MarketCoin.fromJson(data[APIKeyConstants.coinPairDetails]);
          findAndUpdateListData(coin);
        }
      }
    }
  }

  void subscribeSocketChannels() {
    APIRepository().subscribeEvent(
      SocketConstants.channelMarketOverviewTopCoinListData, this);
  }

  void unSubscribeChannel() {
    APIRepository().unSubscribeEvent(
      SocketConstants.channelMarketOverviewTopCoinListData, this);
    stopAutoRefresh(); // Screen se bahar jaane par timer band
  }

  void findAndUpdateListData(MarketCoin? coin) {
    if (coin == null) return;
    if (marketFullList.isNotEmpty) {
      final index = marketFullList
          .indexWhere((element) => element.coinType == coin.coinType);
      if (index != -1) {
        coin.baseCoinType = marketFullList[index].baseCoinType;
        marketFullList[index] = coin;
        applyFiltersAndSort();
      }
    }
  }
}