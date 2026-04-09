import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/dashboard_data.dart';
import 'package:tradexpro_flutter/data/models/response.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/data/models/wallet.dart';
import 'package:tradexpro_flutter/data/models/coin_pair.dart';
import 'package:tradexpro_flutter/data/remote/api_repository.dart';

class WalletController extends GetxController with GetSingleTickerProviderStateMixin {
  final refreshController = EasyRefreshController(controlFinishRefresh: true);
  final searchController = TextEditingController();
  TabController? tabController;
  List<CoinPair> coinPairs = [];
  RxInt selectedTypeIndex = 0.obs;
  int loadedPage = 0;
  bool hasMoreData = false;
  RxList<Wallet> walletList = <Wallet>[].obs;
  Rx<TotalBalance> totalBalance = TotalBalance().obs;
  int walletListFromType = 0;
  Timer? searchTimer;

  Map<int, String> getTypeMap() {
    final settings = getSettingsLocal();
    var map = {WalletViewType.overview: "Overview".tr, WalletViewType.spot: "Spot".tr};
    if (settings?.enableFutureTrade == 1) map[WalletViewType.future] = "Futures".tr;
    if (settings?.p2pModule == 1) map[WalletViewType.p2p] = "P2P".tr;
    map[WalletViewType.checkDeposit] = "Check Deposit".tr;
    return map;
  }

  void changeWalletTab(int type) {
    final index = getTypeMap().keys.toList().indexOf(type);
    if (index != -1) selectedTypeIndex.value = index;
    tabController?.animateTo(index);
  }

  Future<void> getWalletOverviewData(Function(WalletOverview) onData, {String? coinType}) async {
    if (gUserRx.value.id == 0) {
      refreshController.finishRefresh();
      return;
    }
    APIRepository().getWalletBalanceDetails(coinType ?? "").then((resp) {
      refreshController.finishRefresh();
      resp.success ? onData(WalletOverview.fromJson(resp.data)) : showToast(resp.message);
    }, onError: (err) {
      refreshController.finishRefresh();
      showToast(err.toString());
    });
  }

  void clearListView() {
    loadedPage = 0;
    hasMoreData = false;
    walletList.clear();
  }

  Future<void> getWalletList(int type, Function() onCompleted, {bool isFromLoadMore = false}) async {
    if (gUserRx.value.id == 0) return;
    if (!isFromLoadMore) clearListView();
    loadedPage++;
    final search = searchController.text.trim();
    APIRepository().getWalletList(loadedPage, type: type, search: search).then((resp) {
      if (resp.success) {
        ListResponse? listResponse;
        if (type == WalletViewType.spot) {
          final wallets = resp.data[APIKeyConstants.wallets];
          if (wallets != null) listResponse = ListResponse.fromJson(wallets);
        } else {
          listResponse = ListResponse.fromJson(resp.data);
        }
        if (listResponse != null) {
          loadedPage = listResponse.currentPage ?? 0;
          hasMoreData = listResponse.nextPageUrl != null;
          if (listResponse.data != null) {
            List<Wallet> list = List<Wallet>.from(listResponse.data!.map((x) => Wallet.fromJson(x)));
            walletList.addAll(list);
          }
        }
        if (type == WalletViewType.spot) getDashBoardData();
      } else {
        showToast(resp.message);
      }
      onCompleted();
    }, onError: (err) {
      onCompleted();
      showToast(err.toString());
    });
  }

  void getWalletTotalValue() async {
    APIRepository().getWalletTotalValue().then((resp) {
      if (resp.success) {
        totalBalance.value = TotalBalance.fromJson(resp.data);
      }
    }, onError: (err) {});
  }

  void getDashBoardData() async {
    if (coinPairs.isNotEmpty) return;
    APIRepository().getDashBoardData("").then((resp) {
      if (resp.success) {
        final dashboardData = DashboardData.fromJson(resp.data);
        coinPairs = dashboardData.coinPairs ?? [];
      }
    }, onError: (err) {});
  }

  List<String> getCoinPairList(String text) {
    final pairList = coinPairs.where((element) => (element.coinPairName ?? "").toLowerCase().contains(text.toLowerCase())).toList();
    return pairList.map((e) => e.coinPairName ?? "").toList();
  }

  void transferWalletAmount(Wallet wallet, int walletType, double amount, bool isSend) async {
    showLoadingDialog();
    try {
      ServerResponse? resp;
      if (walletType == WalletViewType.future) {
        /// spot_wallet =1 or future_wallet =2
        resp = await APIRepository().futureTradeWalletBalanceTransfer(isSend ? 2 : 1, wallet.coinType ?? "", amount);
      } else if (walletType == WalletViewType.p2p) {
        resp = await APIRepository().p2pWalletBalanceTransfer(wallet.coinType ?? "", amount, isSend ? 1 : 2);
      }
      hideLoadingDialog();
      if (resp != null && resp.success) {
        final success = resp.data[APIKeyConstants.success] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) {
          Get.back();
          Future.delayed(const Duration(seconds: 1), () => refreshController.callRefresh());
        }
      }
    } catch (err) {
      hideLoadingDialog();
      showToast(err.toString());
    }
  }

}
