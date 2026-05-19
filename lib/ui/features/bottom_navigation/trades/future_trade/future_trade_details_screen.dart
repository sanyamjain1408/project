import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/helper/favorite_helper.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../trade_order_book_widgets.dart';
import '../trade_widgets.dart';
import 'future_trade_controller.dart';

class FutureTradeDetailsScreen extends StatefulWidget {
  const FutureTradeDetailsScreen({super.key});

  @override
  State<FutureTradeDetailsScreen> createState() => _FutureTradeDetailsScreenState();
}

class _FutureTradeDetailsScreenState extends State<FutureTradeDetailsScreen> {
  final _controller = Get.find<FutureTradeController>();
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
                buttonOnlyIcon(onPress: () => Navigator.pop(context), iconData: Icons.arrow_back_outlined, size: Dimens.iconSizeMin),
                TextRobotoAutoBold(_controller.selectedCoinPair.value.getCoinPairName()),
                const Spacer(),
                Obx(() {
                  final change = _controller.futureDashboardData.value.orderData?.total?.tradeWallet?.priceChange;
                  final (sing, color) = getNumberData(change);
                  return buttonText("$sing${coinFormat(change, fixed: 4)}%",
                      textColor: color, bgColor: color.withValues(alpha:0.2), visualDensity: minimumVisualDensity);
                }),
                Obx(() => FavoriteHelper.getFavoriteIcon(_controller.selectedCoinPair.value, () {
                  FavoriteHelper.updateFavorite(_controller.selectedCoinPair.value, FromKey.future, (pair) {
                    _controller.selectedCoinPair.value = pair;
                    _controller.selectedCoinPair.refresh();
                  });
                })),
                hSpacer5()
              ],
            ),
            Expanded(
              child: ListView(
                
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
                    child: Obx(() => CurrencyPairDetailsView(
                        order: _controller.futureDashboardData.value.orderData, prices: _controller.futureDashboardData.value.lastPriceData)),
                  ),
                  // Chart — full width, no horizontal margin, no divider border
                  Obx(() => TvChartFullView(coinPair: _controller.selectedCoinPair.value)),
                  // Obx(() => tabBarText(
                  //     ["Candlestick".tr, "Depth".tr],
                  //     chartIndex.value,
                  //     selectedColor: context.theme.focusColor,
                  //     (index) => chartIndex.value = index)),
                  // Obx(() => chartIndex.value == 0
                  //     ? const ChartScreen(fromModal: false)
                  //     : DepthChartScreen(buyOrders: _controller.buyExchangeOrder, sellOrders: _controller.sellExchangeOrder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
                    child: Column(
                      children: [
                        vSpacer10(),
                        Obx(() => tabBarText(
                            ["Order Book".tr, "Trades".tr], tabIndex.value, selectedColor: context.theme.focusColor, (index) => tabIndex.value = index)),
                        vSpacer10(),
                        Obx(() {
                          switch (tabIndex.value) {
                            case 0:
                              return DetailsOrderBookView(
                                  buyExchangeOrder: _controller.buyExchangeOrder,
                                  sellExchangeOrder: _controller.sellExchangeOrder,
                                  total: _controller.futureDashboardData.value.orderData?.total);
                            case 1:
                              return TradeListView(
                                  exchangeTrades: _controller.exchangeTrades, total: _controller.futureDashboardData.value.orderData?.total);
                            default:
                              return Container();
                          }
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            TradeBottomButtonsView(
                buyStr: "Open".tr,
                sellStr: "Close".tr,
                onTap: (bool isBuy) => _controller.onOpenCloseChange != null ? _controller.onOpenCloseChange!(isBuy ? 0 : 1) : null)
          ],
        ),
      ),
    );
  }
}
