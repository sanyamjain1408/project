import 'package:get/get.dart';
import '../../../../data/models/blog_news.dart';
import '../../../../data/models/coin_pair.dart';
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
      // Socket se data aa raha hai — ignore karo, spot API se refresh karega
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
        if (resp.success && resp.data != null && resp.data is Map<String, dynamic>) {
          DataProcessHelper.commonSettingsProcess(
            resp.data,
            onSettings: (landingSettings) {
              if (landingSettings != null) {
                landingData.value = landingSettings;
              }
            },
          );
        }
        _loadSpotMarketCoins();
        handleSocketChannels(true);
      },
      onError: (err) {
        showToast(err.toString());
        _loadSpotMarketCoins();
      },
    );
  }

  void _loadSpotMarketCoins() {
    APIRepository().getSpotMarketPairs().then((resp) {
      isLoading.value = false;
      if (!resp.success) return;

      List rawPairs = [];
      if (resp.data is List) {
        rawPairs = resp.data as List;
      } else if (resp.data is Map) {
        rawPairs = (resp.data['data'] as List?) ??
            (resp.data['pairs'] as List?) ??
            (resp.data['result'] as List?) ??
            (resp.data['markets'] as List?) ??
            [];
      }
      if (rawPairs.isEmpty) return;

      final allCoins = rawPairs.map<CoinPair>((p) {
        final coin = CoinPair();
        coin.childCoinName  = p['base_currency']  ?? p['base']       ?? p['base_asset']  ?? '';
        coin.parentCoinName = p['quote_currency'] ?? p['quote']      ?? p['quote_asset'] ?? '';
        coin.lastPrice      = double.tryParse(
            p['last_price']?.toString() ??
            p['current_price']?.toString() ??
            p['price']?.toString() ?? '0') ?? 0;
        coin.priceChange    = double.tryParse(
            p['price_change_percent']?.toString() ??
            p['change_24h']?.toString() ??
            p['price_change_24h']?.toString() ??
            p['change']?.toString() ?? '0') ?? 0;
        coin.volume         = double.tryParse(
            p['volume_24h']?.toString() ??
            p['volume']?.toString() ??
            p['base_volume']?.toString() ?? '0') ?? 0;
        coin.icon           = p['icon'] ?? p['logo'] ?? p['image'] ?? p['icon_url'] ?? '';
        coin.coinPair       = '${coin.childCoinName}_${coin.parentCoinName}';
        coin.coinPairName   = '${coin.childCoinName}/${coin.parentCoinName}';
        return coin;
      }).toList();

      // Core Assets: volume ke hisaab se top 10
      final coreAssets = List<CoinPair>.from(allCoins)
        ..sort((a, b) => (b.volume ?? 0).compareTo(a.volume ?? 0));
      final top10CoreAssets = coreAssets.take(8).toList();

      // 24H Gainer: priceChange ke hisaab se descending sort
      final gainers = List<CoinPair>.from(allCoins)
        ..sort((a, b) => (b.priceChange ?? 0).compareTo(a.priceChange ?? 0));
      final top10Gainers = gainers.take(8).toList();

      // New Listing: API se jo order aaya uske hisaab se last 10 (latest added)
      final latest = allCoins.reversed.take(8).toList();

      landingList.value = LandingList(
        assetCoinPairs: top10CoreAssets,
        hourlyCoinPairs: top10Gainers,
        latestCoinPairs: latest,
      );
    }, onError: (err) {
      isLoading.value = false;
    });
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
