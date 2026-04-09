import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/future_data.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import '../../wallet/wallet_widgets.dart';
import '../trade_widgets.dart';
import 'future_trade_controller.dart';

class OpenCloseTabViews extends StatefulWidget {
  final String? fromPage;

  const OpenCloseTabViews({super.key, this.fromPage});

  @override
  OpenCloseTabViewsState createState() => OpenCloseTabViewsState();
}

class OpenCloseTabViewsState extends State<OpenCloseTabViews> with SingleTickerProviderStateMixin {
  final _controller = Get.find<FutureTradeController>();
  TabController? tabController;

  RxBool isTpSlOpen = false.obs;
  final isLoggedIn = gUserRx.value.id > 0;

  RxInt selectedSubTabIndexOpen = 0.obs;
  RxInt selectedSubTabIndexClose = 0.obs;
  RxInt selectedSizeCoinIndex = 0.obs;
  final priceEditController = TextEditingController();
  final stopPriceEditController = TextEditingController();
  final sizeEditController = TextEditingController();
  final takeProfitEditController = TextEditingController();
  final stopLossEditController = TextEditingController();
  Timer? _preDataTimer;
  Rx<FTPreOrderData> ftPreOrderData = FTPreOrderData().obs;

  @override
  void initState() {
    _controller.onOpenCloseChange = onOpenCloseChange;
    _controller.selectedTabIndex.value = (widget.fromPage == FromKey.open ? 0 : 1);
    tabController = TabController(vsync: this, length: 2, initialIndex: _controller.selectedTabIndex.value);
    super.initState();
    setSelectedPrice.addListener(() {
      if (setSelectedPrice.value != null && setSelectedPrice.value! > 0) {
        int subIndex = _controller.selectedTabIndex.value == 0 ? selectedSubTabIndexOpen.value : selectedSubTabIndexClose.value;
        if (subIndex == 0 || subIndex == 2) priceEditController.text = setSelectedPrice.value.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        Obx(() => BuySellToggleButton(options: ["Open".tr, "Close".tr], selected: _controller.selectedTabIndex.value, onSelect: onOpenCloseChange)),
        vSpacer5(),
        Obx(() {
          int subIndex = _controller.selectedTabIndex.value == 0 ? selectedSubTabIndexOpen.value : selectedSubTabIndexClose.value;
          final total = _controller.futureDashboardData.value.orderData?.total;
          // final balance = total?.baseWallet?.balance;
          // if ((balance ?? 0) > 0) _controller.fBalance = balance!;
          final baseCoinType = total?.baseWallet?.coinType ?? "";
          final tradeCoinType = total?.tradeWallet?.coinType ?? "";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dropDownListIndex(["Limit".tr, "Market".tr, "Stop Limit".tr, "Stop Market".tr], subIndex, "", (index) {
                _clearInputViews();
                _controller.selectedTabIndex.value == 0 ? selectedSubTabIndexOpen.value = index : selectedSubTabIndexClose.value = index;
              }, height: Dimens.btnHeightMid, hMargin: 0, bgColor: Colors.transparent, radius: Dimens.radiusCornerSmall),
              vSpacer10(),
              if (subIndex == 2 || subIndex == 3)
                TradeTextFieldCalculate(
                    controller: stopPriceEditController, sTitle: "Stop Price".tr, sSubtitle: "Mark".tr, onTextChange: _onTextChanged),
              if (subIndex == 2 || subIndex == 3) vSpacer10(),
              if (subIndex == 0 || subIndex == 2)
                TradeTextFieldCalculate(controller: priceEditController, sTitle: "Price".tr, sSubtitle: baseCoinType, onTextChange: _onTextChanged),
              if (subIndex == 0 || subIndex == 2) vSpacer10(),
              _currencySwitchView([tradeCoinType, baseCoinType]),
              vSpacer5(),
              TradeTextFieldCalculate(
                  controller: sizeEditController,
                  sTitle: "Size".tr,
                  sSubtitle: selectedSizeCoinIndex.value == 0 ? tradeCoinType : baseCoinType,
                  onTextChange: _onTextChanged),
              _controller.selectedTabIndex.value == 0 ? _tpSLView(tradeCoinType) : vSpacer10(),
              isLoggedIn
                  ? TradeBalanceView(
                      balance: _controller.fBalance.value,
                      coinType: baseCoinType,
                      onTap: () => showModalSheetFullScreen(
                          context,
                          WalletTransferView(
                              isSend: false,
                              fromType: WalletViewType.future,
                              coinType: baseCoinType,
                              onSubmit: (amount) => transferFutureAmount(baseCoinType, amount))))
                  : const TradeLoginButton(),
              Obx(() => PreOrderDataView(
                  preData: ftPreOrderData.value,
                  total: _controller.futureDashboardData.value.orderData?.total,
                  isTrade: selectedSizeCoinIndex.value == 0)),
              if (isLoggedIn) _buttonView(),
            ],
          );
        })
      ],
    );
  }

  void onOpenCloseChange(int index) {
    _controller.selectedTabIndex.value = index;
    _clearInputViews();
  }

  FittedBox _currencySwitchView(List<String> list) {
    final popView = Row(
      children: [
        TextRobotoAutoBold(" (${list[selectedSizeCoinIndex.value]})", fontSize: Dimens.fontSizeMidExtra),
        Icon(Icons.arrow_drop_down, size: Dimens.iconSizeMinExtra, color: context.theme.primaryColor)
      ],
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.only(right: Dimens.paddingMin),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextRobotoAutoBold("Size".tr, fontSize: Dimens.fontSizeMid, color: context.theme.primaryColorLight),
            PopupMenuView(list, child: popView, onSelected: (selected) {
              Get.back();
              selectedSizeCoinIndex.value = list.indexOf(selected);
              _checkAndGetPreOrderData();
            }),
          ],
        ),
      ),
    );
  }

  Widget _tpSLView(String tradeCoinType) {
    return Obx(() => Column(
          children: [
            vSpacer5(),
            Row(children: [
              Checkbox(
                visualDensity: minimumVisualDensity,
                value: isTpSlOpen.value,
                onChanged: (bool? value) => isTpSlOpen.value = value ?? false,
              ),
              TextRobotoAutoBold("TP/SL".tr, fontSize: Dimens.fontSizeSmall)
            ]),
            if (isTpSlOpen.value)
              Column(children: [
                vSpacer5(),
                TradeTextFieldCalculate(controller: takeProfitEditController, sTitle: "Take Profit".tr, sSubtitle: tradeCoinType),
                vSpacer10(),
                TradeTextFieldCalculate(controller: stopLossEditController, sTitle: "Stop Loss".tr, sSubtitle: tradeCoinType),
              ])
          ],
        ));
  }

  Row _buttonView() {
    bool isOpen = _controller.selectedTabIndex.value == 0;
    return Row(
      children: [
        Expanded(
            child: buttonText(isOpen ? "Open Long".tr : "Close Short".tr,
                fontSize: Dimens.fontSizeSmall,
                visualDensity: VisualDensity.compact,
                radius: Dimens.radiusCornerMid,
                textColor: Colors.white,
                onPress: () => _checkInputData(isOpen ? true : null))),
        hSpacer10(),
        Expanded(
            child: buttonText(isOpen ? "Open Short".tr : "Close Long".tr,
                fontSize: Dimens.fontSizeSmall,
                visualDensity: VisualDensity.compact,
                radius: Dimens.radiusCornerMid,
                textColor: Colors.white,
                onPress: () => _checkInputData(isOpen ? false : null))),
      ],
    );
  }

  void _clearInputViews() {
    takeProfitEditController.text = "";
    stopLossEditController.text = "";
    sizeEditController.text = "";
    stopPriceEditController.text = "";
    isTpSlOpen.value = false;
    ftPreOrderData.value = FTPreOrderData();
    final price = _controller.futureDashboardData.value.orderData?.total?.tradeWallet?.lastPrice;
    priceEditController.text = coinFormat(price);
  }

  void _onTextChanged(String text) {
    if (_preDataTimer?.isActive ?? false) _preDataTimer?.cancel();
    _preDataTimer = Timer(const Duration(seconds: 1), () => _checkAndGetPreOrderData());
  }

  void _checkAndGetPreOrderData() {
    final fTrade = _setDataOnTrade();
    if (fTrade.orderType == OrderType.limit || fTrade.orderType == OrderType.stopLimit) {
      fTrade.price = makeDouble(priceEditController.text.trim());
    }
    if (fTrade.orderType == OrderType.stopLimit || fTrade.orderType == OrderType.stopMarket) {
      fTrade.stopPrice = makeDouble(stopPriceEditController.text.trim());
    }

    if (fTrade.orderType == OrderType.limit && ((fTrade.price ?? 0) <= 0 || (fTrade.amount ?? 0) <= 0)) {
      ftPreOrderData.value = FTPreOrderData();
      return;
    }

    if (fTrade.orderType == OrderType.market && (fTrade.amount ?? 0) <= 0) {
      ftPreOrderData.value = FTPreOrderData();
      return;
    }

    if (fTrade.orderType == OrderType.stopLimit && ((fTrade.price ?? 0) <= 0 || (fTrade.amount ?? 0) <= 0 || (fTrade.stopPrice ?? 0) <= 0)) {
      ftPreOrderData.value = FTPreOrderData();
      return;
    }

    if (fTrade.orderType == OrderType.stopMarket && ((fTrade.amount ?? 0) <= 0 || (fTrade.stopPrice ?? 0) <= 0)) {
      ftPreOrderData.value = FTPreOrderData();
      return;
    }
    _controller.prePlaceOrderData(fTrade, (data) => ftPreOrderData.value = data ?? FTPreOrderData());
  }

  CreateTrade _setDataOnTrade() {
    final fTrade = CreateTrade();
    fTrade.orderType = (_controller.selectedTabIndex.value == 0 ? selectedSubTabIndexOpen.value : selectedSubTabIndexClose.value) + 1;
    fTrade.amount = makeDouble(sizeEditController.text.trim());
    fTrade.tradeType = _controller.selectedTabIndex.value == 0 ? FutureTradeType.open : FutureTradeType.close;
    fTrade.marginMode = _controller.isIsolate.value ? MarginMode.isolate : MarginMode.cross;
    fTrade.leverageAmount = ListConstants.leverages[_controller.selectedLeverageIndex.value];
    fTrade.amountType = selectedSizeCoinIndex.value == 0 ? 2 : 1;
    if (isTpSlOpen.value) {
      final tp = makeDouble(takeProfitEditController.text.trim());
      if (tp > 0) fTrade.takeProfit = tp;
      final sl = makeDouble(stopLossEditController.text.trim());
      if (sl > 0) fTrade.stopLoss = tp;
    }
    return fTrade;
  }

  void _checkInputData(bool? isBuy) {
    final fTrade = _setDataOnTrade();
    if ((fTrade.amount ?? 0) <= 0) {
      showToast("amount_must_greater_than_0".tr);
      return;
    }

    if (fTrade.orderType == OrderType.limit || fTrade.orderType == OrderType.stopLimit) {
      fTrade.price = makeDouble(priceEditController.text.trim());
      if ((fTrade.price ?? 0) <= 0) {
        showToast("price_must_greater_than_0".tr);
        return;
      }
    }

    if (fTrade.orderType == OrderType.stopLimit || fTrade.orderType == OrderType.stopMarket) {
      fTrade.stopPrice = makeDouble(stopPriceEditController.text.trim());
      if ((fTrade.stopPrice ?? 0) <= 0) {
        showToast("stop_price_must_greater_than_0".tr);
        return;
      }
    }
    hideKeyboard(context: context);
    _controller.handlePlaceBuySellOrder(fTrade, isBuy);
  }

  void transferFutureAmount(String coinType, double amount) async {
    showLoadingDialog();
    try {
      final resp = await APIRepository().futureTradeWalletBalanceTransfer(1, coinType, amount);
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) Get.back();
    } catch (err) {
      hideLoadingDialog();
      showToast(err.toString());
    }
  }
}

class PreOrderDataView extends StatelessWidget {
  const PreOrderDataView({super.key, required this.preData, required this.total, required this.isTrade});

  final FTPreOrderData preData;
  final Total? total;
  final bool isTrade;

  @override
  Widget build(BuildContext context) {
    final baseCoinType = total?.baseWallet?.coinType ?? "";
    final tradeCoinType = total?.tradeWallet?.coinType ?? "";

    return preData.longCost == null && preData.shortCost == null
        ? vSpacer0()
        : Column(children: [
            vSpacer5(),
            Row(children: [
              Expanded(child: _textWithSpan("Cost".tr, "${coinFormat(preData.longCost)} $baseCoinType")),
              hSpacer10(),
              Expanded(child: _textWithSpan("Cost".tr, "${coinFormat(preData.shortCost)} $baseCoinType", textAlign: TextAlign.end))
            ]),
            Row(children: [
              Expanded(
                  child: _textWithSpan("Max".tr,
                      "${coinFormat(isTrade ? preData.maxSizeOpenLongTrade : preData.maxSizeOpenLongBase)} ${isTrade ? tradeCoinType : baseCoinType}")),
              hSpacer10(),
              Expanded(
                  child: _textWithSpan("Max".tr,
                      "${coinFormat(isTrade ? preData.maxSizeOpenShortTrade : preData.maxSizeOpenShortBase)} ${isTrade ? tradeCoinType : baseCoinType}",
                      textAlign: TextAlign.end))
            ]),
            vSpacer10()
          ]);
  }

  AutoSizeText _textWithSpan(String text, String details, {TextAlign? textAlign}) {
    return AutoSizeText.rich(
      TextSpan(
        text: "$text: ",
        style: Get.theme.textTheme.displaySmall,
        children: <TextSpan>[TextSpan(text: " $details", style: Get.theme.textTheme.displaySmall!.copyWith(color: Get.theme.primaryColor))],
      ),
      maxLines: 1,
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}

