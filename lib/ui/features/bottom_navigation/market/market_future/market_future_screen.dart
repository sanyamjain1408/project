import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';

import '../market_widgets.dart';
import 'market_future_controller.dart';

class MarketFutureScreen extends StatefulWidget {
  const MarketFutureScreen({super.key});

  @override
  MarketFutureState createState() => MarketFutureState();
}

class MarketFutureState extends State<MarketFutureScreen> with SingleTickerProviderStateMixin {
  final _controller = Get.put(FutureController());
  late final TabController _tabController;

  List<String> getTabList() => ["Core Assets".tr, "24H Gainers".tr, "New Listing".tr];

  @override
  void initState() {
    _tabController = TabController(length: getTabList().length, vsync: this);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getFutureCoinList(false);
      _controller.subscribeSocketChannels();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.coinPairList.clear();
    _controller.unSubscribeChannel();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: boxDecorationTopRound(color: context.theme.dialogTheme.backgroundColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tabBarUnderline(getTabList(), _tabController,
                indicator: tabCustomIndicator(context, padding: Dimens.paddingLargeExtra),
                isScrollable: true,
                fontSize: Dimens.fontSizeMid,
                onTap: (index) => _controller.changeTab(index)),
            dividerHorizontal(height: 0),
            Obx(() => SpotMarketHeaderView(sort: _controller.marketSort.value, hideCap: true, onTap: (sort) => _controller.onSortChanged(sort))),
            Obx(() {
              return _controller.coinPairList.isEmpty
                  ? handleEmptyViewWithLoading(_controller.isLoadingList.value)
                  : Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(Dimens.paddingMid),
                        separatorBuilder: (context, index) => dividerHorizontal(height: 10),
                        itemCount: _controller.coinPairList.length,
                        itemBuilder: (context, index) {
                          /// if (_controller.hasMoreData && index == _controller.coinPairList.length - 1) {
                          ///   WidgetsBinding.instance.addPostFrameCallback((t) => _controller.getFutureCoinList(true));
                          /// }
                          return MarketCoinPairItemView(
                              pair: _controller.coinPairList[index],
                              fromKey: FromKey.future,
                              onFavChange: (message) => showToast(message, isError: false));
                        },
                      ),
                    );
            }),
          ],
        ),
      ),
    );
  }
}

// class MarketFutureState extends State<MarketFutureScreen> {
//   final _controller = Get.put(FutureController());
//
//   List<String> getTabList() => ["Core Assets".tr, "24H Gainers".tr, "New Listing".tr];
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getFutureExchangeMarketDetail());
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _controller.marketData.value = FutureMarketData();
//     _controller.coinPairList.clear();
//     _controller.unSubscribeChannel();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Obx(() => _controller.isLoading.value
//         ? showLoading()
//         : Expanded(
//       child: ListView(
//         padding: const EdgeInsets.all(Dimens.paddingMid),
//         children: [
//           Obx(() {
//             final mData = _controller.marketData.value;
//             return Column(
//               children: [
//                 if ((mData.coins?.length ?? 0) > 0) OpenInterestView(coinPair: mData.coins!.first),
//                 if (mData.highestVolumePair != null) LongShortRatioView(lsPair: mData.highestVolumePair!, plPair: mData.profitLossByCoinPair!),
//                 if (mData.coins.isValid) HighestSearchView(pairs: mData.coins!),
//               ],
//             );
//           }),
//           vSpacer20(),
//           Obx(() {
//             final selected = _controller.selectedTab.value;
//             return tabBarText(getTabList(), selected, selectedColor: context.theme.focusColor, (index) => _controller.changeTab(index));
//           }),
//           Obx(() {
//             return Column(
//               children: [
//                 if (_controller.isLoadingList.value) showLoadingSmall(),
//                 vSpacer10(),
//                 MarketListHeaderView(first: "Market".tr, second: "${"Price".tr}/${"Volume".tr}", third: "24H Change".tr),
//                 vSpacer2(),
//                 _controller.coinPairList.isValid
//                     ? Column(
//                   children: List.generate(_controller.coinPairList.length, (index) {
//                     return FutureMarketCoinItemView(coinPair: _controller.coinPairList[index]);
//                   }),
//                 )
//                     : showEmptyView(height: Dimens.menuHeight)
//               ],
//             );
//           }),
//           vSpacer20(),
//           TextRobotoAutoBold("Market Index".tr),
//           vSpacer10(),
//           Obx(() {
//             final mDataCoins = _controller.marketData.value.coins;
//             return mDataCoins.isValid
//                 ? Wrap(
//                 spacing: Dimens.paddingMid,
//                 runSpacing: Dimens.paddingMid,
//                 children: List.generate(mDataCoins?.length ?? 0, (index) => MarketIndexView(coinPair: mDataCoins![index])))
//                 : showEmptyView(height: Dimens.menuHeight);
//           }),
//           vSpacer10(),
//         ],
//       ),
//     ));
//   }
// }
//
