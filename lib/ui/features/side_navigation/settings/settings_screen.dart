import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/colors.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/language_util.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/utils/theme.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'settings_controller.dart';
import 'settings_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final _controller = Get.put(SettingsController());
  RxBool isDark = false.obs;
  final _iconSize = Get.width / 4;

  @override
  void initState() {
    super.initState();
    isDark.value = ThemeService().loadThemeFromBox();
    _controller.selectedColorIndex.value = GetStorage().read(PreferenceKey.buySellColorIndex) ?? 0;
    _controller.selectedPreferenceIndex.value = GetStorage().read(PreferenceKey.buySellUpDown) ?? 0;
    _controller.setCurrentLanguage();
    _controller.selectedCurrency.value = -1;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getUserSetting());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(title: "Settings".tr),
      body: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(Dimens.paddingMid),
          children: [
            Obx(() => _controller.isLoading.value ? showLoadingSmall() : vSpacer0()),
            vSpacer10(),
            TextRobotoAutoNormal("Google Authentication Settings".tr, color: context.theme.primaryColor),
            vSpacer10(),
            Row(
              children: [
                showImageAsset(imagePath: AssetConstants.imgGoogleAuthenticator, width: _iconSize, height: _iconSize),
                hSpacer10(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextRobotoAutoBold("Authenticator app".tr),
                      vSpacer2(),
                      TextRobotoAutoNormal("Authenticator_app_use_message".tr, maxLines: 5),
                    ],
                  ),
                )
              ],
            ),
            vSpacer10(),
            _g2FAButtonView(),
            vSpacer20(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextRobotoAutoBold("Security".tr),
                      TextRobotoAutoNormal("Please turn on this option to enable two factor authentication".tr, maxLines: 3),
                    ],
                  ),
                ),
                Obx(() {
                  final g2FEnabled = _controller.userSettings.value.user?.g2FEnabled == 1;
                  return toggleSwitch(
                      selectedValue: g2FEnabled,
                      activeText: "On".tr,
                      inactiveText: "Off".tr,
                      onChange: (value) => _controller.enableDisable2FALogin());
                }),
              ],
            ),
            dividerHorizontal(height: Dimens.mainContendGapTop),
            TextRobotoAutoBold("Preference Settings".tr),
            vSpacer10(),
            TextRobotoAutoNormal("Currency".tr),
            Obx(() {
              final list = getCurrencyList(_controller.userSettings.value.fiatCurrency);
              return dropDownListIndex(list, _controller.selectedCurrency.value, "Select".tr, (value) {
                _controller.selectedCurrency.value = value;
                _controller.saveCurrency();
              }, hMargin: 0, bgColor: Colors.transparent);
            }),
            vSpacer15(),
            TextRobotoAutoNormal("Language".tr),
            Obx(() {
              final list = _controller.getLanguageList();
              return dropDownListIndex(list, _controller.selectedLanguage.value, "Select".tr, (value) {
                _controller.selectedLanguage.value = value;
                final language = getSettingsLocal()?.languageList?[_controller.selectedLanguage.value];
                LanguageUtil.updateLanguage(language?.key ?? "");
              }, hMargin: 0, bgColor: Colors.transparent);
            }),
            vSpacer20(),
            Obx(() => CupertinoFormRow(
                  padding: EdgeInsets.zero,
                  prefix: Row(
                    children: <Widget>[
                      Icon(isDark.value ? Icons.dark_mode : Icons.light_mode, size: Dimens.iconSizeMid),
                      hSpacer10(),
                      TextRobotoAutoBold(isDark.value ? 'Dark Mode'.tr : "Light Mode".tr)
                    ],
                  ),
                  child: CupertinoSwitch(
                    value: isDark.value,
                    activeTrackColor: context.theme.focusColor,
                    onChanged: (value) {
                      ThemeService().switchTheme();
                      isDark.value = value;
                    },
                  ),
                )),
            vSpacer20(),
            Obx(() => Column(children: [
                  ColorItemView(
                      "Style Settings".tr, bsColorList[_controller.selectedColorIndex.value], false, false, () => changeStyleSettings(context)),
                  vSpacer10(),
                  PreferenceItemView(
                      "Color Preference".tr, _controller.selectedPreferenceIndex.value, false, false, () => changePreferenceSettings(context)),
                ]))
          ],
        ),
      ),
    );
  }

  Widget _g2FAButtonView() {
    return Obx(() {
      final isValid = _controller.userSettings.value.user?.google2FaSecret.isValid ?? false;
      return Row(
        children: [
          SizedBox(
            width: context.width / 2,
            child: buttonText(isValid ? "Remove".tr : "Set Up".tr, bgColor: isValid ? Colors.red : null, onPress: () {
              if (isValid) {
                showBottomSheetFullScreen(context, _showGoogleAuthyRemoveView(),
                    title: "Remove".tr, onClose: () => _controller.codeEditController.text = "");
              } else {
                showBottomSheetFullScreen(context, _showGoogleAuthyAddView(),
                    title: "Set Up".tr, onClose: () => _controller.codeEditController.text = "");
              }
            }),
          ),
        ],
      );
    });
  }

  Expanded _showGoogleAuthyAddView() {
    return Expanded(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(Dimens.paddingMid),
        children: [
          Align(alignment: Alignment.center, child: qrView(_controller.userSettings.value.qrcode ?? '')),
          vSpacer20(),
          TextRobotoAutoNormal("Google Authenticator app info message".tr, maxLines: 5),
          vSpacer10(),
          textWithCopyButton(_controller.userSettings.value.google2faSecret ?? ""),
          dividerHorizontal(height: Dimens.mainContendGapTop, indent: context.width / 8),
          textFieldWithSuffixIcon(
              controller: _controller.codeEditController, hint: "Enter Your Code".tr, labelText: "Your Code".tr, type: TextInputType.number),
          vSpacer20(),
          buttonRoundedMain(text: "Verify".tr, onPress: () => _controller.setupGoogleSecret()),
          vSpacer20(),
        ],
      ),
    );
  }

  Expanded _showGoogleAuthyRemoveView() {
    return Expanded(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(Dimens.paddingMid),
        children: [
          showImageAsset(imagePath: AssetConstants.imgGoogleAuthenticator, width: _iconSize, height: _iconSize),
          vSpacer20(),
          TextRobotoAutoNormal("Google Authenticator remove message".tr, maxLines: 5),
          vSpacer20(),
          textFieldWithSuffixIcon(
              controller: _controller.codeEditController, hint: "Enter Your Code".tr, labelText: "Your Code".tr, type: TextInputType.number),
          vSpacer20(),
          buttonRoundedMain(text: "Remove".tr, onPress: () => _controller.setupGoogleSecret()),
          vSpacer20(),
        ],
      ),
    );
  }

  void changeStyleSettings(BuildContext context) {
    final titleList = ["Fresh".tr, "Traditional".tr, "Color Vision Deficiency".tr];
    final customView = Obx(() => Padding(
          padding: const EdgeInsets.all(Dimens.paddingMid),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              titleList.length,
              (index) => ColorItemView(titleList[index], bsColorList[index], _controller.selectedColorIndex.value == index, true, () async {
                _controller.selectedColorIndex.value = index;
                GetStorage().write(PreferenceKey.buySellColorIndex, index);
                initBuySellColor();
                await Get.forceAppUpdate();
              }),
            ),
          ),
        ));

    showBottomSheetDynamic(context, customView, title: "Style Settings".tr);
  }

  void changePreferenceSettings(BuildContext context) {
    final titleList = ["Green Up/Red Down".tr, "Green Down/Red up".tr];
    final customView = Obx(() => Padding(
        padding: const EdgeInsets.all(Dimens.paddingMid),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            titleList.length,
            (index) => PreferenceItemView(titleList[index], index, _controller.selectedPreferenceIndex.value == index, true, () async {
              _controller.selectedPreferenceIndex.value = index;
              GetStorage().write(PreferenceKey.buySellUpDown, index);
              initBuySellColor();
              await Get.forceAppUpdate();
            }),
          ),
        )));
    showBottomSheetDynamic(context, customView, title: "Color Preference".tr);
  }
}
