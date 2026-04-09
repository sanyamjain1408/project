import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/models/fiat_deposit.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/paystack_util.dart';


class WalletFiatDepositController extends GetxController {
  RxBool isLoading = true.obs;
  RxInt selectedMethodIndex = 0.obs;
  Rx<FiatDeposit> fiatDepositData = FiatDeposit().obs;
  late Wallet wallet;

  Future<void> getFiatDepositData() async {
    isLoading.value = true;
    APIRepository().getWalletCurrencyDeposit().then((resp) {
      isLoading.value = false;
      if (resp.success) {
        fiatDepositData.value = FiatDeposit.fromJson(resp.data);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  Future<void> walletCurrencyDeposit(CreateDeposit deposit, Function() onSuccess) async {
    final pMethod = fiatDepositData.value.paymentMethods?[selectedMethodIndex.value];
    deposit.paymentId = pMethod?.id;
    showLoadingDialog();
    APIRepository().walletCurrencyDeposit(deposit).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        if (deposit.code.isValid) Get.back();
        onSuccess();
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.message);
    });
  }

  List<String> getMethodList(FiatDeposit? fiatDepositData) {
    if (fiatDepositData?.paymentMethods.isValid ?? false) {
      return fiatDepositData!.paymentMethods!.map((e) => e.title ?? "").toList();
    }
    return [];
  }

  List<String> getBankList(FiatDeposit? fiatDepositData) {
    if (fiatDepositData?.banks.isValid ?? false) {
      return fiatDepositData!.banks!.map((e) => e.bankForm?.title ?? "").toList();
    }
    return [];
  }

  Future<void> payStackPaymentUrlGet(double amount, String email, Function(PayStackData) onSuccess) async {
    final pMethod = fiatDepositData.value.paymentMethods?[selectedMethodIndex.value];
    showLoadingDialog();
    APIRepository().paystackPaymentUrlGet(wallet.id, pMethod?.id ?? 0, amount, email, 2, currency: wallet.coinType).then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success = resp.data[APIKeyConstants.success] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        if (success) {
          final data = PayStackData.fromJson(resp.data[APIKeyConstants.data]);
          onSuccess(data);
        } else {
          showToast(message);
        }
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.message);
    });
  }
}
