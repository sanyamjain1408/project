import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'dimens.dart';
import 'image_util.dart';

Widget buttonRoundedMain(
    {String? text,
    VoidCallback? onPress,
    Color? textColor,
    Color? bgColor,
    double buttonHeight = Dimens.btnHeightMain,
    double? width,
    double? borderRadius = Dimens.radiusCornerLarge}) {
  width = width ?? Get.width;
  bgColor = bgColor ?? Get.theme.focusColor;
  textColor = textColor ?? (bgColor == Get.theme.focusColor ? Colors.white : null);
  return Container(
      margin: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
      height: buttonHeight,
      width: width,
      child: ElevatedButton(
          style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all<Color>(bgColor),
              backgroundColor: WidgetStateProperty.all<Color>(bgColor),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(borderRadius!)), side: BorderSide(color: bgColor)))),
          onPressed: onPress,
          child: AutoSizeText(text ?? "", style: Get.theme.textTheme.labelMedium!.copyWith(color: textColor), maxLines: 1)));
}

Widget buttonRoundedWithIcon(
    {String? text,
    VoidCallback? onPress,
    IconData? iconData,
    String? iconPath,
    Color? textColor,
    Color? bgColor,
    Color? borderColor,
    VisualDensity? visualDensity,
    double? borderRadius = Dimens.radiusCorner,
    EdgeInsets? padding,
    TextDirection textDirection = TextDirection.rtl}) {
  bgColor = bgColor ?? Colors.grey;
  final iconColor = textColor ?? Get.theme.primaryColor;
  return Directionality(
    textDirection: textDirection,
    child: ElevatedButton.icon(
        icon: iconPath.isValid
            ? showImageAsset(imagePath: iconPath, color: iconColor, width: Dimens.iconSizeMin, height: Dimens.iconSizeMin)
            : Icon(iconData ?? Icons.arrow_back, color: iconColor),
        style: ButtonStyle(
            elevation: WidgetStateProperty.all<double>(0),
            visualDensity: visualDensity,
            padding: WidgetStateProperty.all<EdgeInsetsGeometry>(padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
            foregroundColor: WidgetStateProperty.all<Color>(bgColor),
            backgroundColor: WidgetStateProperty.all<Color>(bgColor),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(borderRadius!)), side: BorderSide(color: borderColor ?? bgColor)))),
        onPressed: onPress,
        label: AutoSizeText(text ?? "", style: Get.theme.textTheme.labelMedium!.copyWith(color: textColor))),
  );
}

Widget buttonText(String text,
    {VoidCallback? onPress, Color? textColor, Color? bgColor, Color? borderColor, VisualDensity? visualDensity, double? fontSize, double? radius}) {
  bgColor = bgColor ?? Get.theme.focusColor;
  fontSize = fontSize ?? (visualDensity == minimumVisualDensity ? Dimens.fontSizeMidExtra : null);
  textColor = textColor ?? (bgColor == Get.theme.focusColor ? Colors.white : null);
  return ElevatedButton(
      style: ButtonStyle(
          visualDensity: visualDensity,
          elevation: WidgetStateProperty.all<double>(0),
          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
          foregroundColor: WidgetStateProperty.all<Color>(bgColor),
          backgroundColor: WidgetStateProperty.all<Color>(bgColor),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(radius ?? Dimens.radiusCornerLarge)), side: BorderSide(color: borderColor ?? bgColor)))),
      onPressed: onPress,
      child: AutoSizeText(text, style: Get.theme.textTheme.labelMedium!.copyWith(fontSize: fontSize, color: textColor), minFontSize: 8, maxLines: 1));
}

Widget buttonTextBordered(String text, bool selected, {VoidCallback? onPress, Color? color, VisualDensity? visualDensity, double? radius}) {
  color = color ?? Get.theme.focusColor;
  return buttonText(text,
      visualDensity: visualDensity,
      bgColor: Colors.transparent,
      radius: radius,
      textColor: selected ? color : Get.theme.primaryColor.withValues(alpha:0.5),
      borderColor: selected ? color : Get.theme.primaryColor.withValues(alpha:0.1),
      onPress: onPress);
}

Widget buttonOnlyIcon(
    {VoidCallback? onPress, String? iconPath, IconData? iconData, double? size, Color? iconColor, double? padding, VisualDensity? visualDensity}) {
  size = size ?? Dimens.iconSizeMin;
  return IconButton(
    padding: padding == null ? EdgeInsets.zero : EdgeInsets.all(padding),
    visualDensity: visualDensity,
    onPressed: onPress,
    icon: iconPath.isValid
        ? iconPath!.contains(".svg")
            ? SvgPicture.asset(iconPath,
                width: size, height: size, colorFilter: iconColor == null ? null : ColorFilter.mode(iconColor, BlendMode.srcIn))
            : Image.asset(iconPath, width: size, height: size, color: iconColor)
        : iconData != null
            ? Icon(iconData, size: size, color: iconColor)
            : const SizedBox(),
  );
}
