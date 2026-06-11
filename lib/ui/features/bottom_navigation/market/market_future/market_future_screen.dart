import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import '../market_spot/market_spot_controller.dart';

// Global icon cache — coin symbol → icon URL (built from spot market data)
final Map<String, String> _iconCache = {};

// ─── Design tokens (same as spot) ────────────────────────────────────────────
const _green  = Color(0xFFB5F000);
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

// Hardcoded icon URLs for commodities/stocks not on CDN
const _kStaticIcons = <String, String>{
  'XAU':   'https://trapix.com/gold-bars.png',
  'XAG':   'https://trapix.com/silver.png',
  'XPT':   'https://trapix.com/platinum.png',
  'XPD':   'https://trapix.com/palladium.png',
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
  static const _filters = ['ALL', 'USDT', 'USDC', 'BTC'];
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: textFieldSearch(
                controller: _searchCtrl,
                height: Dimens.btnHeightSmall,
                margin: 0,
                borderRadius: Dimens.radiusCornerMid,
                onTextChange: (_) {},
                bgColor: _dim,
              ),
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
                  ? Expanded(child: showEmptyView(height: 100))
                  : Expanded(
                      child: RefreshIndicator(
                        color: _green,
                        onRefresh: _fetchPairs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(5),
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
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.transparent,
      child: Row(
        children: _filters.asMap().entries.map((e) {
          final isSelected = _filterIndex == e.key;
          return GestureDetector(
            onTap: () { setState(() => _filterIndex = e.key); _applyFilter(); },
            child: Container(
              height: 35,
              color: Colors.transparent,
              margin: const EdgeInsets.only(right: 20),
              alignment: Alignment.center,
              child: Text(e.value,
                style: TextStyle(
                  fontSize: 14, fontFamily: _dm,
                  fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                  color: isSelected ? Colors.white : Colors.white54)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryList() {
    const hotCats = ['TradFi', 'Stocks', 'Indices', 'Commodity'];
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      color: Colors.transparent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final on = _catIndex == i;
          final label = _categories[i];
          final isHot = hotCats.contains(label);
          final isAI  = label == 'AI';
          return GestureDetector(
            onTap: () { setState(() => _catIndex = i); _applyFilter(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: on ? _green : _dim,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isHot) ...[
                    const Text('🔥', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 3),
                  ] else if (isAI) ...[
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(color: Color(0xFFFF8A00), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(label,
                    style: TextStyle(
                      color: on ? Colors.black : Colors.white,
                      fontSize: 13, fontWeight: on ? FontWeight.w700 : FontWeight.w500, fontFamily: _dm)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.transparent,
      child: const Row(
        children: [
          Expanded(flex: 3,
            child: Text('Pair/Vol', style: TextStyle(color: Colors.white30, fontSize: 14, fontWeight: FontWeight.w400, height: 1.6))),
          Expanded(flex: 2,
            child: Text('Price', textAlign: TextAlign.right,
                style: TextStyle(color: Colors.white30, fontSize: 14, fontWeight: FontWeight.w400, height: 1.6))),
          SizedBox(width: 20),
          Expanded(flex: 2,
            child: Text('24h Change', textAlign: TextAlign.right,
                style: TextStyle(color: Colors.white30, fontSize: 14, fontWeight: FontWeight.w400, height: 1.6))),
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
    final priceStr6  = '\$${coinFormat(pair.lastPrice, fixed: 6)}';
    final volStr     = '\$${numberFormatCompact(pair.volume, decimals: 2)}';
    final cColor     = isUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return GestureDetector(
      onTap: () {
        // Navigate to future trading page — pair details
        // Get.to(() => FuturePairDetailsScreen(symbol: pair.symbol));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        margin: const EdgeInsets.only(bottom: 5),
        color: Colors.transparent,
        child: Row(
          children: [
            hSpacer10(),

            // ── Coin icon + name + volume ──
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  // Coin icon — from spot market cache, else jsdelivr, else fallback
                  ClipOval(child: _buildIcon()),
                  hSpacer10(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Line 1: symbol + tag inline
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  text: pair.baseAsset,
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400, fontFamily: _dm),
                                  children: [
                                    TextSpan(
                                      text: '/${pair.quoteAsset}',
                                      style: const TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w400, fontFamily: _dm),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_categoryTag(pair.category) != null) ...[
                              const SizedBox(width: 4),
                              _categoryTag(pair.category)!,
                            ],
                          ],
                        ),
                        // Line 2: volume
                        Text(volStr,
                            style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w400, fontFamily: _dm),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            hSpacer5(),

            // ── Price ──
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(priceStr,
                      maxLines: 1, textAlign: TextAlign.end,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: _dm)),
                  Text(priceStr6,
                      style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w400, fontFamily: _dm),
                      maxLines: 1),
                ],
              ),
            ),

            hSpacer20(),

            // ── 24h Change badge ──
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 30,
                child: Container(
                  decoration: BoxDecoration(color: cColor, borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(changeStr,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1),
                    ),
                  ),
                ),
              ),
            ),

            hSpacer15(),
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
    String? label;
    Color? color;
    switch (category) {
      case 'stock':     label = 'Stocks';  color = const Color(0xFF2ecc8f); break;
      case 'index':     label = 'Index';   color = const Color(0xFF5aa9ff); break;
      case 'commodity':
        label = _kFullNames[pair.baseAsset.toUpperCase()] ?? 'Commodity';
        color = const Color(0xFFE0B341);
        break;
      default: return null;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(color: color!.withOpacity(0.18), borderRadius: BorderRadius.circular(3)),
      child: Text(label!, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600, fontFamily: _dm)),
    );
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

  // If spotUrl provided: try spotUrl only (no CDN fallback — spot URLs are authoritative)
  // Otherwise: atomiclabs CDN → coincap
  String _url(int attempt) {
    final s = widget.symbol.toLowerCase();
    if (widget.spotUrl != null && widget.spotUrl!.isNotEmpty) {
      if (attempt == 0) return widget.spotUrl!;
      return '';
    }
    switch (attempt) {
      case 0: return 'https://cdn.jsdelivr.net/gh/atomiclabs/cryptocurrency-icons@1a63530be6e374711a8554f31b17e4cb92c25fa/128/color/$s.png';
      case 1: return 'https://assets.coincap.io/assets/icons/$s@2x.png';
      default: return '';
    }
  }

  int get _maxAttempts => (widget.spotUrl != null && widget.spotUrl!.isNotEmpty) ? 1 : 2;

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
