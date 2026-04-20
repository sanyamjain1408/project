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

const _bg = Color(0xFF121212);
const _cardBg = Color(0xFF1E1E1E);
const _green = Color(0xFFCCFF00);
const _white = Color(0xFFFFFFFF);
const _grey = Color(0xFF8A8A8A);
const _divider = Color(0xFF2A2A2A);
const _dmSans = 'DMSans';

const Color _primary = Color(0xFF111111);
const Color _secondary = Color(0xFF1A1A1A);


void alertForAction(
  BuildContext context, {
  String? title,
  String? subTitle,
  int? maxLinesSub,
  String? buttonTitle,
  VoidCallback? onOkAction,
  Color? buttonColor,
}) {
  final view = Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _primary, //  CARD BG COLOR
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        vSpacer10(),

        // 🔥 TITLE
        if (title != null)
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _white,
              fontSize: 18, //  custom size
              fontWeight: FontWeight.w700, //  custom weight
              fontFamily: _dmSans, //  custom font
            ),
          ),

        vSpacer10(),

        // 🔥 SUBTITLE
        if (subTitle != null)
          Text(
            subTitle,
            maxLines: maxLinesSub ?? 5,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              fontFamily: _dmSans,
            ),
          ),

        vSpacer15(),

        // 🔥 BUTTON
        if (buttonTitle != null)
          buttonRoundedMain(
            text: buttonTitle,
            onPress: onOkAction,
            bgColor: Colors.red, // BUTTON BG COLOR
            textColor: Colors.white,
            buttonHeight: Dimens.btnHeightMid,
          ),

        vSpacer10(),
      ],
    ),
  );

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent, // important
    builder: (_) => view,
  );
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
