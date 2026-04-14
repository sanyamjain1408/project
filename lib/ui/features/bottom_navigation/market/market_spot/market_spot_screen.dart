import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';

import '../market_widgets.dart'; // General imports
import 'market_spot_controller.dart';
import 'market_spot_widgets.dart' as spot; // Local imports with prefix

class MarketSpotScreen extends StatefulWidget {
  const MarketSpotScreen({super.key});

  @override
  MarketSpotState createState() => MarketSpotState();
}

class MarketSpotState extends State<MarketSpotScreen> with SingleTickerProviderStateMixin {
  final _controller = Get.put(MarketSpotController());
  late final TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: _controller.getTypeMap().values.length, vsync: this);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getMarketOverviewTopCoinList(false);
      _controller.subscribeSocketChannels();
    });
  }

  @override
  void dispose() {
    _controller.unSubscribeChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: boxDecorationTopRound(color: context.theme.dialogTheme.backgroundColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tabBarUnderline(_controller.getTypeMap().values.toList(), _tabController,
                indicator: tabCustomIndicator(context, padding: Dimens.paddingLargeExtra),
                isScrollable: true,
                fontSize: Dimens.fontSizeMid,
                onTap: (index) => _controller.changeTab(index)),
            dividerHorizontal(height: 0),
            vSpacer10(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid),
              child: textFieldSearch(
                  controller: _controller.searchController,
                  height: Dimens.btnHeightSmall,
                  margin: 0,
                  borderRadius: Dimens.radiusCornerMid,
                  onTextChange: _controller.onTextChanged),
            ),
            Obx(() => spot.SpotMarketHeaderView(
              sort: _controller.marketSort.value, 
              onTap: (sort) => _controller.onSortChanged(sort)
            )),
            Obx(() {
              return _controller.marketList.isEmpty
                  ? handleEmptyViewWithLoading(_controller.isLoading.value)
                  : Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(Dimens.paddingMid),
                        separatorBuilder: (context, index) => dividerHorizontal(),
                        itemCount: _controller.marketList.length,
                        itemBuilder: (context, index) {
                          if (_controller.hasMoreData && index == _controller.marketList.length - 1) {
                            WidgetsBinding.instance.addPostFrameCallback((t) => _controller.getMarketOverviewTopCoinList(true));
                          }
                          return Builder(
                            builder: (BuildContext newContext) {
                              return spot.MarketCoinItemViewBottom(
                                coin: _controller.marketList[index],
                                onFavChange: (message) => showToast(message, isError: false),
                              );
                            },
                          );
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