import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/fiat_deposit.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_up/sign_up_screen.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';

class TwoTextSpaceFixed extends StatelessWidget {
  const TwoTextSpaceFixed(this.text, this.subText,
      {super.key,
      this.subColor,
      this.color,
      this.maxLine,
      this.subMaxLine,
      this.fontSize,
      this.flex,
      this.subTextAlign,
      this.tFontSize,
      this.vFontSize,
      this.onSubTap});

  final String text;
  final String subText;
  final Color? subColor;
  final Color? color;
  final int? maxLine;
  final int? subMaxLine;
  final double? fontSize;
  final double? tFontSize;
  final double? vFontSize;
  final int? flex;
  final TextAlign? subTextAlign;
  final VoidCallback? onSubTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            flex: flex ?? 3,
            child: TextRobotoAutoBold(text,
                fontSize: tFontSize ?? fontSize,
                color: color ?? context.theme.primaryColorLight,
                textAlign: TextAlign.start,
                maxLines: maxLine ?? 1)),
        Expanded(
            flex: 6,
            child: InkWell(
              onTap: onSubTap,
              child: TextRobotoAutoBold(subText,
                  fontSize: vFontSize ?? fontSize,
                  color: subColor,
                  textAlign: subTextAlign ?? TextAlign.end,
                  minFontSize: Dimens.fontSizeMidExtra,
                  maxLines: subMaxLine ?? 1),
            )),
      ],
    );
  }
}

class TwoTextFixed extends StatelessWidget {
  const TwoTextFixed(this.text, this.subText,
      {super.key,
        this.subColor,
        this.color,
        this.maxLine,
        this.subMaxLine,
        this.fontSize,
        this.flex,
        this.subTextAlign,
        this.tFontSize,
        this.vFontSize,
        this.onSubTap});

  final String text;
  final String subText;
  final Color? subColor;
  final Color? color;
  final int? maxLine;
  final int? subMaxLine;
  final double? fontSize;
  final double? tFontSize;
  final double? vFontSize;
  final int? flex;
  final TextAlign? subTextAlign;
  final VoidCallback? onSubTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            flex: flex ?? 3,
            child: TextRobotoAutoNormal(text,
                fontSize: tFontSize ?? fontSize,
                color: color ?? context.theme.primaryColorLight,
                textAlign: TextAlign.start,
                maxLines: maxLine ?? 1)),
        Expanded(
            flex: 6,
            child: InkWell(
              onTap: onSubTap,
              child: TextRobotoAutoBold(subText,
                  fontSize: vFontSize ?? fontSize,
                  color: subColor,
                  textAlign: subTextAlign ?? TextAlign.end,
                  minFontSize: Dimens.fontSizeMidExtra,
                  maxLines: subMaxLine ?? 1),
            )),
      ],
    );
  }
}

Widget twoTextSpaceFixed(String text, String subText,
    {Color? subColor, Color? color, int maxLine = 1, int subMaxLine = 1, double? fontSize, int? flex}) {
  fontSize = fontSize ?? Dimens.fontSizeMid;
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: flex ?? 3, child: TextRobotoAutoBold(text, fontSize: fontSize, color: color, textAlign: TextAlign.start, maxLines: maxLine)),
      Expanded(
          flex: 6,
          child: TextRobotoAutoBold(subText,
              fontSize: fontSize, color: subColor, textAlign: TextAlign.end, minFontSize: Dimens.fontSizeMidExtra, maxLines: subMaxLine)),
    ],
  );
}

Widget signInNeedView({bool isDrawer = false}) {
  final logoSize = isDrawer ? Dimens.iconSizeLargeExtra : Dimens.iconSizeLogo;
  return Padding(
    padding: const EdgeInsets.all(Dimens.paddingMid),
    child: SizedBox(
      height: isDrawer ? 210 : getContentHeight(withBottomNav: true, withToolbar: true) - 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppLogo(size: logoSize),
          vSpacer20(),
          TextRobotoAutoBold("Sign In to unlock".tr, maxLines: 3, textAlign: TextAlign.center),
          isDrawer ? vSpacer10() : vSpacer20(),
          isDrawer
              ? buttonText("Sign In".tr, onPress: () => Get.offAll(() => const SignInPage()), visualDensity: VisualDensity.compact)
              : buttonRoundedMain(text: "Sign In".tr, onPress: () => Get.offAll(() => const SignInPage()), buttonHeight: Dimens.btnHeightMid),
          isDrawer ? vSpacer10() : vSpacer20(),
          textSpanWithAction('Do not have account'.tr, "Sign Up".tr, onTap: () => Get.offAll(() => const SignUpScreen())),
        ],
      ),
    ),
  );
}

Widget listHeaderView(String cFirst, String cSecond, String cThird) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      TextRobotoAutoNormal(cFirst),
      TextRobotoAutoNormal(cSecond, textAlign: TextAlign.center),
      TextRobotoAutoNormal(cThird, textAlign: TextAlign.end),
    ],
  );
}

Widget twoTextView(String text, String subText, {Color? subColor}) {
  return Row(
    children: [
      TextRobotoAutoNormal(text, fontSize: Dimens.fontSizeSmall),
      Expanded(child: TextRobotoAutoBold(subText, color: subColor, maxLines: 1)),
    ],
  );
}

Widget twoTextSpace(String text, String subText, {Color? subColor, Color? color}) {
  color = color ?? Get.theme.primaryColorLight;
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      TextRobotoAutoBold(text, fontSize: Dimens.fontSizeMid, color: color, textAlign: TextAlign.start),
      TextRobotoAutoBold(subText, fontSize: Dimens.fontSizeMid, color: subColor, textAlign: TextAlign.end),
    ],
  );
}

class DropDownViewWallets extends StatelessWidget {
  const DropDownViewWallets(this.wallets, this.selectedWallet, {super.key, this.onChange});

  final List<Wallet> wallets;
  final Wallet selectedWallet;
  final Function(Wallet value)? onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5, bottom: 5),
      height: 50,
      alignment: Alignment.center,
      child: DropdownButton<Wallet>(
        value: selectedWallet.coinType.isValid ? selectedWallet : null,
        hint: Text("Select".tr, style: context.textTheme.displaySmall),
        icon: Icon(Icons.keyboard_arrow_down_outlined, color: context.theme.primaryColor),
        elevation: 10,
        dropdownColor: context.theme.dialogTheme.backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        underline: Container(height: 0, color: Colors.transparent),
        menuMaxHeight: context.width,
        onChanged: onChange == null ? null : (value) => onChange!(value!),
        items: wallets.map<DropdownMenuItem<Wallet>>((Wallet value) {
          return DropdownMenuItem<Wallet>(
            value: value,
            child: Text(value.coinType ?? "", style: context.textTheme.labelMedium),
          );
        }).toList(),
      ),
    );
  }
}

SizedBox walletsSuffixView(List<Wallet> walletList, Wallet selected, {Function(Wallet value)? onChange, double? width}) {
  return SizedBox(
    width: width ?? Dimens.suffixWide,
    child: Row(
      children: [
        dividerVertical(indent: Dimens.paddingMid),
        hSpacer5(),
        Expanded(child: DropDownViewWallets(walletList, selected, onChange: onChange))
      ],
    ),
  );
}

Widget coinDetailsItemView(String? title, String? subtitle,
    {bool isSwap = false, Color? subColor, String? fromKey, CrossAxisAlignment? crossAlignment}) {
  subColor = subColor ?? Get.theme.primaryColor;
  final mainColor = fromKey.isValid ? (fromKey == FromKey.up ? gBuyColor : gSellColor) : Get.theme.primaryColorLight;
  return Column(
    crossAxisAlignment: crossAlignment ?? CrossAxisAlignment.center,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: TextRobotoAutoBold(title ?? "", color: mainColor, fontSize: isSwap ? Dimens.fontSizeMid : Dimens.fontSizeSmall, maxLines: 1)),
          if (fromKey.isValid)
            Icon(fromKey == FromKey.up ? Icons.arrow_upward : Icons.arrow_downward, color: mainColor, size: Dimens.iconSizeMinExtra)
        ],
      ),
      TextRobotoAutoBold((subtitle ?? 0).toString(), color: subColor, fontSize: isSwap ? Dimens.fontSizeSmall : Dimens.fontSizeMid),
    ],
  );
}

Widget currencyView(BuildContext context, FiatCurrency selectedCurrency, List<FiatCurrency> cList, Function(FiatCurrency) onChange) {
  final text = selectedCurrency.code.isValid ? selectedCurrency.name! : "Select".tr;
  return InkWell(
    onTap: () => chooseCurrencyModal(context, cList, onChange),
    child: SizedBox(
      width: Dimens.suffixWide,
      child: Row(
        children: [
          dividerVertical(indent: Dimens.paddingMid),
          vSpacer5(),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                    child: AutoSizeText(text,
                        style: Get.textTheme.displaySmall?.copyWith(color: Get.theme.primaryColor), maxLines: 2, textAlign: TextAlign.center)),
                Icon(Icons.keyboard_arrow_down, size: Dimens.iconSizeMin, color: Get.theme.primaryColor),
                hSpacer10()
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void chooseCurrencyModal(BuildContext context, List<FiatCurrency> cList, Function(FiatCurrency) onChange) {
  showBottomSheetFullScreen(
      context,
      Expanded(
        child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Dimens.paddingMid),
            children: List.generate(cList.length, (index) {
              final currency = cList[index];
              return InkWell(
                onTap: () {
                  onChange(currency);
                  Get.back();
                },
                child: Padding(
                  padding: const EdgeInsets.all(Dimens.paddingMid),
                  child: TextRobotoAutoBold(currency.name ?? ""),
                ),
              );
            })),
      ),
      title: "Select currency".tr,
      isScrollControlled: false);
}

class TwoTextFixedView extends StatelessWidget {
  const TwoTextFixedView(this.text, this.subText, {super.key, this.flex, this.onSubTap});
  final String text;
  final String subText;
  final  int? flex;
  final VoidCallback? onSubTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: flex ?? 3, child: TextRobotoAutoNormal(text, textAlign: TextAlign.start, maxLines: 1, fontWeight: FontWeight.bold)),
        Expanded(flex: 6, child: InkWell( onTap: onSubTap,
            child: TextRobotoAutoBold(subText, textAlign: TextAlign.end,  maxLines: 1))),
      ],
    );
  }
}

