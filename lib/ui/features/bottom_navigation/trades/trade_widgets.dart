import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/exchange_order.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart';
import 'package:tradexpro_flutter/ui/features/charts/charts_screen.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:decimal/decimal.dart';

final setSelectedPrice = ValueNotifier<double?>(null);

class TradePairTopView extends StatelessWidget {
  const TradePairTopView({
    super.key,
    required this.coinPair,
    this.onTap,
    this.total,
    this.onTapIcon,
    this.onTapDetails,
  });

  final CoinPair coinPair;
  final Total? total;
  final VoidCallback? onTap;
  final VoidCallback? onTapIcon; // middle icon — toggles chart
  final VoidCallback? onTapDetails; // last icon — opens details screen

  @override
  Widget build(BuildContext context) {
    final (sing, color) = getNumberData(total?.tradeWallet?.priceChange);
    return Row(
      children: [
        hSpacer5(),
        InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child: Image.asset(
                  "assets/icons/menu.png",
                  width: 16,
                  height: 16, // optional tint
                ),
              ),
              hSpacer2(),
              Text(
                coinPair.getCoinPairName(),
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        hSpacer5(),
        // ── Plain inline text — no badge, no background ──────────────────────
        Text(
          "$sing${coinFormat(total?.tradeWallet?.priceChange, fixed: 2)}%",
          style: TextStyle(
            color: Color(0xFFD05858),
            fontSize: 12,
            fontFamily: "DMSans",
            height: 1.33,
          ),
        ),
        const Spacer(),
        // ── Star / Grid / Chart icons matching Image 2 ──────────────────────
        InkWell(
          onTap: () {}, // favourite toggle — wire up FavoriteHelper if needed
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              "assets/icons/star.png",
              width: 20,
              height: 20, // optional tint
            ),
          ),
        ),
        InkWell(
          onTap: onTapIcon, // toggles inline chart
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              "assets/icons/bar.png",
              width: 20,
              height: 20, // optional tint
            ),
          ),
        ),
        InkWell(
          onTap: onTapDetails,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              "assets/icons/candel.png",
              width: 20,
              height: 20, // optional tint
            ),
          ),
        ),
        hSpacer5(),
      ],
    );
  }
}

class TradeChartView extends StatelessWidget {
  const TradeChartView({super.key, required this.isShow, required this.onTap});

  final bool isShow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return isShow
        ? ChartsScreen(fromModal: true, onTapClose: onTap)
        : InkWell(
            onTap: onTap,
            child: Row(
              children: [
                hSpacer10(),
                TextRobotoAutoNormal("Candlestick".tr),
                const Spacer(),
                TextRobotoAutoNormal("Expand".tr),
                buttonOnlyIcon(
                  iconData: Icons.arrow_drop_down,
                  iconColor: context.theme.primaryColorLight,
                  visualDensity: minimumVisualDensity,
                ),
              ],
            ),
          );
  }
}

class BuySellToggleButton extends StatelessWidget {
  const BuySellToggleButton({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final int selected;
  final Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    final color = selected == 0 ? gBuyColor : gSellColor;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth.floor() - 4) / 2;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSelect(0),
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: selected == 0
                            ? const Color(0xFF00B052)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        options[0],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: "DMSans",
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 0),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSelect(1),
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        color: selected == 1
                            ? const Color(0xFFD73C3C)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        options[1],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: "DMSans",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TradeTextFieldCalculate extends StatelessWidget {
  const TradeTextFieldCalculate({
    super.key,
    this.controller,
    this.isEnable,
    this.onTextChange,
    this.sTitle,
    this.sSubtitle,
    this.text,
    this.hidePlusMinus,
  });

  final TextEditingController? controller;
  final bool? isEnable;
  final Function(String)? onTextChange;
  final String? sTitle;
  final String? sSubtitle;
  final String? text;
  final bool? hidePlusMinus;

  static const _bg = Color(0xFF1A1A1A);
  static const _white = Color(0xFFFFFFFF);
  static const _divider = Color(0xFF2A2A2A);

  @override
  Widget build(BuildContext context) {
    if (controller != null && text != null && text!.isNotEmpty) {
      controller!.text = text!;
    }

    final showButtons = hidePlusMinus != true && isEnable != false;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // ── LEFT: label + value ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                maxLines: 1,
                enabled: isEnable,
                cursorColor: Colors.white,
                style: const TextStyle(
                  color: _white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'DMSans',
                  height: 1.3,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  labelText: sTitle != null
                      ? (sSubtitle != null && sSubtitle!.isNotEmpty
                            ? "$sTitle"
                            : sTitle)
                      : null,
                  // ── bada size jab empty + unfocused ──
                  labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'DMSans',
                  ),
                  // ── chota size jab focused ya value hai ──
                  floatingLabelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'DMSans',
                  ),
                  floatingLabelBehavior:
                      FloatingLabelBehavior.auto, // ← key change
                ),
                onChanged: (value) {
                  if (onTextChange != null) onTextChange!(value);
                },
              ),
            ),
          ),

          // ── RIGHT: − | + buttons ──
          if (showButtons) ...[
            // Minus button
            GestureDetector(
              onTap: () => _plusMinusButtonAction(false),
              child: Container(
                width: 36,
                height: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  "−",
                  style: TextStyle(
                    color: _white.withOpacity(0.5),
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'DMSans',
                  ),
                ),
              ),
            ),

            // Vertical divider
            Container(width: 1, height: 24, color: _divider),

            // Plus button
            GestureDetector(
              onTap: () => _plusMinusButtonAction(true),
              child: Container(
                width: 36,
                height: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  "+",
                  style: TextStyle(
                    color: _white.withOpacity(0.5),
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'DMSans',
                  ),
                ),
              ),
            ),

            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  void _plusMinusButtonAction(bool isPlus) {
    if (controller == null) return;
    if (controller!.text.trim().isEmpty && !isPlus) return;
    if (isPlus) {
      final t = controller!.text.trim().isEmpty ? "0" : controller!.text.trim();
      final value = Decimal.parse(t) + Decimal.parse('0.01');
      controller!.text = value.toString();
    } else {
      Decimal value =
          Decimal.parse(controller!.text.trim()) - Decimal.parse('0.01');
      if (value.toDouble().isNegative) value = Decimal.parse('0');
      controller!.text = value.toDouble().toString();
    }
    if (onTextChange != null) onTextChange!(controller!.text);
  }
}

class TradeTextField extends StatelessWidget {
  const TradeTextField({
    super.key,
    this.controller,
    this.isEnable,
    this.onTextChange,
    this.sTitle,
    this.sSubtitle,
    this.text,
    this.suffix,
  });

  final TextEditingController? controller;
  final bool? isEnable;
  final Function(String)? onTextChange;
  final String? sTitle;
  final String? sSubtitle;
  final String? text;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    if (controller != null && text != null && text!.isNotEmpty)
      controller!.text = text!;

    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        maxLines: 1,
        cursorColor: context.theme.primaryColor,
        enabled: isEnable,
        textAlign: TextAlign.start,
        textAlignVertical: TextAlignVertical.center,
        style: context.theme.textTheme.displaySmall?.copyWith(
          color: context.theme.primaryColor,
        ),
        onChanged: (value) =>
            onTextChange == null ? null : onTextChange!(value),
        decoration: InputDecoration(
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Dimens.paddingMid,
            vertical: 2,
          ),
          enabledBorder: textFieldBorder(borderRadius: Dimens.radiusCorner),
          disabledBorder: textFieldBorder(borderRadius: Dimens.radiusCorner),
          focusedBorder: textFieldBorder(
            isFocus: true,
            borderRadius: Dimens.radiusCorner,
          ),
          suffixIcon:
              suffix ??
              ((sTitle.isValid || sSubtitle.isValid)
                  ? _textFieldTwoText(context)
                  : null),
        ),
      ),
    );
  }

  FittedBox _textFieldTwoText(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: Dimens.paddingMid),
        child: Column(
          children: [
            if (sTitle.isValid)
              Text(
                sTitle!,
                style: context.theme.textTheme.labelMedium?.copyWith(
                  fontSize: Dimens.fontSizeMidExtra,
                  height: 1,
                ),
              ),
            if (sTitle.isValid && sSubtitle.isValid) vSpacer2(),
            if (sSubtitle.isValid)
              Text(
                sSubtitle!,
                style: context.theme.textTheme.displaySmall?.copyWith(
                  fontSize: Dimens.fontSizeMin,
                  height: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CurrencyPairDetailsView extends StatelessWidget {
  const CurrencyPairDetailsView({
    super.key,
    required this.prices,
    required this.order,
  });

  final List<PriceData>? prices;
  final OrderData? order;

  @override
  Widget build(BuildContext context) {
    PriceData lastPData = prices.isValid ? prices!.first : PriceData();
    final isUp = (lastPData.price ?? 0) >= (lastPData.lastPrice ?? 0);
    final total = order?.total;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: coinDetailsItemView(
            currencyFormat(lastPData.price, fixed: tradeDecimal),
            "${currencyFormat(lastPData.lastPrice, fixed: DefaultValue.decimal)}(${total?.baseWallet?.coinType ?? ""})",
            isSwap: true,
            fromKey: isUp ? FromKey.up : FromKey.down,
          ),
        ),
        hSpacer10(),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _hlTextView(
                "24h high".tr,
                currencyFormat(total?.tradeWallet?.high, fixed: tradeDecimal),
              ),
              _hlTextView(
                "24h low".tr,
                currencyFormat(total?.tradeWallet?.low, fixed: tradeDecimal),
              ),
              _hlTextView(
                "24h volume".tr,
                "${currencyFormat(total?.tradeWallet?.volume, fixed: tradeDecimal)} ${total?.tradeWallet?.coinType ?? ""}",
              ),
              _hlTextView(
                "",
                "${currencyFormat(total?.baseWallet?.volume, fixed: tradeDecimal)} ${total?.baseWallet?.coinType ?? ""}",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Row _hlTextView(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: TextRobotoAutoNormal(
            title,
            textAlign: TextAlign.start,
            fontSize: Dimens.fontSizeMin,
          ),
        ),
        Expanded(
          flex: 4,
          child: TextRobotoAutoBold(
            value,
            textAlign: TextAlign.end,
            fontSize: Dimens.fontSizeSmall,
          ),
        ),
      ],
    );
  }
}

class _CoinIcon extends StatelessWidget {
  const _CoinIcon({required this.icon, required this.name});
  final String? icon;
  final String name;

  @override
  Widget build(BuildContext context) {
    const size = 20.0;
    final fallback = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Color(0xFFCCFF00),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: "DMSans",
        ),
      ),
    );

    if (icon == null || icon!.isEmpty) return fallback;

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.network(
          icon!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, _) => fallback,
        ),
      ),
    );
  }
}

class CoinPairItemView extends StatelessWidget {
  const CoinPairItemView({
    super.key,
    required this.coinPair,
    required this.onTap,
  });

  final CoinPair coinPair;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = coinPair.childCoinName ?? '';
    final parent = coinPair.parentCoinName ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Icon + Name + Volume column ──────────────────────────────────
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _CoinIcon(icon: coinPair.icon, name: child),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            text: child,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              fontFamily: "DMSans",
                              height: 20 / 15,
                            ),
                            children: [
                              if (parent.isNotEmpty)
                                TextSpan(
                                  text: '/$parent',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w300,
                                    fontFamily: "DMSans",
                                    height: 20 / 15,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if ((coinPair.volume ?? 0) > 0)
                          Text(
                            "\$${numberFormatCompact(coinPair.volume, decimals: 2)}",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              fontFamily: "DMSans",
                            ),
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Last price ───────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  coinPair.lastPrice != null
                      ? "${double.parse(coinPair.lastPrice.toString()).toStringAsFixed(4)}..."
                      : "0.0000...",
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    fontFamily: "DMSans",
                    height: 20 / 15,
                  ),
                ),
              ),
            ),
            // ── Change % ─────────────────────────────────────────────────────
            Expanded(
              child: Text(
                "${coinFormat(coinPair.priceChange, fixed: 2)}%",
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: getNumberColor(coinPair.priceChange),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  fontFamily: "DMSans",
                  height: 20 / 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TradeLoginButton extends StatelessWidget {
  const TradeLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return buttonRoundedMain(
      text: "Login".tr,
      bgColor: Colors.red,
      textColor: Colors.white,
      buttonHeight: Dimens.btnHeightMid,
      borderRadius: Dimens.radiusCornerLarge,
      onPress: () => Get.offAll(() => const SignInPage()),
    );
  }
}

class _CoinPairHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white54,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      fontFamily: "DMSans",
      height: 20 / 15,
    );
    return Row(
      children: [
        const Expanded(flex: 2, child: Text("Coin", style: style)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text("Last", textAlign: TextAlign.end, style: style),
          ),
        ),
        const Expanded(
          child: Text("Change", textAlign: TextAlign.end, style: style),
        ),
      ],
    );
  }
}

class TradeCurrencyPairSelectionView extends StatelessWidget {
  const TradeCurrencyPairSelectionView({
    super.key,
    required this.searchEditController,
    required this.onTextChange,
    required this.coinPairs,
    required this.onSelect,
    required this.title,
  });

  final String title;
  final TextEditingController searchEditController;
  final Function(String) onTextChange;
  final List<CoinPair> coinPairs;
  final Function(CoinPair) onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingLarge),
        margin: const EdgeInsets.symmetric(vertical: Dimens.paddingLarge),
        decoration: boxDecorationRightRound(
          color: context.theme.dialogTheme.backgroundColor,
          radius: Dimens.radiusCornerLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            vSpacer20(),
            Row(
              children: [
                TextRobotoAutoBold(title),
                const Spacer(),
                buttonOnlyIcon(
                  iconData: Icons.cancel_outlined,
                  visualDensity: minimumVisualDensity,
                  onPress: () => Navigator.pop(context),
                ),
              ],
            ),
            vSpacer10(),
            textFieldSearch(
              controller: searchEditController,
              height: Dimens.btnHeightMid,
              margin: 0,
              onTextChange: onTextChange,
              bgColor: const Color(0xFF111111),
              iconColor: const Color(0xFFCCFF00),
            ),
            vSpacer10(),
            _CoinPairHeader(),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: List.generate(coinPairs.length, (index) {
                  return CoinPairItemView(
                    coinPair: coinPairs[index],
                    onTap: () {
                      Get.back();
                      onSelect(coinPairs[index]);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TradeListView extends StatelessWidget {
  const TradeListView({super.key, this.total, required this.exchangeTrades});

  final Total? total;
  final List<ExchangeTrade> exchangeTrades;

  @override
  Widget build(BuildContext context) {
    final listLength = min(exchangeTrades.length, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextRobotoAutoNormal(
                "${"Price".tr}(${total?.baseWallet?.coinType ?? ""})",
              ),
            ),
            Expanded(
              child: TextRobotoAutoNormal(
                "${"Amount".tr}(${total?.tradeWallet?.coinType ?? ""})",
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: TextRobotoAutoNormal("Time".tr, textAlign: TextAlign.end),
            ),
          ],
        ),
        dividerHorizontal(height: Dimens.paddingMid),
        exchangeTrades.isEmpty
            ? showEmptyView()
            : Column(
                children: List.generate(listLength, (index) {
                  return TradeItemView(exchangeTrade: exchangeTrades[index]);
                }),
              ),
      ],
    );
  }
}

class TradeItemView extends StatelessWidget {
  const TradeItemView({super.key, required this.exchangeTrade});

  final ExchangeTrade exchangeTrade;

  @override
  Widget build(BuildContext context) {
    final color = (exchangeTrade.price ?? 0) > (exchangeTrade.lastPrice ?? 0)
        ? gBuyColor
        : ((exchangeTrade.price ?? 0) < (exchangeTrade.lastPrice ?? 0)
              ? gSellColor
              : context.theme.primaryColor);
    return InkWell(
      onTap: () => setSelectedPrice.value = exchangeTrade.price,
      child: Row(
        children: [
          Expanded(
            child: TextRobotoAutoNormal(
              currencyFormat(exchangeTrade.price, fixed: tradeDecimal),
              color: color,
            ),
          ),
          Expanded(
            child: TextRobotoAutoNormal(
              coinFormat(exchangeTrade.amount, fixed: tradeDecimal),
              textAlign: TextAlign.center,
              color: context.theme.primaryColor,
            ),
          ),
          Expanded(
            child: TextRobotoAutoNormal(
              exchangeTrade.time ?? "",
              textAlign: TextAlign.end,
              color: context.theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class TradeBottomButtonsView extends StatelessWidget {
  const TradeBottomButtonsView({
    super.key,
    required this.buyStr,
    required this.sellStr,
    required this.onTap,
  });

  final String buyStr;
  final String sellStr;
  final Function(bool) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
      decoration: boxDecorationTopRound(
        color: Theme.of(context).secondaryHeaderColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              buttonText(
                buyStr,
                bgColor: gBuyColor,
                visualDensity: VisualDensity.compact,
                onPress: () {
                  Navigator.pop(context);
                  onTap(true);
                },
                textColor: Colors.white,
              ),
              hSpacer10(),
              buttonText(
                sellStr,
                bgColor: gSellColor,
                visualDensity: VisualDensity.compact,
                onPress: () {
                  Navigator.pop(context);
                  onTap(false);
                },
                textColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TradePercentView extends StatelessWidget {
  const TradePercentView({super.key, required this.onTap});

  final Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 30) / 4;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(ListConstants.percents.length, (index) {
            final item = ListConstants.percents[index];
            return InkWell(
              onTap: () => onTap(item),
              child: _percentItemView(item, width),
            );
          }),
        );
      },
    );
  }

  Container _percentItemView(String item, double width) {
    return Container(
      height: Dimens.btnHeightMin,
      width: width,
      alignment: Alignment.center,
      decoration: boxDecorationRoundBorder(),
      child: TextRobotoAutoNormal("$item%"),
    );
  }
}

class TradeBalanceView extends StatelessWidget {
  const TradeBalanceView({
    super.key,
    this.balance,
    this.coinType,
    required this.onTap,
  });

  final double? balance;
  final String? coinType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "Avail".tr,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: "DMSans",
          ),
        ),
        hSpacer5(),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                coinFormat(balance, fixed: DefaultValue.cryptoDecimal),
                textAlign: TextAlign.end,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14, // ← balance ka size
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DMSans',
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                coinType ?? "",
                textAlign: TextAlign.end,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11, // ← coinType ka size
                  fontWeight: FontWeight.w400,
                  fontFamily: 'DMSans',
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 5),
        InkWell(
          onTap: onTap,
          child: Icon(
            Icons.add_circle_outline,
            color: Color(0xFF00B052),
            size: 20,
          ),
        ),
      ],
    );
  }
}
