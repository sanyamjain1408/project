import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import '../market_widgets.dart';
import 'favorites_pair_controller.dart';

class FavoritesPairScreen extends StatefulWidget {
  const FavoritesPairScreen({super.key});

  @override
  FavoritesPairScreenState createState() => FavoritesPairScreenState();
}

class FavoritesPairScreenState extends State<FavoritesPairScreen> with SingleTickerProviderStateMixin {
  final _controller = Get.put(FavoritesPairController());
  late final TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: _controller.getTypeMap().values.length, vsync: this);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getFavoriteList();
      _controller.subscribeSocketChannels();
    });
  }

  @override
  void dispose() {
    _controller.unSubscribeChannel();
    super.dispose();
    Get.delete<FavoritesPairController>();
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
            Obx(() => SpotMarketHeaderView(sort: _controller.marketSort.value, hideCap: true, onTap: (sort) => _controller.onSortChanged(sort))),
            Obx(() {
              return _controller.favList.isEmpty
                  ? handleEmptyViewWithLoading(false)
                  : Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(Dimens.paddingMid),
                        separatorBuilder: (context, index) => dividerHorizontal(),
                        itemCount: _controller.favList.length,
                        itemBuilder: (context, index) {
                          final fromKey = _controller.selectedTab.value == 0 ? "" : FromKey.future;
                          return MarketCoinPairItemView(
                              pair: _controller.favList[index], fromKey: fromKey, onFavChange: (v) => _controller.getFavoriteList());
                        },
                      ),
                    );
            }),
          ],
        ),
      ),
    );
  }

  List<String> getFavTabs() {
    List<String> list = ['Spot'.tr];
    if (getSettingsLocal()?.enableFutureTrade == 1) list.add('Futures'.tr);
    return list;
  }
}
