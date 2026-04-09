import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:textfield_tags/textfield_tags.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../../p2p_common_widgets.dart';
import 'p2p_create_ads_controller.dart';

class CreateAdsPageTwo extends StatefulWidget {
  const CreateAdsPageTwo({super.key});

  @override
  State<CreateAdsPageTwo> createState() => _CreateAdsPageTwoState();
}

class _CreateAdsPageTwoState extends State<CreateAdsPageTwo> {
  final _controller = Get.find<P2pCreateAdsController>();

  @override
  void initState() {
    super.initState();
    _controller.paymentTagController = StringTagController();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.paymentTagController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coinType = _controller.currentAds?.coinType ?? "";
    final currency = _controller.currentAds?.currency ?? "";

    return ListView(
      padding: const EdgeInsets.all(Dimens.paddingMid),
      children: [
        textFieldWithWidget(
            controller: _controller.amountEditController,
            hint: "Write Amount",
            labelText: "Total Amount".tr,
            type: TextInputType.number,
            borderRadius: Dimens.radiusCornerMid,
            suffixWidget: textFieldTextWidget(coinType)),
        Align(
          alignment: Alignment.centerRight,
          child: buttonTextBordered("Get all balance".tr, true, visualDensity: minimumVisualDensity, onPress: () {
            hideKeyboard();
            _controller.adsAvailableBalance();
          }),
        ),
        TextRobotoAutoBold("Order Limit".tr),
        vSpacer5(),
        Row(
          children: [
            Expanded(
              child: textFieldWithWidget(
                  controller: _controller.minEditController,
                  hint: "Minimum".tr,
                  type: TextInputType.number,
                  borderRadius: Dimens.radiusCornerMid,
                  suffixWidget: textFieldTextWidget(currency)),
            ),
            hSpacer10(),
            Expanded(
              child: textFieldWithWidget(
                  controller: _controller.maxEditController,
                  hint: "Maximum".tr,
                  type: TextInputType.number,
                  borderRadius: Dimens.radiusCornerMid,
                  suffixWidget: textFieldTextWidget(currency)),
            ),
          ],
        ),
        vSpacer20(),
        TextRobotoAutoBold("Payment Method".tr),
        vSpacer5(),
        TagSelectionViewString(
            tagList: _controller.getPaymentNameList(),
            tagController: _controller.paymentTagController,
            initialSelection: _controller.selectedPayMethods,
            onTagSelected: (list) => _controller.selectedPayMethods = list),
        vSpacer2(),
        TextRobotoAutoNormal("Select up to 5 payment methods".tr),
        vSpacer20(),
        TextRobotoAutoBold("Payment Time Limit".tr),
        Obx(() => dropDownListIndex(
            _controller.getTimeLimitList(),
            _controller.selectedTime.value,
            "",
            hMargin: 0,
            radius: Dimens.radiusCornerMid,
            (index) => _controller.selectedTime.value = index,
            isEditable: !_controller.isEdit)),
        vSpacer20(),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          buttonRoundedMain(
              text: "Previous".tr,
              bgColor: context.theme.dialogTheme.backgroundColor,
              onPress: () => _controller.pageController
                  .animateToPage(_controller.currentPageCreate - 1, duration: const Duration(milliseconds: 100), curve: Curves.linearToEaseOut),
              width: 120,
              buttonHeight: Dimens.btnHeightMid),
          hSpacer10(),
          buttonRoundedMain(text: "Next".tr, width: 120, buttonHeight: Dimens.btnHeightMid, onPress: () => _goToThirdPage()),
          hSpacer10()
        ]),
      ],
    );
  }

  void _goToThirdPage() {
    final tAmount = makeDouble(_controller.amountEditController.text.trim());
    if (tAmount <= 0) {
      showToast("amount_must_greater_than_0".tr);
      return;
    }
    final min = makeDouble(_controller.minEditController.text.trim());
    if (min <= 0) {
      showToast("min_order_must_greater_than_0".tr);
      return;
    }
    if (!_controller.selectedPayMethods.isValid) {
      showToast("Select_Payment_Method_message".tr);
      return;
    }
    _controller.currentAds?.amount = tAmount;
    _controller.currentAds?.minimumTradeSize = min;
    _controller.currentAds?.maximumTradeSize = makeDouble(_controller.maxEditController.text.trim());

    if (_controller.selectedPayMethods.isValid) {
      List<String> pList = [];
      for (final payment in _controller.selectedPayMethods) {
        // final uid = _controller.adsSettings!.paymentMethods?.firstWhere((element) => element.adminPaymentMethod?.name == payment).uid;
        final uid = _controller.adsSettings!.paymentMethods?.firstWhere((element) => element.bankForm?.title == payment).id.toString();
        if (uid.isValid) pList.add(uid!);
      }
      _controller.currentAds?.paymentMethod = pList.toSet().join(",");
    }

    if (_controller.selectedTime.value > 0) {
      _controller.currentAds?.paymentTimeId = _controller.adsSettings?.paymentTime?[_controller.selectedTime.value - 1].uid;
    }
    _controller.pageController
        .animateToPage(_controller.currentPageCreate + 1, duration: const Duration(milliseconds: 500), curve: Curves.easeInToLinear);
  }
}
