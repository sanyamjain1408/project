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
  RxDouble futureWalletBalance = 0.0.obs; // wallet_balance — shown in Future card
  RxDouble futureAvailableBalance = 0.0.obs; // available_balance — used in total assets + PNL base
  int walletListFromType = 0;
  Timer? searchTimer;
  Timer? _spotTimer;
  Timer? _futurePnlTimer;
  Timer? _earnTimer;

  // Stored once — like web's spotYesterday state + pnlInitDoneRef
  double _spotYesterday = 0;
  bool _snapshotFetched = false;
  double _futureCombinedPnl = 0;

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

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  @override
  void onClose() {
    _spotTimer?.cancel();
    _futurePnlTimer?.cancel();
    _earnTimer?.cancel();
    searchTimer?.cancel();
    super.onClose();
  }

  Future<void> _init() async {
    // 1. Fetch spot total + earn + future balance (initial)
    await _refreshBalances();

    // 2. If future balance still 0 (token may not have been ready), retry once
    if (futureWalletBalance.value <= 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      final (wb, avail) = await _fetchFutureBalancePair();
      if (wb > 0) futureWalletBalance.value = wb;
      if (avail > 0) futureAvailableBalance.value = avail;
    }

    // 3. Fetch yesterday snapshot ONCE — like web's pnlInitDoneRef
    await _fetchSnapshotOnce();

    // 4. Fetch future combined PNL immediately
    await _refreshFuturePnl();

    // 5. Recompute PNL display
    _recomputePnl();

    // 6. Start tickers — spot refreshes every 10s, future PNL + balance every 10s
    _spotTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _refreshSpotTotal();
      _recomputePnl();
    });
    _futurePnlTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _refreshFuturePnl(); // updates balance + PNL in one call
      _recomputePnl();
    });
    _earnTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final userId = gUserRx.value.id;
      if (userId == 0) return;
      final earn = await _fetchEarnTotal(userId);
      earnWalletTotal.value = earn;
      _recomputePnl();
    });
  }

  Future<void> _refreshFutureBalance() async {
    final (wb, avail) = await _fetchFutureBalancePair();
    if (wb > 0) futureWalletBalance.value = wb;
    if (avail > 0) futureAvailableBalance.value = avail;
  }

  // Refresh spot total only (for tick) — also updates grand total
  Future<void> _refreshSpotTotal() async {
    try {
      final resp = await APIRepository().getWalletTotalValue();
      if (resp.success) {
        final bal = TotalBalance.fromJson(resp.data);
        final newSpot = bal.total ?? spotWalletTotal.value;
        spotWalletTotal.value = newSpot;
        // Recompute grand total so Overview price also updates
        final grandTotal = newSpot + futureAvailableBalance.value + earnWalletTotal.value;
        final cur = totalBalance.value;
        totalBalance.value = TotalBalance(
          currency: cur.currency,
          total: grandTotal,
          todayPnl: cur.todayPnl,
          todayPnlPercent: cur.todayPnlPercent,
          spotPnl: cur.spotPnl,
          spotPnlPercent: cur.spotPnlPercent,
        );
      }
    } catch (_) {}
  }

  // Refresh all balances (initial load)
  Future<void> _refreshBalances() async {
    if (gUserRx.value.id == 0) return;
    final userId = gUserRx.value.id;

    final results = await Future.wait([
      APIRepository().getWalletTotalValue(),
      APIRepository().getWalletBalanceDetails(""),
      _fetchEarnTotal(userId),
      _fetchFutureBalancePair(),
    ]);

    final spotResp = results[0] as dynamic;
    final overviewResp = results[1] as dynamic;
    final earnTotal = results[2] as double;
    final (fetchedWalletBal, fetchedAvailBal) = results[3] as (double, double);

    double spotVal = 0;
    double futureWalletVal = 0; // wallet_balance — shown in Future card
    double futureAvailVal = 0;  // available_balance — used in total assets (matches website)
    double p2pVal = 0;
    String? currency;

    if (spotResp.success) {
      final bal = TotalBalance.fromJson(spotResp.data);
      spotVal = bal.total ?? 0;
      currency = bal.currency;
    }
    if (overviewResp.success) {
      final ov = WalletOverview.fromJson(overviewResp.data);
      futureWalletVal = ov.futureWallet ?? 0;
      futureAvailVal = ov.futureWallet ?? 0;
      p2pVal = ov.p2PWallet ?? 0;
    }
    if (fetchedWalletBal > 0) futureWalletVal = fetchedWalletBal;
    if (fetchedAvailBal > 0) futureAvailVal = fetchedAvailBal;

    spotWalletTotal.value = spotVal;
    earnWalletTotal.value = earnTotal;
    futureWalletBalance.value = futureWalletVal;
    futureAvailableBalance.value = futureAvailVal;

    // Total assets = Spot + FutureAvailable + Earn + P2P (matches website formula)
    final grandTotal = spotVal + futureAvailVal + earnTotal + p2pVal;
    final cur = totalBalance.value;
    totalBalance.value = TotalBalance(
      currency: currency ?? cur.currency,
      total: grandTotal,
      todayPnl: cur.todayPnl,
      todayPnlPercent: cur.todayPnlPercent,
      spotPnl: cur.spotPnl,
      spotPnlPercent: cur.spotPnlPercent,
    );
  }

  // Fetch snapshot ONCE — stores yesterday_value, never called again (like pnlInitDoneRef)
  Future<void> _fetchSnapshotOnce() async {
    if (_snapshotFetched) return;
    final userId = gUserRx.value.id;
    if (userId == 0) return;
    final spotVal = spotWalletTotal.value;
    if (spotVal <= 0) return;
    try {
      final uri = Uri.parse(
        '${APIURLConstants.baseUrl}/api/pnl/summary?user_id=$userId&live_total=${spotVal.toStringAsFixed(2)}',
      );
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json['success'] == true) {
          final yv = double.tryParse(json['data']?['yesterday_value']?.toString() ?? '0') ?? 0;
          if (yv > 0) {
            _spotYesterday = yv;
            _snapshotFetched = true;
          }
        }
      }
    } catch (_) {}
  }

  // Fetch future PNL + balance together (both come from same endpoint)
  Future<void> _refreshFuturePnl() async {
    try {
      final token = getFutureToken();
      if (token.isEmpty) return;
      // Use /wallet-details-balance — same as website (has today_pnl, total_balance, available_balance)
      final resp = await http.get(
        Uri.parse('https://api.trapix.com/api/v1/future/wallet-details-balance'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json['success'] == true) {
          final d = json['data'] ?? {};
          // today_pnl from /wallet-details-balance (matches FutureUserBalance interface)
          final todayPnl = double.tryParse(d['today_pnl']?.toString() ?? '0') ?? 0;
          _futureCombinedPnl = todayPnl;
          // Also update balances from same response
          final totalBal = double.tryParse(d['total_balance']?.toString() ?? '0') ?? 0;
          final availBal = double.tryParse(d['available_balance']?.toString() ?? '0') ?? 0;
          // Website: realFutureBalance = total_balance ?? available_balance
          final cardBal = totalBal > 0 ? totalBal : availBal;
          if (cardBal > 0) futureWalletBalance.value = cardBal;
          if (availBal > 0) {
            futureAvailableBalance.value = availBal;
            // Recompute grand total with updated future available
            final grandTotal = spotWalletTotal.value + availBal + earnWalletTotal.value;
            final cur = totalBalance.value;
            totalBalance.value = TotalBalance(
              currency: cur.currency,
              total: grandTotal,
              todayPnl: cur.todayPnl,
              todayPnlPercent: cur.todayPnlPercent,
              spotPnl: cur.spotPnl,
              spotPnlPercent: cur.spotPnlPercent,
            );
          }
        }
      }
    } catch (_) {}
  }

  // Recompute PNL from stored values — pure math, no API call (like web's useEffect)
  void _recomputePnl() {
    if (_spotYesterday <= 0) return;
    final spotVal = spotWalletTotal.value;
    final yv = _spotYesterday;
    // Website: PNL base uses available_balance (not wallet_balance)
    final futureAvail = futureAvailableBalance.value;

    final spotPnl = spotVal - yv;
    final spotPct = yv > 0 ? (spotPnl / yv) * 100 : 0.0;

    final totalPnl = spotPnl + _futureCombinedPnl;
    final base = yv + futureAvail;
    final totalPct = base > 0 ? (totalPnl / base) * 100 : 0.0;

    final cur = totalBalance.value;
    totalBalance.value = TotalBalance(
      currency: cur.currency,
      total: cur.total,
      todayPnl: totalPnl,
      todayPnlPercent: totalPct,
      spotPnl: spotPnl,
      spotPnlPercent: spotPct,
    );
  }

  // Called by pages for manual refresh (pull-to-refresh)
  Future<void> fetchGrandTotal() async {
    await _refreshBalances();
    if (futureWalletBalance.value <= 0) await _refreshFutureBalance();
    if (!_snapshotFetched) await _fetchSnapshotOnce();
    await _refreshFuturePnl();
    _recomputePnl();
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
          total += double.tryParse(p['accrued_interest']?.toString() ?? '0') ?? 0;
        }
        return total;
      }
    } catch (_) {}
    return 0;
  }

  // Returns (wallet_balance, available_balance) — both needed for different purposes
  Future<(double, double)> _fetchFutureBalancePair() async {
    try {
      final token = getFutureToken();
      if (token.isEmpty) return (0.0, 0.0);
      // Primary: /wallet-details-balance — same as website's useFutureWalletDetailsBalance()
      final resp = await http.get(
        Uri.parse('https://api.trapix.com/api/v1/future/wallet-details-balance'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json['success'] == true) {
          final d = json['data'] ?? {};
          final totalBal = double.tryParse(d['total_balance']?.toString() ?? '0') ?? 0;
          final availBal = double.tryParse(d['available_balance']?.toString() ?? '0') ?? 0;
          // Website: realFutureBalance = total_balance ?? available_balance
          final cardBal = totalBal > 0 ? totalBal : availBal;
          return (cardBal, availBal);
        }
      }
      // Fallback: /balance endpoint if /wallet-details-balance fails
      final resp2 = await http.get(
        Uri.parse('https://api.trapix.com/api/v1/future/balance'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp2.statusCode == 200) {
        final json2 = jsonDecode(resp2.body);
        if (json2['success'] == true) {
          final d2 = json2['data'] ?? {};
          final wb = double.tryParse(d2['wallet_balance']?.toString() ?? '0') ?? 0;
          final avail = double.tryParse(d2['available']?.toString() ?? '0') ?? 0;
          final legacyAvail = double.tryParse(d2['balance']?.toString() ?? '0') ?? 0;
          final effectiveAvail = avail > 0 ? avail : legacyAvail;
          return (wb, effectiveAvail);
        }
      }
    } catch (_) {}
    return (0.0, 0.0);
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
                if (wallets != null) {
                  listResponse = ListResponse.fromJson(wallets);
                }
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

  Future<TotalBalance?> getWalletTotalValue() async {
    try {
      final resp = await APIRepository().getWalletTotalValue();
      if (resp.success) {
        final bal = TotalBalance.fromJson(resp.data);
        // Only update spot total — don't overwrite grand total/PNL
        spotWalletTotal.value = bal.total ?? spotWalletTotal.value;
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
