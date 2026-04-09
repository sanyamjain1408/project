import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:textfield_tags/textfield_tags.dart';
import 'package:tradexpro_flutter/data/models/bank_data.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../p2p_common_widgets.dart';
import 'p2p_create_ads_controller.dart';

class CreateAdsPageThree extends StatefulWidget {
  const CreateAdsPageThree({super.key});

  @override
  State<CreateAdsPageThree> createState() => _CreateAdsPageThreeState();
}

class _CreateAdsPageThreeState extends State<CreateAdsPageThree> {
  final _controller = Get.find<P2pCreateAdsController>();

  @override
  void initState() {
    super.initState();
    _controller.countryTagController = StringTagController();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.countryTagController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Dimens.paddingMid),
      children: [
        TextRobotoAutoBold("Terms [Optional]".tr),
        vSpacer5(),
        textFieldWithSuffixIcon(
            controller: _controller.termsEditController,
            hint: "Terms will be displayed on the counterparty".tr,
            maxLines: 3,
            height: 80,
            borderRadius: Dimens.radiusCornerMid),
        vSpacer10(),
        TextRobotoAutoBold("Auto-reply [Optional]".tr),
        vSpacer5(),
        textFieldWithSuffixIcon(
            controller: _controller.replyEditController,
            hint: "Auto-reply will be displayed on the counterparty".tr,
            maxLines: 3,
            height: 80,
            borderRadius: Dimens.radiusCornerMid),
        vSpacer10(),
        TextRobotoAutoBold("Counterparty Conditions".tr),
        TextRobotoAutoNormal("Adding counterparty requirements message".tr, maxLines: 2),
        vSpacer5(),
        Row(
          children: [
            TextRobotoAutoBold("Register".tr),
            hSpacer5(),
            textFieldWithSuffixIcon(
                controller: _controller.regiEditController,
                width: 100,
                height: 40,
                type: TextInputType.number,
                isEnable: !_controller.isEdit,
                borderRadius: Dimens.radiusCornerMid),
            hSpacer5(),
            TextRobotoAutoBold("days ago".tr),
          ],
        ),
        vSpacer5(),
        Row(
          children: [
            TextRobotoAutoBold("Holding more than".tr),
            hSpacer5(),
            textFieldWithSuffixIcon(
                controller: _controller.holdingEditController,
                type: TextInputType.number,
                width: 100,
                height: 40,
                isEnable: !_controller.isEdit,
                borderRadius: Dimens.radiusCornerMid),
            hSpacer5(),
            TextRobotoAutoBold(_controller.currentAds?.coinType ?? ""),
          ],
        ),
        vSpacer20(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextRobotoAutoBold("Available Region[s]".tr),
            Row(
              children: [
                Obx(() => TextRobotoAutoBold(_controller.selectedCountryList.length.toString(),
                    fontSize: Dimens.fontSizeMid, color: context.theme.focusColor)),
                P2pIconWithTap(
                    icon: Icons.cancel_outlined,
                    onTap: () {
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
        vSpacer20(),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          buttonRoundedMain(
              text: "Previous".tr,
              bgColor: context.theme.dialogTheme.backgroundColor,
              width: 120,
              buttonHeight: Dimens.btnHeightMid,
              onPress: () => _controller.pageController
                  .animateToPage(_controller.currentPageCreate - 1, duration: const Duration(milliseconds: 100), curve: Curves.linearToEaseOut)),
          hSpacer10(),
          buttonRoundedMain(
              text: _controller.isEdit ? "Update".tr : "Create".tr, width: 120, buttonHeight: Dimens.btnHeightMid, onPress: () => _goForCreate()),
          hSpacer10()
        ]),
        vSpacer20(),
      ],
    );
  }

  void _goForCreate() {
    final terms = _controller.termsEditController.text.trim();
    if (terms.isValid) _controller.currentAds?.terms = terms;

    final reply = _controller.replyEditController.text.trim();
    if (reply.isValid) _controller.currentAds?.autoReply = reply;

    _controller.currentAds?.registerDays = makeInt(_controller.regiEditController.text.trim());
    _controller.currentAds?.coinHolding = makeDouble(_controller.holdingEditController.text.trim());

    // List<P2pPaymentInfo> payList = [];
    List<DynamicBank> payList = [];
    for (final payment in _controller.selectedPayMethods) {
      // final object = _controller.adsSettings!.paymentMethods?.firstWhere((element) => element.adminPaymentMethod?.name == payment);
      final object = _controller.adsSettings!.paymentMethods?.firstWhere((element) => element.bankForm?.title == payment);
      if (object != null) payList.add(object);
    }
    _controller.currentAds?.paymentMethodList = payList;

    List<String> cList = [];
    if (_controller.selectedCountryList.isValid) {
      for (final country in _controller.selectedCountryList) {
        final key = _controller.adsSettings!.country?.firstWhere((element) => element.value == country).key;
        if (key.isValid) cList.add(key!);
      }
    } else {
      cList = _controller.adsSettings?.country?.map((e) => e.key ?? "").toList() ?? [];
    }
    _controller.currentAds?.country = cList.toSet().join(",");

    hideKeyboard();
    _controller.saveOrEditAds(context);
  }
}
