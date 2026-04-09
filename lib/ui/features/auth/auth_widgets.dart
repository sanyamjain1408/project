import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/root/root_screen.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/extensions.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';

class AppBarAuthView extends StatelessWidget implements PreferredSizeWidget {
  const AppBarAuthView({super.key, this.title, this.onPress, this.onBack, this.hideBack});

  final String? title;
  final VoidCallback? onPress;
  final VoidCallback? onBack;
  final bool? hideBack;

  @override
  Widget build(BuildContext context) {
    return AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: hideBack == true
            ? null
            : buttonOnlyIcon(
                iconData: Icons.arrow_back,
                iconColor: context.theme.primaryColor,
                onPress: onBack ?? () => Get.offAll(() => const RootScreen())),
        actions: [if (title.isValid) InkWell(onTap: onPress, child: TextRobotoAutoBold(title!)), hSpacer10()]);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AuthTopTitleView extends StatelessWidget {
  const AuthTopTitleView({super.key, this.title, this.subTitle, this.isCenter});

  final String? title;
  final String? subTitle;
  final bool? isCenter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isCenter == true ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        TextRobotoAutoBold(title ?? ""),
        TextRobotoAutoNormal(subTitle ?? "", maxLines: 2),
        vSpacer10(),
      ],
    );
  }
}
