import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';

import '../p2p_common_widgets.dart';
import 'p2p_home_controller.dart';
import 'p2p_home_widgets.dart';

class P2PHomeScreen extends StatefulWidget {
  const P2PHomeScreen({super.key});

  @override
  State<P2PHomeScreen> createState() => _P2PHomeScreenState();
}

class _P2PHomeScreenState extends State<P2PHomeScreen> {
  final _controller = Get.put(P2PHomeController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getHomeData(() => setState(() {})));
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingMid, vertical: Dimens.paddingMin),
        child: Column(
          children: [
            Row(
              children: [
                Obx(() => SegmentedControlView(["Buy".tr, "Sell".tr], _controller.selectedTransactionType.value, onChange: (index) {
                      _controller.selectedTransactionType.value = index;
                      _controller.getAdsList(false);
                    })),
                Obx(() => Expanded(
                      child: dropDownListIndex(_controller.getCoinNameList(), _controller.selectedCoin.value, "Select".tr, (index) {
                        _controller.selectedCoin.value = index;
                        _controller.getAdsList(false);
                      }, height: 35, bgColor: Colors.transparent, radius: Dimens.radiusCornerSmall),
                    )),
                P2pIconWithTap(
                    icon: Icons.info_outline,
                    onTap: () => showBottomSheetFullScreen(context, P2pTutorialView(settings: _controller.settings), title: "How P2P works".tr)),
                P2pIconWithTap(
                    icon: Icons.filter_alt_outlined,
                    onTap: () => showBottomSheetFullScreen(context, const P2pHomeFilterView(),
                        title: "Filter Ads".tr, onClose: () => _controller.checkFilterChange())),
              ],
            ),
            vSpacer5(),
            _adsListView(),
          ],
        ),
      ),
    );
  }

  Widget _adsListView() {
    return Obx(() => _controller.adsList.isEmpty
        ? handleEmptyViewWithLoading(_controller.isLoading.value)
        : Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _controller.adsList.length,
              itemBuilder: (BuildContext context, int index) {
                if (_controller.hasMoreData && index == (_controller.adsList.length - 1)) {
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getAdsList(true));
                }
                return P2pAdsItemView(_controller.adsList[index], _controller.selectedTransactionType.value);
              },
            ),
          ));
  }
}
