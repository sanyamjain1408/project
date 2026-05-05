import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'button_util.dart';
import 'dimens.dart';

const _green = Color(0xFFB5F000);

AppBar appBarBackWithActions({
  String? title,
  List<IconData>? actionIcons,
  Function(int)? onPress,
  double? fontSize,
  Color? bgColor,
}) {
  return AppBar(
    backgroundColor: bgColor ?? Get.theme.scaffoldBackgroundColor,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    leading: buttonOnlyIcon(
      onPress: () => Get.back(),
      iconPath: AssetConstants.icArrowLeft,
      size: 22,
      iconColor: Get.theme.primaryColor,
    ),
    title: TextRobotoAutoBold(
      title ?? "",
      fontSize: fontSize ?? Dimens.fontSizeLarge,
    ),
    actions: (actionIcons == null || actionIcons.isEmpty)
        ? [const SizedBox(width: 25)]
        : List.generate(actionIcons.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: buttonOnlyIcon(
                size: 25,
                onPress: () => onPress != null ? onPress(index) : null,
                iconData: actionIcons[index],
                iconColor: Get.theme.primaryColor,
              ),
            );
          }),
  );
}

Widget tabBarUnderline(
  List<String> titles,
  TabController? controller, {
  Function(int)? onTap,
  bool isScrollable = false,
  TabBarIndicatorSize indicatorSize = TabBarIndicatorSize.tab,
  Color? indicatorColor,
  double? fontSize,
  double? indicatorWeight,
  Decoration? indicator,
  EdgeInsetsGeometry? labelPadding,
}) {
  return Material(
    color: Colors.transparent,
    child: TabBar(
      controller: controller,
      isScrollable: isScrollable,
      tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.center,
      labelPadding: labelPadding ?? const EdgeInsets.symmetric(horizontal: 16),
      labelColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: fontSize ?? Dimens.fontSizeLarge,
        fontWeight: FontWeight.bold,
        fontFamily: "DMSans",
      ),
      unselectedLabelColor: Colors.grey,
      unselectedLabelStyle: TextStyle(
        fontSize: fontSize ?? Dimens.fontSizeLarge,
        fontWeight: FontWeight.normal,
        fontFamily: "DMSans",
      ),
      dividerColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      indicatorColor: Colors.transparent,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _green, width: 4.0),
        insets: EdgeInsets.zero,
      ),
      indicatorSize: indicatorSize,
      indicatorWeight: 0,
      tabs: List.generate(
        titles.length,
        (index) => Tab(child: Text(titles[index])),
      ),
      onTap: (index) => onTap == null ? () {} : onTap(index),
    ),
  );
}

UnderlineTabIndicator tabCustomIndicator(
  BuildContext context, {
  double? padding,
  double? radius,
}) => UnderlineTabIndicator(
  borderRadius: BorderRadius.horizontal(
    left: Radius.circular(radius ?? 5),
    right: Radius.circular(radius ?? 5),
  ),
  borderSide: BorderSide(width: 5.0, color: context.theme.focusColor),
  insets: EdgeInsets.symmetric(horizontal: padding ?? 50),
);

Widget tabBarText(
  List<String> titles,
  int selectedIndex,
  Function(int) onTap, {
  Color? selectedColor,
  double? fontSize,
}) {
  selectedColor = selectedColor ?? Colors.green;
  return Row(
    children: List.generate(
      titles.length,
      (index) => InkWell(
        onTap: () => onTap(index),
        child: Padding(
          padding: const EdgeInsets.all(Dimens.paddingMin),
          child: TextRobotoAutoBold(
            titles[index],
            fontSize: fontSize ?? Dimens.fontSizeMid,
            color: index == selectedIndex ? selectedColor : null,
          ),
        ),
      ),
    ),
  );
}

class TabBarPlain extends StatelessWidget {
  const TabBarPlain({
    super.key,
    required this.titles,
    required this.controller,
    this.fontSize,
    this.isScrollable = false,
    this.onTap,
    this.height,
  });

  final List<String> titles;
  final TabController controller;
  final Function(int)? onTap;
  final bool isScrollable;
  final double? fontSize;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: isScrollable,
      tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.center,
      labelColor: context.theme.primaryColor,
      labelStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
      unselectedLabelColor: context.theme.primaryColorLight,
      unselectedLabelStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w400),
      labelPadding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
      indicator: const BoxDecoration(),
      dividerHeight: 0,
      padding: EdgeInsets.zero,
      tabs: List.generate(
        titles.length,
        (index) => Tab(height: height, text: titles[index]),
      ),
      onTap: (index) => onTap == null ? null : onTap!(index),
    );
  }
}
