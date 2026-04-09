import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/data/models/future_data.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

class OpenInterestView extends StatelessWidget {
  const OpenInterestView({super.key, required this.coinPair});

  final CoinPair coinPair;

  @override
  Widget build(BuildContext context) {
    final color = getNumberColor(coinPair.priceChange);
    return InkWell(
      onTap: () {
        TemporaryData.selectedCurrencyPair = coinPair;
        getRootController().changeBottomNavIndex(AppBottomNavKey.future);
      },
      child: Container(
        decoration: boxDecorationRoundCorner(),
        padding: const EdgeInsets.all(Dimens.paddingMid),
        margin: const EdgeInsets.only(bottom: Dimens.paddingMid),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TextRobotoAutoBold("Open Interest".tr, color: context.theme.primaryColorLight),
                const Spacer(),
                TextRobotoAutoBold(coinPair.getCoinPairName()),
                hSpacer5(),
                TextRobotoAutoNormal("Perpetual".tr),
              ],
            ),
            Align(alignment: Alignment.centerRight, child: TextRobotoAutoBold("${coinFormat(coinPair.volume)} ${coinPair.parentCoinName ?? ""}")),
            Row(
              children: [
                buttonText("${coinFormat(coinPair.priceChange)}%",
                    textColor: color, bgColor: color.withValues(alpha:0.25), visualDensity: VisualDensity.compact),
                hSpacer10(),
                buttonText("24H Change".tr,
                    textColor: context.theme.focusColor, bgColor: context.theme.dialogTheme.backgroundColor, visualDensity: VisualDensity.compact)
              ],
            )
          ],
        ),
      ),
    );
  }
}

class LongShortRatioView extends StatelessWidget {
  const LongShortRatioView({super.key, required this.lsPair, required this.plPair});

  final HighestVolumePair lsPair;

  final ProfitLossByCoinPair plPair;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.only(bottom: Dimens.paddingMin),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextRobotoAutoNormal("Long/Short Ratio".tr),
              buttonTextBordered("24H".tr, true, visualDensity: minimumVisualDensity),
              TextRobotoAutoNormal("Highest/Lowest PNL".tr),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextRobotoAutoBold(lsPair.coinPair ?? ""),
                    TextRobotoAutoNormal("Perpetual".tr),
                    vSpacer5(),
                    _accountView("Short".tr, "${lsPair.shortAccount ?? 0}%", gSellColor),
                    vSpacer2(),
                    _accountView("Long".tr, "${lsPair.longAccount ?? 0}%", gBuyColor),
                    vSpacer2(),
                    _accountView("Ratio".tr, "${lsPair.ratio ?? 0}", context.theme.focusColor),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextRobotoAutoBold(plPair.highestPnl?.symbol ?? ""),
                    TextRobotoAutoNormal("Perpetual".tr),
                    TextRobotoAutoBold("${coinFormat(plPair.highestPnl?.totalAmount, fixed: 4)} ${plPair.highestPnl?.coinType ?? ""}",
                        color: gBuyColor),
                    dividerHorizontal(height: Dimens.paddingMid),
                    TextRobotoAutoBold(plPair.lowestPnl?.symbol ?? ""),
                    TextRobotoAutoNormal("Perpetual".tr),
                    TextRobotoAutoBold("${coinFormat(plPair.lowestPnl?.totalAmount, fixed: 4)} ${plPair.lowestPnl?.coinType ?? ""}",
                        color: gSellColor),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Row _accountView(String text, String amount, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.square_rounded, size: Dimens.iconSizeMinExtra, color: color),
        hSpacer5(),
        TextRobotoAutoNormal(text),
        hSpacer5(),
        TextRobotoAutoBold(amount),
      ],
    );
  }
}

class HighestSearchView extends StatelessWidget {
  const HighestSearchView({super.key, required this.pairs});

  final List<CoinPair> pairs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationRoundBorder(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      height: 130,
      child: Column(
        children: [
          Row(children: [TextRobotoAutoNormal("Highest Searched".tr), hSpacer5(), SizedBox(height: 20, child: buttonTextBordered("24H".tr, true))]),
          Expanded(
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: pairs.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => HighestSearchItemView(pair: pairs[index])),
          ),
        ],
      ),
    );
  }
}

class HighestSearchItemView extends StatelessWidget {
  const HighestSearchItemView({super.key, required this.pair});

  final CoinPair pair;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        TemporaryData.selectedCurrencyPair = pair;
        getRootController().changeBottomNavIndex(AppBottomNavKey.future);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMin),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextRobotoAutoBold(pair.getCoinPairName(), fontSize: Dimens.fontSizeSmall, color: context.theme.primaryColorLight),
            TextRobotoAutoBold(coinFormat(pair.lastPrice)),
            TextRobotoAutoNormal(coinFormat(pair.priceChange, fixed: 2), color: getNumberColor(pair.priceChange)),
          ],
        ),
      ),
    );
  }
}

class MarketListHeaderView extends StatelessWidget {
  const MarketListHeaderView({super.key, required this.first, required this.second, required this.third});

  final String first;
  final String second;
  final String third;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      hSpacer10(),
      Expanded(flex: 3, child: TextRobotoAutoNormal(first)),
      hSpacer5(),
      Expanded(flex: 3, child: TextRobotoAutoNormal(second, textAlign: TextAlign.end)),
      hSpacer5(),
      Expanded(flex: 2, child: TextRobotoAutoNormal(third, textAlign: TextAlign.end)),
      hSpacer10(),
    ]);
  }
}

class MarketIndexView extends StatelessWidget {
  const MarketIndexView({super.key, required this.coinPair});

  final CoinPair coinPair;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        TemporaryData.selectedCurrencyPair = coinPair;
        getRootController().changeBottomNavIndex(AppBottomNavKey.future);
      },
      child: Container(
        width: (Get.width - 50) / 3,
        decoration: boxDecorationRoundBorder(),
        padding: const EdgeInsets.all(Dimens.paddingMid),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextRobotoAutoBold(coinPair.getCoinPairName(), fontSize: Dimens.fontSizeSmall),
            TextRobotoAutoBold("${coinFormat(coinPair.priceChange, fixed: 4)}%", color: getNumberColor(coinPair.priceChange)),
            TextRobotoAutoNormal("Perpetual".tr),
          ],
        ),
      ),
    );
  }
}
