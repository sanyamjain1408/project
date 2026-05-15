import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/ui/features/bottom_navigation/market/market_opportunity/market_opportunity_screen.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';

import 'favorites_pair/favorites_pair_screen.dart';
import 'market_future/market_future_screen.dart';
import 'market_spot/market_spot_screen.dart';

const _bgcolor = Color.fromARGB(255, 17, 17, 17);

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  final RxInt selectedTab = 1.obs;

  /// TABS
  List<String> getMarketTabs() {
    List<String> list = [
      "Favorites".tr,
      "Spot".tr,
    ];

    /// FUTURES TAB
    if (getSettingsLocal()?.enableFutureTrade == 1) {
      list.add("Futures".tr);
    }

    /// OPPORTUNITY TAB
    list.add("Opportunity".tr);

    return list;
  }

  @override
  void initState() {
    super.initState();

    final tabs = getMarketTabs();

    _tabController = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: tabs.length > 1 ? 1 : 0,
    );

    /// TAB CHANGE LISTENER
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        selectedTab.value = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// BODY
  Widget _getBody(int index) {

    /// FUTURES ENABLED
    if (getSettingsLocal()?.enableFutureTrade == 1) {

      switch (index) {

        case 0:
          return const FavoritesPairScreen();

        case 1:
          return const MarketSpotScreen();

        case 2:
          return const MarketFutureScreen();

        case 3:
          return const MarketOpportunityScreen();

        default:
          return const SizedBox();
      }
    }

    /// FUTURES DISABLED
    else {

      switch (index) {

        case 0:
          return const FavoritesPairScreen();

        case 1:
          return const MarketSpotScreen();

        case 2:
          return const MarketOpportunityScreen();

        default:
          return const SizedBox();
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: _bgcolor,

      body: SafeArea(
        child: Column(
          children: [

            /// TAB BAR
            TabBarPlain(
              titles: getMarketTabs(),
              controller: _tabController,
              isScrollable: true,
              fontSize: 16,
              onTap: (index) {
                selectedTab.value = index;
              },
            ),

            /// BODY
            Obx(
              () => _getBody(selectedTab.value),
            ),
          ],
        ),
      ),
    );
  }
}