import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';

import 'p2p_ads/p2p_ads_screen.dart';
import 'p2p_gift_card/p2p_gift_card_screen.dart';
import 'p2p_home/p2p_home_screen.dart';
import 'p2p_orders/p2p_orders_screen.dart';
import 'p2p_trade_controller.dart';
import 'p2p_user_center/p2p_user_center_screen.dart';
import 'p2p_wallet/p2p_wallet_screen.dart';

class P2PTradeScreen extends StatefulWidget {
  const P2PTradeScreen({super.key});

  @override
  State<P2PTradeScreen> createState() => _P2PTradeScreenState();
}

class _P2PTradeScreenState extends State<P2PTradeScreen> with TickerProviderStateMixin {
  final _controller = Get.put(P2pTradeController());
  TabController? _p2pTabController;
  RxInt selectedGiftIndex = 0.obs;

  @override
  void initState() {
    _controller.selectedTabIndex.value = 0;
    _p2pTabController = TabController(vsync: this, length: _controller.getP2pTabMap().length);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Obx(() {
            return gUserRx.value.id == 0
                ? vSpacer0()
                : Column(
                    children: [
                      tabBarUnderline(_controller.getP2pTabMap().values.toList(), _p2pTabController,
                          isScrollable: true,
                          onTap: (index) async => _controller.selectedTabIndex.value = index,
                          fontSize: Dimens.fontSizeMid,
                          indicator: tabCustomIndicator(context, padding: Dimens.paddingLargeDouble)),
                      dividerHorizontal(height: 0),
                    ],
                  );
          }),
          _getTabBody()
        ],
      ),
    );
  }

  Widget _getTabBody() {
    return Obx(() {
      final menuId = _controller.getP2pTabMap().keys.toList()[_controller.selectedTabIndex.value];
      switch (menuId) {
        case 0:
          return const P2PHomeScreen();
        case 1:
          return const P2POrdersScreen();
        case 2:
          return const P2PUserCenterScreen();
        case 3:
          return const P2PWalletScreen();
        case 4:
          return const P2PAdsScreen();
        case 5:
          return const P2pGiftCardScreen();
        default:
          return const SizedBox();
      }
    });
  }
}
