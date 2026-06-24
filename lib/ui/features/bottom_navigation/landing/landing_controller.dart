import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../data/models/blog_news.dart';
import '../../../../data/models/coin_pair.dart';
import '../../../../data/models/settings.dart';
import '../../../../data/remote/api_repository.dart';
import '../../../../utils/common_utils.dart';
import '../../../../data/local/api_constants.dart';
import '../../../../data/remote/socket_provider.dart';
import '../../../../helper/data_process_helper.dart';

class LandingController extends GetxController implements SocketListener {
  Rx<LandingData> landingData = LandingData().obs;
  Rx<LandingList> landingList = LandingList().obs;
  RxBool isLoading = false.obs;
  RxInt selectedTab = 0.obs;
  RxList<Blog> latestBlogList = <Blog>[].obs;

  List<CoinPair> _allCoins = [];
  Timer? _wsReconnTimer;
  Timer? _fallbackTimer;
  WebSocket? _ws;
  bool _wsDisposed = false;

  @override
  void onDataGet(channel, event, data) {}

  void handleSocketChannels(bool isSubscribe) {
    isSubscribe
        ? APIRepository().subscribeEvent(SocketConstants.channelMarketCoinPairData, this)
        : APIRepository().unSubscribeEvent(SocketConstants.channelMarketCoinPairData, this);
  }

  void getLandingSettings() async {
    isLoading.value = true;
    APIRepository().getCommonSettings().then(
      (resp) {
        if (resp.success && resp.data != null && resp.data is Map<String, dynamic>) {
          DataProcessHelper.commonSettingsProcess(resp.data,
              onSettings: (s) { if (s != null) landingData.value = s; });
        }
        _loadSpotMarketCoins();
        handleSocketChannels(true);
      },
      onError: (err) {
        showToast(err.toString());
        _loadSpotMarketCoins();
      },
    );
  }

  Future<void> _loadSpotMarketCoins() async {
    // Connect WS immediately for live updates
    _wsDisposed = false;
    _connectWs();

    try {
      final resp = await http.get(
        Uri.parse('https://api.trapix.com/api/v1/spot/pairs'),
      ).timeout(const Duration(seconds: 5));

      isLoading.value = false;
      if (resp.statusCode != 200) return;

      final decoded = jsonDecode(resp.body);
      final List raw = decoded is List ? decoded
          : (decoded['data'] ?? decoded['pairs'] ?? decoded['result'] ?? decoded['markets'] ?? []);
      if (raw.isEmpty) return;

      _allCoins = raw.map<CoinPair>((p) {
        final coin = CoinPair();
        coin.childCoinName  = p['base_currency']  ?? p['base']  ?? '';
        coin.parentCoinName = p['quote_currency'] ?? p['quote'] ?? '';
        coin.lastPrice      = _dbl(p['current_price'] ?? p['last_price'] ?? p['price']);
        coin.priceChange    = _dbl(p['price_change_24h'] ?? p['price_change_percent'] ?? p['change']);
        coin.volume         = _dbl(p['volume_24h'] ?? p['volume']);
        coin.icon           = p['icon'] ?? p['logo'] ?? p['image'] ?? '';
        coin.coinPair       = '${coin.childCoinName}_${coin.parentCoinName}';
        coin.coinPairName   = '${coin.childCoinName}/${coin.parentCoinName}';
        return coin;
      }).toList();

      _rebuildLandingList(raw);
      _startFallback();
    } catch (_) {
      isLoading.value = false;
    }
  }

  void _rebuildLandingList(List raw) {
    final core = List<CoinPair>.from(_allCoins)
      ..sort((a, b) => (b.lastPrice ?? 0).compareTo(a.lastPrice ?? 0));

    final gainers = List<CoinPair>.from(_allCoins)
      ..sort((a, b) => (b.priceChange ?? 0).compareTo(a.priceChange ?? 0));

    final sorted = List.from(raw)
      ..sort((a, b) => (int.tryParse(b['id']?.toString() ?? '0') ?? 0)
          .compareTo(int.tryParse(a['id']?.toString() ?? '0') ?? 0));
    final newListings = sorted.take(8).map<CoinPair>((p) {
      final coin = CoinPair();
      coin.childCoinName  = p['base_currency']  ?? p['base']  ?? '';
      coin.parentCoinName = p['quote_currency'] ?? p['quote'] ?? 'USDT';
      coin.lastPrice      = _dbl(p['current_price'] ?? p['last_price']);
      coin.priceChange    = _dbl(p['price_change_24h'] ?? p['change']);
      coin.volume         = _dbl(p['volume_24h'] ?? p['volume']);
      coin.icon           = p['icon'] ?? p['logo'] ?? '';
      coin.coinPair       = '${coin.childCoinName}_${coin.parentCoinName}';
      coin.coinPairName   = '${coin.childCoinName}/${coin.parentCoinName}';
      return coin;
    }).toList();

    landingList.value = LandingList(
      assetCoinPairs:   core.take(8).toList(),
      hourlyCoinPairs:  gainers.take(8).toList(),
      latestCoinPairs:  newListings,
    );
  }

  // ── WebSocket for ms-level price updates ───────────────────────────────────
  Future<void> _connectWs() async {
    if (_wsDisposed) return;
    try {
      _ws = await WebSocket.connect('wss://trapix.com/ws/spot');
      _ws!.add(jsonEncode({'type': 'subscribe_all'}));
      _ws!.listen(_onWsData, onDone: _onWsDone, onError: (_) => _onWsDone(), cancelOnError: true);
    } catch (_) { _scheduleWsReconnect(); }
  }

  void _onWsData(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      if (msg['type'] != 'update') return;
      final ticker = msg['ticker'] as Map<String, dynamic>?;
      if (ticker == null || _allCoins.isEmpty) return;
      final symbol = (msg['symbol'] as String? ?? '').toUpperCase();

      final price  = _dbl(ticker['price']);
      final change = _dbl(ticker['change_24h']);
      final volume = _dbl(ticker['volume_24h']);

      final idx = _allCoins.indexWhere((c) =>
          '${c.childCoinName ?? ''}${c.parentCoinName ?? ''}'.toUpperCase() == symbol);
      if (idx == -1) return;
      if (price  > 0) _allCoins[idx].lastPrice   = price;
      _allCoins[idx].priceChange = change;
      if (volume > 0) _allCoins[idx].volume = volume;

      // Debounce re-sort to avoid rebuilding on every single tick
      _renderDebounce?.cancel();
      _renderDebounce = Timer(const Duration(milliseconds: 200), _rebuildFromCache);
    } catch (_) {}
  }

  Timer? _renderDebounce;

  void _rebuildFromCache() {
    if (_allCoins.isEmpty) return;
    final core = List<CoinPair>.from(_allCoins)
      ..sort((a, b) => (b.lastPrice ?? 0).compareTo(a.lastPrice ?? 0));
    final gainers = List<CoinPair>.from(_allCoins)
      ..sort((a, b) => (b.priceChange ?? 0).compareTo(a.priceChange ?? 0));
    landingList.value = LandingList(
      assetCoinPairs:  core.take(8).toList(),
      hourlyCoinPairs: gainers.take(8).toList(),
      latestCoinPairs: landingList.value.latestCoinPairs,
    );
  }

  void _onWsDone() { _ws = null; _scheduleWsReconnect(); }

  void _scheduleWsReconnect() {
    if (_wsDisposed) return;
    _wsReconnTimer?.cancel();
    _wsReconnTimer = Timer(const Duration(seconds: 3), _connectWs);
  }

  // ── REST fallback every 3s ─────────────────────────────────────────────────
  void _startFallback() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final resp = await http.get(Uri.parse('https://api.trapix.com/api/v1/spot/pairs'))
            .timeout(const Duration(seconds: 4));
        if (resp.statusCode != 200) return;
        final decoded = jsonDecode(resp.body);
        final List raw = decoded is List ? decoded
            : (decoded['data'] ?? decoded['pairs'] ?? decoded['markets'] ?? []);
        if (raw.isEmpty || _allCoins.isEmpty) return;
        for (final p in raw) {
          final base  = (p['base_currency'] ?? p['base'] ?? '') as String;
          final quote = (p['quote_currency'] ?? p['quote'] ?? '') as String;
          final price  = _dbl(p['current_price'] ?? p['last_price'] ?? p['price']);
          final change = _dbl(p['price_change_24h'] ?? p['price_change_percent'] ?? p['change']);
          final idx = _allCoins.indexWhere((c) => c.childCoinName == base && c.parentCoinName == quote);
          if (idx != -1) {
            if (price > 0) _allCoins[idx].lastPrice = price;
            _allCoins[idx].priceChange = change;
          }
        }
        _rebuildFromCache();
      } catch (_) {}
    });
  }

  @override
  void onClose() {
    _wsDisposed = true;
    _wsReconnTimer?.cancel();
    _fallbackTimer?.cancel();
    _renderDebounce?.cancel();
    try { _ws?.close(); } catch (_) {}
    super.onClose();
  }

  void getLatestBlogList() async {
    APIRepository().getLatestBlogList().then(
      (resp) {
        if (resp.success && resp.data != null) {
          latestBlogList.value = List<Blog>.from(resp.data.map((x) => Blog.fromJson(x)));
        }
      },
      onError: (err) => showToast(err.toString()),
    );
  }

  double _dbl(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int)    return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
