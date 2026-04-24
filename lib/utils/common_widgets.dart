import 'dart:async';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'decorations.dart';
import 'image_util.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.message,
    this.height,
    this.hideIcon,
    this.icon,
  });

  final String? message;
  final double? height;
  final bool? hideIcon;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      height: height,
      padding: const EdgeInsets.all(Dimens.paddingMid),
      child: Column(
        children: [
          hideIcon == true
              ? vSpacer0()
              : Icon(
                  icon ?? Icons.subtitles_off,
                  size: Dimens.iconSizeLarge,
                  color: context.theme.primaryColorLight,
                ),
          TextRobotoAutoNormal(message ?? "No data available".tr, maxLines: 3),
        ],
      ),
    );
  }
}

Widget showEmptyView({String? message, double height = 20}) {
  message = message ?? "No data available".tr;
  return SizedBox(
    width: Get.width,
    height: height,
    child: Center(
      child: TextRobotoAutoNormal(message, textAlign: TextAlign.center),
    ),
  );
}

Widget handleEmptyViewWithLoading(
  bool isLoading, {
  double height = 50,
  String? message,
}) {
  message = message ?? "No data available".tr;
  return Container(
    margin: const EdgeInsets.all(20),
    height: height,
    child: Center(
      child: isLoading
          ? CircularProgressIndicator(color: Color(0xFF00B052))
          : TextRobotoAutoNormal(
              message,
              maxLines: 3,
              textAlign: TextAlign.center,
            ),
    ),
  );
}

Widget showLoading() {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: CircularProgressIndicator(color: Get.theme.focusColor),
    ),
  );
}

Widget showLoadingSmall() {
  return Padding(
    padding: const EdgeInsets.all(5),
    child: Center(
      child: SizedBox(
        width: Dimens.btnHeightMin,
        height: Dimens.btnHeightMin,
        child: CircularProgressIndicator(color: Get.theme.focusColor),
      ),
    ),
  );
}

Widget dropDownListIndex(
  List<String> items,
  int selectedValue,
  String hint,
  Function(int index) onChange, {
  Color? bgColor,
  Color? borderColor,
  double? height,
  double? width,
  double? padding,
  double? radius,
  double? hintFontSize,
  double? fontSize,
  FocusNode? focusNode,
  double hMargin = 10,
  double vMargin = 5,
  bool isBordered = true,
  bool isEditable = true,
  bool isExpanded = true,
}) {
  bgColor = bgColor ?? Colors.transparent;
  borderColor = borderColor ?? Get.theme.dividerColor;
  padding = padding ?? Dimens.paddingMid;
  height = height ?? Dimens.btnHeightMain;

  return Container(
    margin: EdgeInsets.only(
      left: hMargin,
      top: vMargin,
      right: hMargin,
      bottom: vMargin,
    ),
    padding: EdgeInsets.only(left: padding, top: 0, right: padding, bottom: 0),
    height: 26,
    width: width,
    decoration: isBordered
        ? boxDecorationRoundBorder(
            color: Color(0xFF1A1A1A),
            borderColor: Colors.transparent,
            radius: radius ?? 10,
            width: 1,
          )
        : null,

    child: // DropdownButton ki jagah ye use karo
    PopupMenuButton<String>(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) => onChange(items.indexOf(value)),
      itemBuilder: (context) => items.map((item) {
        return PopupMenuItem<String>(
          value: item,
          height: 50,
          
          child: Text(
            item,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSans',
            ),
          ),
        );
      }).toList(),
      child: DropdownButtonHideUnderline(
  child: DropdownButton<String>(
    focusNode: focusNode,
    isExpanded: true, // ← important
    dropdownColor: const Color(0xFF1A1A1A),
    borderRadius: BorderRadius.circular(10),
    menuMaxHeight: 200,
    iconSize: 0, // ← default icon hide karo
    icon: const SizedBox.shrink(), // ← default icon hatao
    value: items.hasIndex(selectedValue) ? items[selectedValue] : null,
    underline: const SizedBox.shrink(),
    onChanged: isEditable ? (value) => onChange(items.indexOf(value!)) : null,

    // ── SELECTED ITEM — center text + right icon ──
    selectedItemBuilder: (context) {
      return items.map<Widget>((String value) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Center text
            Center(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'DMSans',
                ),
              ),
            ),
            // Right icon
            const Positioned(
              right: 0,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        );
      }).toList();
    },

    items: items.map<DropdownMenuItem<String>>((String value) {
      return DropdownMenuItem<String>(
        value: value,
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.33,
            fontWeight: FontWeight.w700,
            fontFamily: 'DMSans',
          ),
        ),
      );
    }).toList(),
  ),
),
    ),
  );
}

Widget qrView(String data, {Color backgroundColor = Colors.transparent}) {
  final width = Get.width / 2;
  return QrImageView(
    data: data,
    version: QrVersions.auto,
    size: width,
    backgroundColor: Colors.white,
    padding: const EdgeInsets.all(Dimens.paddingMid),
    errorStateBuilder: (c, err) =>
        SizedBox(width: width, height: width, child: const Icon(Icons.error)),
  );
}

Widget countryPickerView(
  BuildContext context,
  Country selectedCountry,
  Function(Country) onSelect, {
  bool? showPhoneCode,
}) {
  return InkWell(
    onTap: () {
      hideKeyboard(context: context);
      showCountryPicker(
        useSafeArea: true,
        context: context,
        showPhoneCode: showPhoneCode ?? false,
        onSelect: onSelect,
        countryListTheme: CountryListThemeData(
          backgroundColor: context.theme.secondaryHeaderColor,
          textStyle: context.theme.textTheme.labelMedium,
          inputDecoration: InputDecoration(
            labelStyle: Get.theme.textTheme.displaySmall,
            filled: false,
            isDense: true,
            hintText: "Search".tr,
            enabledBorder: textFieldBorder(borderRadius: 7),
            disabledBorder: textFieldBorder(borderRadius: 7),
            focusedBorder: textFieldBorder(isFocus: true, borderRadius: 7),
          ),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.only(left: Dimens.paddingMid),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedCountry.flagEmoji,
            style: const TextStyle(fontSize: Dimens.iconSizeMid),
          ),
          Icon(
            Icons.arrow_drop_down,
            size: Dimens.iconSizeMid,
            color: context.theme.primaryColor,
          ),
          hSpacer5(),
        ],
      ),
    ),
  );
}

Widget pinCodeView({TextEditingController? controller}) {
  final size = (Get.width - 100) / 6;
  StreamController<ErrorAnimationType> errorController =
      StreamController<ErrorAnimationType>();
  return Container(
    margin: const EdgeInsets.all(Dimens.paddingMid),
    child: PinCodeTextField(
      length: DefaultValue.codeLength,
      obscureText: false,
      animationType: AnimationType.slide,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(4),
        borderWidth: 0.5,
        fieldHeight: size,
        fieldWidth: size,
        activeColor: Get.theme.focusColor,
        activeFillColor: Colors.transparent,
        inactiveColor: Get.theme.primaryColorLight,
        inactiveFillColor: Colors.transparent,
        selectedColor: Get.theme.focusColor,
        selectedFillColor: Colors.transparent,
        errorBorderColor: Get.theme.colorScheme.error,
      ),
      cursorColor: Get.theme.focusColor,
      animationDuration: const Duration(milliseconds: 100),
      backgroundColor: Colors.transparent,
      enableActiveFill: true,
      hintCharacter: "#",
      textStyle: Get.textTheme.labelMedium?.copyWith(
        fontSize: Dimens.titleFontSizeSmall,
      ),
      errorAnimationController: errorController,
      controller: controller,
      onCompleted: (value) {},
      onChanged: (value) {},
      beforeTextPaste: (text) => false,
      appContext: Get.context!,
    ),
  );
}

Widget toggleSwitch({
  bool? selectedValue,
  Function(bool)? onChange,
  double height = 30,
  String activeText = "",
  String inactiveText = "",
  String text = "",
  TextStyle? textStyle,
  MainAxisAlignment? mainAxisAlignment,
}) {
  return Row(
    mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
    children: [
      if (text.isNotEmpty)
        Text(text, style: textStyle ?? Get.textTheme.displaySmall),
      const SizedBox(width: 5),
      FlutterSwitch(
        width: activeText.isValid ? 80 : height * 2,
        height: height,
        valueFontSize: height / 2,
        toggleSize: height - 10,
        value: selectedValue ?? false,
        toggleColor: Get.theme.primaryColor,
        activeToggleColor: Get.theme.focusColor,
        activeColor: Get.theme.primaryColorLight.withValues(alpha: 0.25),
        inactiveColor: Get.theme.primaryColorLight.withValues(alpha: 0.25),
        borderRadius: height / 2,
        activeTextColor: Get.theme.primaryColorLight,
        inactiveTextColor: Get.theme.primaryColor,
        switchBorder: Border.all(width: 2, color: Get.theme.primaryColor),
        padding: 3,
        showOnOff: true,
        activeText: activeText,
        inactiveText: inactiveText,
        onToggle: (val) {
          if (onChange != null) onChange(val);
        },
      ),
    ],
  );
}

class PopupMenuView extends StatelessWidget {
  const PopupMenuView(this.list, {super.key, this.child, this.onSelected});

  final List<String> list;
  final Widget? child;
  final Function(String)? onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: Get.theme.dialogTheme.backgroundColor,
      itemBuilder: (BuildContext context) =>
          List.generate(list.length, (index) {
            return PopupMenuItem<String>(
              value: list[index],
              height: 35,
              child: Text(list[index], style: Get.theme.textTheme.labelMedium),
            );
          }),
      child: child,
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size, this.radius});

  final double? size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final sizeL = size ?? context.width / 4;
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? Dimens.radiusCorner),
        child: showImageAsset(
          imagePath: 'assets/icons/blogo.png',
          height: sizeL,
          width: sizeL,
        ),
      ),
    );
  }
}

class CheckBoxView extends StatelessWidget {
  const CheckBoxView(
    this.currentValue,
    this.onChanged, {
    super.key,
    this.visualDensity,
    this.scale,
  });

  final bool currentValue;
  final Function(bool) onChanged;
  final VisualDensity? visualDensity;
  final double? scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale ?? 1.2,
      child: Checkbox(
        value: currentValue,
        visualDensity: visualDensity,
        activeColor: Theme.of(context).focusColor,
        onChanged: (value) => onChanged(value ?? false),
        side: BorderSide(width: 0.5, color: Theme.of(context).primaryColor),
      ),
    );
  }
}
