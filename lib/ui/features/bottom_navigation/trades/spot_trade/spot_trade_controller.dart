import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/exchange_order.dart';
import 'package:tradexpro_flutter/data/models/trade_info_socket.dart';
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
        handleOrderBookList(resp.data[APIKeyConstants.orderType], list);
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
