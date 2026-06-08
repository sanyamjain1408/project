import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';

// ── Figma Design Tokens ───────────────────────────────────────────────────────
const _bg = Color(0xFF111111);
const _card = Color(0xFF1A1A1A);
const _white = Color(0xFFFFFFFF);
const _w50 = Color(0x80FFFFFF);
const _w10 = Color(0x1AFFFFFF);
const _green = Color(0xFF00B052);
const _green50 = Color(0x8000B052);
const _red = Color(0xFFD73C3C);
const _lime = Color(0xFFCCFF00);
const _yellow = Color(0xFFEBE400);
const _blue = Color(0xFF4F46FF);
const _fill = Color(0xFF3E4815);
const _stroke = Color(0xFFCCFF00);
const _dm = 'DMSans';

double _d(dynamic v) => v == null ? 0 : double.tryParse(v.toString()) ?? 0;

// ── Models ────────────────────────────────────────────────────────────────────
class _Pt {
  final String date;
  final double value, pnl;
  _Pt({required this.date, required this.value, required this.pnl});
}

class _FData {
  final double todayPnl, todayPct;
  final double todayRealizedPnl, todayUnrealizedPnl;
  final double currentBalance, availableBalance;
  final double sevenDPnl, sevenDPct;
  final double thirtyDPnl, thirtyDPct;
  final double lifetimePnl, lifetimeProfit, lifetimeLoss;
  final double unrealizedPnl;
  final int winDays, lossDays, buyCount, sellCount, openCount;
  final double buyVolume, sellVolume;
  final List<_Pt> chart;

  _FData({
    required this.todayPnl,
    required this.todayPct,
    required this.todayRealizedPnl,
    required this.todayUnrealizedPnl,
    required this.currentBalance,
    required this.availableBalance,
    required this.sevenDPnl,
    required this.sevenDPct,
    required this.thirtyDPnl,
    required this.thirtyDPct,
    required this.lifetimePnl,
    required this.lifetimeProfit,
    required this.lifetimeLoss,
    required this.unrealizedPnl,
    required this.winDays,
    required this.lossDays,
    required this.buyCount,
    required this.sellCount,
    required this.openCount,
    required this.buyVolume,
    required this.sellVolume,
    required this.chart,
  });

  factory _FData.fromJson(Map<String, dynamic> j) {
    final pc = (j['period_changes'] as Map<String, dynamic>?) ?? {};
    final d7 = (pc['7D'] as Map?) ?? {};
    final d30 = (pc['30D'] as Map?) ?? {};
    return _FData(
      todayPnl: _d(j['today_pnl']),
      todayPct: _d(j['today_pct']),
      todayRealizedPnl: _d(j['today_realized_pnl']),
      todayUnrealizedPnl: _d(j['today_unrealized_pnl']),
      currentBalance: _d(j['current_balance']),
      availableBalance: _d(j['available_balance']),
      sevenDPnl: _d(d7['change_abs']),
      sevenDPct: _d(d7['change_pct']),
      thirtyDPnl: _d(d30['change_abs']),
      thirtyDPct: _d(d30['change_pct']),
      lifetimePnl: _d(j['lifetime_pnl']),
      lifetimeProfit: _d(j['lifetime_profit']),
      lifetimeLoss: _d(j['lifetime_loss']),
      unrealizedPnl: _d(j['total_unrealized_pnl']),
      winDays: (j['win_days'] as num?)?.toInt() ?? 0,
      lossDays: (j['loss_days'] as num?)?.toInt() ?? 0,
      buyCount: (j['buy_count'] as num?)?.toInt() ?? 0,
      sellCount: (j['sell_count'] as num?)?.toInt() ?? 0,
      openCount: (j['open_positions_count'] as num?)?.toInt() ?? 0,
      buyVolume: _d(j['buy_volume']),
      sellVolume: _d(j['sell_volume']),
      chart: ((j['chart_data'] as List?) ?? [])
          .map(
            (e) => _Pt(
              date: e['date']?.toString() ?? '',
              value: _d(e['value']),
              pnl: _d(e['pnl']),
            ),
          )
          .toList(),
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class FuturePnlScreen extends StatefulWidget {
  const FuturePnlScreen({super.key});
  @override
  State<FuturePnlScreen> createState() => _State();
}

class _State extends State<FuturePnlScreen> {
  _FData? _data;
  bool _loading = true;
  String _range = '24h';
  bool _more = false;
  bool _hide = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final uid = gUserRx.value.id;
      if (uid == 0) {
        setState(() => _loading = false);
        return;
      }
      final res = await http.get(
        Uri.parse('${APIURLConstants.baseUrl}/api/future/pnl?user_id=$uid'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['success'] == true && j['data'] != null) {
          setState(
            () => _data = _FData.fromJson(j['data'] as Map<String, dynamic>),
          );
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  // n = range==="24h"?1 : range==="7D"?7 : range==="30D"?30 : 90
  int get _rangeN => _range == '24h'
      ? 1
      : _range == '7D'
      ? 7
      : _range == '30D'
      ? 30
      : 90;

  List<_Pt> get _slice {
    if (_data == null) return [];
    final c = _data!.chart;
    final n = _rangeN;
    return c.length > n ? c.sublist(c.length - n) : List<_Pt>.from(c);
  }

  List<double> get _dailyDiff {
    final s = _slice;
    if (s.isEmpty) return [];
    return List.generate(
      s.length,
      (i) => i == 0 ? 0.0 : s[i].value - s[i - 1].value,
    );
  }

  List<double> get _netWorth => _slice.map((e) => e.value).toList();

  List<double> get _profitsDiff {
    final s = _slice;
    if (s.length < 2) return [];
    return s.map((e) => e.value - s.first.value).toList();
  }

  List<double> get _cumPct {
    final s = _slice;
    if (s.isEmpty) return [];
    final base = s.first.value == 0 ? 1.0 : s.first.value;
    return s.map((e) => ((e.value - base) / base) * 100).toList();
  }

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

  double get _totalProfit =>
      _dailyDiff.where((v) => v > 0).fold(0.0, (a, b) => a + b);
  double get _totalLoss =>
      _dailyDiff.where((v) => v < 0).fold(0.0, (a, b) => a + b.abs());
  double get _netPL => _totalProfit - _totalLoss;

  String _fmtPct(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
  String _fmtAbs(double v) =>
      '${v >= 0 ? '+' : ''}\$${v.abs().toStringAsFixed(2)} USDT';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: RefreshIndicator(
        color: _lime,
        backgroundColor: _bg,
        onRefresh: () async {
          await _fetch();
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerBar(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heroCard(),
                    const SizedBox(height: 20),
                    _dailyPnlCard(),
                    const SizedBox(height: 20),
                    _profitsCard(),
                    const SizedBox(height: 20),
                    _netWorthCard(),
                    const SizedBox(height: 20),
                    _cumPnlCard(),
                    const SizedBox(height: 20),
                    _holdingsSection(),
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
      color: _bg,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 50),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back, color: _white, size: 20),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Text(
              'Future PNL Analysis',
              style: TextStyle(
                color: _white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: _dm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Card ─────────────────────────────────────────────────────────────
  Widget _heroCard() {
    final d = _data;
    final sevenDPct = d?.sevenDPct ?? 0;
    final sevenDPnl = d?.sevenDPnl ?? 0;
    final thirtyDPct = d?.thirtyDPct ?? 0;
    final thirtyDPnl = d?.thirtyDPnl ?? 0;
    final lifetimePnl = d?.lifetimePnl ?? 0;
    final totalBalance = d?.currentBalance ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x331A1A1A), Color(0xFF111111)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: const Border(
          top: BorderSide(color: Colors.white, width: 1),
          bottom: BorderSide(color: Colors.white, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Total Value (USDT)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: _dm,
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
                  size: 16,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _loading
              ? _Sk(h: 42, w: 200)
              : Text(
                  _hide ? '****' : '\$${totalBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    fontFamily: _dm,
                  ),
                ),
          const SizedBox(height: 5),
          _loading
              ? _Sk(h: 14, w: 120)
              : Text(
                  _hide ? '≈ ****' : '≈ \$${totalBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: _dm,
                    fontWeight: FontWeight.w400,
                  ),
                ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _pnlCol(
                  '7D PNL',
                  sevenDPct,
                  sevenDPnl,
                  align: CrossAxisAlignment.center,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.5),
              ),
              Expanded(
                child: _pnlCol(
                  '30D PNL',
                  thirtyDPct,
                  thirtyDPnl,
                  align: CrossAxisAlignment.center,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.5),
              ),
              Expanded(
                child: _pnlCol(
                  'Lifetime PNL',
                  0,
                  lifetimePnl,
                  align: CrossAxisAlignment.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _rangeTabs(),
          const SizedBox(height: 20),
          _plRow(
            'Total Profit',
            '+\$${_totalProfit.toStringAsFixed(2)} USD',
            _green,
          ),
          const SizedBox(height: 10),
          _plRow('Total Loss', '\$${_totalLoss.toStringAsFixed(2)} USD', _red),
          const SizedBox(height: 10),
          _plRow(
            'Net Profit/Loss',
            '\$${_netPL.abs().toStringAsFixed(2)} USD',
            _netPL >= 0 ? _green : _red,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _more = !_more),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _more ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: _white,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _more ? 'Less' : 'More',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 12,
                      fontFamily: _dm,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_more) ...[const SizedBox(height: 0), _statGrid()],
        ],
      ),
    );
  }

  Widget _pnlCol(
    String label,
    double pct,
    double abs, {
    CrossAxisAlignment align = CrossAxisAlignment.start,
    bool hidePct = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              fontFamily: _dm,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          if (!hidePct)
            _loading
                ? _Sk(h: 18, w: 60)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      pct == 0 ? '+0.00%' : _fmtPct(pct),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: pct >= 0 ? _green : _red,
                        fontFamily: _dm,
                      ),
                    ),
                  ),
          const SizedBox(height: 5),
          _loading
              ? _Sk(h: 12, w: 80)
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _hide ? '****' : _fmtAbs(abs),
                    style: TextStyle(
                      fontSize: 12,
                      color: abs >= 0 ? _green50 : _red.withValues(alpha: 0.5),
                      fontFamily: _dm,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _plRow(String label, String val, Color color) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withOpacity(0.5),
          fontFamily: _dm,
          fontWeight: FontWeight.w400,
        ),
      ),
      _loading
          ? _Sk(h: 14, w: 120)
          : Flexible(
              child: Text(
                _hide ? '****' : val,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: _dm,
                ),
                textAlign: TextAlign.right,
              ),
            ),
    ],
  );

  Widget _statGrid() {
    final d = _data;
    final daily = _dailyDiff;
    final avgD = daily.isNotEmpty
        ? (daily.reduce((a, b) => a + b) / daily.length).toStringAsFixed(4)
        : '0.0000';
    final best = daily.isNotEmpty
        ? daily.reduce(math.max).toStringAsFixed(4)
        : '0.0000';
    final stats = [
      ['Win Days', '${d?.winDays ?? 0}', _white],
      ['Loss Days', '${d?.lossDays ?? 0}', _white],
      ['Avg Daily PNL', avgD, _white],
      ['Best Day', best, _white],
      ['Total Buys', '${d?.buyCount ?? 0}', _white],
      ['Total Sells', '${d?.sellCount ?? 0}', _white],
      ['Buy Volume', '\$${(d?.buyVolume ?? 0).toStringAsFixed(2)}', _white],
      ['Sell Volume', '\$${(d?.sellVolume ?? 0).toStringAsFixed(2)}', _white],
      ['Open Positions', '${d?.openCount ?? 0}', _white],
      [
        'Unrealized PNL',
        '+${(d?.unrealizedPnl ?? 0).toStringAsFixed(4)} USD',
        _green,
      ],
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3.2,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final s = stats[i];
        return Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  s[0] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w400,
                    fontFamily: _dm,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              _loading
                  ? _Sk(h: 14, w: 50)
                  : Flexible(
                      child: Text(
                        s[1] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: s[2] as Color,
                          fontFamily: _dm,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  // ── Range Tabs ────────────────────────────────────────────────────────────
  Widget _rangeTabs() => Row(
    children: ['24h', '7D', '30D', '90D'].map((r) {
      final on = r == _range;
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: () => setState(() => _range = r),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: on ? _lime : const Color(0xFF111111),
              borderRadius: BorderRadius.circular(5),
              border: on ? null : Border.all(color: Colors.transparent),
            ),
            child: Text(
              r,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: on ? const Color(0xFF111111) : Colors.white,
                fontFamily: _dm,
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );

  // ── Daily PNL Bars Card ───────────────────────────────────────────────────
  Widget _dailyPnlCard() {
    final daily = _dailyDiff;
    final last = daily.isNotEmpty ? daily.last : 0.0;
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
                  color: _white,
                  fontFamily: _dm,
                ),
              ),
              Text(
                _ld,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                  fontFamily: _dm,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _loading
              ? _Sk(h: 32, w: 130)
              : Text(
                  '${last >= 0 ? '+' : ''}\$${last.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: last >= 0 ? _green : _red,
                    fontFamily: _dm,
                  ),
                ),
          const SizedBox(height: 20),
          _loading
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
                style: TextStyle(fontSize: 11, color: _w50, fontFamily: _dm),
              ),
              Text(
                'Day ${_slice.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                  fontFamily: _dm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Profits Card ──────────────────────────────────────────────────────────
  Widget _profitsCard() {
    final diff = _profitsDiff;
    final val = diff.isNotEmpty ? diff.last : 0.0;
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
                  color: _white,
                  fontFamily: _dm,
                ),
              ),
              Text(
                '$_fd - $_ld',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                  fontFamily: _dm,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _loading
              ? _Sk(h: 32, w: 130)
              : Text(
                  '${val >= 0 ? '+' : ''}\$${val.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: val >= 0 ? _green : _red,
                    fontFamily: _dm,
                  ),
                ),
          const SizedBox(height: 20),
          _loading
              ? _Sk(h: 150, r: 8)
              : diff.length < 2
              ? _noData()
              : _AreaChart(data: diff, height: 150),
        ],
      ),
    );
  }

  // ── Asset Net Worth Card ──────────────────────────────────────────────────
  Widget _netWorthCard() {
    final nw = _netWorth;
    final last = nw.isNotEmpty ? nw.last : (_data?.currentBalance ?? 0);
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
                  color: _white,
                  fontFamily: _dm,
                ),
              ),
              Text(
                '$_fd - $_ld',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                  fontFamily: _dm,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _loading
              ? _Sk(h: 28, w: 130)
              : Text(
                  '\$${last.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _white,
                    fontFamily: _dm,
                  ),
                ),
          const SizedBox(height: 20),
          _loading
              ? _Sk(h: 150, r: 8)
              : nw.length < 2
              ? _noData()
              : _AreaChart(data: nw, height: 150),
        ],
      ),
    );
  }

  // ── Cumulative PNL% Card ──────────────────────────────────────────────────
  Widget _cumPnlCard() {
    final cum = _cumPct;
    final btc = _btcTrend;
    final cumLast = cum.isNotEmpty ? cum.last : 0.0;
    final btcLast = btc.isNotEmpty ? btc.last : 0.0;

    String topL = '', midL = '', botL = '';
    if (cum.isNotEmpty && btc.isNotEmpty) {
      final all = [...cum, ...btc];
      final mx = all.reduce(math.max), mn = all.reduce(math.min);
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
                  color: _white,
                  fontFamily: _dm,
                ),
              ),
              Flexible(
                child: Text(
                  '$_fd - $_ld',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w400,
                    fontFamily: _dm,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _loading
                        ? _Sk(h: 24, w: 80)
                        : Text(
                            '${cumLast >= 0 ? '+' : ''}${cumLast.toStringAsFixed(2)}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEBE400),
                              fontFamily: _dm,
                            ),
                          ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(width: 5, height: 2, color: _yellow),
                        const SizedBox(width: 4),
                        Text(
                          'Cumulative PNL',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.w400,
                            fontFamily: _dm,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _loading
                        ? _Sk(h: 24, w: 80)
                        : Text(
                            '${btcLast >= 0 ? '+' : ''}${btcLast.toStringAsFixed(2)}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F46FF),
                              fontFamily: _dm,
                            ),
                          ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(width: 5, height: 2, color: _blue),
                        const SizedBox(width: 4),
                        Text(
                          'BTC Benchmark',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.w400,
                            fontFamily: _dm,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _loading
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
                                  fontFamily: _dm,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: _DualChart(d1: cum, d2: btc, height: 150),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // ── Asset Summary — website style: single USDT row from _data ────────────
  Widget _holdingsSection() {
    // Website: shows futures wallet balance as a single USDT coin row
    final availBal = _data?.availableBalance ?? 0;
    final currentBal = _data?.currentBalance ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Future Holdings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _white,
            fontFamily: _dm,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(0),
          ),
          child: _loading
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: _Sk(h: 54, r: 8),
                )
              : currentBal <= 0 && availBal <= 0
              ? _noData(msg: 'No futures assets found')
              : _assetRow(
                  coinType: 'USDT',
                  label: 'Futures Wallet',
                  balance: availBal,
                  usdVal: currentBal > 0 ? currentBal : availBal,
                ),
        ),
      ],
    );
  }

  Widget _assetRow({
    required String coinType,
    required String label,
    required double balance,
    required double usdVal,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Coin circle with default app icon — padded so corners don't clip
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.transparent),
            ),
            child: Image.asset('assets/images/icon.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: coinType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: _white,
                          fontFamily: _dm,
                        ),
                      ),
                      TextSpan(
                        text: '/USDT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.5), // alag color
                          fontFamily: _dm,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w400,
                    fontFamily: _dm,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _hide ? '****' : balance.toStringAsFixed(4),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _white,
                      fontFamily: _dm,
                    ),
                  ),
                  Text(
                    _hide ? '≈ ****' : '≈\$${usdVal.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w400,
                      fontFamily: _dm,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 10),

              Container(
                width: 70,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  widthFactor: 1.0,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _lime,
                      borderRadius: BorderRadius.circular(2),
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

  Widget _noData({String msg = 'No data for this period'}) => SizedBox(
    height: 80,
    child: Center(
      child: Text(
        msg,
        style: TextStyle(color: _w50, fontSize: 13, fontFamily: _dm),
      ),
    ),
  );
}

// ── Widgets ───────────────────────────────────────────────────────────────────
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
      color: Colors.white12,
      borderRadius: BorderRadius.circular(r),
    ),
  );
}

// ── Area Chart — uses LayoutBuilder so width is always constrained ────────────
class _AreaChart extends StatelessWidget {
  const _AreaChart({required this.data, this.height = 150});
  final List<double> data;
  final double height;
  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return SizedBox(height: height);
    return LayoutBuilder(
      builder: (_, constraints) => SizedBox(
        width: constraints.maxWidth,
        height: height,
        child: CustomPaint(painter: _AreaPainter(data: data)),
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
    const padY = 10.0;

    final indexed = <MapEntry<int, double>>[];
    for (int i = 0; i < data.length; i++) {
      if (data[i] != 0 || i == 0) indexed.add(MapEntry(i, data[i]));
    }
    if (indexed.length < 2) return;

    final vals = indexed.map((e) => e.value).toList();
    final rawMn = vals.reduce(math.min);
    final rawMx = vals.reduce(math.max);
    final mn = rawMn >= 0 ? rawMn * 0.90 : rawMn * 1.10;
    final mx = rawMx >= 0 ? rawMx * 1.02 : rawMx * 0.98;
    final rng = (mx - mn) < 0.001 ? 1.0 : mx - mn;

    final total = math.max(data.length - 1, 1);
    double toX(int origIdx) => (origIdx / total) * W;
    double toY(double v) => H - padY - ((v - mn) / rng) * (H - padY * 2);

    final pts = indexed.map((e) => Offset(toX(e.key), toY(e.value))).toList();
    final linePath = _cr(pts);

    final fill = Path.from(linePath)
      ..lineTo(pts.last.dx, H)
      ..lineTo(pts.first.dx, H)
      ..close();
    canvas.drawPath(fill, Paint()..color = _fill);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = _stroke
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final baseY = toY(indexed.first.value);
    canvas.drawLine(
      Offset(0, baseY),
      Offset(W, baseY),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 1,
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

// ── Dual Line Chart — uses LayoutBuilder ──────────────────────────────────────
class _DualChart extends StatelessWidget {
  const _DualChart({required this.d1, required this.d2, this.height = 150});
  final List<double> d1, d2;
  final double height;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => SizedBox(
      width: constraints.maxWidth,
      height: height,
      child: CustomPaint(
        painter: _DualPainter(d1: d1, d2: d2),
      ),
    ),
  );
}

class _DualPainter extends CustomPainter {
  const _DualPainter({required this.d1, required this.d2});
  final List<double> d1, d2;
  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width, H = size.height;
    const padY = 8.0;
    final all = [...d1, ...d2];
    final rawMn = all.reduce(math.min), rawMx = all.reduce(math.max);
    final mn = rawMn >= 0 ? rawMn * 0.90 : rawMn * 1.10;
    final mx = rawMx >= 0 ? rawMx * 1.02 : rawMx * 0.98;
    final rng = (mx - mn) < 0.001 ? 1.0 : mx - mn;
    double toX(int i, int len) => (i / math.max(len - 1, 1)) * W;
    double toY(double v) => H - padY - ((v - mn) / rng) * (H - padY * 2);

    Path cr(List<double> d) {
      final pts = List.generate(
        d.length,
        (i) => Offset(toX(i, d.length), toY(d[i])),
      );
      final p = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 0; i < pts.length - 1; i++) {
        final p0 = pts[math.max(i - 1, 0)],
            p1 = pts[i],
            p2 = pts[i + 1],
            p3 = pts[math.min(i + 2, pts.length - 1)];
        p.cubicTo(
          p1.dx + (p2.dx - p0.dx) / 6,
          p1.dy + (p2.dy - p0.dy) / 6,
          p2.dx - (p3.dx - p1.dx) / 6,
          p2.dy - (p3.dy - p1.dy) / 6,
          p2.dx,
          p2.dy,
        );
      }
      return p;
    }

    if (d1.length >= 2) {
      final path = cr(d1);
      final pts1 = List.generate(
        d1.length,
        (i) => Offset(toX(i, d1.length), toY(d1[i])),
      );
      final fill = Path.from(path)
        ..lineTo(pts1.last.dx, H)
        ..lineTo(pts1.first.dx, H)
        ..close();
      canvas.drawPath(fill, Paint()..color = _fill);
      canvas.drawPath(
        path,
        Paint()
          ..color = _yellow
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

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

// ── Bar Chart — uses LayoutBuilder ────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  const _BarChart({required this.data, this.height = 130});
  final List<double> data;
  final double height;
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);
    return LayoutBuilder(
      builder: (_, constraints) => SizedBox(
        width: constraints.maxWidth,
        height: height,
        child: CustomPaint(painter: _BarPainter(data: data)),
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
    if (maxAbs == 0) return;
    final midY = H * 0.55;
    final barW = math.max(4.0, (W / data.length) - 2);
    canvas.drawLine(
      Offset(0, midY),
      Offset(W, midY),
      Paint()
        ..color = Colors.transparent
        ..strokeWidth = 1,
    );
    for (int i = 0; i < data.length; i++) {
      final v = data[i];
      if (v.abs() < 0.01) continue;
      final bh = math.max(4.0, (v.abs() / maxAbs) * (midY - 6));
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
