import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/helper/favorite_helper.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import '../../wallet/wallet_crypto_deposit/wallet_crypto_deposit_screen.dart';
import '../../wallet/wallet_crypto_withdraw/wallet_crypto_withdraw_screen.dart';

import '../trade_order_book_widgets.dart';
import '../trade_widgets.dart';
import 'spot_trade_controller.dart';

class SpotTradeDetailsScreen extends StatefulWidget {
  const SpotTradeDetailsScreen({super.key});

  @override
  State<SpotTradeDetailsScreen> createState() =>
      _SpotTradeDetailsScreenState();
}

class _SpotTradeDetailsScreenState extends State<SpotTradeDetailsScreen> {
  final _controller = Get.find<SpotTradeController>();
  final isLogin = gUserRx.value.id > 0;
  RxInt chartIndex = 0.obs;
  RxInt tabIndex = 0.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                buttonOnlyIcon(
                  onPress: () => Navigator.pop(context),
                  iconData: Icons.arrow_back_outlined,
                  size: Dimens.iconSizeMin,
                ),
                TextRobotoAutoBold(
                  _controller.selectedCoinPair.value.getCoinPairName(),
                  fontSize: Dimens.fontSizeMid,
                ),
                const Spacer(),
                // ── Plain inline % text — no red badge ──────────────────────
                Obx(() {
                  final change = _controller
                      .dashboardData
                      .value
                      .orderData
                      ?.total
                      ?.tradeWallet
                      ?.priceChange;
                  final (sing, color) = getNumberData(change);
                  return Text(
                    "$sing${coinFormat(change, fixed: 2)}%",
                    style: TextStyle(
                      color: color,
                      fontSize: Dimens.fontSizeSmall,
                      fontWeight: FontWeight.normal,
                    ),
                  );
                }),
                Obx(() => FavoriteHelper.getFavoriteIcon(
                      _controller.selectedCoinPair.value,
                      () {
                        FavoriteHelper.updateFavorite(
                          _controller.selectedCoinPair.value,
                          '',
                          (pair) {
                            _controller.selectedCoinPair.value = pair;
                            _controller.selectedCoinPair.refresh();
                          },
                        );
                      },
                    )),
                hSpacer5(),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.paddingMid),
                children: [
                  Obx(() => CurrencyPairDetailsView(
                      order: _controller.dashboardData.value.orderData,
                      prices:
                          _controller.dashboardData.value.lastPriceData)),
                  dividerHorizontal(),
                  Obx(() => TvChartFullView(coinPair: _controller.selectedCoinPair.value)),
                  vSpacer10(),
                  Obx(() => tabBarText(
                      [
                        "Order Book".tr,
                        "Trades".tr,
                        "Asset Overview".tr,
                      ],
                      tabIndex.value,
                      selectedColor: context.theme.focusColor,
                      (index) => tabIndex.value = index)),
                  vSpacer10(),
                  Obx(() {
                    switch (tabIndex.value) {
                      case 0:
                        return DetailsOrderBookView(
                          buyExchangeOrder:
                              _controller.buyExchangeOrder,
                          sellExchangeOrder:
                              _controller.sellExchangeOrder,
                          total: _controller
                              .dashboardData.value.orderData?.total,
                        );
                      case 1:
                        return TradeListView(
                          exchangeTrades: _controller.exchangeTrades,
                          total: _controller
                              .dashboardData.value.orderData?.total,
                        );
                      case 2:
                        return AssetOverviewView();
                      default:
                        return Container();
                    }
                  }),
                ],
              ),
            ),
            TradeBottomButtonsView(
              buyStr: "Buy".tr,
              sellStr: "Sell".tr,
              onTap: (bool isBuy) =>
                  _controller.onBuySaleChange != null
                      ? _controller.onBuySaleChange!(isBuy ? 0 : 1)
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}

class AssetOverviewView extends StatelessWidget {
  AssetOverviewView({super.key});

  final _controller = Get.find<SpotTradeController>();

  @override
  Widget build(BuildContext context) {
    final color = context.theme.primaryColorLight;
    return Container(
      padding: const EdgeInsets.all(Dimens.paddingMid),
      width: context.width,
      decoration: boxDecorationRoundCorner(),
      child: Obx(() {
        final total = _controller.selfBalance.value.total;
        final baseCType = total?.baseWallet?.coinType ?? "";
        final tradeCType = total?.tradeWallet?.coinType ?? "";
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextRobotoAutoBold("Trading Account".tr),
            vSpacer5(),
            twoTextSpaceFixed(baseCType,
                coinFormat(_controller.selfBalance.value.baseWallet,
                    fixed: tradeDecimal),
                color: color),
            twoTextSpaceFixed(tradeCType,
                coinFormat(_controller.selfBalance.value.tradeWallet,
                    fixed: tradeDecimal),
                color: color),
            vSpacer10(),
            TextRobotoAutoBold("Funding Account".tr),
            vSpacer5(),
            twoTextSpaceFixed(
                baseCType,
                coinFormat(total?.baseWallet?.balance,
                    fixed: tradeDecimal),
                color: color),
            twoTextSpaceFixed(
                tradeCType,
                coinFormat(total?.tradeWallet?.balance,
                    fixed: tradeDecimal),
                color: color),
            vSpacer15(),
            Row(
              children: [
                Expanded(
                  child: buttonText(
                    "Deposit".tr,
                    visualDensity: VisualDensity.compact,
                    onPress: () {
                      if (total?.tradeWallet != null) {
                        Get.to(() => WalletCryptoDepositScreen(
                            wallet:
                                total!.tradeWallet!.createWallet()));
                      }
                    },
                  ),
                ),
                hSpacer15(),
                Expanded(
                  child: buttonText(
                    "Transfer".tr,
                    visualDensity: VisualDensity.compact,
                    onPress: () {
                      if (total?.tradeWallet != null) {
                        Get.to(() => WalletCryptoWithdrawScreen(
                            wallet:
                                total!.tradeWallet!.createWallet()));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}