import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/currency.dart';
import '../../data/models/wallet.dart';
import '../../utils/decorations.dart';
import '../../utils/dimens.dart';
import '../../utils/text_util.dart';
import 'currency_widgets.dart';

class DropdownViewCurrency extends StatelessWidget {
  const DropdownViewCurrency({super.key, required this.items, this.selectedItem, this.enable = true, this.onSelect});

  final List<Currency> items;
  final Currency? selectedItem;
  final Function(Currency)? onSelect;
  final bool enable;

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<Currency>(
      enabled: enable,
      items:(filter, loadProps) => items,
      selectedItem: selectedItem,
      dropdownBuilder: (context, selectedItem) {
        return selectedItem?.coinType != null
            ? CurrencyItemView(selectedItem!)
            : Padding(padding: const EdgeInsets.only(left: 10), child: TextRobotoAutoNormal("Select Currency".tr));
      },
      onChanged: (value) => (value != null && onSelect != null) ? onSelect!(value) : null,
      popupProps: PopupProps.menu(
        showSelectedItems: true,
        showSearchBox: true,
        menuProps: MenuProps(
          backgroundColor: Theme.of(context).secondaryHeaderColor,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        searchFieldProps: TextFieldProps(
          style: Theme.of(context).textTheme.labelMedium,
          decoration: InputDecoration(
            isDense: true,
            hintText: "Search".tr,
            hintStyle: Theme.of(context).textTheme.displaySmall,
            contentPadding: const EdgeInsets.all(Dimens.paddingMid),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(Dimens.radiusCornerMid)),
              borderSide: BorderSide(width: 1, color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(Dimens.radiusCornerMid)),
              borderSide: BorderSide(width: 1, color: Theme.of(context).focusColor),
            ),
          ),
        ),
        itemBuilder: (context, item, isDisable, selected) => CurrencyItemView(item),
      ),
      compareFn: (item, sItem) => item.coinType == sItem.coinType,
      filterFn: (item, filter) {
        filter = filter.trim().toLowerCase();
        if (filter.isEmpty) return true;
        if ((item.coinType?.toLowerCase().contains(filter) ?? "".isEmpty) ||
            (item.name?.toLowerCase().contains(filter) ?? "".isEmpty)) {
          return true;
        } else {
          return false;
        }
      },
      suffixProps: DropdownSuffixProps(dropdownButtonProps: DropdownButtonProps(color: Theme.of(context).primaryColor)),
      decoratorProps: _dropDownDecorator(
        context,
        hint: "Select".tr,
        baseStyle: Theme.of(context).textTheme.bodyMedium,
        color: Theme.of(context).secondaryHeaderColor,
      ),
    );
  }
}

class DropDownViewNetwork extends StatelessWidget {
  const DropDownViewNetwork({super.key, required this.items, this.selectedItem, this.onSelect});

  final List<Network> items;
  final Network? selectedItem;
  final Function(Network)? onSelect;

  @override
  Widget build(BuildContext context) {
    final checkValue = selectedItem?.id ?? selectedItem?.networkType;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Dimens.paddingMid, vertical: Dimens.paddingMin),
      decoration: boxDecorationRoundCorner(),
      child: DropdownButton<Network>(
        value: checkValue == null ? null : selectedItem,
        isExpanded: true,
        hint: TextRobotoAutoNormal("Select Network".tr),
        icon: Icon(Icons.arrow_drop_down, color: Get.theme.primaryColor),
        elevation: 10,
        dropdownColor: context.theme.secondaryHeaderColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        underline: Container(height: 0, color: Colors.transparent),
        menuMaxHeight: context.width,
        onChanged: (value) => (onSelect != null && value != null) ? onSelect!(value) : null,
        items:
            items.map<DropdownMenuItem<Network>>((Network value) {
              return DropdownMenuItem<Network>(value: value, child: TextRobotoAutoBold(value.networkName ?? ""));
            }).toList(),
      ),
    );
  }
}

DropDownDecoratorProps _dropDownDecorator(BuildContext context, {String? hint, TextStyle? baseStyle, Color? color}) {
  color = color ?? Theme.of(context).primaryColor;
  return DropDownDecoratorProps(
    baseStyle: baseStyle,
    decoration: InputDecoration(
      filled: true,
      isDense: true,
      fillColor: Theme.of(context).secondaryHeaderColor,
      hintText: hint,
      contentPadding: EdgeInsets.zero,
      enabledBorder: commonFieldBorder(context, borderRadius: Dimens.radiusCornerMid),
      disabledBorder: commonFieldBorder(context, borderRadius: Dimens.radiusCornerMid),
      focusedBorder: commonFieldBorder(context, borderRadius: Dimens.radiusCornerMid),
    ),
  );
}

OutlineInputBorder commonFieldBorder(
  BuildContext context, {
  bool isFocus = false,
  bool isError = false,
  double borderRadius = 7,
  Color? bColor,
}) {
  Color color = bColor ?? Theme.of(context).secondaryHeaderColor;
  if (isFocus) color = Theme.of(context).focusColor;
  if (isError) color = Theme.of(context).colorScheme.error;

  return OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
    borderSide: BorderSide(width: 0.5, color: color),
  );
}
