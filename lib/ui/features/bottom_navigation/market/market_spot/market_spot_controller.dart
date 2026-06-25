import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  Timer? _fallbackTimer;
  Timer? _renderTimer; // debounce WS renders

  // Direct WebSocket for real-time ms updates
  WebSocket? _ws;
  bool _wsDisposed = false;
  Timer? _wsReconnTimer;

  List<String> getFilterList() => ["ALL", "USDT", "USDC"];

  Map<int, String> getTypeMap() =>
      {1: "All Crypto".tr, 2: "Spot Markets".tr, 3: "New Listing".tr};

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
    _searchTimer = Timer(const Duration(seconds: 1), () => applyFiltersAndSort());
  }

  void onSortChanged(spot.MarketSort sort) {
    marketSort.value = sort;
    marketSort.refresh();
    applyFiltersAndSort();
  }

  // icon cache from REST — keyed by "BASEUSDT"
  final Map<String, String> _iconCache = {};

  // ── Direct WebSocket ────────────────────────────────────────────────────────
  Future<void> _connectWs() async {
    if (_wsDisposed) return;
    try {
      _ws = await WebSocket.connect('wss://trapix.com/ws/spot');
      _ws!.add(jsonEncode({'type': 'subscribe_all'}));
      _ws!.listen(
        _onWsData,
        onDone: _onWsDone,
        onError: (_) => _onWsDone(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleWsReconnect();
    }
  }

  void _onWsData(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      if (msg['type'] != 'update') return;
      final ticker = msg['ticker'] as Map<String, dynamic>?;
      if (ticker == null) return;
      final symbol = (msg['symbol'] as String? ?? '').toUpperCase();
      if (symbol.isEmpty) return;

      final price  = _toDouble(ticker['price']);
      final change = _toDouble(ticker['change_24h']);
      final volume = _toDouble(ticker['volume_24h']);

      final idx = marketFullList.indexWhere((c) =>
          '${c.coinType ?? ''}${c.baseCoinType ?? ''}'.toUpperCase() == symbol);

      if (idx == -1) return;
      if (price  > 0) marketFullList[idx].price  = price;
      marketFullList[idx].change = change;
      if (volume > 0) marketFullList[idx].volume = volume;

      // Debounce: batch all ticks arriving within 100ms into one render
      _renderTimer?.cancel();
      _renderTimer = Timer(const Duration(milliseconds: 100), applyFiltersAndSort);
    } catch (_) {}
  }

  void _onWsDone() {
    _ws = null;
    _scheduleWsReconnect();
  }

  void _scheduleWsReconnect() {
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

  // ── REST fallback (30s — only to catch new pairs / missed updates) ──────────
  void _startFallback() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 30), (_) => _silentRefresh());
  }

  void _silentRefresh() {
    APIRepository().getSpotMarketPairs().then((resp) {
      if (!resp.success) return;
      List raw = resp.data is List ? resp.data as List
          : (resp.data['data'] ?? resp.data['pairs'] ?? resp.data['markets'] ?? []) as List;
      if (raw.isEmpty) return;
      bool changed = false;
      for (final p in raw) {
        final base  = (p['base_currency']  ?? p['base']  ?? p['base_asset']  ?? '') as String;
        final quote = (p['quote_currency'] ?? p['quote'] ?? p['quote_asset'] ?? '') as String;
        final price  = _toDouble(p['current_price'] ?? p['last_price'] ?? p['price']);
        final change = _toDouble(p['price_change_24h'] ?? p['price_change_percent'] ?? p['change_24h'] ?? p['change']);
        final idx = marketFullList.indexWhere(
            (c) => c.coinType == base && c.baseCoinType == quote);
        if (idx != -1) {
          marketFullList[idx].price  = price;
          marketFullList[idx].change = change;
          changed = true;
        }
      }
      if (changed) applyFiltersAndSort();
    }, onError: (_) {});
  }

  // ── Initial load ────────────────────────────────────────────────────────────
  Future<void> getMarketOverviewTopCoinList(bool isLoadMore) async {
    if (!isLoadMore) {
      loadedPage = 0;
      hasMoreData = false;
      marketFullList.clear();
      marketList.clear();
      _iconCache.clear();
    }
    isLoading.value = true;

    APIRepository().getSpotMarketPairs().then((resp) {
      isLoading.value = false;
      if (resp.success) {
        List raw = resp.data is List ? resp.data as List
            : (resp.data['data'] ?? resp.data['pairs'] ?? resp.data['result'] ?? resp.data['markets'] ?? []) as List;

        // Build icon cache keyed by symbol e.g. "BTCUSDT"
        for (final p in raw) {
          final base  = (p['base_currency']  ?? p['base']  ?? '') as String;
          final quote = (p['quote_currency'] ?? p['quote'] ?? '') as String;
          final icon  = (p['icon'] ?? p['logo'] ?? p['image'] ?? '') as String;
          if (base.isNotEmpty && quote.isNotEmpty) {
            _iconCache['$base$quote'.toUpperCase()] = icon;
          }
        }

        final list = raw.map<MarketCoin>((p) {
          final coin = MarketCoin();
          coin.coinType     = p['base_currency']  ?? p['base']  ?? '';
          coin.baseCoinType = p['quote_currency'] ?? p['quote'] ?? '';
          coin.price  = _toDouble(p['current_price'] ?? p['last_price'] ?? p['price']);
          coin.change = _toDouble(p['price_change_24h'] ?? p['price_change_percent'] ?? p['change']);
          coin.volume = _toDouble(p['volume_24h'] ?? p['volume']);
          coin.coinIcon = p['icon'] ?? p['logo'] ?? p['image'] ?? '';
          return coin;
        }).toList();

        marketFullList..clear()..addAll(list);
        applyFiltersAndSort();

        // Now connect WS for live ms-level updates on top of REST data
        _wsDisposed = false;
        _connectWs();
        _startFallback();
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
      final filter = getFilterList()[selectedFilterIndex.value];
      currentList = currentList.where((c) => c.baseCoinType == filter).toList();
    }

    final query = searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      currentList = currentList.where((c) =>
          (c.coinType?.toLowerCase().contains(query) ?? false) ||
          (c.baseCoinType?.toLowerCase().contains(query) ?? false)).toList();
    }

    final s = marketSort.value;
    if (s.pair != null) {
      currentList.sort((a, b) => s.pair! ? (a.coinType ?? '').compareTo(b.coinType ?? '')
          : (b.coinType ?? '').compareTo(a.coinType ?? ''));
    } else if (s.volume != null) {
      currentList.sort((a, b) => s.volume! ? (a.volume ?? 0).compareTo(b.volume ?? 0)
          : (b.volume ?? 0).compareTo(a.volume ?? 0));
    } else if (s.price != null) {
      currentList.sort((a, b) => s.price! ? (a.price ?? 0).compareTo(b.price ?? 0)
          : (b.price ?? 0).compareTo(a.price ?? 0));
    } else if (s.capital != null) {
      currentList.sort((a, b) => s.capital! ? (a.totalBalance ?? 0).compareTo(b.totalBalance ?? 0)
          : (b.totalBalance ?? 0).compareTo(a.totalBalance ?? 0));
    } else if (s.change != null) {
      currentList.sort((a, b) => s.change! ? (a.change ?? 0).compareTo(b.change ?? 0)
          : (b.change ?? 0).compareTo(a.change ?? 0));
    } else {
      currentList.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
    }

    marketList.value = currentList;
  }

  @override
  void onClose() {
    _disconnectWs();
    _fallbackTimer?.cancel();
    _searchTimer?.cancel();
    _renderTimer?.cancel();
    searchController.dispose();
    super.onClose();
  }

  // ── Pusher socket (kept for compatibility) ──────────────────────────────────
  @override
  void onDataGet(channel, event, data) {
    if (channel == SocketConstants.channelMarketOverviewTopCoinListData &&
        event == SocketConstants.eventMarketOverviewTopCoinList) {
      if (data is Map<String, dynamic>) {
        final details = data[APIKeyConstants.coinPairDetails];
        if (details is Map<String, dynamic>) {
          final coin = MarketCoin.fromJson(details);
          _updateCoin(coin);
        }
      }
    }
  }

  void _updateCoin(MarketCoin? coin) {
    if (coin == null || marketFullList.isEmpty) return;
    final idx = marketFullList.indexWhere(
        (e) => e.coinType == coin.coinType && e.baseCoinType == coin.baseCoinType);
    if (idx != -1) {
      coin.baseCoinType = marketFullList[idx].baseCoinType;
      marketFullList[idx] = coin;
      applyFiltersAndSort();
    }
  }

  void subscribeSocketChannels() {
    APIRepository().subscribeEvent(SocketConstants.channelMarketOverviewTopCoinListData, this);
  }

  void unSubscribeChannel() {
    APIRepository().unSubscribeEvent(SocketConstants.channelMarketOverviewTopCoinListData, this);
    _disconnectWs();
    _fallbackTimer?.cancel();
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int)    return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
