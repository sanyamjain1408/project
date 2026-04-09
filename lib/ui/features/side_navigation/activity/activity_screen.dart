import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../data/models/exchange_order.dart';
import '../../../../../data/models/history.dart';
import '../../../../../data/models/referral.dart';
import '../../../../../helper/app_checker.dart';
import '../../../../../utils/button_util.dart';
import '../../../../../utils/appbar_util.dart';
import '../../../../../utils/dimens.dart';
import '../../../../../utils/spacers.dart';
import '../../../../../ui/ui_helper/app_widgets.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/common_widgets.dart';
import '../../../../../utils/text_field_util.dart';
import 'activity_controller.dart';
import 'activity_widgets.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  ActivityScreenState createState() => ActivityScreenState();
}

class ActivityScreenState extends State<ActivityScreen> with TickerProviderStateMixin {
  final _controller = Get.put(ActivityScreenController());

  @override
  void initState() {
    if (TemporaryData.activityType != null) {
      final index = _controller.getTypeMap().keys.toList().indexOf(TemporaryData.activityType!);
      if (index != -1) _controller.selectedType.value = index;
      TemporaryData.activityType = null;
    }
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (gUserRx.value.id > 0) _controller.getListData(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(title: "Reports".tr),
      body: SafeArea(
        child: Obx(() => gUserRx.value.id == 0
            ? signInNeedView()
            : Column(
                children: [
                  dropDownListIndex(_controller.getTypeMap().values.toList(), _controller.selectedType.value, "All type".tr, (value) {
                    _controller.selectedType.value = value;
                    _controller.isFiat.value = false;
                    _controller.searchController.text = "";
                    _controller.getListData(false);
                  }, bgColor: Colors.transparent, height: Dimens.btnHeightMid),
                  if (_controller.getKey() == HistoryType.deposit || _controller.getKey() == HistoryType.withdraw)
                    Row(
                      children: [
                        hSpacer10(),
                        _currencyButtonView("Crypto".tr, _controller.isFiat.value == false, () {
                          _controller.isFiat.value = false;
                        } ),
                        hSpacer5(),
                        _currencyButtonView("Fiat".tr, _controller.isFiat.value == true, () {
                          _controller.isFiat.value = true;
                        } ),
                        hSpacer5(),
                        Expanded(child:
                          textFieldSearch(
                              controller: _controller.searchController,
                              height: Dimens.btnHeightSmall,
                              margin: 0,
                              onTextChange: _controller.onTextChanged)
                        ),
                        hSpacer10(),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
                      child: textFieldSearch(
                          controller: _controller.searchController, height: Dimens.btnHeightSmall, margin: 0, onTextChange: _controller.onTextChanged),
                    ),
                  _activityTypeList()
                ],
              )),
      ),
    );
  }

  Widget _currencyButtonView(String title, bool isSelected, VoidCallback onTap) {
    return buttonTextBordered(title,isSelected, onPress: () {
      onTap();
      _controller.searchController.text = "";
      _controller.getListData(false);
    }, visualDensity: minimumVisualDensity);
  }

  Widget _activityTypeList() {
    return Obx(() {
      final key = _controller.getKey();
      final historyData = AppChecker.getHistoryTypeData(key);
      return _controller.activityDataList.isEmpty
          ? handleEmptyViewWithLoading(_controller.isLoading.value)
          : Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(Dimens.paddingMid),
          itemCount: _controller.activityDataList.length,
          separatorBuilder: (context, index) => dividerHorizontal(),
          itemBuilder: (context, index) {
              if (index == (_controller.activityDataList.length -1 )) {
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  if (_controller.hasMoreData) _controller.getListData(true);
                });
              }

            final item = _controller.activityDataList[index];
            if (key == HistoryType.swap && item is SwapHistory) {
              return SwapHistoryItemView(item, historyData);
            } else if ((key == HistoryType.buyOrder || key == HistoryType.sellOrder || key == HistoryType.transaction) && item is Trade) {
              return TradeItemView(item, historyData, key);
            } else if ((key == HistoryType.fiatDeposit || key == HistoryType.fiatWithdrawal) && item is FiatHistory) {
              return FiatHistoryItemView(item, historyData);
            } else if (key == HistoryType.stopLimit && item is Trade) {
              return StopLimitItemView(item, historyData);
            } else if ((key == HistoryType.refEarningWithdrawal || key == HistoryType.refEarningTrade) && item is ReferralHistory) {
              return ReferralItemView(item, historyData, key);
            } else if (((key == HistoryType.deposit && _controller.isFiat.value) ||
                (key == HistoryType.withdraw && _controller.isFiat.value)) &&
                item is WalletCurrencyHistory) {
              return WalletFiatHistory(history: item, historyData: historyData, type: key);
            } else if (item is History) {
              return HistoryItemView(item, historyData, key);
            } else {
              return vSpacer0();
            }
          },
        ),
      );
    });
  }

}

