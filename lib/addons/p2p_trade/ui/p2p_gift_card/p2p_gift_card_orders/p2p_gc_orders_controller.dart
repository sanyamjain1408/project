import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

import '../../../models/p2p_gift_card.dart';
import '../../../p2p_api_repository.dart';
import '../../../p2p_constants.dart';

class P2pGCOrdersController extends GetxController {
  int loadedPage = 0;
  bool hasMoreData = true;
  RxBool isDataLoading = true.obs;
  RxInt selectedOrderStatus = 0.obs;
  RxList<P2PGiftCardOrder> gcOrderList = <P2PGiftCardOrder>[].obs;

  Map<int, String> getOrderTypeMap() => {
    -1: "All".tr,
    P2pTradeStatus.timeExpired: "Time Expired".tr,
    P2pTradeStatus.escrow: "In Escrow".tr,
    P2pTradeStatus.paymentDone: "Payment Done".tr,
    P2pTradeStatus.transferDone: "Transfer Done".tr,
    P2pTradeStatus.disputed: "Disputed".tr,
    P2pTradeStatus.canceled: "Canceled".tr,
    P2pTradeStatus.refundedByAdmin: "Refund By Admin".tr,
    P2pTradeStatus.releasedByAdmin: "Released By Admin".tr,
  };


  void getP2pGiftCardOrders(bool isFromLoadMore) {
    if (!isFromLoadMore) {
      loadedPage = 0;
      hasMoreData = true;
      gcOrderList.clear();
    }
    isDataLoading.value = true;
    loadedPage++;

    final usdKey = getOrderTypeMap().keys.toList()[selectedOrderStatus.value];
    final orderStatus = usdKey == -1 ? FromKey.all : usdKey.toString();

    P2pAPIRepository().getP2pGiftCardOrders(loadedPage, orderStatus).then((resp) {
      if (resp.success && resp.data != null) {
        ListResponse listResponse = ListResponse.fromJson(resp.data);
        loadedPage = listResponse.currentPage ?? 0;
        hasMoreData = listResponse.nextPageUrl != null;
        if (listResponse.data != null) {
          List<P2PGiftCardOrder> list = List<P2PGiftCardOrder>.from(listResponse.data!.map((x) => P2PGiftCardOrder.fromJson(x)));
          gcOrderList.addAll(list);
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

}
