import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'common_utils.dart';
import 'decorations.dart';

class TextRobotoAutoBold extends StatelessWidget {
  const TextRobotoAutoBold(this.text, {super.key, this.maxLines, this.color, this.fontSize, this.textAlign, this.minFontSize});

  final String text;
  final int? maxLines;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;
  final double? minFontSize;

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(text,
        maxLines: maxLines ?? 2,
        minFontSize: minFontSize ?? 10,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign ?? TextAlign.start,
        style: Get.theme.textTheme.labelMedium!.copyWith(color: color, fontSize: fontSize));
  }
}

class TextRobotoAutoNormal extends StatelessWidget {
  const TextRobotoAutoNormal(this.text, {super.key, this.maxLines, this.color, this.fontSize, this.textAlign, this.decoration, this.fontWeight});

  final String text;
  final int? maxLines;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;
  final TextDecoration? decoration;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(text,
        maxLines: maxLines ?? 1,
        minFontSize: 10,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign ?? TextAlign.start,
        style: Get.theme.textTheme.displaySmall!.copyWith(color: color, fontSize: fontSize, decoration: decoration, fontWeight: fontWeight));
  }
}

Widget textSpanWithAction(String main, String clickAble,
    {int maxLines = 1,
    double? fontSize,
    TextAlign textAlign = TextAlign.center,
    FontWeight fontWeight = FontWeight.bold,
    Color? mainColor,
    VoidCallback? onTap,
    Color? subColor}) {
  mainColor = mainColor ?? Get.theme.primaryColorLight;
  subColor = subColor ?? Get.theme.focusColor;
  return AutoSizeText.rich(
    TextSpan(
      text: main,
      style: Get.theme.textTheme.displaySmall!.copyWith(fontSize: fontSize, fontWeight: fontWeight, color: mainColor),
      children: <TextSpan>[
        TextSpan(
            text: " $clickAble",
            style: Get.theme.textTheme.displaySmall!.copyWith(fontSize: fontSize, color: subColor, fontWeight: fontWeight),
            recognizer: TapGestureRecognizer()..onTap = onTap),
      ],
    ),
    maxLines: maxLines,
    textAlign: textAlign,
  );
}

Widget textWithCopyButton(String text) {
  return Container(
      padding: const EdgeInsets.all(5),
      decoration: boxDecorationRoundCorner(color: Get.theme.secondaryHeaderColor),
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: Align(
                  alignment: Alignment.center,
                  child: AutoSizeText(text, style: Get.theme.textTheme.displaySmall?.copyWith(color: Get.theme.primaryColor), maxLines: 2))),
          buttonOnlyIcon(iconPath: AssetConstants.icCopy, iconColor: Get.theme.focusColor, onPress: () => copyToClipboard(text))
        ],
      ));
}

Row textWithCopyView(String text, {MainAxisAlignment? mainAxisAlign}) {
  return Row(
    mainAxisAlignment: mainAxisAlign ?? MainAxisAlignment.start,
    children: [
      TextRobotoAutoBold(text, maxLines: 2),
      buttonOnlyIcon(
          iconPath: AssetConstants.icCopy, visualDensity: minimumVisualDensity, iconColor: Get.theme.focusColor, onPress: () => copyToClipboard(text))
    ],
  );
}

Widget textWithBackground(String text, {double? width, double? height, int maxLines = 4, Color bgColor = Colors.green, Color? textColor, TextAlign? textAlign}) {
  return Container(
    padding: const EdgeInsets.all(10),
    width: width ?? Get.width,
    height: height,
    decoration: boxDecorationRoundCorner(color: bgColor),
    child: TextRobotoAutoBold(text, color: textColor, maxLines: maxLines, textAlign: textAlign),
  );
}

// Here it is!
Size getTextSize(String text, TextStyle style, {int? maxLine, double? width, TextScaler? scale}) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLine ?? 100,
      textDirection: TextDirection.ltr,
      textScaler: scale ?? const TextScaler.linear(1))
    ..layout(minWidth: 0, maxWidth: width ?? Get.width);
  return textPainter.size;
}
