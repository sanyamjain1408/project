import 'package:get/get.dart';
import '../../../../data/models/blog_news.dart';
import '../../../../data/models/settings.dart';
import '../../../../data/remote/api_repository.dart';
import '../../../../utils/common_utils.dart';
import '../../../../data/local/api_constants.dart';
import '../../../../data/remote/socket_provider.dart';
import '../../../../helper/data_process_helper.dart';

class LandingController extends GetxController implements SocketListener {
  Rx<LandingData> landingData = LandingData().obs;
  Rx<LandingList> landingList = LandingList().obs;
  RxBool isLoading = false.obs;
  RxInt selectedTab = 0.obs;
  RxList<Blog> latestBlogList = <Blog>[].obs;

  @override
  void onDataGet(channel, event, data) {
    if (channel == SocketConstants.channelMarketCoinPairData && event == SocketConstants.eventMarketCoinPair) {
      if (data is Map<String, dynamic>) {
        landingList.value = LandingList.fromJson(data);
      }
    }
  }

  void handleSocketChannels(bool isSubscribe) {
    isSubscribe
        ? APIRepository().subscribeEvent(SocketConstants.channelMarketCoinPairData, this)
        : APIRepository().unSubscribeEvent(SocketConstants.channelMarketCoinPairData, this);
  }

  void getLandingSettings() async {
    isLoading.value = true;
    APIRepository().getCommonSettings().then(
      (resp) {
        isLoading.value = false;
        if (resp.success && resp.data != null && resp.data is Map<String, dynamic>) {
          DataProcessHelper.commonSettingsProcess(
            resp.data,
            onSettings: (landingSettings) {
              if (landingSettings != null) {
                landingData.value = landingSettings;
                landingList.value = LandingList.fromJson(resp.data);
              }
            },
          );
        }
        handleSocketChannels(true);
      },
      onError: (err) {
        isLoading.value = false;
        showToast(err.toString());
      },
    );
  }

  void getLatestBlogList() async {
    APIRepository().getLatestBlogList().then(
      (resp) {
        if (resp.success && resp.data != null) {
          latestBlogList.value = List<Blog>.from(resp.data.map((x) => Blog.fromJson(x)));
        }
      },
      onError: (err) {
        showToast(err.toString());
      },
    );
  }
}
