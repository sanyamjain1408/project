import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/side_sheet_component.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import '../trade_order_book_widgets.dart';
import '../trade_widgets.dart';
import 'spot_buy_sell_view.dart';
import 'spot_trade_controller.dart';
import 'spot_trade_details_screen.dart';
import 'spot_trade_history_views.dart';

class SpotTradeScreen extends StatefulWidget {
  const SpotTradeScreen({super.key});

  @override
  SpotTradeScreenState createState() => SpotTradeScreenState();
}

class SpotTradeScreenState extends State<SpotTradeScreen> {
  final _controller = Get.put(SpotTradeController());
  final selectedIndex = 0.obs;
  final isChartShow = false.obs;

  @override
  void initState() {
    tradeDecimal = DefaultValue.decimal;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (TemporaryData.selectedCurrencyPair != null) {
        _controller.selectedCoinPair.value = TemporaryData.selectedCurrencyPair!;
        TemporaryData.selectedCurrencyPair = null;

        if (TemporaryData.activityType != null) {
          Future.delayed(const Duration(seconds: 2), () {
            if (_controller.onBuySaleChange != null) _controller.onBuySaleChange!(int.parse(TemporaryData.activityType!));
            TemporaryData.activityType == null;
          });
        }
      }
      _controller.getDashBoardData();
    });
  }

  @override
  void dispose() {
    _controller.unSubscribeChannel(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Obx(() {
            final dd = _controller.dashboardData.value;
            return TradePairTopView(
              coinPair: _controller.selectedCoinPair.value,
              total: dd.orderData?.total,
              onTap: () => _chooseCoinPairModal(),
              onTapIcon: () => Get.to(() => const SpotTradeDetailsScreen()),
            );
          }),
          vSpacer5(),
          Expanded(
            child: Container(
              decoration: boxDecorationTopRoundBorder(radius: Dimens.radiusCornerMid),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
                children: [
                  Obx(() => _controller.isLoading.value ? showLoadingSmall() : vSpacer0()),
                  Obx(() => TradeChartView(isShow: isChartShow.value, onTap: () => isChartShow.value = !isChartShow.value)),
                  Obx(() => isChartShow.value ? vSpacer0() : dividerHorizontal(height: 0)),
                  vSpacer5(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 3,
                          child: Obx(() {
                            return OderBookFixedView(
                              _controller.selectedOrderSort.value,
                              order: _controller.dashboardData.value.orderData,
                              prices: _controller.dashboardData.value.lastPriceData,
                              buyList: _controller.buyExchangeOrder.toList(),
                              sellList: _controller.sellExchangeOrder.toList(),
                              onShortChange: (key) => _controller.selectedOrderSort.value = key,
                              selectedHeaderIndex: _controller.selectedHeaderIndex.value,
                              onHeaderChange: (index) => _controller.selectedHeaderIndex.value = index,
                            );
                          })),
                      hSpacer5(),
                      const Expanded(flex: 5, child: SpotTradeBuySellView(fromPage: FromKey.buy)),
                    ],
                  ),
                  vSpacer10(),
                  const SpotTradeHistoryView()
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _chooseCoinPairModal() {
    _controller.getCoinPairList("");
    SideSheet.left(
      context: context,
      barrierColor: context.theme.secondaryHeaderColor.withValues(alpha:0.5),
      sheetColor: Colors.transparent,

      width: context.width - 50,
      body: Obx(() => TradeCurrencyPairSelectionView(
          title: "Spot Pairs".tr,
          searchEditController: _controller.searchEditController,
          onTextChange: _controller.getCoinPairList,
          coinPairs: _controller.coinPairs.toList(),
          onSelect: (pair) {
            _controller.selectedCoinPair.value = pair;
            _controller.getDashBoardData();
          })),
    );
  }
}
