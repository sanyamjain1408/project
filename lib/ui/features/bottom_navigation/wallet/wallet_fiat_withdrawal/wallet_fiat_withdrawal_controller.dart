import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/fiat_deposit.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';


class WalletFiatWithdrawalController extends GetxController {
  Rx<FiatWithdrawal> fiatWithdrawalData = FiatWithdrawal().obs;
  late Wallet wallet;
  RxBool isLoading = true.obs;
  RxInt selectedMethodIndex = 0.obs;

  void getFiatWithdrawal() {
    isLoading.value = true;
    APIRepository().getWalletCurrencyWithdraw().then((resp) {
      isLoading.value = false;
      if (resp.success) {
        fiatWithdrawalData.value = FiatWithdrawal.fromJson(resp.data);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  List<String> getMethodList(FiatWithdrawal? fiatWithdrawal) {
    if (fiatWithdrawal?.paymentMethodList.isValid ?? false) {
      return fiatWithdrawal!.paymentMethodList!.map((e) => e.title ?? "").toList();
    }
    return [];
  }

  List<String> getBankList(FiatWithdrawal? fiatWithdrawal) {
    if (fiatWithdrawal?.myBank.isValid ?? false) {
      return fiatWithdrawal!.myBank!.map((e) => e.bankForm?.title ?? "").toList();
    }
    return [];
  }

  void walletCurrencyWithdraw(CreateWithdrawal withdraw, Function() onSuccess) {
    showLoadingDialog();
    final pMethod = fiatWithdrawalData.value.paymentMethodList?[selectedMethodIndex.value];
    withdraw.paymentMethodId = pMethod?.id;
    withdraw.paymentMethodType = pMethod?.paymentMethod;
    withdraw.type = "wallet";
    APIRepository().walletCurrencyWithdraw(withdraw).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success, isLong: true);
      if (resp.success) onSuccess();
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }

}
