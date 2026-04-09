import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

import '../../p2p_api_repository.dart';

class P2pWalletController extends GetxController {
  int loadedPage = 0;
  bool hasMoreData = true;
  RxBool isDataLoading = true.obs;
  RxList<Wallet> walletList = <Wallet>[].obs;
  List<Wallet> walletListMain = [];

  void getP2pWalletsList(bool isFromLoadMore) {
    if (!isFromLoadMore) {
      loadedPage = 0;
      hasMoreData = true;
      walletListMain.clear();
      walletList.clear();
    }
    isDataLoading.value = true;
    loadedPage++;
    P2pAPIRepository().getP2pWallets(loadedPage).then((resp) {
      if (resp.success && resp.data != null) {
        ListResponse listResponse = ListResponse.fromJson(resp.data);
        loadedPage = listResponse.currentPage ?? 0;
        hasMoreData = listResponse.nextPageUrl != null;
        if (listResponse.data != null) {
          List<Wallet> list = List<Wallet>.from(listResponse.data!.map((x) => Wallet.fromJson(x)));
          walletListMain.addAll(list);
          searchWallets("");
        }
      } else {
        showToast(resp.message);
      }
      isDataLoading.value = false;
    }, onError: (err) {
      isDataLoading.value = false;
      showToast(err.toString());
    });
  }

  void searchWallets(String query) {
    final text = query.trim().toLowerCase();
    var list = walletListMain;
    if (query.isNotEmpty) {
      list = walletListMain
          .where((e) =>
              (e.name ?? "").toLowerCase().contains(text) ||
              (e.coinType ?? "").toLowerCase().contains(text) ||
              (e.balance ?? 0).toString().contains(text))
          .toList();
    }
    walletList.value = list;
  }

  void transferAmount(Wallet wallet, double amount, bool isSend) {
    showLoadingDialog();

    P2pAPIRepository().transferWalletBalance(wallet.coinType ?? "", amount, isSend ? 1 : 2).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        Get.back();
        Future.delayed(const Duration(seconds: 3), () => getP2pWalletsList(false));
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }
}
