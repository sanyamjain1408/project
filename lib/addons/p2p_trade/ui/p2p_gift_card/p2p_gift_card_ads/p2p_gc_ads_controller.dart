import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

import '../../../models/p2p_gift_card.dart';
import '../../../p2p_api_repository.dart';
import '../../../p2p_constants.dart';

class P2pGCAdsController extends GetxController {
  int loadedPage = 0;
  bool hasMoreData = true;
  RxBool isDataLoading = true.obs;
  RxInt selectedOrderStatus = 0.obs;
  RxList<P2PGiftCardAd> gcOrderList = <P2PGiftCardAd>[].obs;

  Map<int, String> getOrderTypeMap() => {
        -1: "All".tr,
        P2pGiftCardStatus.deActive: "Deactivate".tr,
        P2pGiftCardStatus.active: "Active".tr,
        P2pGiftCardStatus.success: "Success".tr,
        P2pGiftCardStatus.canceled: "Canceled".tr,
        P2pGiftCardStatus.onGoing: "Ongoing".tr
      };

  void getP2pGiftCardUserAdList(bool isFromLoadMore) {
    if (!isFromLoadMore) {
      loadedPage = 0;
      hasMoreData = true;
      gcOrderList.clear();
    }
    isDataLoading.value = true;
    loadedPage++;

    final usdKey = getOrderTypeMap().keys.toList()[selectedOrderStatus.value];
    final orderStatus = usdKey == -1 ? FromKey.all : usdKey.toString();

    P2pAPIRepository().getP2pGiftCardUserAdList(loadedPage, orderStatus).then((resp) {
      if (resp.success && resp.data != null) {
        ListResponse listResponse = ListResponse.fromJson(resp.data);
        loadedPage = listResponse.currentPage ?? 0;
        hasMoreData = listResponse.nextPageUrl != null;
        if (listResponse.data != null) {
          List<P2PGiftCardAd> list = List<P2PGiftCardAd>.from(listResponse.data!.map((x) => P2PGiftCardAd.fromJson(x)));
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

  Future<void> p2pGiftCardDeleteAd(P2PGiftCardAd giftCard) async {
    showLoadingDialog();
    P2pAPIRepository().p2pGiftCardDeleteAd(giftCard.id ?? 0).then((resp) {
      hideLoadingDialog();
      showToast(resp.message, isError: !resp.success);
      if (resp.success) {
        Get.back();
        gcOrderList.remove(giftCard);
      }
    }, onError: (err) {
      hideLoadingDialog();
      showToast(err.toString());
    });
  }
}
