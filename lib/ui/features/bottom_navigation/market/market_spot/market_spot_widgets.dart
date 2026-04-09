import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/market_date.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/helper/favorite_helper.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../currency_pair_details/currency_pair_details_screen.dart';

class MarketTopItemView extends StatelessWidget {
  const MarketTopItemView({super.key, required this.list, required this.title});

  final List<MarketCoin> list;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cWidth = (context.width - (20 + 15)) / 2;
    return Container(
      width: cWidth,
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextRobotoAutoBold(title, fontSize: Dimens.fontSizeMid, color: context.theme.primaryColorLight),
          vSpacer5(),
          Column(children: List.generate(list.length, (index) => MarketCoinItemView(coin: list[index]))),
        ],
      ),
    );
  }
}

class MarketCoinItemView extends StatelessWidget {
  const MarketCoinItemView({super.key, required this.coin});

  final MarketCoin coin;

  @override
  Widget build(BuildContext context) {
    double height = getHeightForTextScaler(context, Dimens.marketTopItemHeight, [1, 2, 3]);
    return SizedBox(
      height: height,
      child: Row(children: [
        showImageNetwork(imagePath: coin.coinIcon, width: Dimens.iconSizeMin, height: Dimens.iconSizeMin),
        hSpacer5(),
        Expanded(flex: 1, child: TextRobotoAutoBold(coin.coinType ?? "", fontSize: Dimens.fontSizeSmall)),
        hSpacer2(),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextRobotoAutoNormal("${coin.currencySymbol ?? ""}${coinFormat(coin.usdtPrice, fixed: 2)}",
                  color: context.theme.primaryColor, fontSize: Dimens.fontSizeSmall, textAlign: TextAlign.end),
              TextRobotoAutoNormal(coinFormat(coin.change, fixed: 2),
                  color: getNumberColor(coin.change), fontSize: Dimens.fontSizeSmall, textAlign: TextAlign.end),
            ],
          ),
        )
      ]),
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
        padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMin),
        color: Colors.transparent,
        child: Row(children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextRobotoAutoBold(coin.coinType ?? ""),
                    if (coin.baseCoinType.isValid) TextRobotoAutoNormal("/${coin.baseCoinType}", fontSize: Dimens.fontSizeSmall),
                  ],
                ),
                TextRobotoAutoNormal("${"Vol".tr} ${numberFormatCompact(coin.volume, decimals: 2, symbol: "\$")}"),
              ],
            ),
          ),
          hSpacer5(),
          Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextRobotoAutoBold(currencyFormat(coin.price), textAlign: TextAlign.end),
                  TextRobotoAutoNormal("${"Cap".tr} ${numberFormatCompact(coin.totalBalance, decimals: 2)}", textAlign: TextAlign.end),
                ],
              )),
          hSpacer10(),
          Expanded(
            flex: 2,
            child: buttonText("$sign${coinFormat(coin.change, fixed: 2)}%",
                textColor: Colors.white, bgColor: cColor, radius: Dimens.radiusCorner, visualDensity: VisualDensity.compact),
          )
        ]),
      ),
    );
  }
}

// class MarketCoinItemViewBottom extends StatelessWidget {
//   const MarketCoinItemViewBottom({super.key, required this.coin});
//
//   final MarketCoin coin;
//
//   @override
//   Widget build(BuildContext context) {
//     final (sign, cColor) = getNumberData(coin.change);
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMin),
//       child: Row(children: [
//         Expanded(
//           flex: 3,
//           child: Row(
//             children: [
//               showImageNetwork(imagePath: coin.coinIcon, width: Dimens.iconSizeMin, height: Dimens.iconSizeMin, bgColor: Colors.transparent),
//               hSpacer5(),
//               Expanded(
//                   child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   TextRobotoAutoBold(coin.coinType ?? "", fontSize: Dimens.fontSizeMidExtra, maxLines: 2, textAlign: TextAlign.start),
//                   TextRobotoAutoNormal(numberFormatCompact(coin.totalBalance, decimals: 2)),
//                 ],
//               )),
//             ],
//           ),
//         ),
//         hSpacer5(),
//         Expanded(
//           flex: 3,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               TextRobotoAutoBold(currencyFormat(coin.price)),
//               TextRobotoAutoNormal(currencyFormat(coin.volume)),
//             ],
//           ),
//         ),
//         hSpacer10(),
//         Expanded(
//           flex: 2,
//           child: buttonText("$sign${coinFormat(coin.change, fixed: 2)}%", textColor: Colors.white,
//               bgColor: cColor, radius: Dimens.radiusCorner, visualDensity: VisualDensity.compact),
//         )
//       ]),
//     );
//   }
// }
