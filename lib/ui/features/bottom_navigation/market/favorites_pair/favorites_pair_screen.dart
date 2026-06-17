import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/api_constants.dart' show APIURLConstants;
import 'package:tradexpro_flutter/data/models/market_date.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import '../market_spot/market_spot_controller.dart';
import '../market_spot/market_spot_widgets.dart' as spot;
import 'favorites_pair_controller.dart';

const _green = Color(0xFFCCFF00);

// ── Storage helpers ───────────────────────────────────────────────────────────

const _kSpotFavKey = 'trapix_spot_favorites_v3';
const _kFutFavKey = 'trapix_fut_favorites_v3';

// Each stored item: {favoriteKey, coinType, baseCoinType, pairName, coinIcon, marketType}
List<Map<String, dynamic>> _readFavs(int marketType) {
  final key = marketType == 3 ? _kFutFavKey : _kSpotFavKey;
  try {
    final raw = GetStorage().read<String>(key);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  } catch (_) {
    return [];
  }
}

void _writeFavs(int marketType, List<Map<String, dynamic>> items) {
  final key = marketType == 3 ? _kFutFavKey : _kSpotFavKey;
  GetStorage().write(key, jsonEncode(items));
}

String _favKey(int marketType, String coinType, String baseCoinType) =>
    '$marketType:${coinType.toUpperCase()}${baseCoinType.toUpperCase()}';

// ─────────────────────────────────────────────────────────────────────────────

class FavoritesPairScreen extends StatefulWidget {
  const FavoritesPairScreen({super.key});

  @override
  FavoritesPairScreenState createState() => FavoritesPairScreenState();
}

class FavoritesPairScreenState extends State<FavoritesPairScreen> {
  final _controller = Get.put(FavoritesPairController());

  // All favorites (unfiltered, from storage)
  List<Map<String, dynamic>> _allSpotFavs = [];
  List<Map<String, dynamic>> _allFutFavs = [];

  // Filtered display list
  List<Map<String, dynamic>> _displayList = [];

  int _filterIndex = 0;
  int _categoryIndex = 0;
  final _searchCtrl = TextEditingController();
  Timer? _searchTimer;
  Timer? _priceTimer;

  static const _filterList = ['ALL', 'USDT', 'USDC'];
  static const _categoryList = ['All', '🔥 AI', 'Meme', 'RWA', 'DeFi', 'NFT', 'L1', 'L2'];
  static const _categoryCoins = <String, List<String>>{
    '🔥 AI': ['FET', 'AGIX', 'OCEAN', 'GRT', 'TAO', 'RNDR', 'WLD', 'NEAR', 'ICP', 'AKT'],
    'Meme': ['DOGE', 'SHIB', 'PEPE', 'FLOKI', 'BONK', 'WIF', 'MEME', 'BOME', 'NEIRO', 'COQ'],
    'RWA': ['ONDO', 'MKR', 'SNX', 'RIO', 'CPOOL', 'MPL', 'TRU', 'POLYX'],
    'DeFi': ['UNI', 'AAVE', 'COMP', 'CRV', 'SUSHI', 'YFI', 'BAL', '1INCH', 'SNX', 'LDO'],
    'NFT': ['APE', 'SAND', 'MANA', 'AXS', 'GALA', 'ILV', 'CHZ', 'SUPER', 'ALICE'],
    'L1': ['BTC', 'ETH', 'SOL', 'AVAX', 'ADA', 'DOT', 'ATOM', 'NEAR', 'FTM', 'SUI'],
    'L2': ['MATIC', 'ARB', 'OP', 'IMX', 'ZK', 'METIS', 'BOBA', 'SKL', 'STRK', 'MANTA'],
  };

  @override
  void initState() {
    super.initState();
    _loadFavoritesFromStorage();
    _startPriceRefresh();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _priceTimer?.cancel();
    _searchCtrl.dispose();
    _controller.unSubscribeChannel();
    Get.delete<FavoritesPairController>(force: true);
    super.dispose();
  }

  void _loadFavoritesFromStorage() {
    _allSpotFavs = _readFavs(2);
    _allFutFavs = _readFavs(3);
    _applyFilters();
  }

  List<Map<String, dynamic>> get _allFavs => [..._allSpotFavs, ..._allFutFavs];

  void _applyFilters() {
    List<Map<String, dynamic>> list = List.from(_allFavs);

    if (_filterIndex > 0) {
      final cur = _filterList[_filterIndex];
      list = list.where((p) => (p['baseCoinType'] as String? ?? '').toUpperCase() == cur).toList();
    }

    if (_categoryIndex > 0) {
      final cat = _categoryList[_categoryIndex];
      final coins = _categoryCoins[cat];
      if (coins != null) {
        list = list.where((p) => coins.contains((p['coinType'] as String? ?? '').toUpperCase())).toList();
      }
    }

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) {
        final name = '${p['coinType'] ?? ''}${p['baseCoinType'] ?? ''}'.toLowerCase();
        return name.contains(q);
      }).toList();
    }

    if (mounted) setState(() => _displayList = list);
  }

  // ── Price refresh every 5s ────────────────────────────────────────────────

  void _startPriceRefresh() {
    _priceTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshPrices());
    _refreshPrices();
  }

  Future<void> _refreshPrices() async {
    if (_allFavs.isEmpty) return;
    try {
      // Build icon cache from MarketSpotController if available
      Map<String, String> iconCache = {};
      try {
        final spotCtrl = Get.find<MarketSpotController>();
        for (final mc in spotCtrl.marketFullList) {
          final k = '${mc.coinType ?? ''}${mc.baseCoinType ?? ''}'.toUpperCase();
          if (mc.coinIcon != null && mc.coinIcon!.isNotEmpty) iconCache[k] = mc.coinIcon!;
        }
      } catch (_) {}

      // Fetch spot prices
      final spotResp = await http
          .get(Uri.parse('${APIURLConstants.baseUrl}/api/v1/spot/pairs'))
          .timeout(const Duration(seconds: 8));
      if (spotResp.statusCode == 200) {
        final body = jsonDecode(spotResp.body);
        final pairs = (body['data'] as List<dynamic>?) ?? [];
        final priceMap = <String, Map<String, dynamic>>{};
        for (final p in pairs) {
          final k = '${p['base_currency'] ?? p['coinType'] ?? ''}${p['quote_currency'] ?? p['baseCoinType'] ?? ''}'.toUpperCase();
          priceMap[k] = p as Map<String, dynamic>;
          // Also store icon
          final icon = p['icon'] ?? p['coin_icon'] ?? p['base_icon'] ?? p['parent_icon'];
          if (icon != null && (icon as String).isNotEmpty) iconCache[k] = icon;
        }
        bool changed = false;
        for (int i = 0; i < _allSpotFavs.length; i++) {
          final fav = _allSpotFavs[i];
          final k = '${fav['coinType']}${fav['baseCoinType']}'.toUpperCase();
          final src = priceMap[k];
          if (src != null) {
            _allSpotFavs[i] = Map.from(fav)
              ..['price'] = (src['current_price'] ?? src['last_price'] ?? src['price'] ?? fav['price'])
              ..['change'] = (src['price_change_24h'] ?? src['change_24h'] ?? src['price_change'] ?? fav['change'])
              ..['volume'] = (src['volume_24h'] ?? src['volume'] ?? fav['volume']);
            changed = true;
          }
          // Update icon if we now have one
          if ((fav['coinIcon'] as String? ?? '').isEmpty && iconCache.containsKey(k)) {
            _allSpotFavs[i] = Map.from(_allSpotFavs[i])..['coinIcon'] = iconCache[k];
            _writeFavs(2, _allSpotFavs);
            changed = true;
          }
        }
        if (changed) _writeFavs(2, _allSpotFavs);
      }

      // Fetch future prices
      final futResp = await http
          .get(Uri.parse('${APIURLConstants.baseUrl}/api/v1/future/pairs'))
          .timeout(const Duration(seconds: 8));
      if (futResp.statusCode == 200) {
        final body = jsonDecode(futResp.body);
        final pairs = (body['data'] as List<dynamic>?) ?? [];
        final priceMap = <String, Map<String, dynamic>>{};
        for (final p in pairs) {
          final k = '${p['base_currency'] ?? p['coinType'] ?? ''}${p['quote_currency'] ?? p['baseCoinType'] ?? 'USDT'}'.toUpperCase();
          priceMap[k] = p as Map<String, dynamic>;
          final icon = p['icon'] ?? p['coin_icon'] ?? p['base_icon'];
          if (icon != null && (icon as String).isNotEmpty) iconCache[k] = icon;
        }
        bool changed = false;
        for (int i = 0; i < _allFutFavs.length; i++) {
          final fav = _allFutFavs[i];
          final k = '${fav['coinType']}${fav['baseCoinType']}'.toUpperCase();
          final src = priceMap[k];
          if (src != null) {
            _allFutFavs[i] = Map.from(fav)
              ..['price'] = (src['current_price'] ?? src['last_price'] ?? src['price'] ?? fav['price'])
              ..['change'] = (src['price_change_24h'] ?? src['change_24h'] ?? src['price_change'] ?? fav['change'])
              ..['volume'] = (src['volume_24h'] ?? src['volume'] ?? fav['volume']);
            changed = true;
          }
          if ((fav['coinIcon'] as String? ?? '').isEmpty && iconCache.containsKey(k)) {
            _allFutFavs[i] = Map.from(_allFutFavs[i])..['coinIcon'] = iconCache[k];
            _writeFavs(3, _allFutFavs);
            changed = true;
          }
        }
        if (changed) _writeFavs(3, _allFutFavs);
      }
    } catch (_) {}
    if (mounted) _applyFilters();
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterTabBar(),
          _buildCategoryList(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: textFieldSearch(
              controller: _searchCtrl,
              height: 30,
              margin: 0,
              borderRadius: 10,
              onTextChange: (v) {
                _searchTimer?.cancel();
                _searchTimer = Timer(const Duration(milliseconds: 400), _applyFilters);
              },
              bgColor: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          _buildAddCoinButton(context),
          const SizedBox(height: 8),
          const _MarketHeaderRow(),
          const SizedBox(height: 7),
          _displayList.isEmpty
              ? _filterList[_filterIndex] == 'USDC'
                  ? const SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Coming Soon',
                          style: TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'DMSans'),
                        ),
                      ),
                    )
                  : showEmptyView(height: 100)
              : Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _displayList.length,
                    itemBuilder: (context, index) {
                      final fav = _displayList[index];
                      return spot.MarketCoinItemViewBottom(
                        coin: _favToMarketCoin(fav),
                        showPerp: (fav['marketType'] as int? ?? 2) == 3,
                        onFavChange: (message) {
                          // Remove from favorites when star tapped on main screen
                          final coinType = fav['coinType'] as String? ?? '';
                          final baseCoinType = fav['baseCoinType'] as String? ?? '';
                          final marketType = fav['marketType'] as int? ?? 2;
                          final fk = _favKey(marketType, coinType, baseCoinType);
                          if (marketType == 3) {
                            _allFutFavs.removeWhere((e) => e['favoriteKey'] == fk);
                            _writeFavs(3, _allFutFavs);
                          } else {
                            _allSpotFavs.removeWhere((e) => e['favoriteKey'] == fk);
                            _writeFavs(2, _allSpotFavs);
                          }
                          _applyFilters();
                          if (message != null) showToast(message, isError: false);
                        },
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFilterTabBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.transparent,
      child: Row(
        children: _filterList.asMap().entries.map((entry) {
          final i = entry.key;
          final isSelected = _filterIndex == i;
          return GestureDetector(
            onTap: () { setState(() => _filterIndex = i); _applyFilters(); },
            child: Container(
              height: 40,
              color: Colors.transparent,
              margin: const EdgeInsets.only(right: 20),
              alignment: Alignment.center,
              child: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: "DMSans",
                  fontWeight: isSelected ? FontWeight.w400 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  height: 1.33,
                ),
              ),
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
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categoryList.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isSelected = _categoryIndex == i;
          return GestureDetector(
            onTap: () { setState(() => _categoryIndex = i); _applyFilters(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFCCFF00) : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                _categoryList[i],
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: "DMSans",
                  height: 1.33,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddCoinButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCCFF00),
            foregroundColor: const Color(0xFF111111),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          onPressed: () => _openAddCoinDrawer(context),
          child: const Text(
            "Add Coin",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: "DMSans", height: 1.25),
          ),
        ),
      ),
    );
  }

  void _openAddCoinDrawer(BuildContext context) {
    // Build initial pending set from current stored favorites
    final pendingSpot = Set<String>.from(_allSpotFavs.map((e) => e['favoriteKey'] as String? ?? ''));
    final pendingFut = Set<String>.from(_allFutFavs.map((e) => e['favoriteKey'] as String? ?? ''));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCoinDrawer(
        initialPendingSpot: pendingSpot,
        initialPendingFut: pendingFut,
        onApply: (updatedSpot, updatedFut) {
          // Apply is called when "Add Coin" is tapped in drawer
          // updatedSpot / updatedFut are the new full saved lists
          _allSpotFavs = updatedSpot;
          _allFutFavs = updatedFut;
          _writeFavs(2, _allSpotFavs);
          _writeFavs(3, _allFutFavs);
          _applyFilters();
        },
      ),
    );
  }
}

// ── Add Coin Drawer ───────────────────────────────────────────────────────────

class _AddCoinDrawer extends StatefulWidget {
  const _AddCoinDrawer({
    required this.initialPendingSpot,
    required this.initialPendingFut,
    required this.onApply,
  });

  final Set<String> initialPendingSpot;
  final Set<String> initialPendingFut;
  // Called with (newSpotList, newFutList) when "Add Coin" is tapped
  final void Function(List<Map<String, dynamic>>, List<Map<String, dynamic>>) onApply;

  @override
  State<_AddCoinDrawer> createState() => _AddCoinDrawerState();
}

class _AddCoinDrawerState extends State<_AddCoinDrawer> {
  int _tabIndex = 0; // 0=Spot, 1=Future
  int _filterIndex = 0;
  String _query = '';
  final _searchCtrl = TextEditingController();

  // All available pairs (fetched from API)
  List<Map<String, dynamic>> _spotPairs = [];
  List<Map<String, dynamic>> _futPairs = [];
  bool _loading = true;

  // Pending selections (keys like "2:BTCUSDT")
  late Set<String> _pendingSpot;
  late Set<String> _pendingFut;

  // Full info for pending items (to save on apply)
  // key → {favoriteKey, coinType, baseCoinType, pairName, coinIcon, marketType}
  final Map<String, Map<String, dynamic>> _pendingSpotInfo = {};
  final Map<String, Map<String, dynamic>> _pendingFutInfo = {};

  static const _filterList = ['ALL', 'USDT', 'USDC'];

  @override
  void initState() {
    super.initState();
    _pendingSpot = Set.from(widget.initialPendingSpot);
    _pendingFut = Set.from(widget.initialPendingFut);

    // Pre-populate info maps from stored data
    for (final fav in _readFavs(2)) {
      final fk = fav['favoriteKey'] as String? ?? '';
      if (fk.isNotEmpty) _pendingSpotInfo[fk] = fav;
    }
    for (final fav in _readFavs(3)) {
      final fk = fav['favoriteKey'] as String? ?? '';
      if (fk.isNotEmpty) _pendingFutInfo[fk] = fav;
    }

    _fetchPairs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPairs() async {
    // First populate from MarketSpotController cache (instant)
    try {
      final spotCtrl = Get.find<MarketSpotController>();
      _spotPairs = spotCtrl.marketFullList.map((mc) {
        final coinType = mc.coinType ?? '';
        final baseCoinType = mc.baseCoinType ?? '';
        final fk = _favKey(2, coinType, baseCoinType);
        // Update pending info if not already there
        if (_pendingSpot.contains(fk) && !_pendingSpotInfo.containsKey(fk)) {
          _pendingSpotInfo[fk] = {
            'favoriteKey': fk,
            'coinType': coinType,
            'baseCoinType': baseCoinType,
            'pairName': '$coinType/$baseCoinType',
            'coinIcon': mc.coinIcon ?? '',
            'marketType': 2,
          };
        }
        return {
          'favoriteKey': fk,
          'coinType': coinType,
          'baseCoinType': baseCoinType,
          'pairName': '$coinType/$baseCoinType',
          'coinIcon': mc.coinIcon ?? '',
          'marketType': 2,
          'price': mc.price,
          'change': mc.change,
        };
      }).toList();
    } catch (_) {}

    if (mounted) setState(() => _loading = _spotPairs.isEmpty);

    // Then fetch from API for accurate icons + future pairs
    try {
      final spotResp = await http
          .get(Uri.parse('${APIURLConstants.baseUrl}/api/v1/spot/pairs'))
          .timeout(const Duration(seconds: 10));
      if (spotResp.statusCode == 200) {
        final body = jsonDecode(spotResp.body);
        final pairs = (body['data'] as List<dynamic>?) ?? [];
        _spotPairs = pairs.map((p) {
          final coinType = (p['base_currency'] ?? p['coinType'] ?? '') as String;
          final baseCoinType = (p['quote_currency'] ?? p['baseCoinType'] ?? '') as String;
          final fk = _favKey(2, coinType, baseCoinType);
          final icon = (p['icon'] ?? p['coin_icon'] ?? p['base_icon'] ?? p['parent_icon'] ?? '') as String;
          if (_pendingSpot.contains(fk)) {
            _pendingSpotInfo[fk] = {
              'favoriteKey': fk,
              'coinType': coinType,
              'baseCoinType': baseCoinType,
              'pairName': '$coinType/$baseCoinType',
              'coinIcon': icon,
              'marketType': 2,
            };
          }
          return {
            'favoriteKey': fk,
            'coinType': coinType,
            'baseCoinType': baseCoinType,
            'pairName': '$coinType/$baseCoinType',
            'coinIcon': icon,
            'marketType': 2,
            'price': p['current_price'] ?? p['last_price'] ?? p['price'] ?? 0,
            'change': p['price_change_24h'] ?? p['change_24h'] ?? p['price_change'] ?? 0,
          };
        }).toList();
      }
    } catch (_) {}

    try {
      final futResp = await http
          .get(Uri.parse('${APIURLConstants.baseUrl}/api/v1/future/pairs'))
          .timeout(const Duration(seconds: 10));
      if (futResp.statusCode == 200) {
        final body = jsonDecode(futResp.body);
        final pairs = (body['data'] as List<dynamic>?) ?? [];
        _futPairs = pairs.map((p) {
          final coinType = (p['base_currency'] ?? p['coinType'] ?? '') as String;
          final baseCoinType = (p['quote_currency'] ?? p['baseCoinType'] ?? 'USDT') as String;
          final fk = _favKey(3, coinType, baseCoinType);
          final icon = (p['icon'] ?? p['coin_icon'] ?? p['base_icon'] ?? '') as String;
          if (_pendingFut.contains(fk)) {
            _pendingFutInfo[fk] = {
              'favoriteKey': fk,
              'coinType': coinType,
              'baseCoinType': baseCoinType,
              'pairName': '$coinType/$baseCoinType',
              'coinIcon': icon,
              'marketType': 3,
            };
          }
          return {
            'favoriteKey': fk,
            'coinType': coinType,
            'baseCoinType': baseCoinType,
            'pairName': '$coinType/$baseCoinType',
            'coinIcon': icon,
            'marketType': 3,
            'price': p['current_price'] ?? p['last_price'] ?? p['price'] ?? 0,
            'change': p['price_change_24h'] ?? p['change_24h'] ?? p['price_change'] ?? 0,
          };
        }).toList();
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _activePairs => _tabIndex == 0 ? _spotPairs : _futPairs;
  Set<String> get _activePending => _tabIndex == 0 ? _pendingSpot : _pendingFut;

  List<Map<String, dynamic>> get _filtered {
    List<Map<String, dynamic>> list = _activePairs;
    if (_filterIndex > 0) {
      final cur = _filterList[_filterIndex];
      list = list.where((p) => (p['baseCoinType'] as String? ?? '').toUpperCase() == cur).toList();
    }
    if (_query.isNotEmpty) {
      list = list.where((p) {
        final name = '${p['coinType'] ?? ''}${p['baseCoinType'] ?? ''}'.toLowerCase();
        return name.contains(_query);
      }).toList();
    }
    return list;
  }

  // Website pattern: toggle adds/removes from PENDING set only
  // Changes are committed when "Add Coin" is tapped
  void _togglePending(Map<String, dynamic> pair) {
    final fk = pair['favoriteKey'] as String;
    if (_tabIndex == 0) {
      setState(() {
        if (_pendingSpot.contains(fk)) {
          _pendingSpot.remove(fk);
          _pendingSpotInfo.remove(fk);
        } else {
          _pendingSpot.add(fk);
          _pendingSpotInfo[fk] = {
            'favoriteKey': fk,
            'coinType': pair['coinType'],
            'baseCoinType': pair['baseCoinType'],
            'pairName': pair['pairName'],
            'coinIcon': pair['coinIcon'] ?? '',
            'marketType': 2,
            'price': pair['price'] ?? 0,
            'change': pair['change'] ?? 0,
            'volume': pair['volume'] ?? 0,
          };
        }
      });
    } else {
      setState(() {
        if (_pendingFut.contains(fk)) {
          _pendingFut.remove(fk);
          _pendingFutInfo.remove(fk);
        } else {
          _pendingFut.add(fk);
          _pendingFutInfo[fk] = {
            'favoriteKey': fk,
            'coinType': pair['coinType'],
            'baseCoinType': pair['baseCoinType'],
            'pairName': pair['pairName'],
            'coinIcon': pair['coinIcon'] ?? '',
            'marketType': 3,
            'price': pair['price'] ?? 0,
            'change': pair['change'] ?? 0,
            'volume': pair['volume'] ?? 0,
          };
        }
      });
    }
  }

  void _onAddCoin() {
    // Commit pending selections to storage
    final newSpotList = _pendingSpot.map((fk) {
      return _pendingSpotInfo[fk] ?? {
        'favoriteKey': fk,
        'coinType': '',
        'baseCoinType': '',
        'pairName': '',
        'coinIcon': '',
        'marketType': 2,
      };
    }).where((e) => (e['coinType'] as String? ?? '').isNotEmpty).toList();

    final newFutList = _pendingFut.map((fk) {
      return _pendingFutInfo[fk] ?? {
        'favoriteKey': fk,
        'coinType': '',
        'baseCoinType': '',
        'pairName': '',
        'coinIcon': '',
        'marketType': 3,
      };
    }).where((e) => (e['coinType'] as String? ?? '').isNotEmpty).toList();

    widget.onApply(newSpotList, newFutList);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pairs = _filtered;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Search + close row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: textFieldSearch(
                    controller: _searchCtrl,
                    height: Dimens.btnHeightSmall,
                    margin: 0,
                    borderRadius: Dimens.radiusCornerMid,
                    onTextChange: (v) => setState(() => _query = v.trim().toLowerCase()),
                    bgColor: const Color(0xFF1A1A1A),
                    iconColor: _green,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Spot / Future tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _TabLabel(
                  label: "Spot",
                  selected: _tabIndex == 0,
                  onTap: () => setState(() {
                    _tabIndex = 0;
                    _filterIndex = 0;
                    _query = '';
                    _searchCtrl.clear();
                  }),
                ),
                const SizedBox(width: 20),
                _TabLabel(
                  label: "Future",
                  selected: _tabIndex == 1,
                  onTap: () => setState(() {
                    _tabIndex = 1;
                    _filterIndex = 0;
                    _query = '';
                    _searchCtrl.clear();
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ALL / USDT / USDC / BTC filter
          SizedBox(
            height: 28,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filterList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (_, i) {
                final sel = _filterIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _filterIndex = i),
                  child: Text(
                    _filterList[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: "DMSans",
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w300,
                      color: sel ? Colors.white : Colors.white54,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Coin list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _green))
                : pairs.isEmpty
                    ? const Center(
                        child: Text(
                          "No pairs found",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: pairs.length,
                        itemBuilder: (_, i) {
                          final pair = pairs[i];
                          final fk = pair['favoriteKey'] as String;
                          final isSelected = _activePending.contains(fk);
                          return InkWell(
                            onTap: () => _togglePending(pair),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  // Star icon — green filled = selected, outline = not
                                  Icon(
                                    isSelected ? Icons.star : Icons.star_border,
                                    color: isSelected ? _green : Colors.white54,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  // Coin icon
                                  _CoinAvatar(
                                    icon: pair['coinIcon'] as String?,
                                    symbol: pair['coinType'] as String? ?? '',
                                  ),
                                  const SizedBox(width: 10),
                                  // Pair name
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          text: pair['coinType'] as String? ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: "DMSans",
                                          ),
                                          children: [
                                            TextSpan(
                                              text: '/${pair['baseCoinType'] ?? ''}',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w300,
                                                fontFamily: "DMSans",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        pair['coinType'] as String? ?? '',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                          fontFamily: "DMSans",
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Add Coin button — applies pending changes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: _onAddCoin,
                child: const Text(
                  "Add Coin",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: "DMSans"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontFamily: "DMSans",
          fontWeight: selected ? FontWeight.w700 : FontWeight.w300,
          color: selected ? Colors.white : Colors.white54,
        ),
      ),
    );
  }
}

class _CoinAvatar extends StatelessWidget {
  const _CoinAvatar({required this.icon, required this.symbol});
  final String? icon;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final hasIcon = icon != null && icon!.isNotEmpty;
    return ClipOval(
      child: hasIcon
          ? Image.network(
              icon!,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() => Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: Color(0xFF2A2A2A), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          symbol.isNotEmpty ? symbol[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
}

// CoinPair-based favorite → MarketCoin for the existing list widget
MarketCoin _favToMarketCoin(Map<String, dynamic> fav) {
  return MarketCoin(
    coinType: fav['coinType'] as String?,
    baseCoinType: fav['baseCoinType'] as String?,
    coinIcon: fav['coinIcon'] as String?,
    price: (fav['price'] as num?)?.toDouble(),
    change: (fav['change'] as num?)?.toDouble(),
    volume: (fav['volume'] as num?)?.toDouble(),
  );
}

class _MarketHeaderRow extends StatelessWidget {
  const _MarketHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Pair/Vol",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: "DMSans",
                height: 1.33,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              "Price",
              textAlign: TextAlign.end,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: "DMSans",
                height: 1.33,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 83,
            child: Text(
              "24h Change",
              textAlign: TextAlign.end,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: "DMSans",
                height: 1.33,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
