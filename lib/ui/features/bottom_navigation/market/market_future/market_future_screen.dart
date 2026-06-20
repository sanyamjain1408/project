import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import '../market_spot/market_spot_controller.dart';
import '../../../root/root_controller.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import '../../trades/future_trade/future_controller.dart';

// Global icon cache — coin symbol → icon URL (built from spot market data)
final Map<String, String> _iconCache = {};

// ─── Design tokens (same as spot) ────────────────────────────────────────────
const _green  = Color(0xFFCCFF00);
const _dim    = Color(0xFF1A1A1A);
const _dm     = 'DMSans';

// ─── Model ───────────────────────────────────────────────────────────────────
class _FuturePair {
  final String symbol, baseAsset, quoteAsset, category;
  final double lastPrice, priceChangePct, volume;
  final String? icon;

  _FuturePair({
    required this.symbol, required this.baseAsset, required this.quoteAsset,
    required this.category, required this.lastPrice,
    required this.priceChangePct, required this.volume,
    this.icon,
  });

  factory _FuturePair.fromJson(Map<String, dynamic> j) {
    double toD(String k) => double.tryParse(j[k]?.toString() ?? '0') ?? 0;
    return _FuturePair(
      symbol:         j['symbol'] as String? ?? '',
      baseAsset:      j['base_currency'] as String? ?? '',
      quoteAsset:     j['quote_currency'] as String? ?? 'USDT',
      category:       (j['category'] as String? ?? 'crypto').toLowerCase(),
      lastPrice:      toD('current_price'),
      priceChangePct: toD('price_change_24h'),
      volume:         toD('volume_24h'),
      icon:           j['icon'] as String?,
    );
  }
}

// Full display names for commodities, indices, and stocks (symbol → name)
const _kFullNames = {
  // Commodities
  'XAU': 'Gold', 'XAG': 'Silver', 'XPT': 'Platinum', 'XPD': 'Palladium',
  'CL': 'Crude Oil', 'WTI': 'WTI Oil', 'NATGAS': 'Natural Gas', 'HG': 'Copper', 'COPPER': 'Copper',
  // Indices
  'US30': 'Dow Jones', 'US500': 'S&P 500', 'US100': 'Nasdaq 100', 'UK100': 'FTSE 100',
  'DE40': 'DAX 40', 'JP225': 'Nikkei 225', 'HK50': 'Hang Seng',
  // Stocks
  'TSLA': 'Tesla', 'AAPL': 'Apple', 'MSFT': 'Microsoft', 'GOOGL': 'Alphabet',
  'AMZN': 'Amazon', 'NVDA': 'Nvidia', 'META': 'Meta', 'NFLX': 'Netflix',
  'SNDK': 'SanDisk', 'COST': 'Costco', 'LLY': 'Eli Lilly', 'BABA': 'Alibaba',
  'PYPL': 'PayPal', 'INTC': 'Intel', 'AMD': 'AMD', 'UBER': 'Uber',
  'SPOT': 'Spotify', 'COIN': 'Coinbase', 'SHOP': 'Shopify', 'SQ': 'Block',
};

// Hardcoded icon URLs for commodities/stocks not on crypto CDN
const _kStaticIcons = <String, String>{
  'XAU':   'https://cdn-icons-png.flaticon.com/512/2933/2933245.png',
  'XAG':   'https://cdn-icons-png.flaticon.com/512/2933/2933116.png',
  'XPT':   'https://cdn-icons-png.flaticon.com/512/2933/2933116.png',
  'XPD':   'https://cdn-icons-png.flaticon.com/512/2933/2933116.png',
  'CL':    'https://cdn-icons-png.flaticon.com/512/3198/3198295.png',
  'WTI':   'https://cdn-icons-png.flaticon.com/512/3198/3198295.png',
  'TSLA':  'https://logo.clearbit.com/tesla.com',
  'AAPL':  'https://logo.clearbit.com/apple.com',
  'MSFT':  'https://logo.clearbit.com/microsoft.com',
  'GOOGL': 'https://logo.clearbit.com/google.com',
  'AMZN':  'https://logo.clearbit.com/amazon.com',
  'NVDA':  'https://logo.clearbit.com/nvidia.com',
  'META':  'https://logo.clearbit.com/meta.com',
  'NFLX':  'https://logo.clearbit.com/netflix.com',
  'COST':  'https://logo.clearbit.com/costco.com',
  'LLY':   'https://logo.clearbit.com/lilly.com',
  'BABA':  'https://logo.clearbit.com/alibaba.com',
  'PYPL':  'https://logo.clearbit.com/paypal.com',
  'INTC':  'https://logo.clearbit.com/intel.com',
  'AMD':   'https://logo.clearbit.com/amd.com',
  'UBER':  'https://logo.clearbit.com/uber.com',
};

// Maps category tab label → API category value(s)
const _kCatMap = {
  'ALL':       <String>[],
  'AI':        ['crypto'],  // crypto = AI on web
  'TradFi':    ['commodity', 'index'],
  'Stocks':    ['stock'],
  'Indices':   ['index'],
  'Commodity': ['commodity'],
};

// ─── Screen ───────────────────────────────────────────────────────────────────
class MarketFutureScreen extends StatefulWidget {
  const MarketFutureScreen({super.key});
  @override State<MarketFutureScreen> createState() => MarketFutureState();
}

class MarketFutureState extends State<MarketFutureScreen> {
  List<_FuturePair> _allPairs   = [];
  List<_FuturePair> _filtered   = [];
  Map<String, String> _iconMap  = {}; // coinType → icon URL from spot data
  bool _loading  = true;
  int  _filterIndex = 0;
  int  _catIndex    = 0;
  final _searchCtrl = TextEditingController();
  Timer? _timer;

  static const _apiUrl  = 'https://api.trapix.com/api/v1/future/pairs';
  static const _filters = ['ALL', 'USDT', 'USDC'];
  static const _categories = ['ALL', 'AI', 'TradFi', 'Stocks', 'Indices', 'Commodity'];

  @override
  void initState() {
    super.initState();
    _buildIconMap();
    _fetchPairs();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchPairs());
    _searchCtrl.addListener(_applyFilter);
  }

  void _buildIconMap() {
    // From spot controller cache (fast path)
    try {
      final sc = Get.find<MarketSpotController>();
      for (final coin in sc.marketFullList) {
        final type = coin.coinType?.toUpperCase() ?? '';
        final icon = coin.coinIcon ?? '';
        if (type.isNotEmpty && icon.isNotEmpty) _iconMap[type] = icon;
      }
    } catch (_) {}
    // If spot controller not loaded, fetch from spot pairs API
    if (_iconMap.isEmpty) _fetchIconsFromSpotApi();
  }

  Future<void> _fetchIconsFromSpotApi() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.trapix.com/api/v1/spot/pairs'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final pairs = (body['data'] as List? ?? []).whereType<Map<String, dynamic>>();
        for (final p in pairs) {
          final sym = (p['base_currency'] as String? ?? '').toUpperCase();
          final icon = p['icon'] as String? ?? p['base_icon'] as String? ?? p['coin_icon'] as String? ?? '';
          if (sym.isNotEmpty && icon.isNotEmpty) _iconMap[sym] = icon;
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPairs() async {
    try {
      final res = await http.get(Uri.parse(_apiUrl),
          headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final raw  = (body['data'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
        if (raw.isNotEmpty) {
          final pairs = raw.map((e) => _FuturePair.fromJson(e)).toList()
            ..sort((a, b) => b.lastPrice.compareTo(a.lastPrice));
          _buildIconMap(); // refresh icon map after spot data loads
          if (mounted) setState(() { _allPairs = pairs; _loading = false; _applyFilter(); });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    var list = List<_FuturePair>.from(_allPairs);

    // Quote filter (ALL, USDT, USDC, BTC)
    if (_filterIndex > 0) {
      final quote = _filters[_filterIndex];
      list = list.where((p) => p.quoteAsset == quote).toList();
    }

    // Category filter — match API category field
    final catLabel = _categories[_catIndex];
    if (catLabel != 'ALL') {
      final allowed = _kCatMap[catLabel] ?? [];
      if (allowed.isNotEmpty) {
        list = list.where((p) => allowed.contains(p.category)).toList();
      }
    }

    // Search filter
    if (q.isNotEmpty) {
      list = list.where((p) =>
          p.symbol.toLowerCase().contains(q) ||
          p.baseAsset.toLowerCase().contains(q)).toList();
    }

    setState(() => _filtered = list);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter tabs — All / Spot / Futures (same as spot screen)
          _buildFilterTabs(),

          // Category pills
          _buildCategoryList(),

          const SizedBox(height: 10),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: textFieldSearch(
              controller: _searchCtrl,
              height: 30,
              margin: 0,
              borderRadius: 10,
              onTextChange: (_) {},
              bgColor: _dim,
            ),
          ),

          const SizedBox(height: 10),

          // Header row (same as spot)
          _buildHeaderRow(),

          const SizedBox(height: 7),

          // List
          _loading
              ? const Expanded(child: Center(child: CircularProgressIndicator(color: _green, strokeWidth: 2)))
              : _filtered.isEmpty
                  ? Expanded(
                      child: _filters[_filterIndex] == 'USDC'
                          ? const Center(
                              child: Text(
                                'Coming Soon',
                                style: TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'DMSans'),
                              ),
                            )
                          : showEmptyView(height: 100),
                    )
                  : Expanded(
                      child: RefreshIndicator(
                        color: _green,
                        onRefresh: _fetchPairs,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _FuturePairItem(pair: _filtered[i], iconMap: _iconMap),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.transparent,
      child: Row(
        children: _filters.asMap().entries.map((e) {
          final isSelected = _filterIndex == e.key;
          return GestureDetector(
            onTap: () { setState(() => _filterIndex = e.key); _applyFilter(); },
            child: Container(
              height: 40,
              color: Colors.transparent,
              margin: const EdgeInsets.only(right: 20),
              alignment: Alignment.center,
              child: Text(e.value,
                style: TextStyle(
                  fontSize: 15, fontFamily: _dm,
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5))),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryList() {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      color: Colors.transparent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = _catIndex == i;
          final label = _categories[i];
          return GestureDetector(
            onTap: () { setState(() => _catIndex = i); _applyFilter(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: on ? const Color(0xFFCCFF00) : _dim,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(label,
                style: TextStyle(
                  color: on ? Colors.black : Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w400, fontFamily: _dm, height: 1.33)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text('Pair/Vol',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: _dm, height: 1.33))),
          SizedBox(
            width: 90,
            child: Text('Price', textAlign: TextAlign.end,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: _dm, height: 1.33))),
          const SizedBox(width: 18),
          SizedBox(
            width: 83,
            child: Text('24h Change', textAlign: TextAlign.end,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: _dm, height: 1.33))),
        ],
      ),
    );
  }
}

// ─── Pair item (same layout as spot MarketCoinItemViewBottom) ─────────────────
class _FuturePairItem extends StatelessWidget {
  const _FuturePairItem({required this.pair, required this.iconMap});
  final _FuturePair pair;
  final Map<String, String> iconMap;

  @override
  Widget build(BuildContext context) {
    final isUp       = pair.priceChangePct >= 0;
    final changeStr  = '${isUp ? '+' : ''}${pair.priceChangePct.toStringAsFixed(2)}%';
    final priceStr   = coinFormat(pair.lastPrice);
    final volStr     = '\$${numberFormatCompact(pair.volume, decimals: 2)}';
    final cColor     = isUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return GestureDetector(
      onTap: () {
        if (Get.isRegistered<NewFutureController>()) {
          final ctrl = Get.find<NewFutureController>();
          final match = ctrl.pairs.firstWhereOrNull((p) => p.symbol == pair.symbol);
          if (match != null) {
            ctrl.selectPair(match);
          } else {
            // Pairs still loading — store as pending
            TemporaryData.pendingFutureSymbol = pair.symbol;
          }
        } else {
          TemporaryData.pendingFutureSymbol = pair.symbol;
        }
        Get.find<RootController>().changeBottomNavIndex(AppBottomNavKey.future);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon + name + volume
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipOval(child: _buildIcon()),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  text: pair.baseAsset,
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400, fontFamily: _dm, height: 1.25),
                                  children: [
                                    TextSpan(
                                      text: '/${pair.quoteAsset}',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15, fontWeight: FontWeight.w400, fontFamily: _dm, height: 1.25),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_categoryTag(pair.category) != null) ...[
                              const SizedBox(width: 4),
                              _categoryTag(pair.category)!,
                            ],
                          ],
                        ),
                        Text(volStr,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: _dm, height: 1.33),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Price — fixed 90px right-aligned
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(priceStr,
                    textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: _dm, height: 1.25)),
                  Text('\$$priceStr',
                    textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: _dm, height: 1.33)),
                ],
              ),
            ),

            const SizedBox(width: 18),

            // Change badge — fixed 83px
            SizedBox(
              width: 83,
              height: 30,
              child: Container(
                decoration: BoxDecoration(color: cColor, borderRadius: BorderRadius.circular(5)),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(changeStr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: _dm, height: 1.33),
                      maxLines: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    // Priority: pair's own icon → static hardcoded → spot map → CDN fallback
    final sym = pair.baseAsset.toUpperCase();
    final ownIcon = pair.icon != null && pair.icon!.isNotEmpty ? pair.icon : null;
    final spotUrl = ownIcon ?? _kStaticIcons[sym] ?? iconMap[sym];
    return _CoinIcon(
      symbol: pair.baseAsset.toLowerCase(),
      fallback: pair.baseAsset,
      spotUrl: spotUrl,
    );
  }

  Widget? _categoryTag(String category) {
    switch (category) {
      case 'commodity':
        final label = _kFullNames[pair.baseAsset.toUpperCase()] ?? 'Commodity';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: const Color(0x4CFFD800), borderRadius: BorderRadius.circular(4)),
          child: Text(label, style: const TextStyle(color: Color(0xFFFFD900), fontSize: 8, fontWeight: FontWeight.w400, fontFamily: _dm)),
        );
      case 'stock':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: const Color(0x332ecc8f), borderRadius: BorderRadius.circular(4)),
          child: const Text('Stock', style: TextStyle(color: Color(0xFF2ecc8f), fontSize: 8, fontWeight: FontWeight.w400, fontFamily: _dm)),
        );
      case 'index':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: const Color(0x335aa9ff), borderRadius: BorderRadius.circular(4)),
          child: const Text('Index', style: TextStyle(color: Color(0xFF5aa9ff), fontSize: 8, fontWeight: FontWeight.w400, fontFamily: _dm)),
        );
      default: return null;
    }
  }

}

// ─── Coin icon with dual CDN fallback (same as FutureCoinIcon in future_widgets) ─
class _CoinIcon extends StatefulWidget {
  const _CoinIcon({required this.symbol, required this.fallback, this.spotUrl});
  final String symbol;
  final String fallback;
  final String? spotUrl;
  @override State<_CoinIcon> createState() => _CoinIconState();
}

class _CoinIconState extends State<_CoinIcon> {
  int _attempt = 0;

  // Priority: spotUrl → atomiclabs CDN → coincap → fallback letters
  String _url(int attempt) {
    final s = widget.symbol.toLowerCase();
    final hasSpot = widget.spotUrl != null && widget.spotUrl!.isNotEmpty;
    if (hasSpot) {
      switch (attempt) {
        case 0: return widget.spotUrl!;
        case 1: return 'https://assets.coincap.io/assets/icons/$s@2x.png';
        default: return '';
      }
    }
    switch (attempt) {
      case 0: return 'https://cdn.jsdelivr.net/gh/atomiclabs/cryptocurrency-icons@1a63530be6e374711a8554f31b17e4cb92c25fa/128/color/$s.png';
      case 1: return 'https://assets.coincap.io/assets/icons/$s@2x.png';
      default: return '';
    }
  }

  int get _maxAttempts => 2;

  @override
  Widget build(BuildContext context) {
    if (_attempt >= _maxAttempts) return _fallback();
    return Image.network(
      _url(_attempt),
      width: 30, height: 30, fit: BoxFit.cover,
      errorBuilder: (context, error, stack) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _attempt++);
        });
        return _fallback();
      },
    );
  }

  Widget _fallback() => Container(
    width: 30, height: 30,
    decoration: const BoxDecoration(color: _dim, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Text(
      widget.fallback.isNotEmpty ? widget.fallback.substring(0, widget.fallback.length >= 2 ? 2 : 1).toUpperCase() : '?',
      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}
