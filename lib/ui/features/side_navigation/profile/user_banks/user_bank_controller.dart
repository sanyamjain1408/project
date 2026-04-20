import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../data/models/bank_data.dart';
import '../../../../../data/models/dynamic_form.dart';
import '../../../../../data/remote/api_repository.dart';
import '../../../../../utils/common_utils.dart';

class UserBankController extends GetxController {
  RxList<DynamicBank> userBanks    = <DynamicBank>[].obs;
  RxBool              isDataLoading = true.obs;

  // ── Fetch user's saved bank list ─────────────────────────────────────
  void getUserBankList() {
    isDataLoading.value = true;
    APIRepository().getBankList().then(
      (resp) {
        isDataLoading.value = false;
        if (resp.success) {
          userBanks.value = List<DynamicBank>.from(
            resp.data.map((x) => DynamicBank.fromJson(x)),
          );
        } else {
          showToast(resp.message);
        }
      },
      onError: (err) {
        isDataLoading.value = false;
        showToast(err.toString());
      },
    );
  }

  // ── Fetch single bank details for edit screen ────────────────────────
  void getBankDetails(int bankID, Function(DynamicBank?) onSuccess) {
    APIRepository().userUserBank(bankID).then(
      (resp) {
        if (resp.success) {
          onSuccess(DynamicBank.fromJson(resp.data));
        } else {
          showToast(resp.message);
          onSuccess(null);
        }
      },
      onError: (err) {
        showToast(err.toString());
        onSuccess(null);
      },
    );
  }

  // ── Save (add new) or Update existing bank ───────────────────────────
  void userBankSave({
    required String accountNumber,
    required String accountHolder,
    required String bankName,
    required String ifscCode,
    int? bankId,
  }) {
    showLoadingDialog();

    final BankForm form = BankForm()
      ..bankIdL = bankId
      ..access  = BankAccessType.user.toString()
      ..fields  = [
        DynamicField()
          ..slug        = 'account_number'
          ..title       = 'Account Number'
          ..controllerL = TextEditingController(text: accountNumber),
        DynamicField()
          ..slug        = 'account_holder'
          ..title       = 'Account Holder Name'
          ..controllerL = TextEditingController(text: accountHolder),
        DynamicField()
          ..slug        = 'bank_name'
          ..title       = 'Bank Name'
          ..controllerL = TextEditingController(text: bankName),
        DynamicField()
          ..slug        = 'ifsc_code'
          ..title       = 'IFSC Code'
          ..controllerL = TextEditingController(text: ifscCode),
      ];

    APIRepository().userBankSubmit(form).then(
      (resp) {
        hideLoadingDialog();
        showToast(resp.message, isError: !resp.success);
        if (resp.success) {
          Get.back();
          getUserBankList();
        }
      },
      onError: (err) {
        hideLoadingDialog();
        showToast(err.toString());
      },
    );
  }

  // ── Delete bank account ──────────────────────────────────────────────
  void userBankDelete(int bankID) {
    showLoadingDialog();
    APIRepository().userBankDelete(bankID).then(
      (resp) {
        hideLoadingDialog();
        showToast(resp.message, isError: !resp.success);
        if (resp.success) {
          Get.back();
          getUserBankList();
        }
      },
      onError: (err) {
        hideLoadingDialog();
        showToast(err.toString());
      },
    );
  }
}