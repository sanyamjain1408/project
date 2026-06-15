import 'package:decimal/decimal.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

import '../../../../../data/local/constants.dart';
import '../../../../../data/models/currency.dart';
import '../../../../../data/models/faq.dart';
import '../../../../../data/models/history.dart';
import '../../../../../data/models/list_response.dart';
import '../../../../../data/models/response.dart';
import '../../../../../data/local/api_constants.dart';
import '../../../../../data/remote/api_repository.dart';
import '../../../../../helper/app_helper.dart';
import '../../../../../utils/common_utils.dart';
class CoinWalletInfo {
  final double balance;
  const CoinWalletInfo({required this.balance});
}

class WalletCryptoWithdrawController extends GetxController {
  RxList<FAQ> faqList = <FAQ>[].obs;
  RxList<Currency> currencyList = <Currency>[].obs;
  final RxMap<String, double> coinBalanceMap = <String, double>{}.obs;
  final RxMap<String, CoinWalletInfo> coinInfoMap = <String, CoinWalletInfo>{}.obs;
  RxBool balanceMapReady = false.obs;
  RxList<Network> networkList = <Network>[].obs;
  Rx<Currency> selectedCurrency = Currency().obs;
  Rx<Network> selectedNetwork = Network().obs;
  Rx<PreWithdraw> preWithdrawal = PreWithdraw().obs;
  RxList<History> historyList = <History>[].obs;
  RxBool isLoading = true.obs;
  bool isEvm = getSettingsLocal()?.isEvmWallet ?? false;
  Rx<Decimal> walletBalance = Decimal.zero.obs;

  void initController() {
    networkList.value = [];
    selectedCurrency.value = Currency();
    selectedNetwork.value = Network();
    preWithdrawal.value = PreWithdraw();
  }

  Future<void> getWithdrawCoinList({Wallet? preWallet}) async {
    isLoading.value = true;
    _buildBalanceMap();
    APIRepository()
        .getCoinList(isWithdraw: true, currencyType: CurrencyType.crypto)
        .then(
          (resp) {
            isLoading.value = false;
            if (resp.success && resp.data != null) {
              currencyList.value = List<Currency>.from(resp.data!.map((x) => Currency.fromJson(x)));
              final preCode = preWallet?.coinType ?? '';
              if (preCode.isNotEmpty) {
                walletBalance.value = makeDecimal(preWallet?.balance ?? preWallet?.availableBalance);
                 final currency = currencyList.firstWhereOrNull((element) => element.coinType == preCode);
                if (currency != null) {
                  selectedCurrency.value = currency;
                  isEvm ? getWalletNetworks() : getWalletWithdrawal();
                }
              }
            } else {
              showToast(resp.message);
            }
          },
          onError: (err) {
            isLoading.value = false;
            showToast(err.toString());
          },
        );
  }

  void _buildBalanceMap() {
    balanceMapReady.value = false;
    _fetchWalletPage(1, <String, double>{}, <String, CoinWalletInfo>{});
  }

  void _fetchWalletPage(int page, Map<String, double> accBal, Map<String, CoinWalletInfo> accInfo) {
    APIRepository().getWalletList(page, type: WalletViewType.spot, perPage: 200).then((resp) {
      if (!resp.success || resp.data == null) {
        coinBalanceMap.value = Map.from(accBal);
        coinInfoMap.value = Map.from(accInfo);
        balanceMapReady.value = true;
        return;
      }
      final raw = resp.data[APIKeyConstants.wallets] ?? resp.data;
      ListResponse listResp;
      try {
        listResp = ListResponse.fromJson(raw);
      } catch (_) {
        coinBalanceMap.value = Map.from(accBal);
        coinInfoMap.value = Map.from(accInfo);
        balanceMapReady.value = true;
        return;
      }
      for (final item in (listResp.data ?? [])) {
        final w = Wallet.fromJson(item);
        final ct = w.coinType ?? '';
        if (ct.isNotEmpty) {
          final bal = (w.availableBalance ?? w.balance ?? 0).toDouble();
          accBal[ct] = bal;
          accInfo[ct] = CoinWalletInfo(balance: bal);
        }
      }
      if (listResp.nextPageUrl != null) {
        _fetchWalletPage(page + 1, accBal, accInfo);
      } else {
        coinBalanceMap.value = Map.from(accBal);
        coinInfoMap.value = Map.from(accInfo);
        balanceMapReady.value = true;
      }
    });
  }

  /// For CORE Exchange
  Future<void> getWalletWithdrawal() async {
    if (!selectedCurrency.value.coinType.isValid) return;
    isLoading.value = true;
    selectedNetwork.value = Network();
    networkList.clear();
    APIRepository()
        .getWalletWithdrawal(selectedCurrency.value.coinType ?? '')
        .then(
          (resp) {
            isLoading.value = false;
            if (resp.success && resp.data != null) {
              final wObg = WalletAddress.fromJson(resp.data);
              if (wObg.coinPaymentNetworks.isValid) {
                networkList.value = wObg.coinPaymentNetworks!;
              } else if (wObg.network != null) {
                selectedNetwork.value = wObg.network!;
              }
              walletBalance.value = makeDecimal(wObg.wallet?.balance);
            } else {
              showToast(resp.message);
            }
          },
          onError: (err) {
            isLoading.value = false;
            showToast(err.toString());
          },
        );
  }

  /// For EVM withdrawal
  Future<void> getWalletNetworks() async {
    if (!selectedCurrency.value.coinType.isValid) return;
    isLoading.value = true;
    networkList.clear();
    selectedNetwork.value = Network();
    APIRepository()
        .getWalletNetworks(selectedCurrency.value.coinType!, TransferType.withdraw)
        .then(
          (resp) {
            isLoading.value = false;
            if (resp.success && resp.data != null) {
              final cNetworks = CurrencyNetworks.fromJson(resp.data);
              networkList.value = cNetworks.coinPaymentNetworks ?? [];
              if (networkList.isEmpty) networkList.value = cNetworks.networks ?? [];
              walletBalance.value = makeDecimal(cNetworks.wallet?.balance);
            } else {
              showToast(resp.message);
            }
          },
          onError: (err) {
            isLoading.value = false;
            showToast(err.toString());
          },
        );
  }

  Future<void> preWithdrawProcess(String address, Decimal amount) async {
    if (!selectedCurrency.value.coinType.isValid) return;
    if (!selectedNetwork.value.networkType.isValid && (selectedNetwork.value.id ?? 0) <= 0) return;
    APIRepository()
        .preWithdrawProcess(
          address,
          amount,
          coinId: selectedCurrency.value.id,
          coinType: selectedCurrency.value.coinType,
          networkType: selectedNetwork.value.networkType,
          networkId: selectedNetwork.value.id,
        )
        .then(
          (resp) {
            if (resp.success && resp.data != null) {
              preWithdrawal.value = PreWithdraw.fromJson(resp.data);
            } else {
              showToast(resp.message);
            }
          },
          onError: (err) {
            showToast(err.toString());
          },
        );
  }

  Future<void> withdrawProcess(WithdrawalCreate withdraw) async {
    showLoadingDialog();
    APIRepository()
        .withdrawalProcess(withdraw)
        .then(
          (resp) {
            hideLoadingDialog();
            showToast(resp.message, isError: !resp.success);
            if (resp.success) Get.back();
          },
          onError: (err) {
            hideLoadingDialog();
            showToast(err.toString());
          },
        );
  }

  Future<void> getFAQList() async {
    APIRepository().getFAQList(1, type: FAQType.withdraw).then((resp) {
      if (resp.success) {
        ListResponse response = ListResponse.fromJson(resp.data);
        if (response.data != null) {
          faqList.value = List<FAQ>.from(response.data!.map((x) => FAQ.fromJson(x)));
        }
      }
    }, onError: (err) {});
  }

  Future<void> getHistoryListData() async {
    APIRepository().getActivityList(0, HistoryType.withdraw).then((resp) {
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
