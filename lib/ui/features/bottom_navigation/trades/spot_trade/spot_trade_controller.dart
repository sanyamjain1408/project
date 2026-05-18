import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/currency.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/exchange_order.dart';
import 'package:tradexpro_flutter/data/models/spot_data.dart';
import 'package:tradexpro_flutter/data/models/trade_info_socket.dart';
import 'package:tradexpro_flutter/data/remote/spot_socket.dart';
import 'package:tradexpro_flutter/helper/favorite_helper.dart';
import 'package:tradexpro_flutter/ui/features/charts/charts_controller.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/data/remote/socket_provider.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';


class SpotTradeController extends GetxController implements SocketListener {
  Rx<DashboardData> dashboardData = DashboardData().obs;
  Rx<SelfBalance> selfBalance = SelfBalance().obs;
  Rx<CoinPair> selectedCoinPair = CoinPair().obs;
  RxList<CoinPair> coinPairs = <CoinPair>[].obs;
  Map<String, String> coinIconMap = {};
  RxList<ExchangeOrder> buyExchangeOrder = <ExchangeOrder>[].obs;
  RxList<ExchangeOrder> sellExchangeOrder = <ExchangeOrder>[].obs;
  RxList<ExchangeTrade> exchangeTrades = <ExchangeTrade>[].obs;
  Rx<SpotAllMyHistories> allMyHistories = SpotAllMyHistories().obs;
  TextEditingController searchEditController = TextEditingController();
  RxString selectedOrderSort = FromKey.all.obs;
  RxBool isHistoryLoading = false.obs;
  RxBool isLoading = false.obs;
  String tradeHistoryListType = "";
  final _chartController = Get.put(ChartsController());
  String channelTradeInfo = "";
  String channelUserTrades = "";
  String channelDashboard = "";
  RxInt selectedBuySellTab = 0.obs;
  Function(int)? onBuySaleChange;
  RxInt selectedHeaderIndex = 0.obs;
  TradeTolerance? tolerance;

  // ── Spot live-data (WS + HTTP fallback) ──────────────────────────────────
  final _spotWs = SpotWebSocket();
  Timer? _spotHttpTimer;
  bool _wsLive = false;
  bool _wsInitialized = false;

  /// CoinPair format is "BTC_USDT" — WS expects "BTCUSDT"
  String get _spotSymbol =>
      (selectedCoinPair.value.coinPair ?? '').replaceAll('_', '');

  @override
  void onInit() {
    super.onInit();
    _loadCoinIcons();
  }

  @override
  void onClose() {
    _spotWs.dispose();
    _stopHttpPolling();
    super.onClose();
  }

  void _loadCoinIcons() {
    APIRepository().getCoinList().then((resp) {
      if (resp.success && resp.data != null) {
        final list = List<Currency>.from(resp.data!.map((x) => Currency.fromJson(x)));
        for (final c in list) {
          if (c.coinType != null && c.coinIcon != null) {
            coinIconMap[c.coinType!.toUpperCase()] = c.coinIcon!;
          }
        }
        selfBalance.refresh();
      }
    });
  }

  // ── Spot WebSocket ────────────────────────────────────────────────────────

  void _connectSpotWs() {
    final sym = _spotSymbol;
    if (sym.isEmpty) return;
    _wsLive = false;
    if (_wsInitialized) {
      _spotWs.changeSymbol(sym);
    } else {
      _wsInitialized = true;
      _spotWs.connect(sym, _onSpotWsMsg);
    }
    _startHttpPolling();
  }

  void _onSpotWsMsg(Map<String, dynamic> msg) {
    _wsLive = true;
    if (msg['ticker'] is Map) {
      _applyTicker(SpotTicker.fromJson(msg['ticker'] as Map<String, dynamic>));
    }
    if (msg['orderbook'] is Map) {
      _applyOrderBook(SpotOrderBook.fromJson(msg['orderbook'] as Map<String, dynamic>));
    }
    if (msg['trades'] is List) {
      final trades = (msg['trades'] as List)
          .map((t) => SpotTrade.fromJson(t as Map<String, dynamic>))
          .toList();
      _applyTrades(trades);
    }
  }

  void _applyTicker(SpotTicker t) {
    final od = dashboardData.value.orderData;
    if (od != null) {
      od.buyPrice = t.price;
      od.sellPrice = t.price;
    }
    dashboardData.value.lastPriceData = [
      PriceData(
        price: t.price,
        lastPrice: t.price,
        priceOrderType: t.priceChange24h >= 0 ? FromKey.buy : FromKey.sell,
      ),
    ];
    dashboardData.refresh();
    selfBalance.value.buyPrice = t.price;
    selfBalance.value.sellPrice = t.price;
    selfBalance.refresh();
  }

  void _applyOrderBook(SpotOrderBook ob) {
    // bids: server sends descending (highest first) — pass as-is for buy list
    // asks: server sends ascending (lowest first) — handleOrderBookList reverses for sell list
    handleOrderBookList(FromKey.buy, _bidsToOrders(ob.bids));
    handleOrderBookList(FromKey.sell, _asksToOrders(ob.asks));
  }

  /// bids [[price, amount],...] → ExchangeOrder list (descending by price, deduplicated)
  List<ExchangeOrder> _bidsToOrders(List<List<double>> bids) {
    if (bids.isEmpty) return [];
    // Merge duplicate prices
    final merged = <double, double>{};
    for (final r in bids) {
      merged[r[0]] = (merged[r[0]] ?? 0) + r[1];
    }
    final sorted = merged.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    double cumVol = 0;
    final total = sorted.fold(0.0, (s, e) => s + e.value);
    return sorted.map((e) {
      cumVol += e.value;
      final pct = total > 0 ? (cumVol / total) * 100 : 0.0;
      return ExchangeOrder(price: e.key, amount: e.value, total: e.key * e.value, percentage: pct);
    }).toList();
  }

  /// asks [[price, amount],...] → ExchangeOrder list (ascending by price, deduplicated)
  List<ExchangeOrder> _asksToOrders(List<List<double>> asks) {
    if (asks.isEmpty) return [];
    // Merge duplicate prices
    final merged = <double, double>{};
    for (final r in asks) {
      merged[r[0]] = (merged[r[0]] ?? 0) + r[1];
    }
    final sorted = merged.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    double cumVol = 0;
    final total = sorted.fold(0.0, (s, e) => s + e.value);
    return sorted.map((e) {
      cumVol += e.value;
      final pct = total > 0 ? (cumVol / total) * 100 : 0.0;
      return ExchangeOrder(price: e.key, amount: e.value, total: e.key * e.value, percentage: pct);
    }).toList();
  }

  void _applyTrades(List<SpotTrade> trades) {
    exchangeTrades.value = trades
        .map((t) => ExchangeTrade(
              price: t.price,
              amount: t.amount,
              priceOrderType: t.isBuy ? FromKey.buy : FromKey.sell,
              time: t.time,
              total: t.price * t.amount,
            ))
        .toList();
  }

  // ── HTTP fallback polling (kicks in only when WS is silent) ──────────────

  void _startHttpPolling() {
    _stopHttpPolling();
    _spotHttpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_wsLive) _doHttpFetch();
      // Reset flag each cycle so a WS dropout triggers HTTP after ~1 s
      _wsLive = false;
    });
  }

  void _stopHttpPolling() {
    _spotHttpTimer?.cancel();
    _spotHttpTimer = null;
  }

  void _doHttpFetch() {
    final sym = _spotSymbol;
    if (sym.isEmpty) return;

    APIRepository().getSpotTicker(sym).then((resp) {
      if (resp.success && resp.data is Map) {
        _applyTicker(SpotTicker.fromJson(Map<String, dynamic>.from(resp.data as Map)));
      }
    });

    APIRepository().getSpotOrderBook(sym).then((resp) {
      if (resp.success && resp.data is Map) {
        _applyOrderBook(SpotOrderBook.fromJson(Map<String, dynamic>.from(resp.data as Map)));
      }
    });

    APIRepository().getSpotTrades(sym).then((resp) {
      if (resp.success && resp.data is List) {
        _applyTrades((resp.data as List)
            .map((t) => SpotTrade.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList());
      }
    });
  }

  // ── Existing socket (Pusher) ──────────────────────────────────────────────

  @override
  void onDataGet(channel, event, data) {
    if (channel == channelDashboard) {
      if ((event == SocketConstants.eventOrderPlace || event == SocketConstants.eventOrderRemove) && data is SocketOrderPlace) {
        if (data.orderData?.exchangePair == selectedCoinPair.value.coinPair) {
          if(data.orders?.orderType == FromKey.buySell){
            handleOrderBookList(FromKey.buy, data.orders?.buyOrders);
            handleOrderBookList(FromKey.sell, data.orders?.sellOrders);
          } else{
            handleOrderBookList(data.orders?.orderType, data.orders?.orders);
          }
          dashboardData.value.orderData = data.orderData;
          dashboardData.refresh();
        }
      } else {
        if (event == "${SocketConstants.eventOrderPlace}-${gUserRx.value.id}" && data is SocketUserHistory) {
          updateSelfBalance(data.orderData);
          allMyHistories.value.orders = data.orders;
          allMyHistories.value.buyOrders = data.buyOrders;
          allMyHistories.value.sellOrders = data.sellOrders;
          allMyHistories.value.stopLimitOrders = data.stopLimitOrders;
          allMyHistories.value.transactions = data.transactions;
          allMyHistories.refresh();
        }else if (event == "${SocketConstants.eventProcess}-${gUserRx.value.id}" && data is SocketUserHistory) {
          selfBalance.value.total?.tradeWallet?.balance = data.orderData?.total?.tradeWallet?.balance;
          selfBalance.value.total?.baseWallet?.balance = data.orderData?.total?.baseWallet?.balance;
          selfBalance.value.baseWallet = data.orderData?.onOrder?.baseWallet;
          selfBalance.value.tradeWallet = data.orderData?.onOrder?.tradeWallet;
          allMyHistories.value.orders = data.orders;
          allMyHistories.value.buyOrders = data.buyOrders;
          allMyHistories.value.sellOrders = data.sellOrders;
          allMyHistories.value.stopLimitOrders = data.stopLimitOrders;
          allMyHistories.value.transactions = data.transactions;
          allMyHistories.refresh();
        }
      }
    } else if (channel == channelTradeInfo) {
      if (event == SocketConstants.eventProcess && data is SocketTradeInfo) {
        if (data.orderData?.exchangePair == selectedCoinPair.value.coinPair) {
          if (data.trades?.transactions != null) exchangeTrades.value = data.trades?.transactions ?? [];
        }
        dashboardData.value.lastPriceData = data.lastPriceData;
        dashboardData.value.coinPairs = data.pairs;
        dashboardData.value.orderData = data.orderData;
        dashboardData.refresh();
        _chartController.updateChart(data);
        if (data.pairs.isValid) coinPairs.value = data.pairs!;
      }
    }
  }

  void subscribeCoinPairChannel() {
    if (selectedCoinPair.value.parentCoinId != null) {
      channelDashboard = "${SocketConstants.channelDashboard}${selectedCoinPair.value.parentCoinId}-${selectedCoinPair.value.childCoinId}";
      APIRepository().subscribeEvent(channelDashboard, this);
      channelTradeInfo = "${SocketConstants.channelTradeInfo}${selectedCoinPair.value.parentCoinId}-${selectedCoinPair.value.childCoinId}";
      APIRepository().subscribeEvent(channelTradeInfo, this);
    }
  }

  void unSubscribeChannel(bool isDispose) {
    if (channelDashboard.isValid) APIRepository().unSubscribeEvent(channelDashboard, isDispose ? this : null);
    if (channelTradeInfo.isValid) APIRepository().unSubscribeEvent(channelTradeInfo, isDispose ? this : null);
    if (channelUserTrades.isValid) APIRepository().unSubscribeEvent(channelUserTrades, isDispose ? this : null);
    channelTradeInfo = "";
    channelUserTrades = "";
    channelDashboard = "";
  }

  void getDefaultPairData() {
    isLoading.value = true;
    APIRepository().getDashBoardData("").then((resp) {
      if (resp.success) {
        final dData = DashboardData.fromJson(resp.data);
        if (dData.coinPairs.isValid) {
          selectedCoinPair.value = dData.coinPairs!.first;
          getDashBoardData();
        }
      } else {
        isLoading.value = false;
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  void getDashBoardData() {
    if (!selectedCoinPair.value.coinPair.isValid) {
      getDefaultPairData();
      return;
    }

    isLoading.value = true;
    unSubscribeChannel(false);
    APIRepository().getDashBoardData(selectedCoinPair.value.coinPair ?? "").then((resp) {
      isLoading.value = false;
      if (resp.success) {
        dashboardData.value = DashboardData.fromJson(resp.data);
        updateSelfBalance(dashboardData.value.orderData);
        tradeDecimal = dashboardData.value.orderData?.total?.tradeWallet?.pairDecimal ?? DefaultValue.decimal;
        if (selectedCoinPair.value.coinPair == null) {
          final exPair = dashboardData.value.orderData?.exchangePair ?? "";
          if (exPair.isNotEmpty) {
            selectedCoinPair.value = (dashboardData.value.coinPairs ?? []).firstWhere((element) => element.coinPair == exPair);
          }
        }
        FavoriteHelper.checkFavorite(selectedCoinPair.value, '', (pair) => {selectedCoinPair.value = pair, selectedCoinPair.refresh()});
        _chartController.setCoinPair(selectedCoinPair.value);
        Future.delayed(const Duration(milliseconds: 100), () {
          getExchangeOrderList(FromKey.sell);
          getExchangeOrderList(FromKey.buy);
        });
        Future.delayed(const Duration(milliseconds: 200), () => getTradeHistoryList());
        Future.delayed(const Duration(milliseconds: 400), () => getExchangeTradeList());
        Future.delayed(const Duration(milliseconds: 500), () => getLimitOrderTolerance());

        subscribeCoinPairChannel();

        // Connect spot WS for live price / orderbook / trades
        _connectSpotWs();
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  void updateSelfBalance(OrderData? orderData) {
    selfBalance.value.total = orderData?.total;
    selfBalance.value.buyPrice = orderData?.buyPrice;
    selfBalance.value.sellPrice = orderData?.sellPrice;
    if (orderData?.onOrder != null) {
      selfBalance.value.baseWallet = orderData?.onOrder?.baseWallet;
      selfBalance.value.tradeWallet = orderData?.onOrder?.tradeWallet;
    }
    selfBalance.refresh();
  }

  void getExchangeOrderList(String type) {
    APIRepository().getExchangeOrderList(type, dashboardData.value.orderData?.baseCoinId ?? 0, dashboardData.value.orderData?.tradeCoinId ?? 0).then(
        (resp) {
      if (resp.success) {
        var list = List<ExchangeOrder>.from(resp.data[APIKeyConstants.orders].map((x) => ExchangeOrder.fromJson(x)));
        handleOrderBookList(type, list);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      showToast(err.toString());
    });
  }

  void handleOrderBookList(String? type, List<ExchangeOrder>? list) {
    if (list != null) {
      if (type == FromKey.sell) {
        list = list.reversed.toList();
        sellExchangeOrder.value = list;
        _chartController.sellOrders.value = list;
      } else {
        buyExchangeOrder.value = list;
        _chartController.buyOrders.value = list;
      }
    }
  }

  int getListLength(List<ExchangeOrder> list) {
    int length = selectedOrderSort.value == FromKey.all ? DefaultValue.listLimitOrderBook ~/ 2 : DefaultValue.listLimitOrderBook;
    length = list.length < length ? list.length : length;
    return length;
  }

  void getExchangeTradeList() {
    APIRepository().getExchangeTradeList(dashboardData.value.orderData?.baseCoinId ?? 0, dashboardData.value.orderData?.tradeCoinId ?? 0).then(
        (resp) {
      if (resp.success) {
        final list = List<ExchangeTrade>.from(resp.data[APIKeyConstants.transactions].map((x) => ExchangeTrade.fromJson(x)));
        exchangeTrades.value = list;
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      showToast(err.toString());
    });
  }

  void getTradeHistoryList() {
    if (gUserRx.value.id == 0) return;
    isHistoryLoading.value = true;
    final orderData = dashboardData.value.orderData;
    APIRepository().getTradeHistoryList(orderData?.baseCoinId ?? 0, orderData?.tradeCoinId ?? 0, FromKey.buySell).then((resp) {
      isHistoryLoading.value = false;
      if (resp.success && resp.data != null) {
        allMyHistories.value = SpotAllMyHistories.fromJson(resp.data);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isHistoryLoading.value = false;
      showToast(err.toString());
    });
  }

  void getCoinPairList(String searchText) {
    if (searchText.isEmpty) {
      coinPairs.value = dashboardData.value.coinPairs ?? [];
    } else {
      searchText = searchText.toLowerCase();
      final list = (dashboardData.value.coinPairs ?? []).where((element) => (element.coinPairName ?? "").toLowerCase().contains(searchText)).toList();
      coinPairs.value = list;
    }
  }

  /// *** PLACE ORDER *** ///

  void placeOrderLimit(bool isBuy, int baseCoinId, int tradeCoinId, double price, double amount, Function() onSuccess) {
    showLoadingDialog();
    APIRepository().placeOrderLimit(isBuy, baseCoinId, tradeCoinId, price, amount).then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success = resp.data[APIKeyConstants.status] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) onSuccess();
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void placeOrderMarket(bool isBuy, int baseCoinId, int tradeCoinId, double price, double amount, Function() onSuccess) {
    showLoadingDialog();
    APIRepository().placeOrderMarket(isBuy, baseCoinId, tradeCoinId, price, amount).then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success = resp.data[APIKeyConstants.status] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) onSuccess();
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void placeOrderStopMarket(bool isBuy, int baseCoinId, int tradeCoinId, double amount, double limit, double stop, Function() onSuccess) {
    showLoadingDialog();
    APIRepository().placeOrderStopMarket(isBuy, baseCoinId, tradeCoinId, amount, limit, stop).then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success = resp.data[APIKeyConstants.status] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) onSuccess();
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void cancelOpenOrderApp(String  tradeType, int tradeId) {
    showLoadingDialog();
    APIRepository().cancelOpenOrderApp(tradeType, tradeId).then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success = resp.data[APIKeyConstants.status] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) getTradeHistoryList();
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void getLimitOrderTolerance() {
    if (gUserRx.value.id == 0) return;
    final oData = dashboardData.value.orderData;
    APIRepository().getLimitOrderTolerance(oData?.baseCoinId ?? 0, oData?.tradeCoinId ?? 0).then((resp) {
      if (resp.success && resp.data is Map? ) {
        tolerance = TradeTolerance.fromJson(resp.data);
      }
    });
  }
}
