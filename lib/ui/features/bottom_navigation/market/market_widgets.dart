import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/helper/favorite_helper.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'package:tradexpro_flutter/helper/app_helper.dart';
import '../../currency_pair_details/currency_pair_details_screen.dart';

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
                )),
            Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _getUpDownView("Price".tr, sort.price, () => _updateValue(SortKey.price), MainAxisAlignment.center),
                    if (hideCap != true) _getUpDownView(" / ${"Cap".tr}", sort.capital, () => _updateValue(SortKey.capital), MainAxisAlignment.end)
                  ],
                )),
            Expanded(flex: 2, child: _getUpDownView("24h Change".tr, sort.change, () => _updateValue(SortKey.change), MainAxisAlignment.end)),
          ],
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

class MarketCoinPairItemView extends StatelessWidget {
  const MarketCoinPairItemView({super.key, required this.pair, this.onFavChange, this.fromKey});

  final CoinPair pair;
  final Function(String?)? onFavChange;
  final String? fromKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => CurrencyPairDetailsScreen(pair: pair.setCoinPairKey(), fromKey: fromKey, onFavChange: onFavChange)),
      onLongPressStart: (lpDetails) =>
          FavoriteHelper.showFavoritePopup(context, lpDetails.globalPosition, pair.setCoinPairKey(), fromKey, onFavChange),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            SizedBox(
              width: 30, height: 30,
              child: Stack(children: [
                Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2A2A2A)),
                  child: Center(child: Text(
                    (pair.childCoinName ?? '?').isNotEmpty ? (pair.childCoinName ?? '?')[0] : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                ),
                ClipOval(child: showImageNetwork(imagePath: pair.icon ?? '', width: 30, height: 30, bgColor: Colors.transparent)),
              ]),
            ),
            const SizedBox(width: 8),
            // Pair name + vol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(
                      text: '${pair.childCoinName ?? ""}${pair.parentCoinName ?? ""} ',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'DMSans', fontWeight: FontWeight.w400, height: 1.33),
                    ),
                    TextSpan(
                      text: 'Perp',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontFamily: 'DMSans', fontWeight: FontWeight.w400, height: 1.20),
                    ),
                  ]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('\$${numberFormatCompact(pair.volume, decimals: 2)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans', fontWeight: FontWeight.w400, height: 1.33),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Price
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currencyFormat(pair.lastPrice),
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'DMSans', fontWeight: FontWeight.w600, height: 1.33),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('\$${currencyFormat(pair.lastPrice)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'DMSans', fontWeight: FontWeight.w400, height: 1.33),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // % pill
            Container(
              width: 83, height: 30,
              decoration: BoxDecoration(
                color: getNumberColor(pair.priceChange),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${(pair.priceChange ?? 0) >= 0 ? '+' : ''}${coinFormat(pair.priceChange, fixed: 2)}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'DMSans', fontWeight: FontWeight.w600, height: 1.33),
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
