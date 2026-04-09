import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_constants.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_dashboard.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_phase.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'ico_create_phase_controller.dart';

class IcoCreatePhaseScreen extends StatefulWidget {
  const IcoCreatePhaseScreen({super.key, this.prePhase, this.token});

  final IcoPhase? prePhase;
  final IcoToken? token;

  @override
  State<IcoCreatePhaseScreen> createState() => _IcoCreatePhaseScreenState();
}

class _IcoCreatePhaseScreenState extends State<IcoCreatePhaseScreen> {
  final _controller = Get.put(IcoCreatePhaseController());
  final priceEditController = TextEditingController();
  final minPriceEditController = TextEditingController();
  final maxPriceEditController = TextEditingController();
  final titleEditController = TextEditingController();
  final totalEditController = TextEditingController();
  final descriptionEditController = TextEditingController();
  final videoEditController = TextEditingController();
  final fbEditController = TextEditingController();
  final twitEditController = TextEditingController();
  final linkedEditController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    _setPreData();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getIcoCoinList(widget.prePhase?.coinCurrency));
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setPreData() {
    if (widget.prePhase != null) {
      priceEditController.text = (widget.prePhase?.coinPrice ?? "").toString();
      minPriceEditController.text = (widget.prePhase?.minimumPurchasePrice ?? "").toString();
      maxPriceEditController.text = (widget.prePhase?.maximumPurchasePrice ?? "").toString();
      titleEditController.text = widget.prePhase?.phaseTitle ?? "";
      totalEditController.text = (widget.prePhase?.totalTokenSupply ?? "").toString();
      descriptionEditController.text = widget.prePhase?.description ?? "";
      videoEditController.text = widget.prePhase?.videoLink ?? "";
      startDate = widget.prePhase?.startDate;
      endDate = widget.prePhase?.endDate;
      if (widget.prePhase?.socialLink.isValid ?? false) {
        final sMap = json.decode(widget.prePhase!.socialLink!) as Map<String, dynamic>? ?? {};
        if (sMap.containsKey(IcoSocialKeyString.facebook)) fbEditController.text = sMap[IcoSocialKeyString.facebook] ?? "";
        if (sMap.containsKey(IcoSocialKeyString.twitter)) twitEditController.text = sMap[IcoSocialKeyString.twitter] ?? "";
        if (sMap.containsKey(IcoSocialKeyString.linkedIn)) linkedEditController.text = sMap[IcoSocialKeyString.linkedIn] ?? "";
      }
    } else {
      _controller.selectedCurrency.value = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.prePhase == null ? "Create New Phase".tr : "Edit ICO Phase".tr;
    final btnTitle = widget.prePhase == null ? "Create Phase".tr : "Edit Phase".tr;
    final startDateStr = formatDate(startDate);
    final endDateStr = formatDate(endDate);
    final tHeight = isTextScaleGetterThanOne(context) ? (Dimens.btnHeightMain + 5) : Dimens.btnHeightMain;
    return Scaffold(
      appBar: appBarBackWithActions(title: title),
      body: SafeArea(
          child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(Dimens.paddingMid),
        children: [
          vSpacer5(),
          TextRobotoAutoBold("Currency".tr),
          Obx(() {
            final list = _controller.currencyList.map((e) => e.name ?? "").toList();
            return dropDownListIndex(list, _controller.selectedCurrency.value, "Select".tr, (index) => _controller.selectedCurrency.value = index,
                hMargin: 0, bgColor: Colors.transparent);
          }),
          vSpacer10(),
          textFieldWithSuffixIcon(
              controller: priceEditController,
              hint: "Enter Coin price".tr,
              labelText: "Coin price".tr,
              type: const TextInputType.numberWithOptions(decimal: true)),
          vSpacer10(),
          Row(children: [
            Expanded(
                child: textFieldWithSuffixIcon(
                    controller: minPriceEditController,
                    hint: "Enter min price".tr,
                    labelText: "Minimum Price".tr,
                    type: const TextInputType.numberWithOptions(decimal: true))),
            hSpacer5(),
            Expanded(
                child: textFieldWithSuffixIcon(
                    controller: maxPriceEditController,
                    hint: "Enter max price".tr,
                    type: const TextInputType.numberWithOptions(decimal: true),
                    labelText: "Maximum Price".tr)),
          ]),
          vSpacer10(),
          textFieldWithSuffixIcon(controller: titleEditController, hint: "Enter Phase Title".tr, labelText: "Phase Title".tr, height: tHeight),
          vSpacer10(),
          textFieldWithSuffixIcon(
              controller: totalEditController,
              hint: "Enter Total Supply".tr,
              labelText: "Total Token Supply".tr,
              type: const TextInputType.numberWithOptions(decimal: true)),
          vSpacer10(),
          Row(children: [
            Expanded(
                child: InkWell(
                    onTap: () => _openDatePicker(true),
                    child:
                        textFieldWithSuffixIcon(controller: TextEditingController(text: startDateStr), labelText: "Start Date".tr, isEnable: false))),
            hSpacer5(),
            Expanded(
                child: InkWell(
                    onTap: () => _openDatePicker(false),
                    child: textFieldWithSuffixIcon(controller: TextEditingController(text: endDateStr), labelText: "End Date".tr, isEnable: false))),
          ]),
          vSpacer10(),
          textFieldWithSuffixIcon(
              controller: descriptionEditController,
              hint: "Enter Description".tr,
              labelText: "Description".tr,
              maxLines: 3,
              height: isTextScaleGetterThanOne(context) ? 100 : 80),
          vSpacer10(),
          textFieldWithSuffixIcon(controller: videoEditController, hint: "Enter Video Link".tr, labelText: "Video Link".tr, height: tHeight),
          vSpacer10(),
          textFieldWithSuffixIcon(controller: fbEditController, hint: "Enter Facebook Link".tr, labelText: "Facebook Link".tr, height: tHeight),
          vSpacer10(),
          textFieldWithSuffixIcon(controller: twitEditController, hint: "Enter Twitter Link".tr, labelText: "Twitter Link".tr, height: tHeight),
          vSpacer10(),
          textFieldWithSuffixIcon(controller: linkedEditController, hint: "Enter Linkedin Link".tr, labelText: "Linkedin Link".tr, height: tHeight),
          vSpacer10(),
          if (widget.prePhase?.image.isValid ?? false)
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextRobotoAutoBold("Selected Image".tr),
              showImageNetwork(imagePath: widget.prePhase?.image, height: Dimens.iconSizeLogo, width: Dimens.iconSizeLogo)
            ]),
          _documentView(),
          vSpacer10(),
          buttonRoundedMain(text: btnTitle, onPress: () => _checkAndCreateToken()),
          vSpacer10(),
        ],
      )),
    );
  }

  Row _documentView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buttonText("Select Image".tr,
            visualDensity: VisualDensity.compact,
            onPress: () => showImageChooser(context, (chooseFile, isGallery) => _controller.selectedFile.value = chooseFile, isCrop: false)),
        Obx(() {
          final text = _controller.selectedFile.value.path.isEmpty ? "No image selected".tr : _controller.selectedFile.value.name;
          return Expanded(child: TextRobotoAutoNormal(text, maxLines: 2, textAlign: TextAlign.center));
        })
      ],
    );
  }

  Future<void> _openDatePicker(bool isStart) async {
    hideKeyboard(context: context);
    final initialDate = isStart ? startDate : endDate;
    openDatePicker(context, initialDate: initialDate, onPicked: (picked) {
      setState(() {
        isStart ? startDate = picked : endDate = picked;
      });
    });
  }

  void _checkAndCreateToken() {
    final phase = widget.prePhase ?? IcoPhase();
    if (_controller.selectedCurrency.value == -1) {
      showToast("select your currency");
      return;
    }
    final currency = _controller.currencyList[_controller.selectedCurrency.value];
    phase.coinCurrency = currency.coinType;

    phase.coinPrice = makeDouble(priceEditController.text.trim());
    if (phase.coinPrice! <= 0) {
      showToast("price_must_greater_than_0".tr);
      return;
    }
    phase.minimumPurchasePrice = makeDouble(minPriceEditController.text.trim());
    if (phase.minimumPurchasePrice! <= 0) {
      showToast("min_price_must_greater_than_0".tr);
      return;
    }

    phase.maximumPurchasePrice = makeDouble(maxPriceEditController.text.trim());
    if (phase.maximumPurchasePrice! <= 0) {
      showToast("max_price_must_greater_than_0".tr);
      return;
    }

    phase.phaseTitle = titleEditController.text.trim();
    if (!phase.phaseTitle.isValid) {
      showToast("Enter_phase_title");
      return;
    }
    phase.totalTokenSupply = makeDouble(totalEditController.text.trim());
    if (phase.totalTokenSupply! <= 0) {
      showToast("total_supply_must_greater_than_0".tr);
      return;
    }
    phase.startDate = startDate;
    if (phase.startDate == null) {
      showToast("Select_the_start_date");
      return;
    }
    phase.endDate = endDate;
    if (phase.endDate == null) {
      showToast("Select_the_end_date");
      return;
    }
    phase.description = descriptionEditController.text.trim();
    if (!phase.description.isValid) {
      showToast("Enter_the_description");
      return;
    }
    if (!phase.image.isValid && !_controller.selectedFile.value.path.isValid) {
      showToast("Select_the_document");
      return;
    }
    if (widget.token != null) phase.icoTokenId = widget.token?.id;
    phase.videoLink = videoEditController.text.trim();
    final Map<int, String> socialMap = {};
    final fbL = fbEditController.text.trim();
    if (fbL.isValid) socialMap[IcoSocialKeyInt.facebook] = fbL;
    final twitL = twitEditController.text.trim();
    if (twitL.isValid) socialMap[IcoSocialKeyInt.twitter] = twitL;
    final linkedL = linkedEditController.text.trim();
    if (linkedL.isValid) socialMap[IcoSocialKeyInt.linkedIn] = linkedL;

    hideKeyboard(context: context);
    _controller.icoCreateUpdateTokenPhase(phase, _controller.selectedFile.value, socialMap);
  }
}
