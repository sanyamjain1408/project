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
const int _kMaxOrderBookRows = 18; // greendot/reddot mode
const int _kAllModeRows = 9; // dot (all) mode
const int _kOrderDecimal = 5;
const double _kMinFillPercent = 0.05;

// Always shows at least 2 decimal places (e.g. "1.5" → "1.50", "100" → "100.00")
String _fmt2(num? n, {int fixed = _kOrderDecimal}) {
  final s = coinFormat(n, fixed: fixed);
  if (!s.contains('.')) return '$s.00';
  final decLen = s.length - s.indexOf('.') - 1;
  if (decLen < 2) return s + ('0' * (2 - decLen));
  return s;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.maxHeight != double.infinity;
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
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

            // ── SELL LIST ─────────────────────────────────────────────────────────
            if (selectedOrderSort != FromKey.buy)
              SizedBox(
                height: sectionH,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: List.generate(sList.length, (index) {
                    return OderBookItemMinView(
                      key: ValueKey('sell_${sList[index].price}'),
                      sList[index],
                      FromKey.sell,
                      selectedHeaderIndex == 1,
                      priceColor: const Color(0xFFD05858),
                      rowIndex: index,
                    );
                  }),
                ),
              ),

            if (selectedOrderSort != FromKey.buy) vSpacer10(),

            // ── Mid price — sell mode ya all mode ke baad sell list ke niche ──────
            if (selectedOrderSort != FromKey.buy)
              MidPriceBlock(
                lastPData: lastPData,
                priceColor: selectedOrderSort == FromKey.sell
                    ? const Color(0xFFD05858)
                    : (lastPData?.priceOrderType == FromKey.buy
                          ? const Color(0xFF4ED78E)
                          : const Color(0xFFD05858)),
              ),

            if (selectedOrderSort != FromKey.buy) vSpacer10(),

            // ── BUY LIST ──────────────────────────────────────────────────────────
            if (selectedOrderSort != FromKey.sell)
              SizedBox(
                height: sectionH,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(bList.length, (index) {
                    return OderBookItemMinView(
                      key: ValueKey('buy_${bList[index].price}'),
                      bList[index],
                      FromKey.buy,
                      selectedHeaderIndex == 1,
                      priceColor: const Color(0xFF4ED78E),
                      rowIndex: index,
                    );
                  }),
                ),
              ),

            // ── Mid price — buy-only mode mein buy list ke niche ─────────────────
            if (selectedOrderSort == FromKey.buy) vSpacer10(),
            if (selectedOrderSort == FromKey.buy)
              MidPriceBlock(
                lastPData: lastPData,
                priceColor: const Color(0xFF4ED78E),
              ),
            if (selectedOrderSort == FromKey.buy) vSpacer10(),

            if (bounded) const Spacer() else vSpacer5(),

            // ── Bottom controls ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: CustomDropdown(), //  ab ye full space lega
                ),
                const SizedBox(width: 8),
                _DotToggleButton(
                  selectedOrderSort: selectedOrderSort,
                  onToggle: onShortChange,
                ),
              ],
            ),
          ],
        );
      },
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
// MID PRICE BLOCK
// ─────────────────────────────────────────────────────────────────────────────
class MidPriceBlock extends StatelessWidget {
  const MidPriceBlock({
    super.key,
    required this.lastPData,
    required this.priceColor,
  });

  final PriceData? lastPData;
  final Color priceColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                _fmt2(lastPData?.price, fixed: 2),
                style: TextStyle(
                  color: priceColor,
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
          "= \$${_fmt2(lastPData?.lastPrice, fixed: 2)}",
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
            fontFamily: "DMSans",
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
      ],
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
class OderBookItemMinView extends StatefulWidget {
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
  State<OderBookItemMinView> createState() => _OderBookItemMinViewState();
}

class _OderBookItemMinViewState extends State<OderBookItemMinView>
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
  void didUpdateWidget(covariant OderBookItemMinView oldWidget) {
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
    final bgColor = widget.type == FromKey.buy
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    final value = widget.isTotal
        ? numberFormatCompact(widget.order.total, decimals: _kOrderDecimal)
        : _fmt2(widget.order.amount);

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return CustomPaint(
              painter: _OrderFillPainter(
                color: bgColor,
                fillPercent: _animation.value,
              ),
              child: const SizedBox(height: 18, width: double.infinity),
            );
          },
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setSelectedPrice.value = widget.order.price,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    (widget.order.price ?? 0).toDouble().toStringAsFixed(2),
                    style: TextStyle(
                      color: widget.priceColor,
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
// _OrderFillPainter — sirf drawing, koi animation nahi
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
              final fText = isBuy ? _fmt2(order.amount) : _fmt2(order.price);
              final sText = isBuy ? _fmt2(order.price) : _fmt2(order.amount);

              return _OrderBookDetailRow(
                key: ValueKey('${isBuy ? "buy" : "sell"}_${order.price}'),
                order: order,
                color: color,
                fText: fText,
                sText: sText,
                isBuy: isBuy,
              );
            }),
          );
  }
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
                    color: Colors.black.withOpacity(0.3),
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
                color: Colors.white.withOpacity(0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
