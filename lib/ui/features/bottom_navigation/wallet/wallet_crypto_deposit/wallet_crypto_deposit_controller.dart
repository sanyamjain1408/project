
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../data/models/currency.dart';
import '../../../../../data/models/faq.dart';
import '../../../../../data/models/history.dart';
import '../../../../../data/models/list_response.dart';
import '../../../../../data/models/response.dart';
import '../../../../../data/remote/api_repository.dart';
import '../../../../../utils/common_utils.dart';

class WalletCryptoDepositController extends GetxController {

  RxList<FAQ> faqList = <FAQ>[].obs;
  RxList<Currency> currencyList = <Currency>[].obs;
  RxList<Network> networkList = <Network>[].obs;
  Rx<Currency> selectedCurrency = Currency().obs;
  Rx<Network> selectedNetwork = Network().obs;
  Rx<WalletAddress> depositAddress = WalletAddress().obs;
  RxList<History> historyList = <History>[].obs;
  RxBool isLoading = true.obs;
  bool isEvm = getSettingsLocal()?.isEvmWallet ?? false;

  void initController(){
    networkList.value = [];
    selectedCurrency.value = Currency();
    selectedNetwork.value = Network();
    depositAddress.value = WalletAddress();
  }

  Future<void> getDepositCoinList({String? preCode}) async {
    isLoading.value = true;
    APIRepository().getCoinList(isDeposit: true, currencyType: CurrencyType.crypto).then((resp) {
      isLoading.value = false;
      if (resp.success && resp.data != null) {
        currencyList.value = List<Currency>.from(resp.data!.map((x) => Currency.fromJson(x)));
        if(preCode.isValid){
          final currency = currencyList.firstWhereOrNull((element) => element.coinType == preCode);
          if(currency != null) {
            selectedCurrency.value = currency;
            isEvm ? getWalletNetworks() : getWalletDeposit();
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

  /// For CORE Exchange
  Future<void> getWalletDeposit() async {
    if (!selectedCurrency.value.coinType.isValid) return;
    isLoading.value = true;
    selectedNetwork.value = Network();
    networkList.clear();
    depositAddress.value = WalletAddress();
    APIRepository().getWalletDeposit(selectedCurrency.value.coinType ?? '').then((resp) {
      isLoading.value = false;
      if (resp.success && resp.data != null) {
        depositAddress.value = WalletAddress.fromJson(resp.data);
        if(depositAddress.value.coinPaymentNetworks.isValid){
          networkList.value = depositAddress.value.coinPaymentNetworks!;
        }else if(depositAddress.value.network != null){
          selectedNetwork.value = depositAddress.value.network!;
        }
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  /// For CORE Exchange
  Future<void> getWalletNetworkAddress() async {
    if (!selectedCurrency.value.coinType.isValid) return;
    if (!selectedNetwork.value.networkType.isValid && (selectedNetwork.value.id ?? 0) <= 0) return;
    isLoading.value = true;
    depositAddress.value.address = null;
    depositAddress.value.rentedTill = null;
    APIRepository().walletNetworkAddress(selectedCurrency.value.coinType ?? '', selectedNetwork.value.networkType ?? '').then((resp) {
      isLoading.value = false;
      if (resp.success && resp.data != null) {
        final dAddress = WalletAddress.fromJson(resp.data);
        depositAddress.value.address = dAddress.address;
        depositAddress.value.rentedTill = dAddress.rentedTill;
        depositAddress.refresh();
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  /// For EVM Exchange
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

  /// For EVM Exchange
  Future<void> getWalletDepositAddress() async {
    if (!selectedCurrency.value.coinType.isValid) return;
    if (!selectedNetwork.value.networkType.isValid && (selectedNetwork.value.id ?? 0) <= 0) return;
    isLoading.value = true;
    depositAddress.value = WalletAddress();
    APIRepository().walletDepositAddress(selectedCurrency.value.id ?? 0, networkType: selectedNetwork.value.networkType,
        networkId: selectedNetwork.value.id).then((resp) {
      isLoading.value = false;
      if (resp.success && resp.data != null) {
        depositAddress.value = WalletAddress.fromJson(resp.data);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  Future<void> getFAQList() async {
    APIRepository().getFAQList(1, type: FAQType.deposit).then((resp) {
      if (resp.success) {
        ListResponse response = ListResponse.fromJson(resp.data);
        if (response.data != null) {
          faqList.value = List<FAQ>.from(response.data!.map((x) => FAQ.fromJson(x)));
        }
      }
    }, onError: (err) {});
  }

  Future<void> getHistoryListData() async {
    APIRepository().getActivityList(0, HistoryType.deposit).then((resp) {
      if (resp.success && resp.data != null) {
        final historyResponse = HistoryResponse.fromJson(resp.data);
        final listResponse = historyResponse.histories;
        if (listResponse != null) {
          historyList.value = List<History>.from(listResponse.data!.map((x) => History.fromJson(x)));
        }
      }
    }, onError: (err) {});
  }
}

// class WalletCryptoDepositController extends GetxController {
//
//   RxList<FAQ> faqList = <FAQ>[].obs;
//   RxList<Currency> currencyList = <Currency>[].obs;
//   RxList<Network> networkList = <Network>[].obs;
//   Rx<Currency> selectedCurrency = Currency().obs;
//   Rx<Network> selectedNetwork = Network().obs;
//   Rx<WalletAddress> depositAddress = WalletAddress().obs;
//   RxList<History> historyList = <History>[].obs;
//   RxBool isLoading = true.obs;
//   bool isEvm = getSettingsLocal()?.isEvmWallet ?? false;
//
//   initController(){
//     networkList.value = [];
//     selectedCurrency.value = Currency();
//     selectedNetwork.value = Network();
//     depositAddress.value = WalletAddress();
//   }
//
//   Future<void> getDepositCoinList({String? preCode}) async {
//     isLoading.value = true;
//     APIRepository().getCoinList(true, currencyType: CurrencyType.crypto).then((resp) {
//       isLoading.value = false;
//       if (resp.success && resp.data != null) {
//         currencyList.value = List<Currency>.from(resp.data!.map((x) => Currency.fromJson(x)));
//         if(preCode.isValid){
//           final currency = currencyList.firstWhereOrNull((element) => element.coinType == preCode);
//           if(currency != null) {
//             selectedCurrency.value = currency;
//             isEvm ? getWalletNetworks() : getWalletDeposit();
//           }
//         }
//       }else {
//         showToast(resp.message);
//       }
//     }, onError: (err) {
//       isLoading.value = false;
//       showToast(err.toString());
//     });
//   }
//
//   /// For CORE Exchange
//   Future<void> getWalletDeposit() async {
//     if (!selectedCurrency.value.coinType.isValid) return;
//     isLoading.value = true;
//     depositAddress.value = WalletAddress();
//     APIRepository().getWalletDeposit(selectedCurrency.value.coinType ?? '').then((resp) {
//       isLoading.value = false;
//       if (resp.success && resp.data != null) {
//         depositAddress.value = WalletAddress.fromJson(resp.data);
//         // depositAddress.value.address = "this is a demo address";
//       } else {
//         showToast(resp.message);
//       }
//     }, onError: (err) {
//       isLoading.value = false;
//       showToast(err.toString());
//     });
//   }
//
//   /// For EVM Exchange
//   Future<void> getWalletNetworks() async {
//     if(!selectedCurrency.value.coinType.isValid) return;
//     isLoading.value = true;
//     networkList.clear();
//     selectedNetwork.value = Network();
//     APIRepository().getWalletNetworks(selectedCurrency.value.coinType!, TransferType.deposit).then((resp) {
//       isLoading.value = false;
//       if (resp.success && resp.data != null) {
//         final cNetworks =  CurrencyNetworks.fromJson(resp.data);
//         networkList.value = cNetworks.coinPaymentNetworks ?? [];
//         if(networkList.isEmpty) networkList.value = cNetworks.networks ?? [];
//       } else {
//         showToast(resp.message);
//       }
//     }, onError: (err) {
//       isLoading.value = false;
//       showToast(err.toString());
//     });
//   }
//
//   /// For EVM Exchange
//   Future<void> getWalletDepositAddress() async {
//     if (!selectedCurrency.value.coinType.isValid) return;
//     if (!selectedNetwork.value.networkType.isValid) return;
//     isLoading.value = true;
//     depositAddress.value = WalletAddress();
//     APIRepository().walletDepositAddress(selectedCurrency.value.id ?? 0, networkType: selectedNetwork.value.networkType,
//         networkId: selectedNetwork.value.id).then((resp) {
//       isLoading.value = false;
//       if (resp.success && resp.data != null) {
//         depositAddress.value = WalletAddress.fromJson(resp.data);
//       } else {
//         showToast(resp.message);
//       }
//     }, onError: (err) {
//       isLoading.value = false;
//       showToast(err.toString());
//     });
//   }
//
//   Future<void> getFAQList() async {
//     APIRepository().getFAQList(1, type: FAQType.deposit).then((resp) {
//       if (resp.success) {
//         ListResponse response = ListResponse.fromJson(resp.data);
//         if (response.data != null) {
//           faqList.value = List<FAQ>.from(response.data!.map((x) => FAQ.fromJson(x)));
//         }
//       }
//     }, onError: (err) {});
//   }
//
//   Future<void> getHistoryListData() async {
//     APIRepository().getActivityList(0, HistoryType.deposit).then((resp) {
//       if (resp.success && resp.data != null) {
//         final historyResponse = HistoryResponse.fromJson(resp.data);
//         final listResponse = historyResponse.histories;
//         if (listResponse != null) {
//           historyList.value = List<History>.from(listResponse.data!.map((x) => History.fromJson(x)));
//         }
//       }
//     }, onError: (err) {});
//   }
// }