import 'dart:async';
import 'dart:convert';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
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
import 'package:tradexpro_flutter/ui/features/bottom_navigation/trades/future_trade/future_models.dart';

class WalletController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final refreshController = EasyRefreshController(controlFinishRefresh: true);
  final searchController = TextEditingController();
  TabController? tabController;
  List<CoinPair> coinPairs = [];
  RxInt selectedTypeIndex = 0.obs;
  int loadedPage = 0;
  bool hasMoreData = false;
  RxList<Wallet> walletList = <Wallet>[].obs;
  Rx<TotalBalance> totalBalance = TotalBalance().obs;
  RxDouble spotWalletTotal = 0.0.obs;
  RxDouble earnWalletTotal = 0.0.obs;
  RxDouble futureWalletBalance = 0.0.obs;
  RxDouble spotYesterdayValue = 0.0.obs;
  RxDouble futureCombinedPnl = 0.0.obs;
  int walletListFromType = 0;
  Timer? searchTimer;
  Timer? _pnlTimer;

  Map<int, String> getTypeMap() {
    final settings = getSettingsLocal();
    var map = {
      WalletViewType.overview: "Overview".tr,
      WalletViewType.spot: "Spot".tr,
    };
    if (settings?.enableFutureTrade == 1)
      map[WalletViewType.future] = "Futures".tr;
    if (settings?.p2pModule == 1) map[WalletViewType.p2p] = "P2P".tr;
    map[WalletViewType.checkDeposit] = "Check Deposit".tr;
    return map;
  }

  void changeWalletTab(int type) {
    final index = getTypeMap().keys.toList().indexOf(type);
    if (index != -1) selectedTypeIndex.value = index;
    tabController?.animateTo(index);
  }

  Future<WalletOverview?> getWalletOverviewData({String? coinType}) async {
    if (gUserRx.value.id == 0) {
      refreshController.finishRefresh();
      return null;
    }
    try {
      final resp = await APIRepository().getWalletBalanceDetails(coinType ?? "");
      refreshController.finishRefresh();
      if (resp.success) return WalletOverview.fromJson(resp.data);
      showToast(resp.message);
    } catch (err) {
      refreshController.finishRefresh();
      showToast(err.toString());
    }
    return null;
  }

  void clearListView() {
    loadedPage = 0;
    hasMoreData = false;
    walletList.clear();
  }

  Future<void> getWalletList(
    int type,
    Function() onCompleted, {
    bool isFromLoadMore = false,
  }) async {
    if (gUserRx.value.id == 0) return;
    if (!isFromLoadMore) clearListView();
    loadedPage++;
    final search = searchController.text.trim();
    APIRepository()
        .getWalletList(loadedPage, type: type, search: search)
        .then(
          (resp) {
            if (resp.success) {
              ListResponse? listResponse;
              if (type == WalletViewType.spot) {
                final wallets = resp.data[APIKeyConstants.wallets];
                if (wallets != null)
                  listResponse = ListResponse.fromJson(wallets);
              } else {
                listResponse = ListResponse.fromJson(resp.data);
              }
              if (listResponse != null) {
               

                
                loadedPage = listResponse.currentPage ?? 0;
                hasMoreData = listResponse.nextPageUrl != null;
                if (listResponse.data != null) {
                  List<Wallet> list = List<Wallet>.from(
                    listResponse.data!.map((x) => Wallet.fromJson(x)),
                  );
                  walletList.addAll(list);
                }
              }
              if (type == WalletViewType.spot) getDashBoardData();
            } else {
              showToast(resp.message);
            }
            onCompleted();
          },
          onError: (err) {
            onCompleted();
            showToast(err.toString());
          },
        );
  }

  @override
  void onInit() {
    super.onInit();
    fetchGrandTotal();
    _pnlTimer = Timer.periodic(const Duration(seconds: 10), (_) => fetchGrandTotal());
  }

  @override
  void onClose() {
    _pnlTimer?.cancel();
    searchTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchGrandTotal() async {
    if (gUserRx.value.id == 0) return;
    final userId = gUserRx.value.id;

    final spotFuture = APIRepository().getWalletTotalValue();
    final overviewFuture = APIRepository().getWalletBalanceDetails("");
    final earnFuture = _fetchEarnTotal(userId);
    final futureFuture = _fetchFutureBalance();

    final spotResp = await spotFuture;
    final overviewResp = await overviewFuture;
    final earnTotal = await earnFuture;
    final fetchedFutureVal = await futureFuture;

    double spotVal = 0;
    double futureVal = 0;
    double p2pVal = 0;
    String? currency;

    if (spotResp.success) {
      final bal = TotalBalance.fromJson(spotResp.data);
      spotVal = bal.total ?? 0;
      currency = bal.currency;
    }
    if (overviewResp.success) {
      final ov = WalletOverview.fromJson(overviewResp.data);
      futureVal = ov.futureWallet ?? 0;
      p2pVal = ov.p2PWallet ?? 0;
    }

    // Use live future balance if fetched successfully
    if (fetchedFutureVal > 0) futureVal = fetchedFutureVal;

    spotWalletTotal.value = spotVal;
    earnWalletTotal.value = earnTotal;
    futureWalletBalance.value = futureVal;

    final grandTotal = spotVal + futureVal + earnTotal + p2pVal;

    // Fetch future combined PNL (unrealized + today realized)
    final futurePnl = await _fetchFutureCombinedPnl();
    futureCombinedPnl.value = futurePnl;

    // Spot PNL: pass spot-only value to snapshot API
    final pnlResult = await _fetchTodayPnl(userId, spotVal);
    final yv = pnlResult[2]; // yesterday_value
    spotYesterdayValue.value = yv > 0 ? yv : spotVal;

    // Total PNL = spot PNL + future combined PNL
    final spotPnl = pnlResult[0];
    final totalPnl = spotPnl + futurePnl;
    final base = spotYesterdayValue.value + futureVal;
    final totalPct = base > 0 ? (totalPnl / base) * 100 : 0.0;

    final cur = totalBalance.value;
    totalBalance.value = TotalBalance(
      currency: currency ?? cur.currency,
      total: grandTotal,
      todayPnl: totalPnl,
      todayPnlPercent: totalPct,
      spotPnl: spotPnl,
      spotPnlPercent: spotYesterdayValue.value > 0 ? (spotPnl / spotYesterdayValue.value) * 100 : 0.0,
    );
  }

  // Returns [spotPnl, spotPct, yesterdayValue]
  Future<List<double>> _fetchTodayPnl(int userId, double liveTotal) async {
    try {
      final uri = Uri.parse(
        '\${APIURLConstants.baseUrl}/api/pnl/summary?user_id=\$userId&live_total=\${liveTotal.toStringAsFixed(2)}',
      );
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json['success'] == true) {
          final data = json['data'];
          final pnl = double.tryParse(data['today_pnl']?.toString() ?? '0') ?? 0;
          final pct = double.tryParse(data['today_pct']?.toString() ?? '0') ?? 0;
          final yv = double.tryParse(data['yesterday_value']?.toString() ?? '0') ?? 0;
          return [pnl, pct, yv];
        }
      }
    } catch (_) {}
    return [0, 0, 0];
  }

  Future<double> _fetchFutureCombinedPnl() async {
    try {
      final token = getFutureToken();
      if (token.isEmpty) return 0;
      final resp = await http.get(
        Uri.parse('https://api.trapix.com/api/v1/future/balance'),
        headers: {'Authorization': 'Bearer \$token'},
      );
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json['success'] == true) {
          final d = json['data'] ?? {};
          final unreal = double.tryParse(d['unrealized_pnl']?.toString() ?? '0') ?? 0;
          final realized = double.tryParse(d['today_realized_pnl']?.toString() ?? '0') ?? 0;
          return unreal + realized;
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<double> _fetchEarnTotal(int userId) async {
    try {
      final uri = Uri.parse(
        '${APIURLConstants.baseUrl}/api/tf/earn/positions?user_id=$userId',
      );
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final data = json['data'] as List? ?? [];
        double total = 0;
        for (final p in data) {
          total += double.tryParse(p['amount']?.toString() ?? '0') ?? 0;
        }
        return total;
      }
    } catch (_) {}
    return 0;
  }

  Future<double> _fetchFutureBalance() async {
    try {
      final token = getFutureToken();
      if (token.isEmpty) return 0;
      final resp = await http.get(
        Uri.parse('https://api.trapix.com/api/v1/future/balance'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json['success'] == true) {
          return double.tryParse(json['data']?['balance']?.toString() ?? '0') ?? 0;
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<TotalBalance?> getWalletTotalValue() async {
    try {
      final resp = await APIRepository().getWalletTotalValue();
      if (resp.success) {
        final bal = TotalBalance.fromJson(resp.data);
        totalBalance.value = bal;
        return bal;
      }
    } catch (_) {}
    return null;
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
    final pairList = coinPairs
        .where(
          (element) => (element.coinPairName ?? "").toLowerCase().contains(
            text.toLowerCase(),
          ),
        )
        .toList();
    return pairList.map((e) => e.coinPairName ?? "").toList();
  }

  void transferWalletAmount(
    Wallet wallet,
    int walletType,
    double amount,
    bool isSend,
  ) async {
    showLoadingDialog();
    try {
      ServerResponse? resp;
      if (walletType == WalletViewType.future) {
        /// spot_wallet =1 or future_wallet =2
        resp = await APIRepository().futureTradeWalletBalanceTransfer(
          isSend ? 2 : 1,
          wallet.coinType ?? "",
          amount,
        );
      } else if (walletType == WalletViewType.p2p) {
        resp = await APIRepository().p2pWalletBalanceTransfer(
          wallet.coinType ?? "",
          amount,
          isSend ? 1 : 2,
        );
      }
      hideLoadingDialog();
      if (resp != null && resp.success) {
        final success = resp.data[APIKeyConstants.success] as bool? ?? false;
        final message = resp.data[APIKeyConstants.message] as String? ?? "";
        showToast(message, isError: !success);
        if (success) {
          Get.back();
          Future.delayed(
            const Duration(seconds: 1),
            () => refreshController.callRefresh(),
          );
        }
      }
    } catch (err) {
      hideLoadingDialog();
      showToast(err.toString());
    }
  }
}
