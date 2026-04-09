import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/features/auth/auth_widgets.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'change_password_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ChangePasswordScreenState createState() => ChangePasswordScreenState();
}

class ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _controller = Get.put(ChangePasswordController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBarAuthView(onBack: () => Navigator.pop(context)),
      body: SafeArea(
        child: ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Dimens.paddingLargeDouble),
          children: [
            vSpacer20(),
            AuthTopTitleView(title: 'Change Password'.tr, subTitle: "Input your old and new password".tr),
            vSpacer10(),
            textFieldWithSuffixIcon(
                controller: _controller.currentPassEditController,
                labelText: "Current Password".tr,
                hint: "Current Password".tr,
                type: TextInputType.visiblePassword,
                isObscure: true),
            vSpacer15(),
            Obx(() {
              return textFieldWithSuffixIcon(
                  controller: _controller.newPassEditController,
                  labelText: "New Password".tr,
                  hint: "New Password".tr,
                  type: TextInputType.visiblePassword,
                  iconPath: _controller.isShowPassword.value ? AssetConstants.icPasswordShow : AssetConstants.icPasswordHide,
                  isObscure: !_controller.isShowPassword.value,
                  iconAction: () => _controller.isShowPassword.value = !_controller.isShowPassword.value);
            }),
            vSpacer15(),
            Obx(() {
              return textFieldWithSuffixIcon(
                  controller: _controller.confirmPassEditController,
                  labelText: "Confirm New Password".tr,
                  hint: "Confirm New Password".tr,
                  type: TextInputType.visiblePassword,
                  iconPath: _controller.isShowPassword.value ? AssetConstants.icPasswordShow : AssetConstants.icPasswordHide,
                  isObscure: !_controller.isShowPassword.value,
                  iconAction: () => _controller.isShowPassword.value = !_controller.isShowPassword.value);
            }),
            vSpacer30(),
            buttonRoundedMain(text: "Change".tr, onPress: () => _controller.isInPutDataValid(context)),
          ],
        ),
      ),
    );
  }
}
