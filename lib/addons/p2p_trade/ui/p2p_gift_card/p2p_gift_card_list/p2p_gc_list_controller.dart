import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/models/gift_card.dart';
import 'package:tradexpro_flutter/data/models/list_response.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

import '../../../models/p2p_gift_card.dart';
import '../../../p2p_api_repository.dart';

class P2pGCListController extends GetxController {
  int loadedPage = 0;
  bool hasMoreData = true;
  RxBool isDataLoading = true.obs;
  RxList<P2pGiftCard> giftCardList = <P2pGiftCard>[].obs;

  void getP2pGiftCardList(bool isFromLoadMore) {
    if (!isFromLoadMore) {
      loadedPage = 0;
      hasMoreData = true;
      giftCardList.clear();
    }
    isDataLoading.value = true;
    loadedPage++;
    P2pAPIRepository().getP2pGiftCardList(loadedPage).then((resp) {
      if (resp.success && resp.data != null) {
        ListResponse listResponse = ListResponse.fromJson(resp.data);
        loadedPage = listResponse.currentPage ?? 0;
        hasMoreData = listResponse.nextPageUrl != null;
        if (listResponse.data != null) {
          List<P2pGiftCard> list =
              List<P2pGiftCard>.from(listResponse.data!.map((x) => P2pGiftCard(giftCardId: x[APIKeyConstants.id], giftCard: GiftCard.fromJson(x))));
          giftCardList.addAll(list);
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
