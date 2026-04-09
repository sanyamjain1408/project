import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/local/constants.dart';
import '../../../../data/models/staking.dart';
import '../../../../ui/ui_helper/app_widgets.dart';
import '../../../../utils/alert_util.dart';
import '../../../../utils/button_util.dart';
import '../../../../utils/common_utils.dart';
import '../../../../utils/common_widgets.dart';
import '../../../../utils/date_util.dart';
import '../../../../utils/decorations.dart';
import '../../../../utils/dimens.dart';
import '../../../../utils/number_util.dart';
import '../../../../utils/spacers.dart';
import '../../../../utils/text_util.dart';
import '../../../../helper/app_checker.dart';
import '../../../../helper/app_helper.dart';
import 'staking_controller.dart';

class StakingInvestmentScreen extends StatefulWidget {
  const StakingInvestmentScreen({super.key});

  @override
  State<StakingInvestmentScreen> createState() => _StakingInvestmentScreenState();
}

class _StakingInvestmentScreenState extends State<StakingInvestmentScreen> {
  bool isLoading = true;
  final _controller = Get.find<StakingController>();
  RxList<Investment> investmentList = <Investment>[].obs;
  bool hasMoreData = true;
  int loadedPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => getInvestmentList(false));
  }

  void getInvestmentList(bool loadMore) async {
    if (!loadMore) {
      loadedPage = 0;
      hasMoreData = true;
      investmentList.clear();
    }
    isLoading = true;
    loadedPage++;
    _controller.getStakingInvestmentList(loadedPage, (listResponse) {
      isLoading = false;
      loadedPage = listResponse.currentPage ?? 0;
      hasMoreData = listResponse.nextPageUrl != null;
      final list = List<Investment>.from(listResponse.data!.map((x) => Investment.fromJson(x)));
      investmentList.addAll(list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return investmentList.isEmpty
          ? handleEmptyViewWithLoading(isLoading)
          : Expanded(
              child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(Dimens.paddingMid),
                  itemCount: investmentList.length,
                  itemBuilder: (context, index) {
                    if (hasMoreData && index == investmentList.length - 1) getInvestmentList(true);
                    return StakingInvestmentItemView(investment: investmentList[index], onCancel: () => getInvestmentList(false));
                  }),
            );
    });
  }
}

class StakingInvestmentItemView extends StatelessWidget {
  const StakingInvestmentItemView({super.key, required this.investment, required this.onCancel});

  final Investment investment;
  final Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final statusData = AppChecker.getStakingStatusData(investment.status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(Dimens.radiusCorner)),
        onTap: () => showBottomSheetDynamic(context, StakingInvestmentDetailsView(investment: investment), title: "Investment Details".tr),
        child: Container(
          decoration: boxDecorationRoundCorner(),
          padding: const EdgeInsets.all(Dimens.paddingMid),
          margin: const EdgeInsets.only(bottom: Dimens.paddingMid),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TwoTextSpaceFixed(investment.coinType ?? "", daysString(investment.minimumMaturityPeriod), flex: 6, color: context.theme.primaryColor),
              vSpacer3(),
              TwoTextFixed("Status".tr, statusData.first, subColor: statusData.last),
              TwoTextFixed("Daily Earning".tr, "${coinFormat(investment.earnDailyBonus)} ${investment.coinType ?? ""}",  flex: 5),
              TwoTextFixed("Investment Amount".tr, "${coinFormat(investment.investmentAmount)} ${investment.coinType ?? ""}", flex: 5),
              TwoTextFixed("Estimated Interest".tr, "${coinFormat(investment.totalBonus)} ${investment.coinType ?? ""}",  flex: 5),
              if (investment.status == StakingInvestmentStatus.running)
              Align(alignment:Alignment.centerRight,child: buttonText("Cancel".tr, onPress: () => _cancelMyInvestment(context), bgColor: context.theme.colorScheme.error, visualDensity: minimumVisualDensity, textColor: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  void _cancelMyInvestment(BuildContext context) {
    alertForAction(
      context,
      title: "Cancel Investment".tr,
      subTitle: "Do you want to cancel your Investment".tr,
      buttonTitle: "Cancel".tr,
      buttonColor: Colors.red,
      onOkAction: () {
        Get.find<StakingController>().investmentCanceled(investment.uid ?? "", () {
          Get.back();
          onCancel();
        });
      },
    );
  }
}

class StakingInvestmentDetailsView extends StatelessWidget {
  const StakingInvestmentDetailsView({super.key, required this.investment});

  final Investment investment;

  @override
  Widget build(BuildContext context) {
    final statusData = AppChecker.getStakingStatusData(investment.status);
    final typeData = AppChecker.getStakingTermsData(investment.termsType);
    final color = Get.theme.primaryColorLight;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingLarge),
      children: [
        TwoTextFixed("Coin Type".tr, investment.coinType ?? "", color: color),
        TwoTextFixed("Type".tr, typeData.first, subColor: typeData.last, color: color),
        TwoTextFixed("Stake Date".tr, formatDate(investment.createdAt, format: dateTimeFormatDdMMMMYyyyHhMm), color: color, subMaxLine: 2),
        TwoTextFixed("Daily Interest".tr, "${coinFormat(investment.earnDailyBonus)} ${investment.coinType ?? ""}", color: color, flex: 4),
        TwoTextFixed("End Date".tr, formatDate(investment.endDate, format: dateTimeFormatDdMMMMYyyyHhMm), color: color, subMaxLine: 2),
        TwoTextFixed("Minimum Maturity Period".tr, daysString(investment.minimumMaturityPeriod), color: color, flex: 10),
        TwoTextFixed("Remain Interest Day".tr, daysString(investment.remainInterestDay), color: color, flex: 10),
        TwoTextFixed("Offer Percentage".tr, "${coinFormat(investment.offerPercentage)}%", color: color, flex: 5),
        TwoTextFixed("Invested Amount".tr, "${coinFormat(investment.investmentAmount)} ${investment.coinType ?? ""}", color: color, flex: 5),
        TwoTextFixed("Total Bonus".tr, "${coinFormat(investment.totalBonus)} ${investment.coinType ?? ""}", color: color),
        TwoTextFixed("Auto Renew".tr, investment.autoRenewStatus == 2 ? "Enabled".tr : "Disabled".tr, color: color),
        TwoTextFixed("Status".tr, statusData.first, subColor: statusData.last, color: color),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextRobotoAutoBold("Est. APR".tr, fontSize: Dimens.fontSizeLarge),
            TextRobotoAutoBold("${coinFormat(investment.offerPercentage)}%", color: Colors.green),
          ],
        ),
        vSpacer10()
      ],
    );
  }
}
