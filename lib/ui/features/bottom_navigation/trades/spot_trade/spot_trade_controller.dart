import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/currency.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/exchange_order.dart';
import 'package:tradexpro_flutter/data/models/spot_data.dart';
import 'package:tradexpro_flutter/data/remote/spot_socket.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/helper/favorite_helper.dart';
import 'package:tradexpro_flutter/ui/features/charts/charts_controller.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/data/remote/socket_provider.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/data/models/response.dart';


class SpotTradeController extends GetxController implements SocketListener {
  Rx<DashboardData> dashboardData = DashboardData().obs;
  Rx<SelfBalance> selfBalance = SelfBalance().obs;
  Rx<CoinPair> selectedCoinPair = CoinPair().obs;
  RxList<CoinPair> coinPairs = <CoinPair>[].obs;
  Map<String, String> coinIconMap = {};
  RxList<ExchangeOrder> buyExchangeOrder = <ExchangeOrder>[].obs;
  RxList<ExchangeOrder> sellExchangeOrder = <ExchangeOrder>[].obs;
  RxList<ExchangeTrade> exchangeTrades = <ExchangeTrade>[].obs;
  /// Current pair orders — shown in main screen bottom "Open order" tab
  Rx<SpotAllMyHistories> allMyHistories = SpotAllMyHistories().obs;
  /// All pairs orders — shown in My Trade history modal (no symbol filter)
  Rx<SpotAllMyHistories> allPairsHistories = SpotAllMyHistories().obs;
  RxBool isAllPairsLoading = false.obs;
  /// Spot available balances (Trading Account) — from /v1/spot/balances
  RxDouble spotAvailableBase = 0.0.obs;   // e.g. USDT available
  RxDouble spotAvailableTrade = 0.0.obs;  // e.g. BTC available
  RxDouble spotLockedBase = 0.0.obs;
  RxDouble spotLockedTrade = 0.0.obs;
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
  /// true = last tick was up or flat, false = down
  final RxBool tickerGoingUp = true.obs;

  /// Latest spot ticker (price change, 24h high/low/vol)
  final Rx<SpotTicker> spotTicker = const SpotTicker().obs;

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
      }
      selfBalance.refresh();
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
    spotTicker.value = t;
    final prevPrice = selfBalance.value.buyPrice;
    if (prevPrice != null && prevPrice > 0) {
      tickerGoingUp.value = t.price >= prevPrice;
    }
    var od = dashboardData.value.orderData;
    if (od != null) {
      od.buyPrice = t.price;
      od.sellPrice = t.price;
    } else {
      od = OrderData(
        buyPrice: t.price,
        sellPrice: t.price,
        baseCoin: selectedCoinPair.value.childCoinName,  // USDT
        tradeCoin: selectedCoinPair.value.parentCoinName, // BTC
      );
      dashboardData.value.orderData = od;
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
    handleOrderBookList(FromKey.buy, _bidsToOrders(ob.bids));
    handleOrderBookList(FromKey.sell, _asksToOrders(ob.asks));
  }

  /// bids [[price, amount],...] → ExchangeOrder list (descending by price)
  List<ExchangeOrder> _bidsToOrders(List<List<double>> bids) {
    if (bids.isEmpty) return [];
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

  /// asks [[price, amount],...] → ExchangeOrder list (ascending by price)
  List<ExchangeOrder> _asksToOrders(List<List<double>> asks) {
    if (asks.isEmpty) return [];
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

  void applyLastTrades(List<SpotTrade> trades) => _applyTrades(trades);

  void _applyTrades(List<SpotTrade> trades) {
    exchangeTrades.value = trades
        .map((t) => ExchangeTrade(
              price: t.price,
              amount: t.amount,
              priceOrderType: t.isBuy ? FromKey.buy : FromKey.sell,
              time: _formatTradeTime(t.time),
              total: t.price * t.amount,
            ))
        .toList();
  }

  /// API returns time_str already as "HH:mm:ss". For ISO timestamps extract HH:mm:ss.
  String? _formatTradeTime(String? raw) {
    if (raw == null || raw.isEmpty) return raw;
    // Already HH:mm:ss format from time_str field (e.g. "19:03:22")
    if (raw.contains(':') && !raw.contains('-') && !raw.contains('T')) return raw;
    // ISO format: "2024-01-15T10:30:45Z" or "2024-01-15 10:30:45"
    if (raw.length >= 19) {
      if (raw.contains('T')) return raw.substring(11, 19);
      if (raw.contains(' ')) return raw.substring(11, 19);
    }
    return raw;
  }

  // ── HTTP fallback polling (kicks in only when WS is silent) ──────────────

  void _startHttpPolling() {
    _stopHttpPolling();
    // Poll every 2s only if WS has been silent; WS updates _wsLive=true each tick
    _spotHttpTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_wsLive) {
        printFunction('SpotCtrl', 'WS silent — falling back to HTTP poll');
        _doHttpFetch();
      }
      _wsLive = false;
    });
  }

  void _stopHttpPolling() {
    _spotHttpTimer?.cancel();
    _spotHttpTimer = null;
  }

  /// Unwraps a spot API envelope: {"status":true,"data":{...}} or direct body
  dynamic _unwrapSpotData(dynamic body) {
    if (body is Map) {
      final m = body;
      if (m.containsKey('data') && (m['status'] == true || m['success'] == true)) {
        return m['data'];
      }
    }
    return body;
  }

  /// Called from SpotTradeDetailsScreen to ensure trades are loaded.
  /// WebSocket is primary; HTTP is fallback if WS hasn't sent trades yet.
  void fetchLastTrades() {
    // If WS already has trades, nothing to do
    if (exchangeTrades.isNotEmpty) return;
    // Otherwise kick off WS connection (if not already) + HTTP fallback
    _connectSpotWs();
    _doHttpFetchTrades();
  }

  void _doHttpFetchTrades() async {
    final sym = _spotSymbol;
    if (sym.isEmpty) return;
    try {
      final res = await http
          .get(Uri.parse('https://api.trapix.com/api/v1/spot/trades/$sym'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      List? list;
      if (body is List) {
        list = body;
      } else if (body is Map) {
        final d = body['data'];
        if (d is List) list = d;
      }
      if (list != null && list.isNotEmpty) {
        _applyTrades(list
            .map((t) => SpotTrade.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList());
      }
    } catch (_) {}
  }

  void _doHttpFetch() {
    final sym = _spotSymbol;
    if (sym.isEmpty) return;

    APIRepository().getSpotTicker(sym).then((resp) {
      if (!resp.success) return;
      final payload = _unwrapSpotData(resp.data);
      if (payload is Map) {
        _applyTicker(SpotTicker.fromJson(Map<String, dynamic>.from(payload)));
      }
    });

    APIRepository().getSpotOrderBook(sym).then((resp) {
      if (!resp.success) return;
      final payload = _unwrapSpotData(resp.data);
      if (payload is Map) {
        _applyOrderBook(SpotOrderBook.fromJson(Map<String, dynamic>.from(payload)));
      }
    });

    APIRepository().getSpotTrades(sym).then((resp) {
      if (!resp.success) return;
      final payload = _unwrapSpotData(resp.data);
      if (payload is List) {
        _applyTrades((payload)
            .map((t) => SpotTrade.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList());
      }
    });
  }

  // ── Old Pusher socket (kept for compatibility, no longer primary) ─────────

  @override
  void onDataGet(channel, event, data) {
    // Not used for spot — spot uses _spotWs WebSocket directly
  }

  void subscribeCoinPairChannel() {
    // Spot uses WebSocket, not Pusher channels
  }

  void unSubscribeChannel(bool isDispose) {
    if (channelDashboard.isValid) APIRepository().unSubscribeEvent(channelDashboard, isDispose ? this : null);
    if (channelTradeInfo.isValid) APIRepository().unSubscribeEvent(channelTradeInfo, isDispose ? this : null);
    if (channelUserTrades.isValid) APIRepository().unSubscribeEvent(channelUserTrades, isDispose ? this : null);
    channelTradeInfo = "";
    channelUserTrades = "";
    channelDashboard = "";
  }

  // ── MAIN INIT: load spot pairs then initialize selected pair ─────────────

  void getDefaultPairData() {
    isLoading.value = true;
    APIRepository().getSpotPairs().then((resp) {
      printFunction('SpotCtrl pairs success', resp.success);
      printFunction('SpotCtrl pairs data', resp.data);
      if (!resp.success) {
        isLoading.value = false;
        showToast(resp.message);
        return;
      }
      final raw = _unwrapSpotData(resp.data);
      printFunction('SpotCtrl pairs raw unwrapped', raw);
      List<SpotPair> pairs = [];
      if (raw is List) {
        pairs = raw.map((e) => SpotPair.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } else if (raw is Map && raw['pairs'] is List) {
        pairs = (raw['pairs'] as List).map((e) => SpotPair.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      if (pairs.isEmpty) {
        isLoading.value = false;
        return;
      }
      // Convert SpotPair → CoinPair for UI compatibility
      coinPairs.value = pairs.map(_spotPairToCoinPair).toList();
      dashboardData.value.coinPairs = coinPairs.toList();
      // Select BTC/USDT by default, fallback to first pair
      selectedCoinPair.value = coinPairs.firstWhere(
        (p) => (p.parentCoinName ?? '').toUpperCase() == 'BTC' && (p.childCoinName ?? '').toUpperCase() == 'USDT',
        orElse: () => coinPairs[0],
      );
      getDashBoardData();
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  CoinPair _spotPairToCoinPair(SpotPair p) {
    final base = p.baseCurrency ?? '';
    final quote = p.quoteCurrency ?? '';
    return CoinPair(
      coinPair: '${base}_$quote',
      coinPairName: '$base/$quote',
      parentCoinName: base,
      childCoinName: quote,
      parentCoinId: p.baseCoinId,
      childCoinId: p.quoteCoinId,
      coinPairId: p.id,
      lastPrice: p.currentPrice,
      priceChange: p.priceChange24h,
      high: p.high24h?.toString(),
      low: p.low24h?.toString(),
      volume: p.volume24h,
      icon: coinIconMap[quote.toUpperCase()],
      parentIcon: coinIconMap[base.toUpperCase()],
    );
  }

  void getDashBoardData() {
    if (!selectedCoinPair.value.coinPair.isValid) {
      getDefaultPairData();
      return;
    }

    isLoading.value = true;
    final sym = _spotSymbol;

    // Clear orders immediately so previous pair's data doesn't show
    allMyHistories.value = SpotAllMyHistories();
    allMyHistories.refresh();

    // Load ticker for current price
    APIRepository().getSpotTicker(sym).then((resp) {
      isLoading.value = false;
      if (resp.success) {
        final payload = _unwrapSpotData(resp.data);
        if (payload is Map) {
          final ticker = SpotTicker.fromJson(Map<String, dynamic>.from(payload));
          // Website: baseCoin = USDT (quote), tradeCoin = BTC (base)
          // OrderData.baseCoin = USDT, OrderData.tradeCoin = BTC
          final od = OrderData(
            buyPrice: ticker.price,
            sellPrice: ticker.price,
            baseCoin: selectedCoinPair.value.childCoinName,  // USDT
            tradeCoin: selectedCoinPair.value.parentCoinName, // BTC
          );
          dashboardData.value.orderData = od;
          dashboardData.value.lastPriceData = [
            PriceData(
              price: ticker.price,
              lastPrice: ticker.price,
              priceOrderType: ticker.priceChange24h >= 0 ? FromKey.buy : FromKey.sell,
            ),
          ];
          dashboardData.value.coinPairs = coinPairs.toList();
          dashboardData.refresh();

          selfBalance.value.buyPrice = ticker.price;
          selfBalance.value.sellPrice = ticker.price;
          selfBalance.refresh();

          // Auto-fill price in buy/sell form
          onBuySaleChange?.call(selectedBuySellTab.value);
        }
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });

    // Load spot balances
    getSpotBalances();

    // Fetch exchange coin IDs for legacy order API, then load orders
    _fetchCoinIdsAndLoadOrders(sym);

    // Connect spot WebSocket for live orderbook/trades/ticker
    _chartController.setCoinPair(selectedCoinPair.value);
    FavoriteHelper.checkFavorite(selectedCoinPair.value, '', (pair) {
      selectedCoinPair.value = pair;
      selectedCoinPair.refresh();
    });
    _connectSpotWs();
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

  // ── Spot Balances ─────────────────────────────────────────────────────────

  void getSpotBalances() {
    APIRepository().getSpotBalances().then((resp) {
      if (!resp.success) return;
      _applySpotBalances(resp.data);
    });
  }

  void _applySpotBalances(dynamic rawData) {
    printFunction('SpotCtrl balances raw', rawData);
    final payload = _unwrapSpotData(rawData);
    printFunction('SpotCtrl balances payload', payload);
    if (payload is! Map) return;

    final balances = <String, SpotBalance>{};
    payload.forEach((coin, val) {
      if (val is Map) {
        balances[coin.toString().toUpperCase()] = SpotBalance(
          available: makeDouble(val['available']?.toString() ?? '0'),
          locked: makeDouble(val['locked']?.toString() ?? '0'),
        );
      }
    });

    // parentCoinName = BTC (trade coin), childCoinName = USDT (quote/base coin)
    // Website: baseCoin = USDT (you spend USDT to buy), tradeCoin = BTC (you sell BTC)
    // UI baseWallet = what you spend to BUY = USDT = childCoinName
    // UI tradeWallet = what you sell = BTC = parentCoinName
    final quoteC = selectedCoinPair.value.childCoinName?.toUpperCase()  ?? ''; // USDT
    final baseC  = selectedCoinPair.value.parentCoinName?.toUpperCase() ?? ''; // BTC

    final quoteBalance = balances[quoteC]; // USDT balance
    final baseBalance  = balances[baseC];  // BTC balance

    // Ensure Total object exists
    selfBalance.value.total ??= Total();

    // baseWallet = USDT (spend to buy BTC)
    if (quoteBalance != null) {
      selfBalance.value.total!.baseWallet ??= TradeWallet();
      selfBalance.value.total!.baseWallet!.balance  = quoteBalance.available;
      selfBalance.value.total!.baseWallet!.coinType = quoteC;
      spotAvailableBase.value = quoteBalance.available;
      spotLockedBase.value    = quoteBalance.locked;
    }
    // tradeWallet = BTC (what you're buying/selling)
    if (baseBalance != null) {
      selfBalance.value.total!.tradeWallet ??= TradeWallet();
      selfBalance.value.total!.tradeWallet!.balance  = baseBalance.available;
      selfBalance.value.total!.tradeWallet!.coinType = baseC;
      spotAvailableTrade.value = baseBalance.available;
      spotLockedTrade.value    = baseBalance.locked;
    }
    selfBalance.refresh();
  }

  // ── Fetch orders — spot API first (matches website), then legacy fallback ──

  void _fetchCoinIdsAndLoadOrders(String sym) {
    // Try spot API first exactly like website: GET /v1/spot/orders/open?symbol=
    _loadSpotOrders(sym);

    // Also fetch exchange coin IDs for legacy fallback in case spot API fails
    final pairKey = selectedCoinPair.value.coinPair ?? '';
    if (pairKey.isNotEmpty) {
      APIRepository().getDashBoardData(pairKey).then((resp) {
        if (resp.success && resp.data != null) {
          final data = resp.data;
          dynamic orderData;
          if (data is Map && data['data'] is Map) {
            orderData = data['data']['order_data'];
          } else if (data is Map) {
            orderData = data['order_data'];
          }
          if (orderData is Map) {
            final baseId = makeInt(orderData['base_coin_id']);
            final tradeId = makeInt(orderData['trade_coin_id']);
            printFunction('SpotCtrl coinIds', 'base=$baseId trade=$tradeId');
            if (baseId > 0 && tradeId > 0) {
              selectedCoinPair.value.parentCoinId = baseId;
              selectedCoinPair.value.childCoinId = tradeId;
              selectedCoinPair.refresh();
            }
          }
        }
      }, onError: (_) {});
    }
  }

  void _loadSpotOrders(String sym) {
    isHistoryLoading.value = true;
    // Clear stale data before loading new pair's orders
    allMyHistories.value = SpotAllMyHistories();
    allMyHistories.refresh();
    // Parallel: open orders + order history (same as website)
    Future.wait([
      APIRepository().getSpotOpenOrders(sym),
      APIRepository().getSpotOrderHistory(sym),
    ]).then((results) {
      isHistoryLoading.value = false;
      // If pair changed while loading, discard stale results
      if (_spotSymbol != sym) {
        printFunction('SpotCtrl', 'pair changed — discarding stale spot orders for $sym');
        return;
      }
      final openResp = results[0];
      final histResp = results[1];

      printFunction('SpotCtrl openOrders', openResp.success ? openResp.data : openResp.message);
      printFunction('SpotCtrl orderHistory', histResp.success ? histResp.data : histResp.message);

      bool gotData = false;

      if (openResp.success) {
        final raw = _extractList(openResp.data);
        if (raw.isNotEmpty) {
          allMyHistories.value.orders = raw
              .map((o) => Trade.fromJson(Map<String, dynamic>.from(o as Map)))
              .toList();
          gotData = true;
        }
      }

      if (histResp.success) {
        final raw = _extractList(histResp.data);
        if (raw.isNotEmpty) {
          final trades = raw
              .map((o) => Trade.fromJson(Map<String, dynamic>.from(o as Map)))
              .toList();
          allMyHistories.value.buyOrders = trades.where((t) => (t.type ?? '').toLowerCase() == 'buy').toList();
          allMyHistories.value.sellOrders = trades.where((t) => (t.type ?? '').toLowerCase() == 'sell').toList();
          allMyHistories.value.transactions = trades;
          gotData = true;
        }
      }

      allMyHistories.refresh();

      // If spot API returned nothing, fall back to legacy API
      if (!gotData) {
        printFunction('SpotCtrl', 'Spot API empty — trying legacy API');
        _tryLegacyFallback();
      }
    }, onError: (e) {
      isHistoryLoading.value = false;
      printFunction('SpotCtrl loadSpotOrders error', e);
      _tryLegacyFallback();
    });
  }

  void _tryLegacyFallback() {
    final pair = selectedCoinPair.value;
    final baseCoinId = pair.parentCoinId ?? 0;
    final tradeCoinId = pair.childCoinId ?? 0;
    if (baseCoinId > 0 && tradeCoinId > 0) {
      _loadLegacyOrders(baseCoinId, tradeCoinId);
    }
  }

  // ── Probe order endpoints (temp debug) ───────────────────────────────────
  void probeOrderEndpoints(String sym) {
    final candidates = [
      '/v1/spot/my-orders',
      '/v1/spot/user-orders',
      '/v1/spot/trade-orders',
      '/v1/spot/order-list',
      '/v1/spot/history',
      '/v1/spot/my-trades',
      '/v1/spot/trade-history',
    ];
    for (final path in candidates) {
      final url = 'https://api.trapix.com/api$path?symbol=$sym';
      APIRepository().probeUrl(url).then((resp) {
        debugPrint('PROBE $path => ${resp.success ? "OK: ${resp.data.toString().substring(0, resp.data.toString().length.clamp(0, 100))}" : "FAIL: ${resp.message}"}');
      });
    }
  }

  // ── Spot Open Orders / Order History ─────────────────────────────────────

  void getSpotOpenOrders(String sym) => _loadSpotOrders(sym);

  void getSpotOrderHistory(String sym) {
    // Already handled by _loadSpotOrders — skip duplicate call
  }

  void _loadLegacyOrders(int baseCoinId, int tradeCoinId) {
    isHistoryLoading.value = true;
    // Snapshot current pair so we can filter results to only this pair
    final currentBase = baseCoinId;
    final currentTrade = tradeCoinId;
    APIRepository().getSpotMyOrders(baseCoinId, tradeCoinId, 'all').then((resp) {
      isHistoryLoading.value = false;
      printFunction('SpotCtrl legacyOrders success', resp.success);
      printFunction('SpotCtrl legacyOrders data', resp.data);
      if (!resp.success) {
        printFunction('SpotCtrl legacyOrders error', resp.message);
        return;
      }
      // If the pair changed while loading, discard stale results
      final nowBase = selectedCoinPair.value.parentCoinId ?? 0;
      final nowTrade = selectedCoinPair.value.childCoinId ?? 0;
      if (nowBase != currentBase || nowTrade != currentTrade) {
        printFunction('SpotCtrl legacyOrders', 'pair changed — discarding stale result');
        return;
      }
      // isDynamic: raw body = {"status": true, "data": {orders:[], ...}}
      dynamic payload = resp.data;
      if (payload is Map) {
        // Unwrap nested "data" key if present
        if (payload['data'] is Map) payload = payload['data'];
        allMyHistories.value = SpotAllMyHistories.fromJson(Map<String, dynamic>.from(payload));
      }
      allMyHistories.refresh();
    }, onError: (e) {
      isHistoryLoading.value = false;
      printFunction('SpotCtrl legacyOrders error', e);
    });
  }

  List<dynamic> _extractList(dynamic data) {
    final payload = _unwrapSpotData(data);
    if (payload is List) return payload;
    if (payload is Map) {
      if (payload['orders'] is List) return payload['orders'] as List;
      if (payload['data'] is List) return payload['data'] as List;
    }
    return [];
  }

  void getExchangeOrderList(String type) {
    // Not used for spot — orderbook comes from WebSocket / HTTP poll
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
    // Not used for spot — trades come from WebSocket / HTTP poll
  }

  void getTradeHistoryList() {
    _loadSpotOrders(_spotSymbol);
  }

  /// Loads ALL pairs' open orders + order history — used by My Trade history modal.
  /// Website: fetchOpenOrders() + fetchOrderHistory() without symbol param.
  void loadAllMyOrders() {
    isAllPairsLoading.value = true;
    Future.wait([
      APIRepository().getSpotOpenOrders(),    // no symbol = all pairs
      APIRepository().getSpotOrderHistory(),  // no symbol = all pairs
    ]).then((results) {
      isAllPairsLoading.value = false;
      final openResp = results[0];
      final histResp = results[1];
      final histories = SpotAllMyHistories();

      if (openResp.success) {
        final raw = _extractList(openResp.data);
        histories.orders = raw
            .map((o) => Trade.fromJson(Map<String, dynamic>.from(o as Map)))
            .toList();
      }

      if (histResp.success) {
        final raw = _extractList(histResp.data);
        final trades = raw
            .map((o) => Trade.fromJson(Map<String, dynamic>.from(o as Map)))
            .toList();
        histories.buyOrders = trades.where((t) => (t.type ?? '').toLowerCase() == 'buy').toList();
        histories.sellOrders = trades.where((t) => (t.type ?? '').toLowerCase() == 'sell').toList();
        histories.transactions = trades;
      }

      // Fallback to legacy if both spot calls returned nothing
      final gotData = (histories.orders?.isNotEmpty ?? false) ||
          (histories.transactions?.isNotEmpty ?? false);
      if (gotData) {
        allPairsHistories.value = histories;
        allPairsHistories.refresh();
      } else {
        _loadLegacyAllOrders();
      }
    }, onError: (e) {
      isAllPairsLoading.value = false;
      printFunction('SpotCtrl loadAllMyOrders error', e);
      _loadLegacyAllOrders();
    });
  }

  void _loadLegacyAllOrders() {
    // Legacy API needs coin IDs — use current pair's IDs to get all orders for this user
    final pair = selectedCoinPair.value;
    final baseCoinId = pair.parentCoinId ?? 0;
    final tradeCoinId = pair.childCoinId ?? 0;
    if (baseCoinId <= 0 || tradeCoinId <= 0) return;
    isAllPairsLoading.value = true;
    APIRepository().getSpotMyOrders(baseCoinId, tradeCoinId, 'all').then((resp) {
      isAllPairsLoading.value = false;
      if (!resp.success) return;
      dynamic payload = resp.data;
      if (payload is Map) {
        if (payload['data'] is Map) payload = payload['data'];
        allPairsHistories.value = SpotAllMyHistories.fromJson(Map<String, dynamic>.from(payload));
        allPairsHistories.refresh();
      }
    }, onError: (e) {
      isAllPairsLoading.value = false;
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

  void _refreshAfterOrder() {
    final sym = _spotSymbol;
    Future.delayed(const Duration(milliseconds: 1000), () {
      getSpotBalances();
      _loadSpotOrders(sym);
    });
  }

  // Shared response handler for placeSpotOrder
  void _handleSpotOrderResp(ServerResponse resp, Function() onSuccess) {
    hideLoadingDialog();
    if (!resp.success) {
      // Try to extract error message from response body
      String errMsg = resp.message.isNotEmpty ? resp.message : 'Order failed';
      if (resp.data is Map) {
        final d = resp.data as Map;
        errMsg = d['message']?.toString() ?? d['error']?.toString() ?? errMsg;
        // Handle validation errors map
        if (d['errors'] is Map) {
          final errs = d['errors'] as Map;
          errMsg = errs.values.first?.toString() ?? errMsg;
        }
      }
      showToast(errMsg, isError: true);
      return;
    }
    final data = resp.data;
    bool ok = true;
    String msg = 'Order placed successfully';
    if (data is Map) {
      final status = data['status'] ?? data['success'];
      if (status is bool) {
        ok = status;
      } else if (status == true || status == 1) {
        ok = true;
      }
      msg = data['message'] as String? ?? msg;
    }
    showToast(msg, isError: !ok);
    if (ok) {
      onSuccess();
      _refreshAfterOrder();
    }
  }

  void placeOrderLimit(bool isBuy, int baseCoinId, int tradeCoinId, double price, double amount, Function() onSuccess) {
    showLoadingDialog();
    APIRepository().placeSpotOrder(
      _spotSymbol,
      isBuy ? 'buy' : 'sell',
      'limit',
      amount,
      price: price,
    ).then(
      (resp) => _handleSpotOrderResp(resp, onSuccess),
      onError: (err) { hideLoadingDialog(); showToast(err.toString()); },
    );
  }

  void placeOrderMarket(bool isBuy, int baseCoinId, int tradeCoinId, double price, double amount, Function() onSuccess) {
    showLoadingDialog();
    APIRepository().placeSpotOrder(
      _spotSymbol,
      isBuy ? 'buy' : 'sell',
      'market',
      amount,
    ).then(
      (resp) => _handleSpotOrderResp(resp, onSuccess),
      onError: (err) { hideLoadingDialog(); showToast(err.toString()); },
    );
  }

  void placeOrderStopMarket(bool isBuy, int baseCoinId, int tradeCoinId, double amount, double limit, double stop, Function() onSuccess) {
    showLoadingDialog();
    final body = <String, dynamic>{
      'symbol': _spotSymbol,
      'side': isBuy ? 'buy' : 'sell',
      'order_type': 'stop_limit',
      'amount': amount,
      'price': limit,
      'stop_price': stop,
    };
    APIRepository().placeSpotOrderRaw(body).then(
      (resp) => _handleSpotOrderResp(resp, onSuccess),
      onError: (err) { hideLoadingDialog(); showToast(err.toString()); },
    );
  }

  void cancelOpenOrderApp(String tradeType, int tradeId) {
    showLoadingDialog();
    // Try spot DELETE cancel (same as website: DELETE /v1/spot/order/{id})
    APIRepository().cancelSpotOrder(tradeId.toString()).then((resp) {
      if (resp.success) {
        hideLoadingDialog();
        final data = resp.data;
        String msg = 'Order cancelled';
        if (data is Map) msg = data['message'] as String? ?? msg;
        showToast(msg);
        _refreshAfterOrder();
      } else {
        // Fallback to legacy cancel
        APIRepository().cancelOpenOrderApp(tradeType, tradeId).then((resp2) {
          hideLoadingDialog();
          if (!resp2.success) { showToast(resp2.message); return; }
          final data = resp2.data;
          bool ok = true;
          String msg = 'Order cancelled';
          if (data is Map) {
            final status = data['status'] ?? data['success'];
            ok = status == true || status == 1;
            msg = data['message'] as String? ?? msg;
          }
          showToast(msg, isError: !ok);
          if (ok) _refreshAfterOrder();
        }, onError: (err) { hideLoadingDialog(); showToast(err.toString()); });
      }
    }, onError: (err) {
      // Fallback to legacy cancel on error
      APIRepository().cancelOpenOrderApp(tradeType, tradeId).then((resp2) {
        hideLoadingDialog();
        if (!resp2.success) { showToast(resp2.message); return; }
        final data = resp2.data;
        bool ok = true;
        String msg = 'Order cancelled';
        if (data is Map) {
          final status = data['status'] ?? data['success'];
          ok = status == true || status == 1;
          msg = data['message'] as String? ?? msg;
        }
        showToast(msg, isError: !ok);
        if (ok) _refreshAfterOrder();
      }, onError: (err2) { hideLoadingDialog(); showToast(err2.toString()); });
    });
  }

  void getLimitOrderTolerance() {
    // Not needed for spot API — no tolerance endpoint
  }
}
