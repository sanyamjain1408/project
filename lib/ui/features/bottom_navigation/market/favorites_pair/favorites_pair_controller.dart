import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/data/models/market_date.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/data/remote/socket_provider.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/helper/favorite_helper.dart';

import '../market_widgets.dart';

class FavoritesPairController extends GetxController implements SocketListener {
  RxInt selectedTab = 0.obs; // 0 = Spot, 1 = Futures
  RxInt selectedFilterIndex = 0.obs; // ALL / USDT / USDC / BTC
  RxInt selectedCategoryIndex = 0.obs; // All / AI / Meme

  RxList<CoinPair> favList = <CoinPair>[].obs;
  List<CoinPair> favFullList = <CoinPair>[];
  Rx<MarketSort> marketSort = MarketSort().obs;

  final searchController = TextEditingController();
  Timer? _searchTimer;

  List<String> getFilterList() => ["ALL", "USDT", "USDC", "BTC"];

  List<String> getCategoryList() => ["All", "🔥 AI", "Meme", "RWA", "DeFi", "NFT", "L1", "L2"];

  // AI, Meme etc coin tags — same logic as website
  static const _categoryCoins = <String, List<String>>{
    "🔥 AI": ["FET", "AGIX", "OCEAN", "GRT", "TAO", "RNDR", "WLD", "NEAR", "ICP", "AKT"],
    "Meme": ["DOGE", "SHIB", "PEPE", "FLOKI", "BONK", "WIF", "MEME", "BOME", "NEIRO", "COQ"],
    "RWA": ["ONDO", "MKR", "SNX", "RIO", "CPOOL", "MPL", "TRU", "POLYX"],
    "DeFi": ["UNI", "AAVE", "COMP", "CRV", "SUSHI", "YFI", "BAL", "1INCH", "SNX", "LDO"],
    "NFT": ["APE", "SAND", "MANA", "AXS", "GALA", "ILV", "CHZ", "SUPER", "ALICE"],
    "L1": ["BTC", "ETH", "SOL", "AVAX", "ADA", "DOT", "ATOM", "NEAR", "FTM", "SUI"],
    "L2": ["MATIC", "ARB", "OP", "IMX", "ZK", "METIS", "BOBA", "SKL", "STRK", "MANTA"],
  };

  Map<int, String> getTypeMap() {
    final map = {1: "Spot".tr};
    if (getSettingsLocal()?.enableFutureTrade == 1) map[2] = "Futures".tr;
    return map;
  }

  void changeTab(int key) {
    selectedTab.value = key;
    getFavoriteList();
  }

  void onFilterChanged(int index) {
    selectedFilterIndex.value = index;
    applyFiltersAndSort();
  }

  void onCategoryChanged(int index) {
    selectedCategoryIndex.value = index;
    applyFiltersAndSort();
  }

  void onTextChanged(String text) {
    if (_searchTimer?.isActive ?? false) _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 500),
      () => applyFiltersAndSort(),
    );
  }

  void onSortChanged(MarketSort sort) {
    marketSort.value = sort;
    marketSort.refresh();
    applyFiltersAndSort();
  }

  Future<void> getFavoriteList() async {
    final fromKey = selectedTab.value == 0 ? '' : FromKey.future;
    favFullList = FavoriteHelper.getFavoriteList(fromKey);
    applyFiltersAndSort();
  }

  void applyFiltersAndSort() {
    List<CoinPair> list = List.from(favFullList);

    // Filter by base currency (USDT / USDC / BTC)
    final filterList = getFilterList();
    final filterIndex = selectedFilterIndex.value;
    if (filterIndex > 0 && filterIndex < filterList.length) {
      final currency = filterList[filterIndex];
      list = list.where((p) => (p.childCoinName ?? '').toUpperCase() == currency).toList();
    }

    // Filter by category
    final catIndex = selectedCategoryIndex.value;
    final catList = getCategoryList();
    if (catIndex > 0 && catIndex < catList.length) {
      final cat = catList[catIndex];
      final coins = _categoryCoins[cat];
      if (coins != null && coins.isNotEmpty) {
        list = list.where((p) => coins.contains((p.parentCoinName ?? '').toUpperCase())).toList();
      }
    }

    // Search filter
    final query = searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        final pair = '${p.parentCoinName ?? ''}${p.childCoinName ?? ''}'.toLowerCase();
        return pair.contains(query);
      }).toList();
    }

    // Sort
    if (marketSort.value.pair != null) {
      if (marketSort.value.pair == true) {
        list.sort((a, b) => (a.childCoinName ?? '').compareTo(b.childCoinName ?? ''));
      } else {
        list.sort((a, b) => (b.childCoinName ?? '').compareTo(a.childCoinName ?? ''));
      }
    } else if (marketSort.value.volume != null) {
      if (marketSort.value.volume == true) {
        list.sort((a, b) => (a.volume ?? 0).compareTo(b.volume ?? 0));
      } else {
        list.sort((a, b) => (b.volume ?? 0).compareTo(a.volume ?? 0));
      }
    } else if (marketSort.value.price != null) {
      if (marketSort.value.price == true) {
        list.sort((a, b) => (a.lastPrice ?? 0).compareTo(b.lastPrice ?? 0));
      } else {
        list.sort((a, b) => (b.lastPrice ?? 0).compareTo(a.lastPrice ?? 0));
      }
    } else if (marketSort.value.change != null) {
      if (marketSort.value.change == true) {
        list.sort((a, b) => (a.priceChange ?? 0).compareTo(b.priceChange ?? 0));
      } else {
        list.sort((a, b) => (b.priceChange ?? 0).compareTo(a.priceChange ?? 0));
      }
    }

    favList.value = list;
  }

  @override
  void onDataGet(channel, event, data) {
    if (channel == SocketConstants.channelMarketOverviewTopCoinListData && event == SocketConstants.eventMarketOverviewTopCoinList) {
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
    APIRepository().subscribeEvent(SocketConstants.channelMarketOverviewTopCoinListData, this);
  }

  void unSubscribeChannel() {
    APIRepository().unSubscribeEvent(SocketConstants.channelMarketOverviewTopCoinListData, this);
  }

  void findAndUpdateListData(MarketCoin? coin) {
    if (coin == null) return;
    if (favFullList.isNotEmpty) {
      final index = favFullList.indexWhere((element) => element.coinPairId == coin.id);
      if (index != -1) {
        favFullList[index].priceChange = coin.change;
        favFullList[index].lastPrice = coin.price;
        favFullList[index].volume = coin.volume;
        applyFiltersAndSort();
      }
    }
  }
}
