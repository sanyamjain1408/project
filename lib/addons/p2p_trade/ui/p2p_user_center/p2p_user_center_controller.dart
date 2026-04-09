import 'package:get/get.dart';

import '../../../../utils/common_utils.dart';
import '../../models/p2p_ads.dart';
import '../../models/p2p_profile_details.dart';
import '../../p2p_api_repository.dart';

class P2pUserCenterController extends GetxController {
  P2PProfileDetails profileDetails = P2PProfileDetails();
  RxBool isDataLoading = false.obs;
  RxInt selectedTab = 0.obs;
  RxList<P2pFeedback> feedBackList = <P2pFeedback>[].obs;
  RxList<P2pPaymentInfo> paymentInfoList = <P2pPaymentInfo>[].obs;

  void getUserCenter() {
    isDataLoading.value = true;
    P2pAPIRepository().getP2pUserCenter().then((resp) {
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
