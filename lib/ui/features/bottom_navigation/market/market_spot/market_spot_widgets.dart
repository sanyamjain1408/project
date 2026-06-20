import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/market_date.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/helper/favorite_helper.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import '../../../root/root_controller.dart';
import '../../../../../helper/bottom_nav_helper.dart';
import '../../trades/spot_trade/spot_trade_controller.dart';

class MarketSort {
  bool? price;
  bool? volume;
  bool? pair;
  bool? change;
  bool? capital;

  MarketSort({this.price, this.volume, this.pair, this.change, this.capital});
}

class SpotMarketHeaderView extends StatelessWidget {
  const SpotMarketHeaderView({
    super.key,
    required this.sort,
    required this.onTap,
    this.hideCap,
  });

  final MarketSort sort;
  final Function(MarketSort) onTap;
  final bool? hideCap;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
        child: Container(
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    _getUpDownView(
                      "Pair".tr,
                      sort.pair,
                      () => _updateValue(SortKey.pair),
                      MainAxisAlignment.start,
                    ),
                    _getUpDownView(
                      " / ${"Vol".tr}",
                      sort.volume,
                      () => _updateValue(SortKey.volume),
                      MainAxisAlignment.start,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _getUpDownView(
                      "Price".tr,
                      sort.price,
                      () => _updateValue(SortKey.price),
                      MainAxisAlignment.end,
                    ),
                    if (hideCap != true)
                      _getUpDownView(
                        " / ${"Cap".tr}",
                        sort.capital,
                        () => _updateValue(SortKey.capital),
                        MainAxisAlignment.end,
                      ),
                  ],
                ),
              ),
              hSpacer10(),
              Expanded(
                flex: 2,
                child: _getUpDownView(
                  "24h Change".tr,
                  sort.change,
                  () => _updateValue(SortKey.change),
                  MainAxisAlignment.end,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearOtherSort(int type) {
    if (type != SortKey.pair) sort.pair = null;
    if (type != SortKey.price) sort.price = null;
    if (type != SortKey.volume) sort.volume = null;
    if (type != SortKey.change) sort.change = null;
    if (type != SortKey.capital) sort.capital = null;
  }

  void _updateValue(int type) {
    if (type == SortKey.pair) sort.pair = _updateCurrentValue(sort.pair);
    if (type == SortKey.volume) sort.volume = _updateCurrentValue(sort.volume);
    if (type == SortKey.price) sort.price = _updateCurrentValue(sort.price);
    if (type == SortKey.capital)
      sort.capital = _updateCurrentValue(sort.capital);
    if (type == SortKey.change) sort.change = _updateCurrentValue(sort.change);
    _clearOtherSort(type);
    onTap(sort);
  }

  bool? _updateCurrentValue(bool? current) =>
      current == null ? false : (current == false ? true : null);

  SizedBox _getUpDownView(
    String title,
    bool? value,
    VoidCallback onTap,
    MainAxisAlignment alignment,
  ) {
    final colorUp = value == true
        ? Get.theme.focusColor
        : Get.theme.primaryColor;
    final colorDown = value == false
        ? Get.theme.focusColor
        : Get.theme.primaryColor;

    return SizedBox(
      height: Dimens.btnHeightMid,
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: alignment,
          children: [
            TextRobotoAutoNormal(title, fontSize: Dimens.fontSizeSmall),
            hSpacer3(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  AssetConstants.icArrowDropUp,
                  colorFilter: getColorFilter(colorUp),
                  width: 10,
                ),
                vSpacer3(),
                SvgPicture.asset(
                  AssetConstants.icArrowDropDown,
                  colorFilter: getColorFilter(colorDown),
                  width: 10,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MarketCoinItemViewBottom extends StatelessWidget {
  const MarketCoinItemViewBottom({
    super.key,
    required this.coin,
    this.onFavChange,
    this.showPerp = false,
  });

  final MarketCoin coin;
  final Function(String?)? onFavChange;
  final bool showPerp;

  @override
  Widget build(BuildContext context) {
    final isUp = !isNegativeNum(coin.change);
    final sign = isUp ? '+' : '';
    final cColor = isUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    String formattedPrice = coinFormat(coin.price); // LandingMarketView jaisa

    return GestureDetector(
      onTap: () {
        final pair = coin.convertCoinPair();
        pair.coinPair = pair.getCoinPairKey();
        pair.coinPairName = pair.getCoinPairName();
        Get.find<RootController>().changeBottomNavIndex(AppBottomNavKey.trade);
        if (Get.isRegistered<SpotTradeController>()) {
          final ctrl = Get.find<SpotTradeController>();
          ctrl.selectedCoinPair.value = pair;
          ctrl.getDashBoardData();
        }
      },
      onLongPressStart: (lpDetails) => FavoriteHelper.showFavoritePopup(
        context,
        lpDetails.globalPosition,
        coin.convertCoinPair(),
        '',
        onFavChange,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon + name + volume
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipOval(
                    child: showImageNetwork(
                      imagePath: coin.coinIcon,
                      width: 30,
                      height: 30,
                      bgColor: const Color(0xFFD9D9D9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  text: coin.coinType ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: "DMSans",
                                    height: 1.25,
                                  ),
                                  children: [
                                    if ((coin.baseCoinType ?? '').isNotEmpty)
                                      TextSpan(
                                        text: "/${coin.baseCoinType}",
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: "DMSans",
                                          height: 1.25,
                                        ),
                                      ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showPerp) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'Perp',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: "DMSans",
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          "\$${numberFormatCompact(coin.volume, decimals: 2)}",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontFamily: "DMSans",
                            height: 1.33,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Price — fixed 90px right-aligned
            SizedBox(
              width: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedPrice,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: "DMSans",
                      height: 1.25,
                    ),
                  ),
                  Text(
                    "\$$formattedPrice",
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: "DMSans",
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 18),

            // Change badge — fixed 83px
            SizedBox(
              width: 83,
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  color: cColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "$sign${coinFormat(coin.change, fixed: 2)}%",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: "DMSans",
                        height: 1.33,
                      ),
                      maxLines: 1,
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
