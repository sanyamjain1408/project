import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/trades/future_trade/future_models.dart';

// ── Design Tokens (Figma exact) ───────────────────────────────────────────────
const _bg = Color(0xFF111111);
const _card = Color(0xFF1A1A1A);
const _cardInner = Color(0xFF111111);
const _white = Color(0xFFFFFFFF);
const _w50 = Color(0x80FFFFFF);
const _w10 = Color(0x1AFFFFFF);
const _green = Color(0xFF00B052);
const _red = Color(0xFFD73C3C);
const _lime = Color(0xFFCCFF00);
const _cyan = Color(0xFF00E5FF);
const _dm = 'DMSans';

double _d(dynamic v) => v == null ? 0 : double.tryParse(v.toString()) ?? 0;

// ── Models ────────────────────────────────────────────────────────────────────
class _PnlData {
  final double todayValue, yesterdayValue, todayPnl, todayPct;
  final Map<String, _Period> periodChanges;
  final List<_ChartPt> chartData;
  final Map<int, _CalDay> calendarData;
  final Map<String, _TradePnl> tradePnl;

  _PnlData({
    required this.todayValue,
    required this.yesterdayValue,
    required this.todayPnl,
    required this.todayPct,
    required this.periodChanges,
    required this.chartData,
    required this.calendarData,
    required this.tradePnl,
  });

  factory _PnlData.fromJson(Map<String, dynamic> j) {
    final pc = <String, _Period>{};
    final raw = (j['period_changes'] as Map?) ?? {};
    raw.forEach((k, v) {
      if (v is Map) pc[k] = _Period.fromJson(v);
    });

    final chart = ((j['chart_data'] as List?) ?? [])
        .map((e) => _ChartPt(e['date']?.toString() ?? '', _d(e['value'])))
        .toList();

    final cal = <int, _CalDay>{};
    final calRaw = (j['calendar_data'] as Map?) ?? {};
    calRaw.forEach((k, v) {
      final day = int.tryParse(k.toString());
      if (day != null && v is Map) cal[day] = _CalDay.fromJson(v);
    });

    final tp = <String, _TradePnl>{};
    final tpRaw = (j['trade_pnl'] as Map?) ?? {};
    tpRaw.forEach((k, v) {
      if (v is Map) tp[k] = _TradePnl.fromJson(v);
    });

    return _PnlData(
      todayValue: _d(j['today_value']),
      yesterdayValue: _d(j['yesterday_value']),
      todayPnl: _d(j['today_pnl']),
      todayPct: _d(j['today_pct']),
      periodChanges: pc,
      chartData: chart,
      calendarData: cal,
      tradePnl: tp,
    );
  }
}

class _Period {
  final double fromValue, toValue, changeAbs, changePct;
  _Period({
    required this.fromValue,
    required this.toValue,
    required this.changeAbs,
    required this.changePct,
  });
  factory _Period.fromJson(Map j) => _Period(
    fromValue: _d(j['from_value']),
    toValue: _d(j['to_value']),
    changeAbs: _d(j['change_abs']),
    changePct: _d(j['change_pct']),
  );
}

class _ChartPt {
  final String date;
  final double value;
  _ChartPt(this.date, this.value);
}

class _CalDay {
  final double pnl, pct, value;
  _CalDay({required this.pnl, required this.pct, required this.value});
  factory _CalDay.fromJson(Map j) =>
      _CalDay(pnl: _d(j['pnl']), pct: _d(j['pct']), value: _d(j['value']));
}

class _TradePnl {
  final int totalTrades, buyCount, sellCount;
  final double totalFees;
  _TradePnl({
    required this.totalTrades,
    required this.buyCount,
    required this.sellCount,
    required this.totalFees,
  });
  factory _TradePnl.fromJson(Map j) => _TradePnl(
    totalTrades: (j['total_trades'] as num?)?.toInt() ?? 0,
    buyCount: (j['buy_count'] as num?)?.toInt() ?? 0,
    sellCount: (j['sell_count'] as num?)?.toInt() ?? 0,
    totalFees: _d(j['total_fees']),
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────
class WalletPnlScreen extends StatefulWidget {
  const WalletPnlScreen({super.key});
  @override
  State<WalletPnlScreen> createState() => _WalletPnlState();
}

class _WalletPnlState extends State<WalletPnlScreen> {
  _PnlData? _pnl;
  bool _loading = true;
  String _range = '24H';
  String _calTab = 'Assets';

  double _spotTotal = 0;
  double _futureTotal = 0;
  double _futureCombinedPnl = 0;
  double _spotYesterday = 0;

  double get _grandTotal => _spotTotal + _futureTotal;

  @override
  void initState() {
    super.initState();
    _fetchPnl();
  }

  // Fetch spot total — same API as website's getTotalWalletBalanceApi()
  Future<double> _fetchSpotTotal() async {
    try {
      final resp = await APIRepository().getWalletTotalValue();
      if (resp.success) {
        return TotalBalance.fromJson(resp.data).total ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  // Fetch futures balance — same API as website's useFutureWalletDetailsBalance()
  Future<double> _fetchFutureTotal() async {
    try {
      final token = getFutureToken();
      if (token.isEmpty) return 0;
      final res = await http.get(
        Uri.parse('${APIURLConstants.baseUrl}/api/v1/future/balance'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        if (j['success'] == true) {
          return double.tryParse(
                j['data']?['total_balance']?.toString() ?? j['data']?['balance']?.toString() ?? '0',
              ) ??
              0;
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<double> _fetchFutureCombinedPnl(String token) async {
    try {
      if (token.isEmpty) return 0;
      final res = await http.get(
        Uri.parse('\${APIURLConstants.baseUrl}/api/v1/future/balance'),
        headers: {'Authorization': 'Bearer \$token'},
      );
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        if (j['success'] == true) {
          final d = j['data'] ?? {};
          final unreal = double.tryParse(d['unrealized_pnl']?.toString() ?? '0') ?? 0;
          final realized = double.tryParse(d['today_realized_pnl']?.toString() ?? '0') ?? 0;
          return unreal + realized;
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<void> _fetchPnl() async {
    setState(() => _loading = true);
    try {
      final uid = gUserRx.value.id;
      if (uid == 0) {
        setState(() => _loading = false);
        return;
      }

      // Fetch spot, future balance, and future combined PNL in parallel
      final token = getFutureToken();
      final results = await Future.wait([
        _fetchSpotTotal(),
        _fetchFutureTotal(),
        _fetchFutureCombinedPnl(token),
      ]);
      if (mounted) {
        setState(() {
          _spotTotal = results[0];
          _futureTotal = results[1];
          _futureCombinedPnl = results[2];
        });
      }

      // Pass spot-only live_total to snapshot API (matches web app)
      final liveTotal = _spotTotal > 0
          ? '&live_total=${_spotTotal.toStringAsFixed(2)}'
          : '';
      final url =
          '\${APIURLConstants.baseUrl}/api/pnl/summary?user_id=\$uid\$liveTotal';
      final res = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        if (j['success'] == true && j['data'] != null) {
          final parsed = _PnlData.fromJson(j['data'] as Map<String, dynamic>);
          // Total PNL = spot PNL + future combined (unrealized + realized)
          final spotPnl = parsed.todayPnl;
          final totalPnl = spotPnl + _futureCombinedPnl;
          final yv = parsed.yesterdayValue > 0 ? parsed.yesterdayValue : _spotTotal;
          _spotYesterday = yv;
          final base = yv + _futureTotal;
          final totalPct = base > 0 ? (totalPnl / base) * 100 : 0.0;
          // Patch todayPnl/todayPct with combined spot+future
          final patched = _PnlData(
            todayValue: parsed.todayValue,
            yesterdayValue: parsed.yesterdayValue,
            todayPnl: totalPnl,
            todayPct: totalPct,
            periodChanges: parsed.periodChanges,
            chartData: parsed.chartData,
            calendarData: parsed.calendarData,
            tradePnl: parsed.tradePnl,
          );
          if (mounted) setState(() => _pnl = patched);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // Chart slice — same as website
  List<double> get _chartValues {
    final p = _pnl;
    if (p == null) return [];
    if (_range == '24H') {
      return [p.yesterdayValue, p.todayValue];
    }
    final n = _range == '7D'
        ? 7
        : _range == '30D'
        ? 30
        : 90;
    final slice = p.chartData.length > n
        ? p.chartData.sublist(p.chartData.length - n)
        : p.chartData;
    final vals = slice.map((e) => e.value).toList();
    // Fallback: if not enough chart snapshots, synthesise from period_changes
    if (vals.length < 2) {
      final period = p.periodChanges[_range];
      if (period != null && period.fromValue > 0) {
        return [period.fromValue, period.toValue];
      }
    }
    return vals;
  }

  String get _chartDateFrom {
    final p = _pnl;
    if (p == null) return '';
    if (_range == '24H') return _yesterday();
    final slice = _chartSlice;
    return slice.isNotEmpty ? slice.first.date : '';
  }

  String get _chartDateTo {
    final p = _pnl;
    if (p == null) return '';
    if (_range == '24H') return _today();
    final slice = _chartSlice;
    return slice.isNotEmpty ? slice.last.date : '';
  }

  List<_ChartPt> get _chartSlice {
    final p = _pnl;
    if (p == null) return [];
    final n = _range == '7D'
        ? 7
        : _range == '30D'
        ? 30
        : 90;
    return p.chartData.length > n
        ? p.chartData.sublist(p.chartData.length - n)
        : List.from(p.chartData);
  }

  // Period PNL values — same as website
  double get _pnlVal {
    final p = _pnl;
    if (p == null) return 0;
    if (_range == '24H' || _range == '7D') return p.todayPnl;
    return p.periodChanges[_range]?.changeAbs ?? 0;
  }

  double get _pnlPct {
    final p = _pnl;
    if (p == null) return 0;
    if (_range == '24H' || _range == '7D') return p.todayPct;
    return p.periodChanges[_range]?.changePct ?? 0;
  }

  String get _pnlLabel => _range == '24H'
      ? '24H PNL'
      : _range == '7D'
      ? '7D PNL'
      : '$_range Change';

  _TradePnl? get _tradePnl {
    final key = _range == '24H' ? 'today' : _range;
    return _pnl?.tradePnl[key];
  }

  // Calendar data
  Map<int, _CalDay> get _calData => _pnl?.calendarData ?? {};

  List<double> get _calValues => _calData.values.map((d) => d.pnl).toList();

  double get _monthTotal => _calValues.fold(0.0, (a, b) => a + b);
  double get _monthAvgPct =>
      _calValues.isNotEmpty ? _monthTotal / _calValues.length : 0;
  int get _positiveDays => _calValues.where((v) => v >= 0).length;
  int get _negativeDays => _calValues.where((v) => v < 0).length;
  int get _winRate => _calValues.isNotEmpty
      ? ((_positiveDays / _calValues.length) * 100).round()
      : 0;

  String _fmtUsd(double v) =>
      '${v >= 0 ? '+' : '-'}\$${v.abs().toStringAsFixed(2)}';
  String _fmtPct(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
  String _today() =>
      '${_monthNames[DateTime.now().month - 1]} ${DateTime.now().day}';
  String _yesterday() {
    final d = DateTime.now().subtract(const Duration(days: 1));
    return '${_monthNames[d.month - 1]} ${d.day}';
  }

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _dayShort = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  @override
  Widget build(BuildContext context) {
    final spotPct = _grandTotal > 0 ? (_spotTotal / _grandTotal) * 100 : 0.0;
    final futPct = _grandTotal > 0 ? (_futureTotal / _grandTotal) * 100 : 0.0;
    final todayPnl = _pnl?.todayPnl ?? 0;
    final todayPct = _pnl?.todayPct ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: RefreshIndicator(
        color: _lime,
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh: _fetchPnl,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header (scrolls with content) ─────────────────────────
              _headerBar(todayPnl, todayPct),

              // ── Content ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _grandBanner(spotPct, futPct),
                    _statCards(),
                    const SizedBox(height: 20),
                    Text(
                      'Assets Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _white,
                        fontFamily: _dm,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _rangeTabs(),
                    const SizedBox(height: 20),
                    _assetsAnalysisPanel(),
                    const SizedBox(height: 20),
                    _tradeAnalysisPanel(),
                    const SizedBox(height: 40),
                   Text(
                          'PNL Calendar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _white,
                            fontFamily: _dm,
                          ),
                        ),
                    const SizedBox(height: 20),
                    _calendarPanel(),
                    const SizedBox(height: 20),
                    _dailyPnlBarsPanel(),
                    const SizedBox(height: 20),
                    _bestWorstPanel(),
                    const SizedBox(height: 20),
                    _winRatePanel(),
                     const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Scrollable Header Bar ────────────────────────────────────────────────
  Widget _headerBar(double todayPnl, double todayPct) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 10,
        20,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 20),
              const Text(
                'PNL Analysis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: _dm,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF04).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Today: ${todayPnl >= 0 ? '+' : '-'}\$${todayPnl.abs().toStringAsFixed(2)} (${todayPct >= 0 ? '+' : ''}${todayPct.toStringAsFixed(2)}%)',
                    style: const TextStyle(
                      color: Color(0xFF00FF04),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dm,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                flex: 2,
                child: Container(
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFF00).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Total: \$${_grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFCCFF00),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: _dm,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Grand Total Banner ────────────────────────────────────────────────────
  Widget _grandBanner(double spotPct, double futPct) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Portfolio
          Text(
            'Total Portfolio',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              fontFamily: _dm,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 5),
          _loading
              ? _Sk(h: 36, w: 180)
              : Text(
                  '\$${_grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: _white,
                    fontFamily: _dm,
                  ),
                ),
          Text(
            'Spot + Futures',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              fontFamily: _dm,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 25),

          // Progress bar — lime (Spot) + cyan (Futures)
          if (_grandTotal > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: _cyan,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (spotPct / 100).clamp(0.005, 1.0),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: _lime,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Legend
            Row(
              children: [
                _legendDot(_lime),
                const SizedBox(width: 10),
                Text(
                  '${spotPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: _dm,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 25),
                _legendDot(_cyan),
                const SizedBox(width: 10),
                Text(
                  '${futPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: _dm,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
          ],

          // Spot + Futures values
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spot',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                        fontFamily: _dm,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      '\$${_spotTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _lime,
                        fontFamily: _dm,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Futures',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                        fontFamily: _dm,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      '\$${_futureTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _cyan,
                        fontFamily: _dm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c) => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  // ── Four Stat Cards ───────────────────────────────────────────────────────
  Widget _statCards() {
    final p = _pnl;
    final portfolioVal = _grandTotal > 0 ? _grandTotal : (p?.todayValue ?? 0);
    final periodPnl = _pnlVal;
    final periodPct = _pnlPct;

    final periodLabel = _range == '24H'
        ? '24H PNL'
        : _range == '7D'
        ? '7D PNL'
        : '$_range Change';

    final cards = [
      _StatCardData(
        'Portfolio Value',
        '\$${portfolioVal.toStringAsFixed(2)}',
        'Spot + Futures + P2P',
        Colors.transparent,
        Colors.transparent,
      ),

      _StatCardData(
        "Today's PNL",
        _loading ? '–' : _fmtUsd(p?.todayPnl ?? 0),
        _loading ? '' : _fmtPct(p?.todayPct ?? 0),
        Colors.transparent,
        Colors.transparent,
      ),

      _StatCardData(
        periodLabel,
        _loading ? '–' : _fmtUsd(periodPnl),
        _loading ? '' : _fmtPct(periodPct),
        Colors.transparent,
        Colors.transparent,
      ),

      _StatCardData(
        "Yesterday's Value",
        _loading ? '–' : '\$${(p?.yesterdayValue ?? 0).toStringAsFixed(2)}',
        'Baseline',
        Colors.transparent,
        Colors.transparent,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _buildStatCard(cards[i]),
    );
  }

  Widget _buildStatCard(_StatCardData c) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              c.title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontFamily: _dm,
              ),
            ),

            _loading
                ? _Sk(h: 22, w: 120)
                : Text(
                    c.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: _dm,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

            Text(
              c.sub,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontFamily: _dm,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Range Tabs ────────────────────────────────────────────────────────────
  Widget _rangeTabs() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['24H', '7D', '30D', '90D'].map((r) {
        final on = r == _range;
        return GestureDetector(
          // setState triggers _chartValues/_pnlVal recalculation from existing data
          onTap: () => setState(() => _range = r),
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: on ? _lime : _card,
              borderRadius: BorderRadius.circular(5),
              border: on ? null : Border.all(color: Colors.transparent),
            ),
            child: Text(
              r,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: on ? const Color(0xFF111111) : Colors.white,
                fontFamily: _dm,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Cal Tabs ──────────────────────────────────────────────────────────────
  // Widget _calTabs() {
  //   return Row(
  //     mainAxisSize: MainAxisSize.min,
  //     children: ['Assets', 'Cross', 'Isolated', 'Earn'].map((t) {
  //       final on = t == _calTab;
  //       return GestureDetector(
  //         onTap: () => setState(() => _calTab = t),
  //         child: Container(
  //           margin: const EdgeInsets.only(left: 4),
  //           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  //           decoration: BoxDecoration(
  //             color: on ? _lime : _card,
  //             borderRadius: BorderRadius.circular(8),
  //             border: on ? null : Border.all(color: _w10),
  //           ),
  //           child: Text(
  //             t,
  //             style: TextStyle(
  //               fontSize: 11,
  //               fontWeight: FontWeight.w600,
  //               color: on ? _bg : _w50,
  //               fontFamily: _dm,
  //             ),
  //           ),
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  // ── Assets Analysis Panel ─────────────────────────────────────────────────
  Widget _assetsAnalysisPanel() {
    final pnlV = _pnlVal;
    final pnlP = _pnlPct;
    final color = pnlV >= 0 ? const Color(0xFF00B052) : _red;

    final cv = _chartValues;
    final dateF = _chartDateFrom;
    final dateT = _chartDateTo;

    final valF = cv.isNotEmpty ? '\$${cv.first.toStringAsFixed(2)}' : '';

    final valT = cv.isNotEmpty ? '\$${cv.last.toStringAsFixed(2)}' : '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assets Analysis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: _dm,
            ),
          ),

          const SizedBox(height: 10),

          /// Top Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pnlLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                        fontFamily: _dm,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 5),

                    _loading
                        ? _Sk(h: 16, w: 70)
                        : Text(
                            _fmtPct(pnlP),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: color,
                              fontFamily: _dm,
                            ),
                          ),
                  ],
                ),
              ),

              _loading
                  ? _Sk(h: 26, w: 130)
                  : Text(
                      _fmtUsd(pnlV),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontFamily: _dm,
                      ),
                    ),
            ],
          ),

          const SizedBox(height: 20),

          /// Date + Value Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateF,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: _dm,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    valF,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: _dm,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateT,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: _dm,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    valT,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: _dm,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// Chart
          _loading
              ? _Sk(h: 180, r: 8)
              : cv.length < 2
              ? _noData(h: 180)
              : SizedBox(
                  height: 180,
                  child: _LineChart(data: cv, color: color, height: 180),
                ),

          const SizedBox(height: 10),

          /// Insight
          if (!_loading)
            Text(
              '💬 Portfolio ${pnlV >= 0 ? "grew" : "declined"} by \$${pnlV.abs().toStringAsFixed(2)}'
              '${_range == "24H" ? " in the last 24 hours" : " over $_range"}. '
              '${pnlV >= 0 ? "Great work!" : "Stay patient."}',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontFamily: _dm,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }

  // ── Trade Analysis Panel ──────────────────────────────────────────────────
  Widget _tradeAnalysisPanel() {
    final tp = _tradePnl;
    final label = _range == '24H' ? '24H Activity' : '$_range Activity';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Trade Analysis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: _dm,
            ),
          ),

          const SizedBox(height: 10),

          // Activity row (left label, right total trades)
          _loading
              ? _Sk(h: 30, w: 120)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                          fontFamily: _dm,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${tp?.totalTrades ?? 0}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: _dm,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Trade',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.5),
                              fontFamily: _dm,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

          // 2x2 stat cards
          Transform.translate(
            offset: const Offset(0, -10),
            child: _loading
                ? _Sk(h: 180, r: 12)
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.35,
                    children: [
                      _tradeBox('Buy Order', '${tp?.buyCount ?? 0}', _green),
                      _tradeBox('Sell Order', '${tp?.sellCount ?? 0}', _red),
                      _tradeBox(
                        'Fees Paid',
                        '\$${(tp?.totalFees ?? 0).toStringAsFixed(4)}',
                        Colors.white,
                      ),
                      _tradeBox(
                        'Net Trades',
                        '${(tp?.buyCount ?? 0) + (tp?.sellCount ?? 0)}',
                        Colors.white,
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 20),

          // Bottom section title
          Text(
            'Trades by Periods',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.5),
              fontFamily: _dm,
            ),
          ),

          const SizedBox(height: 10),

          // Bottom period cards
          _loading
              ? _Sk(h: 90, r: 10)
              : Row(
                  children: [
                    for (final kv in [
                      ('24H', 'today'),
                      ('7D', '7D'),
                      ('30D', '30D'),
                      ('90D', '90D'),
                    ])
                      Expanded(
                        child: Container(
                          height: 80,
                          margin: EdgeInsets.only(
                            right: kv.$1 == '90D' ? 0 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                kv.$1,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.5),
                                  fontFamily: _dm,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${_pnl?.tradePnl[kv.$2]?.totalTrades ?? 0}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: _dm,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _tradeBox(String label, String value, Color color) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF111111),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white54.withOpacity(0.5),
            fontFamily: _dm,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: _dm,
          ),
        ),
      ],
    ),
  );

  // ── PNL Calendar ──────────────────────────────────────────────────────────
  Widget _calendarPanel() {
  final now = DateTime.now();
  final year = now.year;
  final month = now.month - 1;

  final daysInMonth = DateTime(year, month + 2, 0).day;
  final firstWeekDay = DateTime(year, month + 1, 1).weekday % 7;
  final recordedCount = _calData.length;

  const double dayWidth = 70;
  final double calendarWidth = dayWidth * 7;

  return Container(
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// HEADER
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_monthNames[month]} $year',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _white,
                  fontFamily: _dm,
                ),
              ),
              Text(
                '$recordedCount days recorded',
                style:  TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: _dm,
                ),
              ),
            ],
          ),
        ),

        /// HORIZONTAL SCROLL AREA
        SizedBox(
          height: 460,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: calendarWidth,
              child: Column(
                children: [
                  /// WEEK DAYS
                  Padding(
                    padding: EdgeInsets.zero,
                    child: Row(
                      children: _dayShort.map((d) {
                        return SizedBox(
                          width: dayWidth - 2,
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style:  TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w400,
                              fontFamily: _dm,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),


                  /// CALENDAR GRID
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                                childAspectRatio: 0.82,
                              ),
                              itemCount: firstWeekDay + daysInMonth,
                              itemBuilder: (_, i) {
                                if (i < firstWeekDay) {
                                  return const SizedBox();
                                }

                                final day = i - firstWeekDay + 1;
                                final d = _calData[day];

                                final col = d == null
                                    ? _w50
                                    : (d.pnl >= 0 ? _green : _red);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF111111),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$day',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _white,
                                          fontFamily: _dm,
                                        ),
                                      ),

                                      if (d != null) ...[
                                        const SizedBox(height: 4),

                                        Text(
                                          '${d.pnl >= 0 ? '+' : ''}${d.pnl.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: col,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: _dm,
                                          ),
                                        ),

                                        const SizedBox(height: 2),

                                        Text(
                                          '${d.pct >= 0 ? '+' : ''}${d.pct.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                            color: col,
                                            fontFamily: _dm,
                                          ),
                                        ),
                                      ] else
                                        Text(
                                          '-',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: _dm,
                                            color: Colors.white.withOpacity(0.5),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 0),

        /// SUMMARY CARDS
        Transform.translate(
          offset: const Offset(0, -30),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 2.8,
              children: [
                _miniCard(
                  'Month PNL',
                  _loading ? '–' : _fmtUsd(_monthTotal),
                  _monthTotal >= 0 ? _green : _red,
                ),
                _miniCard(
                  'Avg Daily %',
                  _loading ? '–' : _fmtPct(_monthAvgPct),
                  _monthAvgPct >= 0 ? _green : _red,
                ),
                _miniCard(
                  'Positive Days',
                  _loading ? '–' : '$_positiveDays',
                  _green,
                ),
                _miniCard(
                  'Negative Days',
                  _loading ? '–' : '$_negativeDays',
                  _red,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _miniCard(String label, String value, Color color) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF111111),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style:  TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), fontFamily: _dm, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: _dm,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  // ── Daily PNL Bars ────────────────────────────────────────────────────────
  Widget _dailyPnlBarsPanel() {
    final vals = _calValues;
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily PNL Bars',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _white,
              fontFamily: _dm,
            ),
          ),
          const SizedBox(height: 10),
          _loading
              ? _Sk(h: 120, r: 8)
              : vals.isEmpty
              ? _noData()
              : _BarChart(data: vals, height: 120),
          const SizedBox(height: 10),
          if (vals.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  'Day 1',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), fontFamily: _dm, fontWeight: FontWeight.w400),
                ),
                Text(
                  'Day ${vals.length}',
                  style:  TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: _dm,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Best & Worst Days ─────────────────────────────────────────────────────
  Widget _bestWorstPanel() {
    final entries = _calData.entries.toList()
      ..sort((a, b) => b.value.pnl.compareTo(a.value.pnl));
    final best = entries.isNotEmpty ? entries.first : null;
    final worst = entries.isNotEmpty ? entries.last : null;
    final now = DateTime.now();
    String fmtDay(int d) => '${_monthNames[now.month - 1]} $d, ${now.year}';

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Best & Worst Days',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _white,
              fontFamily: _dm,
            ),
          ),
          const SizedBox(height: 20),
          _loading
              ? Column(
                  children: [
                    _Sk(h: 70, r: 12),
                    const SizedBox(height: 10),
                    _Sk(h: 70, r: 12),
                  ],
                )
              : best == null
              ? _noData()
              : Column(
                  children: [
                    _bestWorstRow('Best Days', best, _green, fmtDay(best.key)),
                    const SizedBox(height: 10),
                    _bestWorstRow('Worst Day', worst!, _red, fmtDay(worst.key)),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _bestWorstRow(
    String label,
    MapEntry<int, _CalDay> entry,
    Color color,
    String date,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:  TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                   fontWeight: FontWeight.w400,
                  fontFamily: _dm,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _white,
                  fontFamily: _dm,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtUsd(entry.value.pnl),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: _dm,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _fmtPct(entry.value.pct),
                style: TextStyle(fontSize: 12, color: color, fontFamily: _dm, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Win Rate ──────────────────────────────────────────────────────────────
  Widget _winRatePanel() {
    final wr = _winRate;
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Win Rate',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _white,
              fontFamily: _dm,
            ),
          ),
          const SizedBox(height: 10),
          _loading
              ? _Sk(h: 30, w: 80)
              : Text(
                  '$wr%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: wr >= 50 ? _green : _red,
                    fontFamily: _dm,
                  ),
                ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                Container(height: 10, color: Colors.white.withOpacity(0.5)),
                AnimatedFractionallySizedBox(
                  widthFactor: (wr / 100).clamp(0.0, 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  child: Container(height: 10, color: wr >= 50 ? _green : _red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noData({double h = 80}) => SizedBox(
    height: h,
    child: Center(
      child: Text(
        'No data for this period',
        style: TextStyle(color: _w50, fontSize: 13, fontFamily: _dm),
      ),
    ),
  );
}

// ── Stat Card Data ────────────────────────────────────────────────────────────
class _StatCardData {
  final String title, value, sub;
  final Color glowTop, glowMid;
  _StatCardData(this.title, this.value, this.sub, this.glowTop, this.glowMid);
}

// ── Skeleton ──────────────────────────────────────────────────────────────────
class _Sk extends StatelessWidget {
  const _Sk({this.h = 20, this.w = double.infinity, this.r = 6});
  final double h, w, r;
  @override
  Widget build(BuildContext context) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.white12,
      borderRadius: BorderRadius.circular(r),
    ),
  );
}

// ── Line Chart ────────────────────────────────────────────────────────────────
class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.data,
    required this.color,
    this.height = 180,
  });
  final List<double> data;
  final Color color;
  final double height;
  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return SizedBox(height: height);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        size: Size.infinite,
        painter: _LinePainter(data: data, color: color),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.data, required this.color});
  final List<double> data;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final W = size.width, H = size.height;
    final mn = data.reduce(math.min), mx = data.reduce(math.max);
    final rng = (mx - mn) < 0.001 ? 1.0 : mx - mn;
    double toX(int i) => (i / (data.length - 1)) * W;
    double toY(double v) => H - 5 - ((v - mn) / rng) * (H - 10);

    final pts = List.generate(data.length, (i) => Offset(toX(i), toY(data[i])));
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = pts[math.max(i - 1, 0)],
          p1 = pts[i],
          p2 = pts[i + 1],
          p3 = pts[math.min(i + 2, pts.length - 1)];
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }

    // Fill
    final fill = Path.from(path)
      ..lineTo(W, H)
      ..lineTo(0, H)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.10));

    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LinePainter o) => true;
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  const _BarChart({required this.data, this.height = 120});
  final List<double> data;
  final double height;
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarPainter(data: data),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({required this.data});
  final List<double> data;
  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width, H = size.height;
    final nonZero = data.where((v) => v.abs() > 0.01).toList();
    if (nonZero.isEmpty) return;
    final maxAbs = nonZero.map((v) => v.abs()).reduce(math.max);
    final midY = H / 2;
    final barW = math.max(4.0, (W / data.length) - 2);
    for (int i = 0; i < data.length; i++) {
      final v = data[i];
      if (v.abs() < 0.01) continue;
      final bh = math.max(3.0, (v.abs() / maxAbs) * (midY - 6));
      final x = (i / data.length) * W + (W / data.length - barW) / 2;
      final y = v >= 0 ? midY - bh : midY;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, bh),
          const Radius.circular(5),
        ),
        Paint()..color = v >= 0 ? _green : _red,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter o) => true;
}
