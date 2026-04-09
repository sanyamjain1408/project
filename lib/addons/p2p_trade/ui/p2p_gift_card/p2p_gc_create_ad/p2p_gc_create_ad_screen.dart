import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/ui/p2p_common_widgets.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/gift_cards/gift_cards_widgets.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../../models/p2p_gift_card.dart';
import 'p2p_gc_create_ad_controller.dart';

class P2PGCCreateAdScreen extends StatefulWidget {
  const P2PGCCreateAdScreen({super.key, this.preAd, this.p2pGiftCard});

  final P2pGiftCard? p2pGiftCard;
  final P2PGiftCardAd? preAd;

  @override
  State<P2PGCCreateAdScreen> createState() => _P2PGCCreateAdScreenState();
}

class _P2PGCCreateAdScreenState extends State<P2PGCCreateAdScreen> with TickerProviderStateMixin {
  final _controller = Get.put(P2pGCCreateAdController());

  @override
  void initState() {
    _controller.onUIUpdate = onUIUpdate;
    _controller.isEdit = widget.preAd != null;
    if (widget.p2pGiftCard != null) _controller.p2pGiftCard = widget.p2pGiftCard!;
    if (widget.preAd != null) _controller.preAd = widget.preAd!;
    _controller.selectedPaymentType.value = -1;
    _controller.selectedCurrency.value = -1;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_controller.isEdit) _controller.getP2pGiftCardDetails();
      _controller.getGiftCardCSettings();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void onUIUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final giftCard = _controller.p2pGiftCard.giftCard;
    final amountStr = "${coinFormat(giftCard?.amount)} ${giftCard?.coinType}";
    String imagePath = giftCard?.banner?.image ?? giftCard?.banner?.banner ?? "";
    return KeyboardDismissOnTap(
      child: Scaffold(
          appBar: appBarBackWithActions(title: _controller.isEdit ? "Edit Gift Card Ad".tr : "Create Gift Card Ad".tr),
          body: SafeArea(
            child: _controller.isLoading
                ? showLoading()
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(Dimens.paddingMid),
                    children: [
                      GiftCardImageAndTag(imagePath: imagePath, amountText: amountStr),
                      vSpacer15(),
                      TextRobotoAutoBold(giftCard?.banner?.title ?? "", maxLines: 5),
                      vSpacer5(),
                      TextRobotoAutoNormal(giftCard?.banner?.subTitle ?? "", maxLines: 10, color: Get.theme.primaryColor),
                      dividerHorizontal(height: Dimens.btnHeightMid),
                      TextRobotoAutoNormal("Payment Type".tr, fontSize: Dimens.fontSizeMid),
                      Obx(() {
                        return dropDownListIndex(
                            ["Bank Transfer".tr, "Crypto Transfer".tr], _controller.selectedPaymentType.value, "Select Payment Type".tr, (index) {
                          _controller.selectedPaymentType.value = index;
                          _controller.selectedCurrency.value = -1;
                        }, hMargin: 0, bgColor: Colors.transparent, radius: Dimens.radiusCornerMid);
                      }),
                      Obx(() {
                        return _controller.selectedPaymentType.value == -1
                            ? vSpacer0()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  vSpacer15(),
                                  TextRobotoAutoNormal("Currency Type".tr, fontSize: Dimens.fontSizeMid),
                                  dropDownListIndex(_controller.getCurrencyNameList(), _controller.selectedCurrency.value, "Select Currency".tr,
                                      (index) {
                                    _controller.selectedCurrency.value = index;
                                  }, hMargin: 0, bgColor: Colors.transparent, radius: Dimens.radiusCornerMid),
                                ],
                              );
                      }),
                      vSpacer15(),
                      TextRobotoAutoNormal("Price".tr, fontSize: Dimens.fontSizeMid),
                      vSpacer5(),
                      textFieldWithSuffixIcon(
                          controller: _controller.priceEditController,
                          hint: "Enter Price".tr,
                          type: TextInputType.number,
                          contentPadding: const EdgeInsets.all(Dimens.paddingLarge),
                          borderRadius: Dimens.radiusCornerMid),
                      vSpacer15(),
                      TextRobotoAutoNormal("Status".tr, fontSize: Dimens.fontSizeMid),
                      Obx(() {
                        return dropDownListIndex(["Active".tr, "Deactivate".tr], _controller.selectedStatus.value, "", (index) {
                          _controller.selectedStatus.value = index;
                        }, hMargin: 0, bgColor: Colors.transparent, radius: Dimens.radiusCornerMid);
                      }),
                      Obx(() {
                        return _controller.selectedPaymentType.value == 0
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  vSpacer15(),
                                  TextRobotoAutoNormal("Payment Method".tr, fontSize: Dimens.fontSizeMid),
                                  vSpacer5(),
                                  TagSelectionViewString(
                                      tagList: _controller.getPaymentNameList(),
                                      tagController: _controller.paymentTagController,
                                      initialSelection: _controller.selectedPayMethods,
                                      onTagSelected: (list) => _controller.selectedPayMethods = list),
                                ],
                              )
                            : vSpacer0();
                      }),
                      vSpacer15(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextRobotoAutoNormal("Available Regions".tr, fontSize: Dimens.fontSizeMid),
                          Row(
                            children: [
                              Obx(() =>
                                  TextRobotoAutoBold(_controller.selectedCountryList.length.toString(), color: Get.theme.colorScheme.secondary)),
                              buttonOnlyIcon(
                                  iconData: Icons.cancel_outlined,
                                  visualDensity: minimumVisualDensity,
                                  iconColor: Get.theme.primaryColor,
                                  onPress: () {
                                    _controller.countryTagController.clearTags();
                                    _controller.selectedCountryList.clear();
                                  })
                            ],
                          )
                        ],
                      ),
                      TagSelectionViewString(
                          tagList: _controller.getCountryNameList(),
                          tagController: _controller.countryTagController,
                          initialSelection: _controller.selectedCountryList,
                          onTagSelected: (list) => _controller.selectedCountryList.value = list),
                      vSpacer15(),
                      TextRobotoAutoNormal("Time Limit".tr, fontSize: Dimens.fontSizeMid),
                      Obx(() => dropDownListIndex(
                          _controller.getTimeLimitList(), _controller.selectedTime.value, "", (index) => _controller.selectedTime.value = index,
                          hMargin: 0, bgColor: Colors.transparent, radius: Dimens.radiusCornerMid)),
                      vSpacer15(),
                      TextRobotoAutoNormal("Terms And Conditions".tr, fontSize: Dimens.fontSizeMid),
                      vSpacer5(),
                      textFieldWithSuffixIcon(
                          controller: _controller.termsEditController,
                          hint: "Enter Terms And Conditions".tr,
                          maxLines: 3,
                          height: 80,
                          borderRadius: Dimens.radiusCornerMid),
                      vSpacer15(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          buttonText("Cancel".tr,
                              bgColor: context.theme.dialogTheme.backgroundColor, visualDensity: VisualDensity.compact, onPress: () => Get.back()),
                          hSpacer10(),
                          buttonText(_controller.isEdit ? "Update".tr : "Create".tr,
                              visualDensity: VisualDensity.compact,
                              textColor: context.theme.scaffoldBackgroundColor,
                              onPress: () => _controller.checkInputData(context)),
                        ],
                      )
                    ],
                  ),
          )),
    );
  }
}
