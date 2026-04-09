import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/local/constants.dart';
import '../../../../data/models/staking.dart';
import '../../../../ui/ui_helper/app_widgets.dart';
import '../../../../utils/alert_util.dart';
import '../../../../utils/button_util.dart';
import '../../../../utils/common_utils.dart';
import '../../../../utils/common_widgets.dart';
import '../../../../utils/decorations.dart';
import '../../../../utils/dimens.dart';
import '../../../../utils/image_util.dart';
import '../../../../utils/number_util.dart';
import '../../../../utils/spacers.dart';
import '../../../../utils/text_util.dart';
import 'staking_controller.dart';
import 'staking_details_screen.dart';

class StakingHomeScreen extends StatefulWidget {
  const StakingHomeScreen({super.key});

  @override
  State<StakingHomeScreen> createState() => _StakingHomeScreenState();
}

class _StakingHomeScreenState extends State<StakingHomeScreen> {
  final isLogin = gUserRx.value.id > 0;
  bool isLoading = true;
  final _controller = Get.find<StakingController>();
  StakingOffersData? stakingData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getStakingOfferList((p0) => setState(() {
            isLoading = false;
            stakingData = p0;
          }));
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyList = stakingData?.offerList?.keys.toList() ?? [];
    return keyList.isEmpty
        ? handleEmptyViewWithLoading(isLoading)
        : Expanded(
            child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(Dimens.paddingMid),
                itemCount: keyList.length,
                itemBuilder: (context, index) {
                  final list = stakingData?.offerList?[keyList[index]] ?? [];
                  return StakingOfferItemView(stakingOffers: list, isLogin: isLogin);
                }),
          );
  }
}

class StakingOfferItemView extends StatelessWidget {
  const StakingOfferItemView({super.key, required this.stakingOffers, required this.isLogin});

  final List<StakingOffer> stakingOffers;
  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    Rx<StakingOffer> selectedOffer = stakingOffers.first.obs;
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.only(bottom: Dimens.paddingMid),
      child: Column(
        children: [
          Row(
            children: [
              showImageNetwork(imagePath: selectedOffer.value.coinIcon, width: Dimens.iconSizeMid, height: Dimens.iconSizeMid),
              hSpacer5(),
              TextRobotoAutoBold(selectedOffer.value.coinType ?? ""),
              const Spacer(),
              if (isLogin)
                buttonText("Stake Now".tr, visualDensity: minimumVisualDensity ,onPress: () {
                  showBottomSheetFullScreen(context, StakingDetailsScreen(stakingOffer: selectedOffer.value), title: "Staking".tr);
                })
            ],
          ),
          vSpacer5(),
          Obx(() {
            return Column(
              children: [
                TwoTextFixed("Minimum Amount".tr, "${coinFormat(selectedOffer.value.minimumInvestment)} ${selectedOffer.value.coinType ?? ""}"),
                TwoTextFixed("Est. APR".tr, "${selectedOffer.value.offerPercentage}%"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextRobotoAutoBold("Duration".tr, color: Get.theme.primaryColorLight),
                    Expanded(
                      child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: Dimens.paddingMin,
                          children: List.generate(stakingOffers.length, (index) {
                            final offer = stakingOffers[index];
                            final isSelected = offer == selectedOffer.value;
                            return buttonTextBordered("${offer.period} ${"Days".tr}", isSelected,
                                visualDensity: minimumVisualDensity, onPress: () => selectedOffer.value = offer);
                          })),
                    )
                  ],
                )
              ],
            );
          })
        ],
      ),
    );
  }
}
