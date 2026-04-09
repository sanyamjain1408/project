import 'package:get/get.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/models/p2p_profile_details.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';

import '../../p2p_api_repository.dart';

class P2pProfileController extends GetxController {
  P2PProfileDetails profileDetails = P2PProfileDetails();
  RxBool isDataLoading = false.obs;
  RxInt selectedTab = 0.obs;
  RxList<P2pFeedback> feedBackList = <P2pFeedback>[].obs;

  void getProfileDetails(int userId) {
    isDataLoading.value = true;
    P2pAPIRepository().getProfileDetails(userId).then((resp) {
      if (resp.success && resp.data != null) {
        profileDetails = P2PProfileDetails.fromJson(resp.data);
      } else {
        showToast(resp.message);
      }
      isDataLoading.value = false;
      getFeedBackList(0);
    }, onError: (err) {
      isDataLoading.value = false;
      showToast(err.toString());
    });
  }

  void getFeedBackList(int index) {
    selectedTab.value = index;
    if (index == 0) {
      feedBackList.value = profileDetails.feedbackList ?? [];
    } else {
      final type = index == 1 ? 1 : 2;
      final list = profileDetails.feedbackList?.where((e) => e.feedbackType == type).toList();
      feedBackList.value = list ?? [];
    }
  }
}
