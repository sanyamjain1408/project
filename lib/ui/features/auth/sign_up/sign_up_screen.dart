import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/api_constants.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/ui/features/auth/auth_widgets.dart';
import 'package:tradexpro_flutter/ui/features/auth/sign_in/sign_in_screen.dart';
import 'package:tradexpro_flutter/ui/features/auth/social_login_view.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/common_widgets.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import 'package:tradexpro_flutter/utils/text_field_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'sign_up_controller.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final _controller = Get.put(SignUpController());
  RxBool checkPrivacy = false.obs;
  RxString appName = "".obs;

  @override
  void initState() {
    super.initState();
    _controller.phoneEditController.text =
        _controller.selectedPhone.value.phoneCode;
    getAppName().then((name) => appName.value = name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBarAuthView(
        title: "Sign In".tr,
        onPress: () => Get.off(() => const SignInPage()),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth * 0.06,
                vertical: 10,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    vSpacer20(),
                    AuthTopTitleView(
                      title: 'Sign up'.tr,
                      subTitle: 'Create your own account'.tr,
                    ),
                    vSpacer10(),
                    textFieldWithSuffixIcon(
                      controller: _controller.firstNameEditController,
                      labelText: "First Name".tr,
                      hint: "First Name".tr,
                      type: TextInputType.name,
                    ),
                    vSpacer15(),
                    textFieldWithSuffixIcon(
                      controller: _controller.lastNameEditController,
                      labelText: "Last Name".tr,
                      hint: "Last Name".tr,
                      type: TextInputType.name,
                    ),
                    vSpacer15(),
                    textFieldWithSuffixIcon(
                      controller: _controller.emailEditController,
                      labelText: "Email".tr,
                      hint: "Email".tr,
                      type: TextInputType.emailAddress,
                    ),
                    vSpacer10(),
                    TextRobotoAutoNormal("Optional".tr),
                    vSpacer5(),
                    Obx(() => textFieldWithWidget(
                          controller: _controller.phoneEditController,
                          type: TextInputType.phone,
                          prefixWidget: countryPickerView(
                            context,
                            _controller.selectedPhone.value,
                            (value) {
                              _controller.selectedPhone.value = value;
                              _controller.phoneEditController.text =
                                  value.phoneCode;
                            },
                            showPhoneCode: true,
                          ),
                        )),
                    TextRobotoAutoNormal(
                      "add phone number message".tr,
                      maxLines: 2,
                      fontSize: Dimens.fontSizeMin,
                    ),
                    vSpacer15(),
                    Obx(() => textFieldWithSuffixIcon(
                          controller: _controller.passEditController,
                          labelText: "Password".tr,
                          hint: "Password".tr,
                          type: TextInputType.visiblePassword,
                          iconPath: _controller.isShowPassword.value
                              ? AssetConstants.icPasswordShow
                              : AssetConstants.icPasswordHide,
                          isObscure: !_controller.isShowPassword.value,
                          iconAction: () => _controller.isShowPassword.value =
                              !_controller.isShowPassword.value,
                        )),
                    vSpacer15(),
                    Obx(() => textFieldWithSuffixIcon(
                          controller: _controller.confirmPassEditController,
                          labelText: "Confirm Password".tr,
                          hint: "Confirm Password".tr,
                          type: TextInputType.visiblePassword,
                          iconPath: _controller.isShowPassword.value
                              ? AssetConstants.icPasswordShow
                              : AssetConstants.icPasswordHide,
                          isObscure: !_controller.isShowPassword.value,
                          iconAction: () => _controller.isShowPassword.value =
                              !_controller.isShowPassword.value,
                        )),
                    vSpacer15(),
                    Obx(() => Row(
                          children: [
                            CheckBoxView(
                              checkPrivacy.value,
                              (value) => checkPrivacy.value = value,
                            ),
                            Expanded(
                              child: textSpanWithAction(
                                "By creating an account, I agree to"
                                    .trParams({"appName": appName.value}),
                                "${"Privacy Police".tr}.",
                                maxLines: 3,
                                textAlign: TextAlign.start,
                                onTap: () =>
                                    openUrlInBrowser(URLConstants.privacyLink),
                              ),
                            ),
                          ],
                        )),
                    vSpacer15(),
                    buttonRoundedMain(
                      text: "Sign Up".tr,
                      onPress: () => _controller.isInPutDataValid(
                          context, checkPrivacy.value),
                    ),
                    vSpacer20(),
                    const SocialLoginView(),
                    vSpacer20(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
