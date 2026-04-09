import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';

import 'auth_widgets.dart';

class SignUpSuccessPage extends StatefulWidget {
  const SignUpSuccessPage({super.key});

  @override
  SignUpSuccessPageState createState() => SignUpSuccessPageState();
}

class SignUpSuccessPageState extends State<SignUpSuccessPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.secondaryHeaderColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            showImageAsset(
                imagePath: AssetConstants.icTickLarge,
                height: Get.width / 3.2,
                width: Get.width / 3.2,
                color: Get.theme.focusColor),
            vSpacer20(),
            AuthTopTitleView(title: 'Successful'.tr, subTitle: 'Your account verified successfully'.tr, isCenter: true),
            vSpacer10(),
            Padding(
              padding: const EdgeInsets.all(Dimens.paddingLargeDouble),
              child: buttonRoundedMain(text: "Sign in now".tr, onPress: () => Get.off(() => const SignInPage())),
            ),

          ],
        ),
      ),
    );
  }
}
