import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';

import 'p2p_gift_card_ads/p2p_gc_ads_screen.dart';
import 'p2p_gift_card_home/p2p_gc_home_screen.dart';
import 'p2p_gift_card_list/p2p_gc_list_screen.dart';
import 'p2p_gift_card_orders/p2p_gc_orders_screen.dart';

class P2pGiftCardScreen extends StatefulWidget {
  const P2pGiftCardScreen({super.key});

  @override
  State<P2pGiftCardScreen> createState() => _P2pGiftCardScreenState();
}

class _P2pGiftCardScreenState extends State<P2pGiftCardScreen> with SingleTickerProviderStateMixin {
  late TabController _p2pGCTabController;
  RxInt selectedGiftIndex = 0.obs;

  @override
  void initState() {
    _p2pGCTabController = TabController(vsync: this, length: 4);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          TabBarPlain(
              titles: ["Home".tr, "Orders".tr, "My Gift Cards".tr, "My Gift Card Ads".tr],
              controller: _p2pGCTabController,
              isScrollable: true, height: Dimens.btnHeightMid,
              onTap: (index) => selectedGiftIndex.value = index),
          Obx(() => _getTabBody(selectedGiftIndex.value))
        ],
      ),
    );
  }

  Widget _getTabBody(int index) {
    switch (index) {
      case 0:
        return const P2PGCHomeScreen();
      case 1:
        return const P2PGCOrdersScreen();
      case 2:
        return const P2PGCListScreen();
      case 3:
        return const P2PGCAdsScreen();
      default:
        return const SizedBox();
    }
  }
}
