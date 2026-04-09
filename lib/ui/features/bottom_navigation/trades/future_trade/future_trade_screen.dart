import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/language_util.dart';
import 'package:tradexpro_flutter/utils/side_sheet_component.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../trade_order_book_widgets.dart';
import '../trade_widgets.dart';
import 'future_history_views.dart';
import 'future_trade_controller.dart';
import 'future_trade_details_screen.dart';
import 'open_close_tab_views.dart';

class FutureTradeScreen extends StatefulWidget {
  const FutureTradeScreen({super.key});

  @override
  FutureTradeScreenState createState() => FutureTradeScreenState();
}

class FutureTradeScreenState extends State<FutureTradeScreen> {
  final _controller = Get.put(FutureTradeController());
  final isMyOrders = true.obs;
  final isChartShow = false.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (TemporaryData.selectedCurrencyPair != null) {
        _controller.selectedCoinPair.value = TemporaryData.selectedCurrencyPair!;
        TemporaryData.selectedCurrencyPair = null;

        if (TemporaryData.activityType != null) {
          Future.delayed(const Duration(seconds: 2), () {
            if (_controller.onOpenCloseChange != null) _controller.onOpenCloseChange!(int.parse(TemporaryData.activityType!));
            TemporaryData.activityType == null;
          });
        }
      }
      _controller.getFutureTradeData();
    });
  }

  @override
  void dispose() {
    _controller.unSubscribeChannel(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        vSpacer5(),
        Obx(() {
          final dd = _controller.futureDashboardData.value;
          return TradePairTopView(
            coinPair: _controller.selectedCoinPair.value,
            total: dd.orderData?.total,
            onTap: () => _chooseCoinPairModal(),
            onTapIcon: () => Get.to(() => const FutureTradeDetailsScreen()),
          );
        }),
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
                  children: [
                    Obx(() => _buttonWithIcon(_controller.isIsolate.value ? "Isolated".tr : "Cross".tr, () {
                          showBottomSheetDynamic(
                              context,
                              title: "${_controller.selectedCoinPair.value.getCoinPairName()} ${"Perpetual Margin Mode".tr}",
                              MarginModeView(isIsolate: _controller.isIsolate.value, onChange: (isolate) => _controller.isIsolate.value = isolate));
                        })),
                    hSpacer10(),
                    Obx(() => _buttonWithIcon(
                          "${ListConstants.leverages[_controller.selectedLeverageIndex.value]}x",
                          () => showBottomSheetDynamic(
                              context,
                              title: "Leverage".tr,
                              LeverageSelectionView(
                                  selectedIndex: _controller.selectedLeverageIndex.value,
                                  onSelect: (index) => _controller.selectedLeverageIndex.value = index)),
                        )),
                  ],
                ),
                vSpacer5(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 3,
                        child: Obx(() {
                          return OderBookFixedView(
                            _controller.selectedOrderSort.value,
                            order: _controller.futureDashboardData.value.orderData,
                            prices: _controller.futureDashboardData.value.lastPriceData,
                            buyList: _controller.buyExchangeOrder,
                            sellList: _controller.sellExchangeOrder,
                            onShortChange: (key) => _controller.selectedOrderSort.value = key,
                            selectedHeaderIndex: _controller.selectedHeaderIndex.value,
                            onHeaderChange: (index) => _controller.selectedHeaderIndex.value = index,
                          );
                        })),
                    hSpacer5(),
                    const Expanded(flex: 5, child: OpenCloseTabViews(fromPage: FromKey.open)),
                  ],
                ),
                vSpacer10(),
                const FutureHistoryViews(fromPage: FromKey.buy)
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buttonWithIcon(String title, VoidCallback onTap) {
    return buttonRoundedWithIcon(
        text: title,
        iconData: Icons.arrow_drop_down,
        bgColor: Colors.transparent,
        borderColor: context.theme.dividerColor,
        padding: EdgeInsets.only(left: LanguageUtil.isDirectionRTL() ? 0 : 10, right: LanguageUtil.isDirectionRTL() ? 10 : 0),
        visualDensity: minimumVisualDensity,
        onPress: onTap);
  }

  void _chooseCoinPairModal() {
    _controller.getCoinPairList("");
    SideSheet.left(
      context: context,
      barrierColor: context.theme.secondaryHeaderColor.withValues(alpha:0.5),
      sheetColor: Colors.transparent,
      width: context.width - 50,
      body: Obx(() => TradeCurrencyPairSelectionView(
          title: "Future Pairs".tr,
          searchEditController: _controller.searchEditController,
          onTextChange: _controller.getCoinPairList,
          coinPairs: _controller.coinPairs.toList(),
          onSelect: _controller.selectCoinPair)),
    );
  }
}

class MarginModeView extends StatelessWidget {
  const MarginModeView({super.key, required this.isIsolate, required this.onChange});

  final bool isIsolate;

  final Function(bool) onChange;

  @override
  Widget build(BuildContext context) {
    RxBool isIsolateLocal = isIsolate.obs;
    final fColor = context.theme.focusColor;

    return Obx(() {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: buttonText("Isolated".tr,
                  textColor: context.theme.primaryColor,
                  bgColor: isIsolateLocal.value ? fColor : Colors.transparent,
                  borderColor: fColor, onPress: () {
            isIsolateLocal.value = true;
            onChange(isIsolateLocal.value);
          })),
          hSpacer10(),
          Expanded(
              child: buttonText("Cross".tr,
                  textColor: context.theme.primaryColor,
                  bgColor: isIsolateLocal.value ? Colors.transparent : fColor,
                  borderColor: fColor, onPress: () {
            isIsolateLocal.value = false;
            onChange(isIsolateLocal.value);
          })),
        ]),
        vSpacer15(),
        TextRobotoAutoNormal(isIsolateLocal.value ? "Isolated Margin Mode Description".tr : "Cross Margin Mode Description".tr, maxLines: 10),
        vSpacer10(),
      ]);
    });
  }
}

class LeverageSelectionView extends StatelessWidget {
  const LeverageSelectionView({super.key, required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    RxInt selectedIndexLocal = selectedIndex.obs;
    return Obx(() {
      return Column(children: [
        buttonRoundedWithIcon(
            text: "${ListConstants.leverages[selectedIndexLocal.value]}x",
            iconData: Icons.check,
            bgColor: Colors.transparent,
            borderColor: context.theme.dividerColor),
        vSpacer10(),
        Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: Dimens.paddingMin,
            children: List.generate(
                ListConstants.leverages.length,
                (index) => buttonTextBordered("${ListConstants.leverages[index]}x", false, onPress: () {
                      selectedIndexLocal.value = index;
                      onSelect(selectedIndexLocal.value);
                    }))),
        vSpacer10(),
      ]);
    });
  }
}
