import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/ui/features/auth/auth_widgets.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import '../sign_in/sign_in_screen.dart';
import 'email_verify_controller.dart';

class EmailVerifyPage extends StatefulWidget {
  final String registrationId;

  const EmailVerifyPage({super.key, required this.registrationId});

  @override
  EmailVerifyPageState createState() => EmailVerifyPageState();
}

class EmailVerifyPageState extends State<EmailVerifyPage> {
  final _controller = Get.put(EmailVerifyController());

  @override
  Widget build(BuildContext context) {
    final subTitle = "${'Enter verification code which sent email'.tr} ${widget.registrationId}";
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBarAuthView(title: "Sign In".tr, hideBack: true, onPress: () => Get.off(() => const SignInPage())),
      body: SafeArea(
        child: ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingLargeDouble),
          children: [
            vSpacer20(),
            AuthTopTitleView(title: 'Code verification'.tr, subTitle: subTitle),
            vSpacer10(),
            pinCodeView(controller: _controller.codeEditController),
            vSpacer30(),
            buttonRoundedMain(text: "Verify".tr, onPress: () => _controller.isInPutDataValid(context, widget.registrationId)),
            vSpacer10(),
          ],
        ),
      ),
    );
  }
}
