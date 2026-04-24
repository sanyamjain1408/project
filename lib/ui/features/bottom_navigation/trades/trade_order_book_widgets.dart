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
    List<ExchangeOrder> bList = [], sList = [];
    if (selectedOrderSort != FromKey.buy) {
      final listLength = getListLength(sellList);
      sList = sellList.sublist(sellList.length - listLength);
    }
    if (selectedOrderSort != FromKey.sell) {
      final listLength = getListLength(buyList);
      bList = buyList.take(listLength).toList();
    }

    final total = order?.total;
    PriceData? lastPData = prices.isValid ? prices?.first : PriceData();
    final isUp = (lastPData?.price ?? 0) >= (lastPData?.lastPrice ?? 0);
    final color = isUp ? gBuyColor : gSellColor;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
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
        vSpacer10(),
        selectedOrderSort == FromKey.buy
            ? vSpacer0()
            : Column(
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
        vSpacer5(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    coinFormat(lastPData?.price, fixed: tradeDecimal),
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
            Text(
              "= \$${currencyFormat(lastPData?.lastPrice, fixed: tradeDecimal)}",
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
        selectedOrderSort == FromKey.sell
            ? vSpacer0()
            : ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: Dimens.menuHeightSettings,
                ),
                child: Column(
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Decimal dropdown ──
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "0.01",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: "DMSans",
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Green / Red dots ──
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ED78E),
                      borderRadius:  BorderRadius.vertical(
                        top: Radius.circular(10),
                        bottom: Radius.circular(10),
                      )
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 8,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD05858),
                      // Sirf top rounded
                      borderRadius:  BorderRadius.vertical(
                        top: Radius.circular(10),
                        bottom: Radius.circular(10),
                      ) ),
                  ),
                ],
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

  int getListLength(List<ExchangeOrder> list) {
    int length = selectedOrderSort == FromKey.all
        ? DefaultValue.listLimitOrderBook ~/ 2
        : DefaultValue.listLimitOrderBook;
    length = list.length < length ? list.length : length;
    return length;
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
    final value = isTotal
        ? numberFormatCompact(order.total, decimals: tradeDecimal)
        : coinFormat(order.amount, fixed: tradeDecimal);

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
                    coinFormat(order.price, fixed: tradeDecimal),
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
// Completely new class name — purani cached state se conflict nahi hoga
// Right se left aata hai, phir wapis — continuously, har row alag phase
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

    _fillAnim = Tween<double>(
      begin: minP,
      end: maxP,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

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
// Right aligned — fillPercent ke hisaab se right se left tak color
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
              final fText = isBuy
                  ? coinFormat(order.amount, fixed: tradeDecimal)
                  : currencyFormat(order.price, fixed: tradeDecimal);
              final sText = isBuy
                  ? currencyFormat(order.price, fixed: tradeDecimal)
                  : coinFormat(order.amount, fixed: tradeDecimal);
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
