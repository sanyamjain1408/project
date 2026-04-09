import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';

import '../../../../ui/ui_helper/app_widgets.dart';
import '../../models/p2p_ads.dart';
import '../p2p_common_widgets.dart';
import 'p2p_ads_controller.dart';
import 'p2p_ads_create/p2p_create_ads_page.dart';

class P2PAdsScreen extends StatefulWidget {
  const P2PAdsScreen({super.key});

  @override
  State<P2PAdsScreen> createState() => _P2PAdsScreenState();
}

class _P2PAdsScreenState extends State<P2PAdsScreen> with TickerProviderStateMixin {
  final _controller = Get.put(P2pAdsController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getP2pAdsList(false));
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          vSpacer10(),
          Row(
            children: [
              hSpacer10(),
              Obx(() {
                final color = _controller.sTransactionType.value == 1 ? gBuyColor : gSellColor;
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: Get.width - 100),
                  child: SegmentedControlView(["Buy Ads".tr, "Sell Ads".tr], _controller.sTransactionType.value, onChange: (index) {
                    _controller.sTransactionType.value = index;
                    _controller.getP2pAdsList(false);
                  }, selectedColor: color),
                );
              }),
              const Spacer(),
              buttonText("Create".tr, visualDensity: VisualDensity.compact, onPress: () => Get.to(() => const P2pCreateAdsPage())),
              hSpacer10()
            ],
          ),
          Obx(() => _controller.adsList.isEmpty
              ? handleEmptyViewWithLoading(_controller.isDataLoading.value)
              : Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(Dimens.paddingMid),
                    itemCount: _controller.adsList.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (_controller.hasMoreData && index == (_controller.adsList.length - 1)) {
                        WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getP2pAdsList(true));
                      }
                      return MyAdsItemView(_controller.adsList[index], _controller.sTransactionType.value == 1, onIconTap: (id) {
                        if (id == 1) {
                          _controller.p2pAdsStatusChange(_controller.adsList[index]);
                        } else if (id == 2) {
                          _controller.p2pAdsDelete(_controller.adsList[index]);
                        }
                      });
                    },
                  ),
                ))
        ],
      ),
    );
  }
}

class MyAdsItemView extends StatelessWidget {
  const MyAdsItemView(this.p2pAds, this.isBuy, {super.key, required this.onIconTap});

  final P2PAds p2pAds;
  final bool isBuy;
  final Function(int) onIconTap;

  @override
  Widget build(BuildContext context) {
    final limitSrt = "${coinFormat(p2pAds.minimumTradeSize)}~${coinFormat(p2pAds.maximumTradeSize)} ${p2pAds.currency ?? ""}";
    return Card(
      margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMin),
      color: context.theme.secondaryHeaderColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(Dimens.paddingMid),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TwoTextSpaceFixed(
              "${coinFormat(p2pAds.price)} ${p2pAds.currency ?? ""}",
              limitSrt,
              flex: 6,
              subColor: context.theme.primaryColorLight,
              color: context.theme.primaryColor,
            ),
            TwoTextSpaceFixed("${"Available".tr} : ", "${coinFormat(p2pAds.available)} ${p2pAds.coinType ?? ""}",
                tFontSize: Dimens.fontSizeSmall),
            TwoTextSpaceFixed("${"Date".tr} : ", formatDate(p2pAds.createdAt, format: dateTimeFormatDdMMMYyyyHhMm),
                tFontSize: Dimens.fontSizeSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                toggleSwitch(height: 20, selectedValue: p2pAds.status == 1, onChange: (ch) => onIconTap(1)),
                hSpacer10(),
                P2pIconWithTap(
                    icon: Icons.edit_note,
                    iconColor: context.theme.focusColor,
                    onTap: () => Get.to(() => P2pCreateAdsPage(editableAds: p2pAds, isBuy: isBuy))),
                P2pIconWithTap(
                    icon: Icons.delete_outline,
                    iconColor: context.theme.colorScheme.error,
                    onTap: () {
                      alertForAction(context,
                          title: "Delete this ad".tr,
                          subTitle: "Are you sure to proceed".tr,
                          onOkAction: () => onIconTap(2),
                          buttonTitle: "Delete".tr,
                          buttonColor: context.theme.colorScheme.error);
                    }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
