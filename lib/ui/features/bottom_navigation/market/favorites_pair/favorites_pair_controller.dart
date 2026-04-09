import 'dart:async';

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
  RxInt selectedTab = 0.obs;
  RxList<CoinPair> favList = <CoinPair>[].obs;
  List<CoinPair> favFullList = <CoinPair>[];
  Rx<MarketSort> marketSort = MarketSort().obs;

  Map<int, String> getTypeMap() {
    final map = {1: "Spot".tr};
    if (getSettingsLocal()?.enableFutureTrade == 1) map[2] = "Futures".tr;
    return map;
  }

  void changeTab(int key) {
    selectedTab.value = key;
    getFavoriteList();
  }

  void onSortChanged(MarketSort sort) {
    marketSort.value = sort;
    marketSort.refresh();
    sortFavList();
  }

  Future<void> getFavoriteList() async {
    final fromKey = selectedTab.value == 0 ? '' : FromKey.future;
    favFullList = FavoriteHelper.getFavoriteList(fromKey);
    sortFavList();
  }

  void sortFavList() {
    final List<CoinPair> currentList = List.from(favFullList);
    if (marketSort.value.pair != null) {
      if (marketSort.value.pair == true) {
        currentList.sort((a, b) => (a.childCoinName ?? '').compareTo(b.childCoinName ?? ''));
      } else {
        currentList.sort((a, b) => (b.childCoinName ?? '').compareTo(a.childCoinName ?? ''));
      }
    } else if (marketSort.value.volume != null) {
      if (marketSort.value.volume == true) {
        currentList.sort((a, b) => (a.volume ?? 0).compareTo(b.volume ?? 0));
      } else {
        currentList.sort((a, b) => (b.volume ?? 0).compareTo(a.volume ?? 0));
      }
    } else if (marketSort.value.price != null) {
      if (marketSort.value.price == true) {
        currentList.sort((a, b) => (a.lastPrice ?? 0).compareTo(b.lastPrice ?? 0));
      } else {
        currentList.sort((a, b) => (b.lastPrice ?? 0).compareTo(a.lastPrice ?? 0));
      }
    } else if (marketSort.value.change != null) {
      if (marketSort.value.change == true) {
        currentList.sort((a, b) => (a.priceChange ?? 0).compareTo(b.priceChange ?? 0));
      } else {
        currentList.sort((a, b) => (b.priceChange ?? 0).compareTo(a.priceChange ?? 0));
      }
    }

    favList.value = currentList;
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
        sortFavList();
      }
    }
  }
}
