import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/data/models/future_data.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/data/remote/socket_provider.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

import '../market_widgets.dart';

class FutureController extends GetxController implements SocketListener {
  RxBool isLoadingList = false.obs;
  RxInt selectedTab = 0.obs;
  RxList<CoinPair> coinPairList = <CoinPair>[].obs;
  List<CoinPair> pairFullList = <CoinPair>[];
  Rx<MarketSort> marketSort = MarketSort().obs;
  int loadedPage = 0;
  bool hasMoreData = false;
  Timer? _refreshTimer;

  // Direct WebSocket for ms-level updates
  WebSocket? _ws;
  bool _wsDisposed = false;
  Timer? _wsReconnTimer;

  List<String> tabKeyList = [FutureMarketKey.assets, FutureMarketKey.hour, FutureMarketKey.new_];

  @override
  void onDataGet(channel, event, data) {
    if (channel == SocketConstants.channelFutureTradeGetExchangeMarketDetailsData && event == SocketConstants.eventMarketDetailsData) {
      final marketData = FutureMarketData.fromJson(data);
      if (isLoadingList.value == false) {
        pairFullList = marketData.coins ?? [];
        sortFutureMarketList();
      }
      // final index = tabKeyList.indexOf(FutureMarketKey.assets);
      // if (selectedTab.value == index && isLoadingList.value == false) {
      //   pairFullList = marketData.coins ?? [];
      //   sortFutureMarketList();
      // }
    }
  }

  void subscribeSocketChannels() {
    APIRepository().subscribeEvent(SocketConstants.channelFutureTradeGetExchangeMarketDetailsData, this);
  }

  void unSubscribeChannel() {
    APIRepository().unSubscribeEvent(SocketConstants.channelFutureTradeGetExchangeMarketDetailsData, this);
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _disconnectWs();
  }

  // ── Direct WebSocket ────────────────────────────────────────────────────────
  Future<void> _connectWs() async {
    if (_wsDisposed) return;
    try {
      _ws = await WebSocket.connect('wss://trapix.com/ws/future');
      _ws!.add(jsonEncode({'type': 'subscribe_all'}));
      _ws!.listen(_onWsData, onDone: _onWsDone, onError: (_) => _onWsDone(), cancelOnError: true);
    } catch (_) { _scheduleReconnect(); }
  }

  void _onWsData(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      if (msg['type'] != 'update') return;
      final ticker = msg['ticker'] as Map<String, dynamic>?;
      if (ticker == null) return;
      final symbol = (msg['symbol'] as String? ?? '').toUpperCase();
      if (symbol.isEmpty || pairFullList.isEmpty) return;

      final price  = _toDouble(ticker['price']);
      final change = _toDouble(ticker['change_24h']);
      final volume = _toDouble(ticker['volume_24h']);

      final idx = pairFullList.indexWhere((p) => (p.coinPair ?? '').toUpperCase().replaceAll('_', '') == symbol);
      if (idx == -1) return;
      if (price  > 0) pairFullList[idx].lastPrice   = price;
      pairFullList[idx].priceChange = change;
      if (volume > 0) pairFullList[idx].volume = volume;
      sortFutureMarketList();
    } catch (_) {}
  }

  void _onWsDone() { _ws = null; _scheduleReconnect(); }

  void _scheduleReconnect() {
    if (_wsDisposed) return;
    _wsReconnTimer?.cancel();
    _wsReconnTimer = Timer(const Duration(seconds: 3), _connectWs);
  }

  void _disconnectWs() {
    _wsDisposed = true;
    _wsReconnTimer?.cancel();
    try { _ws?.close(); } catch (_) {}
    _ws = null;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int)    return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isLoadingList.value) {
        APIRepository().getFutureExchangeMarketDetail(1, tabKeyList[selectedTab.value]).then((resp) {
          if (resp.success) {
            final mData = FutureMarketData.fromJson(resp.data);
            final incoming = mData.coins ?? [];
            bool changed = false;
            for (final newPair in incoming) {
              final idx = pairFullList.indexWhere((p) => p.coinPair == newPair.coinPair);
              if (idx != -1 && (pairFullList[idx].lastPrice != newPair.lastPrice || pairFullList[idx].priceChange != newPair.priceChange)) {
                pairFullList[idx] = newPair;
                changed = true;
              }
            }
            if (changed) sortFutureMarketList();
          }
        }, onError: (_) {});
      }
    });
  }

  void changeTab(int index) {
    selectedTab.value = index;
    getFutureCoinList(false);
  }

  void onSortChanged(MarketSort sort) {
    marketSort.value = sort;
    marketSort.refresh();
    sortFutureMarketList();
  }

  Future<void> getFutureCoinList(bool isLoadMore) async {
    if (!isLoadMore) {
      loadedPage = 0;
      hasMoreData = true;
      pairFullList.clear();
      coinPairList.clear();
    }
    isLoadingList.value = true;
    loadedPage++;
    APIRepository().getFutureExchangeMarketDetail(loadedPage, tabKeyList[selectedTab.value]).then((resp) {
      isLoadingList.value = false;
      if (resp.success) {
        final mData = FutureMarketData.fromJson(resp.data);
        pairFullList.addAll(mData.coins ?? []);
        sortFutureMarketList();
        if (loadedPage == 1) {
          _wsDisposed = false;
          _connectWs();
          startAutoRefresh();
        }
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoadingList.value = false;
      showToast(err.toString());
    });
  }

  void sortFutureMarketList() {
    final List<CoinPair> currentList = List.from(pairFullList);
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

    coinPairList.value = currentList;
  }
}

// class FutureController extends GetController implements SocketListener {
//   RxBool isLoading = true.obs;
//   RxBool isLoadingList = false.obs;
//
//   // RxString selectedTabSub = FutureMarketKey.assets.obs;
//   RxInt selectedTab = 0.obs;
//   RxList<CoinPair> coinPairList = <CoinPair>[].obs;
//   Rx<FutureMarketData> marketData = FutureMarketData().obs;
//   List<String> tabKeyList = [FutureMarketKey.assets, FutureMarketKey.hour, FutureMarketKey.new_];
//
//   @override
//   void onDataGet(channel, event, data) {
//     if (channel == SocketConstants.channelFutureTradeGetExchangeMarketDetailsData && event == SocketConstants.eventMarketDetailsData) {
//       marketData.value = FutureMarketData.fromJson(data);
//       final index = tabKeyList.indexOf(FutureMarketKey.assets);
//       if (selectedTab.value == index && isLoadingList.value == false) coinPairList.value = marketData.value.coins ?? [];
//     }
//   }
//
//   void subscribeSocketChannels() {
//     APIRepository().subscribeEvent(SocketConstants.channelFutureTradeGetExchangeMarketDetailsData, this);
//   }
//
//   void unSubscribeChannel() {
//     APIRepository().unSubscribeEvent(SocketConstants.channelFutureTradeGetExchangeMarketDetailsData, this);
//   }
//
//   Future<void> getFutureExchangeMarketDetail() async {
//     isLoading.value = true;
//     APIRepository().getFutureExchangeMarketDetail(1, FutureMarketKey.assets).then((resp) {
//       if (resp.success) {
//         marketData.value = FutureMarketData.fromJson(resp.data);
//         coinPairList.value = marketData.value.coins ?? [];
//       } else {
//         showToast(resp.message);
//       }
//       isLoading.value = false;
//       subscribeSocketChannels();
//     }, onError: (err) {
//       isLoading.value = false;
//       showToast(err.toString());
//     });
//   }
//
//   void changeTab(int index) {
//     isLoadingList.value = true;
//     selectedTab.value = index;
//     getFutureCoinList(tabKeyList[selectedTab.value]);
//   }
//
//   // void changeSubTab(String key) {
//   //   isLoadingList = true;
//   //   selectedTabSub.value = key;
//   //   // getFutureCoinList(tabKeyList[]);
//   // }
//
//   Future<void> getFutureCoinList(String key) async {
//     APIRepository().getFutureExchangeMarketDetail(1, key).then((resp) {
//       isLoadingList.value = false;
//       if (resp.success) {
//         final mData = FutureMarketData.fromJson(resp.data);
//         coinPairList.value = mData.coins ?? [];
//       } else {
//         showToast(resp.message);
//       }
//     }, onError: (err) {
//       isLoadingList.value = false;
//       showToast(err.toString());
//       coinPairList.value = [];
//     });
//   }
// }
