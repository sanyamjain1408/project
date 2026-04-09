import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../data/models/currency.dart';
import '../../../../../data/models/wallet.dart';
import '../../../../../data/remote/api_repository.dart';
import '../../../../../helper/app_helper.dart';
import '../../../../../utils/common_utils.dart';

class CheckDepositController extends GetxController {
  RxList<Currency> currencyList = <Currency>[].obs;
  RxList<Network> networkList = <Network>[].obs;
  Rx<Currency> selectedCurrency = Currency().obs;
  Rx<Network> selectedNetwork = Network().obs;
  RxBool isLoading = true.obs;
  bool isEvm = getSettingsLocal()?.isEvmWallet ?? false;

  void initController() {
    networkList.value = [];
    selectedCurrency.value = Currency();
    selectedNetwork.value = Network();
  }

  Future<void> getCoinList({String? preCode}) async {
    isLoading.value = true;
    APIRepository().getCoinList(isDeposit: true, checkDeposit: true).then((resp) {
      isLoading.value = false;
      if (resp.success && resp.data != null) {
        currencyList.value = List<Currency>.from(resp.data!.map((x) => Currency.fromJson(x)));
        if(preCode.isValid){
          final currency = currencyList.firstWhereOrNull((element) => element.coinType == preCode);
          if(currency != null) {
            selectedCurrency.value = currency;
            if(isEvm) getWalletNetworks();
          }
        }
      }else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  Future<void> getWalletNetworks() async {
    if(!selectedCurrency.value.coinType.isValid) return;
    isLoading.value = true;
    networkList.clear();
    selectedNetwork.value = Network();
    APIRepository().getWalletNetworks(selectedCurrency.value.coinType!, TransferType.deposit).then((resp) {
      isLoading.value = false;
      if (resp.success && resp.data != null) {
        final cNetworks =  CurrencyNetworks.fromJson(resp.data);
        networkList.value = cNetworks.coinPaymentNetworks ?? [];
        if(networkList.isEmpty) networkList.value = cNetworks.networks ?? [];
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

 void checkCoinTransaction(int netId, int coinId, String transactionId, Function(CheckDeposit) onSuccess) async {
    showLoadingDialog();
    APIRepository().checkCoinTransaction(netId, coinId, transactionId).then((resp) {
      hideLoadingDialog();
      if (resp.success && resp.data != null) {
        final deposit = CheckDeposit.fromJson(resp.data);
        deposit.message = resp.message;
        onSuccess(deposit);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }
}