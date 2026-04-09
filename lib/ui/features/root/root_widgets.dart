import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/models/user.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/decorations.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/language_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

import '../side_navigation/profile/profile_screen.dart';
import '../side_navigation/referrals/referrals_screen.dart';

class DrawerProfileView extends StatelessWidget {
  const DrawerProfileView({super.key, this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final hasUser = (user?.id ?? 0) > 0;
    final title = hasUser ? getName(user?.firstName, user?.lastName) : "Sign In".tr;
    RxString subTitle = (hasUser ? user?.email ?? "" : "Welcome_kAppName".trParams({"appName": "".tr})).obs;
    if (!hasUser) getAppName().then((name) => subTitle.value = "Welcome_kAppName".trParams({"appName": name}));

    return InkWell(
      onTap: () => hasUser ? Get.to(() => const ProfileScreen()) : Get.offAll(() => const SignInPage()),
      child: Row(
        children: [
          hSpacer10(),
          hasUser
              ? showCircleAvatar(user?.photo, size: Dimens.iconSizeLargeExtra)
              : const AppLogo(size: Dimens.iconSizeLargeExtra, radius: Dimens.iconSizeLargeExtra),
          hSpacer10(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [TextRobotoAutoBold(title, fontSize: Dimens.fontSizeLarge), Obx(() => TextRobotoAutoNormal(subTitle.value))],
          ),
        ],
      ),
    );
  }
}

class DrawerMenuItemView extends StatelessWidget {
  const DrawerMenuItemView({super.key, required this.navTitle, this.iconPath, this.navAction, this.icon});

  final String navTitle;
  final String? iconPath;
  final VoidCallback? navAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = context.theme.primaryColor;
    final tAlign = LanguageUtil.isDirectionRTL() ? TextAlign.right : TextAlign.left;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: Dimens.paddingLargeDouble),
      leading: iconPath.isValid
          ? showImageAsset(imagePath: iconPath, color: color, width: Dimens.iconSizeMin, height: Dimens.iconSizeMin)
          : (icon != null ? Icon(icon, size: Dimens.iconSizeMin, color: color) : hSpacer20()),
      title: TextRobotoAutoBold(navTitle, color: color, textAlign: tAlign),
      onTap: navAction,
    );
  }
}

class DrawerReferralView extends StatelessWidget {
  const DrawerReferralView({super.key, required this.hasUser});

  final bool hasUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationRoundBorder(),
      padding: const EdgeInsets.all(Dimens.paddingMid),
      margin: const EdgeInsets.all(Dimens.paddingMid),
      child: ListTile(
        visualDensity: minimumVisualDensity,
        dense: true,
        title: TextRobotoAutoBold("Referrals".tr),
        subtitle: TextRobotoAutoNormal("Refer friend to earn rewards".tr),
        trailing: Icon(Icons.account_tree_rounded, size: Dimens.iconSizeLarge, color: context.theme.primaryColorLight),
        onTap: () => hasUser ? Get.to(() => const ReferralsScreen()) : Get.offAll(() => const SignInPage()),
      ),
    );
  }
}
