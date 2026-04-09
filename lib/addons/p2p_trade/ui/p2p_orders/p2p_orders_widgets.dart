import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/models/p2p_order.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../../ui/ui_helper/app_widgets.dart';
import '../../p2p_common_utils.dart';
import '../p2p_order_details/p2p_order_details_screen.dart';
import 'p2p_orders_controller.dart';

class P2pOrderItemView extends StatelessWidget {
  const P2pOrderItemView(this.p2pOrder, {super.key, required this.isDisputeList});

  final P2POrder p2pOrder;
  final bool isDisputeList;

  @override
  Widget build(BuildContext context) {
    final status = getTradeTypeData(p2pOrder.status, isDispute: isDisputeList);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.to(() => P2pOrderDetailsScreen(uid: p2pOrder.uid ?? "")),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMin),
          color: context.theme.secondaryHeaderColor,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(Dimens.paddingMid),
            child: Column(
              children: [
                TwoTextSpaceFixed("${"Order Id".tr} : ", p2pOrder.orderId ?? ""),
                TwoTextSpaceFixed("${"Amount".tr} : ", "${coinFormat(p2pOrder.amount)} ${p2pOrder.coinType ?? ""}"),
                TwoTextSpaceFixed("${"Price".tr} : ", "${coinFormat(p2pOrder.price)} ${p2pOrder.currency ?? ""}"),
                TwoTextSpaceFixed("${"Seller fees".tr} : ", coinFormat(p2pOrder.sellerFees ?? 0)),
                TwoTextSpaceFixed("${"Status".tr} : ", status.first, subColor: status.last),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class P2pOrdersFilterView extends StatelessWidget {
  const P2pOrdersFilterView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<P2POrdersController>();
    return Flexible(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(Dimens.paddingMid),
        children: [
          TextRobotoAutoNormal("Coin".tr, fontSize: Dimens.fontSizeMid),
          Obx(() {
            return dropDownListIndex(controller.getCoinNameList(), controller.selectedCoin.value, "", (index) {
              controller.selectedCoin.value = index;
              controller.hasFilterChanged = true;
            }, hMargin: 0, bgColor: Colors.transparent);
          }),
          vSpacer15(),
          TextRobotoAutoNormal("Order Type".tr, fontSize: Dimens.fontSizeMid),
          Obx(() {
            return dropDownListIndex(controller.getOrderTypeMap().values.toList(), controller.selectedOrderStatus.value, "", (index) {
              controller.selectedOrderStatus.value = index;
              controller.hasFilterChanged = true;
            }, hMargin: 0, bgColor: Colors.transparent);
          }),
          vSpacer15(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextRobotoAutoNormal("From".tr, fontSize: Dimens.fontSizeMid),
                    vSpacer5(),
                    _datePickerView(context, true, controller)
                  ],
                ),
              ),
              hSpacer15(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextRobotoAutoNormal("To".tr, fontSize: Dimens.fontSizeMid),
                    vSpacer5(),
                    _datePickerView(context, false, controller)
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _datePickerView(BuildContext context, bool isStart, P2POrdersController controller) {
    return Obx(() {
      final currentText = isStart ? controller.startDate.value : controller.endDate.value;
      return Container(
        decoration: boxDecorationRoundBorder(),
        padding: const EdgeInsets.all(Dimens.paddingMid),
        child: InkWell(
          onTap: () {
            showDatePickerView(context, (date) {
              final dateStr = formatDate(date, format: dateFormatMMDdYyyy);
              isStart ? controller.startDate.value = dateStr : controller.endDate.value = dateStr;
              controller.hasFilterChanged = true;
            });
          },
          child: Row(
            children: [
              Expanded(
                  child: currentText.isNotEmpty
                      ? TextRobotoAutoBold(currentText)
                      : const TextRobotoAutoNormal(dateFormatMMDdYyyy, fontSize: Dimens.fontSizeMidExtra)),
              Icon(Icons.calendar_month, size: Dimens.iconSizeMid, color: Get.theme.primaryColor)
            ],
          ),
        ),
      );
    });
  }
}
