import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'dimens.dart';
import 'dart:ui';

Container textFieldWithSuffixIcon({
  Widget? countryPick,
  TextEditingController? controller,
  String? hint,
  String? text,
  String? labelText,
  TextInputType? type,
  String? iconPath,
  VoidCallback? iconAction,
  bool isObscure = false,
  bool isEnable = true,
  int maxLines = 1,
  double? width,
  double height = 50,
  double? borderRadius = 7,
  FocusNode? focusNode,
  EdgeInsets? contentPadding,
  Function(String)? onTextChange,
}) {
  if (controller != null && text != null && text.isNotEmpty) {
    controller.text = text;
  }
  return Container(
    height: height,
    width: width,
    padding: const EdgeInsets.only(left: 0, right: 0, top: 0),
    child: TextField(
      focusNode: focusNode,
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      cursorColor: Get.theme.primaryColor,
      obscureText: isObscure,
      enabled: isEnable,
      style: Get.theme.textTheme.displaySmall?.copyWith(
        color: Get.theme.primaryColor,
      ),
      onChanged: (value) {
        if (onTextChange != null) onTextChange(value);
      },
      decoration: InputDecoration(
        prefixIcon: countryPick,
        labelText: labelText,
        labelStyle: Get.theme.textTheme.displaySmall?.copyWith(
          color: Get.theme.primaryColor,
        ),
        filled: false,
        isDense: true,
        hintText: hint,
        contentPadding: contentPadding,
        hintStyle: Get.theme.textTheme.displaySmall,
        enabledBorder: _textFieldBorder(borderRadius: borderRadius!),
        disabledBorder: _textFieldBorder(borderRadius: borderRadius),
        focusedBorder: _textFieldBorder(
          isFocus: true,
          borderRadius: borderRadius,
        ),
        suffixIcon: iconPath == null
            ? null
            : _buildTextFieldIcon(
                iconPath: iconPath,
                action: iconAction,
                color: Get.theme.primaryColorLight,
                size: Dimens.iconSizeMid,
              ),
      ),
    ),
  );
}

Container textFieldWithWidget({
  TextEditingController? controller,
  String? hint,
  String? text,
  String? labelText,
  Widget? suffixWidget,
  Widget? prefixWidget,
  TextInputType? type,
  bool isObscure = false,
  bool isEnable = true,
  bool readOnly = false,
  int maxLines = 1,
  double? width,
  double? height,
  double? borderRadius = 7,
  TextAlign textAlign = TextAlign.start,
  Function(String)? onTextChange,
}) {
  if (controller != null && text != null && text.isNotEmpty) {
    controller.text = text;
  }
  return Container(
    height: height ?? 50,
    width: width,
    padding: const EdgeInsets.only(left: 0, right: 0, top: 0),
    child: TextField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      cursorColor: Get.theme.primaryColor,
      obscureText: isObscure,
      enabled: isEnable,
      readOnly: readOnly,
      textAlign: textAlign,
      style: Get.theme.textTheme.displaySmall?.copyWith(
        color: Get.theme.primaryColor,
      ),
      onChanged: (value) {
        if (onTextChange != null) onTextChange(value);
      },
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: Get.theme.textTheme.displaySmall?.copyWith(
          color: Get.theme.primaryColor,
        ),
        hintStyle: Get.theme.textTheme.displaySmall,
        filled: false,
        isDense: true,
        hintText: hint,
        enabledBorder: _textFieldBorder(borderRadius: borderRadius!),
        disabledBorder: _textFieldBorder(borderRadius: borderRadius),
        focusedBorder: _textFieldBorder(
          isFocus: true,
          borderRadius: borderRadius,
        ),
        prefixIcon: prefixWidget,
        suffixIcon: suffixWidget,
      ),
    ),
  );
}

// Basic Search Bar with Interactive Icon Color
Container textFieldSearch({
  TextEditingController? controller,
  double? borderRadius = 7,
  Function()? onSearch,
  Function(String)? onTextChange,
  double? height,
  double? width,
  double? margin,
}) {
  height = 30;

  return Container(
    margin: EdgeInsets.only(left: 10, right: 10),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            cursorColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              isDense: true,
              hintText: "Search".tr,
              hintStyle: const TextStyle(color: Colors.white54, fontSize: 15),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              border: InputBorder.none,
              suffixIcon: IconButton(
                padding: const EdgeInsets.only(right: 2),
                icon: Image.asset(
                  'assets/icons/search.png',
                  height: 15,
                  width: 15,
                  color: Colors.white54,
                ),
                onPressed: () {
                  if (onSearch != null) onSearch();
                },
              ),
            ),
            onSubmitted: (value) {
              if (onSearch != null) onSearch();
            },
            onChanged: (value) {
              if (onTextChange != null) onTextChange(value);
            },
          ),
        ),
      ),
    ),
  );
}

SizedBox textFieldWithPrefixSuffixText({
  TextEditingController? controller,
  String? text,
  String? hint,
  String? prefixText,
  String? suffixText,
  Color? suffixColor,
  bool isEnable = true,
  TextAlign textAlign = TextAlign.end,
  double? width,
  Function(String)? onTextChange,
}) {
  if (controller != null && text != null) controller.text = text;
  return SizedBox(
    height: 50,
    width: width,
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      cursorColor: Get.theme.primaryColor,
      enabled: isEnable,
      style: Get.theme.textTheme.displaySmall?.copyWith(
        color: Get.theme.primaryColor,
      ),
      textAlign: textAlign,
      textAlignVertical: TextAlignVertical.center,
      onChanged: (value) {
        if (onTextChange != null) onTextChange(value);
      },
      decoration: InputDecoration(
        prefixIcon: prefixText.isValid
            ? textFieldTextWidget(prefixText!)
            : hSpacer10(),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 10,
          minHeight: 50,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 10,
          minHeight: 50,
        ),
        filled: false,
        isDense: true,
        hintText: hint,
        contentPadding: EdgeInsets.zero,
        enabledBorder: _textFieldBorder(borderRadius: 7),
        disabledBorder: _textFieldBorder(borderRadius: 7),
        focusedBorder: _textFieldBorder(isFocus: true, borderRadius: 7),
        suffixIcon: suffixText.isValid
            ? textFieldTextWidget(
                suffixText!,
                color: suffixColor ?? Get.theme.focusColor,
              )
            : hSpacer10(),
      ),
    ),
  );
}

class TextFieldNoBorder extends StatelessWidget {
  const TextFieldNoBorder({
    super.key,
    this.controller,
    this.hint,
    this.inputType,
    this.onTextChange,
  });

  final TextEditingController? controller;
  final String? hint;
  final bool enabled = true;
  final TextInputType? inputType;
  final Function(String)? onTextChange;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: inputType,
      style: Get.theme.textTheme.displaySmall?.copyWith(
        color: Get.theme.primaryColor,
      ),
      maxLines: 1,
      cursorColor: Get.theme.primaryColor,
      onChanged: onTextChange,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        filled: false,
        hintText: hint,
        hintStyle: Get.theme.textTheme.displaySmall?.copyWith(
          fontSize: Dimens.fontSizeSmall,
        ),
      ),
    );
  }
}

OutlineInputBorder _textFieldBorder({
  bool isFocus = false,
  double borderRadius = 5,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
    borderSide: BorderSide(
      width: 1,
      color: isFocus ? Get.theme.focusColor : Get.theme.dividerColor,
    ),
  );
}

InkWell _buildTextFieldIcon({
  String? iconPath,
  VoidCallback? action,
  Color? color,
  double? size,
}) {
  return InkWell(
    onTap: action,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: SvgPicture.asset(
        iconPath!,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color, BlendMode.srcIn),
        height: size,
        width: size,
      ),
    ),
  );
}

OutlineInputBorder textFieldBorder({
  bool isFocus = false,
  double borderRadius = 5,
}) => _textFieldBorder(isFocus: isFocus, borderRadius: borderRadius);

FittedBox textFieldTextWidget(String text, {Color? color, double? hMargin}) =>
    FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          hMargin == null ? hSpacer10() : SizedBox(width: hMargin),
          Text(
            text,
            style: Get.textTheme.labelMedium?.copyWith(
              color: color ?? Get.theme.primaryColor,
            ),
          ),
          hMargin == null ? hSpacer10() : SizedBox(width: hMargin),
        ],
      ),
    );
