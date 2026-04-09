import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/addons/p2p_trade/ui/p2p_trade_screen.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';

import 'spot_trade/spot_trade_screen.dart';
import 'trade_controller.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> with SingleTickerProviderStateMixin {
  final _controller = TradeController();
  late final TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: _controller.getTradeTabs().length, vsync: this);
    if (TemporaryData.changingPageId != null) {
      _controller.selectedTab.value = TemporaryData.changingPageId!;
      TemporaryData.changingPageId = null;
      _tabController.animateTo(_controller.selectedTab.value);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: Dimens.btnHeightMid,
          child: TabBarPlain(
              titles: _controller.getTradeTabs(),
              controller: _tabController,
              fontSize: Dimens.fontSizeLarge,
              onTap: (index) => _controller.selectedTab.value = index),
        ),
        Obx(() {
          switch (_controller.selectedTab.value) {
            case 0:
              return const SpotTradeScreen();
              case 1:
            return const P2PTradeScreen();
            default:
              return Container();
          }
        })
      ],
    );
  }
}
