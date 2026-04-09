import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../p2p_common_widgets.dart';
import '../../../../utils/appbar_util.dart';
import '../../../../utils/common_utils.dart';
import '../../../../utils/common_widgets.dart';
import '../../../../utils/dimens.dart';
import '../../../../utils/spacers.dart';
import '../../../../ui/ui_helper/app_widgets.dart';
import 'p2p_profile_controller.dart';

class P2pProfileScreen extends StatefulWidget {
  const P2pProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  P2pProfileScreenState createState() => P2pProfileScreenState();
}

class P2pProfileScreenState extends State<P2pProfileScreen> {
  final _controller = Get.put(P2pProfileController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _controller.getProfileDetails(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(title: "User Profile".tr),
      body: SafeArea(
        child: Obx(() {
          final pDetails = _controller.profileDetails;
          return _controller.isDataLoading.value
              ? showLoading()
              : ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(Dimens.paddingMid),
                  children: [
                    P2pProfileTopInfoView(user: pDetails.user, userRegisterDays: pDetails.userRegisterAt),
                    dividerHorizontal(height: Dimens.paddingLargeDouble),
                    Table(
                      children: [
                        TableRow(
                          children: [
                            coinDetailsItemView("Total trades".tr, "${pDetails.totalTrade ?? 0}"),
                            coinDetailsItemView("30d Trades".tr, "${pDetails.completionRate30D ?? 0}%"),
                            coinDetailsItemView("First order at".tr, "${pDetails.firstOrderAt ?? 0} ${"days ago".tr}"),
                          ],
                        ),
                        TableRow(children: [vSpacer10(), vSpacer10(), vSpacer10()]),
                        TableRow(
                          children: [
                            coinDetailsItemView("Positive reviews".tr, "${pDetails.positive ?? 0}"),
                            coinDetailsItemView("Reviews percentage".tr, "${pDetails.positiveFeedback ?? 0}%"),
                            coinDetailsItemView("Negative reviews".tr, "${pDetails.negative ?? 0}"),
                          ],
                        ),
                      ],
                    ),
                    dividerHorizontal(),
                    Obx(
                      () => tabBarText(
                        ["All".tr, "Positive".tr, "Negative".tr],
                        _controller.selectedTab.value,
                        (p0) => _controller.getFeedBackList(p0),
                      ),
                    ),
                    vSpacer5(),
                    Obx(() {
                      return _controller.feedBackList.isEmpty
                          ? showEmptyView(height: Dimens.menuHeightSettings)
                          : Column(
                              children: List.generate(
                                _controller.feedBackList.length,
                                (index) => FeedBackItemView(feedback: _controller.feedBackList[index]),
                              ),
                            );
                    }),
                  ],
                );
        }),
      ),
    );
  }
}
