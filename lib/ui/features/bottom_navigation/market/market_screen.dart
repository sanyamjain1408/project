import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';

import 'favorites_pair/favorites_pair_screen.dart';
import 'market_future/market_future_screen.dart';
import 'market_spot/market_spot_screen.dart';


// RGBA(17, 17, 17, 1) ko Flutter Color mein convert karna hai
// Format: Color.fromARGB(Alpha, Red, Green, Blue)
const  _bgcolor =  Color.fromARGB(255, 17, 17, 17);  ///background: #111111;background: var(--Primary, rgba(17, 17, 17, 1));



class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  RxInt selectedTab = 1.obs;

  @override
  void initState() {
    _tabController = TabController(length: getMarketTabs().length, vsync: this, initialIndex: 1);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: _bgcolor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBarPlain(
                titles: getMarketTabs(),
                controller: _tabController,
                isScrollable: true,
                fontSize: 16,
                onTap: (index) => selectedTab.value = index),
            Obx(() => _getBody(selectedTab.value))
          ],
        ),
      ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return const FavoritesPairScreen();
      case 1:
        return const MarketSpotScreen();
      case 2:
        return const MarketFutureScreen();
      default:
        return Container();
    }
  }

  List<String> getMarketTabs() {
    List<String> list = ["Favorites".tr, 'Spot'.tr];
    if (getSettingsLocal()?.enableFutureTrade == 1) list.add('Futures'.tr);
    return list;
  }
}
