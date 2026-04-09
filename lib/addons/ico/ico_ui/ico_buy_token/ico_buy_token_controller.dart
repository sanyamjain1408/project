import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/ico/ico_api_repository.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_phase.dart';
import 'package:tradexpro_flutter/addons/ico/model/ico_settings.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';

import 'package:tradexpro_flutter/data/local/api_constants.dart';

class IcoBuyCoinController extends GetxController {
  RxBool isDataLoading = true.obs;
  Rx<IcoPhase> phase = IcoPhase().obs;
  Rx<IcoBuySettings> buySettings = IcoBuySettings().obs;
  RxInt selectedMethodIndex = 0.obs;

  void getIcoActivePhaseDetails(int id) async {
    IcoAPIRepository().getIcoActivePhaseDetails(id).then((resp) {
      if (resp.success) {
        phase.value = IcoPhase.fromJson(resp.data);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) => showToast(err.toString()));
  }

  Future<void> getIcoTokenBuyPage() async {
    IcoAPIRepository().getIcoTokenBuyPage().then((resp) {
      isDataLoading.value = false;
      if (resp.success && resp.data != null) {
        buySettings.value = IcoBuySettings.fromJson(resp.data);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isDataLoading.value = false;
      showToast(err.toString());
    });
  }

  List<String> getMethodList() {
    if (buySettings.value.paymentMethods.isValid) {
      return buySettings.value.paymentMethods!.map((e) => e.title ?? "").toList();
    }
    return [];
  }

  List<String> getBankList() {
    if (buySettings.value.bank.isValid) {
      // return buySettings.value.bank!.map((e) => e.bankName ?? "").toList();
      return buySettings.value.bank!.map((e) => e.bankForm?.title ?? "").toList();
    }
    return [];
  }

  List<String> getCurrencyList() {
    if (buySettings.value.currencyList.isValid) {
      return buySettings.value.currencyList!.map((e) => e.name ?? "").toList();
    }
    return [];
  }

  List<String> getWalletList() {
    if (buySettings.value.wallet.isValid) {
      return buySettings.value.wallet!.map((e) => e.name ?? "").toList();
    }
    return [];
  }

  Future<void> getIcoTokenPriceInfo(double amount, String currency, Function(TokenPriceInfo) onRate, {int? payerWallet}) async {
    final method = buySettings.value.paymentMethods?[selectedMethodIndex.value];
    IcoAPIRepository()
        .getIcoTokenPriceInfo(phase.value.id ?? 0, amount, phase.value.tokenId ?? 0, method?.paymentMethod ?? 0, currency, payerWallet: payerWallet)
        .then((resp) {
      if (resp.success) {
        final info = TokenPriceInfo.fromJson(resp.data);
        onRate(info);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      showToast(err.toString());
    });
  }

  Future<void> icoTokenBuy(IcoCreateBuyToken buyToken, Function() onSuccess) async {
    showLoadingDialog();
    final method = buySettings.value.paymentMethods?[selectedMethodIndex.value];
    buyToken.paymentMethod = method?.paymentMethod;
    buyToken.phaseId = phase.value.id;
    buyToken.tokenId = phase.value.tokenId;
    buyToken.bankRef = buySettings.value.ref;
    IcoAPIRepository().icoTokenBuyNew(buyToken).then((resp) {
      hideLoadingDialog();
      if (resp.success) {
        final success = resp.data[APIKeyConstants.success] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) onSuccess();
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.message);
    });
  }
}
