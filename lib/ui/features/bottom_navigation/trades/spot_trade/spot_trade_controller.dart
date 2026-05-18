import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/currency.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/exchange_order.dart';
import 'package:tradexpro_flutter/data/models/trade_info_socket.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/models/settings.dart';
import 'package:tradexpro_flutter/helper/favorite_helper.dart';
import 'package:tradexpro_flutter/ui/features/charts/charts_controller.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/data/remote/socket_provider.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LIVE DATA CONFIG — Real backend data from WebSocket
// ─────────────────────────────────────────────────────────────────────────────

class SpotTradeController extends GetxController implements SocketListener {
  // ─── Observable state ──────────────────────────────────────────────────────
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

  // ─── Live Data Refresh Timer ────────────────────────────────────────────────
  Timer? _refreshTimer;
  static const int _refreshIntervalMs = 1000;
  static const int _kMinBotOrders = 20;
  static const int _kChartInterval = 500;

  // Dynamic bot speeds — read from server settings (same as website)
  int _kObSpeed = 800;
  int _kTrMin = 50;
  int _kTrMax = 150;
  int _kPrSpeed = 800;
  double _kPrPct = 0.0001;

  final Random _rng = Random();
  Timer? _obTimer;
  Timer? _tradeTimer;
  Timer? _priceTimer;
  bool _botEnabled = false;
  bool _botStarted = false;
  bool _botInitialized = false;
  double _basePrice = 0;
  double _lastBasePrice = 0;
  double _sessionHigh = 0;
  double _sessionLow = 0;
  double _sessionVol = 0;
  double _minAmt = 0;
  double _maxAmt = 0;
  double _chartAccVol = 0;
  double _chartAccPrice = 0;
  int _chartLastPush = 0;
  List<ExchangeOrder> _botBuyList = [];
  List<ExchangeOrder> _botSellList = [];

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadCoinIcons();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _stopBot();
    unSubscribeChannel(true);
    searchEditController.dispose();
    super.onClose();
  }

  void _loadCoinIcons() {
    APIRepository().getCoinList().then((resp) {
      if (resp.success && resp.data != null) {
        final list =
            List<Currency>.from(resp.data!.map((x) => Currency.fromJson(x)));
        for (final c in list) {
          if (c.coinType != null && c.coinIcon != null) {
            coinIconMap[c.coinType!.toUpperCase()] = c.coinIcon!;
          }
        }
        selfBalance.refresh();
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SOCKET
  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onDataGet(channel, event, data) {
    if (channel.contains(channelDashboard)) {
      if ((event == SocketConstants.eventOrderPlace ||
              event == SocketConstants.eventOrderRemove) &&
          data is SocketOrderPlace) {
        if (data.orderData?.exchangePair ==
            selectedCoinPair.value.coinPair) {
          if (data.orders?.orderType == FromKey.buySell) {
            handleOrderBookList(FromKey.buy, data.orders?.buyOrders);
            handleOrderBookList(FromKey.sell, data.orders?.sellOrders);
          } else {
            handleOrderBookList(
                data.orders?.orderType, data.orders?.orders);
          }
          dashboardData.value.orderData = data.orderData;
          dashboardData.refresh();
        }
      } else if (event == SocketConstants.eventProcess && data is SocketTradeInfo) {
        if (data.orderData?.exchangePair ==
            selectedCoinPair.value.coinPair) {
          if (data.trades?.transactions != null) {
            exchangeTrades.value = data.trades?.transactions ?? [];
          }
        }
        dashboardData.value.lastPriceData = data.lastPriceData;
        dashboardData.value.coinPairs = data.pairs;
        dashboardData.value.orderData = data.orderData;
        dashboardData.refresh();
        _chartController.updateChart(data);
        if (data.pairs.isValid) coinPairs.value = data.pairs!;

        final livePrice =
            data.lastPriceData?.isNotEmpty == true
                ? (data.lastPriceData!.first.price ?? 0)
                : 0.0;
        if (livePrice > 0 && _botEnabled) {
          _basePrice = livePrice.toDouble();
        }
      } else {
        if (event ==
                "${SocketConstants.eventOrderPlace}-${gUserRx.value.id}" &&
            data is SocketUserHistory) {
          updateSelfBalance(data.orderData);
          allMyHistories.value.orders = data.orders;
          allMyHistories.value.buyOrders = data.buyOrders;
          allMyHistories.value.sellOrders = data.sellOrders;
          allMyHistories.value.stopLimitOrders = data.stopLimitOrders;
          allMyHistories.value.transactions = data.transactions;
          allMyHistories.refresh();
        } else if (event ==
                "${SocketConstants.eventProcess}-${gUserRx.value.id}" &&
            data is SocketUserHistory) {
          selfBalance.value.total?.tradeWallet?.balance =
              data.orderData?.total?.tradeWallet?.balance;
          selfBalance.value.total?.baseWallet?.balance =
              data.orderData?.total?.baseWallet?.balance;
          selfBalance.value.baseWallet =
              data.orderData?.onOrder?.baseWallet;
          selfBalance.value.tradeWallet =
              data.orderData?.onOrder?.tradeWallet;
          allMyHistories.value.orders = data.orders;
          allMyHistories.value.buyOrders = data.buyOrders;
          allMyHistories.value.sellOrders = data.sellOrders;
          allMyHistories.value.stopLimitOrders = data.stopLimitOrders;
          allMyHistories.value.transactions = data.transactions;
          allMyHistories.refresh();
        }
      }
    } else if (channel.contains(channelTradeInfo)) {
      if (event == SocketConstants.eventProcess &&
          data is SocketTradeInfo) {
        if (data.orderData?.exchangePair ==
            selectedCoinPair.value.coinPair) {
          if (data.trades?.transactions != null) {
            exchangeTrades.value = data.trades?.transactions ?? [];
          }
        }
        dashboardData.value.lastPriceData = data.lastPriceData;
        dashboardData.value.coinPairs = data.pairs;
        dashboardData.value.orderData = data.orderData;
        dashboardData.refresh();
        _chartController.updateChart(data);
        if (data.pairs.isValid) coinPairs.value = data.pairs!;

        final livePrice =
            data.lastPriceData?.isNotEmpty == true
                ? (data.lastPriceData!.first.price ?? 0)
                : 0.0;
        if (livePrice > 0 && _botEnabled) {
          _basePrice = livePrice.toDouble();
        }
      }
    }
  }

  void subscribeCoinPairChannel() {
    final parentId = selectedCoinPair.value.parentCoinId ??
        dashboardData.value.orderData?.baseCoinId;
    final childId = selectedCoinPair.value.childCoinId ??
        dashboardData.value.orderData?.tradeCoinId;

    if (parentId != null && childId != null) {
      channelDashboard =
          "${SocketConstants.channelDashboard}$parentId-$childId";
      APIRepository().subscribeEvent(channelDashboard, this);
      channelTradeInfo =
          "${SocketConstants.channelTradeInfo}$parentId-$childId";
      APIRepository().subscribeEvent(channelTradeInfo, this);
    }
  }

  void unSubscribeChannel(bool isDispose) {
    if (channelDashboard.isValid) {
      APIRepository().unSubscribeEvent(
          channelDashboard, isDispose ? this : null);
    }
    if (channelTradeInfo.isValid) {
      APIRepository().unSubscribeEvent(
          channelTradeInfo, isDispose ? this : null);
    }
    if (channelUserTrades.isValid) {
      APIRepository().unSubscribeEvent(
          channelUserTrades, isDispose ? this : null);
    }
    channelTradeInfo = "";
    channelUserTrades = "";
    channelDashboard = "";
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DASHBOARD DATA
  // ─────────────────────────────────────────────────────────────────────────
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

    // Reset bot for new pair
    _stopBot();
    _resetBotState();

    isLoading.value = true;
    unSubscribeChannel(false);
    APIRepository()
        .getDashBoardData(selectedCoinPair.value.coinPair ?? "")
        .then((resp) {
      isLoading.value = false;
      if (resp.success) {
        dashboardData.value = DashboardData.fromJson(resp.data);
        updateSelfBalance(dashboardData.value.orderData);
        tradeDecimal =
            dashboardData.value.orderData?.total?.tradeWallet?.pairDecimal ??
                DefaultValue.decimal;

        if (selectedCoinPair.value.coinPair == null) {
          final exPair =
              dashboardData.value.orderData?.exchangePair ?? "";
          if (exPair.isNotEmpty) {
            selectedCoinPair.value =
                (dashboardData.value.coinPairs ?? []).firstWhere(
                    (element) => element.coinPair == exPair);
          }
        }

        FavoriteHelper.checkFavorite(
            selectedCoinPair.value,
            '',
            (pair) => {
                  selectedCoinPair.value = pair,
                  selectedCoinPair.refresh()
                });
        _chartController.setCoinPair(selectedCoinPair.value);

        Future.delayed(const Duration(milliseconds: 100), () {
          getExchangeOrderList(FromKey.sell);
          getExchangeOrderList(FromKey.buy);
        });
        Future.delayed(const Duration(milliseconds: 200),
            () => getTradeHistoryList());
        Future.delayed(const Duration(milliseconds: 400),
            () => getExchangeTradeList());
        Future.delayed(const Duration(milliseconds: 500),
            () => getLimitOrderTolerance());

        subscribeCoinPairChannel();

        // ── Start live data refresh timer ─────────────────────────────
        _startRefreshTimer();
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

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _initBotFromDashboard();
    _refreshTimer = Timer.periodic(
      const Duration(milliseconds: _refreshIntervalMs),
      (_) {
        if (!_botEnabled) return;
        final livePrice = dashboardData.value.lastPriceData?.isNotEmpty == true
            ? (dashboardData.value.lastPriceData!.first.price ?? 0)
            : 0.0;
        if (livePrice > 0) _basePrice = livePrice.toDouble();
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ORDER LISTS
  // ─────────────────────────────────────────────────────────────────────────
  void getExchangeOrderList(String type) {
    APIRepository()
        .getExchangeOrderList(
            type,
            dashboardData.value.orderData?.baseCoinId ?? 0,
            dashboardData.value.orderData?.tradeCoinId ?? 0)
        .then((resp) {
      if (resp.success) {
        var list = List<ExchangeOrder>.from(
            resp.data[APIKeyConstants.orders]
                .map((x) => ExchangeOrder.fromJson(x)));
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
    int length = selectedOrderSort.value == FromKey.all
        ? DefaultValue.listLimitOrderBook ~/ 2
        : DefaultValue.listLimitOrderBook;
    length = list.length < length ? list.length : length;
    return length;
  }

  void getExchangeTradeList() {
    APIRepository()
        .getExchangeTradeList(
            dashboardData.value.orderData?.baseCoinId ?? 0,
            dashboardData.value.orderData?.tradeCoinId ?? 0)
        .then((resp) {
      if (resp.success) {
        final list = List<ExchangeTrade>.from(
            resp.data[APIKeyConstants.transactions]
                .map((x) => ExchangeTrade.fromJson(x)));
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
    APIRepository()
        .getTradeHistoryList(orderData?.baseCoinId ?? 0,
            orderData?.tradeCoinId ?? 0, FromKey.buySell)
        .then((resp) {
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
      final list = (dashboardData.value.coinPairs ?? [])
          .where((element) =>
              (element.coinPairName ?? "")
                  .toLowerCase()
                  .contains(searchText))
          .toList();
      coinPairs.value = list;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PLACE ORDER APIs
  // ─────────────────────────────────────────────────────────────────────────
  void placeOrderLimit(bool isBuy, int baseCoinId, int tradeCoinId,
      double price, double amount, Function() onSuccess) {
    showLoadingDialog();
    APIRepository()
        .placeOrderLimit(isBuy, baseCoinId, tradeCoinId, price, amount)
        .then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success =
            resp.data[APIKeyConstants.status] as bool? ?? false;
        final message =
            resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) onSuccess();
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void placeOrderMarket(bool isBuy, int baseCoinId, int tradeCoinId,
      double price, double amount, Function() onSuccess) {
    showLoadingDialog();
    APIRepository()
        .placeOrderMarket(isBuy, baseCoinId, tradeCoinId, price, amount)
        .then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success =
            resp.data[APIKeyConstants.status] as bool? ?? false;
        final message =
            resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) onSuccess();
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void placeOrderStopMarket(
    bool isBuy,
    int baseCoinId,
    int tradeCoinId,
    double amount,
    double total,
    double price,
    double stop,
    Function() onSuccess,
  ) {
    showLoadingDialog();
    APIRepository()
        .placeOrderStopMarket(
            isBuy, baseCoinId, tradeCoinId, amount, total, price, stop)
        .then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success =
            resp.data[APIKeyConstants.status] as bool? ?? false;
        final message =
            resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) onSuccess();
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

  void cancelOpenOrderApp(String tradeType, int tradeId) {
    showLoadingDialog();
    APIRepository().cancelOpenOrderApp(tradeType, tradeId).then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success =
            resp.data[APIKeyConstants.status] as bool? ?? false;
        final message =
            resp.data[APIKeyConstants.message] as String? ?? "";
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
    APIRepository()
        .getLimitOrderTolerance(
            oData?.baseCoinId ?? 0, oData?.tradeCoinId ?? 0)
        .then((resp) {
      if (resp.success && resp.data is Map?) {
        tolerance = TradeTolerance.fromJson(resp.data);
      }
    });
  }

  // =========================================================================
  // BOT ENGINE — TSX MobileTrade ka exact port
  // =========================================================================

  /// Dashboard data aane ke baad bot settings read karo aur engine shuru karo
  void _initBotFromDashboard() {
    // Read bot enable flag + speeds from CommonSettings (same source as website)
    try {
      final objMap = GetStorage().read(PreferenceKey.settingsObject);
      if (objMap != null) {
        final s = CommonSettings.fromJson(objMap as Map<String, dynamic>);
        // Website: parseInt(settings?.enable_bot_trade) === 1
        final fromSettings = s.enableBotTrade ?? 0;
        final fromDashboard = dashboardData.value.enableBotTrade ?? 0;
        _botEnabled = fromSettings == 1 || fromDashboard == 1;
        _kObSpeed = max(300, s.botOrderBookSpeed ?? 800);
        _kTrMin   = max(20,  s.botTradeSpeedMin  ?? 50);
        _kTrMax   = max(50,  s.botTradeSpeedMax  ?? 150);
        _kPrSpeed = max(300, s.botPriceSpeed     ?? 800);
        _kPrPct   = min(s.botPriceChangePercent  ?? 0.0001, 0.0001);
      } else {
        _botEnabled = (dashboardData.value.enableBotTrade ?? 0) == 1;
      }
    } catch (_) {
      _botEnabled = (dashboardData.value.enableBotTrade ?? 0) == 1;
    }

    if (!_botEnabled) return;

    final price =
        dashboardData.value.lastPriceData?.isNotEmpty == true
            ? (dashboardData.value.lastPriceData!.first.price ?? 0.0)
            : 0.0;

    _basePrice = price.toDouble();
    _lastBasePrice = _basePrice;

    if (_basePrice > 0 && _sessionHigh == 0) {
      _sessionHigh = (dashboardData.value.orderData?.total?.tradeWallet?.high ??
              _basePrice)
          .toDouble();
      _sessionLow = (dashboardData.value.orderData?.total?.tradeWallet?.low ??
              _basePrice)
          .toDouble();
      _sessionVol = (dashboardData.value.orderData?.total?.tradeWallet?.volume ??
              0)
          .toDouble();

      final range = _amountRangeByPrice(_basePrice);
      final dMin =
          (dashboardData.value.orderData?.botMinAmount ?? 0).toDouble();
      final dMax =
          (dashboardData.value.orderData?.botMaxAmount ?? 0).toDouble();
      _minAmt = dMin > 0 ? dMin : range[0];
      _maxAmt = dMax > 0 ? dMax : range[1];
    }

    if (!_botStarted) _startBot();
  }

  void _startBot() {
    if (_botStarted) return;
    _botStarted = true;

    // ── 1. Order Book loop ────────────────────────────────────────────────
    void obLoop() {
      if (!_botEnabled || !_botStarted) return;
      _topUpOrderBook();
      _obTimer = Timer(Duration(milliseconds: _kObSpeed), obLoop);
    }

    _obTimer = Timer(const Duration(seconds: 1), obLoop);

    // ── 2. Fake trades loop ───────────────────────────────────────────────
    void tradeLoop() {
      if (!_botEnabled || !_botStarted) return;
      if (_basePrice <= 0) {
        _tradeTimer = Timer(const Duration(milliseconds: 500), tradeLoop);
        return;
      }
      _addFakeTrade();
      final delay =
          _kTrMin + _rng.nextInt(_kTrMax - _kTrMin);
      _tradeTimer = Timer(Duration(milliseconds: delay), tradeLoop);
    }

    _tradeTimer =
        Timer(const Duration(milliseconds: 500), tradeLoop);

    // ── 3. Price tick loop ────────────────────────────────────────────────
    void priceLoop() {
      if (!_botEnabled || !_botStarted) return;
      if (_basePrice <= 0) {
        _priceTimer =
            Timer(const Duration(milliseconds: 500), priceLoop);
        return;
      }
      _tickPrice();
      _priceTimer =
          Timer(Duration(milliseconds: _kPrSpeed), priceLoop);
    }

    _priceTimer =
        Timer(const Duration(milliseconds: 1500), priceLoop);
  }

  void _stopBot() {
    _obTimer?.cancel();
    _tradeTimer?.cancel();
    _priceTimer?.cancel();
    _obTimer = null;
    _tradeTimer = null;
    _priceTimer = null;
    _botStarted = false;
  }

  void _resetBotState() {
    _botEnabled = false;
    _botInitialized = false;
    _sessionHigh = 0;
    _sessionLow = 0;
    _sessionVol = 0;
    _basePrice = 0;
    _lastBasePrice = 0;
    _botBuyList = [];
    _botSellList = [];
    _chartAccVol = 0;
    _chartAccPrice = 0;
    _chartLastPush = 0;
  }

  // ── Order Book top-up (TSX topUp()) ──────────────────────────────────────
  void _topUpOrderBook() {
    if (_basePrice <= 0) return;
    final dec = tradeDecimal;
    final mn = _minAmt > 0 ? _minAmt : _amountRangeByPrice(_basePrice)[0];
    final mx = _maxAmt > 0 ? _maxAmt : _amountRangeByPrice(_basePrice)[1];

    if (!_botInitialized) {
      final book = _buildBook(_basePrice, dec, mn, mx);
      _botBuyList = book[0];
      _botSellList = book[1];
      _botInitialized = true;
      _lastBasePrice = _basePrice;
    } else {
      final mult = pow(10, dec);
      final moved = (((_basePrice * mult) - (_lastBasePrice * mult)).abs());
      if (moved >= 0.5 * mult) {
        _botSellList = _shiftBook(_botSellList, _basePrice, false, dec, mn, mx);
        _botBuyList = _shiftBook(_botBuyList, _basePrice, true, dec, mn, mx);
        _lastBasePrice = _basePrice;
      } else {
        _botBuyList = _nudgeAmounts(_botBuyList, mn, mx);
        _botSellList = _nudgeAmounts(_botSellList, mn, mx);
      }
    }

    // Update observables
    buyExchangeOrder.value = List.from(_botBuyList);
    sellExchangeOrder.value = List.from(_botSellList);
    _chartController.buyOrders.value = List.from(_botBuyList);
    _chartController.sellOrders.value = List.from(_botSellList);
    buyExchangeOrder.refresh();
    sellExchangeOrder.refresh();
  }

  // ── Fake trade (TSX addTrade()) ───────────────────────────────────────────
  void _addFakeTrade() {
    final dec = tradeDecimal;
    final mn = _minAmt > 0 ? _minAmt : _amountRangeByPrice(_basePrice)[0];
    final mx = _maxAmt > 0 ? _maxAmt : _amountRangeByPrice(_basePrice)[1];
    final isBuy = _rng.nextBool();
    final mult = pow(10, dec).toDouble();
    final offset = (_rng.nextDouble() * 0.2 * mult).floor() + 1;
    final tradeInt = isBuy
        ? (_basePrice * mult).round() + offset
        : (_basePrice * mult).round() - offset;
    final tradePrice = tradeInt / mult;
    final amount = _makeAmt(mn, mx);
    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    final newTrade = ExchangeTrade(
      price: tradePrice,
      amount: amount,
      time: timeStr,
    );

    final current = List<ExchangeTrade>.from(exchangeTrades);
    current.insert(0, newTrade);
    if (current.length > 50) current.removeLast();
    exchangeTrades.value = current;
    exchangeTrades.refresh();

    _chartAccPrice = tradePrice;
    _chartAccVol += amount * tradePrice;
    final nowTs = DateTime.now().millisecondsSinceEpoch;
    if (nowTs - _chartLastPush >= _kChartInterval) {
      _chartLastPush = nowTs;
      // Chart update — SocketTradeInfo ka minimal stub paas karo
      _chartController.updateChart(
        SocketTradeInfo(
          orderData: dashboardData.value.orderData,
          lastPriceData: dashboardData.value.lastPriceData,
          trades: Trades(
            transactions: exchangeTrades,
          ),
        ),
      );
      _chartAccVol = 0;
    }
  }

  // ── Price tick (TSX tickPrice()) ──────────────────────────────────────────
  void _tickPrice() {
    final lpd = dashboardData.value.lastPriceData;
    if (lpd == null || lpd.isEmpty) return;

    final current = (lpd.first.price ?? 0).toDouble();
    final delta = current * (_rng.nextDouble() * _kPrPct * 2 - _kPrPct);
    final newPrice = current + delta;
    _basePrice = newPrice;

    // Update last price data
    final updated = PriceData(
      price: newPrice,
      lastPrice: lpd.first.price,
      priceOrderType: lpd.first.priceOrderType,
    );
    dashboardData.value.lastPriceData = [updated, ...lpd.skip(1)];
    dashboardData.refresh();
    _chartController.update();
    update();
  }

  // =========================================================================
  // BOT HELPERS — TSX helper functions ka exact port
  // =========================================================================

  /// TSX getAmountRangeByPrice()
  List<double> _amountRangeByPrice(double p) {
    if (p >= 10000) return [0.001, 0.1];
    if (p >= 1000) return [0.1, 2.0];
    if (p >= 100) return [0.5, 10.0];
    if (p >= 1) return [10.0, 500.0];
    if (p >= 0.01) return [100.0, 5000.0];
    if (p >= 0.0001) return [10000.0, 500000.0];
    return [1000000000.0, 20000000000.0];
  }

  /// TSX makeAmt()
  double _makeAmt(double mn, double mx) {
    final r = _rng.nextDouble();
    double a;
    if (r < 0.3) {
      a = mn + _rng.nextDouble() * (mx - mn) * 0.25;
    } else if (r < 0.7) {
      a = mn + (mx - mn) * 0.25 + _rng.nextDouble() * (mx - mn) * 0.5;
    } else {
      a = mn + (mx - mn) * 0.65 + _rng.nextDouble() * (mx - mn) * 0.35;
    }
    return a.clamp(mn, mx);
  }

  /// TSX makeRow() — ek single ExchangeOrder banata hai
  ExchangeOrder _makeRow(double priceF, double mn, double mx) {
    final amt = _makeAmt(mn, mx);
    final pct = _rng.nextDouble() * 70 + 10;
    return ExchangeOrder(
      price: priceF,
      amount: amt,
      total: amt * priceF,
      percentage: pct,
    );
  }

  /// TSX buildBook() — fresh order book
  List<List<ExchangeOrder>> _buildBook(
      double price, int dec, double mn, double mx) {
    final mult = pow(10, dec).toDouble();
    var base = (price * mult).round().toDouble();
    final minStep = max(1, mult * 0.1);
    final maxStep = mult * 1.5;

    // Sells (asks) — above base price
    final sells = <ExchangeOrder>[];
    var cur = base;
    for (var i = 0; i < _kMinBotOrders; i++) {
      cur += (minStep + _rng.nextDouble() * (maxStep - minStep)).floor();
      sells.add(_makeRow(cur / mult, mn, mx));
    }
    // Sort descending (top = highest, bottom = closest to mid)
    sells.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));

    // Buys (bids) — below base price
    final buys = <ExchangeOrder>[];
    cur = base;
    for (var i = 0; i < _kMinBotOrders; i++) {
      cur -= (minStep + _rng.nextDouble() * (maxStep - minStep)).floor();
      if (cur <= 0) break;
      buys.add(_makeRow(cur / mult, mn, mx));
    }
    // Sort descending (top = highest bid, spread side)
    buys.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));

    return [buys, sells];
  }

  /// TSX shiftBook() — price move ke baad book re-anchor
  List<ExchangeOrder> _shiftBook(List<ExchangeOrder> orders, double price,
      bool isBuy, int dec, double mn, double mx) {
    final mult = pow(10, dec).toDouble();
    final base = (price * mult).round().toDouble();
    final minStep = max(1, mult * 0.1);
    final maxStep = mult * 1.5;
    final maxDist = 50 * mult;

    // Keep only orders still within range
    List<ExchangeOrder> kept = orders.where((o) {
      final pi = ((o.price ?? 0) * mult).round().toDouble();
      return isBuy
          ? pi < base && (base - pi) <= maxDist
          : pi > base && (pi - base) <= maxDist;
    }).toList();

    final used = <double>{};
    for (final o in kept) {
      used.add(((o.price ?? 0) * mult).round().toDouble());
    }

    // Top up until we have enough
    while (kept.length < _kMinBotOrders) {
      if (isBuy) {
        final lowest = kept.isEmpty
            ? base
            : kept
                .map((o) => ((o.price ?? 0) * mult).round().toDouble())
                .reduce(min);
        final ni = lowest -
            (minStep + _rng.nextDouble() * (maxStep - minStep)).floor();
        if (ni > 0 && !used.contains(ni)) {
          used.add(ni);
          kept.add(_makeRow(ni / mult, mn, mx));
        }
      } else {
        final highest = kept.isEmpty
            ? base
            : kept
                .map((o) => ((o.price ?? 0) * mult).round().toDouble())
                .reduce(max);
        final ni = highest +
            (minStep + _rng.nextDouble() * (maxStep - minStep)).floor();
        if (!used.contains(ni)) {
          used.add(ni);
          kept.add(_makeRow(ni / mult, mn, mx));
        }
      }
    }

    kept.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
    if (kept.length > _kMinBotOrders) kept = kept.sublist(0, _kMinBotOrders);
    return kept;
  }

  /// TSX nudgeAmts() — small amount fluctuation per tick
  List<ExchangeOrder> _nudgeAmounts(
      List<ExchangeOrder> orders, double mn, double mx) {
    final count = _rng.nextDouble() < 0.4
        ? (_rng.nextBool() ? 1 : 2)
        : 0;
    final idxs = <int>{};
    while (idxs.length < count && orders.isNotEmpty) {
      idxs.add(_rng.nextInt(orders.length));
    }

    return orders.asMap().entries.map((e) {
      final i = e.key;
      final o = e.value;
      final pf = o.price ?? 0;
      if (idxs.contains(i)) {
        final na = _makeAmt(mn, mx);
        return ExchangeOrder(
            price: pf,
            amount: na,
            total: na * pf,
            percentage: o.percentage);
      }
      if (_rng.nextDouble() > 0.2) {
        final cur = o.amount ?? 0;
        final nudged = max(mn, cur + (_rng.nextDouble() * 0.30 - 0.15) * cur);
        return ExchangeOrder(
            price: pf,
            amount: nudged,
            total: nudged * pf,
            percentage: o.percentage);
      }
      return o;
    }).toList();
  }
}
