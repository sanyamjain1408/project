import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'button_util.dart';
import 'common_utils.dart';
import 'decorations.dart';
import 'dimens.dart';

void alertForAction(BuildContext context,
    {String? title, String? subTitle, int? maxLinesSub, String? buttonTitle, VoidCallback? onOkAction, Color? buttonColor}) {
  final view = Column(
    children: [
      vSpacer10(),
      if (title.isValid) TextRobotoAutoBold(title!, maxLines: 2, fontSize: Dimens.fontSizeLarge),
      vSpacer10(),
      if (subTitle.isValid) TextRobotoAutoBold(subTitle!, maxLines: maxLinesSub ?? 5),
      vSpacer15(),
      if (buttonTitle.isValid) buttonRoundedMain(text: buttonTitle, onPress: onOkAction, bgColor: buttonColor, buttonHeight: Dimens.btnHeightMid),
      vSpacer10(),
    ],
  );
  showModalSheetFullScreen(context, view);
}

void showModalSheetFullScreen(BuildContext context, Widget customView, {Function? onClose}) {
  showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return KeyboardDismissOnTap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  hSpacer10(),
                  buttonOnlyIcon(
                      iconPath: AssetConstants.icCloseBox,
                      size: Dimens.iconSizeMid,
                      iconColor: gIsDarkMode ? context.theme.primaryColor : context.theme.secondaryHeaderColor,
                      onPress: () {
                        Get.back();
                        if (onClose != null) onClose();
                      })
                ],
              ),
              Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMid, horizontal: Dimens.paddingMid),
                  margin: const EdgeInsets.symmetric(vertical: Dimens.paddingLarge, horizontal: Dimens.paddingLarge),
                  decoration: boxDecorationRoundBorder(color: Get.theme.secondaryHeaderColor),
                  child: customView)
            ],
          ),
        );
      });
}

void showBottomSheetFullScreen(BuildContext context, Widget customView, {Function? onClose, String? title, bool isScrollControlled = true}) {
  Get.bottomSheet(
      SafeArea(
        child: Container(
            alignment: Alignment.bottomCenter,
            height: getContentHeight(),
            decoration: boxDecorationTopRound(radius: Dimens.radiusCornerMid),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                vSpacer10(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buttonOnlyIcon(
                        iconPath: AssetConstants.icCross,
                        size: Dimens.iconSizeMinExtra,
                        onPress: () {
                          Get.back();
                          if (onClose != null) onClose();
                        }),
                    TextRobotoAutoBold(title ?? ""),
                    hSpacer20()
                  ],
                ),
                dividerHorizontal(),
                customView
              ],
            )),
      ),
      isScrollControlled: isScrollControlled,
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      isDismissible: true).whenComplete(() => onClose != null ? onClose() : {});
}

void showBottomSheetDynamic(BuildContext context, Widget customView, {Function? onClose, String? title, bool? isScrollControlled}) {
  showModalBottomSheet<dynamic>(
      isScrollControlled: isScrollControlled ?? true,
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea:true,
      builder: (BuildContext bc) {
        return Container(
            decoration: boxDecorationTopRoundBorder(radius: Dimens.radiusCornerMid),
            padding: const EdgeInsets.all(Dimens.paddingMid),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buttonOnlyIcon(
                        iconPath: AssetConstants.icCross,
                        size: Dimens.iconSizeMinExtra,
                        iconColor: context.theme.primaryColor,
                        onPress: () => Get.back()),
                    TextRobotoAutoBold(title ?? ""),
                  ],
                ),
                dividerHorizontal(),
                customView
              ],
            ));
      }).whenComplete(() => onClose != null ? onClose() : {});
}
