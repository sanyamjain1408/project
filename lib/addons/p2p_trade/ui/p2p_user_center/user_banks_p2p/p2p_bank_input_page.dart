import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../helper/app_checker.dart';
import '../../../../../utils/button_util.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/common_widgets.dart';
import '../../../../../utils/dimens.dart';
import '../../../../../utils/extensions.dart';
import '../../../../../utils/spacers.dart';
import '../../../../../utils/text_field_util.dart';
import '../../../../../utils/text_util.dart';
import '../../../../../data/models/bank_data.dart';
import '../../../../../data/models/dynamic_form.dart';
import '../../../../../utils/appbar_util.dart';
import '../../../models/p2p_settings.dart';
import 'p2p_bank_controller.dart';

class P2pBankInputPage extends StatefulWidget {
  const P2pBankInputPage({super.key, this.preBank});

  final DynamicBank? preBank;

  @override
  State<P2pBankInputPage> createState() => _P2pBankInputPageState();
}

class _P2pBankInputPageState extends State<P2pBankInputPage> {
  final _controller = Get.find<P2PBankController>();

  Rx<P2PPaymentMethod> selectedPayment = P2PPaymentMethod().obs;

  @override
  void initState() {
    super.initState();
    if (widget.preBank == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getP2pAdminPaymentMethods());
    } else {
      _updatePreBankData(widget.preBank);
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _controller.getP2pDetailsPaymentMethod(widget.preBank?.id ?? 0, _updatePreBankData);
      });
    }
  }

 void _updatePreBankData(DynamicBank? preBank) {
    final bankItems = preBank?.bank ?? {};
    final bankForm = preBank?.bankForm ?? BankForm();
    for (String slug in bankItems.keys) {
      final value = bankItems[slug]?.value ?? '';
      final field = bankForm.fields?.firstWhereOrNull((element) => element.slug == slug);
      if (field != null) field.controllerL = TextEditingController(text: value);
    }
    selectedPayment.value.bankForm = bankForm;
    selectedPayment.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final btnTitle = widget.preBank == null ? "Add".tr : "Update".tr;
    final title = widget.preBank == null ? "Add payment method".tr : "Edit payment method".tr;

    return Scaffold(
      appBar: appBarBackWithActions(title: title),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimens.paddingMid),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextRobotoAutoNormal("Payment Method".tr, fontSize: Dimens.fontSizeMid, fontWeight: FontWeight.bold),
              Obx(() {
                final data = _getDropdownData();
                return dropDownListIndex(
                  data.first,
                  data.last,
                  "Select Bank".tr,
                  _setSelectedBankForm,
                  hMargin: 0,
                  isEditable: widget.preBank == null,
                );
              }),
              Obx(() {
                final fields = selectedPayment.value.bankForm?.fields ?? [];
                return fields.isEmpty
                    ? vSpacer0()
                    : Expanded(
                      child: ListView.separated(
                        itemCount: fields.length,
                        separatorBuilder: (context, index) => vSpacer15(),
                        padding: EdgeInsets.symmetric(vertical: Dimens.paddingMid),
                        itemBuilder: (context, index) {
                          return DynamicFieldItemView(
                            dField: fields[index],
                            fieldUpdated: () => selectedPayment.refresh(),
                          );
                        },
                      ),
                    );
              }),
              Obx(() {
                final fields = selectedPayment.value.bankForm?.fields ?? [];
                return fields.isEmpty ? vSpacer0() : buttonRoundedMain(text: btnTitle, onPress: _nextButtonAction);
              }),
            ],
          ),
        ),
      ),
    );
  }

  List _getDropdownData(){
    if(widget.preBank != null){
      return [[selectedPayment.value.bankForm?.title ?? ''], 0];
    }else{
      final list = _controller.paymentList.map((element) => element.bankForm?.title ?? '').toList();
      final sIndex = _controller.paymentList.indexWhere((element) => element.id == selectedPayment.value.bankForm?.id);
      return [list, sIndex];
    }
  }

  void _setSelectedBankForm(int index) {
    final method = _controller.paymentList[index];
    for (DynamicField field in (method.bankForm?.fields ?? [])) {
      field.controllerL = TextEditingController();
    }
    selectedPayment.value = method;
  }

  void _nextButtonAction() {
    bool hasError = false;
    final fieldList = selectedPayment.value.bankForm?.fields ?? [];
    for (final field in fieldList) {
      if (field.errorL.isValid) hasError = true;
      final valueL = field.controllerL?.text.trim() ?? '';
      if (field.required == 1 && !valueL.isValid) {
        field.errorL = "${field.title ?? ''} ${"is required".tr}".toCapitalizeFirst();
        hasError = true;
      }
    }
    hasError ? selectedPayment.refresh() : _saveOrUpdateBank();
  }

  void _saveOrUpdateBank() {
    hideKeyboard();
    selectedPayment.value.bankForm?.bankIdL = widget.preBank?.id;
    selectedPayment.value.bankForm?.access = BankAccessType.p2p.toString();
    _controller.p2pBankSave(selectedPayment.value.bankForm!);
  }
}

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
