import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../utils/button_util.dart';
import '../../../../../utils/common_utils.dart';
import '../../../../../utils/common_widgets.dart';
import '../../../../../utils/dimens.dart';
import '../../../../../utils/extensions.dart';
import '../../../../../utils/spacers.dart';
import '../../../../../utils/text_util.dart';
import '../../../../../data/models/bank_data.dart';
import '../../../../../data/models/dynamic_form.dart';
import '../../../../../utils/appbar_util.dart';
import '../../../../ui_helper/bank_widgets.dart';
import 'user_bank_controller.dart';

class BankInputPage extends StatefulWidget {
  const BankInputPage({super.key, this.preBank});

  final DynamicBank? preBank;

  @override
  State<BankInputPage> createState() => _BankInputPageState();
}

class _BankInputPageState extends State<BankInputPage> {
  final _controller = Get.find<UserBankController>();

  Rx<BankForm> selectedBank = BankForm().obs;

  @override
  void initState() {
    super.initState();
    if (widget.preBank == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getBankFormList());
    } else {
      _updatePreBankData(widget.preBank);
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _controller.getBankDetails(widget.preBank?.id ?? 0, _updatePreBankData);
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
    selectedBank.value = bankForm;
  }

  @override
  Widget build(BuildContext context) {
    final btnTitle = widget.preBank == null ? "Create Bank".tr : "Update Bank".tr;
    final title = widget.preBank == null ? "Add New Bank".tr : "Edit Bank".tr;

    return Scaffold(
      appBar: appBarBackWithActions(title: title),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimens.paddingMid),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextRobotoAutoNormal("Bank".tr, fontSize: Dimens.fontSizeMid, fontWeight: FontWeight.bold),
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
                final fields = selectedBank.value.fields ?? [];
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
                            fieldUpdated: () => selectedBank.refresh(),
                          );
                        },
                      ),
                    );
              }),
              Obx(() {
                final fields = selectedBank.value.fields ?? [];
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
      return [[selectedBank.value.title ?? ''], 0];
    }else{
      final list = _controller.bankForms.map((element) => element.title ?? '').toList();
      final sIndex = _controller.bankForms.indexWhere((element) => element.id == selectedBank.value.id);
      return [list, sIndex];
    }
  }

  void _setSelectedBankForm(int index) {
    final form = _controller.bankForms[index];
    for (DynamicField field in (form.fields ?? [])) {
      field.controllerL = TextEditingController();
    }
    selectedBank.value = form;
  }

  void _nextButtonAction() {
    bool hasError = false;
    final fieldList = selectedBank.value.fields ?? [];
    for (final field in fieldList) {
      if (field.errorL.isValid) hasError = true;
      final valueL = field.controllerL?.text.trim() ?? '';
      if (field.required == 1 && !valueL.isValid) {
        field.errorL = "${field.title ?? ''} ${"is required".tr}".toCapitalizeFirst();
        hasError = true;
      }
    }
    hasError ? selectedBank.refresh() : _saveOrUpdateBank();
  }

  void _saveOrUpdateBank() {
    hideKeyboard();
    selectedBank.value.bankIdL = widget.preBank?.id;
    selectedBank.value.access = BankAccessType.user.toString();
    _controller.userBankSave(selectedBank.value);
  }
}

