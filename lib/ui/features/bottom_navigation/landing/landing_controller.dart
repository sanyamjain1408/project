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

      // Core Assets: sorted by price descending (matches web app)
      final coreAssets = List<CoinPair>.from(allCoins)
        ..sort((a, b) => (b.lastPrice ?? 0).compareTo(a.lastPrice ?? 0));
      final top10CoreAssets = coreAssets.take(8).toList();

      // 24H Gainer: sorted by priceChange descending
      final gainers = List<CoinPair>.from(allCoins)
        ..sort((a, b) => (b.priceChange ?? 0).compareTo(a.priceChange ?? 0));
      final top10Gainers = gainers.take(8).toList();

      landingList.value = LandingList(
        assetCoinPairs: top10CoreAssets,
        hourlyCoinPairs: top10Gainers,
        latestCoinPairs: [],
      );

      // New Listing: fetch from API with type=4 (same as web app)
      _loadNewListings();
    }, onError: (err) {
      isLoading.value = false;
    });
  }

  void _loadNewListings() {
    APIRepository().getMarketOverviewTopCoinList(1, 'USD', 4).then((resp) {
      if (!resp.success) return;
      List rawList = [];
      if (resp.data is List) {
        rawList = resp.data as List;
      } else if (resp.data is Map) {
        rawList = (resp.data['data'] as List?) ?? [];
      }
      final newCoins = rawList.map<CoinPair>((p) {
        final coin = CoinPair();
        coin.childCoinName  = p['coin_type']  ?? p['base_currency']  ?? p['child_coin_name'] ?? '';
        coin.parentCoinName = p['base_coin_type'] ?? p['quote_currency'] ?? p['parent_coin_name'] ?? 'USDT';
        coin.lastPrice      = double.tryParse(p['current_price']?.toString() ?? p['last_price']?.toString() ?? '0') ?? 0;
        coin.priceChange    = double.tryParse(p['price_change']?.toString() ?? p['change']?.toString() ?? '0') ?? 0;
        coin.volume         = double.tryParse(p['volume']?.toString() ?? '0') ?? 0;
        coin.icon           = p['coin_icon'] ?? p['icon'] ?? p['logo'] ?? '';
        coin.coinPair       = '${coin.childCoinName}_${coin.parentCoinName}';
        coin.coinPairName   = '${coin.childCoinName}/${coin.parentCoinName}';
        return coin;
      }).take(8).toList();
      final updated = landingList.value;
      updated.latestCoinPairs = newCoins;
      landingList.value = LandingList(
        assetCoinPairs: updated.assetCoinPairs,
        hourlyCoinPairs: updated.hourlyCoinPairs,
        latestCoinPairs: newCoins,
      );
    }, onError: (_) {});
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
