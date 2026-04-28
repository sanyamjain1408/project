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
const int _kMaxOrderBookRows = 8;
// ✅ 5 decimal digits
const int _kOrderDecimal = 5;

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
  });

  final String selectedOrderSort;
  final OrderData? order;
  final List<PriceData>? prices;
  final List<ExchangeOrder> buyList;
  final List<ExchangeOrder> sellList;
  final Function(String) onShortChange;
  final int selectedHeaderIndex;
  final Function(int) onHeaderChange;

  @override
  Widget build(BuildContext context) {
    final total = order?.total;
    PriceData? lastPData = prices.isValid ? prices?.first : PriceData();

    // ── Sell list: max 8, bottom-aligned (neeche se dikhao) ──────────────────
    List<ExchangeOrder> sList = [];
    if (selectedOrderSort != FromKey.buy) {
      final raw = sellList.length > _kMaxOrderBookRows
          ? sellList.sublist(sellList.length - _kMaxOrderBookRows)
          : List<ExchangeOrder>.from(sellList);
      sList = raw;
    }

    // ── Buy list: max 8, top-aligned (upar se dikhao) ────────────────────────
    List<ExchangeOrder> bList = [];
    if (selectedOrderSort != FromKey.sell) {
      bList = buyList.length > _kMaxOrderBookRows
          ? buyList.sublist(0, _kMaxOrderBookRows)
          : List<ExchangeOrder>.from(buyList);
    }

    // ── Fixed row height so both sections always occupy the same space ────────
    const double rowH = 18.0;
    const double sectionH = _kMaxOrderBookRows * rowH;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        vSpacer5(),

        // ── Header ────────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${"Price".tr}\n(${total?.baseWallet?.coinType ?? ""})",
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
                      text: "\n(${total?.tradeWallet?.coinType ?? ""})",
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

        // ── SELL LIST — fixed height box, items stick to BOTTOM ───────────────
        // Jab kam items aaye to upar blank space rehta hai
        if (selectedOrderSort != FromKey.buy)
          SizedBox(
            height: sectionH,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, // ✅ neeche se dikhao
              children: List.generate(sList.length, (index) {
                return OderBookItemMinView(
                  sList[index],
                  FromKey.sell,
                  selectedHeaderIndex == 1,
                  priceColor: const Color(0xFFD05858),
                  rowIndex: index,
                );
              }),
            ),
          ),

        vSpacer5(),

        // ── Mid price ─────────────────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    coinFormat(lastPData?.price, fixed: _kOrderDecimal),
                    style: const TextStyle(
                      color: Color(0xFFD05858),
                      fontSize: 15,
                      fontFamily: "DMSans",
                      fontWeight: FontWeight.w600,
                      height: 1.33,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            vSpacer5(),
            Text(
              "= \$${currencyFormat(lastPData?.lastPrice, fixed: _kOrderDecimal)}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontFamily: "DMSans",
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
          ],
        ),

        vSpacer5(),

        // ── BUY LIST — fixed height box, items stick to TOP ───────────────────
        // Jab kam items aaye to neeche blank space rehta hai
        if (selectedOrderSort != FromKey.sell)
          SizedBox(
            height: sectionH,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // ✅ upar se dikhao
              children: List.generate(bList.length, (index) {
                return OderBookItemMinView(
                  bList[index],
                  FromKey.buy,
                  selectedHeaderIndex == 1,
                  priceColor: const Color(0xFF4ED78E),
                  rowIndex: index,
                );
              }),
            ),
          ),

        vSpacer5(),

        // ── Bottom controls ───────────────────────────────────────────────────
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomDropdown(),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {},
              child: Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Image.asset(
                    "assets/icons/dot.png",
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
  });

  final ExchangeOrder order;
  final String type;
  final bool isTotal;
  final Color? priceColor;
  final int rowIndex;

  @override
  Widget build(BuildContext context) {
    final bgColor = type == FromKey.buy
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    final percent = getPercentageValue(1, order.percentage);
    // ✅ 5 decimal digits
    final value = isTotal
        ? numberFormatCompact(order.total, decimals: _kOrderDecimal)
        : coinFormat(order.amount, fixed: _kOrderDecimal);

    return Stack(
      children: [
        _OrderFillAnimation(
          color: bgColor,
          percent: percent,
          rowIndex: rowIndex,
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setSelectedPrice.value = order.price,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    // ✅ 5 decimal digits
                    coinFormat(order.price, fixed: _kOrderDecimal),
                    style: TextStyle(
                      color: priceColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                      fontFamily: "DMSans",
                    ),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                  ),
                ),
                Expanded(
                  child: TextRobotoAutoBold(
                    value,
                    color: Theme.of(context).primaryColor,
                    fontSize: Dimens.fontSizeSmall,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OrderFillAnimation
// ─────────────────────────────────────────────────────────────────────────────
class _OrderFillAnimation extends StatefulWidget {
  const _OrderFillAnimation({
    required this.color,
    required this.percent,
    required this.rowIndex,
  });

  final Color color;
  final double percent;
  final int rowIndex;

  @override
  State<_OrderFillAnimation> createState() => _OrderFillAnimationState();
}

class _OrderFillAnimationState extends State<_OrderFillAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fillAnim;

  @override
  void initState() {
    super.initState();
    final ms = 1600 + (widget.rowIndex * 139) % 1400;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );
    final base = widget.percent.clamp(0.05, 1.0);
    final minP = (base - 0.15).clamp(0.02, 1.0);
    final maxP = (base + 0.15).clamp(0.02, 1.0);
    _fillAnim = Tween<double>(begin: minP, end: maxP).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _ctrl.repeat(reverse: true);
    _ctrl.value = (widget.rowIndex * 0.19) % 1.0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fillAnim,
      builder: (context, _) {
        return CustomPaint(
          painter: _OrderFillPainter(
            color: widget.color,
            fillPercent: _fillAnim.value,
          ),
          child: const SizedBox(height: 18, width: double.infinity),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OrderFillPainter
// ─────────────────────────────────────────────────────────────────────────────
class _OrderFillPainter extends CustomPainter {
  _OrderFillPainter({required this.color, required this.fillPercent});

  final Color color;
  final double fillPercent;

  @override
  void paint(Canvas canvas, Size size) {
    final fillW = size.width * fillPercent.clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(size.width - fillW, 0, fillW, size.height),
      Paint()..color = color.withOpacity(0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _OrderFillPainter old) =>
      old.fillPercent != fillPercent || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAILS ORDER BOOK VIEW
// ─────────────────────────────────────────────────────────────────────────────
class DetailsOrderBookView extends StatelessWidget {
  const DetailsOrderBookView({
    super.key,
    this.total,
    required this.buyExchangeOrder,
    required this.sellExchangeOrder,
  });

  final Total? total;
  final List<ExchangeOrder> buyExchangeOrder;
  final List<ExchangeOrder> sellExchangeOrder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        listHeaderView(
          "${"Amount".tr} (${total?.tradeWallet?.coinType ?? ''})",
          "${"Price".tr} (${total?.baseWallet?.coinType ?? ''})",
          "${"Amount".tr} (${total?.tradeWallet?.coinType ?? ''})",
        ),
        vSpacer5(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _getListView(buyExchangeOrder, true)),
            hSpacer10(),
            Expanded(child: _getListView(sellExchangeOrder, false)),
          ],
        ),
      ],
    );
  }

  Widget _getListView(List<ExchangeOrder> list, bool isBuy) {
    final listLength = min(list.length, 100);
    final color = isBuy ? gBuyColor : gSellColor;
    return list.isEmpty
        ? showEmptyView(message: "No Orders Available".tr)
        : Column(
            children: List.generate(listLength, (index) {
              final order = list[index];
              // ✅ 5 decimal digits
              final fText = isBuy
                  ? coinFormat(order.amount, fixed: _kOrderDecimal)
                  : currencyFormat(order.price, fixed: _kOrderDecimal);
              final sText = isBuy
                  ? currencyFormat(order.price, fixed: _kOrderDecimal)
                  : coinFormat(order.amount, fixed: _kOrderDecimal);
              final percent = getPercentageValue(1, order.percentage);
              return InkWell(
                onTap: () => setSelectedPrice.value = order.price,
                child: Stack(
                  children: [
                    RotatedBox(
                      quarterTurns: -2,
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 20,
                        color: color.withValues(alpha: 0.15),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextRobotoAutoNormal(
                            fText,
                            color: isBuy ? null : color,
                          ),
                        ),
                        Expanded(
                          child: TextRobotoAutoNormal(
                            sText,
                            textAlign: TextAlign.end,
                            color: isBuy ? color : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
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
  String selectedValue = "0.01";
  final List<String> items = ["0.01", "0.1", "1"];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          dropdownColor: const Color(0xFF1A1A1A),
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.white.withOpacity(0.7),
            size: 18,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: "DMSans",
            fontWeight: FontWeight.w400,
          ),
          onChanged: (value) {
            setState(() => selectedValue = value!);
          },
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
        ),
      ),
    );
  }
}