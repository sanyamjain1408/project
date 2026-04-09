import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/models/p2p_ads.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/ui/p2p_home/p2p_home_controller.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/faq/faq_page.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../../ui/ui_helper/app_widgets.dart';
import '../../models/p2p_settings.dart';
import '../p2p_ads_details/p2p_ads_details_screen.dart';
import '../p2p_common_widgets.dart';

class P2pAdsItemView extends StatelessWidget {
  const P2pAdsItemView(this.p2pAds, this.transactionType, {super.key});

  final P2PAds p2pAds;
  final int transactionType;

  @override
  Widget build(BuildContext context) {
    final btnTitle = transactionType == 1 ? "Buy".tr : "Sell".tr;
    final color = transactionType == 1 ? gBuyColor : gSellColor;
    final limitSrt = "${coinFormat(p2pAds.minimumTradeSize)}-${coinFormat(p2pAds.maximumTradeSize)} ${p2pAds.currency ?? ""}";
    return Card(
      margin: const EdgeInsets.symmetric(vertical: Dimens.paddingMin),
      color: Colors.grey.withValues(alpha: 0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(Dimens.paddingMid),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                P2pUserView(user: p2pAds.user, isActiveOnTap: gUserRx.value.id > 0),
                buttonText("$btnTitle ${p2pAds.coinType ?? ""}", visualDensity: VisualDensity.compact, bgColor: color, textColor: Colors.white,
                    onPress: () {
                  checkLoggedInStatus(context, () => Get.to(() => P2pAdsDetailsScreen(p2pAds: p2pAds, adsType: transactionType)));
                })
              ],
            ),
            vSpacer5(),
            TwoTextSpaceFixed("${"Price".tr} : ", "${coinFormat(p2pAds.price)} ${p2pAds.currency ?? ""}", fontSize: Dimens.fontSizeSmall),
            TwoTextSpaceFixed("${"Available".tr} : ", "${coinFormat(p2pAds.available)} ${p2pAds.coinType ?? ""}",
                fontSize: Dimens.fontSizeSmall),
            TwoTextSpaceFixed("${"Limit".tr} : ", limitSrt, fontSize: Dimens.fontSizeSmall),
            if (p2pAds.paymentMethodList.isValid)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextRobotoAutoBold("${"Payment".tr} : ", color: context.theme.primaryColorLight, fontSize: Dimens.fontSizeSmall),
                  Expanded(
                    child: Wrap(
                      runSpacing: Dimens.paddingMin,
                      spacing: Dimens.paddingMin,
                      alignment: WrapAlignment.end,
                      children: List.generate(p2pAds.paymentMethodList?.length ?? 0, (index) {
                        return Container(
                          padding: const EdgeInsets.all(Dimens.paddingMin),
                          decoration: boxDecorationRoundCorner(color: Colors.grey.withValues(alpha: 0.3)),
                          child: TextRobotoAutoBold(p2pAds.paymentMethodList![index].bankForm?.title ?? "",
                              fontSize: Dimens.fontSizeMin),
                          // child: TextRobotoAutoBold(p2pAds.paymentMethodList![index].adminPaymentMethod?.name ?? "",
                          //     fontSize: Dimens.fontSizeMin),
                        );
                      }),
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}

class P2pHomeFilterView extends StatelessWidget {
  const P2pHomeFilterView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<P2PHomeController>();
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(Dimens.paddingMid),
        children: [
          TextRobotoAutoNormal("Limit Amount".tr, fontSize: Dimens.fontSizeMid),
          vSpacer5(),
          textFieldWithSuffixIcon(
              controller: controller.amountEditController,
              hint: "Write Amount".tr,
              type: TextInputType.number,
              onTextChange: (text) => controller.hasFilterChanged = true),
          vSpacer15(),
          TextRobotoAutoNormal("Fiat".tr, fontSize: Dimens.fontSizeMid),
          Obx(() {
            return dropDownListIndex(controller.getCurrencyNameList(), controller.selectedCurrency.value, "", (index) {
              controller.selectedCurrency.value = index;
              controller.hasFilterChanged = true;
            }, bgColor: Colors.transparent, hMargin: 0);
          }),
          vSpacer15(),
          TextRobotoAutoNormal("Payment".tr, fontSize: Dimens.fontSizeMid),
          Obx(() {
            return dropDownListIndex(controller.getPaymentNameList(), controller.selectedPayment.value, "", (index) {
              controller.selectedPayment.value = index;
              controller.hasFilterChanged = true;
            }, bgColor: Colors.transparent, hMargin: 0);
          }),
          vSpacer15(),
          TextRobotoAutoNormal("Available Regions".tr, fontSize: Dimens.fontSizeMid),
          Obx(() {
            return dropDownListIndex(controller.getCountryNameList(), controller.selectedCountry.value, "", (index) {
              controller.selectedCountry.value = index;
              controller.hasFilterChanged = true;
            }, bgColor: Colors.transparent, hMargin: 0);
          }),
          vSpacer10(),
        ],
      ),
    );
  }
}

class P2pTutorialView extends StatelessWidget {
  const P2pTutorialView({super.key, required this.settings});

  final P2PAdsSettings settings;

  @override
  Widget build(BuildContext context) {
    RxBool isBuy = true.obs;
    return Expanded(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
        children: [
          Obx(() {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buttonTutorialText(isBuy.value, "Buy Crypto".tr, () => isBuy.value = true),
                    hSpacer5(),
                    _buttonTutorialText(!isBuy.value, "Sell Crypto".tr, () => isBuy.value = false)
                  ],
                ),
                if (isBuy.value && settings.p2PBuyStep1Heading.isValid)
                  _tutorialItemView(settings.p2PBuyStep1Icon, settings.p2PBuyStep1Heading, settings.p2PBuyStep1Des),
                if (isBuy.value && settings.p2PBuyStep2Heading.isValid)
                  _tutorialItemView(settings.p2PBuyStep2Icon, settings.p2PBuyStep2Heading, settings.p2PBuyStep2Des),
                if (isBuy.value && settings.p2PBuyStep3Heading.isValid)
                  _tutorialItemView(settings.p2PBuyStep3Icon, settings.p2PBuyStep3Heading, settings.p2PBuyStep3Des),
                if (!isBuy.value && settings.p2PSellStep1Heading.isValid)
                  _tutorialItemView(settings.p2PSellStep1Icon, settings.p2PSellStep1Heading, settings.p2PSellStep1Des),
                if (!isBuy.value && settings.p2PSellStep2Heading.isValid)
                  _tutorialItemView(settings.p2PSellStep2Icon, settings.p2PSellStep2Heading, settings.p2PSellStep2Des),
                if (!isBuy.value && settings.p2PSellStep3Heading.isValid)
                  _tutorialItemView(settings.p2PSellStep3Icon, settings.p2PSellStep3Heading, settings.p2PSellStep3Des),
              ],
            );
          }),
          vSpacer30(),
          TextRobotoAutoBold("Advantage of P2P Exchange".tr),
          vSpacer10(),
          if (settings.p2PAdvantage1Heading.isValid)
            _tutorialItemView(settings.p2PAdvantage1Icon, settings.p2PAdvantage1Heading, settings.p2PAdvantage1Des),
          if (settings.p2PAdvantage2Heading.isValid)
            _tutorialItemView(settings.p2PAdvantage2Icon, settings.p2PAdvantage2Heading, settings.p2PAdvantage2Des),
          if (settings.p2PAdvantage3Heading.isValid)
            _tutorialItemView(settings.p2PAdvantage3Icon, settings.p2PAdvantage3Heading, settings.p2PAdvantage3Des),
          if (settings.p2PAdvantage4Heading.isValid)
            _tutorialItemView(settings.p2PAdvantage4Icon, settings.p2PAdvantage4Heading, settings.p2PAdvantage4Des),
          FAQRelatedView(settings.p2PFaq ?? []),
          vSpacer30(),
          TextRobotoAutoBold("Top Payment Methods".tr),
          vSpacer10(),
          Wrap(
            runSpacing: Dimens.paddingMin,
            spacing: Dimens.paddingMin,
            children: List.generate(settings.paymentMethodLanding?.length ?? 0, (index) {
              return Container(
                padding: const EdgeInsets.all(Dimens.paddingMid),
                decoration: boxDecorationRoundCorner(color: context.theme.dialogTheme.backgroundColor),
                child: TextRobotoAutoBold(settings.paymentMethodLanding![index].name ?? "", fontSize: Dimens.fontSizeMidExtra),
              );
            }),
          ),
          vSpacer10(),
        ],
      ),
    );
  }

  Widget _buttonTutorialText(bool selected, String title, VoidCallback onTap) => buttonText(title,
      bgColor: selected ? Get.theme.focusColor : Colors.transparent,
      fontSize: Dimens.fontSizeMidExtra,
      onPress: onTap,
      visualDensity: VisualDensity.compact);

  ListTile _tutorialItemView(String? imagePath, String? title, String? subTitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: showImageNetwork(imagePath: imagePath, height: Dimens.iconSizeLargeExtra, width: Dimens.iconSizeLargeExtra, boxFit: BoxFit.cover),
      title: TextRobotoAutoBold(title ?? ""),
      subtitle: TextRobotoAutoNormal(subTitle ?? "", fontSize: Dimens.fontSizeSmall, maxLines: 100),
    );
  }
}
