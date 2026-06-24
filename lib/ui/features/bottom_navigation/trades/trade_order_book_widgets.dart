import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/exchange_order.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'trade_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const int _kMaxOrderBookRows = 15; // greendot/reddot mode
const int _kAllModeRows = 8; // dot (all) mode
const int _kOrderDecimal = 5;
const double _kMinFillPercent = 0.05;

// Detect how many decimals a value actually has (max 8)
int _detectDecimals(num? n) {
  if (n == null || n == 0) return 4;
  final s = n.toStringAsFixed(8);
  final dec = s.split('.').last.replaceAll(RegExp(r'0+$'), '');
  return dec.isEmpty ? 0 : dec.length.clamp(2, 8);
}

// Calculate consistent decimal places for an entire list
int _listDecimals(List<ExchangeOrder> list) {
  if (list.isEmpty) return 4;
  int max = 0;
  for (final e in list) {
    final d = _detectDecimals(e.amount);
    if (d > max) max = d;
  }
  return max.clamp(2, 8);
}

// Binance-style: K/M/B for large, fixed decimals for small — no hilna
String _fmt2(num? n, {int fixed = _kOrderDecimal}) {
  final val = (n ?? 0).toDouble();
  if (val == 0 || val.isNaN) return "0.${'0' * fixed}";
  if (val >= 1000000000) return "${(val / 1000000000).toStringAsFixed(2)}B";
  if (val >= 1000000) return "${(val / 1000000).toStringAsFixed(2)}M";
  if (val >= 1000) return "${(val / 1000).toStringAsFixed(2)}K";
  return val.toStringAsFixed(fixed);
}

String _fmtPrice(num? n, {int fixed = 2}) {
  final val = (n ?? 0).toDouble();
  final intPart = val.toStringAsFixed(0);
  if (intPart.length > 7) return intPart;
  return val.toStringAsFixed(fixed);
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER BOOK FIXED VIEW
// ─────────────────────────────────────────────────────────────────────────────
class OderBookFixedView extends StatelessWidget {
  const OderBookFixedView(
    this.selectedOrderSort, {
    super.key,
    required this.order,
    this.prices,
    required this.buyList,
    required this.sellList,
    required this.onShortChange,
    required this.selectedHeaderIndex,
    required this.onHeaderChange,
    this.baseCoin,
    this.tradeCoin,
    this.priceDecimal = 2,
    this.amountDecimal = 5,
  });

  final String selectedOrderSort;
  final OrderData? order;
  final List<PriceData>? prices;
  final List<ExchangeOrder> buyList;
  final List<ExchangeOrder> sellList;
  final Function(String) onShortChange;
  final int selectedHeaderIndex;
  final Function(int) onHeaderChange;
  final String? baseCoin;
  final String? tradeCoin;
  final int priceDecimal;
  final int amountDecimal;

  @override
  Widget build(BuildContext context) {
    final total = order?.total;
    PriceData? lastPData = prices.isValid ? prices?.first : PriceData();

    final int maxRows = selectedOrderSort == FromKey.all
        ? _kAllModeRows
        : _kMaxOrderBookRows;

    List<ExchangeOrder> sList = [];
    if (selectedOrderSort != FromKey.buy) {
      final raw = sellList.length > maxRows
          ? sellList.sublist(sellList.length - maxRows)
          : List<ExchangeOrder>.from(sellList);
      sList = raw;
    }

    List<ExchangeOrder> bList = [];
    if (selectedOrderSort != FromKey.sell) {
      bList = buyList.length > maxRows
          ? buyList.sublist(0, maxRows)
          : List<ExchangeOrder>.from(buyList);
    }

    const double rowH = 18.0;
    final double sectionH = maxRows * rowH;

    // Dynamic decimal: use max precision across all visible rows so column stays stable
    final int effectiveAmtDecimal = _listDecimals([...sList, ...bList]);

    // Compute max amount across both sides for relative fill bar
    final allAmounts = [...sList, ...bList]
        .map((e) => (e.amount ?? 0).toDouble())
        .toList();
    final maxAmt = allAmounts.isEmpty ? 1.0 : allAmounts.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // ── Top: header + rows + mid price ────────────────────────────────────────
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${"Price".tr}\n(${baseCoin ?? total?.baseWallet?.coinType ?? ""})",
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.5),
                    height: 1.2,
                  ),
                  maxLines: 2,
                ),
                InkWell(
                  onTap: () => _onArrowTap(context),
                  child: Text.rich(
                    TextSpan(
                      text: selectedHeaderIndex == 1 ? "Total".tr : "Amount".tr,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: "DMSans",
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.5),
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(
                          text: "\n(${tradeCoin ?? total?.tradeWallet?.coinType ?? ""})",
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: "DMSans",
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.5),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            vSpacer5(),

            // ── SELL LIST ──────────────────────────────────────────────────────
            if (selectedOrderSort != FromKey.buy)
              SizedBox(
                height: sectionH,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: List.generate(sList.length, (index) {
                    return OderBookItemMinView(
                      key: ValueKey('sell_${index}_${sList[index].price}'),
                      sList[index],
                      FromKey.sell,
                      selectedHeaderIndex == 1,
                      priceColor: const Color(0xFFD05858),
                      rowIndex: index,
                      priceDecimal: priceDecimal,
                      amountDecimal: effectiveAmtDecimal,
                      fillPct: ((sList[index].amount ?? 0).toDouble() / maxAmt).clamp(0.0, 1.0),
                    );
                  }),
                ),
              ),

            if (selectedOrderSort != FromKey.buy)
              MidPriceBlock(
                lastPData: lastPData,
                priceDecimal: priceDecimal,
                priceColor: selectedOrderSort == FromKey.sell
                    ? const Color(0xFFD05858)
                    : (lastPData?.priceOrderType == FromKey.buy
                          ? const Color(0xFF4ED78E)
                          : const Color(0xFFD05858)),
              ),

            // ── BUY LIST ──────────────────────────────────────────────────────
            if (selectedOrderSort != FromKey.sell)
              SizedBox(
                height: sectionH,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(bList.length, (index) {
                    return OderBookItemMinView(
                      key: ValueKey('buy_${index}_${bList[index].price}'),
                      bList[index],
                      FromKey.buy,
                      selectedHeaderIndex == 1,
                      priceColor: const Color(0xFF4ED78E),
                      rowIndex: index,
                      priceDecimal: priceDecimal,
                      amountDecimal: effectiveAmtDecimal,
                      fillPct: ((bList[index].amount ?? 0).toDouble() / maxAmt).clamp(0.0, 1.0),
                    );
                  }),
                ),
              ),
           

            // ── Mid price — buy-only mode ──────────────────────────────────────
            if (selectedOrderSort == FromKey.buy) const SizedBox(height: 0),
            if (selectedOrderSort == FromKey.buy)
              MidPriceBlock(
                lastPData: lastPData,
                priceDecimal: priceDecimal,
                priceColor: const Color(0xFF4ED78E),
              ),
            if (selectedOrderSort == FromKey.buy) const SizedBox(height: 0),
          ],
        ),

        // ── Bottom: B/S bar + controls — always fixed at bottom ───────────────────
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(builder: (context) {
              final totalBid = buyList.fold(0.0, (s, e) => s + ((e.amount ?? 0).toDouble()));
              final totalAsk = sellList.fold(0.0, (s, e) => s + ((e.amount ?? 0).toDouble()));
              final total = totalBid + totalAsk;
              final bidPct = total > 0 ? (totalBid / total * 100).round() : 50;
              final askPct = 100 - bidPct;
              return Container(
                height: 25,
                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    stops: [bidPct / 100, bidPct / 100],
                    colors: [const Color(0x1F0ECB81), const Color(0x1FF6465D)],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 13, height: 13,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: const Color(0xFF0ECB81), width: 1.5),
                        ),
                        child: const Center(child: Text('B', style: TextStyle(color: Color(0xFF0ECB81), fontSize: 8, fontWeight: FontWeight.w800))),
                      ),
                      const SizedBox(width: 3),
                      Text('$bidPct%', style: const TextStyle(color: Color(0xFF0ECB81), fontSize: 10, fontWeight: FontWeight.w700)),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('$askPct%', style: const TextStyle(color: Color(0xFFD05858), fontSize: 10, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 3),
                      Container(
                        width: 13, height: 13,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: const Color(0xFFD05858), width: 1.5),
                        ),
                        child: const Center(child: Text('S', style: TextStyle(color: Color(0xFFD05858), fontSize: 8, fontWeight: FontWeight.w800))),
                      ),
                    ]),
                  ],
                ),
              );
            }),
            Row(
              children: [
                Expanded(child: CustomDropdown()),
                const SizedBox(width: 8),
                _DotToggleButton(
                  selectedOrderSort: selectedOrderSort,
                  onToggle: onShortChange,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    );
  }

  void _onArrowTap(BuildContext context) {
    final list = ["Amount".tr, "Total".tr];
    final view = Column(
      children: List.generate(list.length, (index) {
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Dimens.paddingMid,
          ),
          title: TextRobotoAutoBold(list[index], fontSize: Dimens.fontSizeMid),
          trailing: index == selectedHeaderIndex
              ? Icon(
                  Icons.done,
                  color: context.theme.focusColor,
                  size: Dimens.iconSizeMin,
                )
              : null,
          onTap: () {
            Navigator.pop(context);
            onHeaderChange(index);
          },
        );
      }),
    );
    showBottomSheetDynamic(context, view, title: "Choose".tr);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MID PRICE BLOCK — green when price rises, red when price falls
// ─────────────────────────────────────────────────────────────────────────────
class MidPriceBlock extends StatefulWidget {
  const MidPriceBlock({
    super.key,
    required this.lastPData,
    required this.priceColor,
    this.priceDecimal = 2,
  });

  final PriceData? lastPData;
  final Color priceColor;
  final int priceDecimal; // used as initial color before first price change

  @override
  State<MidPriceBlock> createState() => _MidPriceBlockState();
}

class _MidPriceBlockState extends State<MidPriceBlock> {
  static const _green = Color(0xFF4ED78E);
  static const _red   = Color(0xFFD05858);

  late Color _priceColor;
  double? _lastPrice;
  bool _isUp = true;

  @override
  void initState() {
    super.initState();
    _priceColor = widget.priceColor;
    _lastPrice  = widget.lastPData?.price;
  }

  @override
  void didUpdateWidget(covariant MidPriceBlock old) {
    super.didUpdateWidget(old);
    final newPrice = widget.lastPData?.price;
    if (newPrice != null && _lastPrice != null && newPrice != _lastPrice) {
      setState(() {
        _isUp = newPrice > _lastPrice!;
        _priceColor = _isUp ? _green : _red;
      });
    }
    if (newPrice == null) {
      // Symbol changed — reset cached state so stale price doesn't flash
      setState(() {
        _lastPrice = null;
        _priceColor = widget.priceColor;
      });
    } else {
      _lastPrice = newPrice;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawPrice = widget.lastPData?.price;
    final hasPrice = rawPrice != null && rawPrice > 0;
    final priceStr = hasPrice ? _fmtPrice(rawPrice, fixed: widget.priceDecimal) : '';
    final usdStr   = hasPrice ? "≈ \$${_fmtPrice(widget.lastPData?.lastPrice, fixed: widget.priceDecimal)}" : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Price + arrow on same line ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  color: _priceColor,
                  fontSize: 15,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  height: 1.33,
                ),
                child: Text(priceStr, maxLines: 1),
              ),
              if (hasPrice)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    _isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    key: ValueKey(_isUp),
                    color: _priceColor,
                    size: 18,
                  ),
                ),
            ],
          ),
          // ── USD equivalent below price ─────────────────────────
          Text(
            usdStr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              fontFamily: "DMSans",
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ 3-STATE DOT TOGGLE BUTTON
// all → dot.png (default)
// buy → greendot.png (sirf buy dikhega)
// sell → reddot.png (sirf sell dikhega)
// ─────────────────────────────────────────────────────────────────────────────
class _DotToggleButton extends StatelessWidget {
  const _DotToggleButton({
    required this.selectedOrderSort,
    required this.onToggle,
  });

  final String selectedOrderSort;
  final Function(String) onToggle;

  String get _dotAsset {
    if (selectedOrderSort == FromKey.buy) return "assets/icons/greendot.png";
    if (selectedOrderSort == FromKey.sell) return "assets/icons/reddot.png";
    return "assets/icons/dot.png";
  }

  // ✅ Cycle: all → buy → sell → all
  void _onTap() {
    if (selectedOrderSort == FromKey.all) {
      onToggle(FromKey.buy);
    } else if (selectedOrderSort == FromKey.buy) {
      onToggle(FromKey.sell);
    } else {
      onToggle(FromKey.all);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Image.asset(
            _dotAsset,
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER BOOK ICON
// ─────────────────────────────────────────────────────────────────────────────
class OrderBookIcon extends StatelessWidget {
  const OrderBookIcon(this.fromKey, this.selectedKey, this.onTap, {super.key});

  final String fromKey;
  final String selectedKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedKey == fromKey;
    double opacity = isSelected ? 1 : 0.5;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 15,
          height: 15,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              fromKey == FromKey.all
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          color: gBuyColor.withValues(alpha: opacity),
                          height: 7,
                          width: 7,
                        ),
                        Container(
                          color: gSellColor.withValues(alpha: opacity),
                          height: 7,
                          width: 7,
                        ),
                      ],
                    )
                  : Container(
                      color: fromKey == FromKey.buy
                          ? gBuyColor.withValues(alpha: opacity)
                          : gSellColor.withValues(alpha: opacity),
                      height: 15,
                      width: 7,
                    ),
              showImageAsset(
                imagePath: AssetConstants.icBoxFilterAll,
                width: 7,
                height: 15,
                color: Colors.grey.withValues(alpha: opacity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER BOOK ITEM MIN VIEW
// ─────────────────────────────────────────────────────────────────────────────
class OderBookItemMinView extends StatelessWidget {
  const OderBookItemMinView(
    this.order,
    this.type,
    this.isTotal, {
    super.key,
    this.priceColor,
    this.rowIndex = 0,
    this.priceDecimal = 2,
    this.amountDecimal = 5,
    this.fillPct,
  });

  final ExchangeOrder order;
  final String type;
  final bool isTotal;
  final Color? priceColor;
  final int rowIndex;
  final int priceDecimal;
  final int amountDecimal;
  final double? fillPct;

  @override
  Widget build(BuildContext context) {
    final isBuy = type == FromKey.buy;
    final bgColor = isBuy
        ? const Color(0x1F0ECB81)
        : const Color(0x1FF6465D);

    final pct = (fillPct ?? getPercentageValue(1, order.percentage)).clamp(0.0, 1.0);

    final value = isTotal
        ? numberFormatCompact(order.total, decimals: amountDecimal)
        : _fmt2(order.amount, fixed: amountDecimal);

    return GestureDetector(
      onTap: () => setSelectedPrice.value = order.price,
      child: Container(
        height: 18,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            stops: [0.0, pct, pct],
            colors: [bgColor, bgColor, Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _fmtPrice(order.price, fixed: priceDecimal),
                style: TextStyle(
                  color: priceColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.start,
                maxLines: 1,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// DETAILS ORDER BOOK VIEW
// ─────────────────────────────────────────────────────────────────────────────
/// Website-style 4-column paired order book:
/// Amount(Trade) | Buy Price(Base) | Sell Price(Base) | Amount(Trade)
/// with cumulative depth bars drawn behind each row (like the website).
class DetailsOrderBookView extends StatelessWidget {
  const DetailsOrderBookView({
    super.key,
    this.total,
    required this.buyExchangeOrder,
    required this.sellExchangeOrder,
    this.tradeCoinOverride,
    this.baseCoinOverride,
    this.priceDecimal = 2,
    this.amountDecimal = 5,
  });

  final Total? total;
  final List<ExchangeOrder> buyExchangeOrder;
  final List<ExchangeOrder> sellExchangeOrder;
  final String? tradeCoinOverride;
  final String? baseCoinOverride;
  final int priceDecimal;
  final int amountDecimal;

  @override
  Widget build(BuildContext context) {
    final tradeCoin = tradeCoinOverride?.isNotEmpty == true ? tradeCoinOverride! : (total?.tradeWallet?.coinType ?? '');
    final baseCoin  = baseCoinOverride?.isNotEmpty  == true ? baseCoinOverride!  : (total?.baseWallet?.coinType  ?? '');
    final maxRows   = min(12, max(buyExchangeOrder.length, sellExchangeOrder.length));
    const rowH = 22.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Column headers ────────────────────────────────────────────
          Row(
            children: [
              _hdr('Amount($tradeCoin)', flex: 3, align: TextAlign.left),
              _hdr('Price($baseCoin)',   flex: 3, align: TextAlign.right),
              SizedBox(width: 10,),
              _hdr('Price($baseCoin)',   flex: 3, align: TextAlign.left),
              _hdr('Amount($tradeCoin)', flex: 3, align: TextAlign.right),
            ],
          ),
          const SizedBox(height: 4),
          // ── Paired rows ───────────────────────────────────────────────
          SizedBox(
            height: maxRows * rowH,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalW = constraints.maxWidth;
                final halfW  = totalW / 2;
                final buyOrders  = buyExchangeOrder.take(maxRows).toList();
                final sellOrders = sellExchangeOrder.take(maxRows).toList();

                // Shared max so both sides use identical scale
                double maxPctOf(List<ExchangeOrder> l) => l
                    .map((o) => (o.percentage ?? 0).toDouble())
                    .fold(0.0, (a, b) => a > b ? a : b);
                final sharedMax = max(maxPctOf(buyOrders), maxPctOf(sellOrders));
                final double maxPct = sharedMax > 0 ? sharedMax : 1.0;

                // Build normalised fractions (0..1) for each row
                final buyFracs  = List.generate(maxRows, (i) =>
                    i < buyOrders.length  ? ((buyOrders[i].percentage  ?? 0).toDouble() / maxPct).clamp(0.0, 1.0) : 0.0);
                // sell: mirror of buy — same widths, ascending order (small top, large bottom)
                final sellFracs = (buyFracs.toList()..sort((a, b) => a.compareTo(b)));

                return Stack(
                  children: [
                    // ── Continuous green background (buy side, right half of left column) ──
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DepthBarPainter(
                          fracs: buyFracs,
                          rowH: rowH,
                          halfW: halfW,
                          color: const Color(0x2622C55E),
                          growFromRight: false,
                          gap: 10,
                        ),
                      ),
                    ),
                    // ── Continuous red background (sell side, left half of right column) ──
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DepthBarPainter(
                          fracs: sellFracs,
                          rowH: rowH,
                          halfW: halfW,
                          color: const Color(0x26D05858),
                          growFromRight: true,
                          gap: 10,
                        ),
                      ),
                    ),
                    // ── Text rows on top ──
                    Column(
                      children: List.generate(maxRows, (i) {
                        final buy  = i < buyExchangeOrder.length  ? buyExchangeOrder[i]  : null;
                        final sell = i < sellExchangeOrder.length ? sellExchangeOrder[i] : null;
                        return SizedBox(
                          height: rowH,
                          child: Row(
                            children: [
                              // Buy side
                              Expanded(
                                child: Row(children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      buy != null ? _fmt2(buy.amount, fixed: amountDecimal) : '',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFFDDDDDD), fontFamily: 'monospace'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      buy != null ? _fmtPrice(buy.price, fixed: priceDecimal) : '',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontSize: 11, color: gBuyColor, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                                    ),
                                  ),
                                ]),
                              ),
                              // Gap between buy and sell columns
                              const SizedBox(width: 10),
                              // Sell side
                              Expanded(
                                child: Row(children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      sell != null ? _fmtPrice(sell.price, fixed: priceDecimal) : '',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontSize: 11, color: gSellColor, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      sell != null ? _fmt2(sell.amount, fixed: amountDecimal) : '',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFFDDDDDD), fontFamily: 'monospace'),
                                    ),
                                  ),
                                ]),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _hdr(String text, {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(fontSize: 10, color: Color(0xFF848E9C)),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _DepthBarPainter — draws continuous stepped depth bars with no row gaps
// ─────────────────────────────────────────────────────────────────────────────
class _DepthBarPainter extends CustomPainter {
  const _DepthBarPainter({
    required this.fracs,
    required this.rowH,
    required this.halfW,
    required this.color,
    required this.growFromRight,
    this.gap = 10,
  });
  final List<double> fracs;
  final double rowH;
  final double halfW;
  final Color color;
  final bool growFromRight;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final half = gap / 2;
    if (growFromRight) {
      // sell side: starts at halfW + half, grows rightward
      for (int i = 0; i < fracs.length; i++) {
        final frac = fracs[i];
        if (frac <= 0) continue;
        final barW = (halfW - half) * frac;
        final top = i * rowH;
        final bottom = top + rowH;
        canvas.drawRect(Rect.fromLTRB(halfW + half, top, halfW + half + barW, bottom), paint);
      }
    } else {
      // buy side: ends at halfW - half, grows leftward
      for (int i = 0; i < fracs.length; i++) {
        final frac = fracs[i];
        if (frac <= 0) continue;
        final barW = (halfW - half) * frac;
        final top = i * rowH;
        final bottom = top + rowH;
        canvas.drawRect(Rect.fromLTRB(halfW - half - barW, top, halfW - half, bottom), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DepthBarPainter old) =>
      old.fracs != fracs || old.color != color || old.gap != gap;
}

// ─────────────────────────────────────────────────────────────────────────────
// _OrderBookDetailRow — StatefulWidget with AnimationController
// ─────────────────────────────────────────────────────────────────────────────
class _OrderBookDetailRow extends StatefulWidget {
  const _OrderBookDetailRow({
    super.key,
    required this.order,
    required this.color,
    required this.fText,
    required this.sText,
    required this.isBuy,
  });

  final ExchangeOrder order;
  final Color color;
  final String fText;
  final String sText;
  final bool isBuy;

  @override
  State<_OrderBookDetailRow> createState() => _OrderBookDetailRowState();
}

class _OrderBookDetailRowState extends State<_OrderBookDetailRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double _currentPercent = _kMinFillPercent;

  double _safePercent(double raw) => raw.clamp(_kMinFillPercent, 1.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _currentPercent = _safePercent(
      getPercentageValue(1, widget.order.percentage),
    );

    _animation = Tween<double>(
      begin: _currentPercent,
      end: _currentPercent,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.value = 1.0;

    _controller.addListener(() {
      _currentPercent = _animation.value;
    });
  }

  @override
  void didUpdateWidget(covariant _OrderBookDetailRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newPercent = _safePercent(
      getPercentageValue(1, widget.order.percentage),
    );

    if ((newPercent - _currentPercent).abs() > 0.001) {
      final fromPercent = _currentPercent;
      _currentPercent = newPercent;

      _animation = Tween<double>(begin: fromPercent, end: newPercent).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

      _controller
        ..value = 0.0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setSelectedPrice.value = widget.order.price,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return RotatedBox(
                quarterTurns: -2,
                child: LinearProgressIndicator(
                  value: _animation.value,
                  minHeight: 20,
                  color: widget.color.withValues(alpha: 0.15),
                  backgroundColor: Colors.transparent,
                ),
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: TextRobotoAutoNormal(
                  widget.fText,
                  color: widget.isBuy ? null : widget.color,
                ),
              ),
              Expanded(
                child: TextRobotoAutoNormal(
                  widget.sText,
                  textAlign: TextAlign.end,
                  color: widget.isBuy ? widget.color : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────

class CustomDropdown extends StatefulWidget {
  const CustomDropdown({super.key});

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  // Initial selected value
  String selectedValue = "0.01";
  final List<String> items = ["0.01", "0.1", "1"];

  // Overlay logic ke liye variable
  OverlayEntry? overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool isOpen = false;

  @override
  void dispose() {
    // Widget destroy hone par overlay hata dena taaki memory leak na ho
    closeDropdown();
    super.dispose();
  }

  // Method to open the custom dropdown
  void openDropdown() {
    if (isOpen) return;
    setState(() => isOpen = true);

    // RenderBox se parent ki size nikalna (Width match karne ke liye)
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        // Width bahar wale container jitni set ki hai
        width: size.width,
        // Top position niche set ki hai dropdown button ke
        top: offset.dy + size.height,
        left: offset.dx,
        child: GestureDetector(
          // Dropdown ke bahar click karne par band karne ke liye behavior
          behavior: HitTestBehavior.translucent,
          onTap: closeDropdown,
          child: Material(
            color: Colors.transparent,
            child: Container(
              // Card ka design (Background color dark)
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C), // Dark grey/black for list
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              // Item list
              child: ListView(
                // Padding + shrink wrap taaki height content ke hisaab se ho
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: items.map((item) {
                  final bool isSelected = item == selectedValue;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedValue = item;
                      });
                      closeDropdown();
                    },
                    child: Container(
                      height: 40, // Har item ki height
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        // Yahan logic hai: Selected item ka color Green
                        color: isSelected
                            ? const Color(0xFF1DB954)
                            : Colors.transparent,
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: "DMSans",
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  // Method to close dropdown
  void closeDropdown() {
    if (!isOpen) return;
    overlayEntry?.remove();
    overlayEntry = null;
    setState(() => isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (isOpen) {
            closeDropdown();
          } else {
            openDropdown();
          }
        },
        child: Container(
          height: 28, // Apni di height
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
          ),
          // UI jo dikhega jab dropdown band ho
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w400,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: Colors.white.withValues(alpha: 0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
