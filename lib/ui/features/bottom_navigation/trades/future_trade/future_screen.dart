import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/earn/earn_screen.dart';
// import 'package:tradexpro_flutter/addons/p2p_trade/ui/p2p_trade_screen.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/trades/trapix_chart_widget.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'future_chart_widget.dart';
import 'future_controller.dart';
import 'future_models.dart';
import 'future_widgets.dart';

class NewFutureScreen extends StatefulWidget {
  const NewFutureScreen({super.key, this.showTopTabs = true});
  final bool showTopTabs;

  @override
  State<NewFutureScreen> createState() => _NewFutureScreenState();
}

class _NewFutureScreenState extends State<NewFutureScreen> {
  late final NewFutureController _ctrl;

  String _subTab = 'Future';
  String _buySell = 'Buy';
  String _orderType = 'limit';
  String _marginMode = 'isolated';
  int _leverage = 20;
  String _qty = '';
  String _limitPx = '';
  String _triggerPx = '';
  double _sliderPct = 0;
  bool _showTpSl = false;
  String _tp = '';
  String _sl = '';

  late final TextEditingController _limitPxCtrl;
  final FocusNode _limitPxFocus = FocusNode();
  bool _limitPxUserEdited = false;
  Worker? _priceWorker;

  String _bottomTab = 'Position';
  bool _showChart = false;
  bool _isFavourite = false;
  bool _showMarginModal = false;
  bool _showLevModal = false;
  bool _showOrderTypeDropdown = false;
  String _bookFilter = 'all';
  String _bookPrecision = '0.01';

  String _countdown = '00:00:00';
  Timer? _countdownTimer;
  OverlayEntry? _precisionEntry;

  static const _topTabs = ['Future', 'Earn', /*'P2P',*/ 'Copy Trading', 'Option'];

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(NewFutureController());
    _limitPxCtrl = TextEditingController();
    _limitPxFocus.addListener(() {
      if (!_limitPxFocus.hasFocus) _limitPxUserEdited = false;
    });
    _priceWorker = ever(_ctrl.currentPair, (FuturePair? pair) {
      if (pair == null) return;
      if ((_orderType == 'limit' || _orderType == 'stop_limit') && !_limitPxFocus.hasFocus && !_limitPxUserEdited) {
        final formatted = pair.currentPrice.toStringAsFixed(pair.pricePrecision);
        _limitPxCtrl.text = formatted;
        setState(() => _limitPx = formatted);
      }
    });
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _limitPxCtrl.dispose();
    _limitPxFocus.dispose();
    _priceWorker?.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final period = 8 * 3600 * 1000;
    final target = ((now / period).ceil() * period).toInt();
    final diff = math.max(0, target - now);
    final h = diff ~/ 3600000;
    final m = (diff % 3600000) ~/ 60000;
    final s = (diff % 60000) ~/ 1000;
    if (mounted) setState(() => _countdown = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}');
  }

  void _applyPct(double pct) {
    final pair = _ctrl.currentPair.value;
    final qp = pair?.quantityPrecision ?? 4;
    final markPrice = pair?.currentPrice ?? 0;
    final activePrice = (_orderType == 'limit' || _orderType == 'stop_limit') && double.tryParse(_limitPx) != null && double.parse(_limitPx) > 0
        ? double.parse(_limitPx)
        : markPrice;
    setState(() {
      _sliderPct = pct;
      final m = _ctrl.balance.value * (pct / 100);
      _qty = (m > 0 && activePrice > 0) ? ((m * _leverage) / activePrice).toStringAsFixed(qp) : '';
    });
  }

  Future<void> _placeOrder(FuturePair? pair, double marginVal) async {
    if (!_ctrl.isLoggedIn.value) { _showSnack('Please login to place an order', isError: true); return; }
    if (pair == null) return;
    final qtyD = double.tryParse(_qty) ?? 0;
    if (qtyD <= 0) { _showSnack('Please enter a valid quantity', isError: true); return; }
    if (_orderType == 'limit' && (double.tryParse(_limitPx) ?? 0) <= 0) { _showSnack('Please enter a valid limit price', isError: true); return; }
    if (_orderType == 'stop_limit' && ((double.tryParse(_triggerPx) ?? 0) <= 0 || (double.tryParse(_limitPx) ?? 0) <= 0)) {
      _showSnack('Please enter valid trigger and limit price', isError: true);
      return;
    }
    final success = await _ctrl.placeOrder(
      symbol: pair.symbol,
      side: _buySell == 'Buy' ? 'long' : 'short',
      leverage: _leverage,
      margin: marginVal,
      quantity: qtyD,
      orderType: _orderType,
      price: _orderType == 'market' ? 0 : (double.tryParse(_limitPx) ?? 0),
      marginMode: _marginMode,
      takeProfit: _showTpSl && _tp.isNotEmpty ? double.tryParse(_tp) : null,
      stopLoss: _showTpSl && _sl.isNotEmpty ? double.tryParse(_sl) : null,
      stopPrice: _orderType == 'stop_limit' ? double.tryParse(_triggerPx) : null,
    );
    if (success) {
      setState(() { _qty = ''; _sliderPct = 0; _tp = ''; _sl = ''; _triggerPx = ''; });
      _showSnack('Position opened successfully');
    } else {
      final errMsg = _ctrl.lastError.isNotEmpty ? _ctrl.lastError : 'Order failed. Please try again.';
      _showSnack(errMsg, isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: futureDmSans)),
      backgroundColor: isError ? futureRed : futureGreen,
      duration: const Duration(seconds: 2),
    ));
  }

  void _openPrecisionDropdown(BuildContext btnCtx) {
    _precisionEntry?.remove();
    _precisionEntry = null;
    final RenderBox box = btnCtx.findRenderObject() as RenderBox;
    final Offset origin = box.localToGlobal(Offset.zero);
    final items = ['0.01', '0.1', '1'];
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => Stack(children: [
      Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () { entry.remove(); _precisionEntry = null; })),
      Positioned(
        left: origin.dx, top: origin.dy + box.size.height + 4, width: box.size.width,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
            child: Column(mainAxisSize: MainAxisSize.min, children: items.map((v) {
              final selected = v == _bookPrecision;
              return GestureDetector(
                onTap: () { setState(() => _bookPrecision = v); entry.remove(); _precisionEntry = null; },
                child: Container(
                  height: 32, alignment: Alignment.center,
                  decoration: BoxDecoration(color: selected ? const Color(0xFF00B052) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                  child: Text(v, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.white.withValues(alpha: 0.5), fontFamily: futureDmSans)),
                ),
              );
            }).toList()),
          ),
        ),
      ),
    ]));
    _precisionEntry = entry;
    Overlay.of(btnCtx).insert(entry);
  }

  Widget _buildPrecisionDropdown() {
    return Builder(builder: (btnCtx) => GestureDetector(
      onTap: () => _openPrecisionDropdown(btnCtx),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_bookPrecision, style: const TextStyle(fontSize: 12, color: futureTextWhite, fontFamily: futureDmSans)),
          Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.5), size: 18),
        ]),
      ),
    ));
  }

  Widget _buildDotToggle() {
    String asset;
    if (_bookFilter == 'buy') asset = 'assets/icons/greendot.png';
    else if (_bookFilter == 'sell') asset = 'assets/icons/reddot.png';
    else asset = 'assets/icons/dot.png';
    return GestureDetector(
      onTap: () => setState(() {
        if (_bookFilter == 'all') _bookFilter = 'buy';
        else if (_bookFilter == 'buy') _bookFilter = 'sell';
        else _bookFilter = 'all';
      }),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
        child: Center(child: Image.asset(asset, width: 20, height: 20, fit: BoxFit.contain)),
      ),
    );
  }

  Widget _buildTopTabs() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: _topTabs.map((tab) {
          final active = _subTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _subTab = tab),
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(tab, style: TextStyle(fontSize: 16, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: active ? futureTextWhite : Colors.white.withValues(alpha: 0.5), fontFamily: futureDmSans)),
            ),
          );
        }).toList()),
      ),
    );
  }

  Widget _buildCoinInfoBar(FuturePair? pair, int pp) {
    final change = pair?.priceChange24h ?? 0;
    final changeColor = change >= 0 ? const Color(0xFF007958) : const Color(0xFFD05850);
    final symbol = (pair?.symbol ?? 'BTCUSDT').replaceAll('/', '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.transparent,
      child: Row(children: [
        GestureDetector(
          onTap: () => FuturePairDrawer.show(context, _ctrl, (pair, limitPx, leverage) { _ctrl.selectPair(pair); setState(() { _limitPx = limitPx; _leverage = leverage; }); }),
          child: Row(children: [
            Image.asset('assets/icons/menu.png', width: 16, height: 16),
            const SizedBox(width: 10),
            Text(symbol, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: futureTextWhite, fontFamily: futureDmSans)),
            const SizedBox(width: 5),
            Text('Perp', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w400, fontFamily: futureDmSans)),
            const SizedBox(width: 5),
            Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: changeColor, fontFamily: futureDmSans)),
          ]),
        ),
        const Spacer(),
        InkWell(onTap: () => setState(() => _isFavourite = !_isFavourite), child: Padding(padding: const EdgeInsets.all(10), child: Image.asset('assets/icons/star.png', width: 20, height: 20))),
        InkWell(onTap: () => setState(() => _showChart = !_showChart), child: Padding(padding: const EdgeInsets.all(10), child: Image.asset('assets/icons/bar.png', width: 20, height: 20))),
        InkWell(onTap: () => Get.to(() => FutureChartScreen(ctrl: _ctrl)), child: Padding(padding: const EdgeInsets.all(10), child: Image.asset('assets/icons/candel.png', width: 20, height: 20))),
      ]),
    );
  }

  Widget _buildAnnouncement() {
    return const _FutureMarqueeTicker();
  }

  Map<String, dynamic> _processOrderBook(List<List<String>> rawBids, List<List<String>> rawAsks, int pp, int qp, int maxRows) {
    final bidsSorted = [...rawBids]..sort((a, b) => double.parse(b[0]).compareTo(double.parse(a[0])));
    final asksSorted = [...rawAsks]..sort((a, b) => double.parse(a[0]).compareTo(double.parse(b[0])));
    final bidsSlice = bidsSorted.take(maxRows).toList();
    final asksSlice = asksSorted.take(maxRows).toList();

    double bidCum = 0;
    final bids = bidsSlice.map((b) {
      bidCum += double.tryParse(b[1]) ?? 0;
      return {'price': double.tryParse(b[0])?.toStringAsFixed(pp) ?? b[0], 'amount': double.tryParse(b[1])?.toStringAsFixed(qp) ?? b[1], 'cum': bidCum};
    }).toList();
    final maxBidCum = bidCum > 0 ? bidCum : 1.0;
    for (final b in bids) { b['pct'] = (b['cum'] as double) / maxBidCum * 100; }

    double askCum = 0;
    final asks = asksSlice.map((a) {
      askCum += double.tryParse(a[1]) ?? 0;
      return {'price': double.tryParse(a[0])?.toStringAsFixed(pp) ?? a[0], 'amount': double.tryParse(a[1])?.toStringAsFixed(qp) ?? a[1], 'cum': askCum};
    }).toList();
    final maxAskCum = askCum > 0 ? askCum : 1.0;
    for (final a in asks) { a['pct'] = (a['cum'] as double) / maxAskCum * 100; }

    return {'bids': bids, 'asks': asks};
  }

  Widget _buildMain() {
    return Obx(() {
      final pair = _ctrl.currentPair.value;
      final markPrice = pair?.currentPrice ?? 0;
      final pp = pair?.pricePrecision ?? 2;
      final qp = pair?.quantityPrecision ?? 4;
      final bookRows = _bookFilter == 'all' ? 8 : 15;

      final rawBids = _ctrl.orderBookBids;
      final rawAsks = _ctrl.orderBookAsks;
      final processed = _processOrderBook(rawBids, rawAsks, pp, qp, bookRows);
      final bids = processed['bids'] as List<Map<String, dynamic>>;
      final asks = processed['asks'] as List<Map<String, dynamic>>;
      final asksReversed = asks.reversed.toList();

      final activePrice = (_orderType == 'limit' || _orderType == 'stop_limit') && double.tryParse(_limitPx) != null && double.parse(_limitPx) > 0
          ? double.parse(_limitPx) : markPrice;
      final qtyD = double.tryParse(_qty) ?? 0;
      final marginVal = activePrice > 0 && qtyD > 0 ? (qtyD * activePrice) / _leverage : 0.0;
      final fee = marginVal * _leverage * ((pair?.takerFee ?? 0.05) / 100);
      final cost = (marginVal + fee).toStringAsFixed(2);
      final maxQty = activePrice > 0 ? (_ctrl.balance.value * _leverage / activePrice).toStringAsFixed(qp) : '0.0000';

      if (_subTab == 'Earn') return Column(children: [if (widget.showTopTabs) _buildTopTabs(), const Expanded(child: EarnScreen())]);
      // if (_subTab == 'P2P') return Column(children: [if (widget.showTopTabs) _buildTopTabs(), const Expanded(child: P2PTradeScreen())]);
      if (_subTab == 'Copy Trading' || _subTab == 'Option') {
        return Column(children: [
          if (widget.showTopTabs) _buildTopTabs(),
          Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.construction_rounded, size: 48, color: futureMuted),
            const SizedBox(height: 12),
            Text('$_subTab Coming Soon', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: futureMuted, fontFamily: futureDmSans)),
          ]))),
        ]);
      }

      final colWidth = (MediaQuery.of(context).size.width - 24) * 0.42;

      return Container(
        color: const Color(0xFF111111),
        child: Column(children: [
          if (widget.showTopTabs) _buildTopTabs(),
          const SizedBox(height: 0),
          _buildCoinInfoBar(pair, pp),
          if (_showChart) TrapixChartWidget(symbol: (pair?.symbol ?? 'BTCUSDT').replaceAll('/', ''), height: MediaQuery.of(context).size.width * 0.75, isFuture: true),
          _buildAnnouncement(),
          Expanded(child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: colWidth,
                    child: FutureOrderBook(
                      asks: asksReversed, bids: bids, markPrice: markPrice, pp: pp,
                      quote: pair?.quoteCurrency ?? 'USDT', base: pair?.baseCurrency ?? 'BTC', change: pair?.priceChange24h ?? 0,
                      isUp: (pair?.priceChange24h ?? 0) >= 0,
                      bookFilter: _bookFilter, countdown: _countdown, columnWidth: colWidth,
                      onPriceTap: (v) { _limitPxCtrl.text = v; _limitPxUserEdited = true; setState(() => _limitPx = v); },
                      precisionDropdown: _buildPrecisionDropdown(),
                      dotToggle: _buildDotToggle(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: FutureTradeForm(
                    pair: pair, pp: pp, qp: qp,
                    base: pair?.baseCurrency ?? 'BTC', quote: pair?.quoteCurrency ?? 'USDT',
                    activePrice: activePrice, marginVal: marginVal, cost: cost, maxQty: maxQty,
                    buySell: _buySell, orderType: _orderType, marginMode: _marginMode,
                    leverage: _leverage, qty: _qty, limitPx: _limitPx, triggerPx: _triggerPx,
                    sliderPct: _sliderPct, showTpSl: _showTpSl, tp: _tp, sl: _sl,
                    showOrderTypeDropdown: _showOrderTypeDropdown,
                    limitPxCtrl: _limitPxCtrl, limitPxFocus: _limitPxFocus,
                    limitPxUserEdited: _limitPxUserEdited, ctrl: _ctrl,
                    onQtyChanged: (v) => setState(() => _qty = v),
                    onLimitPxChanged: (v) => setState(() => _limitPx = v),
                    onTriggerPxChanged: (v) => setState(() => _triggerPx = v),
                    onTpChanged: (v) => setState(() => _tp = v),
                    onSlChanged: (v) => setState(() => _sl = v),
                    onTpSlToggle: (v) => setState(() => _showTpSl = v),
                    onOrderTypeDropdownToggle: (v) => setState(() => _showOrderTypeDropdown = v),
                    onOrderTypeChanged: (v) => setState(() => _orderType = v),
                    onSliderPct: _applyPct,
                    onMarginModeTap: () => setState(() => _showMarginModal = true),
                    onLeverageTap: () => setState(() => _showLevModal = true),
                    onBuySellChanged: (v) => setState(() => _buySell = v),
                    onPlaceOrder: () => _placeOrder(pair, marginVal),
                  )),
                ]),
              ),
              FuturePositionsSection(
                pair: pair, pp: pp, bottomTab: _bottomTab, ctrl: _ctrl,
                onTabChanged: (t) => setState(() => _bottomTab = t),
                onTpSlTap: (pos) => FutureTpSlModal.show(context, pos, pp, _ctrl),
                onLeverageTap: () => setState(() => _showLevModal = true),
              ),
            ]),
          )),
        ]),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Stack(children: [
          _buildMain(),
          if (_showMarginModal) FutureOverlayModal(
            onDismiss: () => setState(() { _showMarginModal = false; _showLevModal = false; }),
            content: FutureMarginModeModal(marginMode: _marginMode, ctrl: _ctrl, onSelected: (mode) => setState(() { _marginMode = mode; _showMarginModal = false; })),
          ),
          if (_showLevModal) FutureOverlayModal(
            onDismiss: () => setState(() { _showMarginModal = false; _showLevModal = false; }),
            content: FutureLeverageModal(leverage: _leverage, onSelected: (val) => setState(() { _leverage = val; _showLevModal = false; })),
          ),
        ]),
      ),
    );
  }
}

// ── Full chart screen (opened via Get.to from candle icon) ───────────────────
class FutureChartScreen extends StatefulWidget {
  const FutureChartScreen({super.key, required this.ctrl});
  final NewFutureController ctrl;

  @override
  State<FutureChartScreen> createState() => _FutureChartScreenState();
}

class _FutureChartScreenState extends State<FutureChartScreen> {
  NewFutureController get _ctrl => widget.ctrl;
  String _chartSubTab = 'Chart';
  String _unifiedTab = 'Order Book';

  Widget _buildPriceView(FuturePair? pair, String countdown) {
    final pp = pair?.pricePrecision ?? 2;
    final change = pair?.priceChange24h ?? 0;
    final isUp = change >= 0;
    final priceColor = isUp ? gBuyColor : gSellColor;
    final markPrice = pair?.currentPrice ?? 0;
    final base = pair?.baseCurrency ?? 'BTC';
    final quote = pair?.quoteCurrency ?? 'USDT';
    final fundingPct = '${((pair?.fundingRate ?? 0.0001) * 100).toStringAsFixed(4)}%';
    final vol24h = pair?.volume24h ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 6,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(color: priceColor, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: futureDmSans, height: 32 / 24),
                  child: Text(markPrice.toStringAsFixed(pp), maxLines: 1),
                ),
              ),
              Icon(isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: priceColor, size: 28),
            ]),
            const SizedBox(height: 2),
            Text.rich(TextSpan(children: [
              TextSpan(
                text: '≈\$${markPrice.toStringAsFixed(pp > 2 ? 2 : pp)}  ',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: futureDmSans, fontWeight: FontWeight.w400),
              ),
              TextSpan(
                text: '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                style: TextStyle(color: priceColor, fontSize: 12, fontFamily: futureDmSans, fontWeight: FontWeight.w400),
              ),
            ])),
            const SizedBox(height: 2),
            Text('Mark Price ${markPrice.toStringAsFixed(pp)}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w400, fontFamily: futureDmSans)),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 7,
          child: Column(children: [
            _statRow('24h High', (pair?.high24h ?? 0).toStringAsFixed(pp)),
            _statRow('24h Low', (pair?.low24h ?? 0).toStringAsFixed(pp)),
            _statRow('24h Vol ($base)', formatFutureVolume(vol24h / (markPrice > 0 ? markPrice : 1))),
            _statRow('24h Vol ($quote)', '\$${formatFutureVolume(vol24h)}'),
            _statRow('Index Price', markPrice.toStringAsFixed(pp)),
            _statRow('Funding', fundingPct, valueColor: futureGreen),
            _statRow('Countdown', countdown, valueColor: futureGreen),
          ]),
        ),
      ]),
    );
  }

  Widget _statRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: futureDmSans, height: 16 / 12))),
        Text(value,
            style: TextStyle(color: valueColor ?? Colors.white, fontSize: 12, fontWeight: FontWeight.w400, fontFamily: futureDmSans, height: 16 / 12)),
      ]),
    );
  }

  Widget _buildFullOrderBook() {
    final pair = _ctrl.currentPair.value;
    final pp = pair?.pricePrecision ?? 2;
    final qp = pair?.quantityPrecision ?? 4;
    final markPrice = pair?.currentPrice ?? 0;

    final rawBids = _ctrl.orderBookBids;
    final rawAsks = _ctrl.orderBookAsks;
    final bidsSorted = [...rawBids]..sort((a, b) => double.parse(b[0]).compareTo(double.parse(a[0])));
    final asksSorted = [...rawAsks]..sort((a, b) => double.parse(a[0]).compareTo(double.parse(b[0])));

    double bidCum = 0;
    final bidRows = bidsSorted.take(15).map((b) {
      bidCum += double.tryParse(b[1]) ?? 0;
      return {'price': double.tryParse(b[0])?.toStringAsFixed(pp) ?? b[0], 'amount': double.tryParse(b[1])?.toStringAsFixed(qp) ?? b[1], 'cum': bidCum};
    }).toList();
    final maxBidCum = bidCum > 0 ? bidCum : 1.0;
    for (final b in bidRows) { b['pct'] = (b['cum'] as double) / maxBidCum * 100; }

    double askCum = 0;
    final askRows = asksSorted.take(15).map((a) {
      askCum += double.tryParse(a[1]) ?? 0;
      return {'price': double.tryParse(a[0])?.toStringAsFixed(pp) ?? a[0], 'amount': double.tryParse(a[1])?.toStringAsFixed(qp) ?? a[1], 'cum': askCum};
    }).toList();
    final maxAskCum = askCum > 0 ? askCum : 1.0;
    for (final a in askRows) { a['pct'] = (a['cum'] as double) / maxAskCum * 100; }

    final halfWidth = (MediaQuery.of(context).size.width / 2 - 20).clamp(0.0, 300.0);

    return FutureFullOrderBook(
      bidRows: bidRows, askRows: askRows, markPrice: markPrice, pp: pp, halfWidth: halfWidth,
      base: pair?.baseCurrency ?? 'BTC',
      quote: pair?.quoteCurrency ?? 'USDT',
      onPriceTap: (price) => Get.back(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chartTabIdx = _chartSubTab == 'Chart' ? 0 : _chartSubTab == 'Coin Info' ? 1 : 2;
    final bookTabIdx = _unifiedTab == 'Order Book' ? 0 : _unifiedTab == 'Trade History' ? 1 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(children: [
        Obx(() {
          final pair = _ctrl.currentPair.value;
          final symbol = (pair?.symbol ?? 'BTCUSDT').replaceAll('/', '');
          final change = pair?.priceChange24h ?? 0;
          final changeColor = change >= 0 ? gBuyColor : gSellColor;
          return SafeArea(
            bottom: false,
            child: Row(children: [
              buttonOnlyIcon(onPress: () => Get.back(), iconData: Icons.arrow_back_outlined, size: Dimens.iconSizeMin),
              Text(symbol, style: const TextStyle(fontFamily: futureDmSans, color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, height: 28 / 20)),
              const SizedBox(width: 6),
              Text('Perp', style: TextStyle(fontFamily: futureDmSans, color: Colors.white.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w400)),
              const SizedBox(width: 8),
              Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%', style: TextStyle(fontFamily: futureDmSans, color: changeColor, fontSize: 14, fontWeight: FontWeight.w400)),
              const Spacer(),
              buttonOnlyIcon(onPress: () {}, iconData: Icons.ios_share_sharp, size: 20),
              hSpacer5(),
            ]),
          );
        }),
        tabBarText(
          ['Chart'.tr, 'Coin Info'.tr, 'Contract Info'.tr], chartTabIdx,
          (i) => setState(() => _chartSubTab = i == 0 ? 'Chart' : i == 1 ? 'Coin Info' : 'Contract Info'),
          selectedColor: Colors.white, unSelectedColor: Colors.white.withValues(alpha: 0.5),
          fontSize: 16, selectedFontWeight: FontWeight.w700, unSelectedFontWeight: FontWeight.w400, fontFamily: futureDmSans,
        ),
        Expanded(child: Obx(() {
          final pair = _ctrl.currentPair.value;
          final symbol = (pair?.symbol ?? 'BTCUSDT').replaceAll('/', '');
          if (_chartSubTab != 'Chart') return const SizedBox.expand();
          // countdown
          final now = DateTime.now().millisecondsSinceEpoch;
          const period = 8 * 3600 * 1000;
          final target = ((now / period).ceil() * period).toInt();
          final diff = (target - now).clamp(0, period);
          final h = diff ~/ 3600000;
          final m = (diff % 3600000) ~/ 60000;
          final s = (diff % 60000) ~/ 1000;
          final countdown = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
          return ListView(padding: EdgeInsets.zero, children: [
            _buildPriceView(pair, countdown),
            const _FutureMarqueeTicker(),
            TrapixChartWidget(symbol: symbol, height: MediaQuery.of(context).size.width * 1.05, isFuture: true),
            Column(children: [
              tabBarText(
                ['Order Book'.tr, 'Trade History'.tr, 'Data Analysis'.tr], bookTabIdx,
                (i) => setState(() => _unifiedTab = i == 0 ? 'Order Book' : i == 1 ? 'Trade History' : 'Data Analysis'),
                selectedColor: Colors.white, unSelectedColor: Colors.white.withValues(alpha: 0.5),
                fontSize: 16, selectedFontWeight: FontWeight.w700, unSelectedFontWeight: FontWeight.w400, fontFamily: futureDmSans,
              ),
              vSpacer10(),
              dividerHorizontal(height: Dimens.paddingMid),
              vSpacer10(),
              Builder(builder: (_) {
                if (_unifiedTab == 'Order Book') return _buildFullOrderBook();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text(_unifiedTab == 'Trade History' ? 'No trade history data' : 'No data analysis available',
                      style: const TextStyle(fontSize: 13, color: futureMuted, fontFamily: futureDmSans))),
                );
              }),
            ]),
          ]);
        })),
        Container(
          padding: const EdgeInsets.fromLTRB(Dimens.paddingMid, Dimens.paddingMin, Dimens.paddingMid, Dimens.paddingMin),
          decoration: boxDecorationTopRound(color: Theme.of(context).secondaryHeaderColor),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: gBuyColor, borderRadius: BorderRadius.circular(5), border: Border.all(color: gBuyColor)), child: Text('Buy'.tr, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400, fontFamily: futureDmSans, height: 24 / 16))),
            )),
            hSpacer10(),
            Expanded(child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: gSellColor, borderRadius: BorderRadius.circular(5), border: Border.all(color: gSellColor)), child: Text('Sell'.tr, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400, fontFamily: futureDmSans, height: 24 / 16))),
            )),
          ]),
        ),
      ]),
    );
  }
}

class _FutureMarqueeTicker extends StatefulWidget {
  const _FutureMarqueeTicker();

  @override
  State<_FutureMarqueeTicker> createState() => _FutureMarqueeTickerState();
}

class _FutureMarqueeTickerState extends State<_FutureMarqueeTicker> {
  final _sc = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  Future<void> _startScroll() async {
    await Future.delayed(const Duration(seconds: 1));
    while (mounted && _sc.hasClients) {
      final max = _sc.position.maxScrollExtent;
      if (max <= 0) {
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }
      await _sc.animateTo(max, duration: Duration(milliseconds: (max * 60).toInt()), curve: Curves.linear);
      if (!mounted) break;
      _sc.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const marqueeText = '   Trapix.com lists TDO/USDT Trading Pair!   ';
    return Container(
      height: 25,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(children: [
        const Icon(Icons.volume_up_outlined, color: Color(0xFF007958), size: 20),
        const SizedBox(width: 6),
        Expanded(
          child: SingleChildScrollView(
            controller: _sc,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Text(
              marqueeText * 5,
              style: const TextStyle(color: Color(0xFF007958), fontSize: 12, fontWeight: FontWeight.w400, fontFamily: futureDmSans, height: 16 / 12),
            ),
          ),
        ),
      ]),
    );
  }
}

