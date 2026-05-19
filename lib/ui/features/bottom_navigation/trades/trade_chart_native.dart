import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:k_chart_plus/entity/k_line_entity.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:k_chart_plus/utils/data_util.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

KLineEntity _parseCandle(dynamic raw) {
  final json = (raw is Map<String, dynamic>)
      ? raw
      : Map<String, dynamic>.from(raw as Map);

  double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  final timeVal = _i(json['time']);
  // If already ms (>= year 2001 in ms), don't multiply
  final timeMs = timeVal > 9999999999 ? timeVal : timeVal * 1000;

  return KLineEntity.fromCustom(
    time: timeMs,
    open: _d(json['open']),
    close: _d(json['close']),
    high: _d(json['high']),
    low: _d(json['low']),
    vol: _d(json['volume']),
  );
}

List<dynamic>? _extractRaw(dynamic data) {
  if (data == null) return null;
  if (data is List) return data;
  if (data is Map) {
    if (data['data'] is List) return data['data'] as List;
    if (data['candles'] is List) return data['candles'] as List;
    if (data['result'] is List) return data['result'] as List;
    if (data['klines'] is List) return data['klines'] as List;
    // Try any key whose value is a non-empty List
    for (final val in data.values) {
      if (val is List && val.isNotEmpty) return val;
    }
  }
  return null;
}

String _buildSymbol(CoinPair? pair) {
  if (pair == null) return '';
  final child = (pair.childCoinName ?? '').toUpperCase().trim();
  final parent = (pair.parentCoinName ?? '').toUpperCase().trim();
  if (child.isEmpty || parent.isEmpty) return '';
  return '$child$parent';
}

ChartColors _buildColors() {
  final c = ChartColors();
  c.bgColor = const Color(0xFF0B0B0B);
  c.upColor = const Color(0xFF2BC295);
  c.dColor = const Color(0xFFFF4747);
  c.nowPriceUpColor = const Color(0xFF2BC295);
  c.nowPriceDnColor = const Color(0xFFFF4747);
  c.gridColor = const Color(0xFF1A1A1A);
  c.defaultTextColor = const Color(0xFFD1D4DC);
  c.ma5Color = const Color(0xFFF0B90B);
  c.ma10Color = const Color(0xFF2BC295);
  c.ma30Color = const Color(0xFFFF4747);
  return c;
}
const _kIntervals = ['1m', '5m', '15m', '30m', '1h', '4h', '1d'];

// ─────────────────────────────────────────────────────────────────────────────
// NativeInlineChart
// ─────────────────────────────────────────────────────────────────────────────

class NativeInlineChart extends StatefulWidget {
  const NativeInlineChart({
    super.key,
    required this.coinPair,
    this.show = true,
    this.onDragChange,
  });

  final CoinPair? coinPair;
  final bool show;
  final ValueChanged<bool>? onDragChange;

  @override
  State<NativeInlineChart> createState() => _NativeInlineChartState();
}

class _NativeInlineChartState extends State<NativeInlineChart> {
  List<KLineEntity> _candles = [];
  bool _loading = false;
  bool _isDragging = false;
  String _debugMsg = 'Not started';
  Timer? _pollTimer;
  int _lastTime = 0;
  final String _interval = '15m';

  @override
  void initState() {
    super.initState();
    if (widget.show) _fetchData();
  }

  @override
  void didUpdateWidget(NativeInlineChart old) {
    super.didUpdateWidget(old);
    final newSym = _buildSymbol(widget.coinPair);
    final oldSym = _buildSymbol(old.coinPair);
    if (oldSym != newSym || (!old.show && widget.show)) {
      _lastTime = 0;
      _candles = [];
      _fetchData();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool replace = true}) async {
    if (!widget.show) return;
    final sym = _buildSymbol(widget.coinPair);

    if (sym.isEmpty) {
      _debugMsg =
          'Symbol empty! child=${widget.coinPair?.childCoinName} parent=${widget.coinPair?.parentCoinName}';
      if (mounted) setState(() {});
      return;
    }

    if (replace) {
      if (_loading) return;
      _loading = true;
      _debugMsg = 'Loading $sym/$_interval...';
      if (mounted) setState(() {});
    }

    try {
      final resp = await APIRepository().getSpotKlines(sym, _interval);

      //debugPrint('══ KLINES INLINE [$sym/$_interval] ══');
      ///debugPrint('  success=${resp.success}  msg=${resp.message}');
     // debugPrint('  dataType=${resp.data?.runtimeType}');
      final dataStr = resp.data.toString();
     // debugPrint('  data=${dataStr.substring(0, dataStr.length.clamp(0, 400))}');

      if (!mounted) return;

      if (!resp.success) {
        _debugMsg = 'API Error: ${resp.message}';
        if (replace) _loading = false;
        if (mounted) setState(() {});
        return;
      }

      final raw = _extractRaw(resp.data);

      if (raw == null) {
        final keys = resp.data is Map ? (resp.data as Map).keys.toList() : 'not a map';
        _debugMsg = 'Cannot parse response. Keys=$keys  type=${resp.data?.runtimeType}';
       // debugPrint('KLINES extract=null  keys=$keys  data=${resp.data}');
        if (replace) _loading = false;
        if (mounted) setState(() {});
        return;
      }

      if (raw.isEmpty) {
        _debugMsg = 'Server returned empty list for $sym/$_interval';
        if (replace) _loading = false;
        if (mounted) setState(() {});
        return;
      }

     // debugPrint('KLINES first candle: ${raw[0]}');

      final candles = raw.map(_parseCandle).toList();
      if (replace) {
        _candles = candles;
        _lastTime =
            candles.isNotEmpty ? (candles.last.time ?? 0) ~/ 1000 : 0;
        DataUtil.calcMA(_candles, const [5, 10, 20]);
        DataUtil.calcMACD(_candles);
        _debugMsg = 'OK: ${candles.length} candles';
      } else {
        _mergeCandles(candles);
      }
    } catch (e, st) {
      _debugMsg = 'Exception: $e';
    //  debugPrint('KLINES INLINE EXCEPTION: $e\n$st');
    }

    if (replace) _loading = false;
    if (mounted) setState(() {});
  }

  void _mergeCandles(List<KLineEntity> fresh) {
    final threshold = _lastTime * 1000;
    final newOnes =
        fresh.where((c) => (c.time ?? 0) >= threshold).toList();
    for (final c in newOnes) {
      final idx = _candles.indexWhere((x) => x.time == c.time);
      if (idx >= 0) {
        _candles[idx] = c;
      } else {
        _candles.add(c);
      }
    }
    if (_candles.length > 500) {
      _candles = _candles.sublist(_candles.length - 200);
    }
    if (newOnes.isNotEmpty) {
      _lastTime = (newOnes.last.time ?? 0) ~/ 1000;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show || widget.coinPair == null) return const SizedBox.shrink();

    if (_loading && _candles.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
            child: CircularProgressIndicator(color: Color(0xFF2BC295))),
      );
    }

    if (_candles.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bar_chart, color: Colors.white24, size: 40),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _debugMsg,
                  style:
                      const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _fetchData(),
                child: const Text('Retry',
                    style: TextStyle(color: Color(0xFF2BC295))),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: Get.width * 0.75,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          setState(() => _isDragging = true);
          widget.onDragChange?.call(true);
        },
        onPointerUp: (_) {
          setState(() => _isDragging = false);
          widget.onDragChange?.call(false);
        },
        onPointerCancel: (_) {
          setState(() => _isDragging = false);
          widget.onDragChange?.call(false);
        },
        child: KChartWidget(
          _candles,
          ChartStyle(),
          _buildColors(),
          isTrendLine: false,
          mainStateLi: {MainState.MA},
          volHidden: false,
          secondaryStateLi: {SecondaryState.MACD},
          fixedLength: tradeDecimal,
          xFrontPadding: 50,
          timeFormat: const [mm, '-', dd, ' ', HH, ':', nn],
          verticalTextAlignment: VerticalTextAlignment.left,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NativeFullChart
// ─────────────────────────────────────────────────────────────────────────────

class NativeFullChart extends StatefulWidget {
  const NativeFullChart({super.key, this.coinPair});

  final CoinPair? coinPair;

  @override
  State<NativeFullChart> createState() => _NativeFullChartState();
}

class _NativeFullChartState extends State<NativeFullChart> {
  List<KLineEntity> _candles = [];
  bool _loading = false;
  String _debugMsg = 'Not started';
  Timer? _pollTimer;
  int _lastTime = 0;
  int _intervalIndex = 2;
  String get _interval => _kIntervals[_intervalIndex];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startPolling();
  }

  @override
  void didUpdateWidget(NativeFullChart old) {
    super.didUpdateWidget(old);
    final newSym = _buildSymbol(widget.coinPair);
    final oldSym = _buildSymbol(old.coinPair);
    if (oldSym != newSym) {
      _lastTime = 0;
      _candles = [];
      _fetchData();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_loading) _fetchData(replace: false);
    });
  }

  Future<void> _fetchData({bool replace = true}) async {
    final sym = _buildSymbol(widget.coinPair);
   // debugPrint('🔥 KLINES REQUEST URL: ${APIURLConstants.spotBaseUrl}/v1/spot/klines/$sym?interval=$_interval&limit=200');
    if (sym.isEmpty) {
      _debugMsg =
          'Symbol empty! child=${widget.coinPair?.childCoinName} parent=${widget.coinPair?.parentCoinName}';
      if (mounted) setState(() {});
      return;
    }

    if (replace) {
      if (_loading) return;
      _loading = true;
      _debugMsg = 'Loading $sym/$_interval...';
      if (mounted) setState(() {});
    }

    try {
      final resp = await APIRepository().getSpotKlines(sym, _interval);

     // debugPrint('══ KLINES FULL [$sym/$_interval] ══');
      //debugPrint('  success=${resp.success}  msg=${resp.message}');
     // debugPrint('  dataType=${resp.data?.runtimeType}');
     
     // debugPrint('  data=${dataStr.substring(0, dataStr.length.clamp(0, 400))}');

      if (!mounted) return;

      if (!resp.success) {
        _debugMsg = 'API Error: ${resp.message}';
        if (replace) _loading = false;
        if (mounted) setState(() {});
        return;
      }

      final raw = _extractRaw(resp.data);

      if (raw == null) {
        final keys =
            resp.data is Map ? (resp.data as Map).keys.toList() : 'not a map';
        _debugMsg =
            'Cannot parse response.\nKeys=$keys\ntype=${resp.data?.runtimeType}';
       // debugPrint('KLINES extract=null  keys=$keys  data=${resp.data}');
        if (replace) _loading = false;
        if (mounted) setState(() {});
        return;
      }

      if (raw.isEmpty) {
        _debugMsg = 'Empty list for $sym/$_interval';
        if (replace) _loading = false;
        if (mounted) setState(() {});
        return;
      }

     // debugPrint('KLINES first candle: ${raw[0]}');

      final candles = raw.map(_parseCandle).toList();
      if (replace) {
        _candles = candles;
        _lastTime =
            candles.isNotEmpty ? (candles.last.time ?? 0) ~/ 1000 : 0;
        DataUtil.calcMA(_candles, const [5, 10, 20]);
        DataUtil.calcMACD(_candles);
        _debugMsg = 'OK: ${candles.length} candles';
      } else {
        _mergeCandles(candles);
      }
    } catch (e, st) {
      _debugMsg = 'Exception: $e';
    //  debugPrint('KLINES FULL EXCEPTION: $e\n$st');
    }

    if (replace) _loading = false;
    if (mounted) setState(() {});
  }

  void _mergeCandles(List<KLineEntity> fresh) {
    final threshold = _lastTime * 1000;
    final newOnes =
        fresh.where((c) => (c.time ?? 0) >= threshold).toList();
    for (final c in newOnes) {
      final idx = _candles.indexWhere((x) => x.time == c.time);
      if (idx >= 0) {
        _candles[idx] = c;
      } else {
        _candles.add(c);
      }
    }
    if (_candles.length > 500) {
      _candles = _candles.sublist(_candles.length - 200);
    }
    if (newOnes.isNotEmpty) {
      _lastTime = (newOnes.last.time ?? 0) ~/ 1000;
    }
    if (mounted) setState(() {});
  }

  void _setInterval(int idx) {
    if (idx == _intervalIndex) return;
    _intervalIndex = idx;
    _lastTime = 0;
    _candles = [];
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IntervalBar(
          intervals: _kIntervals,
          selectedIndex: _intervalIndex,
          onSelect: _setInterval,
        ),
        Expanded(child: _chartBody()),
      ],
    );
  }

  Widget _chartBody() {
    if (_loading && _candles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2BC295)),
      );
    }

    if (_candles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart, color: Colors.white24, size: 48),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _debugMsg,
                style:
                    const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _fetchData(),
              child: const Text('Retry',
                  style: TextStyle(color: Color(0xFF2BC295))),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => KChartWidget(
        _candles,
        ChartStyle(),
        _buildColors(),
        mBaseHeight: constraints.maxHeight,
        isTrendLine: false,
        mainStateLi: {MainState.MA},
        volHidden: false,
        secondaryStateLi: {SecondaryState.MACD},
        fixedLength: tradeDecimal,
        xFrontPadding: 50,
        timeFormat: const [mm, '-', dd, ' ', HH, ':', nn],
        verticalTextAlignment: VerticalTextAlignment.left,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interval bar
// ─────────────────────────────────────────────────────────────────────────────

class _IntervalBar extends StatelessWidget {
  const _IntervalBar({
    required this.intervals,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> intervals;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: intervals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF2BC295)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2BC295)
                      : Colors.white24,
                ),
              ),
              child: Text(
                intervals[i],
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white70,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}