import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/exchange_order.dart';
import 'package:tradexpro_flutter/data/models/future_data.dart';
import 'package:tradexpro_flutter/data/models/trade_info_socket.dart';
import 'package:tradexpro_flutter/helper/favorite_helper.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/data/remote/socket_provider.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';


import '../charts/charts_controller.dart';

class CurrencyPairDetailsController extends GetxController implements SocketListener {
  Rx<OrderData> orderData = OrderData().obs;
  final _chartController = Get.put(ChartsController());
  Rx<CoinPair> selectedPair = CoinPair().obs;
  RxList<PriceData> lastPriceData = <PriceData>[].obs;
  RxList<ExchangeOrder> buyExchangeOrder = <ExchangeOrder>[].obs;
  RxList<ExchangeOrder> sellExchangeOrder = <ExchangeOrder>[].obs;
  RxList<ExchangeTrade> exchangeTrades = <ExchangeTrade>[].obs;
  RxBool isLoading = false.obs;
  String channelTradeInfo = "";
  String channelDashboard = "";

  void getCurrencyPairDetailsSpot() {
    if (!selectedPair.value.coinPair.isValid) return;
    isLoading.value = true;
    APIRepository().getDashBoardData(selectedPair.value.coinPair ?? "").then((resp) {
      isLoading.value = false;
      if (resp.success) {
        final dashboardData = DashboardData.fromJson(resp.data);
        if (dashboardData.orderData != null) orderData.value = dashboardData.orderData!;
        if (dashboardData.lastPriceData != null) lastPriceData.value = dashboardData.lastPriceData!;

        final exPair = orderData.value.exchangePair ?? "";
        if (exPair.isNotEmpty) {
          final pair = (dashboardData.coinPairs ?? []).firstWhereOrNull((element) => element.coinPair == exPair);
          if (pair != null) selectedPair.value = pair;
        }
        tradeDecimal = dashboardData.orderData?.total?.tradeWallet?.pairDecimal ?? DefaultValue.decimal;
        FavoriteHelper.checkFavorite(selectedPair.value, '', (pair) => selectedPair.value = pair);
        _chartController.setCoinPair(selectedPair.value);
        getExchangeOrderList(FromKey.sell);
        getExchangeOrderList(FromKey.buy);
        Future.delayed(const Duration(milliseconds: 500), () => getExchangeTradeList());
        subscribeCoinPairChannel();
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  void getCurrencyPairDetailsFuture() {
    if (!selectedPair.value.coinPair.isValid) return;
    isLoading.value = true;
    APIRepository().getFutureTradeAppDashboard(selectedPair.value.coinPair ?? '').then((resp) {
      isLoading.value = false;
      if (resp.success) {
        final fDashboardData = FutureTradeDashboardData.fromJson(resp.data);
        if (fDashboardData.orderData != null) orderData.value = fDashboardData.orderData!;
        if (fDashboardData.lastPriceData != null) lastPriceData.value = fDashboardData.lastPriceData!;

        final exPair = orderData.value.exchangePair ?? "";
        if (exPair.isNotEmpty) {
          final pair = (fDashboardData.pairs ?? []).firstWhereOrNull((element) => element.coinPair == exPair);
          if (pair != null) selectedPair.value = pair;
        }
        FavoriteHelper.checkFavorite(selectedPair.value, FromKey.future, (pair) => selectedPair.value = pair);
        _chartController.setCoinPair(selectedPair.value);
        getExchangeOrderList(FromKey.sell);
        getExchangeOrderList(FromKey.buy);

        Future.delayed(const Duration(milliseconds: 500), () => getFutureExchangeTradeList());

        // subscribeCoinPairChannel();
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  void getExchangeOrderList(String type) {
    APIRepository().getExchangeOrderList(type, orderData.value.baseCoinId ?? 0, orderData.value.tradeCoinId ?? 0).then((resp) {
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

  void getExchangeTradeList() {
    APIRepository().getExchangeTradeList(orderData.value.baseCoinId ?? 0, orderData.value.tradeCoinId ?? 0).then((resp) {
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

  void getFutureExchangeTradeList() {
    APIRepository().getFutureTradeExchangeMarketTradesApp(orderData.value.baseCoinId ?? 0, orderData.value.tradeCoinId ?? 0).then((resp) {
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

  ///SOCKET Mechanism

  @override
  void onDataGet(channel, event, data) {
    if (channel == channelDashboard) {
      if ((event == SocketConstants.eventOrderPlace || event == SocketConstants.eventOrderRemove) && data is SocketOrderPlace) {
        if (data.orderData?.exchangePair == selectedPair.value.coinPair) {
          handleOrderBookList(data.orders?.orderType, data.orders?.orders);
          if (data.orderData != null) orderData.value = data.orderData!;
        }
      }
    } else if (channel == channelTradeInfo) {
      if (event == SocketConstants.eventProcess && data is SocketTradeInfo) {
        if (data.orderData?.exchangePair == selectedPair.value.coinPair) {
          if (data.trades?.transactions != null) exchangeTrades.value = data.trades?.transactions ?? [];
        }
        if (data.lastPriceData != null) lastPriceData.value = data.lastPriceData!;
        if (data.orderData != null) orderData.value = data.orderData!;
        _chartController.updateChart(data);
      }
    }
  }

  void subscribeCoinPairChannel() {
    if (selectedPair.value.parentCoinId != null) {
      channelDashboard = "${SocketConstants.channelDashboard}${selectedPair.value.parentCoinId}-${selectedPair.value.childCoinId}";
      APIRepository().subscribeEvent(channelDashboard, this);
      channelTradeInfo = "${SocketConstants.channelTradeInfo}${selectedPair.value.parentCoinId}-${selectedPair.value.childCoinId}";
      APIRepository().subscribeEvent(channelTradeInfo, this);
    }
  }

  void unSubscribeChannel(bool isDispose) {
    if (channelDashboard.isValid) APIRepository().unSubscribeEvent(channelDashboard, isDispose ? this : null);
    if (channelTradeInfo.isValid) APIRepository().unSubscribeEvent(channelTradeInfo, isDispose ? this : null);
    channelTradeInfo = "";
    channelDashboard = "";
  }
}
