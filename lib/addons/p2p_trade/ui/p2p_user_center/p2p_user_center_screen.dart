import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/appbar_util.dart';
import '../../../../utils/common_utils.dart';
import '../../../../utils/common_widgets.dart';
import '../../../../utils/dimens.dart';
import '../../../../utils/spacers.dart';
import '../../../../utils/text_util.dart';
import '../p2p_common_widgets.dart';
import 'p2p_user_center_controller.dart';
import 'user_banks_p2p/p2p_bank_screen.dart';

class P2PUserCenterScreen extends StatefulWidget {
  const P2PUserCenterScreen({super.key});

  @override
  State<P2PUserCenterScreen> createState() => _P2PUserCenterScreenState();
}

class _P2PUserCenterScreenState extends State<P2PUserCenterScreen> {
  final _controller = Get.put(P2pUserCenterController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getUserCenter());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pDetails = _controller.profileDetails;
      return _controller.isDataLoading.value
          ? showLoading()
          : Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Dimens.paddingMid),
                children: [
                  P2pProfileTopInfoView(user: pDetails.user, userRegisterDays: pDetails.userRegisterAt),
                  dividerHorizontal(height: Dimens.paddingLargeDouble),
                  Table(
                    children: [
                      TableRow(children: [
                        _countItemView("Total trades".tr, "${pDetails.totalTrade ?? 0}"),
                        _countItemView("30d Trades".tr, "${pDetails.completionRate30D ?? 0}%"),
                        _countItemView("First order at".tr, "${pDetails.firstOrderAt ?? 0} ${"days ago".tr}"),
                      ]),
                      TableRow(children: [vSpacer10(), vSpacer10(), vSpacer10()]),
                      TableRow(children: [
                        _countItemView("Positive reviews".tr, "${pDetails.positive ?? 0}"),
                        _countItemView("Reviews percentage".tr, "${pDetails.positiveFeedback ?? 0}%"),
                        _countItemView("Negative reviews".tr, "${pDetails.negative ?? 0}"),
                      ]),
                    ],
                  ),
                  vSpacer20(),
                  P2PBanksScreen(),
                  vSpacer20(),
                  Obx(() => tabBarText(
                      ["All".tr, "Positive".tr, "Negative".tr], _controller.selectedTab.value, (p0) => _controller.getFeedBackList(p0),
                      selectedColor: context.theme.focusColor)),
                  vSpacer10(),
                  Obx(() {
                    return _controller.feedBackList.isEmpty
                        ? showEmptyView(height: Dimens.menuHeightSettings)
                        : Column(
                            children: List.generate(
                                _controller.feedBackList.length, (index) => FeedBackItemView(feedback: _controller.feedBackList[index])));
                  })
                ],
              ),
            );
    });
  }

  Column _countItemView(String? title, String? subtitle) {
    return Column(
      children: [
        TextRobotoAutoNormal(title ?? ""),
        TextRobotoAutoBold((subtitle ?? "").toString()),
      ],
    );
  }
}
