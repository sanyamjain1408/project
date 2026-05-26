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
  final String bookFilter;
  final String countdown;
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
    required this.bookFilter,
    required this.countdown,
    required this.columnWidth,
    required this.onPriceTap,
    required this.precisionDropdown,
    required this.dotToggle,
  });

  @override
  Widget build(BuildContext context) {
    final showAsks = bookFilter == 'all' || bookFilter == 'sell';
    final showBids = bookFilter == 'all' || bookFilter == 'buy';
    final changeColor = change >= 0 ? const Color(0xFF007958) : const Color(0xFFD05850);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Container(
        //   margin: const EdgeInsets.only(bottom: 10),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Text('Funding/ Next Funding', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w400, fontFamily: futureDmSans)),
        //       const SizedBox(height: 2),
        //       Row(
        //         children: [
        //           Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: changeColor, fontFamily: futureDmSans)),
        //           const SizedBox(width: 4),
        //           Text('/ $countdown', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w400, fontFamily: futureDmSans)),
        //         ],
        //       ),
        //     ],
        //   ),
        // ),
        vSpacer5(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Price', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w400, fontFamily: futureDmSans)),
            Text('Total', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w400, fontFamily: futureDmSans)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('($quote)', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w400, fontFamily: futureDmSans)),
            Text('($base)', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w400, fontFamily: futureDmSans)),
          ],
        ),
        const SizedBox(height: 2),
        if (showAsks) ...[
          ...asks.map((ask) => _BookRow(price: ask['price'], amount: ask['amount'], pct: ask['pct'], pp: pp, isAsk: true, columnWidth: columnWidth, onTap: onPriceTap)),
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
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: change >= 0 ? const Color(0xFF4ED78E) : const Color(0xFFD05858), fontFamily: futureDmSans),
                    ),
                    const SizedBox(width: 4),
                    Icon(change >= 0 ? Icons.arrow_upward : Icons.arrow_downward, color: change >= 0 ? const Color(0xFF4ED78E) : const Color(0xFFD05858), size: 14),
                  ],
                ),
                Text('≈ \$${markPrice.toStringAsFixed(pp > 2 ? 2 : pp)}', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w400, fontFamily: futureDmSans)),
              ],
            ),
          ),
        ),
        if (showBids) ...[
          const SizedBox(height: 2),
          ...bids.map((bid) => _BookRow(price: bid['price'], amount: bid['amount'], pct: bid['pct'], pp: pp, isAsk: false, columnWidth: columnWidth, onTap: onPriceTap)),
        ],
        const SizedBox(height: 10),
        // B/S ratio bar
        Builder(builder: (context) {
          final totalAsk = asks.fold(0.0, (s, e) => s + (double.tryParse(e['amount'] ?? '0') ?? 0));
          final totalBid = bids.fold(0.0, (s, e) => s + (double.tryParse(e['amount'] ?? '0') ?? 0));
          final total = totalAsk + totalBid;
          final bidPct = total > 0 ? (totalBid / total * 100).round() : 50;
          final askPct = 100 - bidPct;
          return Container(
            height: 24,
            margin: const EdgeInsets.only(bottom: 8),
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
            Expanded(child: precisionDropdown),
            const SizedBox(width: 10),
            dotToggle,
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

  const _BookRow({required this.price, required this.amount, required this.pct, required this.pp, required this.isAsk, required this.columnWidth, required this.onTap});

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
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: color, fontFamily: 'monospace'),
                textAlign: TextAlign.left,
                maxLines: 1,
              ),
            ),
            Text(
              _formatAmount(amountVal),
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w400, fontFamily: 'monospace'),
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
    final labels = {'limit': 'Limit', 'market': 'Market', 'stop_limit': 'Stop limit'};
    final dotColor = buySell == 'Buy' ? futureGreen : futureRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _BtnDropdown(text: marginMode.capitalizeFirst!, onTap: onMarginModeTap)),
            const SizedBox(width: 10),
            Expanded(child: _BtnDropdown(text: '${leverage}x', onTap: onLeverageTap)),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 30,
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(5)),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              _TabBtn(label: 'Buy', active: buySell == 'Buy', activeColor: const Color(0xFF00B052), onTap: () => onBuySellChanged('Buy')),
              _TabBtn(label: 'Sell', active: buySell == 'Sell', activeColor: const Color(0xFFD73C3C), onTap: () => onBuySellChanged('Sell')),
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
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(child: Text(labels[orderType]!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: futureTextWhite, height: 16 / 12, fontFamily: futureDmSans))),
                    Positioned(right: 10, child: Text('▾', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)))),
                  ],
                ),
              ),
            ),
            if (showOrderTypeDropdown)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: labels.entries.map((e) {
                    final isSelected = orderType == e.key;
                    return GestureDetector(
                      onTap: () { onOrderTypeChanged(e.key); onOrderTypeDropdownToggle(false); },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00B052) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5), fontFamily: futureDmSans))),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        if (orderType == 'stop_limit') ...[
          const SizedBox(height: 8),
          FuturePriceInput(label: 'Trigger Price', value: triggerPx, onChanged: onTriggerPxChanged, pp: pp, isTrigger: true),
        ],
        if (orderType == 'limit' || orderType == 'stop_limit') ...[
          const SizedBox(height: 8),
          FuturePriceInput(label: 'Limit Price', value: limitPx, onChanged: onLimitPxChanged, pp: pp, limitPxCtrl: limitPxCtrl, limitPxFocus: limitPxFocus, onLimitPxUserEdited: () {}),
        ],
        const SizedBox(height: 8),
        FutureQtyInput(base: base, qty: qty, qp: qp, onChanged: onQtyChanged),
        const SizedBox(height: 8),
        // Slider dots
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [0, 25, 50, 75, 100].map((pct) {
            final active = sliderPct >= pct;
            return GestureDetector(
              onTap: () => onSliderPct(pct.toDouble()),
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: active ? dotColor : futureCard2,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: futureBorder),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onTpSlToggle(!showTpSl),
          child: Row(
            children: [
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  border: Border.all(color: showTpSl ? futureGreen : futureMuted),
                  borderRadius: BorderRadius.circular(2),
                  color: showTpSl ? futureGreen : Colors.transparent,
                ),
                child: showTpSl ? const Icon(Icons.check, size: 10, color: futureBg) : null,
              ),
              const SizedBox(width: 5),
              Text('TP/SL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.5), fontFamily: futureDmSans)),
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
              FuturePriceInput(label: 'Take-Profit Price', value: tp, onChanged: onTpChanged, pp: pp),
              const SizedBox(height: 8),
              FuturePriceInput(label: 'Take-Loss Price', value: sl, onChanged: onSlChanged, pp: pp),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FutureBalanceInfo(quote: quote, maxQty: maxQty, cost: cost, ctrl: ctrl),
        const SizedBox(height:10),
        Obx(() => GestureDetector(
          onTap: ctrl.orderLoading.value ? null : () => onPlaceOrder(),
          child: Container(
            width: double.infinity, height: 40,
            decoration: BoxDecoration(color: buySell == 'Buy' ? futureGreen : futureRed, borderRadius: BorderRadius.circular(6)),
            alignment: Alignment.center,
            child: Text(
              ctrl.orderLoading.value ? 'Processing...' : (buySell == 'Buy' ? 'Buy' : 'Sell'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: futureTextWhite, fontFamily: futureDmSans),
            ),
          ),
        )),
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
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: futureTextWhite, fontFamily: futureDmSans, height: 16 / 12)),
            const Spacer(),
            Text('▾', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
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
  const _TabBtn({required this.label, required this.active, required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: active ? activeColor : const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(5)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: active ? futureTextWhite : Colors.white.withValues(alpha: 0.8), fontFamily: futureDmSans)),
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
        : (TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length));
    final focusNode = isLimitField ? limitPxFocus : null;
    final step = math.pow(10, -pp).toDouble();

    return Container(
      height: 40,
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w400, height: 12 / 10, fontFamily: futureDmSans)),
                const SizedBox(height: 2),
                TextField(
                  controller: ctrl,
                  focusNode: focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 16 / 12, color: futureTextWhite, fontFamily: futureDmSans),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                  onChanged: (v) {
                    if (isLimitField) onLimitPxUserEdited?.call();
                    onChanged(v);
                  },
                ),
              ],
            ),
          ),
          _StepBtn(label: '−', onTap: () {
            final cur = double.tryParse(isLimitField ? ctrl.text : value) ?? 0;
            final newVal = math.max(0, cur - step).toStringAsFixed(pp);
            if (isLimitField) { onLimitPxUserEdited?.call(); ctrl.text = newVal; ctrl.selection = TextSelection.collapsed(offset: newVal.length); }
            onChanged(newVal);
          }),
          const SizedBox(width: 14),
          Container(height: 30, width: 1, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(width: 14),
          _StepBtn(label: '+', onTap: () {
            final cur = double.tryParse(isLimitField ? ctrl.text : value) ?? 0;
            final newVal = (cur + step).toStringAsFixed(pp);
            if (isLimitField) { onLimitPxUserEdited?.call(); ctrl.text = newVal; ctrl.selection = TextSelection.collapsed(offset: newVal.length); }
            onChanged(newVal);
          }),
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

  const FutureQtyInput({super.key, required this.base, required this.qty, required this.qp, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: qty)..selection = TextSelection.collapsed(offset: qty.length);
    final step = math.pow(10, -qp).toDouble();

    return Container(
      height: 40,
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qty $base', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), height: 12 / 10, fontWeight: FontWeight.w400, fontFamily: futureDmSans)),
                const SizedBox(height: 2),
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: futureTextWhite, height: 16 / 12, fontFamily: futureDmSans),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
          _StepBtn(label: '−', onTap: () {
            final cur = double.tryParse(qty) ?? 0;
            onChanged(math.max(0, cur - step).toStringAsFixed(qp));
          }),
          const SizedBox(width: 14),
          Container(height: 30, width: 1, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(width: 14),
          _StepBtn(label: '+', onTap: () {
            final cur = double.tryParse(qty) ?? 0;
            onChanged((cur + step).toStringAsFixed(qp));
          }),
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
        width: 22, height: 22,
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5), fontFamily: futureDmSans)),
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

  const FutureBalanceInfo({super.key, required this.quote, required this.maxQty, required this.cost, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Avail.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.5), fontFamily: futureDmSans)),
            Obx(() => Text('${ctrl.balance.value.toStringAsFixed(2)} $quote', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white, fontFamily: futureDmSans))),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Max', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.5), fontFamily: futureDmSans)),
            Text(maxQty, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white, fontFamily: futureDmSans)),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Cost', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.5), fontFamily: futureDmSans)),
            Text('$cost USDT', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white, fontFamily: futureDmSans)),
          ],
        ),
      ],
    );
  }
}

// ── Positions / Orders / Assets Section ──────────────────────────────────────
class FuturePositionsSection extends StatelessWidget {
  final FuturePair? pair;
  final int pp;
  final String bottomTab;
  final NewFutureController ctrl;
  final void Function(String tab) onTabChanged;
  final void Function(FuturePosition pos) onTpSlTap;
  final VoidCallback onLeverageTap;

  const FuturePositionsSection({
    super.key,
    required this.pair,
    required this.pp,
    required this.bottomTab,
    required this.ctrl,
    required this.onTabChanged,
    required this.onTpSlTap,
    required this.onLeverageTap,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = ['Position', 'Open Orders', 'Assets'];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: futureBorder, width: 8))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: futureBorder))),
            child: Row(
              children: tabs.map((t) {
                final active = bottomTab == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () => onTabChanged(t),
                    child: Column(
                      children: [
                        Text(t, style: TextStyle(fontSize: 15, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? futureTextWhite : futureMuted, fontFamily: futureDmSans)),
                        if (active) Container(margin: const EdgeInsets.only(top: 4), height: 2, width: 20, color: futureYellow),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: bottomTab == 'Position'
                ? _PositionsTab(pair: pair, pp: pp, ctrl: ctrl, onTpSlTap: onTpSlTap, onLeverageTap: onLeverageTap)
                : bottomTab == 'Open Orders'
                ? _OpenOrdersTab(pair: pair, pp: pp, ctrl: ctrl)
                : _AssetsTab(ctrl: ctrl),
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

  const _PositionsTab({required this.pair, required this.pp, required this.ctrl, required this.onTpSlTap, required this.onLeverageTap});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final openPositions = ctrl.positions.where((p) => p.status == 'open').toList();
      if (openPositions.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(child: Text('No open positions', style: TextStyle(fontSize: 13, color: futureMuted, fontFamily: futureDmSans))),
        );
      }
      return Column(children: openPositions.map((pos) => _PositionCard(pos: pos, pair: pair, pp: pp, ctrl: ctrl, onTpSlTap: onTpSlTap, onLeverageTap: onLeverageTap)).toList());
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

  const _PositionCard({required this.pos, required this.pair, required this.pp, required this.ctrl, required this.onTpSlTap, required this.onLeverageTap});

  @override
  Widget build(BuildContext context) {
    final isLong = pos.side == 'long';
    final markPrice = (pair != null && pair!.symbol == pos.symbol) ? pair!.currentPrice : pos.entryPrice;
    final rawPnl = isLong ? (markPrice - pos.entryPrice) * pos.quantity : (pos.entryPrice - markPrice) * pos.quantity;
    final pnl = rawPnl - pos.fee;
    final roi = pos.margin > 0 ? (pnl / pos.margin) * 100 : 0.0;
    final pnlColor = pnl >= 0 ? futureGreen : futureRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: futureCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: futureBorder)),
      child: Column(
        children: [
          Row(
            children: [
              Text(pos.symbol, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: futureTextWhite, fontFamily: futureDmSans)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: futureCard2, borderRadius: BorderRadius.circular(3)),
                child: Text('Cross ${pos.leverage}x', style: const TextStyle(fontSize: 10, color: futureMuted, fontFamily: futureDmSans)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: isLong ? futureGreenLight : futureRedLight, borderRadius: BorderRadius.circular(4)),
                child: Text(isLong ? 'Buy' : 'Sell', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isLong ? futureGreen : futureRed, fontFamily: futureDmSans)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('PNL (USDT)', style: TextStyle(fontSize: 10, color: futureMuted, fontFamily: futureDmSans)),
                Text('${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(4)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: pnlColor, fontFamily: futureDmSans)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('ROI', style: TextStyle(fontSize: 10, color: futureMuted, fontFamily: futureDmSans)),
                Text('${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(2)}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: pnlColor, fontFamily: futureDmSans)),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            FutureInfoCell(label: 'Size (USDT)', value: (pos.quantity * pos.entryPrice).toStringAsFixed(4)),
            FutureInfoCell(label: 'Margin (USDT)', value: pos.margin.toStringAsFixed(2)),
            FutureInfoCell(label: 'Margin Ratio', value: '1.0%', valueColor: futureGreen),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            FutureInfoCell(label: 'Entry Price', value: pos.entryPrice.toStringAsFixed(pp)),
            FutureInfoCell(label: 'Mark Price', value: markPrice.toStringAsFixed(pp)),
            FutureInfoCell(label: 'Liq. Price', value: pos.liquidationPrice.toStringAsFixed(pp), valueColor: futureRed),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: FutureActionBtn(label: 'Leverage', onTap: onLeverageTap)),
            const SizedBox(width: 8),
            Expanded(child: FutureActionBtn(label: 'TP/SL', onTap: () => onTpSlTap(pos))),
            const SizedBox(width: 8),
            Expanded(child: FutureActionBtn(label: 'Close', onTap: () => ctrl.closePosition(pos.id))),
          ]),
        ],
      ),
    );
  }
}

class _OpenOrdersTab extends StatelessWidget {
  final FuturePair? pair;
  final int pp;
  final NewFutureController ctrl;

  const _OpenOrdersTab({required this.pair, required this.pp, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final openOrders = ctrl.orders.where((o) => o.status == 'pending').toList();
      if (openOrders.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(child: Text('No open orders', style: TextStyle(fontSize: 13, color: futureMuted, fontFamily: futureDmSans))),
        );
      }
      return Column(children: openOrders.map((o) {
        final qp = pair?.quantityPrecision ?? 4;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: futureCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: futureBorder)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(o.symbol, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: futureTextWhite, fontFamily: futureDmSans)),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancel request sent'))),
                child: const Icon(Icons.delete_outline, color: futureRed, size: 18),
              ),
            ]),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${o.side == 'long' ? 'Buy' : 'Sell'} ${o.orderType}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: o.side == 'long' ? futureGreen : futureRed, fontFamily: futureDmSans)),
              Text(o.createdAt, style: const TextStyle(fontSize: 10, color: futureMuted, fontFamily: futureDmSans)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              FutureInfoCell(label: 'Amount', value: o.quantity.toStringAsFixed(qp)),
              FutureInfoCell(label: 'Fee (USDT)', value: o.fee.toStringAsFixed(4)),
              FutureInfoCell(label: 'Price (USDT)', value: o.price.toStringAsFixed(pp)),
              FutureInfoCell(label: 'Total (USDT)', value: o.margin.toStringAsFixed(2)),
            ]),
          ]),
        );
      }).toList());
    });
  }
}

class _AssetsTab extends StatelessWidget {
  final NewFutureController ctrl;
  const _AssetsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final positions = ctrl.positions;
      final unrealizedPnl = positions.fold<double>(0, (acc, p) {
        final isLong = p.side == 'long';
        final rawPnl = isLong ? (p.entryPrice - p.entryPrice) * p.quantity : (p.entryPrice - p.entryPrice) * p.quantity;
        return acc + rawPnl - p.fee;
      });
      final bal = ctrl.balance.value;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: futureCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: futureBorder)),
        child: Column(children: [
          _AssetRow(label: 'Currency Equity', value: '${bal.toStringAsFixed(4)} USDT'),
          const SizedBox(height: 8),
          _AssetRow(label: 'Available Margin', value: '${bal.toStringAsFixed(4)} USDT'),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Unrealized PnL', style: TextStyle(fontSize: 13, color: futureMuted, fontFamily: futureDmSans)),
            Text(
              '${unrealizedPnl >= 0 ? '+' : ''}${unrealizedPnl.toStringAsFixed(4)} USDT',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: unrealizedPnl >= 0 ? futureGreen : futureRed, fontFamily: futureDmSans),
            ),
          ]),
        ]),
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
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: futureMuted, fontFamily: futureDmSans)),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: futureTextWhite, fontFamily: futureDmSans)),
    ]);
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class FutureInfoCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const FutureInfoCell({super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: futureMuted, fontFamily: futureDmSans)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: valueColor ?? futureTextWhite, fontFamily: futureDmSans)),
      ]),
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
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: futureBorder)),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: futureTextWhite, fontFamily: futureDmSans)),
      ),
    );
  }
}

// ── Coin color map (same as spot) ─────────────────────────────────────────────
const _kFutureCoinColors = <String, Color>{
  'BTC': Color(0xFFF7931A), 'ETH': Color(0xFF627EEA), 'BNB': Color(0xFFF3BA2F),
  'XRP': Color(0xFF346AA9), 'SOL': Color(0xFF9945FF), 'DOGE': Color(0xFFC2A633),
  'ADA': Color(0xFF0033AD), 'DOT': Color(0xFFE6007A), 'AVAX': Color(0xFFE84142),
  'MATIC': Color(0xFF8247E5), 'LINK': Color(0xFF2A5ADA), 'LTC': Color(0xFF838383),
  'TRX': Color(0xFFEF0027), 'SHIB': Color(0xFFFFA409), 'UNI': Color(0xFFFF007A),
  'ATOM': Color(0xFF2E3148), 'BCH': Color(0xFF8DC351), 'FIL': Color(0xFF0090FF),
  'APT': Color(0xFF00C2CB), 'ARB': Color(0xFF28A0F0), 'OP': Color(0xFFFF0420),
  'SUI': Color(0xFF4DA2FF), 'NEAR': Color(0xFF00C08B), 'FTM': Color(0xFF1969FF),
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
    if (attempt == 0) return 'https://cdn.jsdelivr.net/gh/atomiclabs/cryptocurrency-icons@1a63530be6e374711a8554f31b17e4cb92c25fa/128/color/$slug.png';
    if (attempt == 1) return 'https://assets.coincap.io/assets/icons/${slug}@2x.png';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sym = widget.symbol.toUpperCase();
    final coinColor = _kFutureCoinColors[sym] ?? const Color(0xFF444444);
    final label = sym.length >= 2 ? sym.substring(0, 2) : (sym.isNotEmpty ? sym : '?');

    final fallback = Container(
      width: _size, height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [coinColor.withValues(alpha: 0.27), coinColor.withValues(alpha: 0.53)],
        ),
        border: Border.all(color: coinColor.withValues(alpha: 0.4), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, fontFamily: futureDmSans, letterSpacing: 0.3)),
    );

    final url = _urlForAttempt(_attempt, sym);
    if (url == null) return fallback;

    return SizedBox(
      width: _size, height: _size,
      child: ClipOval(
        child: Image.network(
          url,
          width: _size, height: _size,
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
  final void Function(FuturePair pair, String limitPx, int leverage) onPairSelected;

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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: FuturePairDrawer(ctrl: ctrl, onPairSelected: (pair, limitPx, leverage) {
          Navigator.pop(context);
          onPairSelected(pair, limitPx, leverage);
        }),
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
              const Text('Future Pairs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: futureDmSans)),
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
            decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF2A2A2A))),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFFCCFF00), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 14, color: Colors.white, fontFamily: futureDmSans),
                    decoration: const InputDecoration(hintText: 'Search', hintStyle: TextStyle(color: Colors.white54, fontFamily: futureDmSans), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
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
                      Text(tab, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? Colors.white : Colors.white54, fontFamily: futureDmSans)),
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
              Expanded(flex: 2, child: Text('Coin', style: TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w400, fontFamily: futureDmSans, height: 20 / 15))),
              Expanded(child: Text('Last', textAlign: TextAlign.end, style: TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w400, fontFamily: futureDmSans, height: 20 / 15))),
              Expanded(child: Text('Change', textAlign: TextAlign.end, style: TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w400, fontFamily: futureDmSans, height: 20 / 15))),
            ],
          ),
          Expanded(
            child: Obx(() {
              final filtered = widget.ctrl.pairs.where((p) {
                final matchSearch = p.symbol.toLowerCase().contains(_search.toLowerCase()) ||
                    p.baseCurrency.toLowerCase().contains(_search.toLowerCase());
                final matchQuote = _quoteTab == 'ALL' || p.quoteCurrency.toUpperCase() == _quoteTab;
                return matchSearch && matchQuote;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No pairs found', style: TextStyle(color: Colors.white54, fontFamily: futureDmSans)));
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  final change = p.priceChange24h;
                  final changeColor = change >= 0 ? const Color(0xFF0ECB81) : const Color(0xFFF6465D);
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          text: p.baseCurrency,
                                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: futureDmSans, height: 20 / 15),
                                          children: [
                                            TextSpan(
                                              text: '/${p.quoteCurrency}',
                                              style: const TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w300, fontFamily: futureDmSans, height: 20 / 15),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (p.volume24h > 0)
                                        Text('\$$vol', style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w400, fontFamily: futureDmSans), maxLines: 1),
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
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400, fontFamily: futureDmSans, height: 20 / 15),
                            ),
                          ),
                          // Change %
                          Expanded(
                            child: Text(
                              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: changeColor, fontSize: 15, fontWeight: FontWeight.w400, fontFamily: futureDmSans, height: 20 / 15),
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

  const FutureOverlayModal({super.key, required this.content, required this.onDismiss});

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
              decoration: const BoxDecoration(color: Color(0xFF121212), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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

  const FutureMarginModeModal({super.key, required this.marginMode, required this.ctrl, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => Text('${ctrl.currentPair.value?.symbol ?? 'BTCUSDT'} Perpetual Margin Mode', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: futureTextWhite, fontFamily: futureDmSans), textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _ModalOptionBtn(label: 'Isolated', active: marginMode == 'isolated', onTap: () => onSelected('isolated'))),
            const SizedBox(width: 12),
            Expanded(child: _ModalOptionBtn(label: 'Cross', active: marginMode == 'cross', onTap: () => onSelected('cross'))),
          ]),
          const SizedBox(height: 16),
          Text(
            marginMode == 'isolated'
                ? 'In Isolated Margin Mode, a specific amount of margin is allocated to an individual position. If the margin falls below the maintenance level, only that specific position will be liquidated.'
                : 'In Cross Margin Mode, the trader\'s entire account balance is used as collateral for all open positions.',
            style: const TextStyle(fontSize: 12, color: futureMuted, fontFamily: futureDmSans, height: 1.5),
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

  const FutureLeverageModal({super.key, required this.leverage, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final leverageOptions = [1, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Leverage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: futureTextWhite, fontFamily: futureDmSans)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: futureCard2, borderRadius: BorderRadius.circular(20), border: Border.all(color: futureBorder)),
            child: Text('${leverage}x', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: futureTextWhite, fontFamily: futureDmSans)),
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
                  width: 50, height: 50,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: futureCard2, border: Border.all(color: active ? futureTextWhite : Colors.transparent, width: 1.5)),
                  alignment: Alignment.center,
                  child: Text('${val}x', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: futureTextWhite, fontFamily: futureDmSans)),
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
  const _ModalOptionBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: active ? futureYellow : futureBorder, width: active ? 2 : 1)),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: futureTextWhite, fontFamily: futureDmSans)),
      ),
    );
  }
}

// ── TP/SL Modal ───────────────────────────────────────────────────────────────
class FutureTpSlModal {
  static void show(BuildContext context, FuturePosition pos, int pp, NewFutureController ctrl) {
    final tpCtrl = TextEditingController(text: pos.takeProfit?.toString() ?? '');
    final slCtrl = TextEditingController(text: pos.stopLoss?.toString() ?? '');
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Take Profit / Stop Loss', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: futureTextWhite, fontFamily: futureDmSans)),
            const SizedBox(height: 12),
            Text('Entry: ${pos.entryPrice.toStringAsFixed(pp)} · ${pos.side == 'long' ? 'Long' : 'Short'}', style: TextStyle(fontSize: 12, color: pos.side == 'long' ? futureGreen : futureRed, fontFamily: futureDmSans)),
            const SizedBox(height: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Take Profit Price', style: TextStyle(fontSize: 11, color: futureGreen, fontFamily: futureDmSans)),
              const SizedBox(height: 4),
              _ModalInput(ctrl: tpCtrl, hint: 'TP price (0 = disabled)'),
              const SizedBox(height: 12),
              const Text('Stop Loss Price', style: TextStyle(fontSize: 11, color: futureRed, fontFamily: futureDmSans)),
              const SizedBox(height: 4),
              _ModalInput(ctrl: slCtrl, hint: 'SL price (0 = disabled)'),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(height: 40, decoration: BoxDecoration(color: futureCard2, borderRadius: BorderRadius.circular(6), border: Border.all(color: futureBorder)), alignment: Alignment.center, child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: futureTextWhite, fontFamily: futureDmSans))),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: () async {
                  await ctrl.updateTpSl(pos.id, double.tryParse(tpCtrl.text) ?? 0, double.tryParse(slCtrl.text) ?? 0);
                  Get.back();
                },
                child: Container(height: 40, decoration: BoxDecoration(color: futureGreen, borderRadius: BorderRadius.circular(6)), alignment: Alignment.center, child: const Text('Confirm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: futureTextWhite, fontFamily: futureDmSans))),
              )),
            ]),
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
      decoration: BoxDecoration(color: futureCard2, borderRadius: BorderRadius.circular(6), border: Border.all(color: futureBorder)),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: futureTextWhite, fontFamily: futureDmSans),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: futureMuted, fontSize: 12, fontFamily: futureDmSans), border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10)),
      ),
    );
  }
}
