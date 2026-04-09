import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/exchange_order.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'spot_trade_controller.dart';

class SpotTradeHistoryView extends StatefulWidget {
  const SpotTradeHistoryView({super.key});

  @override
  SpotTradeHistoryViewState createState() => SpotTradeHistoryViewState();
}

class SpotTradeHistoryViewState extends State<SpotTradeHistoryView> with SingleTickerProviderStateMixin {
  final _controller = Get.find<SpotTradeController>();
  RxInt selectedTabIndex = 0.obs;
  RxInt selectedSubTabIndex = 0.obs;
  TabController? orderTabController;

  @override
  void initState() {
    orderTabController = TabController(vsync: this, length: 4);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        tabBarUnderline(
            ["Open Orders".tr, "Order History".tr, "Trade History".tr, "Stop Limit Orders".tr], orderTabController,
            indicator: tabCustomIndicator(context),
            isScrollable: true,
            fontSize: Dimens.fontSizeMid,
            onTap: (index) => selectedTabIndex.value = index),
        dividerHorizontal(height: 0),
        vSpacer10(),
        Obx(() {
          final color = selectedSubTabIndex.value == 0 ? gBuyColor : gSellColor;
          return selectedTabIndex.value == 1
              ? Padding(
                  padding: const EdgeInsets.only(
                      left: Dimens.paddingMid, right: Dimens.paddingMid, bottom: Dimens.paddingMid),
                  child: tabBarText(
                      ["Buy".tr, "Sell".tr],
                      selectedSubTabIndex.value,
                      selectedColor: color,
                      (index) => selectedSubTabIndex.value = index),
                )
              : vSpacer0();
        }),
        Obx(() => gUserRx.value.id == 0
            ? Padding(
                padding: const EdgeInsets.all(Dimens.paddingMid),
                child:
                    textSpanWithAction("Want to trade".tr, "Login".tr, onTap: () => Get.to(() => const SignInPage())),
              )
            : _listView())
      ],
    );
  }

  Widget _listView() {
    return Obx(() {
      final list = getData(selectedTabIndex.value, _controller.allMyHistories.value, subTab: selectedSubTabIndex.value);
      return list.isEmpty
          ? handleEmptyViewWithLoading(_controller.isHistoryLoading.value)
          : Column(
              children: List.generate(list.length, (index) {
                if (selectedTabIndex.value == 3 && list[index] is StopLimitOrder) {
                  return SpotTradeHistoryStopLimitItemView(
                      trade: list[index],
                      onCancel: (trade) => _controller.cancelOpenOrderApp('stop', trade.id ?? 0),
                      orderData: _controller.dashboardData.value.orderData);
                } else {
                  return SpotTradeHistoryItemView(
                      trade: list[index],
                      fromKey: getFromKey(),
                      onCancel: (trade) => _controller.cancelOpenOrderApp(trade.type ?? '', trade.id ?? 0),
                      orderData: _controller.dashboardData.value.orderData);
                }
              }),
            );
    });
  }

  List<dynamic> getData(int tab, SpotAllMyHistories histories, {int? subTab}) {
    if (tab == 0) {
      return histories.orders ?? [];
    } else if (tab == 1) {
      return (subTab == 0 ? histories.buyOrders : histories.sellOrders) ?? [];
    } else if (tab == 2) {
      return histories.transactions ?? [];
    } else if (tab == 3) {
      return histories.stopLimitOrders ?? [];
    }
    return [];
  }

  String getFromKey() {
    if (selectedTabIndex.value == 0) {
      return FromKey.buySell;
    } else if (selectedTabIndex.value == 1 && selectedSubTabIndex.value == 0) {
      return FromKey.buy;
    } else if (selectedTabIndex.value == 1 && selectedSubTabIndex.value == 1) {
      return FromKey.sell;
    } else if (selectedTabIndex.value == 2) {
      return FromKey.trade;
    }
    return '';
  }
}

class SpotTradeHistoryItemView extends StatelessWidget {
  const SpotTradeHistoryItemView(
      {super.key, required this.trade, required this.orderData, required this.fromKey, required this.onCancel});

  final Trade trade;
  final OrderData? orderData;
  final String fromKey;
  final Function(Trade) onCancel;

  @override
  Widget build(BuildContext context) {
    final color = trade.type == FromKey.buy ? gBuyColor : gSellColor;
    final tradeCoin = orderData?.tradeCoin ?? "";
    final baseCoin = orderData?.baseCoin ?? "";
    final pcl = context.theme.primaryColorLight;
    return Column(
      children: [
        if (fromKey != FromKey.trade)
          Row(
            children: [
              buttonTextBordered((trade.type ?? "").toUpperCase(), true,
                  color: color, visualDensity: minimumVisualDensity),
              const Spacer(),
              if (fromKey == FromKey.buySell)
                buttonText("Cancel".tr, visualDensity: minimumVisualDensity, onPress: () => onCancel(trade)),
              if (fromKey == FromKey.buy || fromKey == FromKey.sell) TextRobotoAutoBold("$tradeCoin/$baseCoin"),
            ],
          ),
        twoTextSpaceFixed("${"Amount".tr}: ", "${coinFormat(trade.amount)} $tradeCoin",
            color: pcl, fontSize: Dimens.fontSizeSmall),
        twoTextSpaceFixed("${"Fees".tr}: ", "${coinFormat(trade.fees)} $baseCoin",
            color: pcl, fontSize: Dimens.fontSizeSmall),
        twoTextSpaceFixed("${"Price".tr}: ", "${coinFormat(trade.price)} $baseCoin",
            color: pcl, fontSize: Dimens.fontSizeSmall),
        if (fromKey != FromKey.buy)
          twoTextSpaceFixed("${"Processed".tr}: ", "${coinFormat(trade.processed)} $tradeCoin",
              color: pcl, fontSize: Dimens.fontSizeSmall),
        if (fromKey != FromKey.trade)
          twoTextSpaceFixed("${"Total".tr}: ", "${coinFormat(trade.total)} $baseCoin",
              color: pcl, fontSize: Dimens.fontSizeSmall),
        twoTextSpaceFixed("${"Created At".tr}: ", formatDate(trade.createdAt, format: dateTimeFormatDdMMMMYyyyHhMm),
            color: pcl, fontSize: Dimens.fontSizeSmall),
        if (fromKey == FromKey.trade) textWithCopyView(trade.transactionId ?? "", mainAxisAlign: MainAxisAlignment.end),
        dividerHorizontal()
      ],
    );
  }
}

class SpotTradeHistoryStopLimitItemView extends StatelessWidget {
  const SpotTradeHistoryStopLimitItemView(
      {super.key, required this.trade, required this.orderData, required this.onCancel});

  final StopLimitOrder trade;
  final OrderData? orderData;
  final Function(StopLimitOrder) onCancel;

  @override
  Widget build(BuildContext context) {
    final color = trade.type == FromKey.buy ? gBuyColor : gSellColor;
    final tradeCoin = orderData?.tradeCoin ?? "";
    final baseCoin = orderData?.baseCoin ?? "";
    final pcl = context.theme.primaryColorLight;
    return Column(
      children: [
        Row(
          children: [
            buttonTextBordered((trade.type ?? "").toUpperCase(), true,
                color: color, visualDensity: minimumVisualDensity),
            const Spacer(),
            buttonText("Cancel".tr, visualDensity: minimumVisualDensity, onPress: () => onCancel(trade)),
          ],
        ),
        twoTextSpaceFixed("${"Amount".tr}: ", "${coinFormat(trade.amount)} $tradeCoin",
            color: pcl, fontSize: Dimens.fontSizeSmall),
        twoTextSpaceFixed("${"Fees".tr}: ", "${coinFormat(trade.fees)} $baseCoin",
            color: pcl, fontSize: Dimens.fontSizeSmall),
        twoTextSpaceFixed("${"Price".tr}: ", "${coinFormat(trade.price)} $baseCoin",
            color: pcl, fontSize: Dimens.fontSizeSmall),
        twoTextSpaceFixed("${"Stop".tr}: ", "${coinFormat(trade.stop)} $baseCoin",
            color: pcl, fontSize: Dimens.fontSizeSmall),
        twoTextSpaceFixed("${"Total".tr}: ", "${coinFormat(trade.total)} $baseCoin",
            color: pcl, fontSize: Dimens.fontSizeSmall),
        // twoTextSpaceFixed("${"Created At".tr}: ", formatDate(trade.createdAt, format: dateTimeFormatDdMMMMYyyyHhMm)),
        dividerHorizontal()
      ],
    );
  }
}
