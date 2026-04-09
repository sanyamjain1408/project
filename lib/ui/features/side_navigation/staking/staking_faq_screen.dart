import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/staking.dart';
import 'package:tradexpro_flutter/ui/features/side_navigation/faq/faq_page.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import 'staking_controller.dart';

class StakingFAQScreen extends StatefulWidget {
  const StakingFAQScreen({super.key});

  @override
  State<StakingFAQScreen> createState() => _StakingFAQScreenState();
}

class _StakingFAQScreenState extends State<StakingFAQScreen> {
  final _controller = Get.find<StakingController>();
  bool isLoading = true;
  StakingLandingData? stakingLandingData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.getStakingLandingDetails((p0) => setState(() {
            isLoading = false;
            stakingLandingData = p0;
          }));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(title: "Staking Info".tr),
      body: SafeArea(
        child: isLoading
            ? showLoading()
            : Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (stakingLandingData?.stakingLandingCoverImage.isValid ?? false)
                      showImageNetwork(
                          imagePath: stakingLandingData?.stakingLandingCoverImage, width: Get.width, height: Get.width / 2, hideDefaultImage: true),
                    if (stakingLandingData?.stakingLandingCoverImage.isValid ?? false) vSpacer10(),
                    Padding(
                      padding: const EdgeInsets.all(Dimens.paddingMid),
                      child: Column(
                        children: [
                          if (stakingLandingData?.stakingLandingTitle.isValid ?? false)
                            TextRobotoAutoBold(stakingLandingData?.stakingLandingTitle ?? "", maxLines: 3, textAlign: TextAlign.center),
                          if (stakingLandingData?.stakingLandingDescription.isValid ?? false) vSpacer10(),
                          if (stakingLandingData?.stakingLandingDescription.isValid ?? false)
                            TextRobotoAutoNormal(stakingLandingData?.stakingLandingDescription ?? "",
                                color: Colors.white, maxLines: 10, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    Padding(padding: const EdgeInsets.all(Dimens.paddingMid), child: FAQRelatedView(stakingLandingData?.faqList ?? [])),
                  ],
                ),
              ),
      ),
    );
  }
}
