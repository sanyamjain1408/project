import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/local/constants.dart';
import '../../data/models/bank_data.dart';
import '../../data/models/dynamic_form.dart';
import '../../helper/app_checker.dart';
import 'app_widgets.dart';
import '../../utils/button_util.dart';
import '../../utils/common_utils.dart';
import '../../utils/decorations.dart';
import '../../utils/dimens.dart';
import '../../utils/spacers.dart';
import '../../utils/text_field_util.dart';
import '../../utils/text_util.dart';
import '../../utils/extensions.dart';

class DynamicFieldItemView extends StatelessWidget {
  const DynamicFieldItemView({super.key, required this.dField, required this.fieldUpdated});

  final DynamicField dField;
  final Function() fieldUpdated;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textSpanWithAction(
          dField.title ?? '',
          dField.required == 1 ? "*" : '',
          subColor: Colors.red,
          fontSize: Dimens.fontSizeMid,
        ),
        vSpacer5(),
        textFieldWithWidget(
          height: 45,
          controller: dField.controllerL,
          hint: "${"Enter".tr} ${dField.title ?? ''}".toCapitalizeFirst(),
          type: AppChecker.getTextInputType(dField.dataType),
          onTextChange: _setDataOnField,
        ),
        if (dField.errorL.isValid)
          TextRobotoAutoNormal(dField.errorL ?? '', color: Theme.of(context).colorScheme.error, maxLines: 3),
      ],
    );
  }

  void _setDataOnField(String text) {
    final valueL = dField.controllerL?.text.trim() ?? '';
    dField.errorL = '';
    if (dField.required == 1 && valueL.isEmpty) {
      dField.errorL = "${dField.title ?? ''} ${"is required".tr}".toCapitalizeFirst();
    } else if (valueL.isNotEmpty) {
      final type = dField.dataType ?? '';
      if (type == DynamicFieldTypes.email) {
        if (!GetUtils.isEmail(valueL)) dField.errorL = "Input a valid Email".tr;
      }
    }
    fieldUpdated();
  }
}

class DynamicBankDetailsView extends StatelessWidget {
  const DynamicBankDetailsView({super.key, required this.dBank});

  final DynamicBank dBank;

  @override
  Widget build(BuildContext context) {
    final bankSlugs = dBank.bank?.keys ?? [];
    return Column(
      children: [
        vSpacer10(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextRobotoAutoBold("Bank details".tr),
            buttonTextBordered("Copy", true, onPress: () => copyToClipboard(dBank.toCopy()), visualDensity: minimumVisualDensity),
          ],
        ),
        vSpacer5(),
        Container(
          decoration: boxDecorationRoundBorder(),
          padding: const EdgeInsets.all(Dimens.paddingMid),
          child: Column(
            children: List.generate(bankSlugs.length, (index) {
              final item = dBank.bank!.values.toList()[index];
              return TwoTextFixedView(item.title ?? '', item.value ?? '', onSubTap: () => copyToClipboard(item.value ?? '', textInMsg: true));
            },),
          ),
        ),
        vSpacer2(),
        Align(alignment: Alignment.centerRight, child: TextRobotoAutoNormal("Tap on the value for copy".tr, textAlign: TextAlign.end)),
      ],
    );
  }
}