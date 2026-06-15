import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/exchange_order.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/trades/trapix_chart_widget.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart';
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
    this.priceChangeOverride,
  });

  final CoinPair coinPair;
  final Total? total;
  final VoidCallback? onTap;
  final VoidCallback? onTapIcon; // middle icon — toggles chart
  final VoidCallback? onTapDetails; // last icon — opens details screen
  final double? priceChangeOverride; // used by spot to pass ticker.priceChange24h

  @override
  Widget build(BuildContext context) {
    final rawChange = priceChangeOverride ?? total?.tradeWallet?.priceChange;
    final (sing, color) = getNumberData(rawChange);
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
        // ── Plain inline text — green if up, red if down ────────────────────
        Text(
          "$sing${coinFormat(rawChange, fixed: 2)}%",
          style: TextStyle(
            color: color,
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

String _symbolFromPair(CoinPair? p) {
  // parentCoinName = base coin (e.g. BTC), childCoinName = quote coin (e.g. USDT)
  // API expects parentCoin + childCoin (e.g. BTCUSDT)
  final parent = p?.parentCoinName?.toUpperCase() ?? '';
  final child = p?.childCoinName?.toUpperCase() ?? '';
  if (parent.isNotEmpty && child.isNotEmpty) return '$parent$child';
  // fallback: coinPair field is "USDT_BTC" (childCoinName_parentCoinName) — swap to get BTCUSDT
  final cp = p?.coinPair ?? '';
  if (cp.isNotEmpty) {
    final parts = cp.split('_');
    if (parts.length == 2) return '${parts[1]}${parts[0]}'.toUpperCase();
    return cp.replaceAll('_', '').toUpperCase();
  }
  return 'BTCUSDT';
}

// ── Inline chart (shown on spot trade screen when bar icon tapped) ────────────
class TradeChartView extends StatelessWidget {
  const TradeChartView({
    super.key,
    required this.isShow,
    required this.onTap,
    this.coinPair,
  });
  final bool isShow;
  final VoidCallback onTap;
  final CoinPair? coinPair;

  @override
  Widget build(BuildContext context) {
    if (!isShow) return const SizedBox.shrink();
    final sym = _symbolFromPair(coinPair);
    return TrapixChartWidget(symbol: sym, height: Get.width * 0.85);
  }
}

// ── Full chart (shown in details screen) ─────────────────────────────────────
class TvChartFullView extends StatelessWidget {
  const TvChartFullView({super.key, this.coinPair});
  final CoinPair? coinPair;

  @override
  Widget build(BuildContext context) {
    final sym = _symbolFromPair(coinPair);
    return TrapixChartWidget(symbol: sym, height: Get.width * 1.1);
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

// Coin color map — same as website's COIN_COLORS
const _kCoinColors = <String, Color>{
  'BTC': Color(0xFFF7931A), 'ETH': Color(0xFF627EEA), 'BNB': Color(0xFFF3BA2F),
  'XRP': Color(0xFF346AA9), 'SOL': Color(0xFF9945FF), 'DOGE': Color(0xFFC2A633),
  'ADA': Color(0xFF0033AD), 'DOT': Color(0xFFE6007A), 'AVAX': Color(0xFFE84142),
  'MATIC': Color(0xFF8247E5), 'LINK': Color(0xFF2A5ADA), 'LTC': Color(0xFF838383),
  'TRX': Color(0xFFEF0027), 'SHIB': Color(0xFFFFA409), 'UNI': Color(0xFFFF007A),
  'ATOM': Color(0xFF2E3148), 'BCH': Color(0xFF8DC351), 'FIL': Color(0xFF0090FF),
  'APT': Color(0xFF00C2CB), 'ARB': Color(0xFF28A0F0), 'OP': Color(0xFFFF0420),
  'SUI': Color(0xFF4DA2FF), 'NEAR': Color(0xFF00C08B), 'FTM': Color(0xFF1969FF),
};

class _CoinIcon extends StatefulWidget {
  const _CoinIcon({required this.icon, required this.symbol});
  final String? icon;
  final String symbol; // base coin symbol, e.g. "BTC"

  @override
  State<_CoinIcon> createState() => _CoinIconState();
}

class _CoinIconState extends State<_CoinIcon> {
  static const size = 22.0;
  bool _imgError = false;

  @override
  void didUpdateWidget(_CoinIcon old) {
    super.didUpdateWidget(old);
    if (old.icon != widget.icon || old.symbol != widget.symbol) {
      _imgError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sym = widget.symbol.toUpperCase();
    final coinColor = _kCoinColors[sym] ?? const Color(0xFF444444);
    final label = sym.length >= 2 ? sym.substring(0, 2) : (sym.isNotEmpty ? sym : '?');

    final fallback = Container(
      width: size,
      height: size,
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
          fontFamily: "DMSans",
          letterSpacing: 0.3,
        ),
      ),
    );

    final url = widget.icon;
    if (_imgError || url == null || url.isEmpty) return fallback;

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, e, st) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _imgError = true);
            });
            return fallback;
          },
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
                  _CoinIcon(icon: coinPair.parentIcon, symbol: parent),
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
                            text: parent, // BNB
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700, // bold
                              fontFamily: "DMSans",
                              height: 20 / 15,
                            ),
                            children: [
                              if (child.isNotEmpty)
                                TextSpan(
                                  text: '/$child', // /USDT
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w300, // light
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
              child: Text(
                coinPair.lastPrice != null
                    ? (coinPair.lastPrice!).toStringAsFixed(4)
                    : "0.0000",
                textAlign: TextAlign.end,
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

class TradeCurrencyPairSelectionView extends StatefulWidget {
  const TradeCurrencyPairSelectionView({
    super.key,
    required this.searchEditController,
    required this.onTextChange,
    required this.coinPairs,
    required this.onSelect,
    required this.title,
    this.futurePairs = const [],
    this.onSelectFuture,
    this.initialTab = 0, // 0 = Spot, 1 = Future
  });

  final String title;
  final TextEditingController searchEditController;
  final Function(String) onTextChange;
  final List<CoinPair> coinPairs;
  final Function(CoinPair) onSelect;
  final List<CoinPair> futurePairs;
  final Function(CoinPair)? onSelectFuture;
  final int initialTab;

  @override
  State<TradeCurrencyPairSelectionView> createState() =>
      _TradeCurrencyPairSelectionViewState();
}

class _TradeCurrencyPairSelectionViewState
    extends State<TradeCurrencyPairSelectionView> {
  static const _green = Color(0xFFB5F000);

  int _tabIndex = 0; // 0 = Spot, 1 = Future
  int _filterIndex = 0;
  int _categoryIndex = 0;

  static const _filterList = ["ALL", "USDT", "USDC", "BTC"];
  static const _categories = ["All", "🔥 AI", "Meme", "RWA", "DeFi", "NFT", "L1", "L2"];

  static const _categoryCoins = <String, List<String>>{
    "🔥 AI": ["FET", "AGIX", "OCEAN", "GRT", "TAO", "RNDR", "WLD", "NEAR", "ICP", "AKT"],
    "Meme": ["DOGE", "SHIB", "PEPE", "FLOKI", "BONK", "WIF", "MEME", "BOME", "NEIRO", "COQ"],
    "RWA": ["ONDO", "MKR", "SNX", "RIO", "CPOOL", "MPL", "TRU", "POLYX"],
    "DeFi": ["UNI", "AAVE", "COMP", "CRV", "SUSHI", "YFI", "BAL", "1INCH", "SNX", "LDO"],
    "NFT": ["APE", "SAND", "MANA", "AXS", "GALA", "ILV", "CHZ", "SUPER", "ALICE"],
    "L1": ["BTC", "ETH", "SOL", "AVAX", "ADA", "DOT", "ATOM", "NEAR", "FTM", "SUI"],
    "L2": ["MATIC", "ARB", "OP", "IMX", "ZK", "METIS", "BOBA", "SKL", "STRK", "MANTA"],
  };

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;
  }

  List<CoinPair> get _activePairs =>
      _tabIndex == 0 ? widget.coinPairs : widget.futurePairs;

  List<CoinPair> get _filteredPairs {
    List<CoinPair> list = _activePairs;

    // Filter by base currency
    if (_filterIndex > 0) {
      final currency = _filterList[_filterIndex];
      list = list.where((p) => (p.childCoinName ?? '').toUpperCase() == currency).toList();
    }

    // Filter by category
    if (_categoryIndex > 0) {
      final cat = _categories[_categoryIndex];
      final coins = _categoryCoins[cat];
      if (coins != null && coins.isNotEmpty) {
        list = list.where((p) => coins.contains((p.parentCoinName ?? '').toUpperCase())).toList();
      }
    }

    return list;
  }

  bool get _hasFuture => widget.futurePairs.isNotEmpty || widget.onSelectFuture != null;

  @override
  Widget build(BuildContext context) {
    final pairs = _filteredPairs;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingLarge),
      decoration: BoxDecoration(
        color: context.theme.dialogTheme.backgroundColor ?? const Color(0xFF111111),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vSpacer20(),
          const SizedBox(height: 20),
          // ── Search + close ──
          Row(
            children: [
              Expanded(
                child: textFieldSearch(
                  controller: widget.searchEditController,
                  height: Dimens.btnHeightMid,
                  margin: 0,
                  onTextChange: widget.onTextChange,
                  bgColor: const Color(0xFF111111),
                  iconColor: _green,
                ),
              ),
              const SizedBox(width: 8),
              buttonOnlyIcon(
                iconData: Icons.close,
                visualDensity: minimumVisualDensity,
                onPress: () => Navigator.pop(context),
              ),
            ],
          ),
          vSpacer10(),
          // ── Spot / Future tabs (only show if future pairs available) ──
          if (_hasFuture) ...[
            Row(
              children: [
                _SpotFutureTab(
                  label: "Spot",
                  selected: _tabIndex == 0,
                  onTap: () => setState(() {
                    _tabIndex = 0;
                    _filterIndex = 0;
                    _categoryIndex = 0;
                  }),
                ),
                const SizedBox(width: 20),
                _SpotFutureTab(
                  label: "Future",
                  selected: _tabIndex == 1,
                  onTap: () => setState(() {
                    _tabIndex = 1;
                    _filterIndex = 0;
                    _categoryIndex = 0;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          // ── Filter tabs: ALL / USDT / USDC / BTC ──
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filterList.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (_, i) {
                final selected = _filterIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _filterIndex = i),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      _filterList[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: "DMSans",
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w300,
                        color: selected ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // ── Category pills: All / AI / Meme / … ──
          SizedBox(
            height: 26,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = _categoryIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _categoryIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected ? _green : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _categories[i],
                      style: TextStyle(
                        color: selected ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontFamily: "DMSans",
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // ── Header row ──
          _CoinPairHeader(),
          // ── Coin list ──
          Expanded(
            child: ListView.builder(
              itemCount: pairs.length,
              itemBuilder: (_, index) => CoinPairItemView(
                coinPair: pairs[index],
                onTap: () {
                  Get.back();
                  if (_tabIndex == 1 && widget.onSelectFuture != null) {
                    widget.onSelectFuture!(pairs[index]);
                  } else {
                    widget.onSelect(pairs[index]);
                  }
                },
              ),
            ),
          ),
          // ── Add Coin button ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  "Add Coin",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
  }
}

// Spot / Future tab label widget
class _SpotFutureTab extends StatelessWidget {
  const _SpotFutureTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontFamily: "DMSans",
          fontWeight: selected ? FontWeight.w700 : FontWeight.w300,
          color: selected ? Colors.white : Colors.white54,
        ),
      ),
    );
  }
}

class TradeListView extends StatelessWidget {
  const TradeListView({
    super.key,
    this.total,
    required this.exchangeTrades,
    this.tradeCoinOverride,
    this.baseCoinOverride,
  });

  final Total? total;
  final List<ExchangeTrade> exchangeTrades;
  final String? tradeCoinOverride;
  final String? baseCoinOverride;

  @override
  Widget build(BuildContext context) {
    final listLength = min(exchangeTrades.length, 100);
    final baseCoin  = baseCoinOverride  ?? total?.baseWallet?.coinType  ?? "";
    final tradeCoin = tradeCoinOverride ?? total?.tradeWallet?.coinType ?? "";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "${"Price".tr}($baseCoin)",
                  style:  TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w400,
                    height: 16/12
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  "${"Amount".tr}($tradeCoin)",
                  style:  TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w400,
                    height: 16/12
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  "Time".tr,
                  style:  TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: "DMSans",
                    fontWeight: FontWeight.w400,
                    height: 16/12
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          exchangeTrades.isEmpty
              ? showEmptyView()
              : Column(
                  children: List.generate(listLength, (index) {
                    return TradeItemView(exchangeTrade: exchangeTrades[index]);
                  }),
                ),
        ],
      ),
    );
  }
}

class TradeItemView extends StatelessWidget {
  const TradeItemView({super.key, required this.exchangeTrade});

  final ExchangeTrade exchangeTrade;

  @override
  Widget build(BuildContext context) {
    // Use priceOrderType (buy/sell from WS) as primary color source — matches website
    final isBuy =
        (exchangeTrade.priceOrderType ?? '').toLowerCase() == FromKey.buy;
    final color = isBuy ? gBuyColor : gSellColor;
    return InkWell(
      onTap: () => setSelectedPrice.value = exchangeTrade.price,
      child: Row(
        children: [
          Expanded(
            child: Text(
              (exchangeTrade.price ?? 0).toStringAsFixed(2),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (exchangeTrade.amount ?? 0).toStringAsFixed(6),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.theme.primaryColor,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              exchangeTrade.time ?? "",
              textAlign: TextAlign.end,
              style: TextStyle(
                color: context.theme.primaryColor,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w400,
              ),
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
