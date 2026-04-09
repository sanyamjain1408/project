import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/p2p_constants.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../../../ui/ui_helper/app_widgets.dart';
import '../../../models/p2p_gift_card.dart';
import '../../../p2p_common_utils.dart';
import '../p2p_gc_create_ad/p2p_gc_create_ad_screen.dart';
import 'p2p_gc_ads_controller.dart';

class P2PGCAdsScreen extends StatefulWidget {
  const P2PGCAdsScreen({super.key});

  @override
  State<P2PGCAdsScreen> createState() => _P2PGCAdsScreenState();
}

class _P2PGCAdsScreenState extends State<P2PGCAdsScreen> with TickerProviderStateMixin {
  final _controller = Get.put(P2pGCAdsController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getP2pGiftCardUserAdList(false));
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
          child: Row(
            children: [
              Expanded(flex: 4, child: TextRobotoAutoBold("${"Ads Status".tr}: ", color: context.theme.primaryColorLight)),
              hSpacer5(),
              Obx(() {
                return Expanded(
                  flex: 6,
                  child: dropDownListIndex(_controller.getOrderTypeMap().values.toList(), _controller.selectedOrderStatus.value, "", (index) {
                    _controller.selectedOrderStatus.value = index;
                    _controller.getP2pGiftCardUserAdList(false);
                  }, bgColor: Colors.transparent, hMargin: 0, height: 35),
                );
              }),
            ],
          ),
        ),
        Obx(() => _controller.gcOrderList.isEmpty
            ? handleEmptyViewWithLoading(_controller.isDataLoading.value)
            : Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(Dimens.paddingMid),
                  itemCount: _controller.gcOrderList.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (_controller.hasMoreData && index == (_controller.gcOrderList.length - 1)) {
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getP2pGiftCardUserAdList(true));
                    }
                    return P2pGCAdItemView(_controller.gcOrderList[index]);
                  },
                ),
              ))
      ]),
    );
  }
}

class P2pGCAdItemView extends StatelessWidget {
  const P2pGCAdItemView(this.p2pGiftCardAd, {super.key});

  final P2PGiftCardAd p2pGiftCardAd;

  @override
  Widget build(BuildContext context) {
    final status = getGiftCardStatusData(p2pGiftCardAd.status);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMin),
      color: Colors.grey.withValues(alpha: 0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(Dimens.paddingMid),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TwoTextSpaceFixed("${coinFormatP2p(p2pGiftCardAd.price)} ${p2pGiftCardAd.currencyType ?? ""}", status.first,
                subColor: status.last, flex: 8, color: context.theme.primaryColor),
            TwoTextSpaceFixed("${"Amount".tr} : ", "${coinFormatP2p(p2pGiftCardAd.amount)} ${p2pGiftCardAd.giftCard?.coinType ?? ""}"),
            TwoTextSpaceFixed("${"Created At".tr} : ", formatDate(p2pGiftCardAd.createdAt, format: dateTimeFormatDdMMMYyyyHhMm)),
            vSpacer5(),
            if ([P2pGiftCardStatus.active, P2pGiftCardStatus.deActive].contains(p2pGiftCardAd.status))
              Wrap(
                spacing: Dimens.paddingMid,
                runSpacing: Dimens.paddingMid,
                children: [
                  buttonText("Edit".tr, onPress: () async {
                    final result = await Get.to(() => P2PGCCreateAdScreen(preAd: p2pGiftCardAd));
                    if (result != null && result == true) Get.find<P2pGCAdsController>().getP2pGiftCardUserAdList(false);
                  }, visualDensity: minimumVisualDensity),
                  buttonText("Delete".tr, bgColor: Colors.redAccent, textColor: Colors.white, onPress: () {
                    alertForAction(context,
                        title: "Delete Gift Card Ad",
                        subTitle: "Are you sure to proceed".tr,
                        buttonTitle: "Yes".tr.toUpperCase(),
                        onOkAction: () => Get.find<P2pGCAdsController>().p2pGiftCardDeleteAd(p2pGiftCardAd));
                  }, visualDensity: minimumVisualDensity),
                ],
              )
          ],
        ),
      ),
    );
  }
}
