import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/staking.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';

import 'staking_controller.dart';

class StakingEarningScreen extends StatefulWidget {
  const StakingEarningScreen({super.key});

  @override
  State<StakingEarningScreen> createState() => _StakingEarningScreenState();
}

class _StakingEarningScreenState extends State<StakingEarningScreen> {
  bool isLoading = true;
  final _controller = Get.find<StakingController>();
  RxList<StakingEarning> earningList = <StakingEarning>[].obs;
  bool hasMoreData = true;
  int loadedPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => getEarningList(false));
  }

  void getEarningList(bool loadMore) async {
    if (!loadMore) {
      loadedPage = 0;
      hasMoreData = true;
      earningList.clear();
    }
    isLoading = true;
    loadedPage++;
    _controller.getStakingEarningList(loadedPage, (listResponse) {
      isLoading = false;
      loadedPage = listResponse.currentPage ?? 0;
      hasMoreData = listResponse.nextPageUrl != null;
      final list = List<StakingEarning>.from(listResponse.data!.map((x) => StakingEarning.fromJson(x)));
      earningList.addAll(list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return earningList.isEmpty
          ? handleEmptyViewWithLoading(isLoading)
          : Expanded(
              child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(Dimens.paddingMid),
                  itemCount: earningList.length,
                  itemBuilder: (context, index) {
                    if (hasMoreData && index == earningList.length - 1) getEarningList(true);
                    return StakingEarningItemView(earning: earningList[index]);
                  }),
            );
    });
  }
}

class StakingEarningItemView extends StatelessWidget {
  const StakingEarningItemView({super.key, required this.earning});

  final StakingEarning earning;

  @override
  Widget build(BuildContext context) {
    final pcl = context.theme.primaryColorLight;
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.only(bottom: Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          twoTextSpaceFixed("Coin Type".tr, earning.coinType ?? "", color: pcl),
          twoTextSpaceFixed("Total Invested".tr, coinFormat(earning.totalInvestment), color: pcl),
          twoTextSpaceFixed("Total Interest".tr, coinFormat(earning.totalBonus), color: pcl),
          twoTextSpaceFixed("Total Amount".tr, coinFormat(earning.totalAmount), color: pcl),
          twoTextSpaceFixed("Payment Date".tr, formatDate(earning.createdAt, format: dateTimeFormatDdMMMMYyyyHhMm),
              flex: 4, subMaxLine: 2, color: pcl),
        ],
      ),
    );
  }
}
