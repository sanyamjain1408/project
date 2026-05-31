import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'future_controller.dart';
import 'future_models.dart';

// ── Order Book ────────────────────────────────────────────────────────────────
class FutureOrderBook extends StatelessWidget {
  final List<Map<String, dynamic>> asks;
  final List<Map<String, dynamic>> bids;
  final double markPrice;
  final int pp;
  final String quote;
  final String base;
  final double change;
  final bool isUp;
  final String bookFilter;
  final String countdown;
  final double fundingRate;
  final double columnWidth;
  final void Function(String price) onPriceTap;
  final Widget precisionDropdown;
  final Widget dotToggle;

  const FutureOrderBook({
    super.key,
    required this.asks,
    required this.bids,
    required this.markPrice,
    required this.pp,
    required this.quote,
    required this.base,
    required this.change,
    required this.isUp,
    required this.bookFilter,
    required this.countdown,
    required this.fundingRate,
    required this.columnWidth,
    required this.onPriceTap,
    required this.precisionDropdown,
    required this.dotToggle,
  });

  @override
  Widget build(BuildContext context) {
    final showAsks = bookFilter == 'all' || bookFilter == 'sell';
    final showBids = bookFilter == 'all' || bookFilter == 'buy';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top content: funding, headers, order rows, price
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Funding/ Next Funding',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400,
                    fontFamily: futureDmSans,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${(fundingRate * 100).toStringAsFixed(4)}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF0ECB81),
                        fontFamily: futureDmSans,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ $countdown',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF0ECB81),
                        fontWeight: FontWeight.w400,
                        fontFamily: futureDmSans,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            vSpacer5(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price ($quote)',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                    fontWeight: FontWeight.w400,
                    fontFamily: "DMSans",
                    height: 1.2,
                  ),
                  maxLines: 2,
                ),
                Text(
                  'Amount ($base)',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                    fontWeight: FontWeight.w400,
                    fontFamily: "DMSans",
                    height: 1.2,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 2),
            if (showAsks) ...[
              ...asks.map(
                (ask) => _BookRow(
                  price: ask['price'],
                  amount: ask['amount'],
                  pct: ask['pct'],
                  pp: pp,
                  isAsk: true,
                  columnWidth: columnWidth,
                  onTap: onPriceTap,
                ),
              ),
            ],
            GestureDetector(
              onTap: () => onPriceTap(markPrice.toStringAsFixed(pp)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          markPrice.toStringAsFixed(pp),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: change >= 0
                                ? const Color(0xFF4ED78E)
                                : const Color(0xFFD05858),
                            fontFamily: futureDmSans,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          change >= 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: change >= 0
                              ? const Color(0xFF4ED78E)
                              : const Color(0xFFD05858),
                          size: 14,
                        ),
                      ],
                    ),
                    Text(
                      '≈ \$${markPrice.toStringAsFixed(pp > 2 ? 2 : pp)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w400,
                        fontFamily: futureDmSans,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showBids) ...[
              const SizedBox(height: 2),
              ...bids.map(
                (bid) => _BookRow(
                  price: bid['price'],
                  amount: bid['amount'],
                  pct: bid['pct'],
                  pp: pp,
                  isAsk: false,
                  columnWidth: columnWidth,
                  onTap: onPriceTap,
                ),
              ),
            ],
          ],
        ),
        // Bottom content: B/S bar + precision/dot row — fixed at bottom
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final totalAsk = asks.fold(
                  0.0,
                  (s, e) => s + (double.tryParse(e['amount'] ?? '0') ?? 0),
                );
                final totalBid = bids.fold(
                  0.0,
                  (s, e) => s + (double.tryParse(e['amount'] ?? '0') ?? 0),
                );
                final total = totalAsk + totalBid;
                final bidPct = total > 0
                    ? (totalBid / total * 100).round()
                    : 50;
                final askPct = 100 - bidPct;
                return Container(
                  height: 24,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      stops: [bidPct / 100, bidPct / 100],
                      colors: [
                        const Color(0x1F0ECB81),
                        const Color(0x1FF6465D),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: const Color(0xFF0ECB81),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'B',
                                style: TextStyle(
                                  color: Color(0xFF0ECB81),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$bidPct%',
                            style: const TextStyle(
                              color: Color(0xFF0ECB81),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$askPct%',
                            style: const TextStyle(
                              color: Color(0xFFD05858),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: const Color(0xFFD05858),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'S',
                                style: TextStyle(
                                  color: Color(0xFFD05858),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            Row(
              children: [
                Expanded(child: precisionDropdown),
                const SizedBox(width: 10),
                dotToggle,
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _BookRow extends StatelessWidget {
  final String price;
  final String amount;
  final double pct;
  final int pp;
  final bool isAsk;
  final double columnWidth;
  final void Function(String price) onTap;

  const _BookRow({
    required this.price,
    required this.amount,
    required this.pct,
    required this.pp,
    required this.isAsk,
    required this.columnWidth,
    required this.onTap,
  });

  String _formatPrice(double val) {
    final formatted = val.toStringAsFixed(2);
    // If integer part alone is too wide (more than 7 chars), show integer only
    final intPart = val.toStringAsFixed(0);
    if (intPart.length > 7) return intPart;
    return formatted;
  }

  String _formatAmount(double val) {
    final formatted = val.toStringAsFixed(5);
    // If integer part alone is too wide (more than 7 chars), show integer only
    final intPart = val.toStringAsFixed(0);
    if (intPart.length > 7) return intPart;
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final color = isAsk ? const Color(0xFFD05858) : const Color(0xFF4ED78E);
    final barColor = isAsk ? const Color(0x1FF6465D) : const Color(0x1F0ECB81);
    final priceVal = double.tryParse(price) ?? 0;
    final amountVal = double.tryParse(amount) ?? 0;
    final fillFraction = (pct / 100).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () => onTap(double.parse(price).toStringAsFixed(pp)),
      child: Container(
        height: 18,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            stops: [0.0, fillFraction, fillFraction],
            colors: [barColor, barColor, Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _formatPrice(priceVal),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: color,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.left,
                maxLines: 1,
              ),
            ),
            Text(
              _formatAmount(amountVal),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontFamily: 'monospace',
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

// ── Trade Form ────────────────────────────────────────────────────────────────
class FutureTradeForm extends StatelessWidget {
  final FuturePair? pair;
  final int pp;
  final int qp;
  final String base;
  final String quote;
  final double activePrice;
  final double marginVal;
  final String cost;
  final String maxQty;
  final String buySell;
  final String orderType;
  final String marginMode;
  final int leverage;
  final String qty;
  final String limitPx;
  final String triggerPx;
  final double sliderPct;
  final bool showTpSl;
  final String tp;
  final String sl;
  final bool showOrderTypeDropdown;
  final TextEditingController limitPxCtrl;
  final FocusNode limitPxFocus;
  final bool limitPxUserEdited;
  final NewFutureController ctrl;

  final void Function(String) onQtyChanged;
  final void Function(String) onLimitPxChanged;
  final void Function(String) onTriggerPxChanged;
  final void Function(String) onTpChanged;
  final void Function(String) onSlChanged;
  final void Function(bool) onTpSlToggle;
  final void Function(bool) onOrderTypeDropdownToggle;
  final void Function(String) onOrderTypeChanged;
  final void Function(double) onSliderPct;
  final VoidCallback onMarginModeTap;
  final VoidCallback onLeverageTap;
  final void Function(String) onBuySellChanged;
  final Future<void> Function() onPlaceOrder;

  const FutureTradeForm({
    super.key,
    required this.pair,
    required this.pp,
    required this.qp,
    required this.base,
    required this.quote,
    required this.activePrice,
    required this.marginVal,
    required this.cost,
    required this.maxQty,
    required this.buySell,
    required this.orderType,
    required this.marginMode,
    required this.leverage,
    required this.qty,
    required this.limitPx,
    required this.triggerPx,
    required this.sliderPct,
    required this.showTpSl,
    required this.tp,
    required this.sl,
    required this.showOrderTypeDropdown,
    required this.limitPxCtrl,
    required this.limitPxFocus,
    required this.limitPxUserEdited,
    required this.ctrl,
    required this.onQtyChanged,
    required this.onLimitPxChanged,
    required this.onTriggerPxChanged,
    required this.onTpChanged,
    required this.onSlChanged,
    required this.onTpSlToggle,
    required this.onOrderTypeDropdownToggle,
    required this.onOrderTypeChanged,
    required this.onSliderPct,
    required this.onMarginModeTap,
    required this.onLeverageTap,
    required this.onBuySellChanged,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    final labels = {
      'limit': 'Limit',
      'market': 'Market',
      'stop_limit': 'Stop limit',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _BtnDropdown(
                text: marginMode.capitalizeFirst!,
                onTap: onMarginModeTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BtnDropdown(text: '${leverage}x', onTap: onLeverageTap),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              _TabBtn(
                label: 'Buy',
                active: buySell == 'Buy',
                activeColor: const Color(0xFF00B052),
                onTap: () => onBuySellChanged('Buy'),
              ),
              _TabBtn(
                label: 'Sell',
                active: buySell == 'Sell',
                activeColor: const Color(0xFFD73C3C),
                onTap: () => onBuySellChanged('Sell'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        // Order type dropdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => onOrderTypeDropdownToggle(!showOrderTypeDropdown),
              child: Container(
                width: double.infinity,
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        labels[orderType]!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: futureTextWhite,
                          height: 16 / 12,
                          fontFamily: futureDmSans,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      child: Text(
                        '▾',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showOrderTypeDropdown)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: labels.entries.map((e) {
                    final isSelected = orderType == e.key;
                    return GestureDetector(
                      onTap: () {
                        onOrderTypeChanged(e.key);
                        onOrderTypeDropdownToggle(false);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00B052)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              fontFamily: futureDmSans,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        if (orderType == 'stop_limit') ...[
          const SizedBox(height: 8),
          FuturePriceInput(
            label: 'Trigger Price',
            value: triggerPx,
            onChanged: onTriggerPxChanged,
            pp: pp,
            isTrigger: true,
          ),
        ],
        if (orderType == 'limit' || orderType == 'stop_limit') ...[
          const SizedBox(height: 8),
          FuturePriceInput(
            label: 'Limit Price',
            value: limitPx,
            onChanged: onLimitPxChanged,
            pp: pp,
            limitPxCtrl: limitPxCtrl,
            limitPxFocus: limitPxFocus,
            onLimitPxUserEdited: () {},
          ),
        ],
        const SizedBox(height: 8),
        FutureQtyInput(base: base, qty: qty, qp: qp, onChanged: onQtyChanged),
        const SizedBox(height: 8),
        // Slider with dots overlay
        SizedBox(
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: Colors.white.withValues(alpha: 0.5),
                  inactiveTrackColor: const Color(0xFF1A1A1A),
                  thumbColor: Colors.transparent,
                ),
                child: Slider(
                  value: sliderPct,
                  min: 0,
                  max: 100,
                  divisions: 4,
                  onChanged: (v) {
                    final snapped = (v / 25).round() * 25.0;
                    onSliderPct(snapped);
                  },
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [0.0, 25.0, 50.0, 75.0, 100.0].map((point) {
                      final active = sliderPct >= point;
                      return Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: active ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onTpSlToggle(!showTpSl),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: showTpSl ? futureGreen : futureMuted,
                  ),
                  borderRadius: BorderRadius.circular(7),
                  color: showTpSl ? futureGreen : Colors.transparent,
                ),
                child: showTpSl
                    ? const Icon(Icons.check, size: 10, color: futureBg)
                    : null,
              ),
              const SizedBox(width: 5),
              Text(
                'TP/SL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontFamily: futureDmSans,
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: showTpSl,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              FuturePriceInput(
                label: 'Take-Profit Price',
                value: tp,
                onChanged: onTpChanged,
                pp: pp,
              ),
              const SizedBox(height: 8),
              FuturePriceInput(
                label: 'Take-Loss Price',
                value: sl,
                onChanged: onSlChanged,
                pp: pp,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FutureBalanceInfo(quote: quote, maxQty: maxQty, cost: cost, ctrl: ctrl),
        const SizedBox(height: 10),
        Obx(
          () => GestureDetector(
            onTap: ctrl.orderLoading.value ? null : () => onPlaceOrder(),
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: buySell == 'Buy' ? futureGreen : futureRed,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                ctrl.orderLoading.value
                    ? 'Processing...'
                    : (buySell == 'Buy' ? 'Buy' : 'Sell'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: futureTextWhite,
                  fontFamily: futureDmSans,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BtnDropdown extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _BtnDropdown({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: futureTextWhite,
                fontFamily: futureDmSans,
                height: 16 / 12,
              ),
            ),
            const Spacer(),
            Text(
              '▾',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const _TabBtn({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: active ? activeColor : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: active
                  ? futureTextWhite
                  : Colors.white.withValues(alpha: 0.8),
              fontFamily: futureDmSans,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Price Input ───────────────────────────────────────────────────────────────
class FuturePriceInput extends StatelessWidget {
  final String label;
  final String value;
  final void Function(String) onChanged;
  final int pp;
  final bool isTrigger;
  final TextEditingController? limitPxCtrl;
  final FocusNode? limitPxFocus;
  final VoidCallback? onLimitPxUserEdited;

  const FuturePriceInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.pp,
    this.isTrigger = false,
    this.limitPxCtrl,
    this.limitPxFocus,
    this.onLimitPxUserEdited,
  });

  @override
  Widget build(BuildContext context) {
    final isLimitField = !isTrigger && label == 'Limit Price';
    final ctrl = isLimitField && limitPxCtrl != null
        ? limitPxCtrl!
        : (TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length));
    final focusNode = isLimitField ? limitPxFocus : null;
    final step = math.pow(10, -pp).toDouble();

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400,
                    height: 12 / 10,
                    fontFamily: futureDmSans,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: ctrl,
                  focusNode: focusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                    color: futureTextWhite,
                    fontFamily: futureDmSans,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) {
                    if (isLimitField) onLimitPxUserEdited?.call();
                    onChanged(v);
                  },
                ),
              ],
            ),
          ),
          _StepBtn(
            label: '−',
            onTap: () {
              final cur =
                  double.tryParse(isLimitField ? ctrl.text : value) ?? 0;
              final newVal = math.max(0, cur - step).toStringAsFixed(pp);
              if (isLimitField) {
                onLimitPxUserEdited?.call();
                ctrl.text = newVal;
                ctrl.selection = TextSelection.collapsed(offset: newVal.length);
              }
              onChanged(newVal);
            },
          ),
          const SizedBox(width: 14),
          Container(
            height: 30,
            width: 1,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 14),
          _StepBtn(
            label: '+',
            onTap: () {
              final cur =
                  double.tryParse(isLimitField ? ctrl.text : value) ?? 0;
              final newVal = (cur + step).toStringAsFixed(pp);
              if (isLimitField) {
                onLimitPxUserEdited?.call();
                ctrl.text = newVal;
                ctrl.selection = TextSelection.collapsed(offset: newVal.length);
              }
              onChanged(newVal);
            },
          ),
        ],
      ),
    );
  }
}

// ── Qty Input ─────────────────────────────────────────────────────────────────
class FutureQtyInput extends StatelessWidget {
  final String base;
  final String qty;
  final int qp;
  final void Function(String) onChanged;

  const FutureQtyInput({
    super.key,
    required this.base,
    required this.qty,
    required this.qp,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: qty)
      ..selection = TextSelection.collapsed(offset: qty.length);
    final step = math.pow(10, -qp).toDouble();

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qty $base',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 12 / 10,
                    fontWeight: FontWeight.w400,
                    fontFamily: futureDmSans,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: futureTextWhite,
                    height: 16 / 12,
                    fontFamily: futureDmSans,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
          _StepBtn(
            label: '−',
            onTap: () {
              final cur = double.tryParse(qty) ?? 0;
              onChanged(math.max(0, cur - step).toStringAsFixed(qp));
            },
          ),
          const SizedBox(width: 14),
          Container(
            height: 30,
            width: 1,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 14),
          _StepBtn(
            label: '+',
            onTap: () {
              final cur = double.tryParse(qty) ?? 0;
              onChanged((cur + step).toStringAsFixed(qp));
            },
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StepBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.5),
            fontFamily: futureDmSans,
          ),
        ),
      ),
    );
  }
}

// ── Balance Info ──────────────────────────────────────────────────────────────
class FutureBalanceInfo extends StatelessWidget {
  final String quote;
  final String maxQty;
  final String cost;
  final NewFutureController ctrl;

  const FutureBalanceInfo({
    super.key,
    required this.quote,
    required this.maxQty,
    required this.cost,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Avail.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.5),
                fontFamily: futureDmSans,
              ),
            ),
            Obx(
              () => Text(
                '${ctrl.availableBalance.value.toStringAsFixed(2)} $quote',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  fontFamily: futureDmSans,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Max',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.5),
                fontFamily: futureDmSans,
              ),
            ),
            Text(
              maxQty,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                fontFamily: futureDmSans,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cost',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.5),
                fontFamily: futureDmSans,
              ),
            ),
            Text(
              '$cost USDT',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                fontFamily: futureDmSans,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Positions / Orders / Assets Section ──────────────────────────────────────
class FuturePositionsSection extends StatefulWidget {
  final FuturePair? pair;
  final int pp;
  final String bottomTab;
  final NewFutureController ctrl;
  final void Function(String tab) onTabChanged;
  final void Function(FuturePosition pos) onTpSlTap;
  final VoidCallback onLeverageTap;
  final bool hideHeader;

  const FuturePositionsSection({
    super.key,
    required this.pair,
    required this.pp,
    required this.bottomTab,
    required this.ctrl,
    required this.onTabChanged,
    required this.onTpSlTap,
    required this.onLeverageTap,
    this.hideHeader = false,
  });

  @override
  State<FuturePositionsSection> createState() => _FuturePositionsSectionState();
}

class _FuturePositionsSectionState extends State<FuturePositionsSection> {
  void _openHistory() {
    Get.to(
      () => FutureHistoryFullScreen(
        ctrl: widget.ctrl,
        pair: widget.pair,
        pp: widget.pp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ['Position', 'Open Orders', 'Assets'];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(),
      child: Column(
        children: [
          if (!widget.hideHeader)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(),
              child: Row(
                children: [
                  ...tabs.map((t) {
                    final active = widget.bottomTab == t;
                    return GestureDetector(
                      onTap: () => widget.onTabChanged(t),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active ? futureTextWhite : futureMuted,
                            fontFamily: futureDmSans,
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openHistory,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Image.asset(
                        "assets/icons/history.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.hideHeader ? 0 : 12,
              vertical: 8,
            ),
            child: widget.bottomTab == 'Position'
                ? _PositionsTab(
                    pair: widget.pair,
                    pp: widget.pp,
                    ctrl: widget.ctrl,
                    onTpSlTap: widget.onTpSlTap,
                    onLeverageTap: widget.onLeverageTap,
                  )
                : widget.bottomTab == 'Open Orders'
                ? _OpenOrdersTab(
                    pair: widget.pair,
                    pp: widget.pp,
                    ctrl: widget.ctrl,
                  )
                : _AssetsTab(ctrl: widget.ctrl),
          ),
        ],
      ),
    );
  }
}

class _PositionsTab extends StatelessWidget {
  final FuturePair? pair;
  final int pp;
  final NewFutureController ctrl;
  final void Function(FuturePosition pos) onTpSlTap;
  final VoidCallback onLeverageTap;

  const _PositionsTab({
    required this.pair,
    required this.pp,
    required this.ctrl,
    required this.onTpSlTap,
    required this.onLeverageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final openPositions = ctrl.positions
          .where((p) => p.status == 'open')
          .toList();
      if (openPositions.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Text(
              'No open positions',
              style: TextStyle(
                fontSize: 13,
                color: futureMuted,
                fontFamily: futureDmSans,
              ),
            ),
          ),
        );
      }
      return Column(
        children: openPositions
            .map(
              (pos) => _PositionCard(
                pos: pos,
                pair: pair,
                pp: pp,
                ctrl: ctrl,
                onTpSlTap: onTpSlTap,
                onLeverageTap: onLeverageTap,
              ),
            )
            .toList(),
      );
    });
  }
}

class _PositionCard extends StatelessWidget {
  final FuturePosition pos;
  final FuturePair? pair;
  final int pp;
  final NewFutureController ctrl;
  final void Function(FuturePosition pos) onTpSlTap;
  final VoidCallback onLeverageTap;

  const _PositionCard({
    required this.pos,
    required this.pair,
    required this.pp,
    required this.ctrl,
    required this.onTpSlTap,
    required this.onLeverageTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLong = pos.side == 'long';
    final markPrice = (pair != null && pair!.symbol == pos.symbol)
        ? pair!.currentPrice
        : pos.entryPrice;
    final rawPnl = isLong
        ? (markPrice - pos.entryPrice) * pos.quantity
        : (pos.entryPrice - markPrice) * pos.quantity;
    final pnl = rawPnl - pos.fee;
    final roi = pos.margin > 0 ? (pnl / pos.margin) * 100 : 0.0;
    final pnlColor = pnl >= 0 ? futureGreen : futureRed;
    final sideColor = isLong ? futureGreen : futureRed;
    final sideLabel = isLong ? 'Buy' : 'Sell';
    final marginRatio = pos.margin > 0
        ? (pos.margin / (pos.quantity * pos.entryPrice) * 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          left: const BorderSide(color: Colors.transparent),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Symbol + Perp + Cross badge | share + Buy/Sell ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                pos.symbol,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                  fontFamily: futureDmSans,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Perp',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: futureDmSans,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Text(
                  'Cross ${pos.leverage}x',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: futureDmSans,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Image.asset(
                  'assets/images/perp.png',
                  width: 15,
                  height: 20,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: sideColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.transparent),
                ),
                child: Text(
                  sideLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: sideColor,
                    height: 20/15,
                    fontFamily: futureDmSans,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Row 2: PNL label | ROI label ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PNL (USDT)',
                style: TextStyle(
                  fontSize: 12,
                  height: 16/12,
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: futureDmSans,
                ),
              ),
              Text(
                'ROI',
                style: TextStyle(
                  fontSize: 12,
                  height: 16/12,
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: futureDmSans,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // ── Row 3: PNL value | ROI value ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: pnlColor,
                  fontFamily: futureDmSans,
                  height: 28/20,
                ),
              ),
              Text(
                '${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: pnlColor,
                  fontFamily: futureDmSans,
                  height: 28/20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Row 4: Size | Margin | Margin Ratio ──
          Row(
            children: [
              _InfoCell(
                label: 'Size (USDT)',
                value: (pos.quantity * pos.entryPrice).toStringAsFixed(4),
              ),
              _InfoCell(
                label: 'Margin (USDT)',
                value: pos.margin.toStringAsFixed(2),
                align: TextAlign.center,
              ),
              _InfoCell(
                label: 'Margin Ratio',
                value: '${marginRatio.toStringAsFixed(2)}%',
                valueColor: futureGreen,
                align: TextAlign.end,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Row 5: Entry | Mark | Liq ──
          Row(
            children: [
              _InfoCell(
                label: 'Entry Price (USDT)',
                value: pos.entryPrice.toStringAsFixed(pp),
              ),
              _InfoCell(
                label: 'Mark Price (USDT)',
                value: markPrice.toStringAsFixed(pp),
                align: TextAlign.center,
              ),
              _InfoCell(
                label: 'Liq. Price (USDT)',
                value: pos.liquidationPrice.toStringAsFixed(pp),
                
                align: TextAlign.end,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Row 6: Leverage | TP/SL | Close ──
          Row(
            children: [
              Expanded(
                child: _CardBtn(label: 'Leverage', onTap: onLeverageTap),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _CardBtn(label: 'TP/SL', onTap: () => onTpSlTap(pos)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _CardBtn(
                  label: 'Close',
                  onTap: () => ctrl.closePosition(pos.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextAlign align;

  const _InfoCell({
    required this.label,
    required this.value,
    this.valueColor,
    this.align = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final cross = align == TextAlign.end
        ? CrossAxisAlignment.end
        : align == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Expanded(
      child: Column(
        crossAxisAlignment: cross,
        children: [
          Text(
            label,
            textAlign: align,
            style: TextStyle(
              fontSize: 12,
              height: 16/12,
              color: Colors.white.withOpacity(0.5),
              fontFamily: futureDmSans,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: align,
            style: TextStyle(
              fontSize: 15,
              height: 20/15,
              fontWeight: FontWeight.w400,
              color: valueColor ?? futureTextWhite,
              fontFamily: futureDmSans,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CardBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Material(
        color: const Color(0xFF1A1A1A),
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white12,
          highlightColor: Colors.white10,
          child: Container(
            height: 30,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: futureDmSans,
                height: 16 / 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenOrdersTab extends StatelessWidget {
  final FuturePair? pair;
  final int pp;
  final NewFutureController ctrl;

  const _OpenOrdersTab({
    required this.pair,
    required this.pp,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final openOrders = ctrl.orders
          .where((o) => o.status == 'pending')
          .toList();
      if (openOrders.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Text(
              'No open orders',
              style: TextStyle(
                fontSize: 13,
                color: futureMuted,
                fontFamily: futureDmSans,
              ),
            ),
          ),
        );
      }
      return Column(
        children: openOrders.map((o) {
          final qp = pair?.quantityPrecision ?? 4;
          final isLong = o.side == 'long';
          final sideColor = isLong ? futureGreen : futureRed;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: futureBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: pair + delete
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        o.symbol,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: futureTextWhite,
                          fontFamily: futureDmSans,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ctrl.cancelOrder(o.id),
                        child: Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.delete_outline,
                            color: futureRed,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Row 2: type + date
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${isLong ? 'Buy' : 'Sell'} ${o.orderType[0].toUpperCase()}${o.orderType.substring(1).toLowerCase()}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sideColor,
                          fontFamily: futureDmSans,
                        ),
                      ),
                      Text(
                        o.createdAt,
                        style: const TextStyle(
                          fontSize: 11,
                          color: futureMuted,
                          fontFamily: futureDmSans,
                        ),
                      ),
                    ],
                  ),
                ),
                // Row 3: Amount | Fee | Price | Total
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      FutureInfoCell(
                        label: 'Amount',
                        value: o.quantity.toStringAsFixed(qp),
                      ),
                      FutureInfoCell(
                        label: 'Fee (USDT)',
                        value: o.fee.toStringAsFixed(4),
                        textAlign: TextAlign.center,
                      ),
                      FutureInfoCell(
                        label: 'Price (USDT)',
                        value: o.price.toStringAsFixed(pp),
                        textAlign: TextAlign.center,
                      ),
                      FutureInfoCell(
                        label: 'Total (USDT)',
                        value: o.margin.toStringAsFixed(2),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}

class _AssetsTab extends StatelessWidget {
  final NewFutureController ctrl;
  const _AssetsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final positions = ctrl.positions
          .where((p) => p.status == 'open')
          .toList();
      final unrealizedPnl = positions.fold<double>(0, (acc, p) {
        final isLong = p.side == 'long';
        final rawPnl = isLong
            ? (p.entryPrice - p.entryPrice) * p.quantity
            : (p.entryPrice - p.entryPrice) * p.quantity;
        return acc + rawPnl - p.fee;
      });
      final bal = ctrl.balance.value;
      return Column(
        children: [
          _AssetRow(
            label: 'Currency Equity',
            value: '${bal.toStringAsFixed(4)} USDT',
          ),
          const Divider(color: futureBorder, height: 20),
          _AssetRow(
            label: 'Available Margin',
            value: '${bal.toStringAsFixed(4)} USDT',
          ),
          const Divider(color: futureBorder, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Unrealized PnL',
                style: TextStyle(
                  fontSize: 14,
                  color: futureMuted,
                  fontFamily: futureDmSans,
                ),
              ),
              Text(
                '${unrealizedPnl >= 0 ? '+' : ''}${unrealizedPnl.toStringAsFixed(4)} USDT',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: unrealizedPnl >= 0 ? futureGreen : futureRed,
                  fontFamily: futureDmSans,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _AssetRow extends StatelessWidget {
  final String label;
  final String value;
  const _AssetRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: futureMuted,
            fontFamily: futureDmSans,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: futureTextWhite,
            fontFamily: futureDmSans,
          ),
        ),
      ],
    );
  }
}

// ── My Trades History Full Screen ─────────────────────────────────────────────
class FutureHistoryFullScreen extends StatefulWidget {
  final NewFutureController ctrl;
  final FuturePair? pair;
  final int pp;

  const FutureHistoryFullScreen({
    super.key,
    required this.ctrl,
    required this.pair,
    required this.pp,
  });

  @override
  State<FutureHistoryFullScreen> createState() =>
      _FutureHistoryFullScreenState();
}

class _FutureHistoryFullScreenState extends State<FutureHistoryFullScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'My Trades',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: futureDmSans,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.transparent,
            indicator: const BoxDecoration(),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: futureDmSans,
              height: 1.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              fontFamily: futureDmSans,
              height: 1.5,
            ),
            dividerColor: Colors.transparent,
            dividerHeight: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: const [
              Tab(text: 'Open Order'),
              Tab(text: 'Order History'),
              Tab(text: 'Trade History'),
              Tab(text: 'Position History'),
              Tab(text: 'Funding History'),
              Tab(text: 'Futures Bonus'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _FutureOrderTabView(
            ctrl: widget.ctrl,
            pair: widget.pair,
            pp: widget.pp,
            filter: 'open',
          ),
          _FutureOrderTabView(
            ctrl: widget.ctrl,
            pair: widget.pair,
            pp: widget.pp,
            filter: 'history',
          ),
          _FutureOrderTabView(
            ctrl: widget.ctrl,
            pair: widget.pair,
            pp: widget.pp,
            filter: 'all',
          ),
          _FuturePositionHistoryTab(ctrl: widget.ctrl, pp: widget.pp),
          const _FutureNoDataTab(label: 'Funding History'),
          const _FutureNoDataTab(label: 'Futures Bonus'),
        ],
      ),
    );
  }
}

class _FutureNoDataTab extends StatefulWidget {
  final String label;
  const _FutureNoDataTab({this.label = ''});

  @override
  State<_FutureNoDataTab> createState() => _FutureNoDataTabState();
}

class _FutureNoDataTabState extends State<_FutureNoDataTab> {
  String? selectedSymbol;
  String? selectedType;
  String? selectedStatus;

  void _showFilterDrawer({
    required String title,
    required List<String> options,
    required String? selected,
    required void Function(String?) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FutureFilterDrawer(
        title: title,
        options: options,
        selected: selected,
        onSelect: (val) {
          Navigator.pop(context);
          setState(() => onSelect(val));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              _FutureFilterChipBtn(
                label: 'Pair',
                selected: selectedSymbol,
                onTap: () => _showFilterDrawer(
                  title: 'Select Pair',
                  options: const ['USDT', 'BTC', 'USDC'],
                  selected: selectedSymbol,
                  onSelect: (v) => selectedSymbol = v,
                ),
              ),
              const SizedBox(width: 8),
              _FutureFilterChipBtn(
                label: 'Order Type',
                selected: selectedType,
                onTap: () => _showFilterDrawer(
                  title: 'Select Order Type',
                  options: const ['Buy', 'Sell'],
                  selected: selectedType,
                  onSelect: (v) => selectedType = v,
                ),
              ),
              const SizedBox(width: 8),
              _FutureFilterChipBtn(
                label: 'Status',
                selected: selectedStatus,
                onTap: () => _showFilterDrawer(
                  title: 'Select Status',
                  options: const ['Success', 'Pending'],
                  selected: selectedStatus,
                  onSelect: (v) => selectedStatus = v,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'No records found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontFamily: futureDmSans,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Position History Tab ──────────────────────────────────────────────────────
class _FuturePositionHistoryTab extends StatefulWidget {
  final NewFutureController ctrl;
  final int pp;

  const _FuturePositionHistoryTab({required this.ctrl, required this.pp});

  @override
  State<_FuturePositionHistoryTab> createState() => _FuturePositionHistoryTabState();
}

class _FuturePositionHistoryTabState extends State<_FuturePositionHistoryTab> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!_loaded) {
      _loaded = true;
      widget.ctrl.fetchPositionHistory();
    }
  }

  String _fmtDate(String s) {
    if (s.isEmpty) return '—';
    try {
      final dt = DateTime.parse(s).toLocal();
      return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = widget.ctrl.positionHistory;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                _FutureFilterChipBtn(
                  label: 'Pair',
                  selected: null,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _FutureFilterChipBtn(
                  label: 'Order Type',
                  selected: null,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _FutureFilterChipBtn(
                  label: 'Status',
                  selected: null,
                  onTap: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      'No records found',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                        fontFamily: futureDmSans,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final pos = list[i];
                      final isLong = pos.side == 'long';
                      final pnlPos = pos.pnl >= 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: futureCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: futureBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(pos.symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: futureDmSans)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isLong ? futureGreenLight : futureRedLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isLong ? 'Long' : 'Short',
                                    style: TextStyle(color: isLong ? futureGreen : futureRed, fontSize: 12, fontFamily: futureDmSans),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: futureCard2, borderRadius: BorderRadius.circular(4)),
                                  child: Text('${pos.leverage}x', style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: futureDmSans)),
                                ),
                                const Spacer(),
                                Text(
                                  pos.status.toUpperCase(),
                                  style: TextStyle(
                                    color: pos.status == 'liquidated' ? futureRed : Colors.white54,
                                    fontSize: 11,
                                    fontFamily: futureDmSans,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _phItem('Entry Price', pos.entryPrice.toStringAsFixed(widget.pp))),
                                Expanded(child: _phItem('Close Price', pos.closePrice.toStringAsFixed(widget.pp))),
                                Expanded(child: _phItem('Quantity', pos.quantity.toStringAsFixed(4))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(child: _phItem('Margin', '${pos.margin.toStringAsFixed(2)} USDT')),
                                Expanded(child: _phItem('Fee', '-${pos.fee.toStringAsFixed(4)} USDT')),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('PnL', style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11, fontFamily: futureDmSans)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${pnlPos ? "+" : ""}${pos.pnl.toStringAsFixed(4)} USDT',
                                        style: TextStyle(color: pnlPos ? futureGreen : futureRed, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: futureDmSans),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(child: _phItem('Opened', _fmtDate(pos.openedAt))),
                                Expanded(child: _phItem('Closed', _fmtDate(pos.closedAt))),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  Widget _phItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11, fontFamily: futureDmSans)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: futureDmSans)),
      ],
    );
  }
}

class _FutureOrderTabView extends StatefulWidget {
  final NewFutureController ctrl;
  final FuturePair? pair;
  final int pp;
  final String filter; // 'open', 'history', 'all'

  const _FutureOrderTabView({
    required this.ctrl,
    required this.pair,
    required this.pp,
    required this.filter,
  });

  @override
  State<_FutureOrderTabView> createState() => _FutureOrderTabViewState();
}

class _FutureOrderTabViewState extends State<_FutureOrderTabView> {
  List<FutureOrder> _filteredList = [];
  bool _isFilterActive = false;

  List<FutureOrder> _baseList(List<FutureOrder> all) {
    if (widget.filter == 'open')
      return all.where((o) => o.status == 'pending').toList();
    if (widget.filter == 'history')
      return all.where((o) => o.status != 'pending').toList();
    return all.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allList = _baseList(widget.ctrl.orders.toList());
      final displayList = _isFilterActive ? _filteredList : allList;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: _FutureFilterBar(
              orders: allList,
              filter: widget.filter,
              onFiltered: (filtered) {
                setState(() {
                  _filteredList = filtered;
                  _isFilterActive = true;
                });
              },
              onReset: () {
                setState(() {
                  _filteredList = [];
                  _isFilterActive = false;
                });
              },
            ),
          ),
          Expanded(
            child: displayList.isEmpty
                ? Center(
                    child: Text(
                      'No records found',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                        fontFamily: futureDmSans,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: displayList.length,
                    itemBuilder: (_, i) => _HistoryOrderCard(
                      order: displayList[i],
                      pp: widget.pp,
                      qp: widget.pair?.quantityPrecision ?? 4,
                      showDelete: widget.filter == 'open',
                      onDelete: widget.filter == 'open'
                          ? () => widget.ctrl.cancelOrder(displayList[i].id)
                          : null,
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

// ── Future Filter Bar ─────────────────────────────────────────────────────────
class _FutureFilterBar extends StatefulWidget {
  final List<FutureOrder> orders;
  final String filter; // 'open', 'history', 'all'
  final Function(List<FutureOrder>) onFiltered;
  final VoidCallback onReset;

  const _FutureFilterBar({
    required this.orders,
    required this.filter,
    required this.onFiltered,
    required this.onReset,
  });

  @override
  State<_FutureFilterBar> createState() => _FutureFilterBarState();
}

class _FutureFilterBarState extends State<_FutureFilterBar> {
  String? selectedSymbol;
  String? selectedType;
  String? selectedStatus;

  void _applyFilters() {
    if (selectedSymbol == null &&
        selectedType == null &&
        selectedStatus == null) {
      widget.onReset();
      return;
    }
    List<FutureOrder> result = List.from(widget.orders);
    if (selectedSymbol != null) {
      result = result
          .where(
            (o) =>
                o.symbol.toUpperCase().contains(selectedSymbol!.toUpperCase()),
          )
          .toList();
    }
    if (selectedType != null) {
      result = result.where((o) {
        final isLong = o.side == 'long' || o.side == 'buy';
        return selectedType == 'Buy' ? isLong : !isLong;
      }).toList();
    }
    if (selectedStatus != null) {
      result = result.where((o) {
        final isCompleted = o.status == 'completed' || o.status == 'filled';
        return selectedStatus == 'Success' ? isCompleted : !isCompleted;
      }).toList();
    }
    widget.onFiltered(result);
  }

  void _showFilterDrawer({
    required String title,
    required List<String> options,
    required String? selected,
    required void Function(String?) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FutureFilterDrawer(
        title: title,
        options: options,
        selected: selected,
        onSelect: (val) {
          Navigator.pop(context);
          setState(() => onSelect(val));
          WidgetsBinding.instance.addPostFrameCallback((_) => _applyFilters());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Derive unique symbols from orders for pair filter
    final symbols = widget.orders
        .map((o) {
          final sym = o.symbol.toUpperCase();
          if (sym.endsWith('USDT')) return 'USDT';
          if (sym.endsWith('BTC')) return 'BTC';
          if (sym.endsWith('USDC')) return 'USDC';
          return sym;
        })
        .toSet()
        .toList();
    if (symbols.isEmpty) symbols.addAll(['USDT', 'BTC']);

    return Row(
      children: [
        _FutureFilterChipBtn(
          label: 'Pair',
          selected: selectedSymbol,
          onTap: () => _showFilterDrawer(
            title: 'Select Pair',
            options: symbols,
            selected: selectedSymbol,
            onSelect: (v) => selectedSymbol = v,
          ),
        ),
        const SizedBox(width: 8),
        _FutureFilterChipBtn(
          label: 'Order Type',
          selected: selectedType,
          onTap: () => _showFilterDrawer(
            title: 'Select Order Type',
            options: const ['Buy', 'Sell'],
            selected: selectedType,
            onSelect: (v) => selectedType = v,
          ),
        ),
        if (widget.filter != 'open') ...[
          const SizedBox(width: 8),
          _FutureFilterChipBtn(
            label: 'Status',
            selected: selectedStatus,
            onTap: () => _showFilterDrawer(
              title: 'Select Status',
              options: const ['Success', 'Pending'],
              selected: selectedStatus,
              onSelect: (v) => selectedStatus = v,
            ),
          ),
        ],
      ],
    );
  }
}

class _FutureFilterChipBtn extends StatelessWidget {
  const _FutureFilterChipBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String? selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = selected != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected ?? label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFFD4F000)
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontFamily: futureDmSans,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isActive
                  ? const Color(0xFFD4F000)
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _FutureFilterDrawer extends StatelessWidget {
  const _FutureFilterDrawer({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });
  final String title;
  final List<String> options;
  final String? selected;
  final Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: futureDmSans,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _FutureDrawerOption(
            label: 'All',
            isSelected: selected == null,
            onTap: () => onSelect(null),
          ),
          ...options.map(
            (opt) => _FutureDrawerOption(
              label: opt,
              isSelected: selected == opt,
              onTap: () => onSelect(opt),
            ),
          ),
        ],
      ),
    );
  }
}

class _FutureDrawerOption extends StatelessWidget {
  const _FutureDrawerOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.07),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFD4F000)
                    : Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
                fontFamily: futureDmSans,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: Color(0xFFD4F000),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryOrderCard extends StatelessWidget {
  final FutureOrder order;
  final int pp;
  final int qp;
  final bool showDelete;
  final VoidCallback? onDelete;

  const _HistoryOrderCard({
    required this.order,
    required this.pp,
    required this.qp,
    required this.showDelete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLong = order.side == 'long' || order.side == 'buy';
    final sideColor = isLong ? futureGreen : futureRed;
    final rawType = order.orderType;
    final orderTypeCap = rawType.isNotEmpty
        ? rawType[0].toUpperCase() + rawType.substring(1).toLowerCase()
        : 'Limit';
    final typeLabel = '${isLong ? 'Buy' : 'Sell'} $orderTypeCap';
    final isCompleted = order.status == 'completed' || order.status == 'filled';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── ROW 1: Symbol + delete/date ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
          child: Row(
            children: [
              Text(
                order.symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: futureDmSans,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              if (showDelete)
                GestureDetector(
                  onTap: onDelete,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Image.asset(
                      'assets/icons/delete.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                Text(
                  order.createdAt,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: futureDmSans,
                    height: 1.33,
                  ),
                ),
            ],
          ),
        ),
        // ── ROW 2: Type label + date (open orders only) ───────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
          child: Row(
            children: [
              Text(
                typeLabel,
                style: TextStyle(
                  color: sideColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  fontFamily: futureDmSans,
                  height: 1.066,
                ),
              ),
              const Spacer(),
              if (showDelete)
                Text(
                  order.createdAt,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: futureDmSans,
                    height: 1.33,
                  ),
                ),
            ],
          ),
        ),
        // ── Field rows ────────────────────────────────────────────────────────
        _row('Amount', order.quantity.toStringAsFixed(qp)),
        _row('Fee (USDT)', order.fee.toStringAsFixed(4)),
        _row('Price (USDT)', order.price.toStringAsFixed(pp)),
        _row('Total (USDT)', order.margin.toStringAsFixed(2)),
        if (!showDelete) _statusRow(isCompleted),
        const SizedBox(height: 10),
        Divider(
          height: 0,
          thickness: 0.5,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontFamily: futureDmSans,
            fontWeight: FontWeight.w400,
            height: 1.33,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: futureDmSans,
            fontWeight: FontWeight.w400,
            height: 1.066,
          ),
        ),
      ],
    ),
  );

  Widget _statusRow(bool isCompleted) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Text(
          'Status',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontFamily: futureDmSans,
            fontWeight: FontWeight.w400,
            height: 1.33,
          ),
        ),
        const Spacer(),
        Text(
          isCompleted ? 'Success' : order.status,
          style: TextStyle(
            color: isCompleted
                ? const Color(0xFF00B052)
                : const Color(0xFFD4F000),
            fontSize: 15,
            fontFamily: futureDmSans,
            fontWeight: FontWeight.w400,
            height: 1.066,
          ),
        ),
      ],
    ),
  );
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class FutureInfoCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextAlign? textAlign;
  const FutureInfoCell({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final align = textAlign ?? TextAlign.start;
    final crossAxis = align == TextAlign.end
        ? CrossAxisAlignment.end
        : align == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Expanded(
      child: Column(
        crossAxisAlignment: crossAxis,
        children: [
          Text(
            label,
            textAlign: align,
            style: const TextStyle(
              fontSize: 9,
              color: futureMuted,
              fontFamily: futureDmSans,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: align,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: valueColor ?? futureTextWhite,
              fontFamily: futureDmSans,
            ),
          ),
        ],
      ),
    );
  }
}

class FutureActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const FutureActionBtn({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: futureBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: futureTextWhite,
            fontFamily: futureDmSans,
          ),
        ),
      ),
    );
  }
}

// ── Coin color map (same as spot) ─────────────────────────────────────────────
const _kFutureCoinColors = <String, Color>{
  'BTC': Color(0xFFF7931A),
  'ETH': Color(0xFF627EEA),
  'BNB': Color(0xFFF3BA2F),
  'XRP': Color(0xFF346AA9),
  'SOL': Color(0xFF9945FF),
  'DOGE': Color(0xFFC2A633),
  'ADA': Color(0xFF0033AD),
  'DOT': Color(0xFFE6007A),
  'AVAX': Color(0xFFE84142),
  'MATIC': Color(0xFF8247E5),
  'LINK': Color(0xFF2A5ADA),
  'LTC': Color(0xFF838383),
  'TRX': Color(0xFFEF0027),
  'SHIB': Color(0xFFFFA409),
  'UNI': Color(0xFFFF007A),
  'ATOM': Color(0xFF2E3148),
  'BCH': Color(0xFF8DC351),
  'FIL': Color(0xFF0090FF),
  'APT': Color(0xFF00C2CB),
  'ARB': Color(0xFF28A0F0),
  'OP': Color(0xFFFF0420),
  'SUI': Color(0xFF4DA2FF),
  'NEAR': Color(0xFF00C08B),
  'FTM': Color(0xFF1969FF),
};

// ── Coin icon widget with CDN fallbacks (matches spot _CoinIcon) ──────────────
class _FutureCoinIcon extends StatefulWidget {
  final String symbol;
  const _FutureCoinIcon({required this.symbol});

  @override
  State<_FutureCoinIcon> createState() => _FutureCoinIconState();
}

class _FutureCoinIconState extends State<_FutureCoinIcon> {
  static const double _size = 22.0;
  int _attempt = 0; // 0=atomiclabs, 1=coincap, 2=fallback

  @override
  void didUpdateWidget(_FutureCoinIcon old) {
    super.didUpdateWidget(old);
    if (old.symbol != widget.symbol) _attempt = 0;
  }

  String? _urlForAttempt(int attempt, String sym) {
    final slug = sym.toLowerCase();
    if (attempt == 0)
      return 'https://cdn.jsdelivr.net/gh/atomiclabs/cryptocurrency-icons@1a63530be6e374711a8554f31b17e4cb92c25fa/128/color/$slug.png';
    if (attempt == 1)
      return 'https://assets.coincap.io/assets/icons/${slug}@2x.png';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sym = widget.symbol.toUpperCase();
    final coinColor = _kFutureCoinColors[sym] ?? const Color(0xFF444444);
    final label = sym.length >= 2
        ? sym.substring(0, 2)
        : (sym.isNotEmpty ? sym : '?');

    final fallback = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            coinColor.withValues(alpha: 0.27),
            coinColor.withValues(alpha: 0.53),
          ],
        ),
        border: Border.all(color: coinColor.withValues(alpha: 0.4), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          fontFamily: futureDmSans,
          letterSpacing: 0.3,
        ),
      ),
    );

    final url = _urlForAttempt(_attempt, sym);
    if (url == null) return fallback;

    return SizedBox(
      width: _size,
      height: _size,
      child: ClipOval(
        child: Image.network(
          url,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _attempt++);
            });
            return fallback;
          },
        ),
      ),
    );
  }
}

// ── Pair Selection Drawer (bottom sheet, matches spot UI) ─────────────────────
class FuturePairDrawer extends StatefulWidget {
  final NewFutureController ctrl;
  final void Function(FuturePair pair, String limitPx, int leverage)
  onPairSelected;

  const FuturePairDrawer({
    super.key,
    required this.ctrl,
    required this.onPairSelected,
  });

  static void show(
    BuildContext context,
    NewFutureController ctrl,
    void Function(FuturePair pair, String limitPx, int leverage) onPairSelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: FuturePairDrawer(
          ctrl: ctrl,
          onPairSelected: (pair, limitPx, leverage) {
            Navigator.pop(context);
            onPairSelected(pair, limitPx, leverage);
          },
        ),
      ),
    );
  }

  @override
  State<FuturePairDrawer> createState() => _FuturePairDrawerState();
}

class _FuturePairDrawerState extends State<FuturePairDrawer> {
  String _search = '';
  String _quoteTab = 'ALL';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Future Pairs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: futureDmSans,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.cancel_outlined, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Search field matching spot style
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFFCCFF00), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontFamily: futureDmSans,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontFamily: futureDmSans,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Quote tabs
          Row(
            children: ['ALL', 'USDT', 'INR'].map((tab) {
              final active = _quoteTab == tab;
              return GestureDetector(
                onTap: () => setState(() => _quoteTab = tab),
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        tab,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : Colors.white54,
                          fontFamily: futureDmSans,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          // Column headers
          const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Coin',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    fontFamily: futureDmSans,
                    height: 20 / 15,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Last',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    fontFamily: futureDmSans,
                    height: 20 / 15,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Change',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    fontFamily: futureDmSans,
                    height: 20 / 15,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Obx(() {
              final filtered = widget.ctrl.pairs.where((p) {
                final matchSearch =
                    p.symbol.toLowerCase().contains(_search.toLowerCase()) ||
                    p.baseCurrency.toLowerCase().contains(
                      _search.toLowerCase(),
                    );
                final matchQuote =
                    _quoteTab == 'ALL' ||
                    p.quoteCurrency.toUpperCase() == _quoteTab;
                return matchSearch && matchQuote;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    'No pairs found',
                    style: TextStyle(
                      color: Colors.white54,
                      fontFamily: futureDmSans,
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  final change = p.priceChange24h;
                  final changeColor = change >= 0
                      ? const Color(0xFF0ECB81)
                      : const Color(0xFFF6465D);
                  final price = p.currentPrice.toStringAsFixed(4);
                  final vol = formatFutureVolume(p.volume24h);

                  return InkWell(
                    onTap: () => widget.onPairSelected(p, price, p.leverageMin),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon + name + volume
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                _FutureCoinIcon(symbol: p.baseCurrency),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          text: p.baseCurrency,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: futureDmSans,
                                            height: 20 / 15,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: '/${p.quoteCurrency}',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w300,
                                                fontFamily: futureDmSans,
                                                height: 20 / 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (p.volume24h > 0)
                                        Text(
                                          '\$$vol',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: futureDmSans,
                                          ),
                                          maxLines: 1,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Price
                          Expanded(
                            child: Text(
                              price,
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                fontFamily: futureDmSans,
                                height: 20 / 15,
                              ),
                            ),
                          ),
                          // Change %
                          Expanded(
                            child: Text(
                              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: changeColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                fontFamily: futureDmSans,
                                height: 20 / 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Modals ────────────────────────────────────────────────────────────────────
class FutureOverlayModal extends StatelessWidget {
  final Widget content;
  final VoidCallback onDismiss;

  const FutureOverlayModal({
    super.key,
    required this.content,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 430),
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class FutureMarginModeModal extends StatelessWidget {
  final String marginMode;
  final NewFutureController ctrl;
  final void Function(String mode) onSelected;

  const FutureMarginModeModal({
    super.key,
    required this.marginMode,
    required this.ctrl,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(
            () => Text(
              '${ctrl.currentPair.value?.symbol ?? 'BTCUSDT'} Perpetual Margin Mode',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: futureTextWhite,
                fontFamily: futureDmSans,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ModalOptionBtn(
                  label: 'Isolated',
                  active: marginMode == 'isolated',
                  onTap: () => onSelected('isolated'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModalOptionBtn(
                  label: 'Cross',
                  active: marginMode == 'cross',
                  onTap: () => onSelected('cross'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            marginMode == 'isolated'
                ? 'In Isolated Margin Mode, a specific amount of margin is allocated to an individual position. If the margin falls below the maintenance level, only that specific position will be liquidated.'
                : 'In Cross Margin Mode, the trader\'s entire account balance is used as collateral for all open positions.',
            style: const TextStyle(
              fontSize: 12,
              color: futureMuted,
              fontFamily: futureDmSans,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class FutureLeverageModal extends StatelessWidget {
  final int leverage;
  final void Function(int val) onSelected;

  const FutureLeverageModal({
    super.key,
    required this.leverage,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final leverageOptions = [1, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Leverage',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: futureTextWhite,
              fontFamily: futureDmSans,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: futureCard2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: futureBorder),
            ),
            child: Text(
              '${leverage}x',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: futureTextWhite,
                fontFamily: futureDmSans,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: leverageOptions.map((val) {
              final active = leverage == val;
              return GestureDetector(
                onTap: () => onSelected(val),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: futureCard2,
                    border: Border.all(
                      color: active ? futureTextWhite : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${val}x',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: futureTextWhite,
                      fontFamily: futureDmSans,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ModalOptionBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModalOptionBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? futureYellow : futureBorder,
            width: active ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: futureTextWhite,
            fontFamily: futureDmSans,
          ),
        ),
      ),
    );
  }
}

// ── TP/SL Modal ───────────────────────────────────────────────────────────────
class FutureTpSlModal {
  static void show(
    BuildContext context,
    FuturePosition pos,
    int pp,
    NewFutureController ctrl,
  ) {
    final tpCtrl = TextEditingController(
      text: pos.takeProfit?.toString() ?? '',
    );
    final slCtrl = TextEditingController(text: pos.stopLoss?.toString() ?? '');
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Take Profit / Stop Loss',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: futureTextWhite,
                fontFamily: futureDmSans,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Entry: ${pos.entryPrice.toStringAsFixed(pp)} · ${pos.side == 'long' ? 'Long' : 'Short'}',
              style: TextStyle(
                fontSize: 12,
                color: pos.side == 'long' ? futureGreen : futureRed,
                fontFamily: futureDmSans,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Take Profit Price',
                  style: TextStyle(
                    fontSize: 11,
                    color: futureGreen,
                    fontFamily: futureDmSans,
                  ),
                ),
                const SizedBox(height: 4),
                _ModalInput(ctrl: tpCtrl, hint: 'TP price (0 = disabled)'),
                const SizedBox(height: 12),
                const Text(
                  'Stop Loss Price',
                  style: TextStyle(
                    fontSize: 11,
                    color: futureRed,
                    fontFamily: futureDmSans,
                  ),
                ),
                const SizedBox(height: 4),
                _ModalInput(ctrl: slCtrl, hint: 'SL price (0 = disabled)'),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: futureCard2,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: futureBorder),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: futureTextWhite,
                          fontFamily: futureDmSans,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final success = await ctrl.updateTpSl(
                        pos.id,
                        double.tryParse(tpCtrl.text) ?? 0,
                        double.tryParse(slCtrl.text) ?? 0,
                      );
                      if (!context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.of(context).pop();
                      if (success) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          messenger.showSnackBar(
                            SnackBar(
                              content: const Text(
                                'TP/SL updated successfully',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: futureGreen,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        });
                      }
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: futureGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: futureTextWhite,
                          fontFamily: futureDmSans,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  const _ModalInput({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: futureCard2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: futureBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: futureTextWhite,
          fontFamily: futureDmSans,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: futureMuted,
            fontSize: 12,
            fontFamily: futureDmSans,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
