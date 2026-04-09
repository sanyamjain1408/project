import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/ui/ui_helper/app_widgets.dart';
import 'package:tradexpro_flutter/data/models/referral.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import '../activity/activity_screen.dart';
import 'referrals_controller.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  ReferralsScreenState createState() => ReferralsScreenState();
}

class ReferralsScreenState extends State<ReferralsScreen> {
  final _controller = Get.put(ReferralsController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getReferralData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBarBackWithActions(
            title: "Referrals".tr,
            actionIcons: [Icons.history],
            onPress: (i) {
              TemporaryData.activityType = HistoryType.refEarningTrade;
              Get.to(() => const ActivityScreen());
            }),
        body: SafeArea(
          child: Obx(() {
            final refData = _controller.referralData.value;
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(Dimens.paddingMid),
              children: [
                _topShareView(refData.url),
                vSpacer10(),
                Container(
                  decoration: boxDecorationRoundCorner(),
                  padding: const EdgeInsets.all(Dimens.paddingMid),
                  child: Row(children: [
                    ReferralsItemView(title: "Total Rewards".tr, subtitle: (refData.totalReward ?? 0).toString()),
                    ReferralsItemView(title: "Total Invited".tr, subtitle: (refData.countReferrals ?? 0).toString()),
                  ]),
                ),
                vSpacer20(),
                ReferralsLevelView(referralLevels: refData.referralLevel),
                vSpacer20(),
                ReferencesView(referrals: refData.referrals),
              ],
            );
          }),
        ));
  }

  Container _topShareView(String? referralLink) {
    final link = URLConstants.referralLink + (referralLink ?? "");
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextRobotoAutoBold("Invite Your Fiends".tr),
          vSpacer10(),
          Row(
            children: [
              Expanded(child: textWithCopyButton(link)),
              TextRobotoAutoBold("Or".tr),
              hSpacer10(),
              buttonOnlyIcon(
                  iconData: Icons.share, iconColor: context.theme.focusColor, visualDensity: minimumVisualDensity, onPress: () => shareText(link))
            ],
          )
        ],
      ),
    );
  }
}

class ReferralsLevelView extends StatelessWidget {
  const ReferralsLevelView({super.key, this.referralLevels});

  final Map<String, int>? referralLevels;

  @override
  Widget build(BuildContext context) {
    final refLevels = referralLevels ?? {"1": 0, "2": 0, "3": 0};
    final keys = refLevels.keys.toList();
    final values = refLevels.values.toList();
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextRobotoAutoBold("My Referrals".tr),
          vSpacer15(),
          Row(children: [
            ReferralsItemView(title: "${"Level".tr} ${keys[0]}", subtitle: values[0].toString(), subFontSize: Dimens.fontSizeLarge),
            ReferralsItemView(title: "${"Level".tr} ${keys[1]}", subtitle: values[1].toString(), subFontSize: Dimens.fontSizeLarge),
            ReferralsItemView(title: "${"Level".tr} ${keys[2]}", subtitle: values[2].toString(), subFontSize: Dimens.fontSizeLarge),
          ])
        ],
      ),
    );
  }
}

class ReferralsItemView extends StatelessWidget {
  const ReferralsItemView({super.key, required this.title, required this.subtitle, this.subFontSize});

  final String title;
  final String subtitle;
  final double? subFontSize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          TextRobotoAutoBold(title, color: context.theme.primaryColorLight),
          dividerHorizontal(),
          TextRobotoAutoBold(subtitle, fontSize: subFontSize ?? Dimens.titleFontSizeMid),
        ],
      ),
    );
  }
}

class ReferencesView extends StatelessWidget {
  const ReferencesView({super.key, this.referrals});

  final List<Referral>? referrals;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationRoundCorner(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextRobotoAutoBold("My References".tr),
          vSpacer15(),
          referrals.isValid
              ? Column(children: List.generate(referrals!.length, (index) => _referencesItemView(referrals![index])))
              : showEmptyView(message: "empty_message_reference_list".tr)
        ],
      ),
    );
  }

  Column _referencesItemView(Referral referral) {
    final pcl = Get.theme.primaryColorLight;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        twoTextSpaceFixed('Name'.tr, referral.fullName ?? "", color: pcl),
        twoTextSpaceFixed('Email'.tr, referral.email ?? "", color: pcl),
        twoTextSpaceFixed('Level'.tr, referral.level ?? "", color: pcl),
        twoTextSpaceFixed('Joining Date'.tr, formatDate(referral.joiningDate, format: dateFormatMMMMDddYyy), color: pcl),
        dividerHorizontal(),
      ],
    );
  }
}
