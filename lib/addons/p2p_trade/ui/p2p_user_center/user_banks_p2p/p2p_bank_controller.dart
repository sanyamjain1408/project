import 'package:get/get.dart';

import '../../../../../data/models/bank_data.dart';
import '../../../../../data/models/list_response.dart';
import '../../../../../utils/common_utils.dart';
import '../../../models/p2p_settings.dart';
import '../../../p2p_api_repository.dart';

class P2PBankController extends GetxController {
  RxList<DynamicBank> p2pBankList = <DynamicBank>[].obs;
  RxList<P2PPaymentMethod> paymentList = <P2PPaymentMethod>[].obs;
  RxBool isDataLoading = true.obs;

  void getP2pBankList() {
    isDataLoading.value = true;
    P2pAPIRepository().getP2pPaymentMethod().then(
      (resp) {
        isDataLoading.value = false;
        if (resp.success && resp.data != null) {
          ListResponse listResponse = ListResponse.fromJson(resp.data);
          p2pBankList.value = List<DynamicBank>.from(listResponse.data.map((x) => DynamicBank.fromJson(x)));
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

  void getP2pAdminPaymentMethods() {
    P2pAPIRepository().getP2pAdminPaymentMethods().then(
      (resp) {
        if (resp.success && resp.data != null) {
          paymentList.value = List<P2PPaymentMethod>.from(resp.data!.map((x) => P2PPaymentMethod.fromJson(x)));
        } else {
          showToast(resp.message);
        }
      },
      onError: (err) {
        showToast(err.toString());
      },
    );
  }

  void getP2pDetailsPaymentMethod(int bankID, Function(DynamicBank) onSuccess) {
    P2pAPIRepository()
        .getP2pDetailsPaymentMethod(bankID)
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

  void p2pBankSave(BankForm bank) {
    showLoadingDialog();
    P2pAPIRepository()
        .p2pPaymentMethodSave(bank)
        .then(
          (resp) {
            hideLoadingDialog();
            showToast(resp.message, isError: !resp.success);
            if (resp.success) {
              Get.back();
              getP2pBankList();
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
    P2pAPIRepository()
        .p2pPaymentMethodDelete(bankID)
        .then(
          (resp) {
            hideLoadingDialog();
            showToast(resp.message, isError: !resp.success);
            if (resp.success) {
              Get.back();
              getP2pBankList();
            }
          },
          onError: (err) {
            hideLoadingDialog();
            showToast(err.toString());
          },
        );
  }

}
