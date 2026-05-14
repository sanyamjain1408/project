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
          // debugPrint('=== [LANDING] Raw backend response keys: ${(resp.data as Map).keys.toList()}');
          DataProcessHelper.commonSettingsProcess(
            resp.data,
            onSettings: (landingSettings) {
              if (landingSettings != null) {
                landingData.value = landingSettings;
                landingList.value = LandingList.fromJson(resp.data);

                // --- ANNOUNCEMENT LOG ---
                // final announcements = landingSettings.announcementList;
                // debugPrint('=== [ANNOUNCEMENT] Count: ${announcements?.length ?? 0}');
                // if (announcements != null && announcements.isNotEmpty) {
                //   for (int i = 0; i < announcements.length; i++) {
                //     final a = announcements[i];
                //     debugPrint('  [ANNOUNCEMENT $i] id=${a.id} | title=${a.title} | slug=${a.slug} | image=${a.image} | updatedAt=${a.updatedAt}');
                //     debugPrint('  [ANNOUNCEMENT $i] description (first 200): ${(a.description ?? '').substring(0, (a.description ?? '').length > 200 ? 200 : (a.description ?? '').length)}');
                //   }
                // } else {
                //   debugPrint('  [ANNOUNCEMENT] No announcements received from backend.');
                // }

                // --- BANNER LOG ---
                // final banners = landingSettings.bannerList;
                // debugPrint('=== [BANNER] Count: ${banners?.length ?? 0}');
                // if (banners != null && banners.isNotEmpty) {
                //   for (int i = 0; i < banners.length; i++) {
                //     final b = banners[i];
                //     debugPrint('  [BANNER $i] id=${b.id} | title=${b.title} | image=${b.image}');
                //   }
                // }
              }
            },
          );
        }
        handleSocketChannels(true);
      },
      onError: (err) {
        isLoading.value = false;
        // debugPrint('=== [LANDING] Error: $err');
        showToast(err.toString());
      },
    );
  }

  void getLatestBlogList() async {
    APIRepository().getLatestBlogList().then(
      (resp) {
        if (resp.success && resp.data != null) {
          latestBlogList.value = List<Blog>.from(resp.data.map((x) => Blog.fromJson(x)));

          // --- BLOG LOG ---
          // debugPrint('=== [BLOG] Count: ${latestBlogList.length}');
          // for (int i = 0; i < latestBlogList.length; i++) {
          //   final b = latestBlogList[i];
          //   debugPrint('  [BLOG $i] id=${b.id} | title=${b.title} | slug=${b.slug} | status=${b.status} | publish=${b.publish} | views=${b.views} | thumbnail=${b.thumbnail}');
          //   debugPrint('  [BLOG $i] category=${b.category} | subCategory=${b.subCategory} | isFeatured=${b.isFetured} | publishAt=${b.publishAt}');
          // }
        }
        // else {
        //   debugPrint('=== [BLOG] API failed or no data | success=${resp.success}');
        // }
      },
      onError: (err) {
        // debugPrint('=== [BLOG] Error: $err');
        showToast(err.toString());
      },
    );
  }
}
