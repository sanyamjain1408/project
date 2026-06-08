import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/wallet/wallet_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — Figma exact match
// ─────────────────────────────────────────────────────────────────────────────
const _bg = Color(0xFF0D0F14);
const _surface = Color(0xFF13161D);
const _card = Color(0xFF181C26);
const _border = Color(0xFF1F2535);
const _accent = Color(0xFFC6F135);
const _green = Color(0xFF0ECB81);
const _red = Color(0xFFF6465D);
const _yellow = Color(0xFFF0B90B);
const _blue = Color(0xFF3B82F6);
const _text = Color(0xFFEAECEF);
const _muted = Color(0xFF848E9C);
const _fnt = 'DMSans';

// Figma chart colors: dark olive/green fill
const _chartFill = Color(0xFF3E4815);
const _chartStroke = Color(0xFF7CB518);

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
double _d(dynamic v) => v == null ? 0 : double.tryParse(v.toString()) ?? 0;

class _Pt {
  final String date;
  final double value;
  _Pt(this.date, this.value);
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
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

class _PnlData {
  final double todayValue, yesterdayValue, todayPnl, todayPct;
  final Map<String, _Period> periods;
  final List<_Pt> chart;

  _PnlData({
    required this.todayValue,
    required this.yesterdayValue,
    required this.todayPnl,
    required this.todayPct,
    required this.periods,
    required this.chart,
  });

  factory _PnlData.fromJson(Map<String, dynamic> j) {
    final pc = (j['period_changes'] as Map<String, dynamic>?) ?? {};
    final periods = <String, _Period>{};
    pc.forEach((k, v) {
      if (v is Map) periods[k] = _Period.fromJson(v);
    });

    final chart = ((j['chart_data'] as List?) ?? [])
        .map((e) => _Pt(e['date']?.toString() ?? '', _d(e['value'])))
        .toList();

    return _PnlData(
      todayValue: _d(j['today_value']),
      yesterdayValue: _d(j['yesterday_value']),
      todayPnl: _d(j['today_pnl']),
      todayPct: _d(j['today_pct']),
      periods: periods,
      chart: chart,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class SpotPnlScreen extends StatefulWidget {
  const SpotPnlScreen({super.key});
  @override
  State<SpotPnlScreen> createState() => _SpotPnlScreenState();
}

class _SpotPnlScreenState extends State<SpotPnlScreen> {
  _PnlData? _pnl;
  List<Wallet> _wallets = [];
  double _spotTotal = 0;
  String _spotCoin = 'USD';
  bool _pnlLoading = true;
  bool _walletLoading = true;
  String _range = '7D';
  bool _hide = false;

  @override
  void initState() {
    super.initState();
    // Load spotTotal from already-fetched WalletController
    try {
      final wc = Get.find<WalletController>();
      if (wc.spotWalletTotal.value > 0) _spotTotal = wc.spotWalletTotal.value;
      final cur = wc.totalBalance.value.currency;
      if (cur != null && cur.isNotEmpty) _spotCoin = cur;
    } catch (_) {}
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_fetchWallets(), _fetchPnl()]);
  }

  // ── Wallet list — uses APIRepository with proper auth ─────────────────────
  Future<void> _fetchWallets() async {
    if (mounted) setState(() => _walletLoading = true);
    try {
      final resp = await APIRepository().getWalletList(
        1,
        type: WalletViewType.spot,
        search: '',
      );
      if (resp.success && resp.data != null) {
        final raw = resp.data;
        List items = [];
        if (raw is Map) {
          items =
              raw['data'] as List? ?? raw['wallets']?['data'] as List? ?? [];
        } else if (raw is List) {
          items = raw;
        }
        // ignore: avoid_print
        print(
          'SPOT_PNL_WALLETS count=${items.length} first=${items.isNotEmpty ? items.first : null}',
        );
        final list =
            items
                .map((e) => Wallet.fromJson(e as Map<String, dynamic>))
                .where((w) => (w.totalBalanceUsd ?? 0) > 0)
                .toList()
              ..sort(
                (a, b) =>
                    (b.totalBalanceUsd ?? 0).compareTo(a.totalBalanceUsd ?? 0),
              );
        if (mounted) setState(() => _wallets = list);
      } else {
        // ignore: avoid_print
        print('SPOT_PNL_WALLETS_FAIL: ${resp.message}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('SPOT_PNL_WALLETS_ERROR: $e');
    }
    if (mounted) setState(() => _walletLoading = false);
  }

  // ── PNL summary — public API, no auth needed ──────────────────────────────
  Future<void> _fetchPnl() async {
    if (mounted) setState(() => _pnlLoading = true);
    try {
      final uid = gUserRx.value.id;
      if (uid == 0) {
        if (mounted) setState(() => _pnlLoading = false);
        return;
      }
      final days = _range == '7D'
          ? 7
          : _range == '30D'
          ? 30
          : 90;
      final liveQ = _spotTotal > 0 ? '&live_total=$_spotTotal' : '';
      final q = '$liveQ&days=$days';
      final url = '${APIURLConstants.baseUrl}/api/pnl/summary?user_id=$uid$q';
      // ignore: avoid_print
      print('PNL_URL: $url');
      final r = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );
      // ignore: avoid_print
      print('PNL_STATUS: ${r.statusCode}');
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        // ignore: avoid_print
        print(
          'PNL_SUCCESS: ${j['success']}  chart_data_len: ${(j['data']?['chart_data'] as List?)?.length}  period_keys: ${(j['data']?['period_changes'] as Map?)?.keys.toList()}',
        );
        if (j['success'] == true && j['data'] != null) {
          final parsed = _PnlData.fromJson(j['data'] as Map<String, dynamic>);
          // ignore: avoid_print
          print('PNL_CHART_POINTS: ${parsed.chart.length}  range: $_range');
          // ignore: avoid_print
          print(
            'PNL_CHART_VALUES: ${parsed.chart.map((p) => '${p.date}:${p.value.toStringAsFixed(0)}').join(', ')}',
          );
          if (_spotTotal == 0 && parsed.todayValue > 0)
            _spotTotal = parsed.todayValue;
          if (mounted) setState(() => _pnl = parsed);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('SPOT_PNL_ERROR: $e');
    }
    if (mounted) setState(() => _pnlLoading = false);
  }

  // ── Chart slices — same as website useMemo slice(-n) ──────────────────────
  List<_Pt> get _slice {
    if (_pnl == null) return [];
    final c = _pnl!.chart;
    final n = _range == '7D'
        ? 7
        : _range == '30D'
        ? 30
        : 90;
    return c.length > n ? c.sublist(c.length - n) : List.from(c);
  }

  int get _sliceDays => _slice.length;

  // Net worth — raw values directly (website: slice.map(d => d.value))
  List<double> get _netWorth => _slice.map((e) => e.value).toList();

  // Daily diff — website: y = i===0 ? 0 : d.value - slice[i-1].value
  List<double> get _dailyDiff {
    final s = _slice;
    if (s.isEmpty) return [];
    return List.generate(
      s.length,
      (i) => i == 0 ? 0.0 : s[i].value - s[i - 1].value,
    );
  }

  // Profits — website: y = d.value - slice[0].value
  List<double> get _profitsDiff {
    final s = _slice;
    if (s.length < 2) return [];
    return s.map((e) => e.value - s.first.value).toList();
  }

  // Cumulative % — website: ((d.value - base) / base) * 100
  List<double> get _cumPct {
    final s = _slice;
    if (s.isEmpty) return [];
    final base = s.first.value == 0 ? 1.0 : s.first.value;
    return s.map((e) => ((e.value - base) / base) * 100).toList();
  }

  // BTC counter-trend — website: cumPct * -0.6 - i * 0.08
  List<double> get _btcTrend {
    final s = _slice;
    if (s.isEmpty) return [];
    final base = s.first.value == 0 ? 1.0 : s.first.value;
    return List.generate(s.length, (i) {
      final pct = ((s[i].value - base) / base) * 100;
      return pct * -0.6 - i * 0.08;
    });
  }

  String get _fd => _slice.isNotEmpty ? _slice.first.date : '';
  String get _ld => _slice.isNotEmpty ? _slice.last.date : '';

  _Period? get _curPeriod => _pnl?.periods[_range];

  String _pct(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
  String _usd(double v, {int dec = 2}) =>
      '${v >= 0 ? '+' : ''}\$${v.abs().toStringAsFixed(dec)}';

  // Allocation data for donut
  static const _sliceColors = [
    _blue,
    _green,
    _yellow,
    _accent,
    Color(0xFFa78bfa),
    Color(0xFFf97316),
    Color(0xFF06b6d4),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p7d = _pnl?.periods['7D'];
    final p90d = _pnl?.periods['90D'];

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: RefreshIndicator(
        color: _accent,
        backgroundColor: const Color(0xFF111111),
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerBar(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heroCard(p7d, p90d),
                    const SizedBox(height: 10),
                    _allocationCard(),
                    const SizedBox(height: 20),
                    _rangeTabs(),
                    const SizedBox(height: 20),
                    _dailyPnlCard(),
                    const SizedBox(height: 20),
                    _profitsCard(),
                    const SizedBox(height: 20),
                    _netWorthCard(),
                    const SizedBox(height: 20),
                    _cumPnlCard(),
                    const SizedBox(height: 20),
                    _holdingsCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerBar(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(left: 20, right: 20, top: 40),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 20),
          const Text(
            'Spot PNL',
            style: TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: "DMSans",
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 1. HERO CARD
  // ═══════════════════════════════════════════════════════════════════
  Widget _heroCard(_Period? p7d, _Period? p90d) {
    final total = _pnl?.todayValue ?? _spotTotal;
    final todayPnl = _pnl?.todayPnl ?? 0;
    final todayPct = _pnl?.todayPct ?? 0;

    return _firstBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Total Value ($_spotCoin)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _hide = !_hide),
                child: Icon(
                  _hide
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white.withOpacity(0.5),
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _pnlLoading
              ? _Sk(h: 42, w: 200)
              : Text(
                  _hide ? '****' : '\$ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    fontFamily: "DMSans",
                    letterSpacing: -0.5,
                  ),
                ),
          const SizedBox(height: 5),
          _pnlLoading
              ? _Sk(h: 13, w: 120)
              : Text(
                  _hide ? '≈ ****' : '≈ \$${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w400,
                    fontFamily: "DMSans",
                  ),
                ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          // 3-column PNL stats
          Row(
            children: [
              Expanded(
                child: _pnlCol(
                  "Today's PNL",
                  todayPct,
                  todayPnl,
                  align: CrossAxisAlignment.start,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.1),
              ),
              Expanded(
                child: _pnlCol(
                  "7D PNL",
                  p7d?.changePct ?? 0,
                  p7d?.changeAbs ?? 0,
                  align: CrossAxisAlignment.center,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.1),
              ),
              Expanded(
                child: _pnlCol(
                  "Cumulative PNL",
                  p90d?.changePct ?? 0,
                  p90d?.changeAbs ?? 0,
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pnlCol(
    String label,
    double pct,
    double abs, {
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    final col = pct >= 0 ? _green : _red;
    final padH = align == CrossAxisAlignment.start ? 0.0 : 12.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padH),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              fontFamily: "DMSans",
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          _pnlLoading
              ? _Sk(h: 16, w: 55)
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: align == CrossAxisAlignment.end
                      ? Alignment.centerRight
                      : align == CrossAxisAlignment.center
                      ? Alignment.center
                      : Alignment.centerLeft,
                  child: Text(
                    _pct(pct),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: col,
                      fontFamily: "DMSans",
                    ),
                  ),
                ),
          const SizedBox(height: 5),
          _pnlLoading
              ? _Sk(h: 11, w: 80)
              : Text(
                  _hide ? '****' : '${_usd(abs)} $_spotCoin',
                  style: TextStyle(
                    fontSize: 12,
                    color: col.withValues(alpha: 0.5),
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 2. ASSET ALLOCATION — Donut
  // ═══════════════════════════════════════════════════════════════════
  Widget _allocationCard() {
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Asset Allocation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _text,
                  fontFamily: "DMSans",
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _walletLoading
              ? _Sk(h: 140, r: 8)
              : _wallets.isEmpty
              ? _noData(msg: 'No spot assets found')
              : _DonutWidget(
                  wallets: _wallets.take(7).toList(),
                  total: _spotTotal,
                ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 3. RANGE TABS
  // ═══════════════════════════════════════════════════════════════════
  Widget _rangeTabs() {
    return Row(
      children: ['7D', '30D', '90D'].map((r) {
        final on = r == _range;
        return GestureDetector(
          onTap: () {
            setState(() => _range = r);
            _fetchPnl();
          },
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            decoration: BoxDecoration(
              color: on ? _accent : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(5),
              border: on ? null : Border.all(color: Colors.transparent),
            ),
            child: Text(
              r,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: on ? const Color(0xFF111111) : Colors.white,
                fontFamily: "DMSans",
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 4. DAILY PNL BARS — Figma: multiple green/red bars
  // ═══════════════════════════════════════════════════════════════════
  Widget _dailyPnlCard() {
    final daily = _dailyDiff;
    final lastV = daily.isNotEmpty ? daily.last : 0.0;

    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily PNL Bars',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _text,
                  fontFamily: "DMSans",
                ),
              ),
              Text(
                _ld,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _pnlLoading
              ? _Sk(h: 30, w: 130)
              : Text(
                  _hide
                      ? '****'
                      : '${lastV >= 0 ? '+' : ''}\$${lastV.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: lastV >= 0 ? _green : _red,
                    fontFamily: "DMSans",
                  ),
                ),
          const SizedBox(height: 20),
          _pnlLoading
              ? _Sk(h: 130, r: 8)
              : daily.isEmpty
              ? _noData()
              : _BarChart(data: daily, height: 130),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day 1',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                'Day $_sliceDays',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 5. PROFITS — Figma: olive/green smooth area chart
  // ═══════════════════════════════════════════════════════════════════
  Widget _profitsCard() {
    final diff = _profitsDiff;
    final period = _curPeriod;
    final val = period?.changeAbs ?? (_pnl?.todayPnl ?? 0);

    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _text,
                  fontFamily: "DMSans",
                ),
              ),
              Text(
                '$_fd - $_ld',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _pnlLoading
              ? _Sk(h: 30, w: 130)
              : Text(
                  _hide ? '****' : _usd(val),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: val >= 0 ? _green : _red,
                    fontFamily: "DMSans",
                  ),
                ),
          const SizedBox(height: 20),
          _pnlLoading
              ? _Sk(h: 150, r: 8)
              : diff.length < 2
              ? _noData()
              : _AreaChart(data: diff, height: 150),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 6. ASSET NET WORTH — Figma: olive/green smooth area chart
  // ═══════════════════════════════════════════════════════════════════
  Widget _netWorthCard() {
    final nw = _netWorth;
    final last = nw.isNotEmpty ? nw.last : _spotTotal;

    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Asset Net Worth',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _text,
                  fontFamily: "DMSans",
                ),
              ),
              Text(
                '$_fd - $_ld',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _pnlLoading
              ? _Sk(h: 28, w: 130)
              : Text(
                  _hide ? '****' : '\$${last.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _text,
                    fontFamily: "DMSans",
                  ),
                ),
          const SizedBox(height: 20),
          _pnlLoading
              ? _Sk(h: 150, r: 8)
              : nw.length < 2
              ? _noData()
              : _AreaChart(data: nw, height: 150),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 7. CUMULATIVE PNL % — yellow + blue dashed
  // ═══════════════════════════════════════════════════════════════════
  Widget _cumPnlCard() {
    final cum = _cumPct;
    final btc = _btcTrend;
    final cLast = cum.isNotEmpty ? cum.last : 0.0;
    final bLast = btc.isNotEmpty ? btc.last : 0.0;

    String topL = '', midL = '', botL = '';
    if (cum.isNotEmpty && btc.isNotEmpty) {
      final all = [...cum, ...btc];
      final mx = all.reduce(math.max);
      final mn = all.reduce(math.min);
      topL = '${mx >= 0 ? '+' : ''}${mx.toStringAsFixed(2)}%';
      midL =
          '${((mx + mn) / 2) >= 0 ? '+' : ''}${((mx + mn) / 2).toStringAsFixed(2)}%';
      botL = '${mn >= 0 ? '+' : ''}${mn.toStringAsFixed(2)}%';
    }

    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cumulative PNL(%)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _text,
                  fontFamily: "DMSans",
                ),
              ),
              Flexible(
                child: Text(
                  '$_fd - $_ld',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: "DMSans",
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cLast >= 0 ? '+' : ''}${cLast.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEBE400),
                      fontFamily: "DMSans",
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 2,
                        color: const Color(0xFFEBE400),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cumulative PNL',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                          fontFamily: "DMSans",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${bLast >= 0 ? '+' : ''}${bLast.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F46FF),
                      fontFamily: "DMSans",
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(width: 5, height: 2, color: Color(0xFF4F46FF)),
                      const SizedBox(width: 4),
                      Text(
                        'Cumulative PNL',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                          fontFamily: "DMSans",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _pnlLoading
              ? _Sk(h: 150, r: 8)
              : cum.length < 2
              ? _noData()
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 150,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [topL, midL, botL]
                            .map(
                              (l) => Text(
                                l,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.5),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: "DMSans",
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: _DualLineChart(
                        data1: cum,
                        data2: btc,
                        height: 150,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 8. SPOT HOLDINGS
  // ═══════════════════════════════════════════════════════════════════
  Widget _holdingsCard() {
    final visible = _wallets.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spot Holdings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _text,
            fontFamily: "DMSans",
          ),
        ),
        const SizedBox(height: 20),
        _walletLoading
            ? Column(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _Sk(h: 54, r: 10),
                  ),
                ),
              )
            : visible.isEmpty
            ? _noData(msg: 'No spot assets found')
            : Column(
                children: visible
                    .asMap()
                    .entries
                    .map(
                      (e) => _holdingRow(
                        e.value,
                        e.key == visible.length - 1,
                        e.key,
                      ),
                    )
                    .toList(),
              ),
      ],
    );
  }

  Widget _holdingRow(Wallet w, bool isLast, int idx) {
    final barColor = _sliceColors[idx % _sliceColors.length];
    final usd = w.totalBalanceUsd ?? 0;
    final bal = double.tryParse(w.balance?.toString() ?? '0') ?? 0;
    final barFrac = _spotTotal > 0 ? (usd / _spotTotal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.transparent)),
      ),
      child: Row(
        children: [
          // coin icon
          ClipOval(
            child: w.coinIcon != null && w.coinIcon!.isNotEmpty
                ? Image.network(
                    w.coinIcon!,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _fallback(w.coinType ?? '?'),
                  )
                : _fallback(w.coinType ?? '?'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text:  TextSpan(
                    children: [
                      TextSpan(
                        text: 'BTC',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: _text,
                          fontFamily: "DMSans",
                        ),
                      ),
                      TextSpan(
                        text: '/USDT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.5), // USDT ka color
                          fontFamily: "DMSans",
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  w.name ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w400
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _hide ? '****' : bal.toStringAsFixed(4),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: _text,
                  fontFamily: "DMSans",
                ),
              ),
              Text(
                _hide ? '****' : '≈\$${usd.toStringAsFixed(4)}',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), fontFamily: "DMSans"),
              ),
            ],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                widthFactor: barFrac,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(String coin) => Container(
    width: 38,
    height: 38,
    color: _surface,
    alignment: Alignment.center,
    child: Text(
      coin.isNotEmpty ? coin[0].toUpperCase() : '?',
      style: const TextStyle(
        color: _text,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _noData({String msg = 'No data for this period'}) => SizedBox(
    height: 80,
    child: Center(
      child: Text(
        msg,
        style: TextStyle(color: _muted, fontSize: 13, fontFamily: _fnt),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _firstBox extends StatelessWidget {
  const _firstBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x331A1A1A), // 20% opacity (#1A1A1A33)
            Color(0xFF111111), // dark bottom
          ],
        ),
        borderRadius: BorderRadius.circular(20), // Figma radius
        border: const Border(
          top: BorderSide(color: Colors.white, width: 1),
          bottom: BorderSide(color: Colors.white, width: 1),
        ),
      ),
      child: child,
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.transparent),
    ),
    child: child,
  );
}

class _Sk extends StatelessWidget {
  const _Sk({this.h = 20, this.w = double.infinity, this.r = 6});
  final double h, w, r;
  @override
  Widget build(BuildContext context) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(r),
    ),
  );
}

// ── Donut Chart ───────────────────────────────────────────────────────────────
class _SliceData {
  final String label;
  final double value;
  final Color color;
  _SliceData(this.label, this.value, this.color);
}

class _DonutWidget extends StatelessWidget {
  const _DonutWidget({required this.wallets, required this.total});
  final List<Wallet> wallets;
  final double total;

  static const _colors = [
    _blue,
    _green,
    _yellow,
    _accent,
    Color(0xFFa78bfa),
    Color(0xFFf97316),
    Color(0xFF06b6d4),
  ];

  @override
  Widget build(BuildContext context) {
    final tot = wallets.fold(0.0, (s, w) => s + (w.totalBalanceUsd ?? 0));
    final slices = wallets
        .asMap()
        .entries
        .map(
          (e) => _SliceData(
            e.value.coinType ?? '?',
            e.value.totalBalanceUsd ?? 0,
            _colors[e.key % _colors.length],
          ),
        )
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CustomPaint(
            painter: _DonutPainter(slices: slices, total: tot),
          ),
        ),
        const SizedBox(width: 50),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 10,
            children: slices
                .map(
                  (s) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 5),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${s.label} ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(
                                  0.5,
                                ), // Label color
                                fontFamily: "DMSans",
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '${tot > 0 ? ((s.value / tot) * 100).toStringAsFixed(1) : '0.0'}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white, // Percentage color
                                fontFamily: "DMSans",
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.slices, required this.total});
  final List<_SliceData> slices;
  final double total;
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width / 2 - 4;
    const sw = 24.0;
    double angle = -math.pi / 2;
    for (final s in slices) {
      final sweep = total > 0 ? (s.value / total) * 2 * math.pi : 0.0;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r - sw / 2),
        angle,
        sweep,
        false,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.butt,
      );
      angle += sweep;
    }
    canvas.drawCircle(Offset(cx, cy), r - sw, Paint()..color = _card);
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Total',
            style: TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: _fnt,
            ),
          ),
          TextSpan(
            text: '\nValue',
            style: TextStyle(color: _muted, fontSize: 10, fontFamily: _fnt),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DonutPainter o) => o.slices != slices;
}

// ── Figma-style olive/green area chart ────────────────────────────────────────
class _AreaChart extends StatelessWidget {
  const _AreaChart({required this.data, this.height = 150});
  final List<double> data;
  final double height;
  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return SizedBox(height: height);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        size: Size.infinite,
        painter: _AreaPainter(data: data),
      ),
    );
  }
}

class _AreaPainter extends CustomPainter {
  const _AreaPainter({required this.data});
  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final W = size.width, H = size.height;
    const padY = 12.0;

    // Skip zero values — they cause giant spikes (e.g. 2480 → 0 → 49611)
    // Keep index to preserve x-spacing
    final indexed = <MapEntry<int, double>>[];
    for (int i = 0; i < data.length; i++) {
      if (data[i] > 0) indexed.add(MapEntry(i, data[i]));
    }
    if (indexed.length < 2) return;

    final vals = indexed.map((e) => e.value).toList();
    // Give chart breathing room so it doesn't sit flat
    final rawMin = vals.reduce(math.min);
    final rawMax = vals.reduce(math.max);
    final mn = rawMin > 0 ? rawMin * 0.90 : rawMin * 1.10;
    final mx = rawMax > 0 ? rawMax * 1.02 : rawMax * 0.98;
    final rng = (mx - mn) < 0.001 ? 1.0 : mx - mn;

    final total = data.length - 1;
    double toX(int origIdx) => (origIdx / total) * W;
    double toY(double v) => H - padY - ((v - mn) / rng) * (H - padY * 2);

    final pts = indexed.map((e) => Offset(toX(e.key), toY(e.value))).toList();
    final linePath = _cr(pts);
    final bottom = H;

    // Dark olive fill
    final fillPath = Path.from(linePath)
      ..lineTo(pts.last.dx, bottom)
      ..lineTo(pts.first.dx, bottom)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = _chartFill);

    // Green stroke
    canvas.drawPath(
      linePath,
      Paint()
        ..color = _chartStroke
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _cr(List<Offset> p) {
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (int i = 0; i < p.length - 1; i++) {
      final p0 = p[math.max(i - 1, 0)],
          p1 = p[i],
          p2 = p[i + 1],
          p3 = p[math.min(i + 2, p.length - 1)];
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _AreaPainter o) => true;
}

// ── Dual Line (yellow solid + blue dashed) ────────────────────────────────────
class _DualLineChart extends StatelessWidget {
  const _DualLineChart({
    required this.data1,
    required this.data2,
    this.height = 150,
  });
  final List<double> data1, data2;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(
      size: Size.infinite,
      painter: _DualPainter(d1: data1, d2: data2),
    ),
  );
}

class _DualPainter extends CustomPainter {
  const _DualPainter({required this.d1, required this.d2});
  final List<double> d1, d2;
  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width, H = size.height;
    const padY = 10.0;

    // Normalize both series together using min-max of combined
    final all = [...d1, ...d2];
    final mn = all.reduce(math.min);
    final mx = all.reduce(math.max);
    final rng = (mx - mn) < 0.001 ? 1.0 : mx - mn;

    double toX(int i, int len) => (i / (len - 1)) * W;
    double toY(double v) => H - padY - ((v - mn) / rng) * (H - padY * 2);

    Path cr(List<double> d) {
      final pts = List.generate(
        d.length,
        (i) => Offset(toX(i, d.length), toY(d[i])),
      );
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
      return path;
    }

    final bottom = H - padY + 4;

    // Olive fill under yellow line
    if (d1.length >= 2) {
      final path = cr(d1);
      final fill = Path.from(path)
        ..lineTo(toX(d1.length - 1, d1.length), bottom)
        ..lineTo(toX(0, d1.length), bottom)
        ..close();
      canvas.drawPath(fill, Paint()..color = _chartFill);
      canvas.drawPath(
        path,
        Paint()
          ..color = _yellow
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Blue dashed line
    if (d2.length >= 2) {
      final p = Paint()
        ..color = _blue
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      for (final m in cr(d2).computeMetrics()) {
        double dist = 0;
        bool on = true;
        while (dist < m.length) {
          final l = on ? 5.0 : 3.0;
          if (on) canvas.drawPath(m.extractPath(dist, dist + l), p);
          dist += l;
          on = !on;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DualPainter o) => true;
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  const _BarChart({required this.data, this.height = 130});
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
    if (data.isEmpty) return;

    final nonZero = data.where((v) => v.abs() > 0.01).toList();
    // If all bars are zero (no daily change data), skip drawing
    if (nonZero.isEmpty) return;

    // Use log scale to prevent one giant bar dominating
    double safeLog(double v) => math.log(v.abs() + 1);
    final maxLog = nonZero.map(safeLog).reduce(math.max);
    if (maxLog == 0) return;

    final midY = H * 0.55; // slightly below center so green bars have more room
    final spacing = 2.0;
    final barW = math.max(4.0, (W / data.length) - spacing);

    // Baseline
    canvas.drawLine(
      Offset(0, midY),
      Offset(W, midY),
      Paint()
        ..color = _border
        ..strokeWidth = 0.8,
    );

    for (int i = 0; i < data.length; i++) {
      final v = data[i];
      if (v.abs() < 0.01) {
        // Draw a tiny dot on baseline for zero-value days
        canvas.drawCircle(
          Offset((i / data.length) * W + barW / 2, midY),
          2,
          Paint()..color = _border,
        );
        continue;
      }
      final ratio = (safeLog(v) / maxLog).clamp(0.0, 1.0);
      final maxBarH = v >= 0 ? midY - 6 : H - midY - 6;
      final bh = math.max(5.0, ratio * maxBarH);
      final x = (i / data.length) * W + spacing / 2;
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
