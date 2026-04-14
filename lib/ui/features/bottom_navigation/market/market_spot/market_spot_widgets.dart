import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
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

import '../../../currency_pair_details/currency_pair_details_screen.dart';

class MarketSort {
  bool? price;
  bool? volume;
  bool? pair;
  bool? change;
  bool? capital;

  MarketSort({this.price, this.volume, this.pair, this.change, this.capital});
}

class SpotMarketHeaderView extends StatelessWidget {
  const SpotMarketHeaderView({super.key, required this.sort, required this.onTap, this.hideCap});

  final MarketSort sort;
  final Function(MarketSort) onTap;
  final bool? hideCap;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
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
                    _getUpDownView("Pair".tr, sort.pair, () => _updateValue(SortKey.pair), MainAxisAlignment.start),
                    _getUpDownView(" / ${"Vol".tr}", sort.volume, () => _updateValue(SortKey.volume), MainAxisAlignment.start),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _getUpDownView("Price".tr, sort.price, () => _updateValue(SortKey.price), MainAxisAlignment.end),
                    if (hideCap != true) _getUpDownView(" / ${"Cap".tr}", sort.capital, () => _updateValue(SortKey.capital), MainAxisAlignment.end)
                  ],
                ),
              ),
              hSpacer10(),
              Expanded(flex: 2, child: _getUpDownView("24h Change".tr, sort.change, () => _updateValue(SortKey.change), MainAxisAlignment.end)),
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
    if (type == SortKey.capital) sort.capital = _updateCurrentValue(sort.capital);
    if (type == SortKey.change) sort.change = _updateCurrentValue(sort.change);
    _clearOtherSort(type);
    onTap(sort);
  }

  bool? _updateCurrentValue(bool? current) => current == null ? false : (current == false ? true : null);

  SizedBox _getUpDownView(String title, bool? value, VoidCallback onTap, MainAxisAlignment alignment) {
    final colorUp = value == true ? Get.theme.focusColor : Get.theme.primaryColor;
    final colorDown = value == false ? Get.theme.focusColor : Get.theme.primaryColor;

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
                SvgPicture.asset(AssetConstants.icArrowDropUp, colorFilter: getColorFilter(colorUp), width: 10),
                vSpacer3(),
                SvgPicture.asset(AssetConstants.icArrowDropDown, colorFilter: getColorFilter(colorDown), width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MarketCoinItemViewBottom extends StatelessWidget {
  const MarketCoinItemViewBottom({super.key, required this.coin, this.onFavChange});

  final MarketCoin coin;
  final Function(String?)? onFavChange;

  @override
  Widget build(BuildContext context) {
    final (sign, cColor) = getNumberData(coin.change);
    return GestureDetector(
      onTap: () => Get.to(() => CurrencyPairDetailsScreen(pair: coin.convertCoinPair())),
      onLongPressStart: (lpDetails) => FavoriteHelper.showFavoritePopup(context, lpDetails.globalPosition, coin.convertCoinPair(), '', onFavChange),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        color: Colors.transparent,
        child: Row(
          children: [
            showImageNetwork(
              imagePath: coin.coinIcon,
              width: 30,
              height: 30,
              bgColor: Colors.transparent,
            ),
            hSpacer10(),

            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: TextRobotoAutoBold(coin.coinType ?? "", maxLines: 1),
                      ),
                      if ((coin.baseCoinType ?? '').isNotEmpty)
                        TextRobotoAutoNormal(
                          "/${coin.baseCoinType}",
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B7280),
                        ),
                    ],
                  ),
                  TextRobotoAutoNormal(
                    "\$${numberFormatCompact(coin.volume, decimals: 2)}",
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextRobotoAutoBold(
                    currencyFormat(coin.price),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                  ),
                  TextRobotoAutoNormal(
                    "\$${coinFormat(coin.usdtPrice ?? coin.price, fixed: 6)}",
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),

            hSpacer10(),

            Expanded(
              flex: 2,
              child: SizedBox(
                height: 30,
                child: Center(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: "DM Sans",
                      fontWeight: FontWeight.w600,
                    ),
                    child: buttonText(
                      "$sign${coinFormat(coin.change, fixed: 2)}%",
                      textColor: Colors.white,
                      bgColor: cColor,
                      fontSize: 15,
                      radius: Dimens.radiusCorner,
                      visualDensity: VisualDensity.compact,
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