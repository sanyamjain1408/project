import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/p2p_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/response.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';

import '../../models/p2p_order.dart';
import '../../p2p_api_repository.dart';

class P2POrdersController extends GetxController {
  P2PMyOrdersSettings settings = P2PMyOrdersSettings();
  RxList<P2POrder> ordersList = <P2POrder>[].obs;
  RxInt selectedTab = 0.obs;
  RxInt selectedCoin = 0.obs;
  RxInt selectedOrderStatus = 0.obs;
  int loadedPage = 0;
  bool hasMoreData = true;
  RxBool isLoading = true.obs;
  bool hasFilterChanged = false;
  Rx<String> startDate = "".obs;
  Rx<String> endDate = "".obs;

  Map<int, String> getOrderTypeMap() => {
        -1: "All".tr,
        P2pTradeStatus.timeExpired: "Time Expired".tr,
        P2pTradeStatus.escrow: "In Escrow".tr,
        P2pTradeStatus.paymentDone: "Payment Done".tr,
        P2pTradeStatus.transferDone: "Transfer Done".tr,
        P2pTradeStatus.canceled: "Canceled".tr,
        P2pTradeStatus.refundedByAdmin: "Refund By Admin".tr,
        P2pTradeStatus.releasedByAdmin: "Released By Admin".tr,
      };

  Future<void> getOrderSettings(Function() onSuccess) async {
    P2pAPIRepository().getP2pMyOrderListSettings().then((resp) {
      if (resp.success && resp.data != null) {
        settings = P2PMyOrdersSettings.fromJson(resp.data);
        onSuccess();
        getOrdersData(false);
      } else {
        showToast(resp.message);
      }
    }, onError: (err) {
      showToast(err.toString());
    });
  }

  List<String> getCoinNameList() {
    List<String> list = [];
    if (settings.coins.isValid) {
      list = settings.coins!.map((e) => e.coinType ?? "").toList();
    }
    list.insert(0, "All".tr);
    return list;
  }

  void checkFilterChange() {
    if (hasFilterChanged) {
      getOrdersData(false);
      hasFilterChanged = false;
    }
  }

  void getOrdersData(bool isFromLoadMore) {
    if (!isFromLoadMore) {
      loadedPage = 0;
      hasMoreData = true;
      ordersList.clear();
    }
    isLoading.value = true;
    loadedPage++;

    selectedTab.value == 0 ? getOrdersList() : getDisputeList();
  }

  Future<void> getOrdersList() async {
    final cMap = getOrderTypeMap();
    final value = cMap.values.toList()[selectedOrderStatus.value];
    final usdKey = cMap.keys.firstWhere((k) => cMap[k] == value, orElse: () => -1);
    final orderStatus = usdKey == -1 ? FromKey.all : usdKey.toString();
    final coin = selectedCoin.value == 0 ? FromKey.all : settings.coins?[selectedCoin.value - 1].coinType ?? FromKey.all;

    P2pAPIRepository().getP2pMyOrdersList(loadedPage, orderStatus, coin, startDate.value, endDate.value).then((resp) {
      handleListResponse(resp);
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  Future<void> getDisputeList() async {
    P2pAPIRepository().getP2pMyDisputeList(loadedPage).then((resp) {
      handleListResponse(resp);
    }, onError: (err) {
      isLoading.value = false;
      showToast(err.toString());
    });
  }

  void handleListResponse(ServerResponse resp) {
    if (resp.success && resp.data != null) {
      ListResponse listResponse = ListResponse.fromJson(resp.data);
      loadedPage = listResponse.currentPage ?? 0;
      hasMoreData = listResponse.nextPageUrl != null;
      if (listResponse.data != null) {
        List<P2POrder> list = List<P2POrder>.from(listResponse.data!.map((x) => P2POrder.fromJson(x)));
        ordersList.addAll(list);
      }
      isLoading.value = false;
    } else {
      showToast(resp.message);
    }
  }
}
