import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/staking.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/number_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'staking_controller.dart';

class StakingStatisticsScreen extends StatefulWidget {
  const StakingStatisticsScreen({super.key});

  @override
  State<StakingStatisticsScreen> createState() => _StakingStatisticsScreenState();
}

class _StakingStatisticsScreenState extends State<StakingStatisticsScreen> {
  bool isLoading = true;
  final _controller = Get.find<StakingController>();
  StakingInvestmentStatistics? _stakingStatistics;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getStakingInvestmentStatistics((p0) => setState(() {
            isLoading = false;
            _stakingStatistics = p0;
          }));
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? showLoading()
        : Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(Dimens.paddingMid),
              children: [
                StakingStatisticsItemView(statistics: _stakingStatistics?.totalInvestment, title: "Total Investment".tr),
                StakingStatisticsItemView(statistics: _stakingStatistics?.totalRunningInvestment, title: "Running Investment".tr),
                StakingStatisticsItemView(statistics: _stakingStatistics?.totalPaidInvestment, title: "Distributed Investment".tr),
                StakingStatisticsItemView(statistics: _stakingStatistics?.totalUnpaidInvestment, title: "Distributable Investment".tr),
                StakingStatisticsItemView(statistics: _stakingStatistics?.totalCancelInvestment, title: "Cancelled Investment".tr),
              ],
            ),
          );
  }
}

class StakingStatisticsItemView extends StatelessWidget {
  const StakingStatisticsItemView({super.key, required this.statistics, required this.title});
  final List<Statistics>? statistics;
  final String title;

  @override
  Widget build(BuildContext context) {
    final length = statistics?.length ?? 0;
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingLarge),
      margin: const EdgeInsets.only(bottom: Dimens.paddingLargeExtra),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          vSpacer10(),
          TextRobotoAutoBold(title, fontSize: Dimens.fontSizeLarge),
          vSpacer20(),
          if (length > 0) _rowItemView("Coin Type".tr, "Total Bonus".tr, true),
          length > 0
              ? Column(
                  children: List.generate(length, (index) {
                    return _rowItemView(statistics?[index].coinType ?? "", coinFormat(statistics?[index].totalInvestment), false);
                  }),
                )
              : showEmptyView(height: Dimens.menuHeightSettings),
          vSpacer10(),
        ],
      ),
    );
  }

  Column _rowItemView(String v1, String v2, bool isHeader) {
    final color = isHeader ? Get.theme.primaryColorLight : null;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: TextRobotoAutoBold(v1, color: color)),
            Expanded(child: TextRobotoAutoBold(v2, color: color)),
          ],
        ),
        dividerHorizontal(height: 10)
      ],
    );
  }
}
