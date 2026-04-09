import 'package:get/get.dart';

import '../../../../../data/models/bank_data.dart';
import '../../../../../data/remote/api_repository.dart';
import '../../../../../utils/common_utils.dart';

class UserBankController extends GetxController {
  RxList<DynamicBank> userBanks = <DynamicBank>[].obs;
  RxList<BankForm> bankForms = <BankForm>[].obs;
  RxBool isDataLoading = true.obs;

  void getUserBankList() {
    isDataLoading.value = true;
    APIRepository().getBankList().then(
      (resp) {
        isDataLoading.value = false;
        if (resp.success) {
          userBanks.value = List<DynamicBank>.from(resp.data.map((x) => DynamicBank.fromJson(x)));
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

  void getBankFormList() {
    APIRepository().getBankForms().then(
      (resp) {
        if (resp.success) {
          bankForms.value = List<BankForm>.from(resp.data.map((x) => BankForm.fromJson(x)));
        } else {
          showToast(resp.message);
        }
      },
      onError: (err) {
        showToast(err.toString());
      },
    );
  }

  void getBankDetails(int bankID, Function(DynamicBank) onSuccess) {
    APIRepository()
        .userUserBank(bankID)
        .then(
          (resp) {
            if (resp.success) {
              onSuccess(DynamicBank.fromJson(resp.data));
            } else {
              showToast(resp.message);
            }
          },
          onError: (err) {
            showToast(err.toString());
          },
        );
  }

  void userBankSave(BankForm bank) {
    showLoadingDialog();
    APIRepository()
        .userBankSubmit(bank)
        .then(
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

  void userBankDelete(int bankID) {
    showLoadingDialog();
    APIRepository()
        .userBankDelete(bankID)
        .then(
          (resp) {
            hideLoadingDialog();
            showToast(resp.message, isError: !resp.success);
            if (resp.success) getUserBankList();
          },
          onError: (err) {
            hideLoadingDialog();
            showToast(err.toString());
          },
        );
  }
}
