import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/appbar_util.dart';
import 'package:tradexpro_flutter/utils/date_util.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/data/models/user.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import '../../../../helper/app_checker.dart';
import 'kyc_screen.dart';
import 'my_profile_controller.dart';
import 'my_profile_edit_screen.dart';
import 'security_screen.dart';
import 'user_banks/user_bank_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _controller = Get.put(MyProfileController());
  late final TabController _tabController;
  List<UserActivity> userActivities = <UserActivity>[];

  @override
  void initState() {
    _tabController = TabController(length: _controller.getProfileMenus().length, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarBackWithActions(title: "Profile".tr),
      body: SafeArea(
        child: Obx(() => Column(
              children: [
                tabBarUnderline(_controller.getProfileMenus(), _tabController, onTap: (index) {
                  _controller.selectedType.value = index;
                }, isScrollable: true, fontSize: Dimens.fontSizeMid),
                _buildBody()
              ],
            )),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.selectedType.value == 0) {
      return Obx(() => _profileView(gUserRx.value));
    } else if (_controller.selectedType.value == 1) {
      return const ProfileEditScreen();
    } else if (_controller.selectedType.value == 2) {
      return const SecurityScreen();
    } else if (_controller.selectedType.value == 3) {
      return const KYCScreen();
    } else if (_controller.selectedType.value == 4) {
      return const UserBankScreen();
    } else {
      return Container();
    }
  }

  Expanded _profileView(User user) {
    if (userActivities.isEmpty) _controller.getUserActivities((list) => userActivities = list);
    return Expanded(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(Dimens.paddingMid),
        children: [
          ProfileInfoView(user: user),
          vSpacer30(),
          TextRobotoAutoBold("Profile Activity".tr),
          vSpacer10(),
          Row(
            children: [
              Expanded(child: TextRobotoAutoNormal("Action".tr)),
              Expanded(child: TextRobotoAutoNormal("IP Address".tr, textAlign: TextAlign.center)),
              Expanded(child: TextRobotoAutoNormal("Time".tr, textAlign: TextAlign.end)),
            ],
          ),
          vSpacer5(),
          for (final activity in userActivities) _userActivityItem(activity)
        ],
      ),
    );
  }

  Padding _userActivityItem(UserActivity activity) {
    final actionString = "${AppChecker.getActivityActionText(activity.action)}\n${activity.source ?? ""}";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.paddingMin),
      child: Row(
        children: [
          Expanded(child: TextRobotoAutoNormal(actionString, maxLines: 2, color: context.theme.primaryColor)),
          Expanded(child: TextRobotoAutoNormal(activity.ipAddress ?? "", maxLines: 2, textAlign: TextAlign.center)),
          Expanded(
              child: TextRobotoAutoNormal(formatDate(activity.updatedAt, format: dateTimeFormatYyyyMMDdHhMm), maxLines: 2, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class ProfileInfoView extends StatelessWidget {
  const ProfileInfoView({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final boxSize = context.width / 3;
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: boxSize,
              height: boxSize,
              alignment: Alignment.center,
              decoration: getRoundCornerWithShadow(color: context.theme.dialogTheme.backgroundColor),
              child: showCircleAvatar(user.photo, size: (boxSize / 1.5)),
            ),
            hSpacer10(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.nickName.isValid) TextRobotoAutoBold(user.nickName ?? "", fontSize: Dimens.fontSizeLarge),
                TextRobotoAutoBold(getName(user.firstName, user.lastName), color: context.theme.primaryColorLight),
                TextRobotoAutoNormal(user.email ?? "", color: context.theme.primaryColor),
              ],
            )
          ],
        ),
        vSpacer20(),
        textFieldWithSuffixIcon(
            controller: TextEditingController(),
            text: user.countryName.isValid ? user.countryName : "No Country".tr,
            hint: "Country".tr,
            isEnable: false),
        vSpacer10(),
        textFieldWithSuffixIcon(
            controller: TextEditingController(), text: AppChecker.getActiveStatusData(user.status).first, hint: "Status".tr, isEnable: false),
        vSpacer10(),
        textFieldWithSuffixIcon(controller: TextEditingController(), text: user.phone ?? "No Phone".tr, hint: "Phone".tr, isEnable: false),
      ],
    );
  }
}
